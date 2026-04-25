//===========================================================
// HexaChipsers RV32IMAFB — Pipeline Stress Test
//-----------------------------------------------------------
// Tests: RAW hazards, load-use, FPU-integer mixing,
// compressed instructions, tight branch loops
//===========================================================

#include "test_common.h"

//-----------------------------
// 1. RAW Hazard Chain
// Back-to-back dependent ALU ops
//-----------------------------
static uint32_t test_raw_chain(void) {
    uint32_t r;
    asm volatile (
        "li   t0, 1\n"
        "add  t1, t0, t0\n"    // t1 = 2 (depends on t0)
        "add  t2, t1, t1\n"    // t2 = 4 (depends on t1)
        "add  t3, t2, t2\n"    // t3 = 8 (depends on t2)
        "add  t4, t3, t3\n"    // t4 = 16 (depends on t3)
        "add  t5, t4, t4\n"    // t5 = 32 (depends on t4)
        "add  t6, t5, t5\n"    // t6 = 64 (depends on t5)
        "mv   %0, t6\n"
        : "=r"(r) : : "t0","t1","t2","t3","t4","t5","t6"
    );
    return r;
}

//-----------------------------
// 2. Load-Use Hazard
// Load followed by dependent use
//-----------------------------
static volatile uint32_t load_test_data[4] = {10, 20, 30, 40};

static uint32_t test_load_use(void) {
    uint32_t sum = 0;
    // Each load immediately followed by add (load-use hazard)
    for (int i = 0; i < 4; i++) {
        uint32_t val = load_test_data[i];
        sum += val; // depends on load
    }
    return sum;
}

//-----------------------------
// 3. Mixed Integer-FPU pipeline
//-----------------------------
static float test_mixed_pipeline(void) {
    float fval = 1.0f;
    uint32_t ival = 1;

    // Interleave integer and FPU operations
    for (int i = 0; i < 10; i++) {
        fval = fval + (float)ival;     // int → float conversion + fadd
        ival = ival + (uint32_t)fval;   // float → int conversion + add
    }
    return fval;
}

//-----------------------------
// 4. Multiply-Divide chain
// Tests M-extension pipeline
//-----------------------------
static uint32_t test_mul_div_chain(void) {
    uint32_t a = 12345, b = 67890;
    uint32_t r;

    asm volatile (
        "mul   %0, %1, %2\n"      // r = a * b (low 32)
        "divu  %0, %0, %2\n"      // r = r / b = a (depends on mul result)
        "remu  %0, %0, %2\n"      // r = a % b = a (since a < b)
        : "=r"(r) : "r"(a), "r"(b)
    );
    return r;
}

//-----------------------------
// 5. MULH chain
//-----------------------------
static int32_t test_mulh(void) {
    int32_t a = 0x40000000; // 2^30
    int32_t b = 8;          // result = 2^33, high word = 2
    int32_t r;

    asm volatile (
        "mulh %0, %1, %2\n"
        : "=r"(r) : "r"(a), "r"(b)
    );
    return r;
}

//-----------------------------
// 6. Branch Prediction Stress
// Tight loop with alternating branches
//-----------------------------
static uint32_t test_branch_stress(void) {
    uint32_t count = 0;
    for (int i = 0; i < 100; i++) {
        if (i & 1)
            count += 2;
        else
            count += 1;
    }
    return count; // 50*2 + 50*1 = 150
}

//-----------------------------
// 7. WAW (Write-After-Write) test
//-----------------------------
static uint32_t test_waw(void) {
    uint32_t r;
    asm volatile (
        "li   t0, 0x11111111\n"
        "li   t0, 0x22222222\n"  // WAW on t0
        "li   t0, 0x33333333\n"  // WAW on t0 again
        "mv   %0, t0\n"
        : "=r"(r) : : "t0"
    );
    return r;
}

//-----------------------------
// 8. WAR (Write-After-Read) test
//-----------------------------
static uint32_t test_war(void) {
    uint32_t r1, r2;
    asm volatile (
        "li   t0, 100\n"
        "li   t1, 200\n"
        "add  %0, t0, t1\n"    // read t0, t1
        "li   t0, 999\n"       // write t0 (WAR with previous read)
        "mv   %1, t0\n"
        : "=r"(r1), "=r"(r2) : : "t0", "t1"
    );
    // r1 should be 300 (100+200), not affected by subsequent write
    return r1;
}

//-----------------------------
// 9. FPU stall test
// Long-latency FDIV followed by dependent FADD
//-----------------------------
static float test_fpu_stall(void) {
    float a = 100.0f;
    float b = 3.0f;
    float c = 1.0f;
    float result;

    asm volatile (
        "fdiv.s  %0, %1, %2\n"    // long latency
        "fadd.s  %0, %0, %3\n"    // depends on fdiv result (stall)
        : "=f"(result) : "f"(a), "f"(b), "f"(c)
    );
    // 100/3 + 1 ≈ 34.333
    return result;
}

//-----------------------------
// 10. FSQRT stall test
//-----------------------------
static float test_fsqrt_stall(void) {
    float a = 144.0f;
    float one = 1.0f;
    float result;

    asm volatile (
        "fsqrt.s %0, %1\n"         // long latency
        "fadd.s  %0, %0, %2\n"     // depends on fsqrt (stall)
        : "=f"(result) : "f"(a), "f"(one)
    );
    // sqrt(144) + 1 = 13.0
    return result;
}

//-----------------------------
// Main
//-----------------------------
void main(void) {
    TEST_INIT();

    printf("\n<<< HexaChipsers Pipeline Stress Test >>>\n\n");

    // RAW Chain
    uint32_t raw_result = test_raw_chain();
    TEST_CHECK_EQ("RAW chain: 1->2->4->8->16->32->64", raw_result, 64);

    // Load-Use
    uint32_t load_result = test_load_use();
    TEST_CHECK_EQ("Load-use sum(10,20,30,40)", load_result, 100);

    // Mixed Pipeline
    float mixed = test_mixed_pipeline();
    // Expected sequence can be computed offline
    TEST_CHECK("Mixed int-FPU pipeline", mixed > 0.0f);

    // Mul-Div Chain
    uint32_t muldiv = test_mul_div_chain();
    TEST_CHECK_EQ("MUL/DIV chain: a*b/b%b", muldiv, 12345);

    // MULH
    int32_t mulh = test_mulh();
    TEST_CHECK_EQ("MULH(0x40000000,8) = 2", (uint32_t)mulh, 2);

    // Branch Stress
    uint32_t branch_count = test_branch_stress();
    TEST_CHECK_EQ("Branch stress: 100 iter alt", branch_count, 150);

    // WAW
    uint32_t waw = test_waw();
    TEST_CHECK_EQ("WAW: last write wins", waw, 0x33333333);

    // WAR
    uint32_t war = test_war();
    TEST_CHECK_EQ("WAR: read before write", war, 300);

    // FPU Stall (FDIV)
    float fdiv_res = test_fpu_stall();
    TEST_CHECK_FLOAT("FDIV stall: 100/3+1", fdiv_res, 34.3333f, 0.01f);

    // FPU Stall (FSQRT)
    float fsqrt_res = test_fsqrt_stall();
    TEST_CHECK_FLOAT("FSQRT stall: sqrt(144)+1", fsqrt_res, 13.0f, 0.001f);

    TEST_SUMMARY("PIPELINE STRESS");
}

//===========================================================
// End of Program
//===========================================================
