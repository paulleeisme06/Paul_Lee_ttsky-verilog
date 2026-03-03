/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_alif_accelerator (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Internal Registers
    reg [7:0] v_mem;
    reg [7:0] adapt;
    reg       spike_reg;
    
    // Constants
    localparam THRESHOLD  = 8'd200;
    localparam ADAPT_STEP = 8'd20;

    always @(posedge clk) begin
        if (!rst_n) begin
            v_mem <= 8'd0;
            adapt <= 8'd0;
            spike_reg <= 1'b0;
        end else if (ena) begin
            // 1. Spike Logic & Threshold Reset
            if (v_mem >= THRESHOLD) begin
                v_mem <= 8'd0;
                spike_reg <= 1'b1; 
                if (adapt < 8'd230) 
                    adapt <= adapt + ADAPT_STEP;
            end else begin
                spike_reg <= 1'b0;
                
                // 2. Integration: V = V + Input - Leak - Adaptation
                // We use uio_in[3:0] for Vmem leak and uio_in[7:4] for Adapt leak
                if (v_mem + ui_in > (uio_in[3:0] + adapt))
                    v_mem <= v_mem + ui_in - uio_in[3:0] - adapt;
                else
                    v_mem <= 8'd0;

                // 3. Adaptation Decay
                if (adapt > uio_in[7:4])
                    adapt <= adapt - uio_in[7:4];
                else
                    adapt <= 8'd0;
            end
        end
    end

    // Assign Outputs
    assign uo_out[0]   = spike_reg;           // Spike bit
    assign uo_out[7:1] = v_mem[7:1];          // Vmem monitor
    assign uio_out     = adapt;               // Show adaptation state on bidir pins
    assign uio_oe      = 8'hFF;               // Set all UIO pins as outputs to show 'adapt'

    // Use 'ena' to prevent unused warning
    wire _unused = &{ena, 1'b0};

endmodule