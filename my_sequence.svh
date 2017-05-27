 import uvm_pkg::*;
`include "uvm_macros.svh"

class my_transaction extends uvm_sequence_item;

  `uvm_object_utils(my_transaction)

  //rand bit cmd;
  //rand int addr;
  //rand int data;

  //constraint c_addr { addr >= 0; addr < 256; }
  //constraint c_data { data >= 0; data < 256; }

  rand bit tms;
  rand bit tdi;
  rand bit trstn;

  function new (string name = "");
    super.new(name);
  endfunction

endclass: my_transaction

// ================================================================== 

class my_sequence extends uvm_sequence#(my_transaction);

  `uvm_object_utils(my_sequence)

  function new (string name = "");
    super.new(name);
  endfunction

  task body;
    repeat(8) begin
      req = my_transaction::type_id::create("req");
      start_item(req);

      //if (!req.randomize()) begin
      //  `uvm_error("MY_SEQUENCE", "Randomize failed.");
      //end

      // If using ModelSim, which does not support randomize(),
      // we must randomize item using traditional methods, like

//       req.cmd = $urandom;
//       req.addr = $urandom_range(0, 255);
//       req.data = $urandom_range(0, 255);

	req.tms   = $urandom;
	req.trstn = $urandom;
	req.tdi   = $urandom;

      finish_item(req);
    end
  endtask: body

endclass: my_sequence

// ================================================================== 

class my_driver extends uvm_driver #(my_transaction);
	
  `uvm_component_utils(my_driver)

  virtual dut_if dut_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    // Get interface reference from config database
    if(!uvm_config_db#(virtual dut_if)::get(this, "", "dut_vif", dut_vif)) 
    begin
      `uvm_error("", "uvm_config_db::get failed")
    end
    else
    begin
      `uvm_warning("", "Configuration database successfully accessed!")
    end
  endfunction 

  task run_phase(uvm_phase phase);
    // First toggle reset
    dut_vif.trstn_pad_i = 1;
    @(posedge dut_vif.tck_pad_i);
    #1;
    dut_vif.trstn_pad_i = 0;
    
    // Now drive normal traffic
    forever begin
      seq_item_port.get_next_item(req);

      // Wiggle pins of DUT
      dut_vif.trstn_pad_i  = 0;
      dut_vif.tms_pad_i    = req.tms;
      dut_vif.tdi_pad_i    = req.tdi;
      @(posedge dut_vif.tck_pad_i);

      seq_item_port.item_done();
    end
  endtask

endclass: my_driver

