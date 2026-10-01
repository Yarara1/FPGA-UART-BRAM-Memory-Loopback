`timescale 1ns / 1ps

module ClockDivider#(
    parameter divide_rate = 2
)(
    input   wire    clk_in,
    input   wire    rst,
    output  wire    clk_out
    );
    
    localparam bit_width = $clog2(divide_rate);
    
    reg [bit_width-1:0]   counter;
   
    always @(posedge clk_in, posedge rst) begin
        if(rst)  begin
            counter <= {(bit_width){1'b0}};
        end
        else begin
            if(counter == {(bit_width){1'b1}})  counter <= {(bit_width){1'b0}};
            else counter <= counter +  1'b1;
        end
    end
    
    assign clk_out = (counter == {(bit_width){1'b1}})? 1'b1 : 1'b0;
    
    
    
endmodule
