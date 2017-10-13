///////////////////////////////////////////////////////////////////////
////                                                               ////
////  config.svh                                                   ////
////                                                               ////
////  Project : UVM Simulationsmodell eines JTAG-Interfaces        ////
////                                                               ////
////                                                               ////
////  Author(s):                                                   ////
////    Serin Varghese                                             ////
////    Micro and Nano Systems,                                    ////
////    TU Chemnitz                                                ////
////                                                               ////
////  Date: July 2017                                              ////
////                                                               ////
///////////////////////////////////////////////////////////////////////
//// This contains all the conditions for execution of the         ////
//// testbench.                                                    ////
//// - Edit this file everytime the top_module.sv is edited        ////
////                                                               ////
///////////////////////////////////////////////////////////////////////

// DEFINE TO TEST WHICH INSTRUCTION TO EXECUTE
// Select only one out of the following
`define BYPASS_INSTR
`define IDCODE_INSTR
`define SAMPLE_PRELOAD_INSTR
`define INTEST_INSTR
`define EXTEST_INSTR



`define numberOfBoundaryScanCells 5 // Enter here the number of Boundary Scan Cells instantiated in the top_module.sv
`define DATA_LENGTH 30              // Enter the length of the expected datastream for BYPASS Instruction
`define introduceErrorBypass 0      // Toggle to 1 to introduce errors, 0 for normal operation - BYPASS Instruction 
`define introduceErrorIdcode 0      // Toggle to 1 to introduce errors, 0 for normal operation - IDCODE Instruction
`define testForFulladder 1          // Toggle to 1 to run test for full adder, 0 for anyother DUT


//For Sample/Preload, INTEST and EXTEST instructions
// Fill the setPreloadValue according to the bits that are 
// pushed into the TDI serially
`define setPreloadValue 5'b00110 