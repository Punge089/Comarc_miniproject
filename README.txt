SAP-1 Verilog Mini Project

Files:
- src/cpu.v: top module connecting all SAP-1 blocks
- src/control_unit.v: hardwired control unit and timing state generator
- src/register8.v: 8-bit register for IR, A, and B
- src/register4.v: 4-bit register for MAR
- src/program_counter.v: 4-bit PC for 16-byte memory
- src/memory.v: 16 x 8-bit memory
- src/alu.v: ADD, SUB, MUL, DIV ALU
- src/bus_mux.v: single-bus multiplexer
- src/sap1_tb.v: testbench for ADD, SUB, MUL, DIV

Vivado usage:
1. Create an RTL project.
2. Add all files in src as design sources except sap1_tb.v.
3. Add sap1_tb.v as a simulation source.
4. Set sap1_tb as simulation top.
5. Run behavioral simulation.
6. Add clk, reset, pc, mar, ir, a_reg, b_reg, bus, t_state, alu_result, halt, and control signals to the waveform.
7. Capture the waveform screenshot for the report.

Expected required test:
Memory[0] = 13 (LDA 3)
Memory[1] = 26 (ADD 6)
Memory[2] = F0 (HLT)
Memory[3] = 04
Memory[6] = 05
Final A register = 09.
