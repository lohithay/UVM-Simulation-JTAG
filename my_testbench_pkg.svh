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
//// - Agent                                                       ////
//// - Environement                                                ////
///////////////////////////////////////////////////////////////////////

//Defining the name of the package
package my_testbench_pkg;
// Imports
import uvm_pkg::*;
`include "my_sequence.svh"

// ================================================================== //
//                                                                    //
// AGENT                                                              //
//                                                                    //
// The agent contains sequencer, driver, and monitor (not included)   //
//                                                                    //
// ================================================================== //  
class my_agent extends uvm_agent;
	`uvm_component_utils(my_agent)

	uvm_analysis_port#(my_transaction) agent_ap_before;
	uvm_analysis_port#(my_transaction) agent_ap_after;
	
	jtag_monitor_before  mon_before;
	jtag_monitor_after   mon_after ;
	my_driver driver;
	uvm_sequencer#(my_transaction) sequencer;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	// Build Phase
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		agent_ap_before = new("agent_ap_before", this);
		agent_ap_after  = new("agent_ap_after", this);;
		
		sequencer = uvm_sequencer#(my_transaction)::type_id::create("sequencer", this);
		driver = my_driver ::type_id::create("driver", this);
		mon_before = jtag_monitor_before::type_id::create("mon_before", this);
		mon_after = jtag_monitor_after::type_id::create("mon_after", this);		
	endfunction : build_phase

	// Connect Phase
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		
		driver.seq_item_port.connect(sequencer.seq_item_export);		
		mon_after.mon_ap_after.connect(agent_ap_after);
		mon_before.mon_ap_before.connect(agent_ap_before);
		
	endfunction

	// Run Phase
	task run_phase(uvm_phase phase);	
		phase.raise_objection(this);  // We raise objection to keep the test from completing
		begin
			my_sequence seq;
			seq = my_sequence::type_id::create("seq");
			seq.start(sequencer);
		end	
		phase.drop_objection(this);  // We drop objection to allow the test to complete
	endtask

endclass: my_agent
	
// ================================================================== //
//                                                                    //
// ENVIRONMENT                                                        //
//                                                                    //
// ================================================================== //
class my_env extends uvm_env;
	`uvm_component_utils(my_env)

		my_agent agent;

		function new(string name, uvm_component parent);
			super.new(name, parent);
		endfunction
		
		function void build_phase(uvm_phase phase);
			agent = my_agent::type_id::create("agent", this);
		endfunction

endclass: my_env

// ================================================================== //
//                                                                    //
// MY TEST                                                            //
//                                                                    //
// ================================================================== //
class my_test extends uvm_test;
	`uvm_component_utils(my_test)

	my_env env;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		env = my_env::type_id::create("env", this);
	endfunction

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);  // We raise objection to keep the test from completing
		#10;
		`uvm_warning("", "Task Started! Ready for Lift-off!")
		phase.drop_objection(this);  // We drop objection to allow the test to complete
	endtask

	endclass: my_test
 
endpackage