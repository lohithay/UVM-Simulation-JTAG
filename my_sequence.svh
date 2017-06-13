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

// DEFINE TO TEST WHICH INSTRUCTION TO EXECUTE
//`define BYPASS_INSTR
`define IDCODE_INSTR
//`define SAMPLE_INSTR
//`define EXTEST_INSTR
//`define INTEST_INSTR

// Imports
import uvm_pkg::*;
`include "uvm_macros.svh"
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

			if(!req.randomize())
			begin
				`uvm_warning("", "Randomization failed!")
			end
			// If using ModelSim, which does not support randomize(),
			// we must randomize item using traditional methods, like
			//       req.cmd = $urandom;
			//       req.addr = $urandom_range(0, 255);
			//       req.data = $urandom_range(0, 255);

			//`uvm_warning("", "Sequence sent!")
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
		integer init     = 0;
		integer count    = 0;
		integer polarity = 0;
		// First toggle reset
		if(init == 0)
		begin
			dut_vif.trstn_pad_i = 0;
			@(posedge dut_vif.tck_pad_i);
			#1;
			dut_vif.trstn_pad_i = 1;		
			init = 1;
		end
				
		`ifdef BYPASS_INSTR
		//forever
		while(count<=11 && init ==1)
		begin
			seq_item_port.get_next_item(req);
			case(count)
				
				0: begin //Test Logic Reset STATE
					if(dut_vif.test_logic_reset_o) // The DUT enters the Test Logic Reset STATE
					begin
						dut_vif.tdi_pad_i = 1;//Initializing the input port to 1'b1
						dut_vif.tms_pad_i = 0;
						`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
						count++;
					end
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
				
				1: begin //Run Test Idle STATE
					if(dut_vif.run_test_idle_o)// The DUT enters the Run Test Idle STATE
					begin	
						dut_vif.tms_pad_i = 1;
						`uvm_info("DUT", $sformatf("Run Test Idle STATE"), UVM_MEDIUM)	
						count++;
						//complete = 1; //process completed				
					end		
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
				
				2: begin //Select DR Scan STATE
					dut_vif.tms_pad_i = 1;		
					`uvm_info("DUT", $sformatf("Select DR Scan STATE"), UVM_MEDIUM)	
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
					
				3: begin //Select IR Scan STATE		
					dut_vif.tms_pad_i = 0;		
					`uvm_info("DUT", $sformatf("Select IR Scan STATE"), UVM_MEDIUM)	
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
					
				 4: begin //capture ir state
					 dut_vif.tms_pad_i = 0;		
					 `uvm_info("DUT", $sformatf("capture ir state"), UVM_MEDIUM)	
					 count++;					
					 seq_item_port.item_done();
					 @(posedge dut_vif.tck_pad_i);
				 end
				 
				5: begin //SHIFT IR STATE 
					for(int i=0; i<=2; i++)//SHIFTING THE IR WITH 4 1's
					begin
						if(i!=0)  seq_item_port.get_next_item(req);
						
						dut_vif.tms_pad_i = 0;		
						dut_vif.tdi_pad_i = 1;		
						`uvm_info("DUT", $sformatf("Shift IR STATE"), UVM_MEDIUM)	
						//count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);
					end
					
					//Moving to the next state
					count++;
					seq_item_port.get_next_item(req);
					dut_vif.tms_pad_i = 1;		
					//`uvm_info("DUT", $sformatf("Shift IR STATE"), UVM_MEDIUM)	
					//count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
					
				end
					 
				6: begin //EXIT1 IR STATE 
						dut_vif.tms_pad_i = 1;		
						`uvm_info("DUT", $sformatf("EXIT1 IR STATE"), UVM_MEDIUM)	
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 7: begin //UPDATE IR STATE 
						dut_vif.tms_pad_i = 1;		
						`uvm_info("DUT", $sformatf("UPDATE IR STATE"), UVM_MEDIUM)	
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 8: begin //SELECT DR STATE 
						dut_vif.tms_pad_i = 0;		
						`uvm_info("DUT", $sformatf("SELECT DR STATE"), UVM_MEDIUM)	
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end

				 9: begin //CAPTURE DR STATE 
						dut_vif.tms_pad_i = 0;		
						`uvm_info("DUT", $sformatf("CAPTURE DR STATE"), UVM_MEDIUM)	
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 10: begin //SHIFT DR STATE 
						for(int i=0; i<=10; i++)//TDI to TDO via BYPASS Register x10
						begin
							if(i!=0)  seq_item_port.get_next_item(req);
							dut_vif.tms_pad_i = 0;	
							dut_vif.tdi_pad_i = req.tdi;
							`uvm_info("DUT", $sformatf("SHIFT DR STATE"), UVM_MEDIUM)	
							`uvm_info("DUT", $sformatf("Received TDI=%b, TDO=%b", dut_vif.tdi_pad_i, dut_vif.tdo_pad_o), UVM_MEDIUM)							
							seq_item_port.item_done();
							@(posedge dut_vif.tck_pad_i);			
						end 
						count++;
				 end
				 
				 11: begin
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);
						count++;
				 end

				default: break;
			endcase
		end //while loop
		`endif //BYPASS INSTR
		
		`ifdef IDCODE_INSTR
		while(count<=11 && init ==1)
		begin
			seq_item_port.get_next_item(req);
			case(count)
				
				0: begin //Test Logic Reset STATE
					if(dut_vif.test_logic_reset_o) // The DUT enters the Test Logic Reset STATE
					begin
						dut_vif.tms_pad_i = 0;
						`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
						count++;
					end
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
				
				1: begin //Run Test Idle STATE
					if(dut_vif.run_test_idle_o)// The DUT enters the Run Test Idle STATE
					begin	
						dut_vif.tms_pad_i = 1;
						`uvm_info("DUT", $sformatf("Run Test Idle STATE"), UVM_MEDIUM)	
						count++;
						//complete = 1; //process completed				
					end		
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
				
				2: begin //Select DR Scan STATE
					dut_vif.tms_pad_i = 1;		
					`uvm_info("DUT", $sformatf("Select DR Scan STATE"), UVM_MEDIUM)	
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
					
				3: begin //Select IR Scan STATE		
					dut_vif.tms_pad_i = 0;
					dut_vif.tdi_pad_i = 0; //For the first bit that will be shifted into the Instruction Register
					`uvm_info("DUT", $sformatf("Select IR Scan STATE"), UVM_MEDIUM)	
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
					
				 4: begin //capture ir state
					 dut_vif.tms_pad_i = 0;		
					 `uvm_info("DUT", $sformatf("capture ir state"), UVM_MEDIUM)	
					 count++;					
					 seq_item_port.item_done();
					 @(posedge dut_vif.tck_pad_i);
				 end
				 
				5: begin //SHIFT IR STATE 
					for(int i=0; i<=2; i++)//SHIFTING THE IR WITH 4 1's
					begin
						if(i!=0)  seq_item_port.get_next_item(req);
						dut_vif.tms_pad_i = 0;		
						if(i==0) dut_vif.tdi_pad_i = 0;		
						else if(i==1) dut_vif.tdi_pad_i = 1;
						else if(i==2) dut_vif.tdi_pad_i = 0;
						`uvm_info("DUT", $sformatf("Shift IR STATE"), UVM_MEDIUM)	
						//count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);
					end
					
					//Moving to the next state
					count++;
					seq_item_port.get_next_item(req);
					dut_vif.tms_pad_i = 1;		
					//`uvm_info("DUT", $sformatf("Shift IR STATE"), UVM_MEDIUM)	
					//count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
					
				end
					 
				6: begin //EXIT1 IR STATE 
						dut_vif.tms_pad_i = 1;		
						`uvm_info("DUT", $sformatf("EXIT1 IR STATE"), UVM_MEDIUM)	
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 7: begin //UPDATE IR STATE 
						dut_vif.tms_pad_i = 1;		
						`uvm_info("DUT", $sformatf("UPDATE IR STATE"), UVM_MEDIUM)	
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 8: begin //SELECT DR STATE 
						dut_vif.tms_pad_i = 0;		
						`uvm_info("DUT", $sformatf("SELECT DR STATE"), UVM_MEDIUM)	
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end

				 9: begin //CAPTURE DR STATE 
						dut_vif.tms_pad_i = 0;		
						`uvm_info("DUT", $sformatf("CAPTURE DR STATE"), UVM_MEDIUM)	
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 10: begin //SHIFT DR STATE 
						for(int i=0; i<=31; i++)//Shfting out the 32 bit IDCODE
						begin
							if(i!=0)  seq_item_port.get_next_item(req);
							dut_vif.tms_pad_i = 0;	
							dut_vif.tdi_pad_i = req.tdi;
							`uvm_info("DUT", $sformatf("SHIFT DR STATE"), UVM_MEDIUM)	
							`uvm_info("DUT", $sformatf("TDO=%b", dut_vif.tdo_pad_o), UVM_MEDIUM	)						
							seq_item_port.item_done();
							@(posedge dut_vif.tck_pad_i);			
						end 
						count++;
				 end
				 
				 11: begin
						init++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);
						break;
				 end

				default: break;				
			endcase
		end //while loop
		`endif //IDCODE INSTR
		
		if(init == 3)
		begin
			`uvm_warning("", "TEST COMPLETED!!")
		end
		// `ifdef EXTEST_INSTR
		// `endif EXTEST_INSTR
		
		// `ifdef INTEST_INSTR
		// `endif INTEST_INSTR
		
		// `ifdef SAMPLE_INSTR
		// `endif SAMPLE_INSTR
		
		
		
			 
	endtask
