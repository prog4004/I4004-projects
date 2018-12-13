\ Assembler for Intel 4004 uP
\ D K Elvey
\ Dec 30 1998
\ Rev 1.04  ADDED R,


decimal

\ vocabulary ASM4004
\ ASM4004 definitions

\ ROM array has 4096 bytes
$10000 value RomSize  \ extra for macros
RomSize create ROM allot

ROM value >ROM    \ Pointer to ROM array

ROM RomSize erase  \ Clear ROM array

: RHere ( - Address )
    >ROM ROM - ;

: ROM@ ( Addr - Byte )
   ROM + c@ ;

: ROM! ( Byte Addr - )
    ROM + c! ;

: split ( addr - )
    dup $0FF and swap $100 /  $0FF and ;

0 value CurLB

: flpatch ( ForwardLabelsBody - )
   dup cell + @ -1 -        \ t l l
   abort" Attempt to patch other than forward label!"
   dup @ dup                          \ t l l'
   if ( labels linked )
     begin                          \ t l
       dup cell + @  \ First patch addr   t l  p
       dup ROM@ $E0 and $40 =       \ t l p i
       if \ JUN or JMS              \ t l p
         dup>r ROM@ $F0 and           \ t l i
         RHere split $0F and rot or   \ t l a1 a2+i
         r@ ROM!                      \ t l a1
         r> 1+ ROM!                   \ t l
       else \ JCN, ISZ              \ t l p
         RHere swap                   \ t l h p
         1+ ROM!                      \ t l
       then
       @ dup 0=                     \ t l'
     until                          \ t 0
   then drop
   cell + RHere swap ! ;   \ set label

: FLabelP ( - | LabelName ) \ Patch forward label
   [compile] '     \ get label
   >body flpatch ;

: FLP FLabelP ;

: LBL FLP ;

: FLabelDoes ( address - )
    dup cell + @ -1 -
    if ( must be resolved )
       cell + @
    else ( make another link to patch )
       here      \ place to put link
       over @ ,  \ place link
       swap !    \ store new link
       RHere ,   \ place patch address
       0
    then ;

: FLabel ( - | LabelName ) \ Create a forward label to be patched later
  create here to CurLB 0 , -1 ,
  does> ( - addr )
   FLabelDoes ;

: FLB ( - | LabelName ) \ create and mark here as first
                        \ forward label usage
  FLabel CurLB FLabelDoes ;

variable DefSeg   0 DefSeg !
DefSeg value CurSeg

: SEG ( Addr - | SegName )
   \ SegName      changes segment
     create ,
     does>
        RHere CurSeg !
        dup to CurSeg
        @ ROM + to >ROM ;

: ORG ( Address - )   \ Sets ROM address
    $0FFF and ROM + to >ROM ;

0 value MaxRom
: ROM, ( cValue - )   \ Stores value into ROM and incr pointer
    $0FF and
    >ROM c!
    1 +to >ROM
    >ROM ROM - DUP RomSize U> abort" ROM size exceeded! "
    MaxRom MAX to MaxRom ;

: R, ROM, ;

: LIST ( Addr - )
   begin
     cr
      8 0 do
       dup .
       dup ROM + c@ .
       1+ cr
      loop
      key $1B =    \ Break on ESC key
    until drop ;

\ Instruction types

: 1Op  create ,
 ( - )   does> @ ROM, ;

: RegOp create ,
  ( Reg - ) does> @ swap $0F and or ROM, ;

: RegPair create ,
   ( RegPair - ) does> @ swap $0E and or ROM, ;

: DataOp create ,
  ( Data - ) does> @ swap $0F and or ROM, ;

$00 1Op      NOP    $E0 1Op  WRM    $F0 1Op  CLB
$21 RegPair  SRC    $E1 1Op  WMP    $F1 1Op  CLC
$30 RegPair  FIN    $E2 1Op  WRR    $F2 1Op  IAC
$31 RegPair  JIN    $E4 1Op  WR0    $F3 1Op  CMC
$60 RegOp    INC    $E5 1Op  WR1    $F4 1Op  CMA
$80 RegOp    ADD    $E6 1Op  WR2    $F5 1Op  RAL
$90 RegOp    SUB    $E7 1Op  WR3    $F6 1Op  RAR
$A0 RegOp    LD     $E8 1Op  SBM    $F7 1Op  TCC
$B0 RegOp    XCH    $E9 1Op  RDM    $F8 1Op  DAC
$C0 DataOp   BBL    $EA 1Op  RDR    $F9 1Op  TCS
$D0 DataOp   LDM    $EB 1Op  ADM    $FA 1Op  STC
                    $EC 1Op  RD0    $FB 1Op  DAA
                    $ED 1Op  RD1    $FC 1Op  KBP
                    $EE 1Op  RD2    $FD 1Op  DCL
                    $EF 1Op  RD3
