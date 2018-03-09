# ResearchProjectModule
Masters Module: ResearchProject
Name: Serin Varghese
serin_varghese@yahoo.com
Student
TU Chemnitz
Masters - Micro and Nano Systems


Files to be added to one Questasim project:

- top_module.sv
- tap_top.v
- testbench.sv
- InputCell.v
- my_sequence.svh
- my_testbench_pkg.svh
- full_adder.v
- tap_defines.v
- config.svh
# UVM Simulation Model for a JTAG Interface
A verification component is designed for a device with a JTAG interface. We have selected a full adder module with JTAG capability as our device under test. The instructions of Idcode, Bypass, Sample/Preload, Extest and Intest are implemented. All the implemented instructions are IEEE 1149.1 standard compliant. This verification component is designed with the use of the Universal Verification Methodology. Using the modules of the UVM environment, we have given the DUT a set of constrained stimulus and observed the response. The designed VC has the capability to introduce errors to understand how the VC would react to runtime errors. The errors, if any, are printed out on the console. This VC gives us an advantage of reusability wherein this full adder module can be replaced by any other module and the tests can be repeated with little effort. In this project we have designed the advanced DUTs with JTAG capability and verification environment, tested the working of the JTAG instructions and finally compared the expected data with the one that is actually observed. 


## Installation
This project needs QuestaSim to run. 


## Usage

Steps to run the code:
1. Download or clone the repository .
2. Make a project with the following source codes in QUESTASIM
- top_module.sv
- tap_top.v
- testbench.sv
- InputCell.v
- my_sequence.svh
- my_testbench_pkg.svh
- full_adder.v
- tap_defines.v
- config.svh
3. Compile and Simulate the code (Select the top module from the work library)
4. To see the waveforms, in the 'sim' window, right click on 'dut_if1' and 'Add Wave'.

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Credits

TODO: Write credits

## License

TODO: Write license
