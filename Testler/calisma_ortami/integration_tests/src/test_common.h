//===========================================================
// HexaChipsers RV32IMAFB — Integration Test Common Header
//-----------------------------------------------------------
// Provides PASS/FAIL macros and test framework utilities
// shared across all integration tests.
//===========================================================

#ifndef TEST_COMMON_H
#define TEST_COMMON_H

#include <stdint.h>
#include "common.h"
#include "csr.h"
#include "uart.h"
#include "xprintf.h"
#include "gpio.h"
#include "interrupt.h"
#include "system.h"

//-----------------------------
// Test Framework
//-----------------------------
static volatile uint32_t test_pass_count = 0;
static volatile uint32_t test_fail_count = 0;
static volatile uint32_t test_total      = 0;

#define TEST_INIT() do { \
    GPIO_Init(); \
    UART_Init(); \
    test_pass_count = 0; \
    test_fail_count = 0; \
    test_total      = 0; \
} while(0)

#define TEST_CHECK(name, condition) do { \
    test_total++; \
    if (condition) { \
        test_pass_count++; \
        printf("[PASS] %s\n", (name)); \
    } else { \
        test_fail_count++; \
        printf("[FAIL] %s\n", (name)); \
    } \
} while(0)

#define TEST_CHECK_EQ(name, actual, expected) do { \
    test_total++; \
    if ((actual) == (expected)) { \
        test_pass_count++; \
        printf("[PASS] %s = 0x%08x\n", (name), (unsigned)(actual)); \
    } else { \
        test_fail_count++; \
        printf("[FAIL] %s: got 0x%08x, expected 0x%08x\n", \
               (name), (unsigned)(actual), (unsigned)(expected)); \
    } \
} while(0)

// Float comparison with tolerance
static inline int float_eq(float a, float b, float tol) {
    float diff = a - b;
    if (diff < 0) diff = -diff;
    return diff <= tol;
}

#define TEST_CHECK_FLOAT(name, actual, expected, tolerance) do { \
    test_total++; \
    if (float_eq((actual), (expected), (tolerance))) { \
        test_pass_count++; \
        printf("[PASS] %s\n", (name)); \
    } else { \
        test_fail_count++; \
        printf("[FAIL] %s\n", (name)); \
    } \
} while(0)

#define TEST_SUMMARY(suite_name) do { \
    printf("\n========================================\n"); \
    printf("  %s RESULTS\n", (suite_name)); \
    printf("  Total:  %lu\n", (unsigned long)test_total); \
    printf("  Passed: %lu\n", (unsigned long)test_pass_count); \
    printf("  Failed: %lu\n", (unsigned long)test_fail_count); \
    printf("========================================\n"); \
    if (test_fail_count == 0) { \
        printf("ALL TESTS PASSED\n"); \
    } else { \
        printf("SOME TESTS FAILED\n"); \
    } \
    /* Simulation stop marker */ \
    *(volatile uint32_t *)0xFFFFFFFC = 0xDEADDEAD; \
} while(0)

#endif /* TEST_COMMON_H */
//===========================================================
// End of Program
//===========================================================
