\ onecopy.f
\ COPY 1702A TO 1702A
COMMENT:
This code runs in the first socket on the left, in
place of A0540.
If at any time All 4 Right RamPort LEDs should light,
it indicates a programming error. Turn off programming
power and remove EPROM.
There is only enough RAM in the SIM4-01 to copy 1/2 of
the 1702A EPROM at a time, making two sequences.
The program does a RAM test before beginning. If it
has a bad RAM it can't run as it needs all of the RAM
space. It does display the bad loaction.
The 4 right RAM 0 output LEDs indicate changing EPROMs for reading
and programming sequences. The other LEDs of the RAM out port
and ROM out port indicate operation.
RAM 1 Out port 1 indicates programming pulse
ROM 0 and 1 ports indicate EPROM address
ROM 2 and 3 ports indicate Data to EPROM during programming
RAM 2 and 3 ports indicate data from read errors
Note: Both Data in and Data out contrls should be in the
TRUE state for errased check, done between first master read
and first program. If error indication happen right away
during the first programming step, it indicates it failed
to see an erased EPROM.
Turning the program power on and off is a safety step. It is
not required to be off. Do note that only the first program
step checks for erased state. The Program power must be off
before turnning off +5V and -10V.
In some places the coding is a little hard to follow. This is
because the code was significantly optimized for space. More
than 20h was compressed, by optimizing code flow, from the
first written code.
The RamTst was written separate from the copy code so it has
it own set of constant names for ports and registers.

1. Reset Processor ( program power off for safety )
2. Fist Ram Port LED should light. If it doesn't there was
 a RAM failure. The address would be displayed.
3. Install Master EPROM
4. Press Test Switch
5. Second Ram Port LED should light
6. Remove Master EPROM insert Copy EPROM
7. Turn on Program voltage
8. Press Test Swtich
9. Wait just a little over 1 minute
10. Third Ram Port LED should light
     If all the LEDs light that indicates an error
     in programmings has occurred.
     Turn off program power and remove EPROM
11. If no error turn off program power and continue
12. Remove Copy EPROM and install Master EPROM to do second half
13. Press Test Switch
14. Fourth Ram Port LED should light
15. Remove Master EPROM and insert Copy EPROM
16. repeat steps 7 to 12
17. If no errors the First RamPort LED should be lit.
18. Remove Copy EPROM and repeat from step 2 to do another copy
19. Always turn off programming power before turning off
      the main power. Damage to the programming card can occur.

simplified steps:
Reset Switch
RAM0 0 lights:
 0 0 0 *  Read Master, first half w/ test switch
 0 0 * 0  Program, first half w/ test switch
 0 * 0 0  read Master, second half w/ test switch
 * 0 0 0  Program, second half w/ test switch
 0 0 0 *  Complete, ready for next Master

  * * * * Error, fail erase if program doesn't start
                 fail to program if at end of 1 minute program

                 For erase, likely failure: polarity of data
                 fail Prog, likely: no program voltage

COMMENT;



INCLUDE ASM4004.f
HEX

\ Some constants to help make readable code
00 CONSTANt RomPortAddr0 \ for A0-A3 out, tty input on bit 0
10 CONSTANT RomPortAddr1 \ for A4-A7 out, unused input
20 CONSTANT RomPortAddr2 \ for D1-D4 both read and write
30 CONSTANT RomPortAddr3 \ for D5-D8 both read and write
00 CONSTANT RamPortAddr0 \ Output for TTY bit 0 The rest just lights
40 CONSTANT RamPortAddr1 \ Bit 0 TTY control, Bit 1 Program 1702A
                         \ Bit 3 Program 1702 Non-A and lights
80 CONSTANT RamPortAddr2 \ LightsLo
C0 CONSTANT RamPortAddr3 \ LightsHi

RomPortAddr0 CONSTANT AddrPort
RomPortAddr2 CONSTANT DataPort

PAB CONSTANT PortROM  \ same for eprom addr write / data read
0A CONSTANT PortRomHi \ ROM addr
PCD CONSTANT AddrEprom \ used for eprom address
0C CONSTANT AddrEpromHi
0D CONSTANT AddrEpromLo
PEF CONSTANT AddrRam
0E CONSTANT AddrRamHi
0F CONSTANT AddrRamLo
P01 CONSTANT RamOuts
02 CONSTANT TempReg \ wont be using delays while using this register

08 CONSTANT ShiftLights

\ couple of macros
: SkipTo RHERE + ; \ used for addressing forward without LBs
: WaitHere RHERE ; \ Used for error stop and JUN


