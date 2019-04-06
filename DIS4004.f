\ Disassembler for Intel 4004 uP
\ D K Elvey
\ Dec 31 1998
\ rev 1.01
\ March 9 2018
\ Modified to run in win32forth
\ also added optional file out and screen out at the same time
\ rev 2.01

decimal

$1000 value RomSize \ 4K
create ROM RomSize allot
0 value RomEnd

0 value StartAddress

: GetFileName ( Addr - | filename )
   bl word swap over c@ 1+ 100 min cmove ;

create InFile$ 200 allot  0 value InHandle
create OutFile$  200 allot  0 value OutHandle

: OpenInFile ( - )
   InFile$ GetFileName
   InFile$ count r/o open-file
   if ." Open error input? " quit
   else to InHandle then ;

: CloseIn ( - )
   InHandle close-file drop ;

 -1 value >Screen  \ send text to screen
  0 value >File     \ send text to file must be open first

: CloseOut ( - )
   OutHandle close-file drop
   0 to OutHandle 0 to >File ;

: OpenOutFile ( - ) \ Assumes name is InputFile.lst
   OutFile$ count r/w open-file
   if \ didn't open maybe we need to create it
     drop OutFile$ Count r/w create-file
     if ." Couldn't create file" quit
     then
     to outhandle
     -1 to >file
   else \ file exits
     to OutHandle CloseOut
     ." OverWrite?" key
     $DF and $59 - if quit then
     OutFile$ count delete-file if ." Unable to delete file" quit then
     OutFile$ count r/w create-file
     if ." Can't create??" quit then
     to OutHandle
     -1 to >File
   then ;

: ReadRom ( - | FileName ) \ file is a binary image file
   OpenInFile
   StartAddress $0FF0 u>
   if
     ." start can't be more than $1FF0 " 0
   else
     ROM StartAddress + \ loading at some offset don't let too much
     $1000 StartAddress - InHandle read-file
   then
   CloseIn
   abort" Nothing Read from File!"
   StartAddress +
   RomEnd max
   to RomEnd \ Size we have in memory
   InFile$ dup c@ OutFile$ swap 1+ cmove
   OutFile$ count
   begin
     over c@ ascii . =
     over 0= or 0=
   while
     1- swap 1+ swap ( dec_count inc_address )
   repeat
   drop dup
   OutFile$ 1+ - 4 + OutFile$ c!
   >r s" .lst" r> swap cmove ;

: ReadRomTo ( StartAddr - | FileName )
   to StartAddress ReadRom ;

: OutputText ( address count - )
  >Screen IF
           2dup type
          THEN
  >file IF
         OutHandle IF \ opened a file?
                    2DUP OutHandle write-file
                    IF ." File right failed? " quit THEN
                   THEN
        THEN 2DROP ;

: OT ( a c - ) \ short hand for OutputText
 OutputText ;

create TopLabel 0 , 0 , 0 , -1 , \ link, addr, cnt , lastLabel#

