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

    reg [7:0] v_mem;
    reg [7:0] adapt;
    reg       spike_reg;
    
    // Internal wires to simplify the "Front-End" math
    wire [7:0] total_leak = uio_in[3:0] + adapt;

    always @(posedge clk) begin
        if (!rst_n) begin
            v_mem <= 8'd0;
            adapt <= 8'd0;
            spike_reg <= 1'b0;
        end else if (ena) begin
            if (v_mem >= 8'd200) begin
                v_mem <= 8'd0;
                spike_reg <= 1'b1; 
                if (adapt < 8'd230) adapt <= adapt + 8'd20;
            end else begin
                spike_reg <= 1'b0;
                
                // Simplified math to prevent FEOL congestion
                if ((v_mem + ui_in) > total_leak)
                    v_mem <= (v_mem + ui_in) - total_leak;
                else
                    v_mem <= 8'd0;

                if (adapt > uio_in[7:4])
                    adapt <= adapt - uio_in[7:4];
                else
                    adapt <= 8'd0;
            end
        end
    end

    assign uo_out[0]   = spike_reg;
    assign uo_out[7:1] = v_mem[7:1];
    assign uio_out     = adapt;
    assign uio_oe      = 8'hFF; 

    wire _unused = &{ena, 1'b0};
endmodule