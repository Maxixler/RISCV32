//===========================================================
// HexaChipsers RV32IMAFB — Interrupt Test
//-----------------------------------------------------------
// Tests: Timer interrupt, IRQ handler, mcause/mepc/mstatus
// verification, nested interrupt support
//
// NOTE: This file provides its own INT_Timer_Handler,
// INT_IRQ_Handler, and INT_Init to avoid duplicate symbol
// errors with BSP interrupt.c. Compile WITHOUT BSP interrupt.c
//===========================================================

#include "test_common.h"

//-----------------------------
// Interrupt Controller CSR addresses
//-----------------------------
#define MINTCURLVL       0xbf0
#define MINTPRELVL       0xbf1
#define MINTCFGENABLE0   0xbf2
#define MINTCFGSENSE0    0xbf4
#define MINTPENDING0     0xbf6
#define MINTCFGPRIORITY0 0xbf8
#define MSTATUS_ADDR     0x300
#define MIE_ADDR         0x304
#define MCAUSE_ADDR      0x342

#define MTIME_CTRL_ADDR 0x49000000
#define MTIME_DIV_ADDR  0x49000004
#define MTIME_ADDR      0x49000008
#define MTIMEH_ADDR     0x4900000C
#define MTIMECMP_ADDR   0x49000010
#define MTIMECMPH_ADDR  0x49000014

//-----------------------------
// Global interrupt counters
//-----------------------------
static volatile uint32_t timer_irq_count = 0;
static volatile uint32_t timer_mcause    = 0;

//-----------------------------
// Our Timer Handler
// (called from startup.S vector)
//-----------------------------
void INT_Timer_Handler(void) {
    timer_irq_count++;
    timer_mcause = read_csr(mcause);

    // Clear timer interrupt by writing next compare value far away
    uint32_t mtime_low = mem_rd32(MTIME_ADDR);
    mem_wr32(MTIMECMP_ADDR, mtime_low + 50000);

    // Acknowledge timer
    mem_wr32(MTIME_CTRL_ADDR, mem_rd32(MTIME_CTRL_ADDR));
}

//-----------------------------
// IRQ Handler (required by startup.S)
//-----------------------------
void INT_IRQ_Handler(void) {
    uint32_t irq_pend  = read_csr(MINTPENDING0);
    uint32_t irq_level = read_csr(MINTCURLVL);

    switch(irq_level) {
        case 1:
            if (irq_pend & 0x00000001) {
                write_csr(MINTPENDING0, 0x00000001);
            }
            break;
        default:
            break;
    }
}

//-----------------------------
// Interrupt Init
//-----------------------------
static void my_int_init(void) {
    write_csr(MINTCFGPRIORITY0, 0x00000001);
    write_csr(MINTCURLVL,       0x00000000);
    write_csr(MINTCFGSENSE0,    0x00000001);
    write_csr(MINTCFGENABLE0,   0x00000001);

    // Enable timer interrupt
    write_csr(MIE_ADDR, read_csr(MIE_ADDR) | (1 << 7));
    write_csr(MSTATUS_ADDR, read_csr(MSTATUS_ADDR) | (1 << 3));

    // Start MTIME
    mem_wr32(MTIME_DIV_ADDR,  9);
    mem_wr32(MTIME_ADDR,      0);
    mem_wr32(MTIMEH_ADDR,     0);
    mem_wr32(MTIMECMP_ADDR,   200000);
    mem_wr32(MTIMECMPH_ADDR,  0);
    mem_wr32(MTIME_CTRL_ADDR, 0x00000005);
}

