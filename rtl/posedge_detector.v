`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/11 03:50:51
// Design Name: 
// Module Name: negedge_detector
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//module negedge_detector(
//    input   clk,
//    input   rst,
//    input   in,
//    output   out
//    );
    
//    reg d_ff;
//    always @(posedge clk, posedge rst) begin
//        if(rst) d_ff <= 1'b0;
//        else d_ff <=in;
//    end
    
//    assign out = (~in)&&(d_ff^in);
//endmodule

module posedge_detector(
    input   clk,
    input   rst,
    input   in,
    output   out
    );
    
    reg d_ff;
    always @(posedge clk, posedge rst) begin
        if(rst) d_ff <= 1'b0;
        else d_ff <=in;
    end
    
    assign out = (in)&&(d_ff^in);
endmodule
