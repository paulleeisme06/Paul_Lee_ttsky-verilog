/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_alif_accelerator (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out, 
    input  wire [7:0] uio_in, 
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    // Internal Registers
    reg [7:0] v_mem;
    reg [7:0] adapt;
    
    // Threshold Constant
    localparam THRESHOLD = 8'd200;
    localparam ADAPT_STEP = 8'd20;

    // Neuron Logic
    always @(posedge clk) begin
        if (!rst_n) begin
            v_mem <= 8'd0;
            adapt <= 8'd0;
        end else begin
            // 1. Check for Spike (Threshold Crossing)
            if (v_mem >= THRESHOLD) begin
                v_mem <= 8'd0;               // Reset Vmem
                if (adapt < 8'd235)          // Prevent overflow
                    adapt <= adapt + ADAPT_STEP;
            end else begin
                // 2. Integration: V = V + I - Leak_V - Adapt
                // Simplified for 1-cycle hardware efficiency
                if (v_mem + ui_in > (uio_in[3:0] + adapt))
                    v_mem <= v_mem + ui_in - uio_in[3:0] - adapt;
                else
                    v_mem <= 8'd0;

                // 3. Adaptation Leak: Slow decay of the fatigue state
                if (adapt > uio_in[7:4])
                    adapt <= adapt - uio_in[7:4];
                else
                    adapt <= 8'd0;
            end
        end
    end

    // Assign Outputs
    assign uo_out[0]   = (v_mem >= THRESHOLD); // Spike signal
    assign uo_out[7:1] = v_mem[7:1];          // Monitor Vmem
    assign uio_out     = 8'b0;
    assign uio_oe      = 8'b0;

    // Suppress warnings
    wire _unused = &{ena, 1'b0};

endmodule
