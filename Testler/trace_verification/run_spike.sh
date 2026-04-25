#!/bin/bash
#===========================================================
# HexaChipsers RV32IMAFB — Spike Trace Runner
#-----------------------------------------------------------
# Runs an ELF file in Spike ISS with commit logging enabled
# and extracts execution trace for comparison with RTL.
#
# Usage: ./run_spike.sh <path/to/test.elf> [output_trace.log]
#===========================================================

set -euo pipefail

ELF_FILE="${1:?Usage: $0 <test.elf> [output.log]}"
TRACE_FILE="${2:-spike_trace.log}"
IMAGE_NAME="hexachipsers-spike"

# Resolve absolute path
ELF_DIR=$(cd "$(dirname "$ELF_FILE")" && pwd)
ELF_NAME=$(basename "$ELF_FILE")

echo "========================================"
echo " HexaChipsers Spike Trace Runner"
echo " ELF: $ELF_FILE"
echo " Output: $TRACE_FILE"
echo "========================================"

# Build Docker image if needed
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "Building Spike Docker image..."
    SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
fi

# Run Spike with commit logging
echo "Running Spike..."
docker run --rm \
    -v "$ELF_DIR:/workspace:ro" \
    "$IMAGE_NAME" \
    spike \
        --isa=rv32imaf_zba_zbb_zbc_zbs \
        --log-commits \
        --log=- \
        -m0x80000000:0x10000000 \
        "/workspace/$ELF_NAME" \
    2>&1 | tee "$TRACE_FILE"

echo ""
echo "========================================"
echo " Trace saved to: $TRACE_FILE"
echo " Lines: $(wc -l < "$TRACE_FILE")"
echo "========================================"
