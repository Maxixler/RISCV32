//===========================================================
// HexaChipsers RV32IMAFB — Recursive Algorithm Test
//-----------------------------------------------------------
// Tests: Fibonacci, Quicksort, Tower of Hanoi, Ackermann
// Purpose: Stack-heavy recursive calls, pipeline stress
//===========================================================

#include "test_common.h"

//-----------------------------
// 1. Fibonacci (recursive)
//-----------------------------
static int fib_recursive(int n) {
    if (n <= 1) return n;
    return fib_recursive(n - 1) + fib_recursive(n - 2);
}

//-----------------------------
// 2. Fibonacci (iterative)
//-----------------------------
static int fib_iterative(int n) {
    if (n <= 1) return n;
    int a = 0, b = 1, c;
    for (int i = 2; i <= n; i++) {
        c = a + b;
        a = b;
        b = c;
    }
    return b;
}

//-----------------------------
// 3. Quicksort
//-----------------------------
static void swap(int *a, int *b) {
    int t = *a;
    *a = *b;
    *b = t;
}

static int partition(int arr[], int lo, int hi) {
    int pivot = arr[hi];
    int i = lo - 1;
    for (int j = lo; j < hi; j++) {
        if (arr[j] <= pivot) {
            i++;
            swap(&arr[i], &arr[j]);
        }
    }
    swap(&arr[i + 1], &arr[hi]);
    return i + 1;
}

static void quicksort(int arr[], int lo, int hi) {
    if (lo < hi) {
        int p = partition(arr, lo, hi);
        quicksort(arr, lo, p - 1);
        quicksort(arr, p + 1, hi);
    }
}

//-----------------------------
// 4. Tower of Hanoi
//-----------------------------
static volatile int hanoi_moves = 0;

static void hanoi(int n, int from, int to, int aux) {
    if (n == 1) {
        hanoi_moves++;
        return;
    }
    hanoi(n - 1, from, aux, to);
    hanoi_moves++;
    hanoi(n - 1, aux, to, from);
}

//-----------------------------
// 5. Ackermann function
//-----------------------------
static int ackermann(int m, int n) {
    if (m == 0) return n + 1;
    if (n == 0) return ackermann(m - 1, 1);
    return ackermann(m - 1, ackermann(m, n - 1));
}

//-----------------------------
// 6. Factorial
//-----------------------------
static uint32_t factorial(uint32_t n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

//-----------------------------
// Main
//-----------------------------
void main(void) {
    TEST_INIT();

    printf("\n<<< HexaChipsers Recursive Algorithm Test >>>\n\n");

    // --- Fibonacci ---
    int fib20_rec = fib_recursive(20);
    int fib20_iter = fib_iterative(20);
    TEST_CHECK_EQ("Fibonacci(20) recursive",  (uint32_t)fib20_rec,  6765);
    TEST_CHECK_EQ("Fibonacci(20) iterative",  (uint32_t)fib20_iter, 6765);
    TEST_CHECK("Fibonacci recursive==iterative", fib20_rec == fib20_iter);

    int fib10 = fib_recursive(10);
    TEST_CHECK_EQ("Fibonacci(10) recursive", (uint32_t)fib10, 55);

    int fib0 = fib_recursive(0);
    int fib1 = fib_recursive(1);
    TEST_CHECK_EQ("Fibonacci(0)", (uint32_t)fib0, 0);
    TEST_CHECK_EQ("Fibonacci(1)", (uint32_t)fib1, 1);

    // --- Quicksort ---
    {
        #define QS_N 64
        int arr[QS_N];
        // Fill with descending values (worst case for naive pivot)
        for (int i = 0; i < QS_N; i++)
            arr[i] = QS_N - i;

        quicksort(arr, 0, QS_N - 1);

        int sorted = 1;
        for (int i = 1; i < QS_N; i++) {
            if (arr[i] < arr[i - 1]) {
                sorted = 0;
                break;
            }
        }
        TEST_CHECK("Quicksort 64-elem descending", sorted);
        TEST_CHECK_EQ("Quicksort arr[0]",  (uint32_t)arr[0],  1);
        TEST_CHECK_EQ("Quicksort arr[63]", (uint32_t)arr[QS_N-1], QS_N);
    }

    // --- Quicksort already sorted ---
    {
        int arr2[32];
        for (int i = 0; i < 32; i++) arr2[i] = i + 1;
        quicksort(arr2, 0, 31);
        TEST_CHECK_EQ("Quicksort already sorted[0]",  (uint32_t)arr2[0],  1);
        TEST_CHECK_EQ("Quicksort already sorted[31]", (uint32_t)arr2[31], 32);
    }

    // --- Tower of Hanoi ---
    hanoi_moves = 0;
    hanoi(15, 1, 3, 2);
    // 2^15 - 1 = 32767 moves
    TEST_CHECK_EQ("Hanoi(15) moves", (uint32_t)hanoi_moves, 32767);

    hanoi_moves = 0;
    hanoi(10, 1, 3, 2);
    TEST_CHECK_EQ("Hanoi(10) moves", (uint32_t)hanoi_moves, 1023);

    // --- Ackermann ---
    int ack33 = ackermann(3, 3);
    TEST_CHECK_EQ("Ackermann(3,3)", (uint32_t)ack33, 61);

    int ack34 = ackermann(3, 4);
    TEST_CHECK_EQ("Ackermann(3,4)", (uint32_t)ack34, 125);

    int ack20 = ackermann(2, 0);
    TEST_CHECK_EQ("Ackermann(2,0)", (uint32_t)ack20, 3);

    // --- Factorial ---
    TEST_CHECK_EQ("Factorial(0)",  factorial(0),  1);
    TEST_CHECK_EQ("Factorial(1)",  factorial(1),  1);
    TEST_CHECK_EQ("Factorial(5)",  factorial(5),  120);
    TEST_CHECK_EQ("Factorial(10)", factorial(10), 3628800);
    TEST_CHECK_EQ("Factorial(12)", factorial(12), 479001600);

    TEST_SUMMARY("RECURSIVE ALGORITHM");
}

//===========================================================
// End of Program
//===========================================================
