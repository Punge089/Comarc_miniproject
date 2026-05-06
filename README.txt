SAP-1 Verilog Mini Project

ลิ้ง report_v2 : https://docs.google.com/document/d/1j-WHbk19SJPMEqLg20Xl5C-6jCeKzmsBSWOBTCpixcw/edit?usp=sharing

VERILOG FILES (load all into Vivado in this order):
  1. program_counter.v     Program Counter (PC)
  2. mar.v                 Memory Address Register
  3. instruction_register.v Instruction Register (IR)
  4. register.v            Generic 8-bit Register (used for A and B)
  5. alu.v                 ALU: ADD, SUB, MUL, DIV
  6. memory.v              16x8 Memory with preloaded test program
  7. control_unit.v        Hardwired Control Unit (T-state machine)
  8. sap1_top.v            Top-level CPU module (bus mux + connections)
  9. sap1_tb.v             Testbench (6 test cases)

HOW TO RUN IN VIVADO:
  1. Create new RTL project in Vivado
  2. Add all .v files from /verilog_source/
  3. Right-click sap1_tb > Set as Top (for simulation)
  4. Click: Flow > Run Simulation > Run Behavioral Simulation
  5. Add signals to waveform window (see Section 9 of the report)
  6. Take screenshots as described in report Section 9.3

TEST CASES IN TESTBENCH:
  Test 1: LDA 3 + ADD 6   → A = 4+5 = 9   (0x09) [PROJECT SPEC]
  Test 2: LDA 3 + SUB 6   → A = 4-5 = 255 (0xFF)
  Test 3: LDA 3 + MUL 6   → A = 4*5 = 20  (0x14)
  Test 4: LDA 3 + DIV 6   → A = 4/5 = 0   (0x00)
  Test 5: LDA 6 + DIV 3   → A = 5/4 = 1   (0x01)
  Test 6: LDA 3 + MUL 3   → A = 4*4 = 16  (0x10)

INSTRUCTION OPCODES:
  LDA = 0000   ADD = 0001   SUB = 0010
  MUL = 0011   DIV = 0100   HLT = 1111
===================================================
