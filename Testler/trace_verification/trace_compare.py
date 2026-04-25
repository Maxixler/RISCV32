#!/usr/bin/env python3
"""
===========================================================
HexaChipsers RV32IMAFB — Trace Comparison Tool
-----------------------------------------------------------
Compares RTL execution trace against Spike ISS golden model
trace to detect silent data corruption or execution divergence.

Usage:
    python trace_compare.py --rtl rtl_trace.txt --spike spike_trace.log
    python trace_compare.py --rtl rtl_trace.txt --spike spike_trace.log --max-errors 10
===========================================================
"""

import re
import sys
import argparse
from pathlib import Path
from dataclasses import dataclass
from typing import List, Optional, Tuple


@dataclass
class TraceEntry:
    """Single instruction trace entry"""
    line_num: int
    pc: int
    instr_hex: int
    rd_addr: Optional[int] = None
    rd_data: Optional[int] = None
    frd_addr: Optional[int] = None
    frd_data: Optional[int] = None
    raw_line: str = ""


def parse_rtl_trace(filepath: str) -> List[TraceEntry]:
    """
    Parse RTL trace format:
    Each line: PC INSTR_HEX RD RD_DATA [FRD FRD_DATA]
    Example: 90000000 00000097 x01 90000000
             90000804 c0200553 f10 3f800000
    """
    entries = []
    # Try different encodings
    content = None
    for enc in ['utf-8-sig', 'utf-16', 'utf-8', 'latin-1']:
        try:
            with open(filepath, 'r', encoding=enc) as f:
                content = f.readlines()
            break
        except (UnicodeDecodeError, UnicodeError):
            continue

    if content is None:
        print(f"ERROR: Could not read {filepath} with any encoding")
        return []

    for line_num, line in enumerate(content, 1):
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('//'):
                continue

            parts = line.split()
            if len(parts) < 2:
                continue

            try:
                entry = TraceEntry(
                    line_num=line_num,
                    pc=int(parts[0], 16),
                    instr_hex=int(parts[1], 16),
                    raw_line=line
                )

                # Parse register writeback
                if len(parts) >= 4:
                    reg_name = parts[2]
                    reg_data = int(parts[3], 16)

                    if reg_name.startswith('x'):
                        entry.rd_addr = int(reg_name[1:])
                        entry.rd_data = reg_data
                    elif reg_name.startswith('f'):
                        entry.frd_addr = int(reg_name[1:])
                        entry.frd_data = reg_data

                # Parse optional FPU writeback
                if len(parts) >= 6:
                    freg_name = parts[4]
                    freg_data = int(parts[5], 16)
                    if freg_name.startswith('f'):
                        entry.frd_addr = int(freg_name[1:])
                        entry.frd_data = freg_data

                entries.append(entry)
            except (ValueError, IndexError):
                continue

    return entries


