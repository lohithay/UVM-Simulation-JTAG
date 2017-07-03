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
//// Revisions:													   ////
//// 															   ////
//// 27 May 2017 - Build - driver, sequencer and DUT. Checked if   ////
//// 			   the input pins are toggling					   ////
//// 															   ////
//// 06 Jun 2017 - The state machine can be changed and controlled ////
//// 			   using the test sequences. Reached RUN TEST IDLE ////
//// 			   State.										   ////
//// 															   ////
//// 13 Jun 2017 - The BYPASS and the IDCODE instructions are      ////
//// 			   implemented									   ////
/////////////////////////////////////////////////////////////////////// 


// DEFINE TO TEST WHICH INSTRUCTION TO EXECUTE
`define BYPASS_INSTR
//`define IDCODE_INSTR
//`define SAMPLE_INSTR
//`define EXTEST_INSTR
//`define INTEST_INSTR

//Enter the length of the expected datastream
`define DATA_LENGTH 30

// Imports
import uvm_pkg::*;
`include "uvm_macros.svh"

bit startValiadation = 0;


// ================================================================== //
//                                                                    //
// TRANSACTION                                                        //
//                                                                    //
// ================================================================== //
class my_transaction extends uvm_sequence_item;

	`uvm_object_utils(my_transaction)

	rand bit tms;
	rand bit tdi;
	rand bit trstn;
	rand bit tdo;
	
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
		repeat(80)
		begin
			req = my_transaction::type_id::create("req");

			start_item(req);
			if(!req.randomize())
			begin
				`uvm_warning("", "Randomization failed!")
			end
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
					if(dut_vif.test_logic_reset_o) //The DUT enters the Test Logic Reset STATE
					begin
						dut_vif.tdi_pad_i = 1; //Initializing the input port to 1'b1
						dut_vif.tms_pad_i = 0;
						//`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
						count++;
					end
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
				
				1: begin //Run Test Idle STATE
					if(dut_vif.run_test_idle_o)// The DUT enters the Run Test Idle STATE
					begin	
						dut_vif.tms_pad_i = 1;	
						count++;
						//complete = 1; //process completed				
					end		
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
				
				2: begin //Select DR Scan STATE
					dut_vif.tms_pad_i = 1;			
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
					
				3: begin //Select IR Scan STATE		
					dut_vif.tms_pad_i = 0;		
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
					
				4: begin //capture ir state
					dut_vif.tms_pad_i = 0;		
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
						//count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);
					end
					
					//Moving to the next state
					count++;
					seq_item_port.get_next_item(req);
					dut_vif.tms_pad_i = 1;		
					//count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
					
				end
					 
				6: begin //EXIT1 IR STATE 
						dut_vif.tms_pad_i = 1;		
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 7: begin //UPDATE IR STATE 
						dut_vif.tms_pad_i = 1;			
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 8: begin //SELECT DR STATE 
						dut_vif.tms_pad_i = 0;			
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end

				 9: begin //CAPTURE DR STATE 
						dut_vif.tms_pad_i = 0;		
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 10: begin //SHIFT DR STATE 
				 		startValiadation = 1;
						for(int i=0; i<=30; i++)//TDI to TDO via BYPASS Register x10
						begin
							if(i!=0)  seq_item_port.get_next_item(req);
							dut_vif.tms_pad_i = 0;	
							dut_vif.tdi_pad_i = req.tdi;
							`uvm_info("DUT", $sformatf("Received TDI=%b, TDO=%b", dut_vif.tdi_pad_i, dut_vif.tdo_pad_o), UVM_MEDIUM)							
							seq_item_port.item_done();
							@(posedge dut_vif.tck_pad_i);			
						end 
						count++;
						init++;
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
						//`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
						count++;
					end
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
				
				1: begin //Run Test Idle STATE
					if(dut_vif.run_test_idle_o)// The DUT enters the Run Test Idle STATE
					begin	
						dut_vif.tms_pad_i = 1;	
						count++;
						//complete = 1; //process completed				
					end		
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
				
				2: begin //Select DR Scan STATE
					dut_vif.tms_pad_i = 1;			
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
					
				3: begin //Select IR Scan STATE		
					dut_vif.tms_pad_i = 0;
					dut_vif.tdi_pad_i = 0; //For the first bit that will be shifted into the Instruction Register
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
				end
					
				 4: begin //capture ir state
					 dut_vif.tms_pad_i = 0;		
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
						//count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);
					end
					
					//Moving to the next state
					count++;
					seq_item_port.get_next_item(req);
					dut_vif.tms_pad_i = 1;		
					//count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.tck_pad_i);
					
				end
					 
				6: begin //EXIT1 IR STATE 
						dut_vif.tms_pad_i = 1;		
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 7: begin //UPDATE IR STATE 
						dut_vif.tms_pad_i = 1;		
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end
				 
				 8: begin //SELECT DR STATE 
						dut_vif.tms_pad_i = 0;			
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.tck_pad_i);			
				 end

				 9: begin //CAPTURE DR STATE 
						dut_vif.tms_pad_i = 0;			
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
		
		// `ifdef EXTEST_INSTR
		// `endif EXTEST_INSTR
		
		// `ifdef INTEST_INSTR
		// `endif INTEST_INSTR
		
		// `ifdef SAMPLE_INSTR
		// `endif SAMPLE_INSTR
		
		if(init == 2)
		begin
			`uvm_warning("", "TEST COMPLETED!!")
			report_phase(phase);
		end
	endtask

	function void report_phase(uvm_phase phase);
		uvm_report_server svr;
		super.report_phase(phase);

		svr = uvm_report_server::get_server();
		if(svr.get_severity_count(UVM_FATAL)+svr.get_severity_count(UVM_ERROR)>0) begin
			`uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
			`uvm_info(get_type_name(), "----       ERRORS EXIST            ----", UVM_NONE)
			`uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
		end
		else begin
			`uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
			`uvm_info(get_type_name(), "----      NO ERRORS EXIST          ----", UVM_NONE)
			`uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
		end
	endfunction
endclass: my_driver

// ================================================================== //
//                                                                    //
// MONITOR_BEFORE                                                     //
//                                                                    //
// ================================================================== //
class jtag_monitor_before extends uvm_monitor;
	`uvm_component_utils(jtag_monitor_before)
 
	uvm_analysis_port#(my_transaction) mon_ap_before;
 
	virtual dut_if dut_vif;
	
	reg [1:0] clock_value ;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new
 
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		mon_ap_before = new("mon_ap_before", this);		  
		if (! uvm_config_db #(virtual dut_if) :: get (this, "", "dut_vif", dut_vif)) begin
        	`uvm_error (get_type_name (), "DUT interface not found")
      	end         
	endfunction: build_phase

	task run_phase(uvm_phase phase);
		my_transaction sa_tx;
		sa_tx = my_transaction::type_id::create(.name("sa_tx"), .contxt(get_full_name()));

		//Writing the data at every toggling of the TDI pin
		forever begin
			if(startValiadation)
			begin
				@(posedge dut_vif.tdi_pad_i)
				begin
					sa_tx.tdi = dut_vif.tdi_pad_i;
					mon_ap_before.write(sa_tx);
				end
				@(negedge dut_vif.tdi_pad_i)
				begin
					sa_tx.tdi = dut_vif.tdi_pad_i;
					mon_ap_before.write(sa_tx);
				end
			end
		end
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
 
	virtual dut_if dut_vif;

	reg [1:0] clock_value ;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		mon_ap_after = new(.name("mon_ap_before"), .parent(this));
		if (! uvm_config_db #(virtual dut_if) :: get (this, "", "dut_vif", dut_vif)) 
		begin
         `uvm_error (get_type_name (), "DUT interface not found")		
        end
	endfunction: build_phase

	task run_phase(uvm_phase phase);
		my_transaction sa_tx_after;
		sa_tx_after = my_transaction::type_id::create(.name("sa_tx_after"), .contxt(get_full_name()));

		forever begin
			if(startValiadation)
			begin
				//Writing the data at every toggling of the TDO pin
				@(posedge dut_vif.tdo_pad_o)
				begin
					sa_tx_after.tdo = dut_vif.tdo_pad_o;
					mon_ap_after.write(sa_tx_after);
				end
				@(negedge dut_vif.tdo_pad_o)
				begin
					sa_tx_after.tdo = dut_vif.tdo_pad_o;
					mon_ap_after.write(sa_tx_after);
				end
			end
		end
	endtask: run_phase
endclass: jtag_monitor_after



// ================================================================== //
//                                                                    //
// SCOREBOARD                                                         //
//                                                                    //
// ================================================================== //
class jtag_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(jtag_scoreboard)
	
	uvm_analysis_export #(my_transaction) sb_export_before;
	uvm_analysis_export #(my_transaction) sb_export_after;
	
	uvm_tlm_analysis_fifo #(my_transaction) before_fifo;
	uvm_tlm_analysis_fifo #(my_transaction) after_fifo;
	
	my_transaction transaction_before;
	my_transaction transaction_after;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
		transaction_before = new("transaction_before");
		transaction_after = new("transaction_after");
	endfunction: new
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		sb_export_before = new("sb_export_before", this);
		sb_export_after  = new("sb_export_after",  this);
		
		before_fifo = new("before_fifo", this);
		after_fifo  = new("after_fifo",  this);
	endfunction: build_phase
	
	function void connect_phase(uvm_phase phase);
		sb_export_before.connect(before_fifo.analysis_export);
		sb_export_after.connect(after_fifo.analysis_export);
	endfunction: connect_phase
	
	task run();
		forever begin
			if(startValiadation)
			begin
				before_fifo.get(transaction_before);
				after_fifo.get(transaction_after);
				//`uvm_info(get_type_name(),$sformatf("Expected Data: %0h Actual Data: %0h",sc_mem[mem_pkt.addr],mem_pkt.rdata),UVM_LOW)
				`uvm_warning("", "Got into FIFO!")
				//compare();
			end
		end
	endtask: run
	/*
	virtual function void compare();
		if(transaction_before.out == transaction_after.out)
		begin
			`uvm_info("compare", {"Test: OK"}, UVM_LOW);
		end
		else
		begin
			`uvm_info("compare", {"Test: Fail"}, UVM_LOW);
		end
	endfunction: compare
*/
endclass: jtag_scoreboard




// OFFLINE CHANGES MADE:
// Monitor and the scoreboard have been added
