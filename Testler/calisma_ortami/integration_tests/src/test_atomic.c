//===========================================================
// HexaChipsers RV32IMAFB — Atomic Operations Test
//-----------------------------------------------------------
// Tests: LR.W/SC.W, AMO instructions
// Conditional compilation with RISCV_ISA_RV32A
//===========================================================

#include "test_common.h"

//-----------------------------
// Test data in RAM
//-----------------------------
static volatile uint32_t atomic_var __attribute__((aligned(4))) = 0;
static volatile uint32_t atomic_arr[4] __attribute__((aligned(16))) = {0, 0, 0, 0};

#ifdef __riscv_atomic

//-----------------------------
// 1. Basic LR/SC Test
//-----------------------------
static void test_lr_sc_basic(void) {
    printf("--- LR/SC Basic Test ---\n");

    uint32_t result, sc_result;

    // LR.W / SC.W success case
    atomic_var = 42;
    asm volatile (
        "lr.w  %0, (%2)\n"       // load-reserved
        "addi  %0, %0, 8\n"      // modify
        "sc.w  %1, %0, (%2)\n"   // store-conditional
        : "=&r"(result), "=&r"(sc_result)
        : "r"(&atomic_var)
        : "memory"
    );
    TEST_CHECK_EQ("LR/SC success: SC returns 0", sc_result, 0);
    TEST_CHECK_EQ("LR/SC success: value = 50", atomic_var, 50);
}

//-----------------------------
// 2. SC Failure (no prior LR)
// SC without matching LR should fail
//-----------------------------
static void test_sc_failure(void) {
    printf("\n--- SC Failure Test ---\n");

    uint32_t sc_result;
    uint32_t val = 999;

    // First do LR, then invalidate reservation, then SC
    atomic_var = 100;

    asm volatile (
        "lr.w   t0, (%1)\n"        // load-reserved atomic_var
        "sw     zero, 0(%1)\n"     // regular store invalidates reservation
        "sc.w   %0, %2, (%1)\n"   // SC should fail (reservation broken)
        : "=r"(sc_result)
        : "r"(&atomic_var), "r"(val)
        : "t0", "memory"
    );
    TEST_CHECK("SC fail: returns non-zero", sc_result != 0);
}

//-----------------------------
// 3. LR/SC Retry Loop (CAS pattern)
// Compare-and-swap implemented with LR/SC
//-----------------------------
static uint32_t cas(volatile uint32_t *addr, uint32_t expected, uint32_t desired) {
    uint32_t old_val, sc_res;
    asm volatile (
        "1:\n"
        "    lr.w  %0, (%2)\n"
        "    bne   %0, %3, 2f\n"     // if *addr != expected, bail out
        "    sc.w  %1, %4, (%2)\n"
        "    bnez  %1, 1b\n"         // if SC failed, retry
        "2:\n"
        : "=&r"(old_val), "=&r"(sc_res)
        : "r"(addr), "r"(expected), "r"(desired)
        : "memory"
    );
    return old_val;
}

static void test_cas_pattern(void) {
    printf("\n--- CAS (Compare-And-Swap) Pattern ---\n");

    atomic_var = 100;

    // CAS succeeds: expected matches
    uint32_t old = cas(&atomic_var, 100, 200);
    TEST_CHECK_EQ("CAS success: old value", old, 100);
    TEST_CHECK_EQ("CAS success: new value", atomic_var, 200);

    // CAS fails: expected doesn't match
    old = cas(&atomic_var, 100, 300); // expected=100 but actual=200
    TEST_CHECK_EQ("CAS fail: old value (unchanged)", old, 200);
    TEST_CHECK_EQ("CAS fail: value unchanged", atomic_var, 200);
}

//-----------------------------
// 4. AMO Instructions
//-----------------------------
static void test_amo_swap(void) {
    printf("\n--- AMOSWAP Test ---\n");

    uint32_t old;
    atomic_var = 0xAAAAAAAA;

    asm volatile (
        "amoswap.w %0, %1, (%2)"
        : "=r"(old) : "r"(0xBBBBBBBB), "r"(&atomic_var) : "memory"
    );
    TEST_CHECK_EQ("AMOSWAP: old value", old, 0xAAAAAAAA);
    TEST_CHECK_EQ("AMOSWAP: new value", atomic_var, 0xBBBBBBBB);
}

