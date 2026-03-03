/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_alif_accelerator (
    input  wire [7:0] ui_in,    // Input Current
    output wire [7:0] uo_out,   // [7:1] Vmem, [0] Spike
    input  wire [7:0] uo_in,    // (Unused)
    output wire [7:0] uo_out_extra, // (Unused)
    input  wire [7:0] uio_in,   // [7:4] Adapt Leak, [3:0] Vmem Leak
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
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
                spike_reg <= 1'b1; // Pulse high for 1 cycle
                // Increment fatigue (adaptation)
                if (adapt < 8'd230) 
                    adapt <= adapt + ADAPT_STEP;
            end else begin
                spike_reg <= 1'b0;
                
                // 2. Integration: V = V + Input - Leak - Adaptation
                if (v_mem + ui_in > (uio_in[3:0] + adapt))
                    v_mem <= v_mem + ui_in - uio_in[3:0] - adapt;
                else
                    v_mem <= 8'd0;

                // 3. Adaptation Decay: Fatigue fades over time
                if (adapt > uio_in[7:4])
                    adapt <= adapt - uio_in[7:4];
                else
                    adapt <= 8'd0;
            end
        end
    end

    // Assign Outputs
    assign uo_out[0]   = spike_reg;      
    assign uo_out[7:1] = v_mem[7:1]; 
    assign uio_out     = adapt; 
    assign uio_oe      = 8'b0; 

    wire _unused = &{uo_in, uo_out_extra, 1'b0};

endmodule