// (C) 2001-2018 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


/*
  This bridge is responsible for pipelining Avalon transactions as well
  as the backpressure and responses returned to the bridge.  Transactions
  are sent through a stall free pipeline into a "skid FIFO".  The skid
  FIFO ensure that if the master interface backpressures there is enough
  storage elements (in the FIFO) to accept the extra incoming transactions
  that are not allowed to stall (because they flow through a stall free
  pipeline).
  
  The almost full signal of the stall free FIFO is pipelined and sent back to
  the slave side of the bridge to implement backpressure.  This decouples the
  master and slave waitrequests (sort of).  Read data and responses are also
  pipelined from the master interface to the slave interface.  As a result of
  all these stall free pipelines the depth and almost full level of the skid
  FIFO is a function of the pipeline depths.
  
  This bridge does not support clock crossing but in a future version the skid
  FIFO and a new FIFO in the response path will be used to perform clock crossing
  of commands and responses.  When that happens the master and slave will optional
  expose seperate clocks.  In a single clock configuration everything is synchronous
  to the slave clock s_clk including the reset input.  When dual clock support
  is added the bridge will syncronize the input reset accordingly.
  
  This bridge considers the readdata, readdatavalid, response, and
  writeresponsevalid signals to be an upstream response.  All of them will be
  buffered in a stall free pipeline when transporting them between the master to
  slave interface.  The number of pipeline stages is controlled seperately just
  like the command and waitrequets pipelines.


  Revision History:

  1.0 Initial version (lacking clock crossing support)

*/


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module far_reach_avalon_mm_bridge # (
  parameter DATA_WIDTH = 32,
  parameter ADDRESS_WIDTH = 32,
  parameter BURST_WIDTH = 1,  
  parameter DOWNSTREAM_PIPELINE_STAGES = 1,   // must be greater than 0
  parameter WAITREQUEST_PIPELINE_STAGES = 1,  // must be greater than 0
  parameter UPSTREAM_PIPELINE_STAGES = 1,     // must be greater than 0
  parameter SKID_FIFO_DEPTH = 32,
  parameter SKID_FIFO_ALMOST_FULL_LEVEL = 10, // needs to be calculated from SKID_FIFO_DEPTH, DOWNSTREAM_PIPELINE_STAGES, and WAITREQUEST_PIPELINE_STAGES
  parameter MAX_PENDING_READS = 64,           // must be a power of 2 and set to at least 2
  parameter MAX_PENDING_WRITES = 64,          // must be a power of 2 and set to at least 2
  parameter WRITE_TRACKING_ENABLE = 1,        // MAX_PENDING_WRITES should be set to 2 (or more) when WRITE_TRACKING_ENABLE is set to 0
  // these parameters are unused currently
  parameter SKID_FIFO_CLOCK_CROSSING_ENABLE = 0,
  parameter UPSTREAM_CLOCK_CROSSING_ENABLE = 0,
  parameter UPSTREAM_FIFO_DEPTH = 32,
  parameter UPSTREAM_FIFO_ALMOST_FULL_LEVEL = 10 // needs to be calculated from UPSTREAM_FIFO_DEPTH and UPSTREAM_PIPELINE_STAGES
)
(
  input s_clk,
  input m_clk,  // not used, everything will be synchronous to s_clk until clock crossing capabilies are added
  input reset,  // must be synchronous to s_clk and held active long enough to clear out all stall free pipelines

  // slave will consume byte addresses
  input [ADDRESS_WIDTH-1:0] s_address,
  input [DATA_WIDTH-1:0] s_writedata,
  input [(DATA_WIDTH/8)-1:0] s_byteenable,
  input [BURST_WIDTH-1:0] s_burst,
  input s_write,
  input s_read,
  output wire [DATA_WIDTH-1:0] s_readdata,
  output wire s_readdatavalid,
  output wire [1:0] s_response,
  output wire s_writeresponsevalid,
  output wire s_waitrequest,

  // master will drive byte addresses
  output wire [ADDRESS_WIDTH-1:0] m_address,
  output wire [DATA_WIDTH-1:0] m_writedata,
  output wire [(DATA_WIDTH/8)-1:0] m_byteenable,
  output wire [BURST_WIDTH-1:0] m_burst,
  output wire m_write,
  output wire m_read,
  input [DATA_WIDTH-1:0] m_readdata,
  input m_readdatavalid,
  input [1:0] m_response,
  input m_writeresponsevalid,
  input m_waitrequest
);

  localparam DOWNSTREAM_WIDTH = DATA_WIDTH + (DATA_WIDTH/8) + ADDRESS_WIDTH + BURST_WIDTH + 2;  // +2 for read and write signals
  localparam UPSTREAM_WIDTH = DATA_WIDTH + 4;  // +4 for readdatavalid, response, and writeresponsevalid
  localparam PENDING_WRITES_WIDTH = $clog2(MAX_PENDING_WRITES) + 1;
  localparam SKID_FIFO_USED_WIDTH = $clog2(SKID_FIFO_DEPTH);
  localparam READ_BURST_FIFO_USED_WIDTH = $clog2(MAX_PENDING_READS);

  typedef struct packed {
    logic [ADDRESS_WIDTH-1:0] address;
    logic [DATA_WIDTH-1:0] writedata;
    logic [(DATA_WIDTH/8)-1:0] byteenable;
    logic [BURST_WIDTH-1:0] burst;
    logic read;
    logic write;
  } command_struct;

  typedef struct packed {
    logic [DATA_WIDTH-1:0] readdata;
    logic readdatavalid;
    logic [1:0] response;
    logic writeresponsevalid;
  } response_struct;

  command_struct downstream_pipeline_input_data;
  command_struct downstream_pipeline_output_data;

  command_struct skid_fifo_output_data;
  logic skid_fifo_almost_full;
  logic skid_fifo_empty;
  logic skid_fifo_read;
  logic skid_fifo_write;
  logic [SKID_FIFO_USED_WIDTH-1:0] skid_fifo_used;

  response_struct response_pipeline_input_data;
  response_struct response_pipeline_output_data;

  logic enable;               // enable that flows with the command and write data through stall free pipeline
  logic write_enable;
  logic read_enable;
  logic read_waitrequest;
  logic write_waitrequest;
  logic control_waitrequest;  // pipelined copy of the skid FIFO almost full
  
  // tracking start of every write burst and using that to increment the pending writes counter.  When write responses return the counter decrements.
  logic [BURST_WIDTH-1:0] write_burst_counter;
  logic write_burst_counter_load;
  logic write_burst_counter_decrement;
  logic [PENDING_WRITES_WIDTH-1:0] pending_writes_counter;
  logic pending_writes_counter_increment;
  logic pending_writes_counter_decrement; 
  
  // tracking read responses with a counter.  Every time the counter reaches the buffered burst length the outstanding read is considered complete.
  logic [BURST_WIDTH-1:0] read_burst_counter;
  logic read_burst_counter_load;
  logic read_burst_counter_increment;
  logic [BURST_WIDTH-1:0] read_burst_fifo_input_data;
  logic read_burst_fifo_empty;
  logic read_burst_fifo_full;
  logic [BURST_WIDTH-1:0] read_burst_fifo_output_data;
  logic read_burst_fifo_read;
  logic read_burst_fifo_write;
  logic [READ_BURST_FIFO_USED_WIDTH-1:0] read_burst_fifo_used;




