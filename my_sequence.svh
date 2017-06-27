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
		
		// `ifdef EXTEST_INSTR
		// `endif EXTEST_INSTR
		
		// `ifdef INTEST_INSTR
		// `endif INTEST_INSTR
		
		// `ifdef SAMPLE_INSTR
		// `endif SAMPLE_INSTR
		
		if(init == 3)
		begin
			`uvm_warning("", "TEST COMPLETED!!")
		end
		 
	endtask
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
		//mon_ap_before = new("mon_ap_before", this);
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

		forever begin
			@(posedge dut_vif.tdi_pad_i)
			begin
				sa_tx.tdi = dut_vif.tdi_pad_i;
				mon_ap_before.write(sa_tx);
		
				//Can be removed :)
				`uvm_warning("", "Monitor write before complete!")
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
		//@(posedge dut_vif.tck_pad_i); //Write to scoreboard 
		@(posedge dut_vif.tdo_pad_o)
		begin
			sa_tx_after.tdo = dut_vif.tdo_pad_o;
			mon_ap_after.write(sa_tx_after);

			//Can be removed :)
			`uvm_warning("", "Monitor write after complete!")
		end
	end
	endtask: run_phase
endclass: jtag_monitor_after

/*
	 //////////////////////////////////
	 class simpleadder_monitor_after extends uvm_monitor;
	`uvm_component_utils(simpleadder_monitor_after)

	uvm_analysis_port#(simpleadder_transaction) mon_ap_after;

	virtual simpleadder_if vif;

	simpleadder_transaction sa_tx;
	
	//For coverage
	simpleadder_transaction sa_tx_cg;

	//Define coverpoints
	covergroup simpleadder_cg;
      		ina_cp:     coverpoint sa_tx_cg.ina;
      		inb_cp:     coverpoint sa_tx_cg.inb;
		cross ina_cp, inb_cp;
	endgroup: simpleadder_cg

	function new(string name, uvm_component parent);
		super.new(name, parent);
		simpleadder_cg = new;
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		void'(uvm_resource_db#(virtual simpleadder_if)::read_by_name
			(.scope("ifs"), .name("simpleadder_if"), .val(vif)));
		mon_ap_after= new(.name("mon_ap_after"), .parent(this));
	endfunction: build_phase

	task run_phase(uvm_phase phase);
		integer counter_mon = 0, state = 0;
		sa_tx = simpleadder_transaction::type_id::create
			(.name("sa_tx"), .contxt(get_full_name()));

		forever begin
			@(posedge vif.sig_clock)
			begin
				if(vif.sig_en_i==1'b1)
				begin
					state = 1;
					sa_tx.ina = 2'b00;
					sa_tx.inb = 2'b00;
					sa_tx.out = 3'b000;
				end

				if(state==1)
				begin
					sa_tx.ina = sa_tx.ina << 1;
					sa_tx.inb = sa_tx.inb << 1;

					sa_tx.ina[0] = vif.sig_ina;
					sa_tx.inb[0] = vif.sig_inb;

					counter_mon = counter_mon + 1;

					if(counter_mon==2)
					begin
						state = 0;
						counter_mon = 0;

						//Predict the result
						predictor();
						sa_tx_cg = sa_tx;

						//Coverage
						simpleadder_cg.sample();

						//Send the transaction to the analysis port
						mon_ap_after.write(sa_tx);
					end
				end
			end
		end
	endtask: run_phase

	virtual function void predictor();
		sa_tx.out = sa_tx.ina + sa_tx.inb;
	endfunction: predictor
endclass: simpleadder_monitor_after
	 
	 /////////////////////////////////
	

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
			before_fifo.get(transaction_before);
			after_fifo.get(transaction_after);
			//compare();
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

endclass: jtag_scoreboard
*/



// OFFLINE CHANGES MADE:
// Monitor and the scoreboard have been added