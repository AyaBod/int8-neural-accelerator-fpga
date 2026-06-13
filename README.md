# INT8 Neural Network Accelerator (FPGA)

SystemVerilog implementation of an INT8 hardware accelerator targeting FPGA.
Will verify simulation using Questa Intel FPGA Starter Edition.

In progress

## Performance (simulation)


Pipeline stages: 2 
Latency:2 clock cycles
Throughput: 1 matrix-vector multiplication per clock cycle
Data width: INT8 weights, INT32 accumulator 
Matrix size: 4×4

## Tools
- SystemVerilog (IEEE 1800-2012)
- Questa Intel FPGA Starter Edition
- Target board: Intel FPGA PAC N3000
