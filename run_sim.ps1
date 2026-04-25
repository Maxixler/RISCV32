##############################################################
# HexaChipsers RV32IMAFB  Integration Test Runner (PowerShell)
# Workaround for Vivado path encoding issues
#===========================================================

param(
    [string]$TestName = "test_recursive"
)

# Vivado tools
$VIVADO_ROOT = "C:\Xilinx\2025.1\Vivado\bin"
$XVLOG = "$VIVADO_ROOT\xvlog.bat"
$XELAB = "$VIVADO_ROOT\xelab.bat"
$XSIM  = "$VIVADO_ROOT\xsim.bat"

if (-not (Test-Path $XVLOG)) { Write-Error "xvlog not found"; exit 1}
if (-not (Test-Path $XELAB)) { Write-Error "xelab not found"; exit 1}
if (-not (Test-Path $XSIM))  { Write-Error "xsim not found"; exit 1}

# Base directories
$BASE_DIR  = "c:\Users\DELL\Downloads\HexaChipsers-Core"
$RTL_DIR   = "$BASE_DIR\Verilog Dosyaları"
$DEF_DIR   = "$RTL_DIR\Tanımlamalar"
$CPU_DIR   = "$RTL_DIR\Cekirdek\cpu"
$CORE_DIR  = "$RTL_DIR\Cekirdek\HexaCore"
$TOP_DIR   = "$RTL_DIR\Ust modul"
$PERIPH_DIR= "$RTL_DIR\Cevre Birimleri"
$BUS_DIR   = "$RTL_DIR\Veriyolu"
$VER_DIR   = "$BASE_DIR\verification"
$BUILD_DIR = "$BASE_DIR\Testler\calisma_ortami\integration_tests\build"
$WORK_DIR  = "$VER_DIR\xsim_integration"

if (-not (Test-Path $WORK_DIR)) { New-Item -ItemType Directory $WORK_DIR -Force | Out-Null}
cd $WORK_DIR

Write-Host "=========================================================="
Write-Host " HexaChipsers RV32IMAFB — Full System Integration Test"
Write-Host "=========================================================="
Write-Host " Test: $TestName"
Write-Host " Work Dir: $WORK_DIR"
Write-Host ""

# PHASE 1: COMPILE RTL FILES
Write-Host "--- Phase 1: Compiling RTL ---"

$cpu_files = @(
    "$CPU_DIR\cpu_fetch.v",
    "$CPU_DIR\cpu_pipeline.v",
    "$CPU_DIR\cpu_datapath.v",
    "$CPU_DIR\cpu_csr.v",
    "$CPU_DIR\cpu_csr_int.v",
    "$CPU_DIR\cpu_fpu32.v",
    "$CPU_DIR\cpu_csr_dbg.v",
    "$CPU_DIR\cpu_debug.v",
    "$CPU_DIR\cpu_top.v"
)

$core_files = @(
    "$CORE_DIR\RAM.v",
    "$CORE_DIR\bus_m_ahb.v",
    "$CORE_DIR\csr_mtime.v",
    "$CORE_DIR\HexaCore.v"
)

$top_files = @(
    "$TOP_DIR\slaves_ahb.v",
    "$TOP_DIR\chip_top.v",
    "$TOP_DIR\chip_top_wrap.v"
)

$periph_files = @(
    "$PERIPH_DIR\uart\uart.v",
    "$PERIPH_DIR\uart\sasc\trunk\rtl\verilog\sasc_brg.v",
    "$PERIPH_DIR\uart\sasc\trunk\rtl\verilog\sasc_fifo4.v",
    "$PERIPH_DIR\uart\sasc\trunk\rtl\verilog\sasc_top.v",
    "$PERIPH_DIR\i2c\i2c.v",
    "$PERIPH_DIR\i2c\i2c\trunk\rtl\verilog\i2c_master_bit_ctrl.v",
    "$PERIPH_DIR\i2c\i2c\trunk\rtl\verilog\i2c_master_byte_ctrl.v",
    "$PERIPH_DIR\i2c\i2c\trunk\rtl\verilog\i2c_master_top.v",
    "$PERIPH_DIR\spi\spi.v",
    "$PERIPH_DIR\spi\simple_spi\trunk\rtl\verilog\fifo4.v",
    "$PERIPH_DIR\spi\simple_spi\trunk\rtl\verilog\simple_spi_top.v",
    "$PERIPH_DIR\port\port.v",
    "$PERIPH_DIR\int_gen\int_gen.v",
    "$PERIPH_DIR\debug\debug_cdc.v",
    "$PERIPH_DIR\debug\debug_dm.v",
    "$PERIPH_DIR\debug\debug_dtm_jtag.v",
    "$PERIPH_DIR\debug\debug_top.v"
)