/************************************************************************************/  
/************************** Downstream Pipelining ***********************************/
  assign downstream_pipeline_input_data.address = s_address;
  assign downstream_pipeline_input_data.writedata = s_writedata;
  assign downstream_pipeline_input_data.byteenable = s_byteenable;
  assign downstream_pipeline_input_data.burst = s_burst;
  assign downstream_pipeline_input_data.read = s_read;
  assign downstream_pipeline_input_data.write = s_write;
  
  far_reach_avalon_mm_bridge_stall_free_pipeline # (
    .DATA_WIDTH  (DOWNSTREAM_WIDTH),
    .DEPTH       (DOWNSTREAM_PIPELINE_STAGES)
  ) downstream_pipeline
  (
    .clk         (s_clk),
    .input_data  (downstream_pipeline_input_data),
    .output_data (downstream_pipeline_output_data)
  );
 
  far_reach_avalon_mm_bridge_stall_free_pipeline # (
    .DATA_WIDTH  (1),
    .DEPTH       (DOWNSTREAM_PIPELINE_STAGES)
  ) downstream_enable_pipeline
  (
    .clk         (s_clk),
    .input_data  (enable),
    .output_data (skid_fifo_write)
  );
  
  far_reach_avalon_mm_bridge_stall_free_pipeline # (
    .DATA_WIDTH  (1),
    .DEPTH       (WAITREQUEST_PIPELINE_STAGES)
  ) waitrequest_pipeline
  (
    .clk         (s_clk),
    .input_data  (skid_fifo_almost_full),
    .output_data (control_waitrequest)
  );
