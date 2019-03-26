\ HexBin   Used:
\   HexBin InFile.HEX Outfile.BIN
\ If two lines have the same or overlapping address, it will overwrite
\ the with the last values.
\ Check Sum errors reported but not halted

: GetFileName ( Addr - | filename )
   bl word swap over c@ 1+ 100 min cmove ;

create InFile $100 allot  0 value InHandle
create OutFile  $100 allot  0 value OutHandle

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
     OutFile Count r/w create-file
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

create InBuf $100 allot
$4000 constant OutBufSize
create OutBuf OutBufSize allot
OutBuf OutBufSize erase


0 value Pntr
0 value Amount
0 value LineStart
0 value OutCount

: FirstRead ( Need to open the file and set some pointers )
   0 to pntr
   OpenInFile
   InBuf $100 InHandle read-file
   if ." error read" then
   to Amount
   0 to LineStart 0 to Pntr ;

0 value MaxEnd

: ReadDone
     CloseIn
     OpenOutFile
     OutBuf MaxEnd OutHandle write-file drop
     CloseOut
     ."  Wrote Binary"
     ( should clean stack here )
     quit ;

: ReadNext ( reads next 256 bytes or less to buffer )
   InBuf $100 InHandle read-file
   if ." error read" then
   to Amount
   0 to Pntr
   Amount 0=
   if ( ran out of datat ) ReadDone then ;

: GetByte ( - c )
   Amount Pntr > 0= \ in buffer
   if   \ needs more
     ReadNext
   then
     Pntr InBuf + c@
     1 +to Pntr ;

: HexNumb ( - n )
   GetByte
   ascii 0 2dup < if abort then
   - dup 9 >
   if
     dup $16 > if ." Not Hex" abort then
     7 - dup 0 < if ." NotHex" abort then
   then ;

0 value ChkSum

: GetNumb ( - n )
   HexNumb $10 * HexNumb +
   dup +to ChkSum ;

0 value #bytes
0 value Addr

: ReadLines
  begin
   begin
    GetByte ASCII : =
   until
   0 to ChkSum
   GetNumb to #Bytes
   GetNumb $100 * GetNumb + OutBufSize #Bytes - Min
   to Addr
   GetNumb ( DUP . ) if ( only type 0 data ) ReadDone then
   Addr to OutCount
   #Bytes 0 do
    GetNumb OutCount OutBuf + c!
    1 +to OutCount
   loop
   OutCount MaxEnd max to MaxEnd
   ChkSum GetNumb + $0FF and
   if ." @ " Addr h.  ." Error CheckSum " ChkSum $0FF and h. cr then
  again ;

: HexBin  ( - | hexFile BinFile )
  0 to Pntr
  0 to Amount
  0 to LineStart
  0 to OutCount
  0 to ChkSum
  0 to #bytes
  0 to Addr
  cr
  FirstRead
  ReadLines ;



