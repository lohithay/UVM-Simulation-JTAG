//////////////////////////////////////////////////////////////////////
////                                                              ////
////  top_module.sv                                               ////
////                                                              ////
////  This file has been edited for the Project : UVM             ////
////  Simulationsmodell eines JTAG-Interfaces                     ////
////                                                              ////
////  Author(s):                                                  ////
////    Serin Varghese                                            ////
////    Micro and Nano Systems,                                   ////
////    TU Chemnitz                                               ////
////                                                              ////
////  Date: July 2017                                             ////
////                                                              ////
////  Notes: This file contains the top_module of the DUT.        ////
////         All the sub-modules are instantiated here            ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`include "tap_defines.v"
`include "tap_top.v"
`include "full_adder.v"
`include "InputCell.v"
`include "OutputCell.v"

`include "uvm_macros.svh"
import uvm_pkg::*;
 

 //Defining the interface
interface dut_if;
	logic A, B, Cin, Sum, Cout;
	logic TMS, TCK, TDI, TDO, TRST;
endinterface
 
module dut(dut_if dif);

wire w1, w2, w3, w4; // Wires between the Boundary Scan Cells
wire DRCapture, DRShift, DRUpdate;  //Connections between the TAP controller and the Boundary Scan Cells for state of the TAP FSM
wire AToCore, BToCore, CinToCore, CoreToSum, CoreToCout;  //Connections between Boundary Scan Cells and the FullAdder

full_adder full_adder1(AToCore, BToCore, CinToCore, CoreToSum, CoreToCout );
tap_top tap_top1(dif.TMS, dif.TCK, dif.TRST, dif.TDI, dif.TDO, DRShift, DRUpdate, DRCapture, TDO_o, TestMode);

InputCell InputCellA  (dif.A, w2, DRCapture, DRShift, DRUpdate, dif.TCK, w3, AToCore, TestMode);
InputCell InputCellB  (dif.B, w1, DRCapture, DRShift, DRUpdate, dif.TCK, w2, BToCore, TestMode);
InputCell InputCellCin(dif.Cin, dif.TDI, DRCapture, DRShift, DRUpdate, dif.TCK, w1, CinToCore, TestMode);

InputCell OutputCellSum(CoreToSum, w3, DRCapture, DRShift, DRUpdate, dif.TCK, w4, dif.Sum, TestMode);
InputCell OutputCellCout(CoreToCout, w4, DRCapture, DRShift, DRUpdate, dif.TCK, TDO_o, dif.Cout, TestMode);

/////////////////////////////////////////////////////////////////////
// WICHTIG: Edit the config.v file everytime this file is edited!! //
/////////////////////////////////////////////////////////////////////

endmodule