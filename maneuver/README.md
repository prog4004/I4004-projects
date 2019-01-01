Manuever is a 4004 project. 
The code is from the NPS in Monterey, Ca. This code was originally written by a student of Garry Kildall. 
Do a search for:
  microcomputerso100kern.pdf  by Kenneth Harper Kerns
The listing was done on what looks to be a ASR33 teletype. It had poor registration on the print drum. 
In many cases, the letter C and number 0 were not destinguishable. This has the source that I've created. 
It may still have a few errors. It is at the point that it has a matching number of bytes on each 256 byte page, 
when assembled. It is written in my assembler. I am currently using the win32forth version of the assembler 
and may not work with the FPC version. Since it is from a listing and my assembler is a single pass, 
I have created a file that has all the used labels rather than creating the labels as I go. 
This file is loaded by the manuever.f source file. 
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
 H ( RB - ) shows the status and data feilds of a RAM loaction. Must be used on $10 boundaries to make sense as an example if
            wanted to see the RAM at location $40 just do $40 H. Data is shown MSNs ( Most significant nibbles ) first to
            be as one would noramlly look at numbers. Do note that nagative numbers are in 1's complement.
 The binary instruction data is located in ROMCODE array.
 There is more useful stuff in the simulator. Look in MYSIM and SIM4 files for other things that on might need. I do not
 simulate the data written to the ROM I/O that would run an actual display. One has to use the DISP command to see what is
 currently in the display buffer, at any time. This makes more sence then constantly updating the screen with the constant
 noise of it display scan outputs.
