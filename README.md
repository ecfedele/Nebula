# The *Nebula* RISC-V (RV32) Core

The *Nebula* core is a from-scratch implementation of the 32-bit RISC-V instruction set architecture in synthesizable VHDL optimized for FPGA use. Implementing the RV32I and RV32M integer instruction sets as well as the RV32F and RV32D floating-point extensions, *Nebula* seeks to provide a high-performance proof-of-concept RISC-V core for embedded applications.

As this project is still in its early stages, it is important to check this README regularly to keep apprised of the implementation status of various features. In a nutshell, the *Nebula* project seeks to:

 - Develop a pipelined [RV32I](https://five-embeddev.com/riscv-isa-manual/latest/rv32.html) implementation, complete with hardware multiplier/divider ([RV32M](https://five-embeddev.com/riscv-isa-manual/latest/m.html#m-standard-extension-for-integer-multiplication-and-division-version-2.0)) support
 - Incrementally add support for single-precision ([RV32F](https://five-embeddev.com/riscv-isa-manual/latest/f.html#sec:single-float)) and double-precision ([RV32D](https://five-embeddev.com/riscv-isa-manual/latest/d.html#d-standard-extension-for-double-precision-floating-point-version-2.2)) floating-point extensions
 - Configure the core around the [open-source Wishbone bus](https://cdn.opencores.org/downloads/wbspec_b4.pdf) for external communications, enabling the use of other open-source IP cores for peripherals and further promoting the development of an open computing environment
 - Provide a testbed and base from which to develop more advanced microprocessor concepts, such as 64-bit computing, memory management, and out-of-order execution

## Licensing

The *Nebula* IP and source are licensed under the [CERN Open Hardware License, version 2.0 (strongly reciprocal)](https://ohwr.org/cern_ohl_s_v2.txt). In short, this offers complete access and permissions to use, modification, and distribution of *Nebula* and *Nebula*-derived cores provided these instances, modifications, and distributions are made available under the OHL-S-2.0 with the original notices preserved.

Documentation, such as READMEs, Markdown files, LaTeX-compiled documents and source, are provided under the [Creative Commons Attribution-ShareAlike (CC BY-SA)](https://creativecommons.org/licenses/by-sa/4.0/) 4.0 license. Copies of these licenses are made available in the root directory of this repository.