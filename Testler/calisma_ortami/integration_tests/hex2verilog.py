#!/usr/bin/env python3
"""
Intel HEX to Verilog $readmemh converter
Replaces hex2v.exe (Linux binary) on Windows

Usage:
  python hex2verilog.py input.hex output.mem          # 32-bit word format
  python hex2verilog.py input.hex output.memh --byte   # byte format (rom.memh for slaves_ahb.v)
"""
import sys

def parse_ihex(filepath):
    """Parse Intel HEX file, return dict of {address: byte_value}"""
    memory = {}
    base_addr = 0
    
    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line.startswith(':'):
                continue
            
            byte_count = int(line[1:3], 16)
            address = int(line[3:7], 16)
            record_type = int(line[7:9], 16)
            
            if record_type == 0:  # Data record
                for i in range(byte_count):
                    byte_val = int(line[9 + i*2 : 11 + i*2], 16)
                    memory[base_addr + address + i] = byte_val
            elif record_type == 1:  # EOF
                break
            elif record_type == 2:  # Extended segment address
                base_addr = int(line[9:13], 16) << 4
            elif record_type == 4:  # Extended linear address
                base_addr = int(line[9:13], 16) << 16
    
    return memory

def mem_to_readmemh_word(memory, output_path):
    """Convert memory dict to Verilog $readmemh format (32-bit words)"""
    if not memory:
        print("WARNING: Empty memory map")
        return
    
    min_addr = min(memory.keys())
    max_addr = max(memory.keys())
    
    # Align to word boundaries
    min_addr = min_addr & ~3
    max_addr = (max_addr + 3) & ~3
    
    with open(output_path, 'w') as f:
        f.write(f"// Generated from Intel HEX\n")
        f.write(f"// Address range: 0x{min_addr:08X} - 0x{max_addr:08X}\n")
        
        addr = min_addr
        while addr <= max_addr:
            b0 = memory.get(addr + 0, 0)
            b1 = memory.get(addr + 1, 0)
            b2 = memory.get(addr + 2, 0)
            b3 = memory.get(addr + 3, 0)
            word = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
            
            if word != 0 or addr == min_addr:
                f.write(f"@{(addr >> 2):08X} {word:08X}\n")
            
            addr += 4
    
    print(f"Generated {output_path}: {(max_addr - min_addr) // 4 + 1} words")

def mem_to_rom_memh(memory, output_path, base_addr=None):
    """Convert memory dict to byte-oriented rom.memh format for slaves_ahb.v.
    Format: reg [7:0] rom[0:65535]; $readmemh("rom.memh", rom);
    Uses @address format for $readmemh compatibility

    base_addr: if provided, subtract this from all addresses to get flat offsets.
               Auto-detected if not specified (uses minimum address).
    """
    if not memory:
        print("WARNING: Empty memory map")
        return

    if base_addr is None:
        # Auto-detect: find lowest address and align to nearest known base
        min_addr = min(memory.keys())
        # Known bases: 0x90000000 (RAMI), 0x88000000 (RAMD)
        if min_addr >= 0x90000000:
            base_addr = 0x90000000
        elif min_addr >= 0x88000000:
            base_addr = 0x88000000
        else:
            base_addr = min_addr & ~0xFFFF  # align to 64KB boundary
        print(f"  Base address: 0x{base_addr:08X}")

    # Convert absolute addresses to flat offsets
    flat_mem = {}
    for addr, val in memory.items():
        offset = addr - base_addr
        if 0 <= offset < 65536:
            flat_mem[offset] = val

    if not flat_mem:
        print("WARNING: No data in range after base subtraction")
        return

    max_offset = max(flat_mem.keys())
    byte_count = min(max_offset + 1, 65536)

    with open(output_path, 'w') as f:
        f.write(f"// Generated from Intel HEX\n")
        f.write(f"// Address range: 0x{base_addr:08X} - 0x{base_addr + max_offset:08X}\n")
        f.write(f"// Byte count: {byte_count}\n")

        # Use @offset format for $readmemh compatibility
        # Each line: @offset byte_value
        for offset in range(byte_count):
            byte_val = flat_mem.get(offset, 0)
            f.write(f"@{offset:08X} {byte_val:02X}\n")

    print(f"Generated {output_path}: {byte_count} bytes (base=0x{base_addr:08X})")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input.hex> <output.mem> [--byte]")
        sys.exit(1)
    
    byte_mode = "--byte" in sys.argv
    
    memory = parse_ihex(sys.argv[1])
    
    if byte_mode:
        mem_to_rom_memh(memory, sys.argv[2])
    else:
        mem_to_readmemh_word(memory, sys.argv[2])

