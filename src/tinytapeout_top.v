
module cchan_serv_port (
  input [7:0] io_in,
  output [7:0] io_out
);
  wire clk = io_in[0];
  wire buf_clk = io_in[1];
  wire buf_sel = io_in[2];
  wire rst = io_in[3];

  reg [31:0] i_ibus_rdt;  // buf_sel = 0
  reg [31:0] i_dbus_rdt;  // buf_sel = 1

  reg [31:0] o_dbus_dat;  // buf_sel = 0
  reg [15:0] o_ibus_adr; reg [15:0] o_dbus_adr;  // buf_sel = 1

  reg [2:0] counter;  // increments on every buf_clk, to sequentially fill in 4-bit nibbles of the buffer.

  // io_in:
  // - 0: system clock
  // - 1: buffer clock
  // - 2: buffer select
  // - 3: reset

  always @(posedge buf_clk) begin
    if !io_in[2] begin
      i_ibus_rdt[3 + counter*4:0 + counter*4] <= io_in[7:4];
      // Can you <= assign to an output...?
      io_out[3:0] <= o_dbus_dat[3 + counter*4:0 + counter*4];
    end else begin
      i_dbus_rdt[3 + counter*4:0 + counter*4] <= io_in[7:4];
      if counter < 4 begin
        io_out[3:0] <= o_ibus_adr[3 + counter*4:0 + counter*4];
      end else begin
        io_out[3:0] <= o_dbus_adr[3 + (counter-4)*4:0 + (counter-4)*4];
      end
    end
    counter <= counter + 1;
  end

  always @(posedge reset) begin
    counter <= 0;
  end

  serv_rf_top
    #(.WITH_CSR (0))
  cpu
    (.clk(clk),
     .i_rst(rst),
     .i_timer_irq(0),  // No interrupts!
     .o_ibus_adr(o_ibus_adr), // bits [9:2] out - 256 byte memory lol
     .o_ibus_cyc(),  // Ignore, no idea what this does
     .i_ibus_rdt(i_ibus_rdt),  // FROM INPUT BUFFER
     .i_ibus_ack(1'b1), // Assume that when you clock the processor all inputs are ready

     .o_dbus_adr(o_dbus_adr), // bits [9:2] out - 256 byte memory lol
     .o_dbus_dat(o_dbus_dat), // TO OUTPUT BUFFER
     .o_dbus_sel(),  // Ignore, always write all 4 bytes
     .o_dbus_we(),  // Ignore, no idea what this does
     .o_dbus_cyc(),  // Ignore, no idea what this does
     .i_dbus_rdt(i_dbus_rdt),  // FROM INPUT BUFFER
     .i_dbus_ack(1'b1), // Assume that when you clock the processor all inputs are ready
     .o_ext_rs1(),
     .o_ext_rs2(),
     .o_ext_funct3(),
     .i_ext_rd(32'b0),
     .i_ext_ready(0),
     .o_mdu_valid());

endmodule