/********************* End of Downstream Pipelining ********************************/
/***********************************************************************************/  



/***********************************************************************************/
/************************ Master Command Logic *************************************/
  scfifo # (
    .lpm_width               (DOWNSTREAM_WIDTH), 
    .lpm_widthu              (SKID_FIFO_USED_WIDTH),
    .lpm_numwords            (SKID_FIFO_DEPTH),
    .almost_full_value       (SKID_FIFO_ALMOST_FULL_LEVEL),
    .lpm_showahead           ("ON"),
    .use_eab                 ("ON"),
    .add_ram_output_register ("ON"),
    .underflow_checking      ("OFF"),
    .overflow_checking       ("OFF")
  ) skid_fifo
  (
    .sclr                    (reset),
    .clock                   (s_clk),
    .data                    (downstream_pipeline_output_data),
    .almost_full             (skid_fifo_almost_full),
    .usedw                   (skid_fifo_used),         // not used, only included for simulation purposes
    .empty                   (skid_fifo_empty),
    .q                       (skid_fifo_output_data),
    .rdreq                   (skid_fifo_read),
    .wrreq                   (skid_fifo_write)
  );
  assign skid_fifo_read = (skid_fifo_empty == 1'b0) & (m_waitrequest == 1'b0);
  
  assign m_address = skid_fifo_output_data.address;
  assign m_writedata = skid_fifo_output_data.writedata;
  assign m_byteenable = skid_fifo_output_data.byteenable;
  assign m_burst = skid_fifo_output_data.burst;
  assign m_write = skid_fifo_output_data.write & (skid_fifo_empty == 1'b0);
  assign m_read = skid_fifo_output_data.read & (skid_fifo_empty == 1'b0);
/******************** End of Master Command Logic **********************************/
/***********************************************************************************/



/***********************************************************************************/
/****************************** Response Logic *************************************/
  assign response_pipeline_input_data.readdata = m_readdata;
  assign response_pipeline_input_data.readdatavalid = m_readdatavalid;
  assign response_pipeline_input_data.response = m_response;
  assign response_pipeline_input_data.writeresponsevalid = m_writeresponsevalid;

  far_reach_avalon_mm_bridge_stall_free_pipeline # (
    .DATA_WIDTH  (UPSTREAM_WIDTH),
    .DEPTH       (UPSTREAM_PIPELINE_STAGES)
  ) upstream_pipeline
  (
    .clk         (s_clk),
    .input_data  (response_pipeline_input_data),
    .output_data (response_pipeline_output_data)
  );

  // for now there is no clock crossing, otherwise these would go through a DCFIFO first
  assign s_readdata = response_pipeline_output_data.readdata;
  assign s_readdatavalid = response_pipeline_output_data.readdatavalid;
  assign s_response = response_pipeline_output_data.response;
  assign s_writeresponsevalid = response_pipeline_output_data.writeresponsevalid;
/**************************** End of Response Logic ********************************/
/***********************************************************************************/



/***********************************************************************************/
/************************** Slave Waitrequest Logic ********************************/

  // write response tracking
  always @ (posedge s_clk)
  begin
    if (reset)
    begin
      write_burst_counter <= 0;
    end
    else if (write_burst_counter_load == 1)
    begin
      write_burst_counter <= s_burst - 1'b1;
    end
    else if (write_burst_counter_decrement == 1)
    begin
      write_burst_counter <= write_burst_counter - 1'b1;
    end
  end

  // hold this counter at 0 if WRITE_TRACKING_ENABLE is set to 0
  assign write_burst_counter_load = (WRITE_TRACKING_ENABLE == 1) & write_enable & (write_burst_counter == 0);
  assign write_burst_counter_decrement = (WRITE_TRACKING_ENABLE == 1) & write_enable & (write_burst_counter != 0);


  always @ (posedge s_clk)
  begin
    if (reset)
    begin
      pending_writes_counter <= 0;
    end
    else
    begin
      case ({pending_writes_counter_increment, pending_writes_counter_decrement})
        2'b01:  pending_writes_counter <= pending_writes_counter - 1'b1;
        2'b10:  pending_writes_counter <= pending_writes_counter + 1'b1;
        default:  pending_writes_counter <= pending_writes_counter;  // either no change or inc & dec at the same time
      endcase
    end
  end

  // pending writes counter will not increment due to write_burst_counter_load being held at 0 if write tracking is disabled
  // when write tracking (responses) is disabled the write response will be grounded by hw.tcl file
  assign pending_writes_counter_increment = write_burst_counter_load;
  assign pending_writes_counter_decrement = s_writeresponsevalid;



  // read response tracking
  scfifo # (
    .lpm_width               (BURST_WIDTH),
    .lpm_widthu              (READ_BURST_FIFO_USED_WIDTH),    
    .lpm_numwords            (MAX_PENDING_READS),
    .lpm_showahead           ("ON"),
    .use_eab                 ("ON"),
    .add_ram_output_register ("ON"),
    .underflow_checking      ("OFF"),
    .overflow_checking       ("OFF")
  ) read_burst_fifo
  (
    .sclr                    (reset),
    .clock                   (s_clk),
    .data                    (read_burst_fifo_input_data),
    .empty                   (read_burst_fifo_empty),
    .full                    (read_burst_fifo_full),
    .usedw                   (read_burst_fifo_used),         // not used, only included for simulation purposes
    .q                       (read_burst_fifo_output_data),
    .rdreq                   (read_burst_fifo_read),
    .wrreq                   (read_burst_fifo_write)
  );
  
  assign read_burst_fifo_input_data = s_burst;
  assign read_burst_fifo_write = read_enable;
  assign read_burst_fifo_read = read_burst_counter_load;


  always @ (posedge s_clk)
  begin
    if (reset)
    begin
      read_burst_counter <= 'b1;
    end
    else if (read_burst_counter_load)
    begin
      read_burst_counter <= 'b1;
    end
    else if (read_burst_counter_increment)
    begin
      read_burst_counter <= read_burst_counter + 1'b1;
    end
  end
  
  assign read_burst_counter_load = (read_burst_fifo_empty == 0) & (read_burst_fifo_output_data == read_burst_counter);
  assign read_burst_counter_increment = s_readdatavalid;  // load will win over increment
  
  
  // command pipeline enable and slave backpressuring
  assign write_enable = (s_write & (control_waitrequest == 0)) & 
                        ((WRITE_TRACKING_ENABLE == 1)? (pending_writes_counter[PENDING_WRITES_WIDTH-1] == 0) : 1'b1);  // only backpressure writes when tracking them
  assign read_enable = (s_read & (control_waitrequest == 0) & (read_burst_fifo_full == 0));
  assign enable = write_enable | read_enable;
  assign read_waitrequest = (control_waitrequest == 1) | (read_burst_fifo_full == 1);
  /* Using pending writes counter MSB to backpressure will stop slave on the 2nd beat of a burst when the counter reaches max pending writes.  Although not ideal since
     this causes that burst to stall until some write responses return, this is the only way to keep the write_waitrequest logic simple to avoid a deep combinatorial
     path back to the master.  If write responses are not enabled then write_waitrequest is only dependend on control_waitrequest.
  */
  assign write_waitrequest = (control_waitrequest == 1) | ((WRITE_TRACKING_ENABLE == 1)? (pending_writes_counter[PENDING_WRITES_WIDTH-1] == 1) : 1'b0);
  assign s_waitrequest = read_waitrequest | write_waitrequest;


/*********************** End of Slave Waitquest Logic ******************************/
/***********************************************************************************/

endmodule
