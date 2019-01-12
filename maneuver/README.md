Manuever is a 4004 project. 
The code is from the NPS in Monterey, Ca. This code was originally written by a student of Garry Kildall. 
Do a search for:
  microcomputersol00kern.pdf  by Kenneth Harper Kerns
The listing was done on what looks to be a ASR33 teletype. It had poor registration on the print drum. 
In many cases, the letter C and number 0 were not destinguishable. This has the source that I've created. 
It has no known errors. It is at the point that it has a matching number of bytes on each 256 byte page, 
when assembled. It is written in my assembler. I am currently using the win32forth version of the assembler 
and may not work with the FPC version. Since it is from a listing and my assembler is a single pass, 
I have created a file that has all the used labels rather than creating the labels as I go. 
The assembler is loaded by the manuever.f source file. 
I've debugged all the known errors using the simulation with MYSIM.
MYSIM has all the attachments needed to enter data into the simulation as well as display results.
See mnuvr.txt for examples of using these instructions. See MYSIM to see how they are implemented.
maneuver button commands:
CLR  Clears display and allows renetry of data
SPD  Enter speed of own ship
TRG  Enter number to select target ship 0 to 9 for 10 ships
TIM  Enter time in 24 hour format  with otional decimal minute. example: TIM 1234 N DPP 5 N
1ST  Set previous parammeters as first target ship entry
2ND  Set previous parameters as second target ship entry
CPA  redisplay Closest Point of Aproach to display buffer
BRG  Enter relative bearing for selected target ship
RNG  Enter range in yards for selectd target ship
CRS  Enter absolute bearing of own ship
OS   Sets CRS and SPD data as own ship
DPP  use as though a decimal point ( not allowed with range ) only one number afer DPP
CMP  Once OS, 1ST and 2ND data input you can calculate data for CPA and TS
TS   Show absolute course and speed of target ship
SAV  Save 1ST or 2ND target ship entry as 1ST to add new 2ND data
N    reads a number off the stack and places it in the display buffer
DPP  used as the decimal point button
DISP displays the current display buffer

Other useful commands in the simulator.
 esc stop the simulator
 X executes a single instruction in the simulator
 Y ( Addr - ) executes simulator until the addr and breaks
 G ( Addr Cmd - ) starts the simulator with the keyboard command and breaks at the address. Look at listing for values of key
      board commands. I used mostly $11 that is the CMP command during debug.
 H ( RB - ) shows the status and data feilds of a RAM register loaction. Must be used on $10 boundaries to make sense as an 
            example:
            If wanted to see the RAM at location $40 just do $40 H. Data is shown MSNs ( Most significant nibbles ) first to
            be as one would noramlly look at numbers. The memory is organized LSN in the lowest memory address.
            Do note that nagative numbers are in 1's complement. When the number is negative the lest significant bit of
            the highest status bit should be set to 1 as well. 
 The binary instruction data is located in ROMCODE array.
 There is more useful stuff in the simulator. Look in MYSIM and SIM4 files for other things that on might need. I do not
 simulate the data written to the ROM I/O that would run an actual display. One has to use the DISP command to see what is
 currently in the display buffer, at any time. This makes more sence then constantly updating the screen with the constant
 noise of it display scan outputs.
Note that once you have entered any keyboard command, the emulation has been started. It will automatically run the command
until it does a display command that is part of the keyboard/display loop. This is because all the commands have a built in
break command at the keyboard input address. One can look at code in MYSIM to see how this is done. There are some notes
in the assembly source for addresses. It is possible to start the simulator at any address with PCPNTR! ( Addr - ) but
usually it is best to use 0 as the address unless you are analysing effects of some subroutine. The BREAK ( addr - ) commnd
only stops on instruction addresses and not in the middle of an address. One can always use the escape key to stop a runaway.
One can play with things like the CORDIC routine to make SIN ( $20 ) and COS ( $10 ) with values in the RAM register 
bank $00 set to the angle created. These are fixed point with 7 digits before the dp and 9 digits after. The angel 45.3 would
be 0000045300000000. There is also a TAN called CORDICAT.

Last bug was missed because I wasn't using the hardware port for the display I was getting it from the simulated RAM.
I had "00" and it should have been a "CC".

7 segment displays come in two basic types. The decimal point can be to the left of the digit or to the right. On a scanned
display one has to turn on the decimal point with the right digit so that it will be between the correct two digits.
The original source expected the decimal point to be to the left of the digit. I'd already bought ones with the decimal
point to the right.
There are comments in my source but if one doesn't have a compatable assembler, one can still patch the binary.
There are 4 locations to patch:
Addr, Left, Right
1D8, D2, D1
1E2, D2, D1
1EC, D2, D1
1F6, D8, D4
Dwight
