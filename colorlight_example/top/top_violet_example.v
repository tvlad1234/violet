/*
  Example design using the Violet virtual I/O system
  
  Pin mappings for the Colorlight 51-75B V8.2:
    - pushbutton    : reset (design must be reset upon programming!)
    - J1-1 (pin C4) : UART RX
    - J1-2 (pin D4) : UART TX 
  
  LEDs will flash in a "chasing" pattern.
  Button 14 changes the direction of the pattern when pressed.
*/

`default_nettype none

module top_violet_example(
    input wire i_clk,
    input wire nrst,

    input wire uart_rx,
    output wire uart_tx
  );

  reg rst;
  always @(posedge i_clk)
  begin
    rst <= ~nrst;
  end

  localparam clock_freq = 25000000; // input clock frequency in Hz
  localparam baudrate = 9600; // baud rate

  reg [15:0] leds;
  wire [15:0] buttons;

  violet #(.BAUD_DIV(clock_freq / baudrate)) u_vio(i_clk, rst, leds, buttons, uart_rx, uart_tx);

  // LED chaser

  reg [30:0] div_cnt;

  always @(posedge i_clk)
  begin
    if(!rst)
    begin
      if(div_cnt == (clock_freq/10))
      begin
        div_cnt <= 1;
        if(buttons[14])
          leds <= {leds[0], leds[15:1]};
        else
          leds <= {leds[14:0], leds[15]};
      end
      else
        div_cnt <= div_cnt + 1;
    end
    else
    begin
      div_cnt <= 1;
      leds <= 1;
    end
  end

endmodule
