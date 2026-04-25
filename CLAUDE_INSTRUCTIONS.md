# CLAUDE_INSTRUCTIONS.md — HexaChipsers RV32IMAFB Debug & Doğrulama Projesi

> **Son güncelleme**: 2026-04-17
> **Amaç**: Bu dosya, önceki oturumlarda yapılan tüm işlerin detaylı bir aktarımıdır. Yeni bir oturumda Faz 3 ve Faz 4'e eksiksiz devam edebilmek için tüm bağlam burada bulunmaktadır.

---

## 1. PROJE HAKKINDA

### 1.1 Ne Bu?
HexaChipsers-Core, **32-bit RV32IMAFB RISC-V işlemci çekirdeği** projesidir. Aşağıdaki ISA uzantılarını destekler:
- **I**: Base Integer
- **M**: Multiply/Divide (MUL, MULH, DIV, REM vb.)
- **A**: Atomic (LR/SC, AMO) — `RISCV_ISA_RV32A` define ile koşullu
- **F**: Single-Precision FP — `RISCV_ISA_RV32F` define ile koşullu
- **B**: Bit Manipulation (Zba, Zbb, Zbc, Zbs)

### 1.2 Orijinal Kaynak
mmRISC-1 projesi (M.Maruyama, 2017-2023) baz alınmış, Doğukan Biçer tarafından 2024'te Bit Manipulation uzantısı eklenmiştir.

### 1.3 Hedef Platform
- **FPGA**: Terasic DE10-Lite (Intel Altera MAX 10) — ancak IP olarak Xilinx Artix-7/Spartan-7/Zynq'a da paketlenmiştir
- **SDRAM**: 16-bit veri yolu
- **Çevre birimleri**: UART, I2C (×2), SPI, GPIO (×3), JTAG/cJTAG

### 1.4 Pipeline Mimarisi
5-aşamalı pipeline: **IF → ID → EX → MA → WB**
- 10 yollu data forwarding
- Load-use hazard detection + stall
- FPU stall desteği
- Goldschmidt FDIV/FSQRT (configurable iteration count)

---

## 2. PROJE DİZİN YAPISI

```
HexaChipsers-Core/
├── Verilog Dosyaları/
│   ├── Tanımlamalar/           # defines_core.v, defines_chip.v
│   ├── Cekirdek/
│   │   ├── cpu/                # 9 CPU modülü (aşağıda detay)
│   │   └── HexaCore/           # HexaCore.v, bus_m_ahb.v, csr_mtime.v
│   ├── Ust modul/              # chip_top.v, chip_top_wrap.v, slaves_ahb.v
│   ├── Veriyolu/               # AHB matrix, SDRAM controller
│   └── Cevre Birimleri/        # UART, I2C, SPI, GPIO, cJTAG, Debug, Int_gen
├── Testler/
│   ├── calisma_ortami/
│   │   ├── FPU_test/           # Mevcut FPU test ortamı (BSP: link.ld, startup.S, uart, xprintf)
│   │   ├── integration_tests/  # ← FAZ 3: C/Assembly entegrasyon testleri
│   │   │   ├── src/
│   │   │   │   ├── test_common.h          # Test framework (PASS/FAIL macros)
│   │   │   │   ├── test_recursive.c       # 22 test — Fibonacci, Quicksort, Hanoi, Ackermann
│   │   │   │   ├── test_fpu_math.c        # ~40 test — Pi, Taylor, sqrt, IEEE754, FMADD
│   │   │   │   ├── test_bitmanip_edge.c   # ~55 test — Zba/Zbb/Zbc/Zbs, SHAMT fix
│   │   │   │   ├── test_pipeline_stress.c # 10 test — RAW/WAW/WAR, FPU stall
│   │   │   │   ├── test_interrupt.c       # ~12 test — CSR, timer IRQ, MSTATUS.FS
│   │   │   │   └── test_atomic.c          # ~18 test — LR/SC, CAS, AMO
│   │   │   ├── build/                     # Derleme çıktıları (.elf, .hex, _mem.v)
│   │   │   ├── Makefile                   # GNU Make build (MSYS2/WSL)
│   │   │   ├── build.ps1                  # PowerShell build (Windows native)
│   │   │   └── hex2verilog.py             # HEX→Verilog $readmemh dönüştürücü
│   │   ├── Coremark_test/
│   │   ├── Dhrystone_test/
│   │   └── FreeRTOS_test/
│   ├── trace_verification/     # ← FAZ 4: Golden model trace doğrulama
│   │   ├── Dockerfile          # Spike ISS Docker image
│   │   ├── run_spike.sh        # Spike çalıştırma scripti
│   │   └── trace_compare.py    # RTL vs Spike trace karşılaştırma
│   ├── bit_manuplation_test.c  # Mevcut B-ext test kodu
│   └── pi_sayisi_main.c        # Pi hesaplama testi
├── Araçlar/
│   ├── hex2mif/                # hex2v.exe (Linux binary), hex2v.c kaynak kodu
│   ├── openocd/                # OpenOCD konfigürasyonu
│   └── Eclipse IDE/            # IDE ayarları
├── verification/               # ← BİZİM OLUŞTURDUĞUMUZ (Faz 2 + 3 + 4 + 5)
│   ├── tb_bitmanip_fix.sv      # 25 test — Bit manip shamt fix doğrulama
│   ├── tb_fpu_compare_fix.sv   # 41 test — FEQ/FLT/FLE ±0 fix doğrulama
│   ├── tb_integration.sv       # Full-system testbench (CHIP_TOP_WRAP + UART)
│   ├── tb_trace_logger.sv      # RTL instruction trace logger
│   ├── run_tests.tcl           # Vivado xsim batch script (Faz 2)
│   ├── run_integration.tcl     # Vivado xsim full-system sim script (Faz 3)
│   ├── package_ip.tcl          # Vivado IP paketleme scripti
│   ├── xsim_work/              # xsim çalışma dizini
│   └── ip_repo/                # Paketlenmiş IP
│       └── hexachipsers_rv32imafb_1.0/
│           ├── component.xml   # IP-XACT metadata (47KB)
│           ├── src/            # Tüm RTL kaynak dosyaları
│           └── xgui/           # Vivado GUI
├── CLAUDE_INSTRUCTIONS.md      # Bu dosya
└── impl_plan.txt               # Orijinal Implementation plan
```

