///////////////////////////////////////////////////////////////////////
////                                                               ////
////  my_sequence.svh                                              ////
////                                                               ////
////  Project : UVM Simulationsmodell eines JTAG-Interfaces        ////
////                                                               ////
////  Author(s):                                                   ////
////    Serin Varghese                                             ////
////    Micro and Nano Systems,                                    ////
////    TU Chemnitz                                                ////
////                                                               ////
////  Date: July 2017                                              ////
////                                                               ////
////  Notes:                                                       ////
////  These files contain the following UVM blocks(modules)        ////
////  - Transaction                                                ////
////  - Sequencer                                                  ////
////  - Driver                                                     ////
////  - Monitors                                                   ////
////  - Scoreboard                                                 ////
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
//// 															   ////
//// 27 Jun 2017 - Both the monitors are added                     ////
//// 			   								            	   ////
//// 03 Jul 2017 - Scoreboard connected          				   ////
//// 															   ////
//// 11 Jul 2017 - Sample/Preload Instruction is implemented	   ////
//// 															   ////
//// 13 Jul 2017 - Intest Instruction is implemented			   ////
//// 															   ////
//// 11 Aug 2017 - Extest Instruction is added                     ////
////                                                               ////
/////////////////////////////////////////////////////////////////////// 

// Imports
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "tap_defines.v"
`include "config.svh"


bit startValiadation_bypass = 0;  //Indicates when the data has to be checked
bit startValiadation_intest = 0;  //Indicates when the data has to be checked
bit startValiadation_extest = 0;  //Indicates when the data has to be checked
bit startValiadation_samplepreload = 0;  //Indicates when the data has to be checked
bit startValiadation_idcode = 0;  //Indicates when the data has to be checked

bit validationBufferTDI_bypass [100]; //Storage register for the valid TDI signals
bit validationBufferTDI_intest [100]; //Storage register for the valid TDI signals
bit validationBufferTDI_extest [100]; //Storage register for the valid TDI signals
bit validationBufferTDI_samplepreload [100]; //Storage register for the valid TDI signals
bit validationBufferTDI_idcode [100]; //Storage register for the valid TDI signals

bit validationBufferTDO_bypass [100]; //Storage register for the valid TDO signals
bit validationBufferTDO_intest [100]; //Storage register for the valid TDO signals
bit validationBufferTDO_extest [100]; //Storage register for the valid TDO signals
bit validationBufferTDO_samplepreload [100]; //Storage register for the valid TDO signals
bit validationBufferTDO_idcode [100]; //Storage register for the valid TDO signals

integer bypassErrorCount=0;

typedef enum {FALSE, TRUE} boolean;

//For Sample/Preload and INTEST instruction
// Fill the setPreloadValue according to the bits that are 
// pushed into the TDI serially
// The values of the bit are written below.
reg [`numberOfBoundaryScanCells-1:0] PreloadValue =   `setPreloadValue;
//bit setPreloadValue[5] = { Cout, Sum, A, B, Cin };


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
		numberOfRequests = 150 + `DATA_LENGTH;
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


		boolean bypass_true;
		boolean idcode_true;
		boolean samplepreload_true;
		boolean intest_true;
		boolean extest_true;

		boolean isFirstReset = TRUE;

		`ifdef BYPASS_INSTR bypass_true = TRUE; `endif
		`ifndef BYPASS_INSTR bypass_true = FALSE; `endif

		`ifdef IDCODE_INSTR idcode_true = TRUE; `endif
		`ifndef IDCODE_INSTR idcode_true = FALSE; `endif

		`ifdef SAMPLE_PRELOAD_INSTR samplepreload_true = TRUE; `endif
		`ifndef SAMPLE_PRELOAD_INSTR samplepreload_true = FALSE; `endif

		`ifdef INTEST_INSTR intest_true = TRUE; `endif
		`ifndef INTEST_INSTR intest_true = FALSE; `endif

		`ifdef EXTEST_INSTR extest_true = TRUE; `endif
		`ifndef EXTEST_INSTR extest_true = FALSE; `endif

			
		init = 1;

		if(idcode_true == TRUE)
		begin

			if(isFirstReset == TRUE)
			begin
				// First toggle reset
				dut_vif.TRST = 0;
				@(posedge dut_vif.TCK);
				#1;
				dut_vif.TRST = 1;

				//Initializing the TAP controller to go to RUN_TEST_IDLE
				seq_item_port.get_next_item(req);
				begin //Test Logic Reset STATE
					dut_vif.TDI = 1; //Initializing the input port to 1'b1
					dut_vif.TMS = 0;
					//`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
				isFirstReset = FALSE;
			end

			count = 0;

			while(count<=12 && init ==1)
			begin
				seq_item_port.get_next_item(req);
				case(count)
										
					0: begin //Run Test Idle STATE
							dut_vif.TMS = 1;	
							count++;
							//complete = 1; //process completed		
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					1: begin //Select DR Scan STATE
						dut_vif.TMS = 1;			
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					2: begin //Select IR Scan STATE		
						dut_vif.TMS = 0;
						dut_vif.TDI = 0; //For the first bit that will be shifted into the Instruction Register
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					 3: begin //capture ir state
						 dut_vif.TMS = 0;		
						 count++;					
						 seq_item_port.item_done();
						 //`uvm_info("DUT", $sformatf("CAPTURE IR"), UVM_MEDIUM	)
						 @(posedge dut_vif.TCK);
					 end
					 
					4: begin //SHIFT IR STATE 
						for(int i=0; i<=2; i++)//SHIFTING THE IR WITH 4'b0010 - IDCODE instruction
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
						 
					5: begin //EXIT1 IR STATE 
							dut_vif.TMS = 1;		
							count++;					
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 6: begin //UPDATE IR STATE 
							dut_vif.TMS = 1;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 7: begin //SELECT DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 8: begin //CAPTURE DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 9: begin //SHIFT DR STATE 
					 	startValiadation_idcode = 1; //Only now the monitor and the scoreboard starts collecting the bits
							for(int i=0; i<=32; i++)//Shfting out the 32 bit IDCODE
							begin
								if(i!=0)  seq_item_port.get_next_item(req);
								dut_vif.TMS = 0;	
								dut_vif.TDI = 0;
								if(`introduceErrorIdcode == 1 && i>10 && i<15)
									dut_vif.TDO = 1;
								//`uvm_info("DUT", $sformatf("TDO=%b", dut_vif.TDO), UVM_MEDIUM	)						
								seq_item_port.item_done();
								@(posedge dut_vif.TCK);			
							end 
							count++;
					 end
					 
					 10: begin //EXIT1 DR STATE 
					 		dut_vif.TDI = 0;
							dut_vif.TMS = 1;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 11: begin //UPDATE DR STATE 
							dut_vif.TMS = 0;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 12: begin //RUN_TEST_IDLE STATE 
							dut_vif.TMS = 0;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);	
							
							dut_vif.TRST = 0;
							@(posedge dut_vif.TCK);
							#1;
							dut_vif.TRST = 1;

							startValiadation_idcode = 0;

					 end

					default: break;				
				endcase
			end //while loop
		end //IDCODE INSTR

		if(bypass_true == TRUE)
		begin	//forever

			if(isFirstReset == TRUE)
			begin
				// First toggle reset
				dut_vif.TRST = 0;
				@(posedge dut_vif.TCK);
				#1;
				dut_vif.TRST = 1;				
				isFirstReset = FALSE;
			end
				//Initializing the TAP controller to go to RUN_TEST_IDLE
				seq_item_port.get_next_item(req);
				begin //Test Logic Reset STATE
					dut_vif.TDI = 1; //Initializing the input port to 1'b1
					dut_vif.TMS = 0;
					//`uvm_info("DUT", $sformatf("Test Logic Reset STATE"), UVM_MEDIUM)
					seq_item_port.item_done();
					@(posedge dut_vif.TCK);
				end
			
			count = 0;

			while(count<=12 && init ==1)
			begin
				seq_item_port.get_next_item(req);
				case(count)
							
					0: begin //Run Test Idle STATE
						dut_vif.TMS = 1;	
						count++;
						//complete = 1; //process completed				
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					1: begin //Select DR Scan STATE
						dut_vif.TMS = 1;			
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					2: begin //Select IR Scan STATE		
						dut_vif.TMS = 0;		
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					3: begin //CAPTURE IR state
						dut_vif.TMS = 0;		
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					 
					4: begin //SHIFT IR STATE 
						for(int i=0; i<=2; i++)//SHIFTING THE IR WITH 4 1's for BYPASS instruction
						begin
							if(i!=0)  seq_item_port.get_next_item(req);
							dut_vif.TMS = 0;		
							dut_vif.TDI = 1;		
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
						 
					5: begin //EXIT1 IR STATE 
							dut_vif.TDI = 0;
							dut_vif.TMS = 1;		
							count++;					
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 6: begin //UPDATE IR STATE 
							dut_vif.TMS = 1;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 7: begin //SELECT DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 8: begin //CAPTURE DR STATE 
							dut_vif.TMS = 0;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 9: begin //SHIFT DR STATE 
					 		startValiadation_bypass = 1;
							for(int i=0; i<=`DATA_LENGTH; i++)//TDI to TDO via BYPASS Register 
							begin
								if(i!=0)  seq_item_port.get_next_item(req);
								if(i>`DATA_LENGTH/2 && i<(`DATA_LENGTH/2)+5 && `introduceErrorBypass == 1)
									dut_vif.TDO = 1;
								dut_vif.TMS = 0;	
								dut_vif.TDI = req.tdi; //Random bits are sent to the TDI
								//`uvm_info("DUT", $sformatf("Received TDI=%b, TDO=%b", dut_vif.TDI, dut_vif.TDO), UVM_MEDIUM)							
								seq_item_port.item_done();
								@(posedge dut_vif.TCK);			
							end 
							count++;
					 end

					 10: begin //EXIT1 DR STATE 
					 		dut_vif.TDI = 0;
							dut_vif.TMS = 1;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 11: begin //UPDATE DR STATE 
							dut_vif.TMS = 0;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 12: begin //RUN_TEST_IDLE STATE 
							dut_vif.TMS = 0;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);	
							
							dut_vif.TRST = 0;
							@(posedge dut_vif.TCK);
							#1;
							dut_vif.TRST = 1;
							startValiadation_bypass = 0;
					 end

					default: break;
				endcase
			end //while loop
		end
		
		if(intest_true == TRUE)
		begin
			if(isFirstReset == TRUE)
			begin
				// First toggle reset
				dut_vif.TRST = 0;
				@(posedge dut_vif.TCK);
				#1;
				dut_vif.TRST = 1;
				isFirstReset = FALSE;
			end

			//Initializing the TAP controller to go to RUN_TEST_IDLE
			seq_item_port.get_next_item(req);
			begin //Test Logic Reset STATE
				dut_vif.TDI = 1; //Initializing the input port to 1'b1
				dut_vif.TMS = 0;
				seq_item_port.item_done();
				@(posedge dut_vif.TCK);
			end

			count = 0;
			if(`testForFulladder==1)
			begin
				dut_vif.A   =  PreloadValue[2];
				dut_vif.B   =  PreloadValue[3];
			 	dut_vif.Cin =  PreloadValue[4];
			end

			while(count<=12 && init ==1)
			begin
				seq_item_port.get_next_item(req);
				case(count)
					
					0: begin //Run Test Idle STATE
						dut_vif.TMS = 1;	
						count++;
						//complete = 1; //process completed		
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					1: begin //Select DR Scan STATE
						dut_vif.TMS = 1;			
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					2: begin //Select IR Scan STATE		
						dut_vif.TMS = 0;
						dut_vif.TDI = 0; //For the first bit that will be shifted into the Instruction Register
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					3: begin //capture ir state
						 dut_vif.TMS = 0;		
						 count++;					
						 seq_item_port.item_done();
						 @(posedge dut_vif.TCK);
					 end
					 
					4: begin //SHIFT IR STATE 
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
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
						
					end
					
					5: begin //EXIT1 IR STATE 
							dut_vif.TMS = 1;
							dut_vif.TDI = 0;		
							count++;					
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					
					 6: begin //UPDATE IR STATE 
							dut_vif.TMS = 1;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					
					 7: begin //SELECT DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 8: begin //CAPTURE DR STATE 
							dut_vif.TMS = 0;							
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 9: begin //SHIFT DR STATE 
					 		//startValiadation = 1;
							for(int i=0; i<`numberOfBoundaryScanCells-1; i++)//Shfting in the bits for Preloading
							begin
								if(i!=0)  seq_item_port.get_next_item(req);
								dut_vif.TMS = 0;		
								dut_vif.TDI = PreloadValue[i];
								//if(introduceErrorIdcode && i>10 && i<15)
								//	dut_vif.TDO = 1;
								//`uvm_info("DUT", $sformatf("TDO=%b", dut_vif.TDO), UVM_MEDIUM	)						
								seq_item_port.item_done();
								@(posedge dut_vif.TCK);			
							end 
							count++;
					 end

					 10: begin //EXIT1 DR STATE 
							dut_vif.TMS = 1;
							dut_vif.TDI = PreloadValue[`numberOfBoundaryScanCells-1];			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 11: begin //UPDATE DR STATE 
							dut_vif.TMS = 1;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 12: begin //RUN_TEST_IDLE STATE 
							dut_vif.TMS = 0;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);	
							
							dut_vif.TRST = 0;
							@(posedge dut_vif.TCK);
							#1;
							dut_vif.TRST = 1;
							startValiadation_bypass = 0;
					 end

					default: break;				
			
				endcase
			end //while loop
		end //INTEST_INSTR
		
		if(samplepreload_true == TRUE)
		begin
			if(isFirstReset == TRUE)
			begin
				// First toggle reset
				dut_vif.TRST = 0;
				@(posedge dut_vif.TCK);
				#1;
				dut_vif.TRST = 1;
				isFirstReset = FALSE;
			end

			//Initializing the TAP controller to go to RUN_TEST_IDLE
			seq_item_port.get_next_item(req);
			begin //Test Logic Reset STATE
				dut_vif.TDI = 1; //Initializing the input port to 1'b1
				dut_vif.TMS = 0;
				seq_item_port.item_done();
				@(posedge dut_vif.TCK);
			end

			count = 0;
			
			while(count<=12 && init ==1)
			begin
				seq_item_port.get_next_item(req);
				case(count)
										
					0: begin //Run Test Idle STATE
							dut_vif.TMS = 1;	
							count++;
							//complete = 1; //process completed		
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					1: begin //Select DR Scan STATE
						dut_vif.TMS = 1;			
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					2: begin //Select IR Scan STATE		
						dut_vif.TMS = 0;
						dut_vif.TDI = 0; //For the first bit that will be shifted into the Instruction Register
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					3: begin //capture ir state
						 dut_vif.TMS = 0;		
						 count++;					
						 seq_item_port.item_done();
						 @(posedge dut_vif.TCK);
					 end
					 
					4: begin //SHIFT IR STATE 
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
						 
					5: begin //EXIT1 IR STATE 
							dut_vif.TMS = 1;		
							count++;					
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					6: begin //UPDATE IR STATE 
							dut_vif.TMS = 1;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					7: begin //SELECT DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					8: begin //CAPTURE DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					9: begin //SHIFT DR STATE 
					 		//startValiadation = 1;
							for(int i=0; i<=`numberOfBoundaryScanCells-1; i++)//Shfting out the bits via BOundary Scan
							begin
								if(i!=0)  seq_item_port.get_next_item(req);
								dut_vif.TMS = 0;	
								dut_vif.TDI = PreloadValue[i];
								//if(introduceErrorIdcode && i>10 && i<15)
								//	dut_vif.TDO = 1;
								//`uvm_info("DUT", $sformatf("TDO=%b", dut_vif.TDO), UVM_MEDIUM	)						
								seq_item_port.item_done();
								@(posedge dut_vif.TCK);			
							end 
							count++;
					 end

					 10: begin //EXIT1 DR STATE 
					 		dut_vif.TDI = 0;
							dut_vif.TMS = 1;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 11: begin //UPDATE DR STATE 
							dut_vif.TMS = 0;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 12: begin //RUN_TEST_IDLE STATE 
							dut_vif.TMS = 0;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);	
							
							dut_vif.TRST = 0;
							@(posedge dut_vif.TCK);
							#1;
							dut_vif.TRST = 1;
							startValiadation_bypass = 0;
					 end

					default: break;				
				endcase
			end //while loop	
		end //SAMPLE_PRELOAD_INSTR
		
		
		if(extest_true == TRUE)
		begin
			if(isFirstReset == TRUE)
			begin
				// First toggle reset
				dut_vif.TRST = 0;
				@(posedge dut_vif.TCK);
				#1;
				dut_vif.TRST = 1;
				isFirstReset = FALSE;
			end

			//Initializing the TAP controller to go to RUN_TEST_IDLE
			seq_item_port.get_next_item(req);
			begin //Test Logic Reset STATE
				dut_vif.TDI = 1; //Initializing the input port to 1'b1
				dut_vif.TMS = 0;
				seq_item_port.item_done();
				@(posedge dut_vif.TCK);
			end

			count = 0;
			if(`testForFulladder==1)
			begin
				dut_vif.A   =  PreloadValue[2];
				dut_vif.B   =  PreloadValue[3];
			 	dut_vif.Cin =  PreloadValue[4];
			end

			while(count<=17 && init ==1)
			begin
				seq_item_port.get_next_item(req);
				case(count)
					
					0: begin //Run Test Idle STATE
						dut_vif.TMS = 1;	
						count++;
						//complete = 1; //process completed		
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
					
					1: begin //Select DR Scan STATE
						dut_vif.TMS = 1;			
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					2: begin //Select IR Scan STATE		
						dut_vif.TMS = 0;
						dut_vif.TDI = 0; //For the first bit that will be shifted into the Instruction Register
						count++;					
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
					end
						
					3: begin //capture ir state
						 dut_vif.TMS = 0;		
						 count++;					
						 seq_item_port.item_done();
						 @(posedge dut_vif.TCK);
					 end
					 
					4: begin //SHIFT IR STATE 
						for(int i=0; i<=2; i++)//SHIFTING THE IR WITH Instruction for Intest
						begin
							if(i!=0)  seq_item_port.get_next_item(req);
							dut_vif.TMS = 0;		
							if(i==0) dut_vif.TDI = 0;		
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
						dut_vif.TDI = 0;			
						seq_item_port.item_done();
						@(posedge dut_vif.TCK);
						
					end
					
					5: begin //EXIT1 IR STATE 
							dut_vif.TMS = 1;
							dut_vif.TDI = 0;		
							count++;					
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					
					 6: begin //UPDATE IR STATE 
							dut_vif.TMS = 1;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					
					 7: begin //SELECT DR STATE 
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 8: begin //CAPTURE DR STATE 
							dut_vif.TMS = 0;							
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end
					 
					 9: begin //SHIFT DR STATE 
					 		//startValiadation = 1;
							for(int i=0; i<`numberOfBoundaryScanCells-1; i++)//Shfting in the bits for Preloading
							begin
								if(i!=0)  seq_item_port.get_next_item(req);
								dut_vif.TMS = 0;		
								dut_vif.TDI = PreloadValue[i];
								//if(introduceErrorIdcode && i>10 && i<15)
								//	dut_vif.TDO = 1;
								//`uvm_info("DUT", $sformatf("TDO=%b", dut_vif.TDO), UVM_MEDIUM	)						
								seq_item_port.item_done();
								@(posedge dut_vif.TCK);			
							end 
							count++;
					 end

					 10: begin //EXIT1 DR STATE 
							dut_vif.TMS = 1;
							dut_vif.TDI = PreloadValue[`numberOfBoundaryScanCells-1];			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 11: begin //UPDATE DR STATE 
							dut_vif.TMS = 1;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 12: begin // SELECT DR SCAN
							dut_vif.TMS = 1;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 13: begin // CAPTURE DR SCAN
							dut_vif.TMS = 0;			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end 
					 
					 14: begin //SHIFT DR STATE 
					 		startValiadation_intest = 1;
							for(int i=0; i<=`numberOfBoundaryScanCells-1; i++)//Shfting out the bits to test Internal Circuitry
							begin
								if(i!=0)  seq_item_port.get_next_item(req);
								dut_vif.TMS = 0;	
								dut_vif.TDI = PreloadValue[i];
								//if(introduceErrorIdcode && i>10 && i<15)
								//	dut_vif.TDO = 1;
								//`uvm_info("DUT", $sformatf("TDO=%b", dut_vif.TDO), UVM_MEDIUM	)						
								seq_item_port.item_done();
								@(posedge dut_vif.TCK);			
							end 
							count++;
					 end

					 15: begin //EXIT1 DR STATE 
							dut_vif.TMS = 1;
							dut_vif.TDI = PreloadValue[`numberOfBoundaryScanCells-1];			
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 16: begin //UPDATE DR STATE 
							dut_vif.TMS = 0;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);			
					 end

					 17: begin //RUN_TEST_IDLE STATE 
							dut_vif.TMS = 0;		
							count++;
							seq_item_port.item_done();
							@(posedge dut_vif.TCK);	
							//init++;		
					 end
			
					default: break;				
			
				endcase
			end //while loop
		end //EXTEST_INSTR


		`uvm_warning("", "TEST COMPLETED!!")
		
		`ifdef BYPASS_INSTR compareForBypass(); `endif
		
		`ifdef IDCODE_INSTR compareForIdcode(); `endif
		
		`ifdef EXTEST_INSTR 
			if(`testForFulladder)
				printForExtestFullAdder(); 
			else
				printExtest();
		`endif
		
		`ifdef SAMPLE_PRELOAD_INSTR printSamplePreload(); `endif

		`ifdef INTEST_INSTR	printIntest(); `endif
		report_phase(phase);

	endtask

	virtual function void compareForBypass();

		//$display("BYPASS INSTRUCTION SELECTED:");

		for(integer m=0; m<`DATA_LENGTH; m++)
		begin
			if(validationBufferTDI_bypass[m]==validationBufferTDO_bypass[m+2]) // One clock cycle delay. The BYPASS register is a 1-bit register.
			begin
				//`uvm_warning("compareForBypass", "SAME" )
				//$display("TDI= %b TDO=%b ",validationBufferTDI_bypass[m], validationBufferTDO_bypass[m+2] );
			end
			else
			begin
				`uvm_error("compareForBypass", "DIFFERENT")
				$display("compareForBypass: TDI= %b TDO=%b ",validationBufferTDI_bypass[m], validationBufferTDO_bypass[m+2] );
				bypassErrorCount++;
			end
		end

		if(bypassErrorCount == 0)
		begin 
			$display("\n\nBYPASS PASSED SUCCESSFULLY! \n\n",);
		end
		else
		begin
			$display("\n\nBYPASS FAILED! Check previous log for details \n\n",);
		end
	endfunction: compareForBypass

	virtual function void compareForIdcode();

		bit [31:0] EXPECTED = `IDCODE_VALUE;
		bit [31:0] RECEIVED;

		//$display("IDCODE INSTRUCTION SELECTED:");

		for(integer m=0; m<32; m++)
		begin
			RECEIVED[m] = validationBufferTDO_idcode[m+1]; 
			//$display("%d RECEIVED= %b EXPECTED=%b ",m+1, validationBufferTDO[m+1], EXPECTED[m] );
		end
		
		if(RECEIVED == EXPECTED) // Comparing the bit stream read out on TDO with the expected value of the IDCODE register
		begin
			//`uvm_warning("compareForIdcode", "IDCODE MATCHED!" )
			$display(" \n\nRECEIVED IDCODE= %h EXPECTED IDCODE=%h ", RECEIVED, EXPECTED );
			$display("IDCODE PASSED SUCCESSFULLY \n\n",);
		end
		else
		begin `uvm_error("compareForIdcode", "IDCODE DO NOT MATCH")
			$display(" \n\nRECEIVED IDCODE= %h EXPECTED IDCODE=%h ", RECEIVED, EXPECTED );
			$display("IDCODE FAILED! \n\n",);
		end
	endfunction: compareForIdcode

	virtual function void printForExtestFullAdder();

		bit [1:0] EXPECTED;
		bit errorExists = 0;
		//$display("INTEST INSTRUCTION SELECTED:\n");

		//EXPECTED output values
		{EXPECTED[1], EXPECTED[0]} = PreloadValue[2] + PreloadValue[3] + PreloadValue[4];

		//Comparing each input and output
		if(EXPECTED[0] != validationBufferTDO_intest[4]) //Checking for Sum
		begin
			`uvm_error("printForIntest", "Sum Value is wrong!")
			errorExists = 1;
			//$display("EXPECTED - %d RECEIVED - %d", EXPECTED[1], validationBufferTDO[4]);
		end
		if(EXPECTED[1] != validationBufferTDO_intest[3]) //Checking for Cout
		begin
			`uvm_error("printForIntest", "Cout Value is wrong")
			errorExists = 1;
			//$display("EXPECTED - %d RECEIVED - %d", EXPECTED[0], validationBufferTDO[3]);
		end
		if(PreloadValue[2] != validationBufferTDO_intest[5]) //Checking for A
		begin
			`uvm_error("printForIntest", "A Value is wrong")
			errorExists = 1;
		end
		if(PreloadValue[3] != validationBufferTDO_intest[6]) //Checking for B
		begin
			`uvm_error("printForIntest", "B Value is wrong")
			errorExists = 1;
		end
		if(PreloadValue[4] != validationBufferTDO_intest[7]) //Checking for Cin
		begin
			`uvm_error("printForIntest", "C Value is wrong")
			errorExists = 1;
		end

		if(errorExists == 1)
			$display(" \n\nEXTEST FAILED! \n\n",);
		else
			$display(" \n\nEXTEST PASSED SUCCESSFULLY \n\n",);
	endfunction: printForExtestFullAdder

	virtual function void printSamplePreload();

		$display("\n\nSAMPLE-PRELOAD INSTRUCTION executed \n\n",);
	endfunction: printSamplePreload

	virtual function void printIntest();

		$display("\n\nINTEST INSTRUCTION executed \n\n",);
	endfunction : printIntest

	virtual function void printExtest();

		$display("\n\nEXTEST INSTRUCTION executed \n\n",);
	endfunction : printExtest

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
			@(posedge dut_vif.TCK)
			begin
				if(startValiadation_bypass)
				begin
					sa_tx.tdi = dut_vif.TDI;
					mon_ap_before.write(sa_tx); // This instruction writes the data to the scoreboard
					validationBufferTDI_bypass[tdiScan]=dut_vif.TDI; 
					tdiScan++;
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
	integer tdoScan_bypass =0;
	integer tdoScan_idcode =0;
	integer tdoScan_intest =0;
	integer tdoScan_extest =0;


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

			@(negedge dut_vif.TCK)
			begin					
				if(startValiadation_bypass == 1)
				begin
					sa_tx_after.tdo = dut_vif.TDO;
					mon_ap_after.write(sa_tx_after);
					validationBufferTDO_bypass[tdoScan_bypass]=dut_vif.TDO;
					tdoScan_bypass++;
				end

				if(startValiadation_idcode == 1)
				begin
					sa_tx_after.tdo = dut_vif.TDO;
					mon_ap_after.write(sa_tx_after);
					validationBufferTDO_idcode[tdoScan_idcode]=dut_vif.TDO;
					tdoScan_idcode++;
				end

				if(startValiadation_intest == 1)
				begin
					sa_tx_after.tdo = dut_vif.TDO;
					mon_ap_after.write(sa_tx_after);
					validationBufferTDO_intest[tdoScan_intest]=dut_vif.TDO;
					//$display("%d $time() %d Value of TDO - %d",tdoScan_intest, $time, validationBufferTDO_intest[tdoScan_intest]);
					tdoScan_intest++;
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
			before_fifo.get(transaction_before);
			after_fifo.get(transaction_after);
		end
	endtask: run
endclass: jtag_scoreboard