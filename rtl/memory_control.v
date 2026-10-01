`timescale 1ns / 1ps

module memory_control #(
    parameter MEMORY_DEPTH = 100
) (
    input  wire rst, //active-high reset
    input  wire clk,
    input  wire rx_switch, //starts receive/store phase
    input  wire tx_switch, //starts transmit/readback phase
    output reg  led, //turns on when RX phase is complete

    input  wire [7:0]  uart_rx_data, //received byte from uart RX
    input  wire uart_rx_ready, //one-cycle pulse when a byte is ready

    output reg  [7:0]  uart_tx_data, //byte to send to uart tx
    input  wire uart_tx_pop, //pulse from uart tx requesting next byte
    output reg  uart_tx_on, //indicates tx data

    output reg  memory_en, //bram enable
    output reg  memory_write_en, //bram write enable
    output reg  [14:0] memory_addr, //bram addr
    output reg  [7:0]  memory_data_in, //data written into bram
    input  wire [7:0]  memory_data_out //data read from bram
);
  
    reg [3:0] state; reg [13:0] wr_addr;
    reg [13:0] rd_addr; reg [31:0] rx_count;
    reg [31:0] tx_count; reg [7:0]  rx_store;

localparam IDLE = 4'b0000,RX_WAIT = 4'b0001, RX_WRITE = 4'b0010,
RX_DONE = 4'b0011, TX_READ = 4'b0100, TX_SEND= 4'b0101,
TX_WAIT_POP = 4'b0111, TX_DONE = 4'b1000;

always @(posedge clk or posedge rst) begin
    if (rst) begin //reset all outputs,counters,addresses, and state
        uart_tx_data <= 0; memory_en <= 0;
        memory_write_en <= 0; memory_addr <= 0;
        memory_data_in <= 0; uart_tx_on<= 0;
        wr_addr<= 0; rd_addr<= 0;
        rx_count<= 0; tx_count<= 0;
        rx_store<= 0;led<= 0;
        state<= IDLE;
    end else begin //bram controls for each cycle
        memory_en<= 0; memory_write_en <= 0;
        case (state)
            IDLE: begin //led off,tx disabled, wait for receive
                uart_tx_on <= 0;
                led <= 0;
                if (rx_switch) begin //start receive phase from bram address 0
                    state <= RX_WAIT;
                    wr_addr<= 0; rx_count <= 0;
                end
            end
            RX_WAIT: begin //wait until uartrx report a complete received byte
                if (uart_rx_ready) begin //latch received byte then move to write state
                    rx_store <= uart_rx_data;
                    state  <= RX_WRITE;
                end
            end

            RX_WRITE: begin //write the received byte into bram at current wr_addr
                memory_en <= 1; memory_write_en <= 1;
                memory_addr <= wr_addr; memory_data_in <= rx_store;
                if (rx_count == MEMORY_DEPTH - 1) begin //all required bytes received and stored
                    led <= 1; state <= RX_DONE;
                end else begin
                    wr_addr  <= wr_addr + 1;
                    rx_count <= rx_count + 1;
                    state    <= RX_WAIT;
                end
            end
           //rx complete; keep LED on and wait for transmit command
            RX_DONE: begin
                led <=1;
                if (tx_switch) begin
                    uart_tx_on<= 1;
                    rd_addr <=0; tx_count<= 0;
                    state<= TX_READ;
                end
            end
        //wait until uart tx requests the next byte
            TX_WAIT_POP: begin
                if (uart_tx_pop) begin
                  if (tx_count==MEMORY_DEPTH) begin 
                     state <=TX_DONE; 
                  end  
                  else begin //advance to next bram addr and read next byte
                      rd_addr<= rd_addr+1; 
                      tx_count<=tx_count+1; 
                      state <=TX_READ; 
                end
            end
           end
            TX_READ: begin //read one byte from bram at current read address
                memory_en <=1; memory_write_en <= 0;
                memory_addr<= rd_addr; state <= TX_SEND;
            end
          //put BRAM output onto uart tx data bus
            TX_SEND: begin
                uart_tx_data <= memory_data_out;
                uart_tx_on<=1;
                state <= TX_WAIT_POP;
            end
            TX_DONE: begin
                uart_tx_on <= 0;
                state <= IDLE;
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule
