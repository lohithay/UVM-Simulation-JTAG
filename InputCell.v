//////////////////////////////////////////////////////////////////////
////                                                              ////
////  InputCell.v                                                 ////
////                                                              ////
////  Project : UVM Simulationsmodell eines JTAG-Interfaces       ////
////                                                              ////
////  Author(s):                                                  ////
////    Serin Varghese                                            ////
////    Micro and Nano Systems,                                   ////
////    TU Chemnitz                                               ////
////                                                              ////
////  Date: July 2017                                             ////
////                                                              ////
////  Notes: The boundary Scan Cell sub-module is defined here.   ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

/*
                  ToNextBSCell
                      ^
                      |
                 _____|_____
                 |        |
InputPin ------->| Scan   |-------> ToCore
                 | Cell   |
                 ----------
                      ^
                      |
                      |
              FromPreviousBSCell
            
            */

module InputCell( InputPin, FromPreviousBSCell, CaptureDR, ShiftDR, UpdateDR, TCK, ToNextBSCell, ToCore);
input  InputPin;
input  FromPreviousBSCell;
input  CaptureDR;
input  ShiftDR; 
input  UpdateDR;
input  TCK;
output ToNextBSCell;
output ToCore; 

reg    Latch;      
reg    ToNextBSCell;
reg    ToCore;

always @(posedge TCK)
begin
	if(CaptureDR)
		Latch <= InputPin;
	else if(UpdateDR)
		ToCore <= Latch; 
	else if(ShiftDR)
		Latch <= FromPreviousBSCell; // Receives one bit from the previous BS Cell
end

always @(negedge TCK)
begin
	if(ShiftDR)
		ToNextBSCell <= Latch; // Passes on data to the next BS Cell in chain
end

endmodule	// InputCell