\ These are used by the ram test only
\ I patched the two programs together so used different
\ names
    0 CONSTANT DataPair
    1 CONSTANT Data

  P45 CONSTANT RomI/O
    4 CONSTANT RomI/OHi
\ end of RamTst constants

0 ORG
\ RamTst is run first if failure it halts and shows addr
\ This is a simple test to make sure all locations can
\ be written with ones and zeros. The patterns are chosen
\ to detect most addressing errors.
LB RamTst
   0 RomI/O FIM
   0 AddrRam FIM
   0 LDM
   0 DataPair FIM
LB WrFirst
   IAC
   AddrRam SRC
   WRM
   WrFirst AddrRamLo ISZ
   IAC  \ extra incrememnt every 16 bits to improve addr test
   WrFirst AddrRamHi ISZ
LB SecondPass
   AddrRam SRC
   RDM
   CMA  \ complement before writing back
   WRM
FLB NxtAddr JMS
   SecondPass ZERO JCN
LB LastPass
   AddrRam SRC
   RDM
   NxtAddr JMS
   LastPass ZERO JCN
\ if passes RAM test then continue to the
\ EPROM copy program

LB Main
\ TURN ON RAM0 BIT FIRST LIGHT
   1 LDM
   ShiftLights XCH
FLB WaitTest JMS \ RAM 0 light 0
   \ SET FIRST ADDRESSES
   0 AddrRam FIM \ Used to point to RAM storage
   0 AddrEprom FIM \ Used to Addr EPROM address
FLB HalfMaster JMS \ reads half
   0 LDM
   AddrEpromHi XCH  \ need to stay on first half
   WaitTest JMS \ RAM 0 light 1
FLB   Erased? JMS  \ Does complete EPROM so no need to Rewind
FLB   Prog JMS   \ programms half and does rewind
   0 LDM
   AddrEpromHi XCH  \ need to stay on first half
FLB   Check JMS   \ Doesn't rewind so ready for next half
   WaitTest JMS \ RAM 0 light 2
   \ no need to Rewind this time
  \ First half is programmed, on to the second half
   HalfMaster JMS \ reads second half
   8 LDM
   AddrEpromHi XCH  \ now switch to second half
   WaitTest JMS  \ RAM 0 light 3
   Erased? JMS  \ Starts on second half just in case
   8 LDM
   AddrEpromHi XCH  \ now stay on second half
   Prog JMS
   8 LDM
   AddrEpromHi XCH  \ now stay on second half
   Check JMS
   Main JUN


\ These two subroutines used by RAM test
LB Rtrn0
   00 BBL
FLP NxtAddr \ shared code by passes
   Data INC
   CMA
   CLC       \ so no borrow
   Data SUB  \ check for missmatch
FLB RamError ZERO INV JCN
   Rtrn0 AddrRamLo ISZ
   Data INC
   Rtrn0 AddrRamHi ISZ
   01 BBL \ returns done

FLP RamError \ show the bad RAM address
                 \ The 2 high bits indicate the RAM chip
   AddrRamLo LD
   RomI/O SRC
   WRR
   AddrRamHi LD
   RomI/OHi INC
   RomI/O SRC
   WRR
   WaitHere JUN  \ stops here if RAM error

\ From here on, used by the MAIN copy program
\ Delays use P23, P45, P67
\  These are not used by anyone else so OK
LB DLY.009
   0 P67 FIM
LB DLY0
   NOP
   DLY0 7 ISZ
   NOP
   NOP
   DLY0 6 ISZ
   00 BBL

LB DLY.517
   0  P23 FIM
   0B P45 FIM
LB DLY1
   DLY1 2 ISZ
   DLY1 3 ISZ
   DLY1 4 ISZ
   DLY.009 JMS
   DLY1 5 ISZ
FLB ProgReturn JUN \ not able to make this BBL because of stack


LB SetAddr \ used often so made a subroutine
   \ set address on ROM ports to EPROM
   \ RomPort is left pointing too Data In/Out to EPROM
   \ Data In/Out is current SRC
   RomPortAddr0 PortRom FIM
   PortRom SRC  \ address low
   AddrEpromLo LD
   WRR           \ address hi to eprom
   PortRomHi INC  \ to addr Hi same as RomPortAddr1 for address low
   PortRom SRC
   AddrEpromHi LD
   WRR          \ address low to eprom
   PortRomHi INC  \ Now points to EPROM data I/O low
   PortRom SRC \ not always needed but saves a little space
   00 BBL