: CheckLabel?  ( Addr - f/# ) \ label#
   TopLabel @
   begin
     dup    \ addr .link
     if \ valid label value
       2dup cell+ @ =  \ addr .link addr=
       if \ addr match
         swap drop       \ .link
         2 swap +cells  \ .cnt
         dup @ 1+       \  .cnt cnt+1
         over ! \ update count  .cnt
         cell+ @ -1  \
       else \ no match go to next link
         @ 0 \ fetch next link
       then
     else \ end of links
       2drop -1 -1
     then
   until ;

: NewLabel ( Addr - L# )
   here
   TopLabel @ ,  \ new link
   TopLabel ! \ patch top link
   , \ labels address
   1 , \ this label's count
   3 TopLabel +cells dup >r @ \ old label #
   1 + dup , \ new label's number
   dup r> ! ; \ update last label's number

: .Addr ( Addr - )
   0 <# bl hold # # # # #> OT ;

: .Byte ( Byte - )
   0 <# bl hold # # #> OT ;

: PrintLabel ( # - )
   S" L" OT
    0 <# # # # #> OT ;

CREATE Return $0D C, $0A C,

: .OT ( n - )
   0 TUCK DABS <# BL HOLD #S ROT SIGN #> OT ;

: OutCr
   >Screen IF CR THEN
   >File IF
           >Screen >R 0 to >Screen
           Return 2 OT
           R> TO >Screen
         THEN ;

CREATE SomeSpace $100 ALLOT
SomeSpace $100 BL FILL

: OutSpaces ( cnt - )
   SomeSpace SWAP OT ;
: OS ( cnt - ) OutSpaces ;

\ 4 newlabel
\ 5 newlabel
\ 6 newlabel

-1 value PrtAddr?

0 value LabelVal

: .Addr? ( Addr - )
    dup to LabelVal
    dup CheckLabel? dup -1 =
    if
     drop
     dup newlabel
    then
    printlabel 1 OS
    drop ;

: ROM@ ( Addr - Byte )
   ROM + c@ ;

: .A ( Addr - Addr )
   PrtAddr?
   if
     dup .Addr dup ROM@ .Byte
   then 2 OS ;

: PrintLabels
   TopLabel @  \ first link
   begin
    dup
   while
     dup >r
     cell+ @ .Addr 2 OS
     S" Label " OT
     4 OS 3 r@ +cells @ PrintLabel
     2 r@ +cells @
     2 OS S" \  " OT
     .Addr OutCr
     r> @
    repeat drop ;

: .Reg ( Addr Msk - Addr )
    over ROM@ and
   S" R" OT .OT ;

: nop ( addr - addr+1 )
   .A S" NOP" OT OutCr 1+ ;

: jcn ( addr - addr+2 )
    dup ROM@ $0F and
    if
     .A OutCr 1+ .A
     dup ROM@ over 1+ $ff00 and or .Addr?
     dup 1- ROM@
     dup 1 and if S" T0 " OT then
     dup 2 and if S" CARRY " OT then
     dup 4 and if S" ZERO " OT then
     8 and if S" INV " OT then
     S" JCN \ " OT
     LabelVal .Addr
    else
     .A S" SKIP" OT
    then
    OutCR 1+ ;

: fim ( Addr - Addr+2 )
   .A Outcr 1+ .A
    dup ROM@ .Byte
    dup 1- $0E .Reg drop
    S" FIM " OT Outcr 1+ ;

: src ( Addr - Addr+1 )
    .A $0E .Reg
    S" SRC" OT Outcr 1+ ;

: fin ( Addr - Addr+1 )
    .A $0E .Reg
    S" FIN " OT Outcr 1+ ;

: jin ( Addr- Addr+1 )
    .A  $0E .Reg
    S" JIN" OT Outcr 1+ ;

: jun ( Addr - Addr+2 )
    .A Outcr 1+ .A
    dup 1- ROM@ $0F and $100 *
    over ROM@ or .Addr?
    S" JUN \ " OT LabelVal .Addr Outcr 1+ ;

: jms ( Addr - Addr+2 )
   .A Outcr 1+ .A
    dup 1- ROM@ $0F and $100 *
    over ROM@ or .Addr?
    S" JMS \ " OT LabelVal .Addr Outcr 1+ ;

: inc ( Addr - Addr+1 )
    .A $0F .Reg S" INC" OT Outcr 1+ ;

: isz ( Addr - Addr+2 )
    .A Outcr 1+ .A
    dup ROM@ over 1+ $FF00 and or .Addr?
    dup 1- $0F .Reg drop
    S" ISZ \ " OT LabelVal .Addr Outcr 1+ ;

: add ( addr - Addr+1 )
   .A $0F .Reg
   S" ADD" OT Outcr 1+ ;

: sub ( Addr - Addr+1 )
   .A $0F .Reg
   S" SUB" OT Outcr 1+ ;

: ld ( Addr - Addr+1 )
   .A $0F .Reg
   S" LD" OT Outcr 1+ ;

: xch ( Addr - Addr+1 )
   .A $0F .Reg
   S" XCH" OT Outcr 1+ ;

: bbl ( Addr - Addr+1 )
   .A dup ROM@ $0F and .Byte
   S" BBL" OT Outcr 1+ ;

: ldm ( Addr - Addr+1 )
   .A dup ROM@ $0F and .Byte
   S" LDM" OT Outcr 1+ ;

: wrm ( Addr - Addr+1 )
    .A S" WRM" OT Outcr 1+ ;

: wmp ( Addr - Addr+1 )
    .A S" WMP" OT Outcr 1+ ;

: wrr ( Addr - Addr+1 )
    .A S" WRR" OT Outcr 1+ ;

: wr0 ( Addr - Addr+1 )
    .A S" WR0" OT Outcr 1+ ;

: wr1 ( Addr - Addr+1 )
    .A S" WR1" OT Outcr 1+ ;

: wr2 ( Addr - Addr+1 )
    .A S" WR2" OT Outcr 1+ ;

: wr3 ( Addr - Addr+1 )
    .A S" WR3" OT Outcr 1+ ;

: sbm ( Addr - Addr+1 )
    .A S" SBM" OT Outcr 1+ ;

: rdm ( Addr - Addr+1 )
    .A S" RDM" OT Outcr 1+ ;

: rdr ( Addr - Addr+1 )
    .A S" RDR" OT Outcr 1+ ;

: adm ( Addr - Addr+1 )
    .A S" ADM" OT Outcr 1+ ;

: rd0 ( Addr - Addr+1 )
    .A S" RD0" OT Outcr 1+ ;

: rd1 ( Addr - Addr+1 )
    .A S" RD1" OT Outcr 1+ ;

: rd2 ( Addr - Addr+1 )
    .A S" RD2" OT Outcr 1+ ;

: rd3 ( Addr - Addr+1 )
    .A S" RD3" OT Outcr 1+ ;

: clb ( Addr - Addr+1 )
    .A S" CLB" OT Outcr 1+ ;

: clc ( Addr - Addr+1 )
    .A S" CLC" OT Outcr 1+ ;

: iac ( Addr - Addr+1 )
    .A S" IAC" OT Outcr 1+ ;

: cmc ( Addr - Addr+1 )
    .A S" CMC" OT Outcr 1+ ;

: cma ( Addr - Addr+1 )
    .A S" CMA" OT Outcr 1+ ;

: ral ( Addr - Addr+1 )
    .A S" RAL" OT Outcr 1+ ;

: rar ( Addr - Addr+1 )
    .A S" RAR" OT Outcr 1+ ;

: tcc ( Addr - Addr+1 )
    .A S" TCC" OT Outcr 1+ ;

: dac ( Addr - Addr+1 )
    .A S" DAC" OT Outcr 1+ ;

: tcs ( Addr - Addr+1 )
    .A S" TCS" OT Outcr 1+ ;

: stc ( Addr - Addr+1 )
    .A S" STC" OT Outcr 1+ ;

: daa ( Addr - Addr+1 )
    .A S" DAA" OT Outcr 1+ ;

: kbp ( Addr - Addr+1 )
    .A S" KBP" OT Outcr 1+ ;

: dcl ( Addr - Addr+1 )
    .A S" DCL" OT Outcr 1+ ;

: ill ( Addr - Addr+1 )
    .A S" Illegal" OT Outcr 1+ ;


: DisOne ( Addr - Addr' )
   dup ROM@
   exec:
    nop ill ill ill ill ill ill ill
    ill ill ill ill ill ill ill ill
    jcn jcn jcn jcn jcn jcn jcn jcn
    jcn jcn jcn jcn jcn jcn jcn jcn
    fim src fim src fim src fim src
    fim src fim src fim src fim src
    fin jin fin jin fin jin fin jin
    fin jin fin jin fin jin fin jin
    jun jun jun jun jun jun jun jun
    jun jun jun jun jun jun jun jun
    jms jms jms jms jms jms jms jms
    jms jms jms jms jms jms jms jms
    inc inc inc inc inc inc inc inc
    inc inc inc inc inc inc inc inc
    isz isz isz isz isz isz isz isz
    isz isz isz isz isz isz isz isz
    add add add add add add add add
    add add add add add add add add
    sub sub sub sub sub sub sub sub
    sub sub sub sub sub sub sub sub
    ld  ld  ld  ld  ld  ld  ld  ld
    ld  ld  ld  ld  ld  ld  ld  ld
    xch xch xch xch xch xch xch xch
    xch xch xch xch xch xch xch xch
    bbl bbl bbl bbl bbl bbl bbl bbl
    bbl bbl bbl bbl bbl bbl bbl bbl
    ldm ldm ldm ldm ldm ldm ldm ldm
    ldm ldm ldm ldm ldm ldm ldm ldm
    wrm wmp wrr ill wr0 wr1 wr2 wr3
    sbm rdm rdr adm rd0 rd1 rd2 rd3
    clb clc iac cmc cma ral rar tcc
    dac tcs stc daa kbp dcl ill ill ;

0 value PrintFile

: DisBuffer
    hex
    PrintFile
    if
     OpenOutFile  .s key drop
    then
    0
    begin
\      .s cr key drop
      DisOne
      dup RomEnd =
    until drop
    OutCr
    PrintLabels
    CloseOut cr ;


: DisFile
    hex
    ReadRom
    DisBuffer ;

: x disone ;

: xx cr 10 0 do x loop ;
hex