---

## 3. CPU MODÜL HİYERARŞİSİ

| Modül | Dosya | Boyut | İşlev |
|-------|-------|-------|-------|
| `CPU_TOP` | `cpu_top.v` | 51KB | CPU üst seviye, modül bağlantıları |
| `CPU_FETCH` | `cpu_fetch.v` | 34KB | FIFO tabanlı instruction fetch (8 entry) |
| `CPU_PIPELINE` | `cpu_pipeline.v` | 147KB | Pipeline kontrol, decode, hazard detection |
| `CPU_DATAPATH` | `cpu_datapath.v` | 39KB | ALU, register file, forwarding mux |
| `CPU_FPU32` | `cpu_fpu32.v` | 157KB | IEEE 754 FPU (FADD/FSUB/FMUL/FDIV/FSQRT/FMADD) |
| `CPU_CSR` | `cpu_csr.v` | 36KB | CSR yönetimi (mstatus, mie, mtvec, mepc vb.) |
| `CPU_CSR_INT` | `cpu_csr_int.v` | 22KB | Interrupt CSR'ları (mintcurlvl, nested interrupt) |
| `CPU_CSR_DBG` | `cpu_csr_dbg.v` | 39KB | Debug CSR'ları (dcsr, dpc, trigger) |
| `CPU_DEBUG` | `cpu_debug.v` | 32KB | JTAG debug modülü (abstract command, halt/resume) |

---

## 4. TAMAMLANAN FAZLAR

### 4.1 FAZ 1: RTL Kod İncelemesi — 7 KRİTİK BUG DÜZELTİLDİ

#### Bug #1: ALUFUNC_SLLI bit genişliği
- **Dosya**: `defines_core.v:306`
- **Sorun**: 7-bit literal (`6'b0010001`) 6-bit field'da → sessiz truncation
- **Fix**: `6'b010001` olarak düzeltildi

#### Bug #2: ALUFUNC_BINVI duplicate opcode
- **Dosya**: `defines_core.v:346`
- **Sorun**: `ALUFUNC_BINVI = 6'b011000` = `ALUFUNC_BINV` → BINVI hiç çalışmıyordu
- **Fix**: `ALUFUNC_BINVI = 6'b011010` (unique değer)

#### Bug #3: C.FSWSP yanlış kaynak register
- **Dosya**: `cpu_pipeline.v:3073`
- **Sorun**: `id_fpu_src1 = ALU_GPR | x2` (GPR) olmalıydı `ALU_FPR | ...` (FPR)
- **Fix**: `id_fpu_src1 = ALU_FPR | {9'h0, pipe_id_code[6:2]}`

#### Bug #4-8: Bit manipulation immediate komutları yanlış operand
- **Dosya**: `cpu_datapath.v:386-392, 419`
- **Sorun**: BCLRI, BEXTI, BINVI, BSETI, RORI komutları `EX_ALU_IMM[4:0]` kullanıyordu ama pipeline `id_alu_shamt` set ediyor, `id_alu_imm` set etmiyordu → shamt her zaman 0
- **Fix**: `EX_ALU_IMM[4:0]` → `EX_ALU_SHAMT[4:0]`