$E3 1Op WPM \ 4040 instruction

\ Single def instructions

0 value Cond
: JCN ( Addr - )
   Cond $0F and $10 or ROM, ROM,
   0 to Cond ;

: Condition create ,
            does> @ Cond or to Cond ;
   $01 Condition T0
   $02 Condition CARRY
   $04 Condition ZERO
   $08 Condition INV

: FIM ( Data RegPair - )
     $0E and $20 or ROM, ROM, ;

: JUN  ( Address - )
    split $0F and $40 or ROM, ROM, ;

: JMS ( Address - )
    split $0F and $50 or ROM, ROM, ;

: ISZ ( Address Reg - )
    $0F and $70 or ROM, ROM, ;

: LABEL ( - | name )
    RHere HEADER DOCON COMPILE, , ;

: LB LABEL ;

comment:
 structures
 : BEGIN ( - Address )
    RHere ;

 : IF ( - Address )
   ( Cond )
   Cond $08 xor to Cond
   0 JCN RHere ;

: Patch ( AddrPatch AddrHere - )
    2dup $0F00 and
         swap $0F00 and -
         abort" Conditional across page boundary!"
    swap 1-                   \ Back one
    $0FFF and ROM +     \ Wrap around
    dup c@
    [ forth ]
    if  [ ASM4004 ]  \ JUN type
      >ROM >r 1- to >ROM
      JUN
      r> to >ROM [ forth ]
    else \ JCN type
      c!
    then [ ASM4004 ] ;


: ELSE ( Address1 - Address2 )
   ( No Cond ) IF swap
   RHere Patch ;

: THEN ( Address - )
   RHere Patch ;

: WHILE ( Address1 - Address1 Address2 )
   ( Cond ) IF ;

: INRWHILE ( Addr1 Reg - Addr1 Addr2 )
   RHere 4 + swap ISZ
   -1 JUN RHere ;

: INRWHILEZ ( Addr1 Reg - Addr1 Addr2 )
   0 swap ISZ RHere ;

: REPEAT ( Address1 Address2 - )
   swap JUN
   RHere Patch ;

: UNTIL ( Address - )
   ( Cond ) IF swap Patch ;

: INRUNTIL ( Address Reg - )
   RHere 4 + swap ISZ
   JUN ;

: INRUNTILZ ( Address Reg - )
   ISZ ;

: AGAIN ( Address - )
   JUN ;

Comment;

\ Saving output data to binary file

: SmallFile ( - )  \ make rom size minimum
    MaxRom to RomSize ;

: InvertImage ( - )
    ROM
    RomSize 0 do
      dup c@ $0FF xor
      over c!
      1+
    loop drop ;

: GetFileName ( Addr - | filename )
   bl word swap over c@ 1+ 100 min cmove ;

create OutFile  200 allot  0 value OutHandle
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
     $5F and $59 - if quit then \ NOT Y OR y
     OutFile count delete-file if ." Unable to delete file" quit then
     OutFile count r/w create-file
     if ." Can't create??" quit then
     to OutHandle
   then ;

: SAVE-ASM ( - | FileName )  \ Writes Assembled data to file
   OpenOutFile
   MaxRom $100 /mod swap if 1+ then \ write in 256 byte chunks
   $100 * .S
   Rom swap OutHandle write-file ?dup
   if . ." write error" quit then
   CloseOut ;

\ Some useful macros to deal with index registers and ROM/RAM I/O.

: >PAIR ( a b - c ) \ combines two numbers for register pair
     $0F and swap $10 * or ;

  0 constant RP0/1
  2  constant RP2/3
  4  constant RP4/5
  6  constant RP6/7
  8  constant RP8/9
 $A  constant RP10/11
 $C  constant RP12/13
 $E  constant RP14/15

$00 constant RAM0
$40 constant RAM1
$80 constant RAM2
$C0 constant RAM4

$00 constant RR0
$10 constant RR1
$20 constant RR2
$30 constant RR3

$00 constant ROM0
$10 constant ROM1
$20 constant ROM2
$30 constant ROM3

$00 constant P01
$02 constant P23
$04 constant P45
$06 constant P67
$08 constant P89
$0A constant PAB
$0C constant PCD
$0E constant PEF

0 CONSTANT R0
1 CONSTANT R1
2 CONSTANT R2
3 CONSTANT R3
4 CONSTANT R4
5 CONSTANT R5
6 CONSTANT R6
7 CONSTANT R7
8 CONSTANT R8
9 CONSTANT R9
$A CONSTANT RA
$B CONSTANT RB
$C CONSTANT RC
$D CONSTANT RD
$E CONSTANT RE
$F CONSTANT RF

$1000 Seg MacSeg  \ place to put macros

: DefMac  \ define macro
   ;
