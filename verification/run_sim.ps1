# HexaChipsers RV32IMAFB - PowerShell Integration Test Runner
# Avoids Turkish character encoding issues by resolving paths via wildcards
param(
    [string]$TestName = "test_recursive"
)

$ErrorActionPreference = "Continue"

# Resolve paths with Turkish characters using wildcards
$BASE     = "c:\Users\DELL\Downloads\HexaChipsers-Core"
$RTL      = (Get-Item "$BASE\Verilog*").FullName
$DEF      = (Get-Item "$RTL\Tan*mlamalar").FullName
$CPU      = "$RTL\Cekirdek\cpu"
$CORE     = "$RTL\Cekirdek\HexaCore"
$TOP      = "$RTL\Ust modul"
$PERIPH   = "$RTL\Cevre Birimleri"
$BUS      = "$RTL\Veriyolu"
$VER      = "$BASE\verification"
$BUILD    = "$BASE\Testler\calisma_ortami\integration_tests\build"
$WORK     = "$VER\xsim_integration"
$XVLOG    = "C:\Xilinx\2025.1\Vivado\bin\xvlog.bat"
$XELAB    = "C:\Xilinx\2025.1\Vivado\bin\xelab.bat"
$XSIM     = "C:\Xilinx\2025.1\Vivado\bin\xsim.bat"
$SPI_INC  = "$PERIPH\spi\simple_spi\trunk\rtl\verilog"

Write-Host "Resolved RTL dir: $RTL"
Write-Host "Resolved DEF dir: $DEF"

New-Item -ItemType Directory -Force -Path $WORK | Out-Null
Set-Location $WORK

Write-Host "============================================================"
Write-Host " HexaChipsers RV32IMAFB - Full System Integration Test"
Write-Host "============================================================"
Write-Host " Test: $TestName"
Write-Host ""

# ============================================================
# Phase 1: Compile all RTL files
# ============================================================
Write-Host "--- Phase 1: Compiling RTL ---"

$cpu_files = @(
    "$CPU\cpu_fetch.v",
    "$CPU\cpu_pipeline.v",
    "$CPU\cpu_datapath.v",
    "$CPU\cpu_csr.v",
    "$CPU\cpu_csr_int.v",
    "$CPU\cpu_fpu32.v",
    "$CPU\cpu_csr_dbg.v",
    "$CPU\cpu_debug.v",
    "$CPU\cpu_top.v"
)

$core_files = @(
    "$CORE\RAM.v",
    "$CORE\bus_m_ahb.v",
    "$CORE\csr_mtime.v",
    "$CORE\HexaCore.v"
)

$top_files = @(
    "$TOP\slaves_ahb.v",
    "$TOP\chip_top.v",
    "$TOP\chip_top_wrap.v"
)

$periph_files = @(
    "$PERIPH\uart\uart.v",
    "$PERIPH\uart\sasc\trunk\rtl\verilog\sasc_brg.v",
    "$PERIPH\uart\sasc\trunk\rtl\verilog\sasc_fifo4.v",
    "$PERIPH\uart\sasc\trunk\rtl\verilog\sasc_top.v",
    "$PERIPH\i2c\i2c.v",
    "$PERIPH\i2c\i2c\trunk\rtl\verilog\i2c_master_bit_ctrl.v",
    "$PERIPH\i2c\i2c\trunk\rtl\verilog\i2c_master_byte_ctrl.v",
    "$PERIPH\i2c\i2c\trunk\rtl\verilog\i2c_master_top.v",
    "$PERIPH\spi\spi.v",
    "$PERIPH\spi\simple_spi\trunk\rtl\verilog\fifo4.v",
    "$PERIPH\spi\simple_spi\trunk\rtl\verilog\simple_spi_top.v",
    "$PERIPH\port\port.v",
    "$PERIPH\int_gen\int_gen.v",
    "$PERIPH\debug\debug_cdc.v",
    "$PERIPH\debug\debug_dm.v",
    "$PERIPH\debug\debug_dtm_jtag.v",
    "$PERIPH\debug\debug_top.v"
)