#### Bug #9: FEQ +0.0 == -0.0 yanlış
- **Dosya**: `cpu_fpu32.v:1379-1386`
- **Sorun**: Bitwise karşılaştırma `0x00000000 != 0x80000000` → false, IEEE 754'e göre true olmalı
- **Fix**: `(a[30:0] == 31'h0) & (b[30:0] == 31'h0)` zero-check eklendi

#### Bug #10: FLT -0.0 < +0.0 yanlış
- **Dosya**: `cpu_fpu32.v:1388-1400`
- **Sorun**: Sign bit kontrolü -0 < +0 = true döndürüyordu, IEEE 754'e göre false olmalı
- **Fix**: Aynı zero-check, result = 0

#### Bug #11: FLE -0.0 <= +0.0 yanlış
- **Dosya**: `cpu_fpu32.v:1402-1414`
- **Sorun**: Sign bit kontrolü eksikti
- **Fix**: Zero-check eklendi, result = 1 (eşitlik dahil)

#### İnceleme Sonucunda Temiz Bulunan Modüller
- `cpu_fetch.v` — FIFO, state machine, bus handshake ✅
- `cpu_csr.v` — MSTATUS, interrupt priority, counter ✅
- `cpu_csr_int.v` — Nested interrupt ✅
- `cpu_debug.v` — CSR routing ✅

#### Belgelenen Zararsız Sorunlar
- RV64 talimatları (CLZW, CPOPW, CTZW, ROLW, RORW vb.) RV32 pipeline'da decode ediliyor — zararsız
- `ALUFUNC_MAXU_` / `ALUFUNC_MINU_` / `ALUFUNC_MAX` / `ALUFUNC_MIN` dead code — kullanılmıyor
- `SH2ADD.UW` funct7 typo (0010100 yerine 0010000) — RV64-only olduğu için zararsız

---

### 4.2 FAZ 2: Unit Tests — 66/66 PASSED

#### Test 1: tb_bitmanip_fix.sv (25/25 PASSED)
- BCLRI, BEXTI, BINVI, BSETI, RORI komutlarının doğruluğu
- Shamt=0 vs shamt≠0 regresyon testi
- Vivado 2025.1 xsim ile çalıştırıldı

#### Test 2: tb_fpu_compare_fix.sv (41/41 PASSED)
- FEQ: 14 test (+0/-0, NaN, Inf, normal)
- FLT: 15 test (±0, signed compare, NaN, denormal)
- FLE: 12 test (±0, boundary, NaN)

#### RTL Compilation Check (6/6 OK)
```
xvlog -sv -i <defines_dir> cpu_datapath.v   → OK
xvlog -sv -i <defines_dir> cpu_fetch.v      → OK
xvlog -sv -i <defines_dir> cpu_pipeline.v   → OK
xvlog -sv -i <defines_dir> cpu_fpu32.v      → OK
xvlog -sv -i <defines_dir> cpu_csr.v        → OK
xvlog -sv -i <defines_dir> cpu_csr_int.v    → OK
```
> **NOT**: `-sv` flag'i gerekli (unnamed block declarations). Verilog-2001 modunda declare hataları alınır.

---

### 4.3 FAZ 5: IP Paketleme — TAMAMLANDI

- **IP Adı**: `hexachipsers_rv32imafb`
- **Konum**: `verification/ip_repo/hexachipsers_rv32imafb_1.0/`
- **component.xml**: 47KB, Vivado IP Integrator uyumlu
- **Top module**: `CHIP_TOP_WRAP`
- **Hedef FPGA**: Artix-7, Spartan-7, Zynq

---

## 5. TAMAMLANAN FAZLAR (DEVAMI)

### 5.1 FAZ 3: C & Assembly Entegrasyon Testleri — 6/6 DERLEME BAŞARILI

