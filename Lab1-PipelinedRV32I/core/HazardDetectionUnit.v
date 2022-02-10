`timescale 1ps/1ps

module HazardDetectionUnit(
         input clk,
         input Branch_ID, rs1use_ID, rs2use_ID,
         input[1:0] hazard_optype_ID,
         input[4:0] rd_EXE, rd_MEM, rs1_ID, rs2_ID, rs2_EXE,
         output PC_EN_IF, reg_FD_EN, reg_FD_stall, reg_FD_flush,
         reg_DE_EN, reg_DE_flush, reg_EM_EN, reg_EM_flush, reg_MW_EN,
         output forward_ctrl_ls,
         output[1:0] forward_ctrl_A, forward_ctrl_B,

         input mem_w_EXE,
         input DatatoReg_MEM,
         input DatatoReg_EXE,
         input RegWrite_EXE,
         input RegWrite_MEM
       );  // to fill sth. in

reg PC_EN_IF_, reg_FD_EN_, reg_FD_stall_, reg_FD_flush_,
    reg_DE_EN_, reg_DE_flush_, reg_EM_EN_, reg_EM_flush_, reg_MW_EN_;
reg forward_ctrl_ls_;
reg[1:0] forward_ctrl_A_, forward_ctrl_B_;

initial
  begin
    PC_EN_IF_ = 0;
    reg_FD_EN_ = 0;
    reg_FD_stall_ = 0;
    reg_FD_flush_ = 0;
    reg_DE_EN_ = 0;
    reg_DE_flush_ = 0;
    reg_EM_EN_ = 0;
    reg_EM_flush_ = 0;
    reg_MW_EN_ = 0;
    forward_ctrl_ls_ = 0;
    forward_ctrl_A_ = 0;
    forward_ctrl_B_ = 0;
  end

always @ *
  begin
    // rs1
    if (rs1use_ID && rs1_ID)
      begin
        if (rd_EXE == rs1_ID && RegWrite_EXE)
          begin
            forward_ctrl_A_ <= 2'b01;
          end
        else if (rd_MEM == rs1_ID && RegWrite_MEM && ~DatatoReg_MEM)
          begin
            forward_ctrl_A_ <= 2'b10;
          end
        else if (rd_MEM == rs1_ID && RegWrite_MEM && DatatoReg_MEM)
          begin
            forward_ctrl_A_ <= 2'b11;
          end
        else
          begin
            forward_ctrl_A_ <= 0;
          end
      end
    else
      begin
        forward_ctrl_A_ <= 0;
      end

    // rs2
    if (rs2use_ID && rs2_ID)
      begin
        if (rd_EXE == rs2_ID && RegWrite_EXE)
          begin
            forward_ctrl_B_ <= 2'b01;
          end
        else if (rd_MEM == rs2_ID && RegWrite_MEM && ~DatatoReg_MEM)
          begin
            forward_ctrl_B_ <= 2'b10;
          end
        else if (rd_MEM == rs2_ID && RegWrite_MEM && DatatoReg_MEM)
          begin
            forward_ctrl_B_ <= 2'b11;
          end
        else
          begin
            forward_ctrl_B_ <= 0;
          end
      end
    else
      begin
        forward_ctrl_B_ <= 0;
      end

    // ls
    if (mem_w_EXE && rs2_EXE == rd_MEM && RegWrite_MEM && DatatoReg_MEM)
      begin
        forward_ctrl_ls_ <= 1'b1;
      end
    else
      begin
        forward_ctrl_ls_ <= 0;
      end

    // stall
    if (rs1use_ID && rs1_ID && rd_EXE == rs1_ID && RegWrite_EXE && DatatoReg_EXE)
      begin
        PC_EN_IF_ <= 0;
        reg_FD_stall_ <= 1;
        reg_DE_flush_ <= 1;
        reg_FD_flush_ <= 0;
      end
    else if (rs2use_ID && rs2_ID && rd_EXE == rs2_ID && RegWrite_EXE && DatatoReg_EXE)
      begin
        PC_EN_IF_ <= 0;
        reg_FD_stall_ <= 1;
        reg_DE_flush_ <= 1;
        reg_FD_flush_ <= 0;
      end
    else if (Branch_ID)
      begin
        reg_FD_flush_ <= 1;
        PC_EN_IF_ <= 1;
        reg_FD_stall_ <= 0;
        reg_DE_flush_ <= 0;
      end
    else
      begin
        PC_EN_IF_ <= 1;
        reg_FD_flush_ <= 0;
        reg_FD_stall_ <= 0;
        reg_DE_flush_ <= 0;
      end

    // other
    reg_FD_EN_ = 1;
    reg_DE_EN_ = 1;
    reg_EM_EN_ = 1;
    reg_EM_flush_ = 0;
    reg_MW_EN_ = 1;
  end

assign PC_EN_IF = PC_EN_IF_;
assign reg_FD_EN = reg_FD_EN_;
assign reg_FD_stall = reg_FD_stall_;
assign reg_FD_flush = reg_FD_flush_;
assign reg_DE_EN = reg_DE_EN_;
assign reg_DE_flush = reg_DE_flush_;
assign reg_EM_EN = reg_EM_EN_;
assign reg_EM_flush = reg_EM_flush_;
assign reg_MW_EN = reg_MW_EN_;
assign forward_ctrl_ls = forward_ctrl_ls_;
assign forward_ctrl_A = forward_ctrl_A_;
assign forward_ctrl_B = forward_ctrl_B_;

endmodule
