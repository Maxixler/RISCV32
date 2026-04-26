# HexaChipsers-Core Proje Durumu ve Yapıları

> Son güncelleme: 26 Nisan 2026

---

## Genel Durum

HexaChipsers-Core, **RV32IMAFB** komut setini destekleyen 5-aşamalı pipeline RISC-V çekirdeği etrafında tasarlanmış bir System-on-Chip (SoC) platformudur. Çekirdek, **AXI-Lite** bus altyapısı üzerinden 6 periferal birime erişim sağlar. Ayrıca **DQN Inference Hızlandırıcı** entegre edilmiştir.

### Temel Özellikler

| Özellik | Değer |
|---------|-------|
| **ISA** | RV32IMAFB (RV32I + MUL + DIV + FPU) |
| **Pipeline** | 5-aşamalı (IF → ID → EX → MEM → WB) |
| **Bus** | AHB-Lite (1 master, 11 slave) |
| **Periferaller** | UART, SPI, I2C, GPIO, INTGEN, DQN |
| **Hedef FPGA** | Nexys A7-100T (xc7a100tcsg324-1) |
| **Sistem Saati** | 100 MHz (PLL ile) |
| **Reset** | Aktif-düşük, asenkron |

---

## Tamamlanan İşler

### 1. RISC-V Çekirdeği (rtl/Cekirdek/)

**Modüller:**
- `HexaCore.v` — Ana pipeline modülü
- `cpu_top.v` — CPU üst modülü
- `cpu_csr.v` — CSR kontrol birimi
- `cpu_csr_dbg.v` — Debug CSR'ları
- `cpu_csr_int.v` — Interrupt CSR'ları
- `cpu_debug.v` — Debug modülü
- `cpu_fetch.v` — Instruction fetch
- `bus_m_ahb.v` — AHB master interface

**Özellikler:**
- 5-aşamalı pipeline (IF → ID → EX → MEM → WB)
- MUL ve DIV donanım desteği (RV32IMAFB)
- Debug modülü ile JTAG/cJTAG desteği
- CSR'lar ile mtime ve interrupt kontrolü

### 2. AHB Bus Altyapısı (rtl/Cekirdek/bus/)

**Modüller:**
- `bus_m_ahb.v` — AHB master interface
- `ahb_lite_sdram.v` — SDRAM controller
- `ahb_matrix.v` — AHB matrix (1 master, 11 slave)

**Özellikler:**
- 1 master, 11 slave
- Priority-based arbitration
- Address decoding ve routing

### 3. Periferaller (rtl/Cevre Birimleri/)

#### UART (rtl/Cevre Birimleri/uart/)
- `uart.v` — UART controller
- **Özellikler:** 8N1, 16x oversampling, FIFO, interrupt

#### SPI (rtl/Cevre Birimleri/spi/)
- `spi.v` — SPI controller
- **Özellikler:** Mode 0-3, MSB-first, 4 slave CS, interrupt

#### I2C (rtl/Cevre Birimleri/i2c/)
- `i2c.v` — I2C controller
- **Özellikler:** 7-bit adres, 8-bit veri, open-drain, interrupt

#### GPIO (rtl/Cevre Birimleri/port/)
- `port.v` — GPIO controller
- **Özellikler:** 3 port (GPIO0, GPIO1, GPIO2), 96 GPIO

#### INTGEN (rtl/Cevre Birimleri/int_gen/)
- `int_gen.v` — Interrupt generator
- **Özellikler:** 64 interrupt line, edge detection

#### DQN (rtl/Cevre Birimleri/dqn/)
- `ahb_lite_dqn.v` — AHB-Lite DQN wrapper
- `dqn_core.v` — DQN inference core
- **Özellikler:** 4→16→4 ağ, Q1.15, LeakyReLU, ~33 cycle inference

---

## Adres Haritası

| Bölge | Başlangıç | Bitiş | Boyut | Durum |
|-------|-----------|------|------|-------|
| MTIME | 0x49000000 | 0x4900001F | 32 B | ✅ |
| SDRAM | 0x80000000 | 0x87FFFFFF | 128 MB | ✅ |
| RAMD | 0x88000000 | 0x8FFFFFFF | 128 MB | ✅ |
| RAMI | 0x90000000 | 0x9FFFFFFF | 128 MB | ✅ |
| GPIO | 0xA0000000 | 0xAFFFFFFF | 256 MB | ✅ |
| UART | 0xB0000000 | 0xBFFFFFFF | 256 B | ✅ |
| INTGEN | 0xC0000000 | 0xCFFFFFFF | 256 MB | ✅ |
| I2C0 | 0xD0000000 | 0xD00000FF | 256 B | ✅ |
| I2C1 | 0xD0000100 | 0xD00001FF | 256 B | ✅ |
| SPI | 0xE0000000 | 0xE00000FF | 256 B | ✅ |
| DQN | 0xF0000000 | 0xF00000FF | 256 B | ✅ |