#### Toolchain
- **xPack riscv-none-elf-gcc v15.2.0-1** — `C:\xpack-riscv-none-elf-gcc\` altında kurulu
- `-march=rv32imaf_zba_zbb_zbc_zbs -mabi=ilp32f -O2`
- BSP: Mevcut `FPU_test/src/` dosyaları (startup.S, uart.c, xprintf.c, gpio.c, system.c, libc-hooks.c)
- `-lgcc -lc -lgcc` ile soft-float double ve strlen bağımlılıkları çözüldü

#### Oluşturulan Test Programları (`Testler/calisma_ortami/integration_tests/`)

| Test | Dosya | Test Sayısı | Kapsam |
|------|-------|-------------|--------|
| Recursive | `test_recursive.c` | 22 | Fibonacci(20), Quicksort(64), Hanoi(15), Ackermann(3,4), Factorial(12) |
| FPU Math | `test_fpu_math.c` | ~40 | Pi(Leibniz), sin/cos/exp(Taylor), sqrt(Newton), ±0/NaN/Inf, FMADD/FMSUB, FCVT |
| Bit Manip | `test_bitmanip_edge.c` | ~55 | Tüm Zba/Zbb/Zbc/Zbs, boundary values, SHAMT fix validation |
| Pipeline | `test_pipeline_stress.c` | 10 | RAW/WAW/WAR hazards, load-use, MUL/DIV, FPU stall |
| Interrupt | `test_interrupt.c` | ~12 | MISA, MHARTID, MSCRATCH, MCYCLE, timer IRQ, MSTATUS.FS, MTVEC |
| Atomic | `test_atomic.c` | ~18 | LR/SC, CAS pattern, AMO (swap/add/and/or/xor/min/max) |

#### Build Altyapısı
- `build.ps1` — PowerShell build scripti (Windows native)
- `Makefile` — GNU Make build scripti (MSYS2/WSL ile kullanılabilir)
- `hex2verilog.py` — Python HEX→Verilog $readmemh dönüştürücü (hex2v.exe Linux-only olduğu için)
- `test_common.h` — Test framework (TEST_CHECK, TEST_CHECK_EQ, TEST_CHECK_FLOAT, TEST_SUMMARY macros)

#### Derleme Komutu (PowerShell)
```powershell
$env:PATH = "C:\xpack-riscv-none-elf-gcc\xpack-riscv-none-elf-gcc-15.2.0-1\bin;$env:PATH"
riscv-none-elf-gcc -march=rv32imaf_zba_zbb_zbc_zbs -mabi=ilp32f -O2 `
    -nostartfiles -T link.ld `
    startup.S uart.c xprintf.c gpio.c system.c libc-hooks.c test_xxx.c `
    -lgcc -lc -lgcc -o test_xxx.elf
riscv-none-elf-objcopy -O ihex test_xxx.elf test_xxx.hex
python hex2verilog.py test_xxx.hex test_xxx_mem.v
```

#### ÖNEMLİ NOTLAR
1. `test_interrupt.c` kendi `INT_Timer_Handler`, `INT_IRQ_Handler` ve `my_int_init` fonksiyonlarını içerir — BSP `interrupt.c` ile derlenmemeli (duplicate symbol hatası)
2. `test_atomic.c` `__riscv_atomic` ifdef ile koşullu derlenebilir
3. `hex2v.exe` Linux ELF binary'sidir; Windows'ta `hex2verilog.py` kullanılmalı
4. Tüm testler UART üzerinden sonuç yazdırır ve `0xDEADDEAD` magic word ile simülasyonu durdurur

---

### 5.2 FAZ 4: Golden Model Trace Doğrulama — ALTYAPI HAZIR

#### Docker + Spike ISS
- `Testler/trace_verification/Dockerfile` — Ubuntu 22.04 + Spike build
- `Testler/trace_verification/run_spike.sh` — Docker container'da ELF çalıştırma
- Spike komut: `spike --isa=rv32imaf_zba_zbb_zbc_zbs --log-commits test.elf`

#### RTL Trace Logger
- `verification/tb_trace_logger.sv` — Her retire instruction'ı loglar
- Format: `PC_HEX INSTR_HEX xN DATA_HEX`
- **NOT**: DUT sinyal yolları (signal paths) gerçek CHIP_TOP_WRAP hiyerarşisine göre uyarlanmalı

#### Trace Karşılaştırma
- `Testler/trace_verification/trace_compare.py` — RTL vs Spike trace diff
- Mismatch durumunda önceki 10 instruction context gösterir
- Çıktı: `trace_result.txt` rapor dosyası

#### Çalıştırma (Docker gerekli)
```bash
# 1. Docker image build
cd Testler/trace_verification
docker build -t hexachipsers-spike .

# 2. Spike trace oluştur
docker run --rm -v /path/to/build:/workspace hexachipsers-spike \
    spike --isa=rv32imaf_zba_zbb_zbc_zbs --log-commits /workspace/test.elf 2>&1 > spike_trace.log

# 3. Karşılaştır
python trace_compare.py --rtl rtl_trace.txt --spike spike_trace.log
```

#### Vivado Full-System Testbench
- `verification/tb_integration.sv` — CHIP_TOP_WRAP instantiation template
- `verification/run_integration.tcl` — Vivado xsim batch runner
- UART TX monitor ile test çıktılarını yakalar