endclass: my_driver
/*
// ================================================================== //
//                                                                    //
// MONITOR_BEFORE                                                     //
//                                                                    //
// ================================================================== //
class jtag_monitor_before extends uvm_monitor;
     `uvm_component_utils(jtag_monitor_before)
 
     uvm_analysis_port#(my_transaction) mon_ap_before;
 
     virtual dut_if vif;
 
     function new(string name, uvm_component parent);
          super.new(name, parent);
     endfunction: new
 
     function void build_phase(uvm_phase phase);
          super.build_phase(phase);
 
          void'(uvm_resource_db#(virtual dut_if)::read_by_name (.scope("ifs"), .name("dut_if"), .val(vif)));
          mon_ap_before = new(.name("mon_ap_before"), .parent(this));
     endfunction: build_phase
 
     task run_phase(uvm_phase phase);
          
     endtask: run_phase
endclass: jtag_monitor_before

// ================================================================== //
//                                                                    //
// MONITOR_AFTER                                                      //
//                                                                    //
// ================================================================== //
class jtag_monitor_after extends uvm_monitor;
     `uvm_component_utils(jtag_monitor_after)
 
     uvm_analysis_port#(my_transaction) mon_ap_after;
 
     virtual dut_if vif;
 
     function new(string name, uvm_component parent);
          super.new(name, parent);
     endfunction: new
 
     function void build_phase(uvm_phase phase);
          super.build_phase(phase);
 
          void'(uvm_resource_db#(virtual dut_if)::read_by_name (.scope("ifs"), .name("dut_if"), .val(vif)));
          mon_ap_after = new(.name("mon_ap_before"), .parent(this));
     endfunction: build_phase
 
     task run_phase(uvm_phase phase);
          
     endtask: run_phase
endclass: jtag_monitor_after
*/


// OFFLINE CHANGES MADE:
// Lots! Verify if they work!