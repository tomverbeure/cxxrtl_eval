
module VexRiscv(
  input               clk_cpu,
  input               clk_cpu_reset_,

  output              iBus_cmd_valid,
  input               iBus_cmd_ready,
  output     [31:0]   iBus_cmd_payload_pc,

  input               iBus_rsp_valid,
  input               iBus_rsp_payload_error,
  input      [31:0]   iBus_rsp_payload_inst,

  output              dBus_cmd_valid,
  input               dBus_cmd_ready,
  output              dBus_cmd_payload_wr,
  output     [31:0]   dBus_cmd_payload_address,
  output     [31:0]   dBus_cmd_payload_data,
  output     [1:0]    dBus_cmd_payload_size,

  input               dBus_rsp_ready,
  input               dBus_rsp_error,
  input      [31:0]   dBus_rsp_data,

  input               timerInterrupt,
  input               externalInterrupt,
  input               softwareInterrupt
  );

  wire          avm_data_read;
  wire          avm_data_write;
  wire          avm_data_waitrequest;
  wire [3:0]    avm_data_byteenable;
  wire [31:0]   avm_data_address;
  wire [31:0]   avm_data_writedata;

  wire          avm_data_readdatavalid;
  wire [31:0]   avm_data_readdata;

  riscV u_orca(
       .clk(clk_cpu),
       .reset(!clk_cpu_reset_),

       .coe_to_host                     (),
       .coe_from_host                   (32'd0),
       .coe_program_counter             (),

       .avm_instruction_read            (iBus_cmd_valid),
       .avm_instruction_waitrequest     (!iBus_cmd_ready),
       .avm_instruction_address         (iBus_cmd_payload_pc),
       .avm_instruction_byteenable      (),
       .avm_instruction_write           (),
       .avm_instruction_writedata       (),
       .avm_instruction_lock            (),

       .avm_instruction_readdatavalid   (iBus_rsp_valid),
       .avm_instruction_readdata        (iBus_rsp_payload_inst),
       .avm_instruction_response        (2'b00),            // Not used in ORCA core

       .avm_data_read                   (avm_data_read),
       .avm_data_write                  (avm_data_write), 
       .avm_data_waitrequest            (avm_data_waitrequest),
       .avm_data_address                (avm_data_address),
       .avm_data_byteenable             (avm_data_byteenable),
       .avm_data_writedata              (avm_data_writedata),
       .avm_data_lock                   (),

       .avm_data_readdatavalid          (avm_data_readdatavalid), 
       .avm_data_readdata               (avm_data_readdata),
       .avm_data_response               (2'b00),
  );


  reg [1:0]    data_addr_lsb;
  reg [1:0]    data_size;

  always @(*) begin
      data_addr_lsb      = 2'b00;
      data_size          = 2'b00;

      case(avm_data_byteenable)
          // Byte request
          4'b0001: begin
              data_addr_lsb      = 2'b00;
              data_size          = 2'b00;
          end
          4'b0010: begin
              data_addr_lsb      = 2'b01;
              data_size          = 2'b00;
          end
          4'b0100: begin
              data_addr_lsb      = 2'b10;
              data_size          = 2'b00;
          end
          4'b1000: begin
              data_addr_lsb      = 2'b11;
              data_size          = 2'b00;
          end
          // word16 request
          4'b0011: begin
              data_addr_lsb      = 2'b00;
              data_size          = 2'b01;
          end
          4'b1100: begin
              data_addr_lsb      = 2'b10;
              data_size          = 2'b01;
          end
          // word32 request
          4'b1111: begin
              data_addr_lsb      = 2'b00;
              data_size          = 2'b10;
          end
      endcase
  end

  assign dBus_cmd_valid             = avm_data_read | avm_data_write;
  assign dBus_cmd_payload_address   = {avm_data_address[31:2], data_addr_lsb};
  assign dBus_cmd_payload_wr        = avm_data_write;
  assign dBus_cmd_payload_size      = data_size;
  assign dBus_cmd_payload_data      = avm_data_writedata;
  //assign avm_data_waitrequest       = !dBus_cmd_ready;
  assign avm_data_waitrequest       = 1'b0;

  assign avm_data_readdatavalid     = dBus_rsp_ready;
  assign avm_data_readdata          = dBus_rsp_data;

endmodule

// 800-746-6216
//