def parse_spike_trace(filepath: str) -> List[TraceEntry]:
    """
    Parse Spike --log-commits format:
    core   0: 0x90000000 (0x00000097) x1  0x90000000
    core   0: 0x90000004 (0xfe0080e7) x1  0x90000008

    Or newer Spike format (with priv level):
    core   0: 3 0x90000000 (0x00000097) x1  0x90000000
    core   0: 3 0x9000042c (0x00052283) x5  0x00000000 mem 0x90009d34
    """
    entries = []

    # Pattern handles: optional priv level, optional mem annotation
    pattern1 = re.compile(
        r'core\s+\d+:\s+'                    # core N:
        r'(?:\d+\s+)?'                        # optional priv level
        r'0x([0-9a-fA-F]+)\s+'               # PC
        r'\(0x([0-9a-fA-F]+)\)\s*'           # instruction hex
        r'(?:'
        r'(x|f)(\d+)\s+'                     # register name (x/f + number)
        r'0x([0-9a-fA-F]+)'                  # register data
        r')?'
        r'(?:\s+mem\s+0x[0-9a-fA-F]+)?'      # optional mem annotation
        r'(?:\s+c\d+_\w+\s+0x[0-9a-fA-F]+)*' # optional CSR annotations
    )

    # Try different encodings
    content = None
    for enc in ['utf-8-sig', 'utf-16', 'utf-8', 'latin-1']:
        try:
            with open(filepath, 'r', encoding=enc) as f:
                content = f.readlines()
            break
        except (UnicodeDecodeError, UnicodeError):
            continue

    if content is None:
        print(f"ERROR: Could not read {filepath} with any encoding")
        return []

    for line_num, line in enumerate(content, 1):
        line = line.strip()
        if not line or not line.startswith('core'):
            continue

        m = pattern1.match(line)
        if not m:
            continue

        try:
            entry = TraceEntry(
                line_num=line_num,
                pc=int(m.group(1), 16),
                instr_hex=int(m.group(2), 16),
                raw_line=line
            )

            if m.group(3):  # register writeback present
                reg_type = m.group(3)
                reg_num = int(m.group(4))
                reg_val = int(m.group(5), 16)

                if reg_type == 'x':
                    entry.rd_addr = reg_num
                    entry.rd_data = reg_val
                elif reg_type == 'f':
                    entry.frd_addr = reg_num
                    entry.frd_data = reg_val

            entries.append(entry)
        except (ValueError, IndexError):
            continue

    return entries


def compare_traces(
    rtl_trace: List[TraceEntry],
    spike_trace: List[TraceEntry],
    max_errors: int = 20,
    context_lines: int = 10
) -> Tuple[int, int, List[str]]:
    """
    Compare RTL and Spike traces entry by entry.
    Returns: (match_count, mismatch_count, error_messages)
    """
    match_count = 0
    mismatch_count = 0
    errors = []

    min_len = min(len(rtl_trace), len(spike_trace))

    if len(rtl_trace) != len(spike_trace):
        errors.append(
            f"WARNING: Trace length mismatch: RTL={len(rtl_trace)}, "
            f"Spike={len(spike_trace)}"
        )

    for i in range(min_len):
        rtl = rtl_trace[i]
        spike = spike_trace[i]
        mismatches = []

        # Compare PC
        if rtl.pc != spike.pc:
            mismatches.append(
                f"  PC: RTL=0x{rtl.pc:08X}, Spike=0x{spike.pc:08X}"
            )

        # Compare instruction
        if rtl.instr_hex != spike.instr_hex:
            # Allow compressed instruction differences (16 vs 32 bit)
            if not ((rtl.instr_hex & 0xFFFF) == (spike.instr_hex & 0xFFFF)
                    and (rtl.instr_hex & 0x3) != 0x3):
                mismatches.append(
                    f"  INSTR: RTL=0x{rtl.instr_hex:08X}, "
                    f"Spike=0x{spike.instr_hex:08X}"
                )

        # Compare GPR writeback
        if rtl.rd_addr is not None and spike.rd_addr is not None:
            if rtl.rd_addr != spike.rd_addr:
                mismatches.append(
                    f"  RD addr: RTL=x{rtl.rd_addr}, Spike=x{spike.rd_addr}"
                )
            elif rtl.rd_data != spike.rd_data:
                mismatches.append(
                    f"  RD data: RTL=0x{rtl.rd_data:08X}, "
                    f"Spike=0x{spike.rd_data:08X} (x{rtl.rd_addr})"
                )

        # Compare FPR writeback
        if rtl.frd_addr is not None and spike.frd_addr is not None:
            if rtl.frd_addr != spike.frd_addr:
                mismatches.append(
                    f"  FRD addr: RTL=f{rtl.frd_addr}, "
                    f"Spike=f{spike.frd_addr}"
                )
            elif rtl.frd_data != spike.frd_data:
                mismatches.append(
                    f"  FRD data: RTL=0x{rtl.frd_data:08X}, "
                    f"Spike=0x{spike.frd_data:08X} (f{rtl.frd_addr})"
                )

        if mismatches:
            mismatch_count += 1
            if mismatch_count <= max_errors:
                errors.append(
                    f"\n{'='*60}\n"
                    f"MISMATCH at instruction #{i} "
                    f"(RTL line {rtl.line_num}, Spike line {spike.line_num}):"
                )
                errors.extend(mismatches)

                # Show context (previous N instructions)
                if context_lines > 0:
                    errors.append(f"\n  Context (previous {context_lines} instructions):")
                    start = max(0, i - context_lines)
                    for j in range(start, i):
                        errors.append(
                            f"    [{j}] RTL:   {rtl_trace[j].raw_line}"
                        )
                        errors.append(
                            f"         Spike: {spike_trace[j].raw_line}"
                        )
                errors.append(f"  Current:")
                errors.append(f"    [{i}] RTL:   {rtl.raw_line}")
                errors.append(f"         Spike: {spike.raw_line}")
        else:
            match_count += 1

    return match_count, mismatch_count, errors