---

## Vivado IP Paketleme ve FPGA Entegrasyonu

### Vivado Proje Oluşturma

**Dosya:** `create_nexys_a7.tcl`

**Hedef:** Nexys A7-100T (xc7a100tcsg324-1)

**Top:** chip_top_wrap

**Constraint Dosyası:** `constraints/nexys_a7_100t.xdc`

**Pin Atamaları:**
- Clock: E3 (100 MHz)
- Reset: C12 (CPU_RESETN)
- USB-UART: D4 (TX), C4 (RX)
- LED[15:0]: H17, K15, J13, N14, R18, V17, U17, U16, V16, T15, U14, T16, V15, V14, V12, V11
- SW[3:0]: J15, L16, M13, R15
- I2C0: C17 (SDA), D17 (SCL)
- I2C1: AA20 (SDA), AB21 (SCL)
- SPI: U14 (SCK), V14 (MOSI), U15 (MISO), W13/V15/U17/V17 (CS[3:0])
- JTAG: Y5 (TRSTn), Y6 (TCK), AA2 (TMS), Y4 (TDI), Y3 (TDO)

### Bitstream Oluşturma

**Vivado GUI'da:**
1. Flow → Run Synthesis
2. Flow → Run Implementation
3. Bitstream oluşturulana kadar bekleyin

**Hardware Manager ile COM5 Bağlantısı:**
1. Open Hardware Manager
2. Open Target → Auto Connect
3. COM5'i seçin
4. Program Device

---

## Simülasyon Testleri

### 1. DQN AHB-Lite Slave Testi

**Dosya:** `verification/tb_dqn_ahb.sv`

**Amaç:** DQN modülünün AHB-Lite slave olarak çalışmasını doğrulamak.

**Çalıştırma:**
```bash
cd verification
iverilog -g2012 -o tb_dqn_ahb tb_dqn_ahb.sv \
    ../"Verilog Dosyalari/Cevre Birimleri/dqn/ahb_lite_dqn.v" \
    ../"Verilog Dosyalari/Cevre Birimleri/dqn/dqn_core.sv"
vvp tb_dqn_ahb
```

**Beklenen Sonuçlar:**
- Reset değerleri doğrulu mu?
- Register yazma/okuma çalışıyor mu?
- Ağırlık yükleme başarılı mı?
- Inference sonucu doğru mu?

### 2. Mevcut Testler

| Test | Dosya | Açıklama | Sonuç |
|------|------|-----------|--------|
| Integration Test | `verification/run_integration.tcl` | SoC entegrasyon testi |
| Bitmanip Test | `verification/tb_bitmanip_fix.sv` | Bit manipülasyon testi |
| FPU Compare Test | `verification/tb_fpu_compare_fix.sv` | FPU karşılaştırma testi |
| Trace Logger | `verification/tb_trace_logger.sv` | İzleme logger testi |

**Integration Test Çalıştırma:**
```bash
cd verification
vivado -mode batch -source run_integration.tcl
```

---

## DQN Inference Hızlandırıcı

### Ağ Mimarisi
- 4 giriş → 16 gizli → 4 çıkış (4→16→4)
- Q1.15 sabit nokta aritmeti
- LeakyReLU aktivasyon (alpha = 0.01)
- ~33 clock cycle inference süresi

### Register Haritası (0xF0000000)

| Offset | İsim | R/W | Açıklama |
|--------|------|-----|----------|
| 0x00 | CTRL | R/W | `[0]` enable, `[1]` start, `[2]` soft_reset, `[3]` wt_load_mode |
| 0x04 | STATUS | R | `[0]` busy, `[1]` done (sticky), `[2]` wt_loaded, `[5:4]` argmax |
| 0x08 | STATE_0 | R/W | `[15:0]` Giriş state[0] Q1.15 |
| 0x0C | STATE_1 | R/W | `[15:0]` Giriş state[1] Q1.15 |
| 0x10 | STATE_2 | R/W | `[15:0]` Giriş state[2] Q1.15 |
| 0x14 | STATE_3 | R/W | `[15:0]` Giriş state[3] Q1.15 |
| 0x18 | QVAL_0 | R | `[15:0]` Çıkış Q-value[0] Q1.15 |
| 0x1C | QVAL_1 | R | `[15:0]` Çıkış Q-value[1] Q1.15 |
| 0x20 | QVAL_2 | R | `[15:0]` Çıkış Q-value[2] Q1.15 |
| 0x24 | QVAL_3 | R | `[15:0]` Çıkış Q-value[3] Q1.15 |
| 0x28 | QVAL_MAX | R | `[15:0]` Maksimum Q-value Q1.15 |
| 0x2C | WT_ADDR | R/W | `[7:0]` Ağırlık adresi (0-147), auto-increment |
| 0x30 | WT_DATA | R/W | `[15:0]` Ağırlık/bias değeri Q1.15 |
| 0x34 | CYCLE_CNT | R | `[15:0]` Inference süresi (clock cycle) |
| 0x38 | VERSION | R | `0x44514E01` ("DQN" + v1) |

