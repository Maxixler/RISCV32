//===========================================================
// HexaChipsers RV32IMAFB — FPU Math Integration Test
//-----------------------------------------------------------
// Tests: Pi calculation, Taylor sin/cos/exp, Newton sqrt,
//        NaN/Inf handling, IEEE 754 ±0 comparison, rounding
//===========================================================

#include "test_common.h"

//-----------------------------
// 1. Pi via Leibniz series
//    pi/4 = 1 - 1/3 + 1/5 - 1/7 + ...
//-----------------------------
static float compute_pi_leibniz(int iterations) {
    float sum = 0.0f;
    for (int i = 0; i < iterations; i++) {
        float term = 1.0f / (2.0f * (float)i + 1.0f);
        if (i & 1)
            sum -= term;
        else
            sum += term;
    }
    return 4.0f * sum;
}

//-----------------------------
// 2. Taylor series sin(x)
//    sin(x) = x - x^3/3! + x^5/5! - ...
//-----------------------------
static float taylor_sin(float x, int terms) {
    float result = 0.0f;
    float power  = x;
    float fact   = 1.0f;
    for (int n = 0; n < terms; n++) {
        if (n > 0) {
            power *= x * x;
            fact  *= (float)(2 * n) * (float)(2 * n + 1);
        }
        float term = power / fact;
        if (n & 1)
            result -= term;
        else
            result += term;
    }
    return result;
}

//-----------------------------
// 3. Taylor series cos(x)
//    cos(x) = 1 - x^2/2! + x^4/4! - ...
//-----------------------------
static float taylor_cos(float x, int terms) {
    float result = 0.0f;
    float power  = 1.0f;
    float fact   = 1.0f;
    for (int n = 0; n < terms; n++) {
        if (n > 0) {
            power *= x * x;
            fact  *= (float)(2 * n - 1) * (float)(2 * n);
        }
        float term = power / fact;
        if (n & 1)
            result -= term;
        else
            result += term;
    }
    return result;
}

//-----------------------------
// 4. Taylor series exp(x)
//    e^x = 1 + x + x^2/2! + x^3/3! + ...
//-----------------------------
static float taylor_exp(float x, int terms) {
    float result = 1.0f;
    float term   = 1.0f;
    for (int n = 1; n < terms; n++) {
        term *= x / (float)n;
        result += term;
    }
    return result;
}

//-----------------------------
// 5. Newton-Raphson sqrt
//    x_{n+1} = (x_n + S/x_n) / 2
//-----------------------------
static float newton_sqrt(float s) {
    if (s <= 0.0f) return 0.0f;
    float x = s;
    // 20 iterations for convergence
    for (int i = 0; i < 20; i++) {
        x = (x + s / x) * 0.5f;
    }
    return x;
}

//-----------------------------
// 6. Helper: create special FP values
//-----------------------------
static float make_float(uint32_t bits) {
    union { uint32_t u; float f; } conv;
    conv.u = bits;
    return conv.f;
}

static uint32_t float_bits(float f) {
    union { float f; uint32_t u; } conv;
    conv.f = f;
    return conv.u;
}

