`default_nettype none

module rx #(parameter OVERSAMP = 16, parameter BAUD_DIV = 2)
  (
    input wire i_clk,
    input wire i_rst,
    input wire i_rx,
    input wire i_ack,
    output reg [7:0] o_data,
    output reg o_err,
    output reg o_avail
  );

  localparam CLK_PER_BIT = BAUD_DIV / OVERSAMP;

  reg [15:0] baud_cnt, oversamp_cnt;

  reg [7:0] data_reg;
  reg [3:0] bits_to_receive;

  reg [3:0] currentState;

  localparam state_reset = 3'd0;
  localparam state_idle = 3'd1;
  localparam state_startbit = 3'd2;
  localparam state_rx = 3'd3;
  localparam state_stopbit = 3'd4;

  reg r_rx_d, r_rx;

  always @(posedge i_clk)
  begin
    r_rx_d <= i_rx;
    r_rx <= r_rx_d;

    if(!i_rst)
    begin
      case (currentState)
        state_reset :
        begin
          o_data <= 0;
          o_avail <= 0;
          o_err <= 0;
          currentState <= state_idle;
        end

        state_idle :
        begin
          data_reg <= 0;

          if(i_ack)
          begin
            o_avail <= 0;
            o_err <= 0;
          end

          if(!r_rx)
          begin
            bits_to_receive <= 8;
            baud_cnt <= 1;
            oversamp_cnt <= 1;
            currentState <= state_startbit;
          end
        end

        state_startbit :
        begin
          if(baud_cnt == CLK_PER_BIT)
          begin
            baud_cnt <= 1;
            if(oversamp_cnt == OVERSAMP)
            begin
              oversamp_cnt <= 1;
              bits_to_receive <= bits_to_receive - 1;
              currentState <= state_rx;
            end
            else
            begin
              oversamp_cnt <= oversamp_cnt+1;
              if(oversamp_cnt == OVERSAMP >> 1 && r_rx)
              begin
                o_err <= 1;
                currentState <= state_idle;
              end
            end
          end
          else
            baud_cnt <= baud_cnt + 1;
        end

        state_rx:
        begin
          if(baud_cnt == CLK_PER_BIT)
          begin
            baud_cnt <= 1;
            if(oversamp_cnt == OVERSAMP)
            begin
              oversamp_cnt <= 1;
              if(bits_to_receive != 0)
                bits_to_receive <= bits_to_receive - 1;
              else
                currentState <= state_stopbit;
            end
            else
            begin
              if(oversamp_cnt == OVERSAMP >> 1)
                data_reg <= {r_rx, data_reg[7:1]};
              oversamp_cnt <= oversamp_cnt + 1;
            end
          end
          else
            baud_cnt <= baud_cnt + 1;
        end

        state_stopbit:
        begin
          if(baud_cnt == CLK_PER_BIT)
          begin
            baud_cnt <= 1;
            if(oversamp_cnt == OVERSAMP)
            begin
              oversamp_cnt <= 1;
              currentState <= state_idle;
              if(!o_err)
              begin
                o_data <= data_reg;
                o_avail <= 1;
              end
            end
            else
            begin
              if(oversamp_cnt == OVERSAMP >> 1 && !r_rx)
                o_err <= 1;
              oversamp_cnt <= oversamp_cnt+1;
            end
          end
          else
            baud_cnt <= baud_cnt + 1;
        end

        default:
          currentState <= state_reset;
      endcase
    end
    else
      currentState <= state_reset;
  end

endmodule
