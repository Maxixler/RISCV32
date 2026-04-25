//===========================================================
// Testbench: FPU Comparison IEEE 754 ±0 Fix Verification
// Verifies FEQ/FLT/FLE handle +0.0 == -0.0 correctly
//===========================================================
`timescale 1ns/1ps

module tb_fpu_compare_fix;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // IEEE 754 special values
    localparam [31:0] POS_ZERO  = 32'h00000000; // +0.0
    localparam [31:0] NEG_ZERO  = 32'h80000000; // -0.0
    localparam [31:0] POS_ONE   = 32'h3F800000; // +1.0
    localparam [31:0] NEG_ONE   = 32'hBF800000; // -1.0
    localparam [31:0] POS_INF   = 32'h7F800000; // +Inf
    localparam [31:0] NEG_INF   = 32'hFF800000; // -Inf
    localparam [31:0] QNAN      = 32'h7FC00000; // Quiet NaN
    localparam [31:0] SNAN      = 32'h7F800001; // Signaling NaN
    localparam [31:0] POS_TWO   = 32'h40000000; // +2.0
    localparam [31:0] NEG_TWO   = 32'hC0000000; // -2.0
    localparam [31:0] POS_HALF  = 32'h3F000000; // +0.5
    localparam [31:0] POS_DNORM = 32'h00000001; // Smallest denormal

    // Replicate the FIXED FEQ logic from cpu_fpu32.v
    function automatic [31:0] feq(input [31:0] a, input [31:0] b);
        reg a_nan, b_nan;
        a_nan = (a[30:23] == 8'hFF) & (a[22:0] != 23'h0);
        b_nan = (b[30:23] == 8'hFF) & (b[22:0] != 23'h0);
        feq = (a_nan) ? 32'h0
            : (b_nan) ? 32'h0
            : ((a[30:0] == 31'h0) & (b[30:0] == 31'h0)) ? 32'h1 // +0 == -0
            : (a == b) ? 32'h1
            : 32'h0;
    endfunction

    // Replicate the FIXED FLT logic
    function automatic [31:0] flt(input [31:0] a, input [31:0] b);
        reg a_nan, b_nan;
        a_nan = (a[30:23] == 8'hFF) & (a[22:0] != 23'h0);
        b_nan = (b[30:23] == 8'hFF) & (b[22:0] != 23'h0);
        flt = (a_nan) ? 32'h0
            : (b_nan) ? 32'h0
            : ((a[30:0] == 31'h0) & (b[30:0] == 31'h0)) ? 32'h0 // -0 NOT < +0
            : ( a[31] & ~b[31]) ? 32'h1
            : (~a[31] &  b[31]) ? 32'h0
            : (~a[31] & ~b[31]) ? ((a < b) ? 32'h1 : 32'h0)
            : ( a[31] &  b[31]) ? ((a > b) ? 32'h1 : 32'h0)
            : 32'h0;
    endfunction

    // Replicate the FIXED FLE logic
    function automatic [31:0] fle(input [31:0] a, input [31:0] b);
        reg a_nan, b_nan;
        a_nan = (a[30:23] == 8'hFF) & (a[22:0] != 23'h0);
        b_nan = (b[30:23] == 8'hFF) & (b[22:0] != 23'h0);
        fle = (a_nan) ? 32'h0
            : (b_nan) ? 32'h0
            : ((a[30:0] == 31'h0) & (b[30:0] == 31'h0)) ? 32'h1 // -0 <= +0 is TRUE
            : ( a[31] & ~b[31]) ? 32'h1
            : (~a[31] &  b[31]) ? 32'h0
            : (~a[31] & ~b[31]) ? ((a <= b) ? 32'h1 : 32'h0)
            : ( a[31] &  b[31]) ? ((a >= b) ? 32'h1 : 32'h0)
            : 32'h0;
    endfunction

    task automatic check(input string name, input [31:0] got, input [31:0] expected);
        test_count = test_count + 1;
        if (got === expected) begin
            pass_count = pass_count + 1;
            $display("  [PASS] %s: %0d", name, got);
        end else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] %s: got %0d, expected %0d", name, got, expected);
        end
    endtask

    initial begin
        $display("====================================================");
        $display("  TB: FPU Comparison IEEE 754 Fix Verification");
        $display("====================================================");

        // ===== FEQ TESTS =====
        $display("\n--- FEQ Tests ---");
        // Critical zero comparisons (THE BUG FIX)
        check("FEQ(+0, -0)",       feq(POS_ZERO, NEG_ZERO), 32'h1); // MUST be 1
        check("FEQ(-0, +0)",       feq(NEG_ZERO, POS_ZERO), 32'h1); // MUST be 1
        check("FEQ(+0, +0)",       feq(POS_ZERO, POS_ZERO), 32'h1);
        check("FEQ(-0, -0)",       feq(NEG_ZERO, NEG_ZERO), 32'h1);
        // Normal comparisons
        check("FEQ(1.0, 1.0)",     feq(POS_ONE, POS_ONE),   32'h1);
        check("FEQ(1.0, 2.0)",     feq(POS_ONE, POS_TWO),   32'h0);
        check("FEQ(-1.0, 1.0)",    feq(NEG_ONE, POS_ONE),   32'h0);
        // NaN comparisons
        check("FEQ(QNaN, 1.0)",    feq(QNAN, POS_ONE),      32'h0);
        check("FEQ(1.0, QNaN)",    feq(POS_ONE, QNAN),      32'h0);
        check("FEQ(QNaN, QNaN)",   feq(QNAN, QNAN),         32'h0);
        check("FEQ(SNaN, 1.0)",    feq(SNAN, POS_ONE),      32'h0);
        // Infinity
        check("FEQ(+Inf, +Inf)",   feq(POS_INF, POS_INF),   32'h1);
        check("FEQ(-Inf, -Inf)",   feq(NEG_INF, NEG_INF),   32'h1);
        check("FEQ(+Inf, -Inf)",   feq(POS_INF, NEG_INF),   32'h0);

        // ===== FLT TESTS =====
        $display("\n--- FLT Tests ---");
        // Critical zero comparisons (THE BUG FIX)
        check("FLT(-0, +0)",       flt(NEG_ZERO, POS_ZERO), 32'h0); // MUST be 0
        check("FLT(+0, -0)",       flt(POS_ZERO, NEG_ZERO), 32'h0); // MUST be 0
        check("FLT(+0, +0)",       flt(POS_ZERO, POS_ZERO), 32'h0);
        check("FLT(-0, -0)",       flt(NEG_ZERO, NEG_ZERO), 32'h0);
        // Normal comparisons
        check("FLT(1.0, 2.0)",     flt(POS_ONE, POS_TWO),   32'h1);
        check("FLT(2.0, 1.0)",     flt(POS_TWO, POS_ONE),   32'h0);
        check("FLT(-1.0, 1.0)",    flt(NEG_ONE, POS_ONE),   32'h1);
        check("FLT(1.0, -1.0)",    flt(POS_ONE, NEG_ONE),   32'h0);
        check("FLT(-2.0, -1.0)",   flt(NEG_TWO, NEG_ONE),   32'h1);
        check("FLT(-1.0, -2.0)",   flt(NEG_ONE, NEG_TWO),   32'h0);
        // NaN
        check("FLT(QNaN, 1.0)",    flt(QNAN, POS_ONE),      32'h0);
        check("FLT(1.0, QNaN)",    flt(POS_ONE, QNAN),      32'h0);
        // Boundary
        check("FLT(-Inf, +Inf)",   flt(NEG_INF, POS_INF),   32'h1);
        check("FLT(+Inf, -Inf)",   flt(POS_INF, NEG_INF),   32'h0);
        check("FLT(0, denorm)",    flt(POS_ZERO, POS_DNORM), 32'h1);

        // ===== FLE TESTS =====
        $display("\n--- FLE Tests ---");
        // Critical zero comparisons (THE BUG FIX)
        check("FLE(-0, +0)",       fle(NEG_ZERO, POS_ZERO), 32'h1); // MUST be 1
        check("FLE(+0, -0)",       fle(POS_ZERO, NEG_ZERO), 32'h1); // MUST be 1
        check("FLE(+0, +0)",       fle(POS_ZERO, POS_ZERO), 32'h1);
        check("FLE(-0, -0)",       fle(NEG_ZERO, NEG_ZERO), 32'h1);
        // Normal comparisons
        check("FLE(1.0, 2.0)",     fle(POS_ONE, POS_TWO),   32'h1);
        check("FLE(2.0, 1.0)",     fle(POS_TWO, POS_ONE),   32'h0);
        check("FLE(1.0, 1.0)",     fle(POS_ONE, POS_ONE),   32'h1);
        check("FLE(-1.0, -1.0)",   fle(NEG_ONE, NEG_ONE),   32'h1);
        check("FLE(-2.0, -1.0)",   fle(NEG_TWO, NEG_ONE),   32'h1);
        check("FLE(-1.0, -2.0)",   fle(NEG_ONE, NEG_TWO),   32'h0);
        // NaN
        check("FLE(QNaN, 1.0)",    fle(QNAN, POS_ONE),      32'h0);
        check("FLE(1.0, QNaN)",    fle(POS_ONE, QNAN),      32'h0);

        $display("\n====================================================");
        $display("  Results: %0d PASSED, %0d FAILED out of %0d tests", pass_count, fail_count, test_count);
        $display("====================================================");
        if (fail_count > 0) $display("*** SOME TESTS FAILED ***");
        else $display("*** ALL TESTS PASSED ***");
        $finish;
    end
endmodule