---

## 6. VIVADO KULLANIM BİLGİLERİ

### 6.1 Vivado Konumu
```
C:\Xilinx\2025.1\Vivado\bin\
```

### 6.2 Sık Kullanılan Komutlar
```powershell
# SV compile
& "C:\Xilinx\2025.1\Vivado\bin\xvlog.bat" -sv -i <include_dir> <file.v>

# Elaborate
& "C:\Xilinx\2025.1\Vivado\bin\xelab.bat" work.<top_module> -s <sim_name> -debug off

# Simulate
& "C:\Xilinx\2025.1\Vivado\bin\xsim.bat" <sim_name> -runall

# Vivado batch
& "C:\Xilinx\2025.1\Vivado\bin\vivado.bat" -mode batch -source <script.tcl> -notrace
```

### 6.3 Include Path
- Ana tanımlama dosyası: `Verilog Dosyaları/Tanımlamalar/defines_core.v`
- Chip tanımlama: `Verilog Dosyaları/Tanımlamalar/defines_chip.v`
- RTL dosyalarında `\`include "defines_core.v"` kullanılıyor → `-i` ile include dizini belirtmek gerekli
- **ÖNEMLİ**: xsim Verilog modunda `-sv` flag'i olmadan "declarations in unnamed block" hatası alınır

---

## 7. MEVCUT TEST ALTYAPISI (Projede Hazır)

