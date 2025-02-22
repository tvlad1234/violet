`default_nettype none

module tx #(parameter BAUD_DIV = 217)
  (
    input wire i_clk,
    input wire i_rst,
    input wire i_go,
    input wire [7:0] i_data,
    output reg o_tx,
    output reg o_ready
  );


  localparam state_reset = 3'd0;
  localparam state_idle = 3'd1;
  localparam state_startbit = 3'd2;
  localparam state_tx = 3'd3;
  localparam state_stopbit = 3'd4;

  reg [7:0] data_reg;
  reg [3:0] currentState;
  reg [3:0] bits_to_send;

  reg [15:0] baud_cnt;

  always @(posedge i_clk)
  begin
    if(!i_rst)
    begin
      case (currentState)

        state_reset: // reset to idle
        begin
          o_ready <= 1;
          currentState <= state_idle;
          o_tx <= 1;
        end

        state_idle: // idle to startbit or idle to idle
        begin
          if(i_go)
          begin
            bits_to_send <= 8;
            o_ready <= 0;
            baud_cnt <= 1;
            data_reg <= i_data;
            o_tx <= 0; // start bit
            currentState <= state_startbit;
          end
          else
            currentState <= state_idle;
        end

        state_startbit :
        begin
          if(baud_cnt == BAUD_DIV)
          begin
            o_tx <= data_reg[0];
            data_reg <= data_reg >> 1;
            bits_to_send <= bits_to_send - 1;
            currentState <= state_tx;
            baud_cnt <= 1;
          end
          else
            baud_cnt <= baud_cnt + 1;
        end

        state_tx:
        begin
          if(baud_cnt == BAUD_DIV)
          begin
            if(bits_to_send != 0)
            begin
              o_tx <= data_reg[0];
              data_reg <= data_reg >> 1;
              bits_to_send <= bits_to_send - 1;
              currentState <= state_tx;
            end
            else
            begin
              currentState <= state_stopbit;
              o_tx <= 1; // stop bit
            end
            baud_cnt <= 1;
          end
          else
            baud_cnt <= baud_cnt + 1;
        end

        state_stopbit:
        begin
          if(baud_cnt == BAUD_DIV)
          begin
            o_ready <= 1;
            currentState <= state_idle;
          end
          else
            baud_cnt <= baud_cnt + 1;
        end

        default:
          currentState <= state_reset;
      endcase
    end

    else
    begin
      currentState <= state_reset;
      o_ready <= 0;
    end

  end

endmodule