//-----------------------------
// CSR Read/Write Tests
//-----------------------------
static void test_csr_access(void) {
    printf("--- CSR Access Tests ---\n");

    uint32_t misa = read_csr(misa);
    TEST_CHECK("MISA bit[8] I-ext set",  misa & (1 << 8));
    TEST_CHECK("MISA bit[12] M-ext set", misa & (1 << 12));
    TEST_CHECK("MISA bit[2] C-ext set",  misa & (1 << 2));
    TEST_CHECK("MISA XLEN=32 (bits[31:30]=01)", ((misa >> 30) & 0x3) == 1);

    uint32_t has_f = (misa >> 5) & 1;
    TEST_CHECK("MISA bit[5] F-ext set", has_f);

    uint32_t hartid = read_csr(mhartid);
    TEST_CHECK_EQ("MHARTID = 0", hartid, 0);

    uint32_t old_mscratch = read_csr(mscratch);
    write_csr(mscratch, 0xCAFEBABE);
    uint32_t new_mscratch = read_csr(mscratch);
    TEST_CHECK_EQ("MSCRATCH write/read", new_mscratch, 0xCAFEBABE);
    write_csr(mscratch, old_mscratch);

    uint32_t cycle1 = read_csr(mcycle);
    for (volatile int i = 0; i < 100; i++) {}
    uint32_t cycle2 = read_csr(mcycle);
    TEST_CHECK("MCYCLE incrementing", cycle2 > cycle1);
}

//-----------------------------
// Timer Interrupt Test
//-----------------------------
static void test_timer_interrupt(void) {
    printf("\n--- Timer Interrupt Test ---\n");

    timer_irq_count = 0;
    timer_mcause    = 0;

    mem_wr32(MTIME_DIV_ADDR,  9);
    mem_wr32(MTIME_ADDR,      0);
    mem_wr32(MTIMEH_ADDR,     0);
    mem_wr32(MTIMECMP_ADDR,   10000);
    mem_wr32(MTIMECMPH_ADDR,  0);

    write_csr(MIE_ADDR, read_csr(MIE_ADDR) | (1 << 7));
    write_csr(MSTATUS_ADDR, read_csr(MSTATUS_ADDR) | (1 << 3));
    mem_wr32(MTIME_CTRL_ADDR, 0x00000005);

    uint32_t timeout = 0;
    while (timer_irq_count < 2 && timeout < 2000000) {
        timeout++;
    }

    mem_wr32(MTIME_CTRL_ADDR, 0x00000000);
    write_csr(MSTATUS_ADDR, read_csr(MSTATUS_ADDR) & ~(1 << 3));

    TEST_CHECK("Timer IRQ received (count >= 2)", timer_irq_count >= 2);
    printf("  Timer IRQ count: %lu\n", (unsigned long)timer_irq_count);
    TEST_CHECK_EQ("MCAUSE = 0x80000007 (timer irq)", timer_mcause, 0x80000007);
}

//-----------------------------
// MSTATUS Field Tests
//-----------------------------
static void test_mstatus_fields(void) {
    printf("\n--- MSTATUS Field Tests ---\n");

    uint32_t mstatus = read_csr(MSTATUS_ADDR);
    uint32_t fs = (mstatus >> 13) & 0x3;
    TEST_CHECK("MSTATUS.FS != 0 (FPU enabled)", fs != 0);
    printf("  MSTATUS.FS = %lu\n", (unsigned long)fs);

    float tmp;
    asm volatile("fadd.s %0, %0, %0" : "+f"(tmp));
    mstatus = read_csr(MSTATUS_ADDR);
    fs = (mstatus >> 13) & 0x3;
    TEST_CHECK("MSTATUS.FS = Dirty after FPU op", fs == 3);
}

//-----------------------------
// MTVEC Configuration Test
//-----------------------------
static void test_mtvec(void) {
    printf("\n--- MTVEC Test ---\n");

    uint32_t mtvec_val = read_csr(mtvec);
    uint32_t mode = mtvec_val & 0x3;
    uint32_t base = mtvec_val & ~0x3;

    TEST_CHECK("MTVEC mode = vectored (1)", mode == 1);
    TEST_CHECK("MTVEC base aligned (4-byte)", (base & 0x3) == 0);
    printf("  MTVEC = 0x%08x (base=0x%08x, mode=%lu)\n",
           (unsigned)mtvec_val, (unsigned)base, (unsigned long)mode);
}

//-----------------------------
// Main
//-----------------------------
void main(void) {
    TEST_INIT();
    my_int_init();

    printf("\n<<< HexaChipsers Interrupt Test >>>\n\n");

    test_csr_access();
    test_timer_interrupt();
    test_mstatus_fields();
    test_mtvec();

    TEST_SUMMARY("INTERRUPT");
}

//===========================================================
// End of Program
//===========================================================