### 7.1 FPU Test Ortamı
`Testler/calisma_ortami/FPU_test/` altında tam bir C geliştirme ortamı var:
- `startup.S` — Boot kodu (vector table, trap handler, BSS clear, GP/SP init, FPU init)
- `link.ld` — Linker script (ROM @ 0x90000000, RAM @ 0x88000000)
- `common.h` — Donanım adresleri (#define ADDR_xxx)
- `csr.h` — CSR read/write makroları (`read_csr()`, `write_csr()`)
- `uart.c/h` — UART sürücüsü
- `xprintf.c/h` — Tam printf implementasyonu (FP dahil)
- `interrupt.c/h` — Interrupt init ve handler
- `gpio.c/h` — GPIO sürücüsü  
- `float.c/h` — FPU test fonksiyonları
- `main.c` — Ana test programı

### 7.2 Donanım Adresleri (common.h'den)
```c
#define ADDR_UART_TXD  0xA0000000  // UART TX data
#define ADDR_UART_RXD  0xA0000004  // UART RX data
#define ADDR_UART_STS  0xA0000008  // UART status
// GPIO, I2C, SPI adresleri de mevcut
```

### 7.3 hex2v Aracı
`Araçlar/hex2mif/hex2v.exe` — Intel HEX formatını Verilog `$readmemh` formatına çevirir. Derleme sonrası ELF → HEX → V dönüşümü:
```bash
riscv32-unknown-elf-objcopy -O ihex test.elf test.hex
hex2v.exe test.hex test_mem.v
```

---

## 8. KRİTİK TEKNİK DETAYLAR

### 8.1 ALU Fonksiyon Kodları (defines_core.v)
6-bit `id_alu_func` field'ı kullanılıyor. Önemli kodlar:
```verilog
`define ALUFUNC_ADD   6'b000000
`define ALUFUNC_SUB   6'b000001
`define ALUFUNC_SLLI  6'b010001  // düzeltildi (eski: 7-bit)
`define ALUFUNC_BINV  6'b011000
`define ALUFUNC_BINVI 6'b011010  // düzeltildi (eski: BINV ile aynı 011000)
// ... 60+ fonksiyon kodu
```

### 8.2 Pipeline Sinyalleri
```verilog
// Pipeline enable
PIPE_ID_ENABLE, PIPE_EX_ENABLE, PIPE_MA_ENABLE, PIPE_WB_ENABLE

// ALU
EX_ALU_SRC1[13:0], EX_ALU_SRC2[13:0]  // kaynak register
EX_ALU_DST1[13:0], EX_ALU_DST2[13:0]  // hedef register
EX_ALU_FUNC[5:0]                        // ALU fonksiyon kodu
EX_ALU_IMM[31:0]                        // immediate
EX_ALU_SHAMT[4:0]                       // shift amount

// FPU
ID_FPU_STALL                             // FPU pipeline stall
SET_MSTATUS_FS_DIRTY                     // FPU register yazıldı
```

### 8.3 FPU İç Yapısı (cpu_fpu32.v)
- 79-bit "inner" format: `{sign[1], expo[12], frac[66]}`
- Pipeline: `pipe_i` (input) → `pipe_m` (multiply) → `pipe_a` (add) → `pipe_f` (finalize)
- FDIV: Goldschmidt algoritması, `csr_div_loop` ile configurable iterasyon
- FSQRT: Goldschmidt varyantı, `csr_sqr_loop` ile configurable iterasyon
- Special number handling: Ayrı sub-modüller (FADD_SPECIAL_NUMBER, FMUL_SPECIAL_NUMBER, vb.)

### 8.4 Interrupt Önceliklendirme (cpu_csr.v)
```
MEI (Machine External) > MSI (Machine Software) > MTI (Machine Timer) > IRQn (16-79)
```

### 8.5 xsim Bilinen Sınırlamalar
- `cpu_csr_dbg.v` ve `cpu_debug.v` xsim Verilog modunda array port hatası verir — Vivado synthesis'de sorun yok
- `cpu_fpu32.v:2101,2214` unnamed block declaration — `-sv` flag ile düzelir

---

## 9. İLERİ SÜREÇTE YAPILMASI GEREKENLER

> **MEVCUT DURUM** (Nisan 2026):
> - Faz 1 (RTL Bug Fix): ✅ Tamamlandı — 4 kritik hata düzeltildi
> - Faz 2 (Unit Test): ✅ Tamamlandı — 66/66 test geçti
> - Faz 3 (Entegrasyon Testleri): ✅ Tamamlandı — 6/6 test programı derlendi
> - Faz 4 (Trace Doğrulama): ✅ Altyapı hazır, Spike trace üretildi, karşılaştırma doğrulandı
> - Faz 5 (IP Paketleme): ✅ Tamamlandı — Vivado IP Integrator uyumlu paket hazır
> - **Kalan**: Vivado tam sistem simülasyonu (tek eksik adım)

---

### 9.1 EKSİK: Vivado Tam Sistem Simülasyonu

Bu adım, `CHIP_TOP_WRAP` portlarını `tb_integration.sv` içinde eşleştirmeyi gerektirir.

#### 9.1.1 CHIP_TOP_WRAP Port Listesini Bul
```powershell
# Port listesini çıkart:
grep -n "^\s*input\|^\s*output\|^\s*inout" "Verilog Dosyaları\Ust modul\chip_top_wrap.v" | head -40
```

#### 9.1.2 `tb_integration.sv` İçinde DUT'u Aç
`verification/tb_integration.sv` dosyasında `CHIP_TOP_WRAP u_dut (...)` bloğu **template olarak** yorumlu bırakılmıştır. Gerçek port isimlerine göre şu satırları düzenle:
```systemverilog
CHIP_TOP_WRAP u_dut (
    .CLK50    (clk),
    .RESETn   (reset_n),
    // ... gerçek portları buraya ekle
);
```

#### 9.1.3 Instruction Memory Yükleme Mekanizmasını Bul
`chip_top_wrap.v` içinde ROM/instruction memory parametresi nasıl yükleniyor?
- `$readmemh` ile `initial` bloğu mu?
- `parameter MEM_INIT_FILE` var mı?
- AXI/AHB üzerinden boot ROM mu?
Buna göre testbench'i adapte et.

#### 9.1.4 Simülasyonu Çalıştır
```powershell
$env:PATH = "C:\Xilinx\2025.1\Vivado\bin;$env:PATH"
# Test programını seç (örn: test_recursive)
$memFile = "Testler\calisma_ortami\integration_tests\build\test_recursive_mem.v"
vivado -mode batch -source "verification\run_integration.tcl" -tclargs $memFile -notrace
```

#### 9.1.5 UART Çıktısını Doğrula
Simülasyon UART TX'i `uart_log.txt` dosyasına yazar. Beklenen çıktı:
```
<<< HexaChipsers Recursive Algorithm Test >>>
[PASS] Fibonacci(20) recursive = 0x00001a6d
...
ALL TESTS PASSED
```

#### 9.1.6 RTL Trace Logger'ı Adapte Et
`verification/tb_trace_logger.sv` içindeki sinyal yolları gerçek DUT hiyerarşisine göre güncellenmeli:
```systemverilog
// Gerçek sinyal yollarını bul ve uncomment et:
wire wb_valid = u_dut.<hex_core_path>.PIPE_WB_ENABLE;
wire [31:0] wb_pc    = u_dut.<hex_core_path>.pipe_ex_pc;
wire [31:0] wb_instr = u_dut.<hex_core_path>.pipe_id_code;
wire [4:0]  wb_rd    = u_dut.<hex_core_path>.EX_ALU_DST1[4:0];
```

---

### 9.2 SPIKE TRACE İLE RTL KARŞILAŞTIRMA (Tam Akış)

Altyapı hazır, bu adımlar tam sistem simülasyonu tamamlandıktan sonra çalıştırılacak:

```powershell
# Adım 1: Spike trace üret (Docker mevcut)
$build = "Testler\calisma_ortami\integration_tests\build"
docker run --rm `
    --name spike-run `
    -v "${build}:/workspace" `
    hexachipsers-spike `
    timeout 30 spike `
        --isa=rv32imaf_zba_zbb_zbc_zbs `
        -m0x90000000:0x20000,0x88000000:0xC000 `
        --log-commits `
        /workspace/test_recursive.elf `
    2> "Testler\trace_verification\spike_recursive.log"

# Adım 2: Vivado simülasyonundan RTL trace al
# (tb_trace_logger.sv'den üretilir)

# Adım 3: Karşılaştır
python Testler\trace_verification\trace_compare.py `
    --rtl  "verification\xsim_integration\rtl_trace.txt" `
    --spike "Testler\trace_verification\spike_recursive.log" `
    --max-errors 20 `
    --output "Testler\trace_verification\trace_result_recursive.txt"
```

**Beklenen Çıktı:**
```
[PASS] ALL XXXX INSTRUCTIONS MATCH
```
Mismatch varsa → `trace_result.txt` içindeki context'e bakarak hangi instruction'dan itibaren RTL ile Spike'ın ayrıştığını tespit et.

---

### 9.3 COREMARK / DHRYSTONE BENCHMARK (Opsiyonel)

Mevcut `Testler/calisma_ortami/Coremark_test/` ve `Dhrystone_test/` dizinleri var.

#### Derleme
```powershell
$env:PATH = "C:\xpack-riscv-none-elf-gcc\xpack-riscv-none-elf-gcc-15.2.0-1\bin;$env:PATH"
# coremark için:
riscv-none-elf-gcc -march=rv32imaf_zba_zbb_zbc_zbs -mabi=ilp32f -O3 `
    -DITERATIONS=1000 -DPERFORMANCE_RUN=1 `
    -T ..\FPU_test\link.ld `
    startup.S uart.c xprintf.c coremark_main.c core_*.c `
    -lgcc -lc -lgcc -o coremark.elf
```

#### Referans Performans Hedefi
- RV32IMAFB @ 50 MHz: **>1.0 CoreMark/MHz** hedef
- Gerçek FPGA'da ölçüm için UART üzerinden cycle count raporla

---

### 9.4 FREERTOS ENTEGRASYONU (İleri Aşama)

`Testler/calisma_ortami/FreeRTOS_test/` dizini hazır.

Gereksinimler:
1. FreeRTOS kaynak kodunu `FreeRTOS-Kernel/` altına koy
2. `FreeRTOSConfig.h` donanım adreslerine göre yapılandır
3. Timer interrupt (`csr_mtime`) tick source olarak kullan
4. Heap implementasyonu: `heap_4.c` (RAM: 48KB)
5. Demo task'leri UART üzerinden logla

---

### 9.5 FPGA PROGRAMLAMA VE DOĞRULAMA

Simülasyon geçtikten sonra gerçek silicon doğrulaması:

```tcl
# Vivado implementation
open_project hexachipsers.xpr
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
write_bitstream -force hexachipsers.bit

# Program FPGA
open_hw_manager
connect_hw_server
program_hw_devices [get_hw_devices]
```

**FPGA Test Akışı:**
1. Bit dosyasını FPGA'ya yükle
2. UART terminal aç (115200 baud)
3. Reset'i bırak
4. UART'tan `ALL TESTS PASSED` çıktısını bekle
5. JTAG ile register state doğrula (OpenOCD)

---

### 9.6 SONRAKI HATA OLASILIĞI NOKTALARI

Vivado simülasyonunda veya FPGA'da karşılaşılabilecek olası sorunlar:

| Belirti | Olası Neden | Çözüm |
|---------|-------------|-------|
| CPU hiç boot etmiyor | RAM/ROM adresi yanlış | `link.ld` vs hardware address map karşılaştır |
| UART çıktı yok | UART init başarısız | UART baud rate divisor hesapla (`CLK/115200`) |
| Yanlış hesaplama sonuçları | Pipeline hazard kalmış | RTL vs Spike trace compare ile tespit et |
| FPU sonuçları yanlış | Rounding mode sorunu | `fcsr` FFLAGS register'ını kontrol et |
| Interrupt çalışmıyor | MTVEC vektörleme | `mtvec` mode bit (vectored=1) doğrula |
| Spike trace uzuyor (infinite loop) | UART periferik Spike'ta yok | `--max-insns` flag ile limitle |
| Compressed inst decode hatası | C-extension decode bug | `cpu_pipeline.v` C-inst decode'u kontrol et |

---

### 9.7 PROJE TAMAMLANMA KRİTERLERİ

Projenin "production-grade" sayılması için aşağıdakilerin tamamlanması gerekir:

- [x] Tüm RTL bug'ları düzeltildi (Faz 1)
- [x] 66 unit test geçti (Faz 2)
- [x] 6 entegrasyon test programı derlendi (Faz 3)
- [x] Spike golden model trace altyapısı kuruldu (Faz 4)
- [x] IP paketleme tamamlandı (Faz 5)
- [ ] **Vivado tam sistem simülasyonu tüm 6 test için geçti**
- [ ] **RTL trace == Spike golden model (0 mismatch)**
- [ ] **Gerçek FPGA'da UART çıktısı doğrulandı** *(opsiyonel)*

---

## 10. YAPILAN DEĞİŞİKLİKLERİN TAM LİSTESİ

### Değiştirilen Dosyalar (FAZ 1)

| Dosya | Satır | Değişiklik |
|-------|-------|------------|
| `defines_core.v` | 306 | `ALUFUNC_SLLI 6'b0010001` → `6'b010001` |
| `defines_core.v` | 346 | `ALUFUNC_BINVI 6'b011000` → `6'b011010` |
| `cpu_pipeline.v` | 3073 | `ALU_GPR \| x2` → `ALU_FPR \| pipe_id_code[6:2]` |
| `cpu_datapath.v` | 386-392 | BCLRI/BEXTI/BINVI/BSETI `EX_ALU_IMM` → `EX_ALU_SHAMT` |
| `cpu_datapath.v` | 419 | RORI `EX_ALU_IMM` → `EX_ALU_SHAMT` |
| `cpu_fpu32.v` | 1382 | FEQ: `+0==-0` zero-check eklendi |
| `cpu_fpu32.v` | 1391 | FLT: `±0` zero-check eklendi |
| `cpu_fpu32.v` | 1405 | FLE: `±0` zero-check eklendi |

### Oluşturulan Dosyalar (FAZ 2 & 5)

| Dosya | Amaç |
|-------|------|
| `verification/tb_bitmanip_fix.sv` | 25 test — bit manipulation immediate fix doğrulama |
| `verification/tb_fpu_compare_fix.sv` | 41 test — FEQ/FLT/FLE IEEE 754 ±0 fix doğrulama |
| `verification/run_tests.tcl` | Vivado xsim batch test script |
| `verification/package_ip.tcl` | Vivado IP paketleme Tcl scripti |
| `verification/ip_repo/...` | Paketlenmiş IP (31 RTL + component.xml) |

---

## 11. BİLİNEN SORUNLAR VE UYARILAR

1. **Türkçe dosya yolları**: `Verilog Dosyaları`, `Tanımlamalar` vb. Türkçe karakterler Vivado batch'te sorun çıkarabilir. IP paketlemede bu nedenle dosyalar `ip_repo/src/` altına ASCII path'e kopyalandı.

2. **xsim vs Vivado Synthesis farkları**: `cpu_csr_dbg.v` ve `cpu_debug.v` xsim'de array port hatası verir. Bu bir xsim parser sınırlamasıdır, sentezde sorun olmaz.

3. **`-sv` flag zorunluluğu**: Mevcut RTL'de unnamed block içinde `integer i;` gibi declaration'lar var. xsim Verilog modunda hata verir ama `-sv` (SystemVerilog) modunda sorunsuz çalışır.

4. **RV64 talimatları**: Pipeline'da CLZW, CPOPW, CTZW, ROLW, RORW gibi RV64 talimatları decode ediliyor. Zararsız (RV32 assembly'de bu instruction'lar üretilmez) ama temizlik yapılabilir.

5. **B-extension ISA string**: GCC `-march` flag'inde `rv32imaf` yerine `rv32imaf_zba_zbb_zbc_zbs` kullanılmalı (B bireysel alt-uzantılardan oluşur).

---

## 12. REFERANS: ISA CONFIGURATION

`defines_core.v` dosyasında ISA yapılandırması:
```verilog
`define RISCV_ISA_RV32A  // Atomic ISA — koşullu derleme ile etkinleştirilir
`define RISCV_ISA_RV32F  // Single Floating Point ISA — koşullu derleme ile etkinleştirilir
// B-extension her zaman etkin (define ile koşullu değil)
```

MISA register encoding:
```
bit[0]  A - Atomic
bit[2]  C - Compressed (her zaman etkin)
bit[5]  F - Single FP (koşullu)
bit[8]  I - Integer (her zaman)
bit[12] M - Multiply/Divide (her zaman)
bit[13] N - User-level Interrupt
bit[31:30] = 01 (XLEN=32)
```
