`default_nettype none

module command_rx #(parameter BAUD_DIV = 128)
  (
    input wire i_clk,
    input wire rst,
    input wire uart_rx,

    output reg cmd_en,
    output reg [7:0] cmd_addr,
    output reg [15:0] cmd_data
  );

  wire rx_err, rx_avail;
  reg rx_ack;
  wire [7:0] rx_data;

  rx #(.BAUD_DIV(BAUD_DIV)) u_rx (i_clk, rst, uart_rx, rx_ack, rx_data, rx_err, rx_avail);

  localparam state_reset  = 4'd0;
  localparam state_idle   = 4'd1;
  localparam state_ack_r  = 4'd2;
  localparam state_wait_d = 4'd3;
  localparam state_ack_d  = 4'd4;
  reg [3:0] currentState;

  reg [1:0] bytes_to_receive;

  always @(posedge i_clk)
  begin
    if(!rst)
    begin
      case (currentState)
        state_reset :
        begin
          rx_ack <= 0;
          cmd_en <= 0;
          cmd_addr <= 0;
          cmd_data <= 0;
          currentState <= state_idle;
        end

        state_idle :
        begin
          cmd_en <= 0;
          if (rx_avail)
          begin
            rx_ack <= 1;
            cmd_addr <= rx_data;
            currentState <= state_ack_r;
            bytes_to_receive <= 2;
          end
          else
            currentState <= state_idle;
        end

        state_ack_r :
        begin
          rx_ack <= 0;
          currentState <= state_wait_d;
        end

        state_wait_d :
        begin
          if (rx_avail)
          begin
            rx_ack <= 1;
            bytes_to_receive <= bytes_to_receive - 1;

            cmd_data <= {rx_data, cmd_data[15:8]};

            currentState <= state_ack_d;
          end
          else
            currentState <= state_wait_d;
        end

        state_ack_d :
        begin
          rx_ack <= 0;
          if(bytes_to_receive == 0)
          begin
            currentState <= state_idle;
            cmd_en <= 1;
          end
          else
            currentState <= state_wait_d;
        end

        default :
          currentState <= state_reset;
      endcase
    end

    else
      currentState <= state_reset;

  end

endmodule
