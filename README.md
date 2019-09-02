MMX - Miner Manager with Exstension
==================

Miner Manager is a stratum task generator firmware that fit FPGA and ASIC miners.

Main objectives
=============
* It is using stratum protocol
* It generate the tasks (block headers) inside FPGA. all Double-SHA256 was done by FPGA, far more faster than CPU.
* Test the nonce inside the FPGA. only report the >= DIFF tasks back to the host (CGMiner)
* It fits any kinds of stratum mining ASIC, (you may needs some VerilogHDL coding)
* It has a LM32 CPU inside, fit in XC6SLX16 small FPGAs
* The MM datasheet: http://downloads.canaan-creative.com/software/mm/MM_SOC_Specification.pdf

Directory structure
===================

* `firmware`: C codes running in LatticeMico32 soft processor
* `ipcores_dir`: IP cores
* `synth`: Directory for synthesize and build of the hardware part
* `verilog`: The VerilogHDL source code

How to build?
=============

First you need install the ISE for sure. then edit the `isedir` under xilinx.mk
by default we are using /home/Xilinx/14.6/ISE_DS/

For build the toolchain for lm32-rtems, it meets some problems with gcc-5.2.1 under Ubuntu and
gcc-4.9.2 under Debian, for fix that, just switch to gcc-4.8 with CC=gcc=4.8 make ... and you
also need texinfo_4.13a for fix the gdb build.

1. $ make -C firmware/toolchain # Install the lm32-rtems-4.11- toolchain under /opt
2. $ make -C firmware           # Generate the final bitstream file .bit/.mcs under firmware/
3. $ make -C firmware load      # Load the config bit file to FPAG by using Xilix Platform cable

Discussion
==========
* Telegram: https://t.me/EHashPublic

Support
=======
* TBD.

License
=======

This is free and unencumbered public domain software. For more information,
see http://unlicense.org/ or the accompanying UNLICENSE file.

Files under verilog/superkdf9/ have their own license (Lattice Semi-
conductor Corporation Open Source License Agreement).

Some files may have their own license disclaim by the author.
