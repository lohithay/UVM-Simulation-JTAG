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
//`define IDCODE_INSTR
//`define SAMPLE_INSTR
//`define EXTEST_INSTR
`define INTEST_INSTR

//GLOBAL VARIABLE Declaration

integer DATA_LENGTH = 30;  //Enter the length of the expected datastream for BYPASS Instruction
bit introduceErrorBypass = 0; 
bit introduceErrorIdcode = 0;


bit startValiadation = 0;  //Indicates when the data has to be checked
bit validationBufferTDI [100];
bit validationBufferTDO [100];


// Imports
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "tap_defines.v"



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
	rand bit A;
	rand bit B;
	rand bit Cin;

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

	integer numberOfRequests = 0;

	task body;
		numberOfRequests = 80 + DATA_LENGTH;
		repeat(numberOfRequests)
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
			dut_vif.TRST = 0;
			@(posedge dut_vif.TCK);
			#1;
			dut_vif.TRST = 1;		
			init = 1;
		end
				
		`ifdef BYPASS_INSTR
		//forever
		while(count<=11 && init ==1)
		begin
			seq_item_port.get_next_item(req);
			case(count)
				
				0: begin //Test Logic Reset STATE
						dut_vif.TDI = 1; //Initializing the input port to 1'b1
						dut_vif.TMS = 0;
						//`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
						count++;
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
				
				1: begin //Run Test Idle STATE
						dut_vif.TMS = 1;	
						count++;
						//complete = 1; //process completed				
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
				
				2: begin //Select DR Scan STATE
					dut_vif.TMS = 1;			
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
					
				3: begin //Select IR Scan STATE		
					dut_vif.TMS = 0;		
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
					
				4: begin //capture ir state
					dut_vif.TMS = 0;		
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
				 
				5: begin //SHIFT IR STATE 
					for(int i=0; i<=2; i++)//SHIFTING THE IR WITH 4 1's
					begin
						if(i!=0)  seq_item_port.get_next_item(req);
						
						dut_vif.TMS = 0;		
						dut_vif.TDI = 1;		
						//count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					//Moving to the next state
					count++;
					seq_item_port.get_next_item(req);
					dut_vif.TMS = 1;		
					//count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
					
				end
					 
				6: begin //EXIT1 IR STATE 
						dut_vif.TMS = 1;		
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);			
				 end
				 
				 7: begin //UPDATE IR STATE 
						dut_vif.TMS = 1;			
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);			
				 end
				 
				 8: begin //SELECT DR STATE 
						dut_vif.TMS = 0;			
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);			
				 end

				 9: begin //CAPTURE DR STATE 
						dut_vif.TMS = 0;		
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);			
				 end
				 
				 10: begin //SHIFT DR STATE 
				 		startValiadation = 1;
						for(int i=0; i<=DATA_LENGTH; i++)//TDI to TDO via BYPASS Register x10
						begin
							if(i!=0)  seq_item_port.get_next_item(req);
							dut_vif.TMS = 0;	
							dut_vif.TDI = req.tdi;
							`uvm_info("DUT", $sformatf("Received TDI=%b, TDO=%b", dut_vif.TDI, dut_vif.TDO), UVM_MEDIUM)							
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
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
						dut_vif.TMS = 0;
						//`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
						count++;
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
				
				1: begin //Run Test Idle STATE
						dut_vif.TMS = 1;	
						count++;
						//complete = 1; //process completed		
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
				
				2: begin //Select DR Scan STATE
					dut_vif.TMS = 1;			
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
					
				3: begin //Select IR Scan STATE		
					dut_vif.TMS = 0;
					dut_vif.TDI = 0; //For the first bit that will be shifted into the Instruction Register
					count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
					
				 4: begin //capture ir state
					 dut_vif.TMS = 0;		
					 count++;					
					 seq_item_port.item_done();
					 @(posedge dut_vif.TCK);
				 end
				 
				5: begin //SHIFT IR STATE 
					for(int i=0; i<=2; i++)//SHIFTING THE IR WITH 4 1's
					begin
						if(i!=0)  seq_item_port.get_next_item(req);
						dut_vif.TMS = 0;		
						if(i==0) dut_vif.TDI = 0;		
						else if(i==1) dut_vif.TDI = 1;
						else if(i==2) dut_vif.TDI = 0;
						//count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					//Moving to the next state
					count++;
					seq_item_port.get_next_item(req);
					dut_vif.TMS = 1;		
					//count++;					
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
					
				end
					 
				6: begin //EXIT1 IR STATE 
						dut_vif.TMS = 1;		
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);			
				 end
				 
				 7: begin //UPDATE IR STATE 
						dut_vif.TMS = 1;		
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);			
				 end
				 
				 8: begin //SELECT DR STATE 
						dut_vif.TMS = 0;			
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);			
				 end

				 9: begin //CAPTURE DR STATE 
						dut_vif.TMS = 0;			
						count++;
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);			
				 end
				 
				 10: begin //SHIFT DR STATE 
				 	startValiadation = 1;
						for(int i=0; i<=32; i++)//Shfting out the 32 bit IDCODE
						begin
							if(i!=0)  seq_item_port.get_next_item(req);
							dut_vif.TMS = 0;	
							dut_vif.TDI = 0;
							if(introduceErrorIdcode && i>10 && i<15)
								dut_vif.TDO = 1;
							//`uvm_info("DUT", $sformatf("TDO=%b", dut_vif.TDO), UVM_MEDIUM	)						
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
						end 
						count++;
				 end
				 
				 11: begin
						init++;
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
						break;
				 end

				default: break;				
			endcase
		end //while loop
		`endif //IDCODE INSTR
		
		// `ifdef EXTEST_INSTR
		// `endif //EXTEST_INSTR
		
		 `ifdef INTEST_INSTR
			while(count<=11 && init ==1)
			begin
				seq_item_port.get_next_item(req);
				case(count)
					
					0: begin //Test Logic Reset STATE
							dut_vif.TMS = 0;
							//`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
							count++;
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					1: begin //Run Test Idle STATE
							dut_vif.TMS = 1;	
							count++;
							//complete = 1; //process completed		
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					2: begin //Select DR Scan STATE
						dut_vif.TMS = 1;			
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					3: begin //Select IR Scan STATE		
						dut_vif.TMS = 0;
						dut_vif.TDI = 0; //For the first bit that will be shifted into the Instruction Register
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					 4: begin //capture ir state
						 dut_vif.TMS = 0;		
						 count++;					
						 seq_item_port.item_done();
						 @(posedge dut_vif.TCK);
					 end
					 
					5: begin //SHIFT IR STATE 
						for(int i=0; i<=2; i++)//SHIFTING THE IR WITH Instruction for Intest
						begin
							if(i!=0)  seq_item_port.get_next_item(req);
							dut_vif.TMS = 0;		
							if(i==0) dut_vif.TDI = 1;		
							else if(i==1) dut_vif.TDI = 0;
							else if(i==2) dut_vif.TDI = 0;
							//else if(i==3) dut_vif.TDI = 1;
							//count++;					
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);
						end
						
						//Moving to the next state
						count++;
						seq_item_port.get_next_item(req);
						dut_vif.TMS = 1;
						dut_vif.TDI = 1;
						//count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
						
					end
						 
					6: begin //EXIT1 IR STATE 
							dut_vif.TMS = 1;
							dut_vif.TDI = 0;		
							count++;					
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 7: begin //UPDATE IR STATE 
							dut_vif.TMS = 1;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 8: begin //SELECT DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 9: begin //CAPTURE DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 10: begin //SHIFT DR STATE 
					 		startValiadation = 1;
							for(int i=0; i<=32; i++)//Shfting out the bits via BOundary Scan
							begin
								if(i!=0)  seq_item_port.get_next_item(req);
								dut_vif.TMS = 0;	
								dut_vif.TDI = req.tdi;
								//if(introduceErrorIdcode && i>10 && i<15)
								//	dut_vif.TDO = 1;
								//`uvm_info("DUT", $sformatf("TDO=%b", dut_vif.TDO), UVM_MEDIUM	)						
								seq_item_port.item_done();
								@(posedge dut_vif.TCK);			
							end 
							count++;
					 end
					 
					 11: begin
							init++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);
							break;
					 end

					default: break;				
				endcase
			end //while loop
		 `endif //INTEST_INSTR
		
		 `ifdef SAMPLE_INSTR
		 	dut_vif.A = 1'b1;
		 	dut_vif.B = 1'b1;
		 	dut_vif.Cin = 1'b0;

			while(count<=11 && init ==1)
			begin
				seq_item_port.get_next_item(req);
				case(count)
					
					0: begin //Test Logic Reset STATE
							dut_vif.TMS = 0;
							//`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
							count++;
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					1: begin //Run Test Idle STATE
							dut_vif.TMS = 1;	
							count++;
							//complete = 1; //process completed		
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					2: begin //Select DR Scan STATE
						dut_vif.TMS = 1;			
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					3: begin //Select IR Scan STATE		
						dut_vif.TMS = 0;
						dut_vif.TDI = 0; //For the first bit that will be shifted into the Instruction Register
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					 4: begin //capture ir state
						 dut_vif.TMS = 0;		
						 count++;					
						 seq_item_port.item_done();
						 @(posedge dut_vif.TCK);
					 end
					 
					5: begin //SHIFT IR STATE 
						for(int i=0; i<=2; i++)//SHIFTING THE IR WITH Instruction for Sample/Preload
						begin
							if(i!=0)  seq_item_port.get_next_item(req);
							dut_vif.TMS = 0;		
							if(i==0) dut_vif.TDI = 1;		
							else if(i==1) dut_vif.TDI = 0;
							else if(i==2) dut_vif.TDI = 0;

							//count++;					
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);
						end
						
						//Moving to the next state
						count++;
						seq_item_port.get_next_item(req);
						dut_vif.TMS = 1;		
						//count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
						
					end
						 
					6: begin //EXIT1 IR STATE 
							dut_vif.TMS = 1;		
							count++;					
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 7: begin //UPDATE IR STATE 
							dut_vif.TMS = 1;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 8: begin //SELECT DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 9: begin //CAPTURE DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 10: begin //SHIFT DR STATE 
					 		startValiadation = 1;
							for(int i=0; i<=32; i++)//Shfting out the bits via BOundary Scan
							begin
								if(i!=0)  seq_item_port.get_next_item(req);
								dut_vif.TMS = 0;	
								dut_vif.TDI = req.tdi;
								//if(introduceErrorIdcode && i>10 && i<15)
								//	dut_vif.TDO = 1;
								//`uvm_info("DUT", $sformatf("TDO=%b", dut_vif.TDO), UVM_MEDIUM	)						
								seq_item_port.item_done();
								@(posedge dut_vif.TCK);			
							end 
							count++;
					 end
					 
					 11: begin
							init++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);
							break;
					 end

					default: break;				
				endcase
			end //while loop	
		 `endif //SAMPLE_INSTR
		
		if(init == 2)
		begin
			`uvm_warning("", "TEST COMPLETED!!")
			`ifdef BYPASS_INSTR compareForBypass(); `endif
			`ifdef IDCODE_INSTR compareForIdcode(); `endif
			report_phase(phase);
		end
	endtask

	virtual function void compareForBypass();
		for(integer m=0; m<DATA_LENGTH; m++)
		begin
			if(validationBufferTDI[m]==validationBufferTDO[m+2])
			begin
				`uvm_warning("compareForBypass", "SAME" )
				$display("TDI= %b TDO=%b ",validationBufferTDI[m], validationBufferTDO[m+2] );

			end
			else
			begin
				`uvm_error("compareForBypass", "DIFFERENT")
				$display("TDI= %b TDO=%b ",validationBufferTDI[m], validationBufferTDO[m+2] );
			end
		end
	endfunction: compareForBypass

	virtual function void compareForIdcode();
		bit [31:0] EXPECTED = `IDCODE_VALUE;
		bit [31:0] RECEIVED;

		for(integer m=0; m<32; m++)
		begin
			RECEIVED[m] = validationBufferTDO[m+1];
			//$display("%d RECEIVED= %b EXPECTED=%b ",m+1, validationBufferTDO[m+1], EXPECTED[m] );
		end
		
		if(RECEIVED == EXPECTED)
		begin
			`uvm_warning("compareForIdcode", "IDCODE MATCHED!" )
			$display(" RECEIVED IDCODE= %h EXPECTED IDCODE=%h ", RECEIVED, EXPECTED );
		end
		else
		begin `uvm_error("compareForIdcode", "IDCODE DO NOT MATCH")
			$display(" RECEIVED IDCODE= %h EXPECTED IDCODE=%h ", RECEIVED, EXPECTED );
		end
	endfunction: compareForIdcode

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
	integer tdiScan =0;

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
			//if(startValiadation)
			//begin
				@(posedge dut_vif.TCK)
				begin
					if(startValiadation)
					begin
						sa_tx.tdi = dut_vif.TDI;
						mon_ap_before.write(sa_tx);
						validationBufferTDI[tdiScan]=dut_vif.TDI;
						tdiScan++;
					end
				end
			//end
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
	integer tdoScan =0;

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
			`ifdef BYPASS_INSTR
				@(negedge dut_vif.TCK)
				begin
					if(startValiadation)
					begin
						sa_tx_after.tdo = dut_vif.TDO;
						mon_ap_after.write(sa_tx_after);
						validationBufferTDO[tdoScan]=dut_vif.TDO;
						tdoScan++;
					end
				end
			`endif

			`ifdef IDCODE_INSTR
			@(negedge dut_vif.TCK)
			begin
				if(startValiadation)
				begin
					sa_tx_after.tdo = dut_vif.TDO;
					mon_ap_after.write(sa_tx_after);
					validationBufferTDO[tdoScan]=dut_vif.TDO;
					tdoScan++;
				end
			end
			`endif
			`ifdef SAMPLE_INSTR
			@(negedge dut_vif.TCK)
			begin
				if(startValiadation)
				begin
					sa_tx_after.tdo = dut_vif.TDO;
					mon_ap_after.write(sa_tx_after);
					//validationBufferTDO[tdoScan]=dut_vif.TDO;
					//tdoScan++;
				end
			end
			`endif

			`ifdef INTEST_INSTR
			@(negedge dut_vif.TCK)
			begin
				if(startValiadation)
				begin
					sa_tx_after.tdo = dut_vif.TDO;
					mon_ap_after.write(sa_tx_after);
					//validationBufferTDO[tdoScan]=dut_vif.TDO;
					//tdoScan++;
				end
			end
			`endif

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
			before_fifo.get(transaction_before);
			after_fifo.get(transaction_after);
			`uvm_warning("", "Got into FIFO!")
		end
	endtask: run
endclass: jtag_scoreboard




// OFFLINE CHANGES MADE:
// Monitor and the scoreboard have been added