$bus_files = @(
    "$BUS\ahb_matrix\ahb_arb.v",
    "$BUS\ahb_matrix\ahb_interconnect.v",
    "$BUS\ahb_matrix\ahb_master_port.v",
    "$BUS\ahb_matrix\ahb_slave_port.v",
    "$BUS\ahb_matrix\ahb_top.v",
    "$BUS\ahb_sdram\logic\ahb_lite_sdram.v"
)

$all_files = $cpu_files + $core_files + $periph_files + $bus_files + $top_files

$ok = 0
$fail = 0

foreach ($f in $all_files) {
    $fname = Split-Path $f -Leaf
    Write-Host -NoNewline "  Compiling $fname ... "
    
    if (!(Test-Path $f)) {
        Write-Host "MISSING ($f)"
        $fail++
        continue
    }
    
    # SPI sub-modules need extra include path
    if ($f -like "*simple_spi*") {
        $result = & $XVLOG -sv -i "$DEF" -i "$SPI_INC" -d SIMULATION --nolog "$f" 2>&1
    } else {
        $result = & $XVLOG -sv -i "$DEF" -d SIMULATION --nolog "$f" 2>&1
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARN"
        $fail++
    } else {
        Write-Host "OK"
        $ok++
    }
}

Write-Host "  Compile: $ok OK, $fail WARN"
Write-Host ""

# ============================================================
# Phase 2: Compile Testbench
# ============================================================
Write-Host "--- Phase 2: Compiling Testbench ---"
$tb = "$VER\tb_integration.sv"
$result = & $XVLOG -sv -i "$DEF" -d SIMULATION --nolog "$tb" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR compiling testbench:"
    Write-Host "  $result"
    exit 1
} else {
    Write-Host "  Testbench compiled OK"
}

# ============================================================
# Phase 3: Elaborate
# ============================================================
Write-Host ""
Write-Host "--- Phase 3: Elaborating ---"
$result = & $XELAB work.tb_integration -s tb_sim -debug off --nolog --timescale "1ns/1ps" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR elaborating:"
    Write-Host "  $result"
    exit 1
} else {
    Write-Host "  Elaboration OK"
}

# ============================================================
# Phase 4: Run Test
# ============================================================
Write-Host ""
Write-Host "--- Phase 4: Running $TestName ---"

$memhSrc = "$BUILD\${TestName}_rom.memh"
$memhDst = "$WORK\rom.memh"

if (!(Test-Path $memhSrc)) {
    Write-Host "  ERROR: $memhSrc not found"
    exit 1
}

Copy-Item -Force $memhSrc $memhDst
Write-Host "  Loaded: ${TestName}_rom.memh"

$uartLog = "$WORK\uart_log.txt"
if (Test-Path $uartLog) { Remove-Item $uartLog }

$result = & $XSIM tb_sim -runall -log xsim_run.log 2>&1
Write-Host "  Simulation completed"

# Check UART output
if (Test-Path $uartLog) {
    $content = Get-Content $uartLog -Raw -ErrorAction SilentlyContinue
    
    Copy-Item -Force $uartLog "$WORK\uart_${TestName}.txt"
    
    if ($content -match "ALL TESTS PASSED") {
        Write-Host "  RESULT: $TestName = PASS"
    } elseif ($content -match "FAIL") {
        Write-Host "  RESULT: $TestName = FAIL"
        Write-Host "  UART Output:"
        Write-Host "  $content"
    } else {
        Write-Host "  RESULT: $TestName = INCOMPLETE"
        if ($content) {
            $len = [Math]::Min(500, $content.Length)
            Write-Host ("  UART Output (first $len chars):")
            Write-Host ("  " + $content.Substring(0, $len))
        } else {
            Write-Host "  UART Output: (empty)"
        }
    }
} else {
    Write-Host "  WARNING: uart_log.txt not found"
}

Write-Host ""
Write-Host "============================================================"
Write-Host " DONE"
Write-Host "============================================================"
