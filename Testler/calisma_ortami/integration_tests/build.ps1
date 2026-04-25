#===========================================================
# HexaChipsers RV32IMAFB — Build Script (PowerShell)
#-----------------------------------------------------------
# Builds all integration test programs using riscv-none-elf-gcc
#===========================================================

param(
    [string]$ToolchainBin = "C:\xpack-riscv-none-elf-gcc\xpack-riscv-none-elf-gcc-15.2.0-1\bin",
    [string]$Test = "all"
)

# Setup paths
$env:PATH = "$ToolchainBin;$env:PATH"
$CROSS = "riscv-none-elf-"
$CC = "${CROSS}gcc"
$OBJCOPY = "${CROSS}objcopy"
$OBJDUMP = "${CROSS}objdump"
$SIZE = "${CROSS}size"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$SrcDir = "$PSScriptRoot\src"
$BspDir = "$PSScriptRoot\..\FPU_test\src"
$BuildDir = "$PSScriptRoot\build"
$LdScript = "$PSScriptRoot\..\FPU_test\link.ld"
$Hex2v = "$ProjectRoot\Araçlar\hex2mif\hex2v.exe"

# Architecture flags
$ARCH = "rv32imaf_zba_zbb_zbc_zbs"
$ABI = "ilp32f"

# Common flags
$CFLAGS = @(
    "-march=$ARCH", "-mabi=$ABI", "-O2",
    "-nostdlib", "-nostartfiles",
    "-ffunction-sections", "-fdata-sections",
    "-Wall", "-Wno-unused-function",
    "-I$BspDir", "-I$SrcDir",
    "-DFPGA"
)

$LDFLAGS = @(
    "-T", "$LdScript",
    "-march=$ARCH", "-mabi=$ABI",
    "-nostdlib", "-nostartfiles",
    "-Wl,--gc-sections",
    "-lgcc", "-lc", "-lgcc"
)

# BSP source files
$BspSrcs = @(
    "$BspDir\startup.S",
    "$BspDir\uart.c",
    "$BspDir\xprintf.c",
    "$BspDir\interrupt.c",
    "$BspDir\gpio.c",
    "$BspDir\system.c"
)

# Test programs
$Tests = @(
    "test_recursive",
    "test_fpu_math",
    "test_bitmanip_edge",
    "test_pipeline_stress",
    "test_interrupt",
    "test_atomic"
)

# Create build directory
if (!(Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HexaChipsers Integration Test Builder"
Write-Host " Toolchain: $CC"
Write-Host " Arch: $ARCH / ABI: $ABI"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify toolchain
try {
    $ver = & $CC --version 2>&1 | Select-Object -First 1
    Write-Host "Toolchain: $ver" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $CC not found!" -ForegroundColor Red
    exit 1
}

$passCount = 0
$failCount = 0
$failedTests = @()

foreach ($testName in $Tests) {
    if ($Test -ne "all" -and $Test -ne $testName) { continue }

    $testSrc = "$SrcDir\${testName}.c"
    $elfFile = "$BuildDir\${testName}.elf"
    $hexFile = "$BuildDir\${testName}.hex"
    $lstFile = "$BuildDir\${testName}.lst"
    $memFile = "$BuildDir\${testName}_mem.v"
    $mapFile = "$BuildDir\${testName}.map"

    if (!(Test-Path $testSrc)) {
        Write-Host "[SKIP] $testName — source not found" -ForegroundColor Yellow
        continue
    }

    Write-Host "==== Building $testName ====" -ForegroundColor Yellow

    # Compile
    $allFlags = $CFLAGS + $LDFLAGS + @("-Wl,-Map=$mapFile", "-o", $elfFile) + $BspSrcs + @($testSrc)

    try {
        $output = & $CC @allFlags 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[FAIL] Compile error:" -ForegroundColor Red
            $output | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            $failCount++
            $failedTests += $testName
            continue
        }
        Write-Host "  Compiled OK" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] Exception: $_" -ForegroundColor Red
        $failCount++
        $failedTests += $testName
        continue
    }

    # Objcopy to hex
    & $OBJCOPY -O ihex $elfFile $hexFile 2>&1 | Out-Null
    Write-Host "  HEX generated: $hexFile"

    # Objdump
    $dumpOutput = & $OBJDUMP -d -S $elfFile 2>&1
    $dumpOutput | Out-File -FilePath $lstFile -Encoding utf8
    Write-Host "  LST generated: $lstFile"

    # Size
    $sizeOutput = & $SIZE $elfFile 2>&1
    Write-Host "  Size:"
    $sizeOutput | ForEach-Object { Write-Host "    $_" }

    # hex2v conversion
    if (Test-Path $Hex2v) {
        try {
            & $Hex2v $hexFile $memFile 2>&1 | Out-Null
            if (Test-Path $memFile) {
                Write-Host "  MEM generated: $memFile" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] hex2v produced no output" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  [WARN] hex2v failed: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARN] hex2v.exe not found at $Hex2v" -ForegroundColor Yellow
    }

    $passCount++
    Write-Host "==== $testName DONE ====" -ForegroundColor Green
    Write-Host ""
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " BUILD SUMMARY"
Write-Host "  Passed: $passCount / $($passCount + $failCount)"
if ($failCount -gt 0) {
    Write-Host "  Failed: $failCount ($($failedTests -join ', '))" -ForegroundColor Red
} else {
    Write-Host "  ALL BUILDS SUCCESSFUL" -ForegroundColor Green
}
Write-Host "========================================" -ForegroundColor Cyan
