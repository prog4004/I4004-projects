\ SIM4 simuator for 4004 0n SIM4-01 and programmer board MP7-03
: Sim4 ;
decimal

: GetFileName ( Addr - | filename )
   bl word swap over c@ 1+ 100 min cmove ;

create InFile 200 allot  0 value InHandle
create OutFile  200 allot  0 value OutHandle

: OpenInFile ( - )
   InFile GetFileName
   InFile count r/o open-file
   if ." Open error input? " quit
   else to InHandle then ;

: CloseIn ( - )
   InHandle close-file drop ;

: CloseOut ( - )
   OutHandle close-file drop ;

: OpenOutFile ( - )
   OutFile GetFileName
   OutFile count r/w open-file
   if \ didn't open maybe we need to create it
     drop OutFile Count r/w create-file
     if ." Couldn't create file" quit
     then
     to outhandle
   else \ file exits
     to OutHandle CloseOut
     ." OverWrite?" key
     337 and 131 - if quit then
     OutFile count delete-file if ." Unable to delete file" quit then
     OutFile count r/w create-file
     if ." Can't create??" quit then
     to OutHandle
   then ;

\ ROM ports can be only In or Out depending on mask
\ when as output reading as input has single constant
\ value but SIM4 has values on all unused inputs of 1
create RomOut $10 4 * allot
RomOut $10 4 * erase
create RomIn $10 4 * allot
RomIn $10 4 * $0F fill
create RamOut $10 4 * allot
RamOut $10 4 * erase

\ the stack is only 3 deep and only accessable as a PC value
\ I have set it up as 4 values. On being the current PC.
\ PC is only 12 bits for address

create Stack 4 cells allot
stack 3 cells + value LastStack
Stack 4 cells erase
0 Stack !
stack value PcPntr  \ points to current PC.
: PC@ ( - PC ) PcPntr @ ;
: PC! ( NewPC - ) $0FFF and PcPntr ! ;
: PC++ PC@ 1+ PC! ;
: PushStack ( NewPC - )
     1 cells +to PcPntr
     PcPntr LastStack
     u> if Stack to PcPntr then
     PC! ;
: PopStack ( - )
     -1 cells +to PcPntr
     PcPntr stack
     u< if LastStack +to PcPntr then ;

0 value Acc \ bit 4 is carry after math. always update carry
0 value Carry

create registers 16 allot \ waste a nible to make easier to access
Registers 16 erase
: Reg@ ( r - n ) \ must be 0 to 15
   $0F and Registers + c@ $0F and ;
: Reg! ( n r - )
   $0F and Registers + c! ;
: RegPr@ ( rp - n ) \ rp must be from Instr
   $0E and Registers + dup c@ $0F and $10 *
   swap 1+ c@ $0F and + ;
: RegPr! ( n rp - ) \ Rp must be from Instr
   $0E and Registers + >r
   dup $F0 and $10 / r@ c!
   $0F and r> 1+ c! ;

0 value TestPin

0 value Cycles  \ used to keep track of time, each cycle is 10.8us
0 value EventCycle   \ and event to happen as some cycles
' noop value Event  \ What to do if EventCycle = Cycles

0 value BreakPoint  \ addr of next breakPoint

create RomCode $1000 allot \ only 12 bit address
\ no attempt to optimize space of nibbles to bytes these arrays are byte addressed
\ but only the low 4 bits are used on each byte
\ I will addr ess by bytes to make it simple
create RamSpace $10 $10 * 4 * 4 * dup
   allot \ only 16 ea 16 nibble rams
   RamSpace swap erase
create RamStatus $10 4 * 4 * 4 * dup
   allot \ only 16 rams with 4 status each
   RamStatus swap erase
0 value SrcVal