### Kullanım Akışı

1. **Ağırlık Yükleme:**
   - CTRL ← 0x09 (enable + wt_load_mode)
   - WT_ADDR ← 0
   - 148 kez WT_DATA yaz (auto-increment)

2. **Inference Başlatma:**
   - STATE_0..3 ← giriş değerleri
   - CTRL ← 0x03 (enable + start pulse)
   - STATUS.done bekley
   - QVAL_0..3 ve QVAL_MAX oku

3. **Sonuçları Okuma:**
   - QVAL_0..3 → çıkarış değerleri
   - QVAL_MAX → maksimum değer
   - CYCLE_CNT → inference süresi
   - STATUS.argmax → en iyi aksiyon

---

## Firmware Geliştirme

### RISC-V Firmware Derleme

1. RISC-V GNU toolchain ile firmware derleyin
2. `.mem` formatında bellek dosyası oluşturun
3. Vivado'da `.mem` dosyasını projeye ekleyin
4. Bitstream oluşturun

### DQN Kullanımı (C Assembly)

```assembly
# DQN başlat
    lui   t0, 0xF000       # t0 = 0xF0000000 (DQN base)

    # Enable + weight load mode
    li    t1, 0x09           # CTRL = 0x09
    sw    t1, 0x00(t0)      # CTRL ← 0x09

    # Ağırlık yükle (148 ağırlık)
    li    t2, 0x00           # WT_ADDR = 0
    li    t3, 0x01           # WT_DATA = 0x01 (örnek)
    sw    t2, 0x2C(t0)      # WT_ADDR ← 0x00
    sw    t3, 0x30(t0)      # WT_DATA ← 0x01
    # ... (148 kez tekrar)

    # Enable only (weight load mode kapat)
    li    t1, 0x01           # CTRL = 0x01
    sw    t1, 0x00(t0)      # CTRL ← 0x01

    # State değerlerini yaz
    li    t4, 0x1000         # STATE_0 = 0x1000
    sw    t4, 0x08(t0)      # STATE_0 ← 0x1000
    # ... (STATE_1, STATE_2, STATE_3)

    # Inference başlat
    li    t5, 0x03           # CTRL = 0x03 (enable + start)
    sw    t5, 0x00(t0)      # CTRL ← 0x03

    # STATUS polling (done bit beklenir)
poll_done:
    lw    t6, 0x04(t0)      # STATUS oku
    andi  t6, t6, 0x02      # done bit kontrolü
    beqz  t6, poll_done

    # Sonuçları oku
    lw    t7, 0x18(t0)      # QVAL_0
    lw    t8, 0x28(t0)      # QVAL_MAX
```

---

## Kritik Bugfix Geçmişi

### Pipeline ext_stall halt detection (ÇÖZÜLDÜ)
- **Problem:** JAL x0,0 sonsuz döngüsünde pipeline sürekli flush yapıyor → WB'de consecutive PC match 3'e ulaşamıyor
- **Fix:** TB'de ardışık yerine toplam WB commit sayacı kullanıldı (halt_count >= 3)

### Pipeline AXI re-trigger (ÇÖZÜLDÜ)
- **Problem:** AXI Master IF IDLE'a dönüp pipeline hala stall'dayken mem_read/write aktif → yeni transaction başlatıyordu
- **Fix:** `ext_req_sent_q` register ile tek-cycle istek pulsu, ready=1 gelene kadar bekle

### soc_top implicit wire declaration (ÇÖZÜLDÜ)
- **Problem:** Pipeline instance, core_mem_* sinyallerini kullanmadan önce tanımlanmamıştı → XSIM implicit declaration warning
- **Fix:** Sinyal tanımları pipeline instance'ından önce taşındı

