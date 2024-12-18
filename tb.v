`timescale 1ns / 10ps

`ifdef syn
    `include "tsmc18.v" 
    `include "top_syn.v" 
`else
   // `include "top.v" 
 
  
  `include "imm.v"
  `include "Hazard.v"
  `include "Forward.v"
  `include "Decoder.v"
  `include "adder.v"
  `include "Controller.v"
  `include "Branch_compare.v"
  //`include "fetch.v"
  `include "Top.v"
  `include "ALU.v"
  `include "IFID.v"
  `include "IDEX.v"
  `include "EXMEM.v"
  `include "mux_2to1.v"
  `include "mux_3to1.v"
  `include "mux_4to1.v"
  `include "pc.v"
`include "MEMWB.v"

`include "const.svh"
`endif

`include "memory.v"  
`include "registerFile.v"

module tb();
  reg clk, rst;
  wire [31:0] ir, readdata_MEM, pc_out, alu_DMEM, writedata_DMEM;
  wire memwrite_MEM;

  Top CPU1(
    .clk(clk),
    .rst(rst),
    .ir(ir),
    .readdata_MEM(readdata_MEM),
    .pc_out(pc_out),
    .alu_DMEM(alu_DMEM),
    .writedata_DMEM(writedata_DMEM),
    .memwrite_MEM(memwrite_MEM)
  );

  mem irmem(
	  .clk(clk),
    .wen(1'b0),
    .addr(pc_out),
	  .wdata(),
    .rdata(ir)
  );

  mem datamem(
	  .clk(clk),
    .wen(memwrite_MEM),
    .addr(alu_DMEM),
	  .wdata(writedata_DMEM),
    .rdata(readdata_MEM)
  );

  // Annotate timing information for synthesis
  `ifdef SYN
    initial $sdf_annotate("top_syn.sdf", CPU);
  `endif 
  
  // clk reset
  initial begin : clk_reset
    clk = 1'b1;
    rst = 1'b1; 
    #10 rst = 1'b0; // Release reset after 10 time units
    #1000 
    $writememb("ir_memory.txt",irmem.mem);
    $writememb("data_memory.txt", datamem.mem);
    $finish;
  end

  // read prog to mem
  initial begin : prog_load
    // Load program instructions into memory
    $readmemb("./test/irtest.txt", irmem.mem);     
  end

  // Dump waveform for debugging
  initial begin : wave
    $dumpfile("top.fsdb");
    $dumpvars;
  end

  // Generate clock signal
  always #5 clk = ~clk;

  // Check CPU status
  always @(posedge clk) begin
    // Monitor signals at the rising edge of the clock
    $display("Time: %0t | pc_IF: %d| datamem.rdata: %d| datamem.addr: %d| MEMWB.readdata_WB: %d| x5: %d| x6: %d| x7: %d | x8: %d ", 
             $time, CPU1.IFID.pc_IF, datamem.rdata, datamem.addr, CPU1.MEMWB.readdata_WB, CPU1.regfile.registers[5], CPU1.regfile.registers[6], CPU1.regfile.registers[7], CPU1.regfile.registers[8]);


     // $display("Time: %0t | pc_IF: %d| | OP1_: %d|OP2_: %d| IDEX.rs2_EX: %d|addr: %d| MEM[4]: %d,wen: %d| x5: %d| x6: %d| x7: %d | x8: %d ", 
        //     $time, CPU1.IFID.pc_IF, CPU1.ALU.operand1, CPU1.ALU.operand2,CPU1.IDEX.rs2_EX, datamem.addr, datamem.mem[4], datamem.wen, CPU1.regfile.registers[5], CPU1.regfile.registers[6], CPU1.regfile.registers[7], CPU1.regfile.registers[8]);
  //$display("Time: %0t | pc_IF: %d|control %d |IDEX_memwrite: %d| EXMEM_memwrite: %d,datamem.wen: %d", 
           //  $time, CPU1.IFID.pc_IF,CPU1.controller.memwrite,CPU1.IDEX.memwrite_EX,CPU1.EXMEM.memwrite_MEM, datamem.wen);
  end
endmodule