create InstrTable  $100 cells allot \ contains address of the instructions to execute
: ClearInstr
     $100 0 do
        ['] noop InstrTable I cells + !  \ valid instruction does nothing
            loop ;
ClearInstr

: (PC)
   PC@ RomCode + c@ ;

: IncPc
    PC++ 1 +to Cycles ;

0 value CurInstr

0 VALUE DONE

: 4004Engine \ Execute one instruction
    (PC) dup
    to CurInstr
    IncPc
    cells InstrTable + @ execute
    Cycles EventCycle - 0< If Event execute then
    PC@ BreakPoint = if -1 TO DONE then ;

\ 0 value LastPc

: ToBreak ( BreakPoint - )
    0 TO DONE
    $0FFF and to BreakPoint
    begin
 \     PC@ to LastPc
      4004Engine
 \     cycles $0FE and 0=
 \     LastPc PC@ - and
 \     if ." ." 4004Engine  then
      key? if
        key drop -1
      ELSE
        DONE 0 OR
      then
    UNTIL ;



RomCode value RomLoad

: Reset
  stack to PcPntr
  stack 4 cells erase
  Registers 16 erase
  0 to cycles
  0 to SrcVal
  RomOut $40 erase
  RomIn $40 $0F fill
  RamOut $40 erase
  RomCode to RomLoad
  0 to BreakPoint
;

: ReadRom ( - | FileName )
  OpenInFile
  InHandle file-size
  if ." file error?  "
  else
   drop ( size ) $1000 min \ only 4K max
   RomLoad RomCode - over + $1000 >
   if ." exceeds 4K "
   else
    RomLoad over InHandle read-file
    if ." Read Error Bin file " quit then
    drop CloseIn
    +to RomLoad
    RomLoad RomCode - h.
    ."  Rom Loaded" cr
   then
  then ;

\ ReadRom 540.bin
\ ReadRom 541.bin
\ ReadRom 543.bin

: .Instr \ displays the next instruction
   base @ >r hex
   PC@ 3 .r 2*
   (PC) 3 .r space
   (PC) cells InstrTable + @ .name cr
   (PC) $10 /
   dup 1 8 within
   over 3 <> and swap 6 <> and
   (PC) $71 and $21 <> and
   if ( 2 byte instruction )
     PC@ dup 1+ PC! (PC)
     DUP $10 / 5 .R $F AND 1 .r cr PC!
   then
   r> base ! ;

: .Stack base @ >r hex
   PCpntr
   4 0 do
     dup ?
     1 cells -
     dup Stack u<
     if drop LastStack then
   loop drop cr r> base ! ;

: .Acc
   base @ >r ." Acc " Acc 1 .r SPACE CARRY 1 AND . cr
   r> base ! ;
: .reg
   base @ >r
   ." Regs " 16 0 do i registers + c@ 2 .r
   i 1 and if space then loop cr
   r> base ! ;
: .t cr .Acc .Reg .stack .Instr
    srcval 2 .r ;

: x 4004engine .t ;

: .Ram
   base @ hex
   0
   $10 0 do
     $10 0 do
       i $F and 0= if cr then
       4 0 do
         DUP
         RamSpace + c@ $F and 1 .r
         1+
       loop space
       j $10 * i + RamStatus + c@ $F and 1 .r space
     loop
   loop DROP base ! ;

: .RomIn
    cr ." RomIn "  4 0 do i RomIn + c@ . loop ;
: RomIn! ( value Port - )
    $3 and RomIn + c! ;

: .RomOut
    cr ." RomOut" $10 0 do i RomOut + c@ . loop ;

: .RamOut
    cr ." RamOut" $10 0 do i RamOut + c@ . loop ;

: .I/O  .RomIn .RomOut .RamOut ;

0 value Cond  \ Condition for jump

0 value prln
0 value prpg
0 VALUE LSTJP
0 value FLG

: jumps
    PC@ LSTJP =
    OVER FLG = AND
    pc@ $48A $4DD WITHIN           \
    OR 0= \
    IF
      PC@ OVER              \
      if
        ."  J"
      else
        ."  C"
      then
      OVER TO FLG          \ FLG PC@
      DUP TO LSTJP  \ FLG PC@
      4 .r          \ FLG
      1 +to prln     \ FLG
      prln $10 =       \ FLG PRLN?
      if 0 to prln CR  \ FLG
        1 +to prpg
        prpg $20 =
        if 0 to prpg
           CR
           key ascii A = IF QUIT THEN
        then          \ FLG
      then
    THEN ;

: JumpOn ( flag - 'Cond )
\ jumps
  if
    PC@ $0F00 and (PC) or PC!
    1 +to cycles
  else
    IncPc
  then ;

: RRR>InstrTable ( Instr Mask - )
   8 0 do
     over over i 2* + cells InstrTable + !
   loop 2drop ;

: RRRR>InstrTable ( Instr Mask - )
   16 0 do
      over over I + cells InstrTable + !
   loop 2drop ;

: JCN
     CurInstr $0F and to Cond
     TestPin 0= 1 and
     Carry 1 AND 0= 0= 2 and or
     Acc 0= 4 and or
     Cond 8 and if Cond 7 and xor then
     Cond and
     Cond 8 = if drop -1 then JumpOn ;

' JCN $10 RRRR>InstrTable \ same format as RRRR

: FIM
    (PC) CurInstr $E and RegPr!
    IncPC ;

' FIM $20 RRR>InstrTable

: FIN
   PC@ $0F00 and
   0 RegPr@ or RomCode + c@ CurInstr RegPr!
   1 +to Cycles ;

' FIN $30 RRR>InstrTable

: JIN
   CurInstr RegPr@
   PC@ $0F00 and or PC! ;

' JIN $31 RRR>InstrTable

: JUN
   CurInstr $0F and $100 *
   (PC) $0FF and or
   IncPc PC! ;

' JUN $40 RRRR>InstrTable

: JMS
   CurInstr $0f and $100 *
   (PC) $0FF and or
   IncPc PushStack ;

' JMS $50 RRRR>InstrTable

: INC
   CurInstr dup
   Reg@ 1+ $0F and
   swap Reg! ;

' INC $60 RRRR>InstrTable

: ISZ
   INC
   CurInstr Reg@
   JumpOn ;

' ISZ $70 RRRR>InstrTable

: ADD
   CurInstr Reg@ Carry 1 and + Acc +
   dup $10 and 0= 1+ to Carry \ assume true is -1
   $0F and to Acc ;

' ADD $80 RRRR>InstrTable

: SUB
   CurInstr Reg@ $0F xor Carry 1 and
   1 xor
   + Acc +
   dup $10 and 0= 1+ to Carry \ assume true is -1
   $0F and to Acc ;

' SUB $90 RRRR>InstrTable

: LD
   CurInstr Reg@ to Acc ;

' LD $A0 RRRR>InstrTable

: XCH
   CurInstr Reg@ Acc
   CurInstr Reg! to Acc ;

' XCH $B0 RRRR>InstrTable

: LDM
   CurInstr $0F and to Acc ;

' LDM $D0 RRRR>InstrTable

: BBL
   LDM
   PopStack ;

' BBL $C0 RRRR>InstrTable

: CLB
   0 to Acc 0 to Carry ;

' CLB $F0 cells InstrTable + !

: CLC
   0 to Carry ;

' CLC $F1 cells InstrTable + !

: IAC
  Acc 1+ dup $0F and to Acc
  $10 and 0= 1+ to Carry ;

' IAC $F2 cells InstrTable + !

: CMC
   Carry 1 xor to Carry ;

' CMC $F3 cells InstrTable + !

: CMA
   Acc $0F xor to Acc ;

' CMA $F4 cells InstrTable + !

: RAL
   Carry 1 AND Acc 2* +
   dup $0F and to Acc
   $10 and 0= 1+ to Carry ;

' RAL $F5 Cells InstrTable + !

: RAR
   Acc dup Carry 1 AND if $10 or then
   2/ to Acc 1 and to Carry ;

' RAR $F6 cells InstrTable + !

: TCC
   Carry 1 AND to Acc 0 to Carry ;

' TCC $F7 cells InstrTable + !

: DAC
   ACC $0F + dup $10 AND 0= 1+ to Carry
   $0F and to Acc ;

' DAC $F8 cells InstrTable + !

: TCS
   1001 Carry 1 AND + to Acc 0 to Carry ;

' TCS $F9 cells InstrTable + !

: STC
   1 to Carry ;

' STC $FA cells InstrTable + !

: DAA
   Acc 9 >
   Carry 1 and or
   if
    Acc 6 + dup
    $0f and to Acc
    $10 / Carry or to Carry
   then ;

' DAA $FB cells InstrTable + !

: KBP
   Acc 2 >
   if Acc 4 =
     if 3
     else Acc 8 =
       if 4
       else $F then
     then to Acc
   then ;

' KBP $FC cells InstrTable + !

0 value DCLval

: DCL Acc 7 and
   to DCLval
   DCLval 3 = if 4 to DCLval
   else DCLval 4 = if 3 to DCLval then then
   DCLval $100 * to DCLval ; \ not used on SIM4 now

' DCL $FD cells InstrTable + !

: SRC
   CurInstr $E and RegPr@ to SrcVal ;

' SRC $21 RRR>InstrTable

: WRM
   Acc SrcVal DCLval + RamSpace + c! ;

' WRM $E0 cells InstrTable + !

: WMP
   Acc SrcVal DCLval + $40 / RamOut + c! ;

' WMP $E1 cells InstrTable + !

: WRR
  Acc SrcVal $10 / RomOut + c! ;

' WRR $E2 cells InstrTable + !

: WPM ;  \ not on SIM4

' WPM $E3 cells InstrTable + !

: WR0
    Acc $F and SrcVal DCLval +
    $10 / 4 * RamStatus + c! ;

' WR0 $E4 cells InstrTable + !

: WR1
    Acc $F and SrcVal DCLval +
    $10 / 4 * 1+ RamStatus + c! ;

' WR1 $E5 cells InstrTable + !

: WR2
    Acc $F and SrcVal DCLval +
    $10 / 4 * 2 + RamStatus + c! ;

' WR2 $E6 cells InstrTable + !

: WR3
    Acc $F and SrcVal DCLval +
    $10 / 4 * 3 + RamStatus + c! ;

' WR3 $E7 cells InstrTable + !

: SBM
   Acc SrcVal RamSpace + DCLval + c@
   $0F xor + Carry 1 AND 1 xor +
   dup $10 and 0= 1+ to Carry
   $0F and to Acc ;

' SBM $E8 cells InstrTable + !

: RDM
   SrcVal DCLval + RamSpace + c@
   to Acc ;

' RDM $E9 cells InstrTable + !

: ADM
   Acc SrcVal DCLval + RamSpace + c@
   + Carry 1 AND +
   dup $10 and 0= 1+ to Carry
   $0F and to Acc ;

' ADM $EB cells InstrTable + !

: RDR
  SrcVal $10 / RomIn + c@
  to Acc ;

' RDR $EA cells InstrTable + !

: RD0
    SrcVal DCLval + $10 / 4 * RamStatus + c@
    to Acc ;

' RD0 $Ec cells InstrTable + !

: RD1
    SrcVal DCLval + $10 / 4 * 1 + RamStatus + c@
    to Acc ;

' RD1 $ED cells InstrTable + !

: RD2
    SrcVal DCLval + $10 / 4 * 2 + RamStatus + c@
    to Acc ;

' RD2 $EE cells InstrTable + !

: RD3
    SrcVal DCLval + $10 / 4 * 3 + RamStatus + c@
    to Acc ;

' RD3 $EF cells InstrTable + !


HEX














