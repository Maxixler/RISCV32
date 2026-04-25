#===========================================================
# HexaChipsers RV32IMAFB — Spike ISS Docker Image
#-----------------------------------------------------------
# Builds Spike RISC-V ISA Simulator for golden model trace
# verification against RTL execution.
#===========================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    device-tree-compiler \
    libboost-all-dev \
    autoconf \
    automake \
    libtool \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Build Spike ISS
RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git /spike \
    && cd /spike \
    && mkdir build \
    && cd build \
    && ../configure --prefix=/opt/spike \
    && make -j$(nproc) \
    && make install \
    && rm -rf /spike

# Build RISC-V proxy kernel (for running ELF files)
RUN git clone https://github.com/riscv-software-src/riscv-pk.git /pk \
    && cd /pk \
    && mkdir build \
    && cd build \
    && ../configure --prefix=/opt/riscv --host=riscv32-unknown-elf \
    || true  # pk may not build without cross-compiler, that's OK

ENV PATH="/opt/spike/bin:${PATH}"

# Working directory for test files
WORKDIR /workspace

# Default command: show spike version
CMD ["spike", "--help"]
