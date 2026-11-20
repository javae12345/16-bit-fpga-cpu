# 16-bit FPGA CPU with Memory-Mapped UART

A custom 16-bit, multi-cycle processor designed in SystemVerilog, verified through simulation, and implemented on the Digilent Arty Z7 FPGA development board.

## Project Overview

This project implements a custom processor with an 11-instruction instruction set, an FSM-based control unit, eight general-purpose registers, and separate instruction and data memories.

The processor supports memory-mapped UART communication, allowing it to exchange characters with a PC through a serial terminal.

## Key Features

**CPU Architecture**
- 16-bit multi-cycle processor
- 11-instruction custom ISA
- Eight general-purpose registers
- FSM-based control unit
- Separate instruction and data memories
- Conditional branching and program control

**Memory-Mapped Peripherals**
- UART transmitter and receiver operating at 115200 baud
- Eight-byte UART receive FIFO with overrun detection
- UART status and data registers
- GPIO LED outputs

**Verification**
- 26 SystemVerilog testbench files covering CPU components and integrated functionality
- Tests for branching, memory operations, UART communication, and FIFO behavior
- End-to-end UART echo program verification

## UART Echo Demonstration

The instruction memory contains a hardcoded UART echo program that:

1. Polls the UART receiver status register.
2. Waits until a character is available.
3. Reads the received character.
4. Polls the UART transmitter status register.
5. Waits until the transmitter is ready.
6. Sends the character back to the PC.
7. Updates the FPGA LEDs.
8. Repeats the process.

The program was tested on the Arty Z7 board using RealTerm.

## Memory-Mapped I/O

| Address | Function |
|---|---|
| `0xFB` (251) | UART TX status |
| `0xFC` (252) | UART RX data |
| `0xFD` (253) | UART RX status |
| `0xFE` (254) | UART TX data |
| `0xFF` (255) | GPIO LED output |

## Tools and Hardware

- SystemVerilog
- Xilinx Vivado 2025.1
- Digilent Arty Z7
- RealTerm serial terminal

## Repository Structure

- `rtl/` — Synthesizable SystemVerilog design modules
- `tb/` — SystemVerilog testbenches
- `constraints/` — FPGA constraints

## Future Improvements

- Support loading programs from external initialization files
- Expand the instruction set
- Add additional memory-mapped peripherals
- Improve simulation automation