def main():
    parser = argparse.ArgumentParser(
        description='HexaChipsers RV32IMAFB Trace Comparison Tool'
    )
    parser.add_argument('--rtl', required=True,
                        help='Path to RTL execution trace')
    parser.add_argument('--spike', required=True,
                        help='Path to Spike execution trace')
    parser.add_argument('--max-errors', type=int, default=20,
                        help='Maximum number of errors to report (default: 20)')
    parser.add_argument('--context', type=int, default=10,
                        help='Context lines before mismatch (default: 10)')
    parser.add_argument('--output', default='trace_result.txt',
                        help='Output report file (default: trace_result.txt)')

    args = parser.parse_args()

    print("=" * 60)
    print(" HexaChipsers RV32IMAFB Trace Comparison")
    print("=" * 60)
    print(f" RTL trace:   {args.rtl}")
    print(f" Spike trace: {args.spike}")
    print()

    # Parse traces
    print("Parsing RTL trace...", end=" ")
    rtl_trace = parse_rtl_trace(args.rtl)
    print(f"{len(rtl_trace)} entries")

    print("Parsing Spike trace...", end=" ")
    spike_trace = parse_spike_trace(args.spike)
    print(f"{len(spike_trace)} entries")

    if not rtl_trace:
        print("ERROR: No entries parsed from RTL trace")
        sys.exit(1)
    if not spike_trace:
        print("ERROR: No entries parsed from Spike trace")
        sys.exit(1)

    # Compare
    print("\nComparing traces...")
    match, mismatch, errors = compare_traces(
        rtl_trace, spike_trace,
        max_errors=args.max_errors,
        context_lines=args.context
    )

    # Print results
    for err in errors:
        print(err)

    total = match + mismatch
    print(f"\n{'=' * 60}")
    print(f" TRACE COMPARISON RESULTS")
    print(f"{'=' * 60}")
    print(f" Total compared: {total}")
    print(f" Matched:        {match}")
    print(f" Mismatched:     {mismatch}")

    if mismatch == 0 and total > 0:
        print(f"\n [PASS] ALL {total} INSTRUCTIONS MATCH")
        result = "PASS"
    elif mismatch > 0:
        print(f"\n [FAIL] {mismatch} MISMATCHES FOUND")
        result = "FAIL"
    else:
        print(f"\n [WARN] NO INSTRUCTIONS TO COMPARE")
        result = "EMPTY"

    print(f"{'=' * 60}")

    # Write report
    with open(args.output, 'w') as f:
        f.write(f"HexaChipsers Trace Comparison Report\n")
        f.write(f"RTL:   {args.rtl}\n")
        f.write(f"Spike: {args.spike}\n")
        f.write(f"Result: {result}\n")
        f.write(f"Matched: {match}, Mismatched: {mismatch}\n\n")
        for err in errors:
            f.write(err + "\n")

    print(f"\nReport saved to: {args.output}")

    sys.exit(0 if mismatch == 0 else 1)


if __name__ == '__main__':
    main()