//-----------------------------
// Main
//-----------------------------
void main(void) {
    TEST_INIT();

    printf("\n<<< HexaChipsers FPU Math Test >>>\n\n");

    // ==========================================
    //  Pi Calculation
    // ==========================================
    {
        float pi_100   = compute_pi_leibniz(100);
        float pi_1000  = compute_pi_leibniz(1000);
        float pi_10000 = compute_pi_leibniz(10000);
        float pi_ref   = 3.14159265f;

        printf("Pi(100)   = ");
        // Print integer part since we don't have float printf easily
        int pi_int = (int)(pi_100 * 10000);
        printf("%d (x10000)\n", pi_int);

        TEST_CHECK_FLOAT("Pi(100) ~3.13",   pi_100,   pi_ref, 0.02f);
        TEST_CHECK_FLOAT("Pi(1000) ~3.140",  pi_1000,  pi_ref, 0.002f);
        TEST_CHECK_FLOAT("Pi(10000) ~3.1415", pi_10000, pi_ref, 0.0002f);
    }

    // ==========================================
    //  Trigonometric Functions
    // ==========================================
    {
        float pi = 3.14159265f;
        float sin_0     = taylor_sin(0.0f, 10);
        float sin_pi2   = taylor_sin(pi / 2.0f, 12);
        float sin_pi    = taylor_sin(pi, 12);
        float cos_0     = taylor_cos(0.0f, 10);
        float cos_pi2   = taylor_cos(pi / 2.0f, 12);
        float cos_pi    = taylor_cos(pi, 12);

        TEST_CHECK_FLOAT("sin(0) = 0",        sin_0,   0.0f, 1e-5f);
        TEST_CHECK_FLOAT("sin(pi/2) = 1",     sin_pi2, 1.0f, 1e-4f);
        TEST_CHECK_FLOAT("sin(pi) = 0",       sin_pi,  0.0f, 1e-4f);
        TEST_CHECK_FLOAT("cos(0) = 1",        cos_0,   1.0f, 1e-5f);
        TEST_CHECK_FLOAT("cos(pi/2) = 0",     cos_pi2, 0.0f, 1e-3f);
        TEST_CHECK_FLOAT("cos(pi) = -1",      cos_pi, -1.0f, 1e-3f);

        // sin^2 + cos^2 = 1
        float angle = 1.0f; // ~57 degrees
        float s = taylor_sin(angle, 12);
        float c = taylor_cos(angle, 12);
        float identity = s * s + c * c;
        TEST_CHECK_FLOAT("sin^2(1)+cos^2(1)=1", identity, 1.0f, 1e-4f);
    }

    // ==========================================
    //  Exponential Function
    // ==========================================
    {
        float e0  = taylor_exp(0.0f, 15);
        float e1  = taylor_exp(1.0f, 15);
        float em1 = taylor_exp(-1.0f, 15);

        TEST_CHECK_FLOAT("exp(0) = 1",          e0,  1.0f,     1e-5f);
        TEST_CHECK_FLOAT("exp(1) = 2.71828",    e1,  2.71828f, 1e-3f);
        TEST_CHECK_FLOAT("exp(-1) = 0.36788",   em1, 0.36788f, 1e-3f);

        // e^1 * e^-1 = 1
        float product = e1 * em1;
        TEST_CHECK_FLOAT("exp(1)*exp(-1) = 1",  product, 1.0f, 1e-4f);
    }

    // ==========================================
    //  Newton-Raphson Square Root
    // ==========================================
    {
        float sqrt2  = newton_sqrt(2.0f);
        float sqrt4  = newton_sqrt(4.0f);
        float sqrt9  = newton_sqrt(9.0f);
        float sqrt16 = newton_sqrt(16.0f);
        float sqrt0  = newton_sqrt(0.0f);

        TEST_CHECK_FLOAT("sqrt(2) = 1.41421",  sqrt2,  1.41421f, 1e-4f);
        TEST_CHECK_FLOAT("sqrt(4) = 2.0",      sqrt4,  2.0f,     1e-5f);
        TEST_CHECK_FLOAT("sqrt(9) = 3.0",      sqrt9,  3.0f,     1e-5f);
        TEST_CHECK_FLOAT("sqrt(16) = 4.0",     sqrt16, 4.0f,     1e-5f);
        TEST_CHECK_FLOAT("sqrt(0) = 0.0",      sqrt0,  0.0f,     1e-5f);

        // sqrt(x)^2 = x
        float sq = sqrt2 * sqrt2;
        TEST_CHECK_FLOAT("sqrt(2)^2 = 2",      sq,     2.0f,     1e-4f);
    }

    // ==========================================
    //  IEEE 754 Special Values — ±0 Comparison
    //  (Validates Faz 1 FEQ/FLT/FLE fixes)
    // ==========================================
    {
        float pos_zero = make_float(0x00000000); // +0.0
        float neg_zero = make_float(0x80000000); // -0.0

        uint32_t feq_result, flt_result, fle_result;

        // FEQ: +0 == -0 should be TRUE (1)
        asm volatile("feq.s %0, %1, %2" : "=r"(feq_result) : "f"(pos_zero), "f"(neg_zero));
        TEST_CHECK_EQ("FEQ(+0,-0) = 1 (IEEE754)", feq_result, 1);

        // FLT: -0 < +0 should be FALSE (0)
        asm volatile("flt.s %0, %1, %2" : "=r"(flt_result) : "f"(neg_zero), "f"(pos_zero));
        TEST_CHECK_EQ("FLT(-0,+0) = 0 (IEEE754)", flt_result, 0);

        // FLE: -0 <= +0 should be TRUE (1)
        asm volatile("fle.s %0, %1, %2" : "=r"(fle_result) : "f"(neg_zero), "f"(pos_zero));
        TEST_CHECK_EQ("FLE(-0,+0) = 1 (IEEE754)", fle_result, 1);

        // FLT: +0 < -0 should be FALSE
        asm volatile("flt.s %0, %1, %2" : "=r"(flt_result) : "f"(pos_zero), "f"(neg_zero));
        TEST_CHECK_EQ("FLT(+0,-0) = 0 (IEEE754)", flt_result, 0);

        // FLE: +0 <= -0 should be TRUE
        asm volatile("fle.s %0, %1, %2" : "=r"(fle_result) : "f"(pos_zero), "f"(neg_zero));
        TEST_CHECK_EQ("FLE(+0,-0) = 1 (IEEE754)", fle_result, 1);
    }

    // ==========================================
    //  NaN Handling
    // ==========================================
    {
        float qnan = make_float(0x7FC00000); // Quiet NaN
        float snan = make_float(0x7F800001); // Signaling NaN
        float one  = 1.0f;
        float inf  = make_float(0x7F800000); // +Infinity

        uint32_t feq_result;

        // NaN != NaN
        asm volatile("feq.s %0, %1, %2" : "=r"(feq_result) : "f"(qnan), "f"(qnan));
        TEST_CHECK_EQ("FEQ(NaN,NaN) = 0", feq_result, 0);

        // NaN != 1.0
        asm volatile("feq.s %0, %1, %2" : "=r"(feq_result) : "f"(qnan), "f"(one));
        TEST_CHECK_EQ("FEQ(NaN,1.0) = 0", feq_result, 0);

        // +Inf == +Inf
        asm volatile("feq.s %0, %1, %2" : "=r"(feq_result) : "f"(inf), "f"(inf));
        TEST_CHECK_EQ("FEQ(+Inf,+Inf) = 1", feq_result, 1);

        // FCLASS checks
        uint32_t fclass_zero, fclass_nan, fclass_inf;
        asm volatile("fclass.s %0, %1" : "=r"(fclass_zero) : "f"(make_float(0x00000000)));
        asm volatile("fclass.s %0, %1" : "=r"(fclass_nan)  : "f"(qnan));
        asm volatile("fclass.s %0, %1" : "=r"(fclass_inf)  : "f"(inf));
        TEST_CHECK_EQ("FCLASS(+0) = 0x010", fclass_zero, 0x010); // positive zero
        TEST_CHECK_EQ("FCLASS(qNaN) = 0x200", fclass_nan, 0x200); // quiet NaN
        TEST_CHECK_EQ("FCLASS(+Inf) = 0x080", fclass_inf, 0x080); // positive infinity
    }

    // ==========================================
    //  FMADD / FMSUB / FNMADD / FNMSUB
    // ==========================================
    {
        float a = 2.0f, b = 3.0f, c = 1.0f;
        float fmadd_result, fmsub_result;

        // FMADD: a*b + c = 7.0
        asm volatile("fmadd.s %0, %1, %2, %3" : "=f"(fmadd_result) : "f"(a), "f"(b), "f"(c));
        TEST_CHECK_FLOAT("FMADD(2,3,1) = 7.0", fmadd_result, 7.0f, 1e-5f);

        // FMSUB: a*b - c = 5.0
        asm volatile("fmsub.s %0, %1, %2, %3" : "=f"(fmsub_result) : "f"(a), "f"(b), "f"(c));
        TEST_CHECK_FLOAT("FMSUB(2,3,1) = 5.0", fmsub_result, 5.0f, 1e-5f);
    }

    // ==========================================
    //  FCVT conversions
    // ==========================================
    {
        float f_val = 42.75f;
        int32_t i_val;
        uint32_t u_val;

        // FCVT.W.S: float -> int
        asm volatile("fcvt.w.s %0, %1, rtz" : "=r"(i_val) : "f"(f_val));
        TEST_CHECK_EQ("FCVT.W.S(42.75) = 42", (uint32_t)i_val, 42);

        // FCVT.WU.S: float -> unsigned int
        asm volatile("fcvt.wu.s %0, %1, rtz" : "=r"(u_val) : "f"(f_val));
        TEST_CHECK_EQ("FCVT.WU.S(42.75) = 42", u_val, 42);

        // FCVT.S.W: int -> float
        int32_t neg_val = -100;
        float f_from_int;
        asm volatile("fcvt.s.w %0, %1" : "=f"(f_from_int) : "r"(neg_val));
        TEST_CHECK_FLOAT("FCVT.S.W(-100) = -100.0", f_from_int, -100.0f, 1e-5f);
    }

    TEST_SUMMARY("FPU MATH");
}

//===========================================================
// End of Program
//===========================================================
