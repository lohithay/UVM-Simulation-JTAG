//////////////////////////////////////////////////////////////////////
////                                                              ////
////  top_module.sv                                               ////
////                                                              ////
////  This file has been edited for the Project : UVM             ////
////  Simulationsmodell eines JTAG-Interfaces                     ////
////                                                              ////
////  Author(s):                                                  ////
////    Serin Varghese                                            ////
////                                                              ////
////  Notes: Codes adapted from EDA Playground example files and  ////
////         Opencores project                                    ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Code partly edited from tap_top.v                           ////
////                                                              ////
////                                                              ////
////  This file is part of the JTAG Test Access Port (TAP)        ////
////                                                              ////
////  Author(s):                                                  ////
////       Igor Mohor (igorm@opencores.org)                       ////
////       Nathan Yawn (nathan.yawn@opencores.org)                ////
////                                                              ////
////                                                              ////
////  All additional information is avaliable in the jtag.pdf     ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 - 2008 Authors                            ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//                                                                ////
// CVS Revision History                                           ////
//                                                                ////
// $Log: tap_top.v,v $                                            ////
// Revision 1.5  2009-06-16 02:53:58  Nathan                      ////
// Changed some signal names for better consistency between       ////
// different hardware modules. Removed stale CVS log/comments.    ////
//                                                                ////
// Revision 1.4  2009/05/17 20:54:38  Nathan                      ////
// Changed email address to opencores.org                         ////
//                                                                ////
// Revision 1.3  2008/06/18 18:45:07  Nathan                      ////
// Improved reset slightly.  Cleanup.                             ////
//                                                                ////
//                                                                ////
// Revision 1.2 2008/05/14 13:13:24 Nathan                        ////
// Rewrote TAP FSM in canonical form, for readability.  Switched  ////
// from one-hot to binary encoding.  Made reset signal active-    ////
// low, per JTAG spec.  Removed FF chain for 5 TMS reset - reset  ////
// done in Test Logic Reset mode.  Added test_logic_reset_o and   ////
// run_test_idle_o signals.  Removed double registers from IR data////
// path.  Unified the registers at the output of each data register///
// to a single shared FF.                                         ////
//                                                                ////
//////////////////////////////////////////////////////////////////////
`include "tap_defines.v"
`include "tap_top.v"
`include "full_adder.v"
`include "InputCell.v"
`include "OutputCell.v"

`include "uvm_macros.svh"
import uvm_pkg::*;
 
interface dut_if;

 logic A, B, Cin, Sum, Cout;
 logic TMS, TCK, TDI, TDO, TRST ;
 endinterface
 
module dut(dut_if dif);

reg Sum_o, Cout_o, TDO_o;

wire w1, w2, w3, w4; // Wires between the Boundary Scan Cells
wire DRCapture, DRShift, DRUpdate;  //Connections between the TAP controller and the Boundary Scan Cells for state of the TAP FSM
wire AToCore, BToCore, CinToCore, CoreToSum, CoreToCout;  //Connections between Boundary Scan Cells and the FullAdder
wire extest, sample_preload, idcode, intes, debug, bypass;  //connections to indicate to the Boundary Scan Registers about the current state of the Instruction Register

 
full_adder full_adder1(AToCore, BToCore, CinToCore, CoreToSum, CoreToCout );
tap_top tap_top1(dif.TMS, dif.TCK, dif.TRST, dif.TDI, dif.TDO, DRShift, DRUpdate, DRCapture, extest, sample_preload, idcode, intes, debug, bypass, TDO_o);

InputCell InputCellA  (dif.A, w2, DRCapture, DRShift, dif.TCK, w3, AToCore);
InputCell InputCellB  (dif.B, w1, DRCapture, DRShift, dif.TCK, w2, BToCore);
InputCell InputCellCin(dif.Cin, dif.TDI, DRCapture, DRShift, dif.TCK, w1, CinToCore);

OutputCell OutputCellSum(CoreToSum, w3, DRCapture, DRShift, DRUpdate, extest, dif.TCK, w4, Sum_o);
OutputCell OutputCellCout(CoreToCout, w4, DRCapture, DRShift, DRUpdate, extest, dif.TCK, TDO_o, Cout_o);
  



assign dif.Sum = Sum_o;
assign dif.Cout = Cout_o;


endmodule
 
 /*
 
 module full_adder(	input_a, input_b, input_cin, output_sum_o, output_cout_o );
 
module tap_top(
                // JTAG pads
                tms_pad_i, 
                tck_pad_i, 
                trstn_pad_i, 
                tdi_pad_i, 
                tdo_pad_o, 

                // TAP states
                shift_dr_o, 
                update_dr_o,
                capture_dr_o,
              );
 
 module InputCell( InputPin, FromPreviousBSCell, CaptureDR, ShiftDR, TCK, ToNextBSCell, ToCore);
 
 module OutputCell( FromCore, FromPreviousBSCell, CaptureDR, ShiftDR, UpdateDR, extest, TCK, ToNextBSCell, TristatedPin);
  
 */