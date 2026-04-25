#===========================================================
# HexaChipsers RV32IMAFB Integration Test Makefile
#-----------------------------------------------------------
# Builds bare-metal C test programs for the HexaChipsers
# RISC-V core using the xPack riscv-none-elf-gcc toolchain.
#===========================================================

# ---- Toolchain Configuration ----
CROSS   ?= riscv-none-elf-
CC       = $(CROSS)gcc
OBJCOPY  = $(CROSS)objcopy
OBJDUMP  = $(CROSS)objdump
SIZE     = $(CROSS)size

# ---- Architecture Flags ----
ARCH     = rv32imaf_zba_zbb_zbc_zbs
ABI      = ilp32f
OPT      = -O2

# ---- Directories ----
SRC_DIR  = src
BSP_DIR  = ../FPU_test/src
BUILD_DIR= build
HEX2V    = ../../../Araçlar/hex2mif/hex2v.exe

# ---- Linker Script ----
LDSCRIPT = ../FPU_test/link.ld

# ---- Common source files (BSP) ----
BSP_SRCS = $(BSP_DIR)/startup.S \
           $(BSP_DIR)/uart.c    \
           $(BSP_DIR)/xprintf.c \
           $(BSP_DIR)/interrupt.c \
           $(BSP_DIR)/gpio.c    \
           $(BSP_DIR)/system.c

# ---- Test programs ----
TESTS    = test_recursive     \
           test_fpu_math      \
           test_bitmanip_edge \
           test_pipeline_stress \
           test_interrupt     \
           test_atomic

# ---- Compiler / Linker flags ----
CFLAGS   = -march=$(ARCH) -mabi=$(ABI) $(OPT) \
           -nostdlib -nostartfiles \
           -ffunction-sections -fdata-sections \
           -Wall -Wno-unused-function \
           -I$(BSP_DIR) -I$(SRC_DIR) \
           -DFPGA

LDFLAGS  = -T $(LDSCRIPT) \
           -march=$(ARCH) -mabi=$(ABI) \
           -nostdlib -nostartfiles \
           -Wl,--gc-sections \
           -Wl,-Map=$(BUILD_DIR)/$*.map

# ---- Default target ----
.PHONY: all clean info

all: $(addprefix $(BUILD_DIR)/, $(addsuffix .elf, $(TESTS)))

info:
	@echo "CROSS    = $(CROSS)"
	@echo "ARCH     = $(ARCH)"
	@echo "TESTS    = $(TESTS)"
	$(CC) --version | head -1

# ---- Build Rules ----
# Each test: test_xxx.c + BSP sources -> test_xxx.elf -> .hex -> _mem.v
$(BUILD_DIR)/%.elf: $(SRC_DIR)/%.c $(BSP_SRCS) $(LDSCRIPT) | $(BUILD_DIR)
	@echo "==== Building $* ===="
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(BSP_SRCS) $<
	$(OBJCOPY) -O ihex $@ $(BUILD_DIR)/$*.hex
	$(OBJDUMP) -d -S $@ > $(BUILD_DIR)/$*.lst
	$(SIZE) $@
	@echo "---- Converting to Verilog mem ----"
	$(HEX2V) $(BUILD_DIR)/$*.hex $(BUILD_DIR)/$*_mem.v || echo "[WARN] hex2v failed, manual conversion needed"
	@echo "==== $* DONE ===="
	@echo ""

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/*

# ---- Individual test targets ----
.PHONY: $(TESTS)
$(TESTS): %: $(BUILD_DIR)/%.elf

#===========================================================
# End of Makefile
#===========================================================
