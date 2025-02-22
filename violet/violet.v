`default_nettype none

module violet #(parameter BAUD_DIV=128)
  (
    input i_clk,
    input rst,

    input [15:0] leds,
    output reg [15:0] buttons,

    input uart_rx,
    output uart_tx
  );

  reg [15:0] out_reg;
  reg [7:0] tx_data;
  wire tx_ready;
  reg tx_go;

  tx #(.BAUD_DIV(BAUD_DIV)) u_tx(i_clk, rst, tx_go, tx_data, uart_tx, tx_ready);

  localparam cmd_leds = 8'd1;
  localparam cmd_btn = 8'd2;

  wire cmd_en; // command enable
  wire [15:0] cmd_data; // command data register
  wire [7:0] cmd_addr; // command address register

  // UART command interface
  command_rx #(.BAUD_DIV(BAUD_DIV)) cmd(i_clk, rst, uart_rx, cmd_en, cmd_addr, cmd_data);

  reg tx_request;

  always @(posedge i_clk)
  begin
    if(!rst)
    begin
      if (cmd_en)
      begin
        if(cmd_addr == cmd_leds)
          tx_request <= 1;
        else if(cmd_addr == cmd_btn)
          buttons <= cmd_data;
      end
      else
        tx_request <= 0;
    end
    else
    begin
      buttons <= 0;
      tx_request <= 0;
    end

  end

  // Tx state machine
  localparam state_reset  = 4'd0;
  localparam state_idle   = 4'd1;
  localparam state_tx  = 4'd2;
  localparam state_wait = 4'd3;
  reg [3:0] currentState;

  reg [1:0] bytes_to_send;

  always @(posedge i_clk)
  begin
    if(!rst)
    begin
      case (currentState)
        state_reset:
        begin
          tx_go <= 0;
          tx_data <= 0;
          currentState <= state_idle;
        end

        state_idle:
        begin
          if(tx_request)
          begin
            currentState <= state_tx;
            out_reg <= leds;
            bytes_to_send <= 2;
          end
          else
            currentState <= state_idle;
        end

        state_tx:
        begin
          tx_data <= out_reg[7:0];
          bytes_to_send <= bytes_to_send - 1;
          tx_go <= 1;
          currentState <= state_wait;
        end

        state_wait:
        begin
          if(tx_ready)
          begin
            tx_go <= 0;
            if(bytes_to_send == 0)
              currentState <= state_idle;
            else
            begin
              out_reg <= {0, out_reg[15:8]};
              currentState <= state_tx;
            end
          end
          else
            currentState <= state_wait;
        end

        default:
          currentState <= state_reset;
      endcase
    end
    else
    begin
      currentState <= state_reset;
    end

  end


endmodule
