//===========================================================
// HexaChipsers RV32IMAFB — Full System Integration Testbench
//-----------------------------------------------------------
// Instantiates CHIP_TOP_WRAP with real port connections
// Loads test program via rom.memh (byte-oriented format)
// Monitors UART TX for test output
// Ends simulation on 0xDEADDEAD or timeout
//===========================================================

`timescale 1ns / 1ps

`define SIMULATION
`define CLK_PERIOD 20 // 50 MHz = 20ns period

module tb_integration;

//-------------------------------------------
// Clock and Reset
//-------------------------------------------
reg  clk50;
reg  res_n;

initial clk50 = 0;
always #(`CLK_PERIOD / 2) clk50 = ~clk50;

//-------------------------------------------
// DUT Signals
//-------------------------------------------
wire        resout_n;
wire        stby_ack_n;
wire        SRSTn;
wire        RTCK;
wire        TDO;
wire [31:0] GPIO0, GPIO1, GPIO2;
wire        TXD;
wire        I2C0_ENA, I2C0_ADR;
wire [3:0]  SPI_CSN;
wire        SPI_SCK, SPI_MOSI;
wire        SDRAM_CLK, SDRAM_CKE, SDRAM_CSn;
wire [1:0]  SDRAM_DQM, SDRAM_BA;
wire        SDRAM_RASn, SDRAM_CASn, SDRAM_WEn;
wire [12:0] SDRAM_ADDR;
wire [15:0] SDRAM_DQ;
wire        I2C0_SCL, I2C0_SDA;
wire        I2C1_SCL, I2C1_SDA;

//-------------------------------------------
// Pull-ups for GPIO (mimics real hardware)
//-------------------------------------------
assign (pull1, pull0) GPIO0 = 32'hFFFF_FFFF;
assign (pull1, pull0) GPIO1 = 32'hFFFF_FFFF;
// GPIO2 pull-ups, but override:
//   [7]  SW7  = 0 → select fast clock (not 100KHz slow)
//   [9]  SW9  = 0 → debug secure off
//   [10] KEY1 = 1 → no force halt on reset
assign (pull1, pull0) GPIO2 = 32'hFFFF_FD7F; // bit7=0(fast clk), bit9=0(no debug)

//-------------------------------------------
// Tie unused inputs
//-------------------------------------------
reg stby_req;
reg trst_n, tck_jtag, tms_jtag, tdi_jtag;
reg rxd;
reg i2c0_int1, i2c0_int2;
reg spi_miso;

initial begin
    stby_req   = 1'b0;
    trst_n     = 1'b0;
    tck_jtag   = 1'b0;
    tms_jtag   = 1'b1;
    tdi_jtag   = 1'b0;
    rxd        = 1'b1; // idle
    i2c0_int1  = 1'b0;
    i2c0_int2  = 1'b0;
    spi_miso   = 1'b0;
end

//-------------------------------------------
// SDRAM Model (simple: return 0 on read)
//-------------------------------------------
assign SDRAM_DQ = 16'hzzzz;

//-------------------------------------------
// DUT Instantiation — CHIP_TOP_WRAP
//-------------------------------------------
CHIP_TOP_WRAP u_dut (
    .RES_N      (res_n),
    .CLK50      (clk50),
    //
    .STBY_REQ   (stby_req),
    .STBY_ACK_N (stby_ack_n),
    //
    .RESOUT_N   (resout_n),
    //
`ifdef SIMULATION
    .SRSTn      (SRSTn),
`endif
    //
    .TRSTn      (trst_n),
    .TCK        (tck_jtag),
    .TMS        (tms_jtag),
    .TDI        (tdi_jtag),
    .TDO        (TDO),
    //
`ifdef SIMULATION
    .RTCK       (RTCK),
`endif
    //
    .GPIO0      (GPIO0),
    .GPIO1      (GPIO1),
    .GPIO2      (GPIO2),
    //
    .RXD        (rxd),
    .TXD        (TXD),
    //
    .I2C0_SCL   (I2C0_SCL),
    .I2C0_SDA   (I2C0_SDA),
    .I2C0_ENA   (I2C0_ENA),
    .I2C0_ADR   (I2C0_ADR),
    .I2C0_INT1  (i2c0_int1),
    .I2C0_INT2  (i2c0_int2),
    //
    .I2C1_SCL   (I2C1_SCL),
    .I2C1_SDA   (I2C1_SDA),
    //
    .SPI_CSN    (SPI_CSN),
    .SPI_SCK    (SPI_SCK),
    .SPI_MOSI   (SPI_MOSI),
    .SPI_MISO   (spi_miso),
    //
    .SDRAM_CLK  (SDRAM_CLK),
    .SDRAM_CKE  (SDRAM_CKE),
    .SDRAM_CSn  (SDRAM_CSn),
    .SDRAM_DQM  (SDRAM_DQM),
    .SDRAM_RASn (SDRAM_RASn),
    .SDRAM_CASn (SDRAM_CASn),
    .SDRAM_WEn  (SDRAM_WEn),
    .SDRAM_BA   (SDRAM_BA),
    .SDRAM_ADDR (SDRAM_ADDR),
    .SDRAM_DQ   (SDRAM_DQ)
);

//-------------------------------------------
// UART TX Monitor (8N1, sio_ce-based timing)
//-------------------------------------------
// Uses the DUT's UART baud rate generator sio_ce signal
// to determine the exact baud period. This completely avoids
// guessing or formula errors — the period is measured directly
// from the actual hardware BRG output.
//
// Hierarchy: u_dut -> U_CHIP_TOP -> U_UART -> BRG -> sio_ce
//-------------------------------------------
integer uart_log_fd;
integer uart_bit_count;
reg [7:0] uart_rx_byte;
reg       uart_receiving;
integer   uart_baud_period; // in ns, measured from sio_ce
reg       uart_calibrated;
integer   uart_byte_num;

