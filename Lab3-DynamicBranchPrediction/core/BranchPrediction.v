`timescale 1ns / 1ps

`define INDEX 6
`define TAG 8-`INDEX
`define STATE 2

module Branch_Prediction(
         input clk,
         input rst,

         // from IF
         input [7:0] PC_Branch,
         output taken,
         output [7:0] PC_to_take,

         // from ID
         input Branch_ID,
         input J,
         input [7:0] PC_to_branch,
         output refetch
       );

reg taken_IF, taken_ID, refetch_, is_refetch_ed;
reg [7:0] PC_to_take_, PC_to_take_ID;

reg [`TAG + 2 - 1:0] BHT[0:2**`INDEX - 1];

reg [`TAG + 8 - 1:0] BTB[0:2**`INDEX - 1];

wire [`INDEX - 1:0] index_IF;
wire [`TAG - 1:0] tag_IF;
assign index_IF = PC_Branch[`INDEX - 1:0];

assign tag_IF = PC_Branch[7:`INDEX];

reg [`INDEX - 1:0] index_ID;
reg [`TAG - 1:0] tag_ID;

reg BHT_Hit_IF, BHT_Hit_ID, BTB_Hit_IF, BTB_Hit_ID;

always@*
  begin
    if (rst)
      begin
        BHT_Hit_IF <= 1'b0;
        taken_IF <= 1'b0;
        BTB_Hit_IF <= 1'b0;
        PC_to_take_ <= 8'b0;
        refetch_ <= 1'b0;
      end
    else
      begin
        if (BHT[index_IF][`TAG + 2 - 1:2] == tag_IF)
          begin
            BHT_Hit_IF <= 1'b1;
            taken_IF <= BHT[index_IF][1];
          end
        else
          begin
            BHT_Hit_IF <= 1'b0;
            taken_IF <= 1'b0;
          end

        if (BTB[index_IF][`TAG + 8 - 1:8] == tag_IF)
          begin
            BTB_Hit_IF <= 1'b1;
            PC_to_take_ <= BTB[index_IF][7:0];
          end
        else
          begin
            BTB_Hit_IF <= 1'b0;
            PC_to_take_ <= 8'b0;
          end

        if (is_refetch_ed || ((taken_ID & BTB_Hit_ID) && Branch_ID && PC_to_branch == PC_to_take_ID)
            || ((~(taken_ID & BTB_Hit_ID)) && (~Branch_ID)))
          begin
            refetch_ <= 1'b0;
          end
        else
          begin
            refetch_ <= 1'b1;
          end
      end
  end

integer i;
always@(posedge clk or posedge rst)
  begin
    if (rst)
      begin
        taken_ID <= 1'b0;
        is_refetch_ed <= 1'b0;
        BHT_Hit_ID <= 1'b0;
        BTB_Hit_ID <= 1'b0;
        index_ID <= 0;
        tag_ID <= 0;
        for (i = 0; i < 2**`INDEX; i = i + 1)
          begin
            BHT[i] <= 0;
            BTB[i] <= 0;
          end
      end
    else
      begin
        taken_ID <= taken_IF;
        index_ID <= index_IF;
        tag_ID <= tag_IF;
        BHT_Hit_ID <= BHT_Hit_IF;
        BTB_Hit_ID <= BTB_Hit_IF;
        PC_to_take_ID <= PC_to_take_;
        is_refetch_ed <= refetch_;

        if (Branch_ID)
          begin
            if (BHT_Hit_ID)
              begin
                if (BHT[index_ID][0] == 1'b0)
                  begin
                    BHT[index_ID][0] <= 1'b1;
                  end
                else
                  begin
                    BHT[index_ID][1] <= 1'b1;
                  end
              end
            else
              begin
                BHT[index_ID] <= {tag_ID, 2'b10};
              end

            BTB[index_ID] <= {tag_ID, PC_to_branch};
          end
        else
          begin
            if (BHT_Hit_ID)
              begin
                if (BHT[index_ID][0] == 1'b0)
                  begin
                    BHT[index_ID][1] <= 1'b0;
                  end
                else
                  begin
                    BHT[index_ID][0] <= 1'b0;
                  end
              end
            else if (J)
              begin
                BHT[index_ID] <= {tag_ID, 2'b01};
              end
          end
      end
  end

assign taken = taken_IF & BTB_Hit_IF;
assign refetch = refetch_;
assign PC_to_take = PC_to_take_;

endmodule
