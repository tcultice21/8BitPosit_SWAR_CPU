# SIMD-Within-a-Register Full Processor with 8-Bit Posit Support
## With Planned FPGA supplementary support for Xilinx Vivado Implementation for XC7 CPG236 (Basys 3) FPGAs.

This repository contains my implementation of the [ECE480 "Gr8BOnd" Project](https://aggregate.org/EE480/gr8bond.html) from 2020 at the University of Kentucky. This design consists of a 16-bit processor with support for SIMD parallelism of two 8-bit [Posits](http://www.johngustafson.net/pdfs/BeatingFloatingPoint.pdf), an alternative to floating point numbers. It also contains support for 16-bit floats via lookup table, pipelined instructions, OS Trap functionality, and branch prediction.

The project consists of a full instruction set (created by Dr. Hank Dietz) and data memory, with planned modifications to allow for external peripheral/memory addressing (for things like IO interfacing and peripherals). This makes it more friendly to put on FPGAs, such as the Diligent Basys 3 board (top module for that is included for testing). 

The instruction set is provided below with this implementation's specific bit mapping, for reference.
| **Instruction** | **Description** | **Functionality** |
| --- | --- | --- |
| addi $_d_, $_s_ | Add 16-bit integers | $_d_\[15:0\] += $_s_\[15:0\] |
| addii $_d_, $_s_ | Add 8-bit integers | $_d_\[15:8\] += $_s_\[15:8\]; $_d_\[7:0\] += $_s_\[7:0\] |
| addf $_d_, $_s_ | Add 16-bit floats | $_d_\[15:0\] += $_s_\[15:0\] |
| addpp $_d_, $_s_ | Add 8-bit posits | $_d_\[15:8\] += $_s_\[15:8\]; $_d_\[7:0\] += $_s_\[7:0\] |
| and $_d_, $_s_ | bitwise AND 16-bit | $_d_\[15:0\] &= $_d_\[15:0\] |
| anyi $_d_ | bitwise ANY reduction, 16-bit integer | $_d_\[15:0\] = ($_d_\[15:0\] ? -1 : 0) |
| anyii $_d_ | bitwise ANY reduction 8-bit integers | $_d_\[15:8\] = ($_d_\[15:8\] ? -1 : 0); $_d_\[7:0\] = ($_d_\[7:0\] ? -1 : 0) |
| bnz $_c_, _addr_ | Branch if Non-Zero | if ($_c_\[15:0\] != 0) PC += (_addr_\-PC) |
| bz $_c_, _addr_ | Branch if Zero | if ($_c_\[15:0\] == 0) PC += (_addr_\-PC) |
| ci $_d_, _c16_ | Constant 16-bit | $_d_\[15:0\] = _c16_ // by shortest sequence of instructions |
| ci8 $_d_, _c8_ | Constant 8-bit sign extended to 16-bit | $_d_\[15:0\] = ((_c8_ & 0x80) ? 0xff00 : 0) \| (_c8_ & 0xff) |
| cii $_d_, _c8_ | Constant 8-bit duplicated to 16-bit | $_d_\[15:8\] = _c8_; $_d_\[7:0\] = _c8_ |
| cup $_d_, _c8_ | Constant 8-bit to upper 8-bits | $_d_\[15:8\] = _c8_ |
| dup $_d_, $_s_ | Duplicate | $_d_\[15:0\] = $_s_\[15:0\] |
| f2i $_d_ | 16-bit float to integer | $_d_\[15:0\] = (float16)$_d_\[15:0\] |
| f2pp $_d_ | 16-bit float to 8-bit posits | $_d_\[15:0\] = { 2{((posit8)$_d_\[15:0\])}} |
| i2f $_d_ | 16-bit integer to float | $_d_\[15:0\] = (float16)$_d_\[15:0\] |
| ii2pp $_d_ | 8-bit integers to posits | $_d_\[15:8\] = (posit8)$_d_\[15:8\]; $_d_\[7:0\] = (posit8)$_d_\[7:0\] |
| invf $_d_ | Reciprocal 16-bit float | $_d_\[15:0\] = 1 / $_d_\[15:0\] |
| invpp $_d_ | Reciprocal 8-bit posits | $_d_\[15:8\] = 1 / $_d_\[15:8\]; $_d_\[7:0\] = 1 / $_d_\[7:0\] |
| jmp _addr_ | Jump to 16-bit address | PC = _addr_ // by shortest sequence of instructions |
| jnz $_d_, _addr_ | Jump Non-Zero to 16-bit address | if ($_d_ != 0) PC = _addr_ // by shortest sequence of instructions |
| jz $_d_, _addr_ | Jump Zero to 16-bit address | if ($_d_ == 0) PC = _addr_ // by shortest sequence of instructions |
| jr $_a_ | Jump Register | PC = $_a_\[15:0\] |
| ld $_d_, $_s_ | LoaD | $_d_\[15:0\] = memory\[$_s_\[15:0\]\] |
| muli $_d_, $_s_ | Multiply 16-bit integers | $_d_\[15:0\] \*= $_s_\[15:0\] |
| mulii $_d_, $_s_ | Multiply 8-bit integers | $_d_\[15:8\] \*= $_s_\[15:8\]; $_d_\[7:0\] \*= $_s_\[7:0\] |
| mulf $_d_, $_s_ | Multiply 16-bit floats | $_d_\[15:0\] \*= $_s_\[15:0\] |
| mulpp $_d_, $_s_ | Multiply 8-bit posits | $_d_\[15:8\] \*= $_s_\[15:8\]; $_d_\[7:0\] \*= $_s_\[7:0\] |
| negf $_d_ | Negate 16-bit float | $_d_\[15:0\] = -$_d_\[15:0\] |
| negi $_d_ | Negate 16-bit integer | $_d_\[15:0\] = -$_d_\[15:0\] |
| negii $_d_ | Negate 8-bit integers | $_d_\[15:8\] = -$_d_\[15:8\]; $_d_\[7:0\] = -$_d_\[7:0\] |
| not $_d_ | bitwise NOT 16-bit | $_d_\[15:0\] = ~$_d_\[15:0\] |
| or $_d_, $_s_ | bitwise OR 16-bit | $_d_\[15:0\] \|= $_d_\[15:0\] |
| pp2f $_d_ | (low) 8-bit posit to 16-bit float | $_d_\[15:0\] = (float)$_d_\[7:0\] |
| pp2ii $_d_ | 8-bit posits to integers | $_d_\[15:8\] = (int8)$_d_\[15:8\]; $_d_\[7:0\] = (int8)$_d_\[7:0\] |
| shi $_d_, $_s_ | shift 16-bit | $_d_\[15:0\] = (($_s_\[15:0\] > 0) ? ($_d_\[15:0\] << $_s_\[15:0\]) : ($_d_\[15:0\] >> -$_s_\[15:0\])) |
| shii $_d_, $_s_ | shift 8-bit fields | $_d_\[15:8\] = (($_s_\[15:8\] > 0) ? ($_d_\[15:8\] << $_s_\[15:8\]) : ($_d_\[15:8\] >> -$_s_\[15:8\]));  <br>$_d_\[7:0\] = (($_s_\[7:0\] > 0) ? ($_d_\[7:0\] << $_s_\[7:0\]) : ($_d_\[7:0\] >> -$_s_\[7:0\])) |
| slti $_d_, $_s_ | Set Less Than 16-bit integers | $_d_\[15:0\] = $_d_\[15:0\] < $_s_\[15:0\] |
| sltii $_d_, $_s_ | Set Less Than 8-bit integers | $_d_\[15:8\] = $_d_\[15:8\] < $_s_\[15:8\]; $_d_\[7:0\] = $_d_\[7:0\] < $_s_\[7:0\] |
| st $_d_, $_s_ | STore | memory\[$_s_\[15:0\]\] = $_d_\[15:0\] |
| trap | Trap to OS | _this does a bunch of things..._ |
| xor $_d_, $_s_ | bitwise XOR 16-bit | $_d_\[15:0\] ^= $_s_\[15:0\] |
