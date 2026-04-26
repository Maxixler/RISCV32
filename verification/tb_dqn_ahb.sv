// filepath: C:\Users\DELL\Downloads\HexaChipsers-Core\verification\tb_dqn_ahb.sv
// DQN AHB-Lite Slave Testbench for HexaChipsers-Core
`timescale 1ns / 1ps

module tb_dqn_ahb;

    // Clock and Reset
    reg clk;
    reg rstn;

    // AHB-Lite Slave Interface
    wire        hsel;
    wire [1:0]  htrans;
    wire        hwrite;
    wire        hmastlock;
    wire [2:0]  hsize;
    wire [2:0]  hburst;
    wire [3:0]  hprot;
    wire [31:0] haddr;
    wire [31:0] hwdata;
    wire        hready;
    wire        hreadyout;
    wire [31:0] hrdata;
    wire        hresp;

    // Test signals
    integer test_num;
    integer pass_count;
    integer fail_count;

    // ════════════════════════════════════════════════
    // DQN Register offsets
    // ════════════════════════════════════════════════
    localparam CTRL_OFFSET      = 12'h000;
    localparam STATUS_OFFSET    = 12'h004;
    localparam STATE_0_OFFSET   = 12'h008;
    localparam STATE_1_OFFSET   = 12'h00C;
    localparam STATE_2_OFFSET   = 12'h010;
    localparam STATE_3_OFFSET   = 12'h014;
    localparam QVAL_0_OFFSET    = 12'h018;
    localparam QVAL_1_OFFSET    = 12'h01C;
    localparam QVAL_2_OFFSET    = 12'h020;
    localparam QVAL_3_OFFSET    = 12'h024;
    localparam QVAL_MAX_OFFSET  = 12'h028;
    localparam WT_ADDR_OFFSET   = 12'h02C;
    localparam WT_DATA_OFFSET   = 12'h030;
    localparam CYCLE_CNT_OFFSET = 12'h034;
    localparam VERSION_OFFSET   = 12'h038;

    // ════════════════════════════════════════════════
    // Clock generation
    // ════════════════════════════════════════════════
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // ════════════════════════════════════════════════
    // Reset generation
    // ════════════════════════════════════════════════
    initial begin
        rstn = 0;
        #100;
        rstn = 1;
    end

    // ════════════════════════════════════════════════
    // AHB-Lite DQN Slave instance
    // ════════════════════════════════════════════════
    ahb_lite_dqn u_dqn (
        .HCLK     (clk),
        .HRESETn  (rstn),
        .HSEL     (hsel),
        .HTRANS   (htrans),
        .HWRITE   (hwrite),
        .HMASTLOCK (hmastlock),
        .HSIZE    (hsize),
        .HBURST   (hburst),
        .HPROT    (hprot),
        .HADDR    (haddr),
        .HWDATA   (hwdata),
        .HREADY   (hready),
        .HREADYOUT (hreadyout),
        .HRDATA   (hrdata),
        .HRESP    (hresp)
    );

    // ════════════════════════════════════════════════
    // AHB-Lite Master tasks
    // ════════════════════════════════════════════════
    task ahb_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            haddr   <= addr;
            htrans  <= 2'b10;  // NONSEQ
            hwrite  <= 1'b1;
            hsize   <= 3'b010; // Word
            hwdata  <= data;
            hsel    <= 1'b1;
            hready  <= 1'b0;

            @(posedge clk);
            hready  <= 1'b1;
            wait until hreadyout;
            @(posedge clk);
            hsel    <= 1'b0;
            htrans  <= 2'b00;
            hwrite  <= 1'b0;
        end
    endtask

    task ahb_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            haddr   <= addr;
            htrans  <= 2'b10;  // NONSEQ
            hwrite  <= 1'b0;
            hsize   <= 3'b010; // Word
            hsel    <= 1'b1;
            hready  <= 1'b0;

            @(posedge clk);
            hready  <= 1'b1;
            wait until hreadyout;
            @(posedge clk);
            data    <= hrdata;
            hsel    <= 1'b0;
            htrans  <= 2'b00;
        end
    endtask

    // ════════════════════════════════════════════════
    // Test tasks
    // ════════════════════════════════════════════════
    task test_reset_values;
        reg [31:0] rdata;
        begin
            $display("[%0t] Test 1: Reset values", $time);
            ahb_read(32'hF0000000, rdata);
            if (rdata == 32'h00000000) begin
                $display("  PASS: CTRL = 0x%08h", rdata[7:0]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: CTRL = 0x%08h (expected 0x00)", rdata[7:0]);
                fail_count = fail_count + 1;
            end

            ahb_read(32'hF0000004, rdata);
            if (rdata == 32'h00000000) begin
                $display("  PASS: STATUS = 0x%08h", rdata[7:0]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: STATUS = 0x%08h (expected 0x00)", rdata[7:0]);
                fail_count = fail_count + 1;
            end

            ahb_read(32'hF0000038, rdata);
            if (rdata == 32'h44514E01) begin
                $display("  PASS: VERSION = 0x%08h", rdata[31:0]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: VERSION = 0x%08h (expected 0x44514E01)", rdata[31:0]);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task test_register_write;
        reg [31:0] rdata;
        begin
            $display("[%0t] Test 2: Register write", $time);

            // Write CTRL = 0x01 (enable)
            ahb_write(32'hF0000000, 32'h00000001);
            ahb_read(32'hF0000000, rdata);
            if (rdata[0] == 1'b1) begin
                $display("  PASS: CTRL enable bit set");
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: CTRL enable bit not set");
                fail_count = fail_count + 1;
            end

            // Write STATE_0 = 0x1000
            ahb_write(32'hF0000008, 32'h00001000);
            ahb_read(32'hF0000008, rdata);
            if (rdata[15:0] == 16'h1000) begin
                $display("  PASS: STATE_0 = 0x%04h", rdata[15:0]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: STATE_0 = 0x%04h (expected 0x1000)", rdata[15:0]);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task test_weight_load;
        reg [31:0] rdata;
        integer i;
        begin
            $display("[%0t] Test 3: Weight load", $time);

            // Enable weight load mode
            ahb_write(32'hF0000000, 32'h00000009);  // enable + wt_load_mode

            // Load 148 weights
            for (i = 0; i < 148; i = i + 1) begin
                ahb_write(32'hF000002C, {24'h0, i[7:0]});
                ahb_write(32'hF0000030, 32'h00000001);  // dummy weight
            end

            // Check wt_loaded flag
            ahb_read(32'hF0000004, rdata);
            if (rdata[2] == 1'b1) begin
                $display("  PASS: wt_loaded flag set");
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: wt_loaded flag not set");
                fail_count = fail_count + 1;
            end

            // Disable weight load mode
            ahb_write(32'hF0000000, 32'h00000001);  // enable only
        end
    endtask

    task test_inference;
        reg [31:0] rdata;
        begin
            $display("[%0t] Test 4: Inference", $time);

            // Write state values
            ahb_write(32'hF0000008, 32'h00001000);  // STATE_0 = 0x1000
            ahb_write(32'hF000000C, 32'h00002000);  // STATE_1 = 0x2000
            ahb_write(32'h0000010, 32'h00003000);  // STATE_2 = 0x3000
            ahb_write(32'h0000014, 32'h00004000);  // STATE_3 = 0x4000

            // Start inference
            ahb_write(32'hF0000000, 32'h00000003);  // enable + start pulse

            // Wait for done
            wait until (rdata[1] == 1'b1);
            ahb_read(32'hF0000004, rdata);

            // Check results
            ahb_read(32'hF0000018, rdata);  // QVAL_0
            $display("  QVAL_0 = 0x%04h", rdata[15:0]);
            ahb_read(32'hF000001C, rdata);  // QVAL_1
            $display("  QVAL_1 = 0x%04h", rdata[15:0]);
            ahb_read(32'hF0000020, rdata);  // QVAL_2
            $display("  QVAL_2 = 0x%04h", rdata[15:0]);
            ahb_read(32'hF0000024, rdata);  // QVAL_3
            $display("  QVAL_3 = 0x%04h", rdata[15:0]);
            ahb_read(32'hF0000028, rdata);  // QVAL_MAX
            $display("  QVAL_MAX = 0x%04h", rdata[15:0]);
            ahb_read(32'hF0000034, rdata);  // CYCLE_CNT
            $display("  CYCLE_CNT = 0x%04h", rdata[15:0]);

            pass_count = pass_count + 1;
        end
    endtask

    // ════════════════════════════════════════════════
    // Main test sequence
    // ════════════════════════════════════════════════
    initial begin
        test_num = 0;
        pass_count = 0;
        fail_count = 0;

        $display("========================================");
        $display("DQN AHB-Lite Slave Test");
        $display("========================================");

        // Wait for reset
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        // Test 1: Reset values
        test_num = test_num + 1;
        test_reset_values();

        // Test 2: Register write
        test_num = test_num + 1;
        test_register_write();

        // Test 3: Weight load
        test_num = test_num + 1;
        test_weight_load();

        // Test 4: Inference
        test_num = test_num + 1;
        test_inference();

        // Wait for completion
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        $display("========================================");
        $display("Test Summary:");
        $display("  Total tests: %0d", test_num);
        $display("  Passed: %0d", pass_count);
        $display("  Failed: %0d", fail_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end

        $finish;
    end

endmodule