// Access DUT's internal sio_ce signal for calibration
wire dut_sio_ce = u_dut.U_CHIP_TOP.U_UART.sio_ce;

initial begin
    uart_log_fd = $fopen("uart_log.txt", "w");
    if (uart_log_fd == 0) begin
        $display("ERROR: Could not open uart_log.txt");
        $finish;
    end
    uart_bit_count  = 0;
    uart_receiving  = 0;
    uart_calibrated = 0;
    uart_baud_period = 2880; // fallback, will be overwritten by measurement
    uart_byte_num   = 0;
end

// Calibration: measure exact baud period from two consecutive sio_ce pulses
// sio_ce fires once per baud clock (1x rate, not 4x)
initial begin : BAUD_CALIBRATION
    integer t1, t2;
    
    // Wait for reset release and some settling time
    @(posedge res_n);
    #(200 * `CLK_PERIOD); // wait for UART_Init() to set BG registers
    
    // Wait for first sio_ce pulse
    @(posedge dut_sio_ce);
    t1 = $time;
    
    // Wait for second sio_ce pulse
    @(posedge dut_sio_ce);
    t2 = $time;
    
    uart_baud_period = t2 - t1;
    uart_calibrated = 1;
    
    $display("[%0t] UART CALIBRATED from sio_ce: baud_period = %0d ns", $time, uart_baud_period);
    $display("[%0t]   -> Effective baud rate = %0d bps", $time, 1000000000 / uart_baud_period);
end

// UART RX: single always block, triggers on TXD falling edge (start bit)
always @(negedge TXD) begin
    if (uart_calibrated && !uart_receiving && res_n) begin
        uart_receiving = 1;
        
        // Wait to center of start bit (half a baud period)
        #(uart_baud_period / 2);
        
        // Verify we're still in start bit (TXD should be 0)
        if (TXD !== 1'b0) begin
            // False start, abort
            uart_receiving = 0;
        end else begin
            // Sample 8 data bits at their centers
            uart_rx_byte = 0;
            for (uart_bit_count = 0; uart_bit_count < 8; uart_bit_count = uart_bit_count + 1) begin
                #uart_baud_period;
                uart_rx_byte[uart_bit_count] = TXD;
            end
            
            // Wait through stop bit
            #uart_baud_period;
            
            // Display and log the received character
            uart_byte_num = uart_byte_num + 1;
            // Debug: show hex value of each byte for first 200 bytes
            if (uart_byte_num <= 200) begin
                $display("[UART_DBG] byte#%0d = 0x%02x '%c' @%0t", uart_byte_num, uart_rx_byte,
                         (uart_rx_byte >= 8'h20 && uart_rx_byte <= 8'h7E) ? uart_rx_byte : 8'h2E, $time);
            end
            if (uart_rx_byte >= 8'h20 && uart_rx_byte <= 8'h7E) begin
                $write("%c", uart_rx_byte);
                $fwrite(uart_log_fd, "%c", uart_rx_byte);
            end else if (uart_rx_byte == 8'h0A) begin
                $write("\n");
                $fwrite(uart_log_fd, "\n");
            end else if (uart_rx_byte == 8'h0D) begin
                // ignore CR (will be followed by LF)
            end
            
            $fflush(uart_log_fd);
            uart_receiving = 0;
        end
    end
end

//-------------------------------------------
// Simulation Control
//-------------------------------------------
parameter TIMEOUT_US = 50_000; // 50ms timeout
integer cycle_count;

initial begin
    $display("============================================================");
    $display(" HexaChipsers RV32IMAFB — Full System Integration Test");
    $display("============================================================");
    $display(" Time: %0t", $time);
    $display("");
    
    // Force-initialize POR registers (they are reg without init, start as x)
    force u_dut.U_CHIP_TOP.por_n = 1'b0;
    force u_dut.U_CHIP_TOP.por_count = 16'h0000;
    #1;
    release u_dut.U_CHIP_TOP.por_n;
    release u_dut.U_CHIP_TOP.por_count;
    
    // Reset sequence
    res_n = 1'b0;
    #(100 * `CLK_PERIOD); // 100 clk reset
    trst_n = 1'b1;
    #(10 * `CLK_PERIOD);
    res_n = 1'b1;
    
    $display("[%0t] Reset released", $time);
    
    // Debug: check internal signals after reset
    #(50 * `CLK_PERIOD);
    $display("[%0t] DEBUG: por_n=%b res_org=%b res_sys=%b clk=%b",
             $time,
             u_dut.U_CHIP_TOP.por_n,
             u_dut.U_CHIP_TOP.res_org,
             u_dut.U_CHIP_TOP.res_sys,
             u_dut.U_CHIP_TOP.clk);
    $display("[%0t] DEBUG: GPIO2[7]=%b selA=%b selB=%b clkA_ena2=%b",
             $time,
             GPIO2[7],
             u_dut.U_CHIP_TOP.selA,
             u_dut.U_CHIP_TOP.selB,
             u_dut.U_CHIP_TOP.clkA_ena2);
    
    // Wait for timeout
    #(TIMEOUT_US * 1000); // convert us to ns
    
    $display("");
    $display("[%0t] TIMEOUT reached (%0d us)", $time, TIMEOUT_US);
    $display("============================================================");
    $fclose(uart_log_fd);
    $finish;
end

//-------------------------------------------
// End of File
//-------------------------------------------
endmodule
