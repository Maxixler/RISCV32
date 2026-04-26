# HexaChipsers-Core Test Çalıştırma Rehberi

> Son güncelleme: 26 Nisan 2026

---

## İçindekiler

1. [Gereksinler](#gereksinler)
2. [Simülasyon Testleri](#simülasyon-testleri)
3. [FPGA Testleri](#fpga-testleri)
4. [Sorun Giderler](#sorun-giderler)

---

## Gereksinler

### Yazılım Gereksinleri
- **Icarus Verilog** (iverilog) — Basit testler için
- **Vivado XSIM** — Vivado 2025.1+ ile simülasyon
- **RISC-V GNU Toolchain** — RISC-V firmware derlemesi için

### Donanım Gereksinleri
- **Vivado 2025.1+** — Sentez ve bitstream oluşturma
- **Nexys A7-100T** — Hedef FPGA kartı
- **COM5** — USB-JTAG bağlantısı

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

---

### 2. Mevcut Testler

HexaChipsers-Core projesinde mevcut testler:

| Test | Dosya | Açıklama |
|------|------|-----------|
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

## FPGA Testleri

### 1. Vivado Projesi Oluşturma

**Dosya:** `create_nexys_a7.tcl`

**Amaç:** Nexys A7-100T için Vivado projesi oluşturmak.

**Çalıştırma:**

```tcl
# Vivado TCL Console'da çalıştırın
cd C:/Users/DELL/Downloads/HexaChipsers-Core
source create_nexys_a7.tcl
```

**Oluşan Proje:**
- Konum: `C:\Users\DELL\Downloads\HexaChipsers-Core\hexachipsers_nexys_a7\hexachipsers_nexys_a7.xpr`
- Hedef: xc7a100tcsg324-1 (Nexys A7-100T)
- Top: chip_top_wrap

---

### 2. Sentez ve Implementation

**Vivado GUI'da:**

1. **Synthesis Çalıştır:**
   - Flow → Run Synthesis
   - Bitstream oluşturulana kadar bekleyin

2. **Implementation Çalıştır:**
   - Flow → Run Implementation
   - Bitstream oluşturulana kadar bekleyin

3. **Bitstream Oluşturma:**
   - Bitstream oluşturulduğunda `.bit` dosyası oluşur

---

### 3. Hardware Manager ile COM5 Bağlantısı

**Nexys A7-100T → COM5 Bağlantısı:**

| Sinyal | Nexys A7-100T Pin | COM5 Pin |
|--------|------------------|-----------|
| TCK | Y6 | TCK |
| TMS | AA2 | TMS |
| TDI | Y4 | TDI |
| TDO | Y3 | TDO |
| TRSTn | Y5 | TRSTn |

**Bağlantı Adımları:**

1. Vivado'da **Open Hardware Manager**'ı açın
2. **Open Target** → **Auto Connect**'ı seçin
3. COM5'i seçin
4. **Program Device**'ı tıklayın

---

### 4. Firmware Yükleme

**RISC-V Firmware Derleme:**

1. RISC-V GNU toolchain ile firmware derleyin
2. `.mem` formatında bellek dosyası oluşturun
3. Vivado'da `.mem` dosyasını projeye ekleyin
4. Bitstream oluşturun

**Firmware Örneği (DQN kullanımı):**

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

## DQN Register Haritası

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

---

## Sorun Giderler

### Simülasyon Sorunları

**Sorun:** Vivado XSIM bulunamıyorsa:
```bash
# Vivado 2025.1 yolu PATH'e ekleyin
export PATH=/C:/Xilinx/2025.1/Vivado/bin:$PATH
```

**Sorun:** Icarus Verilog bulunamıyorsa:
```bash
# Icarus Verilog yolu PATH'e ekleyin
export PATH=/C:/iverilog/bin:$PATH
```

### FPGA Sorunları

**Sorun:** Bitstream oluşturma başarısız:
- Synthesis hatalarını kontrol edin
- Timing kapanmaları kontrol edin
- Resource kullanımını kontrol edin

**Sorun:** COM5 bağlantısı çalışmıyorsa:
- COM5 sürücüsünü kontrol edin
- USB sürücüsünü kontrol edin
- Vivado Hardware Manager'ı yeniden başlatın

**Sorun:** DQN inference sonuçları beklenmiyorsa:
- Ağırlıkları doğru yüklenmiş mi kontrol edin
- State değerleri doğru yazılmış mı kontrol edin
- STATUS.done flag'ı kontrol edin

---

## Test Sonuçları

| Test | Durum | Sonuç |
|------|-------|--------|
| DQN AHB-Lite Slave | ✅ | Oluşturuldu |
| Vivado Proje Oluşturma | ✅ | Oluşturuldu |
| Nexys A7-100T Constraint | ✅ | Oluşturuldu |
| COM5 Bağlantısı | ⏳ | COM5 ile test edilecek |

---

## Sonraki Adımlar

1. Vivado'yu açın
2. `create_nexys_a7.tcl` script'ini çalıştırın
3. Synthesis ve Implementation çalıştırın
4. Hardware Manager ile COM5'e bağlanın
5. Bitstream'i FPGA'ya yükleyin
6. DQN modülünü test edin
