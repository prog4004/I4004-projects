\ BINHEX  reads in a binary file of 256 bytes and writes out a Intel Hex
\ It need to be expanded to do any size
\ used binhex name.bin name.hex

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
     $DF and $59 - if quit then
     OutFile count delete-file if ." Unable to delete file" quit then
     OutFile count r/w create-file
     if ." Can't create??" quit then
     to OutHandle
   then ;


create BinBuf $1000 allot  \ up to 4K
BinBuf value BinPntr
create LineBuf $40 allot \ to lazy to figure actual size
LineBuf value LinePntr
0 value CkSum

0 value DataSize
0 value DataDone
0 value LineSize

: ReadBin ( - | FileName )
  OpenInFile
  BinBuf $1000 InHandle read-file \ attempt to fill buffer
  if ." Read Error Bin file " quit then
  to DataSize ;

: nibl>char ( nibble - char )  \ convert a nibble to character
    $0F and dup $09 > if $37 +
              else $30 + then ;

: Line! ( Char - )
    LinePntr c! 1 +to LinePntr ;

: DoByte ( Byte - )
    dup +to CkSum
    $10 /mod
    nibl>char Line!
    nibl>char Line! ;

: GetByte ( - )
    BinPntr c@
    1 +to BinPntr
    DoByte ;

: DoLine ( - )
    LineBuf to LinePntr
    0 to CkSum
    ascii : Line!
    LineSize DoByte
    BinPntr BinBuf -
    $0FFFF and
    $100 /mod DoByte DoByte
    0 DoByte
    LineSize 0 do GetByte loop
    $100 CkSum $0FF and - DoByte
    $0D Line! $0A Line! ;

: LastLine ( - )
    LineBuf to LinePntr
    0 to CkSum
    ascii : Line!
    3 0 do 0 DoByte loop
    1 DoByte
    $100 CkSum $0FF and - DoByte
    $0D Line! $0A Line! ;

: WriteLine
    LineBuf LinePntr over - OutHandle write-file
    if ." write Error Tape File " quit then ;

: BinHex ( - | BinFile HexFile ) \ only does 256 byte bins now!
   ReadBin
   OpenOutFile
   BinBuf to BinPntr
   begin
    DataSize $10 -
    dup 0< if $10 + else drop $10 then
    DataSize over - to DataSize
    dup
   while
     to LineSize
     DoLine
     WriteLine
   repeat
   drop
   LastLine
   WriteLine
   CloseOut
   CloseIn ;


