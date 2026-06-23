# INT8 neural network accelerator (FPGA)
 
A SystemVerilog hardware accelerator implementing an INT8 matrix-vector multiply unit, verified end-to-end against a real PyTorch-trained MNIST classifier. Fully verified in simulation; targets the Intel FPGA PAC N3000.
 
## Overview
 
This project implements a small but complete hardware/software pipeline for neural network inference:
 
1. A pipelined INT8 matrix-vector multiply unit built from scratch in SystemVerilog
2. An FSM controller that orchestrates memory reads, computation, and result storage
3. Simulated dual-port Block RAM for weights, inputs, and outputs
4. A single-layer MNIST digit classifier trained in PyTorch, quantized to INT8, and fed through the hardware
5. Comprehensive self-checking testbenches at every level, including a bit-exact match against the Python reference
The hardware is scoped to a 4×4 matrix-vector multiply. To demonstrate a complete pipeline, a real PyTorch model was trained on MNIST and a 4-element slice of one trained classifier's weights and one real image's pixels were run through the hardware, producing a result that exactly matches Python's quantized output. This is not a working digit classifier, but it proves the multiply-accumulate datapath, the quantization, and the hardware/software handoff are all correct, using real numbers from a real trained model.
 
## Architecture
 
### System block diagram
 
```
                    ┌─────────────┐
                    │     FSM     │
                    │ (controller)│
                    └──────┬──────┘
                           │ addresses, enables
              ┌────────────┼────────────┐
              ▼            ▼            ▼
      ┌───────────┐ ┌───────────┐ ┌───────────┐
      │  weight   │ │  vector   │ │  output   │
      │   BRAM    │ │   BRAM    │ │   BRAM    │
      └─────┬─────┘ └─────┬─────┘ └─────▲─────┘
            │             │             │
            ▼             ▼             │
      ┌─────────────────────────┐       │
      │   mat_vec_mul (pipelined)│──────┘
      │   multiply → accumulate  │
      └─────────────────────────┘
```
 
### FSM state diagram
 
![FSM State Diagram](docs\fsm_diagram_updated.png)
 
States: `IDLE → PRELOAD → LOAD → COMPUTE → STORE → DONE`
 
- **PRELOAD** — reads the full 4×4 weight matrix from BRAM into internal registers before computation starts
- **LOAD / COMPUTE / STORE** — loops once per matrix row: loads the input vector, computes the dot product, writes the result
- **DONE** — signals a complete inference pass; pulses back to IDLE
## Performance (simulation)
 
| Metric | Value |
|---|---|
| Pipeline stages | 2 (multiply → accumulate) |
| Latency | 2 clock cycles per row |
| Throughput | 1 matrix-vector multiply per clock cycle (once pipeline is full) |
| Data width | INT8 weights/inputs, INT32 accumulator |
| Matrix size | 4×4 |
| Clock frequency | not yet synthesized — simulation only |
 
## MNIST inference demo
 
A single linear layer (`nn.Linear(784, 10)`) was trained on MNIST in PyTorch, reaching **91.8–92.1% test accuracy**. Weights were quantized to INT8 using per-tensor symmetric scaling.
 
Hardware test: the digit-2 classifier's weights `[10, 12, 13, 1]` were run against the center 4 pixels of a real test image labeled "2" (`[127, 1, 68, -21]`).
 
```
Python reference: 2145
Hardware result[2]:      2145   (exact match)
```
 
See `docs/mnist_inference_result.png` for the simulation output.
 
## Running the simulation
 
Requires Questa Intel FPGA Starter Edition (or any SystemVerilog-2012 capable simulator).
 
```bash
vlog -sv src/bram.sv src/fsm.sv src/mat_vec_mul.sv src/accelerator_top.sv tb/accelerator_top_tb.sv
vsim -c accelerator_top_tb -do "run -all; quit"
```
 
To retrain the model and regenerate the reference data:
 
```bash
python scripts/train_mnist.py
```
 
## Verification summary
 
- `mat_vec_mul_tb.sv` — 24 passing tests: identity matrix, all-ones, negative weights, 3 randomized vectors cross-checked against NumPy, and INT8 boundary values (max positive, max negative, zero matrix)
- `fsm_tb.sv` — full state transition trace (IDLE→PRELOAD→LOAD→COMPUTE→STORE→DONE×4) plus a SystemVerilog assertion (`disable iff (rst)`) that flags any illegal FSM state
- `accelerator_top_tb.sv` — full system integration test; hardware output matches a real PyTorch-quantized MNIST classifier exactly
## Known limitations / scope
 
- 4×4 matrix size only — a real MNIST classifier needs 784 input features; this hardware demonstrates the math and pipeline on a representative slice, not full inference
- Simulation only — not yet synthesized to the target Intel FPGA PAC N3000
- Vector is re-read from BRAM on every row pass rather than cached, since it doesn't change between rows (a minor efficiency opportunity, not a correctness issue)
## Tools
 
- SystemVerilog (IEEE 1800-2012)
- Questa Intel FPGA Starter Edition / Icarus Verilog
- PyTorch + NumPy for training and golden reference
- Target board: Intel FPGA PAC N3000