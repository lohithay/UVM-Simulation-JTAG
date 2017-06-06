import uvm_pkg::*;
`include "uvm_macros.svh"
///////////////////////////////////////////////////////////////////////
////                                                               ////
////  my_sequence.svh                                              ////
////                                                               ////
////  This file has been edited for the Project : UVM              ////
////  Simulationsmodell eines JTAG-Interfaces                      ////
////                                                               ////
////  Author(s):                                                   ////
////    Serin Varghese                                             ////
////                                                               ////
////  Notes: Codes adapted from EDA Playground example files       ////
////                                                               ////
////  This the header file that contains the modules/blocks of     ////
////  uvm. This is called from the testbench.sv file               ////
////                                                               ////
////                                                               ////
///////////////////////////////////////////////////////////////////////
//// These files contain the following UVM blocks(modules)         ////
//// - Transaction                                                 ////
//// - Sequencer                                                   ////
//// - Driver                                                      ////
///////////////////////////////////////////////////////////////////////

// Imports


// ================================================================== //
//                                                                    //
// TRANSACTION                                                        //
//                                                                    //
// ================================================================== //
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

// ================================================================== //
//                                                                    //
// SEQUENCER                                                          //
//                                                                    //
// ================================================================== //
class my_sequence extends uvm_sequence#(my_transaction);

	`uvm_object_utils(my_sequence)

	function new (string name = "");
		super.new(name);
	endfunction

	task body;
		repeat(100)
		begin
			req = my_transaction::type_id::create("req");
			start_item(req);
			// If using ModelSim, which does not support randomize(),
			// we must randomize item using traditional methods, like
			//       req.cmd = $urandom;
			//       req.addr = $urandom_range(0, 255);
			//       req.data = $urandom_range(0, 255);
			
			//req.tms   = $urandom;
			//req.trstn = $urandom;
			//req.tdi   = $urandom;
			`uvm_warning("", "Sequence sent!")
			finish_item(req);  // Waiting for the driver to send the item_done() command
		end
	endtask: body

endclass: my_sequence

// ================================================================== //
//                                                                    //
// DRIVER                                                             //
//                                                                    //
// ================================================================== //
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
		//Writing code to test IDCODE
		integer complete = 0;
		integer init     = 1;
		
		// First toggle reset
		dut_vif.trstn_pad_i = 0;
		@(posedge dut_vif.tck_pad_i);
		#1;
		dut_vif.trstn_pad_i = 1;		
		
		//forever
		while(complete == 0)
		begin
			seq_item_port.get_next_item(req);
			//**working
			// @(posedge dut_vif.tck_pad_i);
			// dut_vif.trstn_pad_i = 0;
			// @(negedge dut_vif.tck_pad_i);
			// dut_vif.trstn_pad_i = 1;
			//**till here
			if(dut_vif.test_logic_reset_o) // The DUT enters the Test Logic Reset STATE
			begin
				dut_vif.tms_pad_i = 0;
				`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
			end
			else if(dut_vif.run_test_idle_o)// The DUT enters the Run Test Idle STATE
			begin	
				dut_vif.tms_pad_i = 1;		
				`uvm_info("DUT", $sformatf("Run Test Idle STATE"), UVM_MEDIUM)	
				//complete = 1; //process completed				
			end			
			seq_item_port.item_done();
			@(posedge dut_vif.tck_pad_i);
		end
		
 
  endtask
endclass: my_driver