$bus_files = @(
    "$BUS_DIR\ahb_matrix\ahb_arb.v",
    "$BUS_DIR\ahb_matrix\ahb_interconnect.v",
    "$BUS_DIR\ahb_matrix\ahb_master_port.v",
    "$BUS_DIR\ahb_matrix\ahb_slave_port.v",
    "$BUS_DIR\ahb_matrix\ahb_top.v",
    "$BUS_DIR\ahb_sdram\logic\ahb_lite_sdram.v"
)

$all_files = $cpu_files + $core_files + $periph_files + $bus_files + $top_files

$compile_pass = 0
$compile_fail = 0

foreach ($f in $all_files) {
    $fname = Split-Path -Leaf $f
    Write-Host -NoNewline "  Compiling $fname... "
    
    if ($f -match "simple_spi") {
        $spi_inc = "$PERIPH_DIR\spi\simple_spi\trunk\rtl\verilog"
        & $XVLOG -sv -i "$DEF_DIR" -i "$spi_inc" -d SIMULATION --nolog "$f" 2>&1 | Out-Null
    } else {
        & $XVLOG -sv -i "$DEF_DIR" -d SIMULATION --nolog "$f" 2>&1 | Out-Null
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK"
        $compile_pass++
    } else {
        Write-Host "FAIL"
        $compile_fail++
    }
}

Write-Host "  Compile: $compile_pass OK, $compile_fail FAIL"
Write-Host ""

if ($compile_fail -gt 0) {
    Write-Error "Compilation failed!"
    exit 1
}

# PHASE 2: COMPILE TESTBENCH
Write-Host "--- Phase 2: Compiling Testbench ---"

$tb_file = "$VER_DIR\tb_integration.sv"
& $XVLOG -sv -i "$DEF_DIR" -d SIMULATION --nolog "$tb_file" 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Error "Testbench compilation failed!"
    exit 1
}
Write-Host "  Testbench compiled OK"
Write-Host ""

# PHASE 3: ELABORATE
Write-Host "--- Phase 3: Elaborating ---"

& $XELAB work.tb_integration -s tb_sim -debug off --nolog --timescale "1ns/1ps" 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Error "Elaboration failed!"
    exit 1
}
Write-Host "  Elaboration OK"
Write-Host ""

# PHASE 4: RUN TEST
Write-Host "--- Phase 4: Running $TestName ---"

$memh_src = "$BUILD_DIR\${TestName}_rom.memh"
$memh_dst = "$WORK_DIR\rom.memh"

if (-not (Test-Path $memh_src)) {
    Write-Error "ROM file not found: $memh_src"
    exit 1
}

Copy-Item -Path $memh_src -Destination $memh_dst -Force
Write-Host "  Loaded: $(Split-Path -Leaf $memh_src)"

$uart_log = "$WORK_DIR\uart_log.txt"
if (Test-Path $uart_log) { Remove-Item $uart_log}

Write-Host "  Running simulation..."
& $XSIM tb_sim -runall --nolog 2>&1 | Out-Null

if (Test-Path $uart_log) {
    $content = Get-Content $uart_log -Raw
    $test_log = "$WORK_DIR\uart_${TestName}.txt"
    Copy-Item -Path $uart_log -Destination $test_log -Force
    
    if ($content -match "ALL TESTS PASSED") {
        Write-Host ("  Test $TestName: PASSED")
        Write-Host ""
        Write-Host "  Test Output:"
        Write-Host $content
    } elseif ($content -match "FAIL") {
        Write-Host ("  Test $TestName: FAILED")
        Write-Host ""
        Write-Host "  UART Output:"
        Write-Host $content
        exit 1
    } else {
        Write-Host ("  Test $TestName: INCOMPLETE")
        Write-Host ""
        Write-Host "  UART Output (first 1000 chars):"
        Write-Host $content.Substring(0, [Math]::Min(1000, $content.Length))
    }
} else {
    Write-Error "uart_log.txt not found after simulation!"
    exit 1
}

Write-Host ""
Write-Host "=========================================================="
Write-Host " Test completed successfully"
Write-Host "=========================================================="