### axi_master_if.sv ready_o Race Condition (ÇÖZÜLDÜ)
- **Problem:** TB taskleri `@(posedge clk)` ile sinyal sürüyordu → DUT'un `always_ff @(posedge clk_i)` ile yarış durumu. `ready_o=1` IDLE'da mem_read/mem_write assertken bile 1 kalıyordu → task hemen dönüyordu.
- **RTL Fix:** `S_IDLE'`da `ready_o=0` when `mem_read_i||mem_write_i` (combinational stall)
- **TB Fix:** Task'lar `@(negedge clk)` ile sinyal sürer → posedge'den önce stable

### dqn_accelerator.sv STATUS register bit eşleme hatası (ÇÖZÜLDÜ — 11 Mart 2026)
- **Problem:** STATUS register read'de `core_argmax` bit [4:3]'te yer alıyordu, belgelenen [5:4] pozisyonu yerine `wt_loaded` ile `core_argmax` arasında padding bit eksikti.
- **Belirtiler:** DQN testinde argmax okuma 3 testte başarısız (yanlış bit pozisyonu)
- **RTL Fix:** STATUS read ifadesine `1'b0` padding bit eklendi: `{24'd0, 2'd0, core_argmax, 1'b0, wt_loaded, done_sticky, core_busy}`

### dqn_accelerator.sv done_sticky yarış durumu (ÇÖZÜLDÜ — 11 Mart 2026)
- **Problem:** CTRL yazımı `done_sticky'yi temizleyip `ctrl_start` set ettiğinde, bir sonraki cycle'da `core_done` henüz düşmemiş (önceki inference'dan hala 1) → `if (core_done && !done_sticky)` koşulu anında true → done_sticky tekrar set → polling eski Q-value'larla erken çıkıyor
- **Belirtiler:** Back-to-back inference testlerinde 3 test başarısız (stale Q-value, yanlış argmax)
- **RTL Fix:** Koşula `&& !ctrl_start` eklendi: `if (core_done && !done_sticky && !ctrl_start)` — start pulse gönderildiğinde done_sticky'nin hemen tekrar set edilmesi engellendi

---

## Dizin Yapısı

```
rtl/
  Cekirdek/
    HexaCore.v
    cpu_top.v
    cpu_csr.v
    cpu_csr_dbg.v
    cpu_csr_int.v
    cpu_debug.v
    cpu_fetch.v
    bus_m_ahb.v
    csr_mtime.v
    Tanimlamalar/
      defines_chip.v
      defines_core.v
  Cevre Birimleri/
    i2c/
      i2c.v
      i2c_slave_model.v
    int_gen/
      int_gen.v
    port/
      port.v
    sdram/
      ahb_lite_sdram.v
    spi/
      spi.v
    uart/
      uart.v
    dqn/
      ahb_lite_dqn.v
      dqn_core.v
  Ust modul/
    chip_top.v
    chip_top_wrap.v
    slaves_ahb.v
  verification/
    tb_dqn_ahb.sv
    run_tests.tcl
    run_integration.tcl
    package_ip.tcl
    create_nexys_a7.tcl
  constraints/
    nexys_a7_100t.xdc
```

---

## Konvansiyonlar

- SystemVerilog (IEEE 1800-2017), `timescale 1ns/1ps`
- Active-low async reset: `rstn_i`
- Signal suffix: `_i` input, `_o` output, pipeline stage: F/D/E/M/W
- Parametre: UPPER_SNAKE_CASE
- AHB: ARM AMBA standard naming
- `always_ff` sequential, `always_comb` combinational, `always_latch` KULLANMA
- Paket: `import riscv_pkg::*;`, `import axi_pkg::*;`

---

## Sonraki Adımlar

1. Vivado'yu açın
2. `create_nexys_a7.tcl` script'ini çalıştırın
3. Synthesis ve Implementation çalıştırın
4. Hardware Manager ile COM5'e bağlanın
5. Bitstream'i FPGA'ya yükleyin
6. DQN modülünü test edin

---

## Test Sonuçları

| Test | Durum | Sonuç |
|------|-------|--------|
| DQN AHB-Lite Slave | ✅ | Oluşturuldu |
| Vivado Proje Oluşturma | ✅ | Oluşturuldu |
| Nexys A7-100T Constraint | ✅ | Oluşturuldu |
| COM5 Bağlantısı | ⏳ | COM5 ile test edilecek |

---

## Kaynaklar

- RISC-V ISA: https://riscv.org/specifications/
- AHB-Lite: https://developer.arm.com/docs/ip/ahb-lite/
- Nexys A7-100T: https://digilent.com/products/nexys-a7-100t