FLP HalfMaster
   \ Reads half the data into RAM to be programmed
   \ Which half depends on the AddrEprom 0 is first 80 is second
   \ It then programs that half
   \ does a rewind to be ready for Prog
   SetAddr JMS  \ RomPort pointing to Data In/Out
   RDR  \ EPROM data in
   AddrRam SRC \ lo nibble
   WRM
   PortRomHi INC \ same as RomPortAddr2 for data low
   PortRom SRC
   RDR  \ EPROM data in
   AddrRamLo INC \ First incr always odd so can't carry
   AddrRam SRC
   WRM
\ Now increment both pointers
   3 SkipTo AddrEpromLo ISZ \ increment EPROM
   AddrEpromHi INC
   HalfMaster AddrRamLo ISZ  \ increment RAM
   HalfMaster AddrRamHi ISZ   \ if done $100 hex Half is done
   0 BBL           \ If here then doing the first program

FLP Prog \ AddrRam should be zero so no need to fix that
   \ when done it leave the EPROM address at rewound
   \ so check can compare same information.
   SetAddr JMS  \ sets the address to the EPROM
   AddrRam SRC
   RDM         \ get low nibble
   PortRom SRC
   WRR         \ to programmer in port low
   AddrRamlo INC \ always odd can't be a carry
   AddrRam SRC
   RDM         \ get high nibble
   PortRomHi INC \ next ROM I/O
   PortRom SRC
   WRR          \ to programmer in port high
   RamPortAddr1 RamOuts FIM \ program control port
   RamOuts SRC
   2 LDM        \ program on
   WMP
   DLY.517 JUN \ stack depth required JUN
FLP ProgReturn
   CLB          \ program off
   WMP
   DLY.009 JMS     \ to let multivibrator time out
   3 SkipTo AddrEpromLo ISZ
   AddrEpromHi INC
   Prog AddrRamLo ISZ  \ must be on the first or second half so keep going
   Prog AddrRamHi ISZ
   0 BBL           \ If here then doing the first program

FLP WaitTest   \ Look for the test switch toggle
   RamPortAddr0 RamOuts FIM \ RAM 0
   RamOuts SRC
   ShiftLights XCH
   WMP
   CLC
   RAL
   ShiftLights XCH
   WaitHere T0 JCN \ Wait for Test Switch
   WaitHere T0 INV JCN
   0 BBL

LB ErrorLight
   0F LDM  \ all on
   RamPortAddr0 RamOuts FIM \ RAM 0
   RamOuts SRC
   WMP
   WaitHere JUN  \ Wait until reset switch

FLP Erased?
   \ Uses RomPort
   \ Uses AddrEprom but leaves it at 0
   \ it is entered for second check at 1/2 way address. This is a
   \ reasonable safety it the Master is left in at the start
   \ of the Program step.
   \ It does expect the True/Comp controls should be in the True
   \ state or it will error.
   SetAddr JMS
   \ RomPort pointing to Data In/Out
   RDR  \ EPROM data in
   ErrorLight zero inv JCN
   PortRomHi INC
   PortRom SRC
   RDR  \ EPROM data in
   ErrorLight zero inv JCN
   Erased? AddrEpromLo ISZ \ Increment Eprom address counter low
   Erased? AddrEpromHi ISZ
   \ both skip to here
   0 BBL     \ If here then doing the first program   0 BBL

LB CK1 \ Trying to reduce code size to be able to do RAM test
   RamOuts SRC
   WMP   \ memory to display ram out
   TempReg XCH
   PortRom SRC
   RDR
   WRR    \ eprom value to display rom out
   CLC
   TempReg SUB
   ErrorLight zero inv JCN
   0 BBL

FLP Check
   \ starts with AddrEprom = 0 or 80H and AddrRam = 0
   \ ends with   AddrEprom = 80H or 0 and AddrRam = 0
   \ that is ready for the next half EPROM.
   \ RomPort = EPROM Data Hi I/O
   \ Uses TempReg, AddrRam, PortRom, AddrEprom, Acc
   SetAddr JMS
   AddrRam SRC
   RDM
   RamPortAddr2 RamOuts FIM
   CK1 JMS
   AddrRamLo INC  \ First incr always odd can't be a carry
   PortRomHi INC \ same now data EPROM hi
   AddrRam SRC
   RDM
   RamPortAddr3 RamOuts FIM
   CK1 JMS
   3 SkipTo AddrEpromLo ISZ \ only increments half as fast
   AddrEpromHi INC
   Check AddrRamLo ISZ  \ Only 128 bytes per pass
   Check AddrRamHi ISZ  \ that is 256 nibbles
   0 BBL



save-asm onecopy.bin



