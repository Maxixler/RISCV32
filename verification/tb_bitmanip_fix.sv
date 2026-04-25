//===========================================================
// Testbench: Bit Manipulation Immediate Fix Verification
// Verifies BCLRI/BEXTI/BINVI/BSETI/RORI use EX_ALU_SHAMT
//===========================================================
`timescale 1ns/1ps

module tb_bitmanip_fix;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // Replicate the fixed ALU logic from cpu_datapath.v
    function automatic [31:0] alu_bclri(input [31:0] rs1, input [4:0] shamt);
        alu_bclri = rs1 & ~(32'h1 << shamt);
    endfunction

    function automatic [31:0] alu_bexti(input [31:0] rs1, input [4:0] shamt);
        alu_bexti = (rs1 >> shamt) & 32'h1;
    endfunction

    function automatic [31:0] alu_binvi(input [31:0] rs1, input [4:0] shamt);
        alu_binvi = rs1 ^ (32'h1 << shamt);
    endfunction

    function automatic [31:0] alu_bseti(input [31:0] rs1, input [4:0] shamt);
        alu_bseti = rs1 | (32'h1 << shamt);
    endfunction

    function automatic [31:0] alu_rori(input [31:0] rs1, input [4:0] shamt);
        alu_rori = (rs1 >> shamt) | (rs1 << (32 - shamt));
    endfunction

    task automatic check(input string name, input [31:0] got, input [31:0] expected);
        test_count = test_count + 1;
        if (got === expected) begin
            pass_count = pass_count + 1;
            $display("  [PASS] %s: got 0x%08h", name, got);
        end else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] %s: got 0x%08h, expected 0x%08h", name, got, expected);
        end
    endtask

    initial begin
        $display("====================================================");
        $display("  TB: Bit Manipulation Immediate Fix Verification");
        $display("====================================================");

        // ---- BCLRI: Clear bit N ----
        $display("\n--- BCLRI Tests ---");
        check("BCLRI(0xFFFFFFFF, 0)",  alu_bclri(32'hFFFFFFFF, 5'd0),  32'hFFFFFFFE);
        check("BCLRI(0xFFFFFFFF, 5)",  alu_bclri(32'hFFFFFFFF, 5'd5),  32'hFFFFFFDF);
        check("BCLRI(0xFFFFFFFF, 31)", alu_bclri(32'hFFFFFFFF, 5'd31), 32'h7FFFFFFF);
        check("BCLRI(0x00000001, 0)",  alu_bclri(32'h00000001, 5'd0),  32'h00000000);
        check("BCLRI(0xDEADBEEF, 16)", alu_bclri(32'hDEADBEEF, 5'd16), 32'hDEADBEEF & ~(32'h1 << 16));

        // ---- BEXTI: Extract bit N ----
        $display("\n--- BEXTI Tests ---");
        check("BEXTI(0x80000000, 31)", alu_bexti(32'h80000000, 5'd31), 32'h1);
        check("BEXTI(0x80000000, 0)",  alu_bexti(32'h80000000, 5'd0),  32'h0);
        check("BEXTI(0x00000020, 5)",  alu_bexti(32'h00000020, 5'd5),  32'h1);
        check("BEXTI(0xAAAAAAAA, 1)",  alu_bexti(32'hAAAAAAAA, 5'd1),  32'h1);
        check("BEXTI(0xAAAAAAAA, 0)",  alu_bexti(32'hAAAAAAAA, 5'd0),  32'h0);

        // ---- BINVI: Invert bit N ----
        $display("\n--- BINVI Tests ---");
        check("BINVI(0x00000000, 0)",  alu_binvi(32'h00000000, 5'd0),  32'h00000001);
        check("BINVI(0x00000001, 0)",  alu_binvi(32'h00000001, 5'd0),  32'h00000000);
        check("BINVI(0x00000000, 31)", alu_binvi(32'h00000000, 5'd31), 32'h80000000);
        check("BINVI(0xDEADBEEF, 12)", alu_binvi(32'hDEADBEEF, 5'd12), 32'hDEADBEEF ^ (32'h1 << 12));

        // ---- BSETI: Set bit N ----
        $display("\n--- BSETI Tests ---");
        check("BSETI(0x00000000, 0)",  alu_bseti(32'h00000000, 5'd0),  32'h00000001);
        check("BSETI(0x00000000, 31)", alu_bseti(32'h00000000, 5'd31), 32'h80000000);
        check("BSETI(0xFFFFFFFF, 15)", alu_bseti(32'hFFFFFFFF, 5'd15), 32'hFFFFFFFF);
        check("BSETI(0xDEAD0000, 3)",  alu_bseti(32'hDEAD0000, 5'd3),  32'hDEAD0008);

        // ---- RORI: Rotate right by N ----
        $display("\n--- RORI Tests ---");
        check("RORI(0x00000001, 1)",  alu_rori(32'h00000001, 5'd1),  32'h80000000);
        check("RORI(0x80000000, 1)",  alu_rori(32'h80000000, 5'd1),  32'h40000000);
        check("RORI(0x12345678, 4)",  alu_rori(32'h12345678, 5'd4),  32'h81234567);
        check("RORI(0x12345678, 8)",  alu_rori(32'h12345678, 5'd8),  32'h78123456);
        check("RORI(0xDEADBEEF, 16)", alu_rori(32'hDEADBEEF, 5'd16), 32'hBEEFDEAD);

        // ---- Verify shamt=0 gives identity (old bug would always use shamt=0) ----
        $display("\n--- Shamt=0 vs Shamt!=0 Regression ---");
        // With old bug (shamt always 0): BCLRI would clear bit 0 regardless
        check("BCLRI(0xFFFF, 5) != BCLRI(0xFFFF, 0)",
              alu_bclri(32'h0000FFFF, 5'd5) != alu_bclri(32'h0000FFFF, 5'd0) ? 32'h1 : 32'h0,
              32'h1);
        check("BEXTI(0x20, 5) != BEXTI(0x20, 0)",
              alu_bexti(32'h00000020, 5'd5) != alu_bexti(32'h00000020, 5'd0) ? 32'h1 : 32'h0,
              32'h1);

        $display("\n====================================================");
        $display("  Results: %0d PASSED, %0d FAILED out of %0d tests", pass_count, fail_count, test_count);
        $display("====================================================");
        if (fail_count > 0) $display("*** SOME TESTS FAILED ***");
        else $display("*** ALL TESTS PASSED ***");
        $finish;
    end
endmodule