static void test_amo_add(void) {
    printf("\n--- AMOADD Test ---\n");

    uint32_t old;
    atomic_var = 100;

    asm volatile (
        "amoadd.w %0, %1, (%2)"
        : "=r"(old) : "r"(50), "r"(&atomic_var) : "memory"
    );
    TEST_CHECK_EQ("AMOADD: old value", old, 100);
    TEST_CHECK_EQ("AMOADD: new value (100+50)", atomic_var, 150);
}

static void test_amo_and(void) {
    printf("\n--- AMOAND Test ---\n");

    uint32_t old;
    atomic_var = 0xFF00FF00;

    asm volatile (
        "amoand.w %0, %1, (%2)"
        : "=r"(old) : "r"(0x0F0F0F0F), "r"(&atomic_var) : "memory"
    );
    TEST_CHECK_EQ("AMOAND: old value", old, 0xFF00FF00);
    TEST_CHECK_EQ("AMOAND: new value", atomic_var, 0x0F000F00);
}

static void test_amo_or(void) {
    printf("\n--- AMOOR Test ---\n");

    uint32_t old;
    atomic_var = 0x00FF00FF;

    asm volatile (
        "amoor.w %0, %1, (%2)"
        : "=r"(old) : "r"(0xF0F0F0F0), "r"(&atomic_var) : "memory"
    );
    TEST_CHECK_EQ("AMOOR: old value", old, 0x00FF00FF);
    TEST_CHECK_EQ("AMOOR: new value", atomic_var, 0xF0FFF0FF);
}

static void test_amo_xor(void) {
    printf("\n--- AMOXOR Test ---\n");

    uint32_t old;
    atomic_var = 0xAAAAAAAA;

    asm volatile (
        "amoxor.w %0, %1, (%2)"
        : "=r"(old) : "r"(0xFFFFFFFF), "r"(&atomic_var) : "memory"
    );
    TEST_CHECK_EQ("AMOXOR: old value", old, 0xAAAAAAAA);
    TEST_CHECK_EQ("AMOXOR: new value (~A)", atomic_var, 0x55555555);
}

static void test_amo_min_max(void) {
    printf("\n--- AMOMIN/AMOMAX Test ---\n");

    uint32_t old;

    // AMOMIN (signed)
    atomic_var = 100;
    asm volatile (
        "amomin.w %0, %1, (%2)"
        : "=r"(old) : "r"((int32_t)-50), "r"(&atomic_var) : "memory"
    );
    TEST_CHECK_EQ("AMOMIN: old value", old, 100);
    TEST_CHECK_EQ("AMOMIN: new = min(100,-50)", atomic_var, (uint32_t)(-50));

    // AMOMAX (signed)
    atomic_var = (uint32_t)(-50);
    asm volatile (
        "amomax.w %0, %1, (%2)"
        : "=r"(old) : "r"(200), "r"(&atomic_var) : "memory"
    );
    TEST_CHECK_EQ("AMOMAX: new = max(-50,200)", atomic_var, 200);

    // AMOMINU (unsigned)
    atomic_var = 100;
    asm volatile (
        "amominu.w %0, %1, (%2)"
        : "=r"(old) : "r"(50), "r"(&atomic_var) : "memory"
    );
    TEST_CHECK_EQ("AMOMINU: new = minu(100,50)", atomic_var, 50);

    // AMOMAXU (unsigned)
    atomic_var = 100;
    asm volatile (
        "amomaxu.w %0, %1, (%2)"
        : "=r"(old) : "r"(200), "r"(&atomic_var) : "memory"
    );
    TEST_CHECK_EQ("AMOMAXU: new = maxu(100,200)", atomic_var, 200);
}

#endif /* __riscv_atomic */

//-----------------------------
// Main
//-----------------------------
void main(void) {
    TEST_INIT();

    printf("\n<<< HexaChipsers Atomic Operations Test >>>\n\n");

#ifdef __riscv_atomic
    test_lr_sc_basic();
    test_sc_failure();
    test_cas_pattern();
    test_amo_swap();
    test_amo_add();
    test_amo_and();
    test_amo_or();
    test_amo_xor();
    test_amo_min_max();
#else
    printf("[SKIP] Atomic extension not enabled in toolchain flags\n");
    printf("       Recompile with -march=rv32imafc_zba_... to enable\n");
    test_pass_count = 1; // count as pass (skipped)
#endif

    TEST_SUMMARY("ATOMIC OPERATIONS");
}

//===========================================================
// End of Program
//===========================================================
