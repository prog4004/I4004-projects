\ MYSIM
FLOAD SIM4
READROM MANEUVER.BBN
HEX
0 ROMIN C! 0 ROMIN 1+ C!
: S0 0 ROMIN 1+ C! ;
: K ( #X - )
   DUP $10 AND 4 / ROMIN 1+ DUP>R C!
   $F AND ROMIN C!
   r@ C@ 8 OR R> C! ;
: WS S0 11 TOBREAK ;
: WNS 44 TOBREAK ;
: WT 3E TOBREAK ;
: Z ( #X - )  \ EXECUTES ONE KEY CODE VAUE IN TABLE
   K
   BEGIN
     4004ENGINE
     PCPNTR @ 44 =
   UNTIL
   ROMOUT 4 + C@ IF ." Err" CR THEN
   WS ;
: DISP
  $10 0 DO
     I 1 =
     I 6 = OR
     I $0A = OR IF SPACE THEN
     I 5 =
     I 9 = OR
     I $0F = OR IF 2E EMIT THEN
    $0F RamSpace + I - c@ $F and
    DUP $0F =
    IF
      $50 + EMIT
    ELSE
      1 .r
    THEN
   LOOP ;

: RESET
 REGISTERS $10 ERASE
 RAMSPACE [ $10 $10 * 4 * 4 * LITERAL ] ERASE
 RAMSTATUS [ $10 4 * 4 * 4 * LITERAL ] ERASE
 ROMOUT 4 ERASE
 ROMIN 4 ERASE
;

: N ( NUMBER - )
   $10 SWAP BEGIN base @ /MOD DUP 0= UNTIL
   DROP
   BEGIN
     DUP 0 = IF $10 + THEN Z
     DUP $10 =
   UNTIL DROP ;

: CLR $0D Z ;
: SPD $15 Z ;
: TRG $1F Z ;
: TIM $1E Z ;
: 1ST $1D Z ;
: 2ND $1C Z ;
: CPA $1A Z ;
: BRG $17 Z ;
: RNG $16 Z ;
: CRS $13 Z ;
: OS $12 Z ;
: DPP $0B Z ;
: CMP $11 Z ;
: TS $18 Z ;
: SAV $14 Z ;

RESET
\  WS CLR SPD 10 N DPP CRS 0 N DPP OS
\  TRG 1 N BRG 12 N DPP TIM 1011 N RNG 1234 N DISP 1ST
\  TRG 1 N BRG 12 N DPP TIM 1020 N RNG 990 N DISP 2ND
\ TRG 1 N  \ CMP

hex
: t
  clr
  spd 15 n dpP 0 n crs 350 n dpP 0 n os
  trg 1 n tim 910 n dpP 0 n brg 12 n dpP 0 n rng 27600 n 1st
  trg 1 n tim 920 n dpP 0 n brg 0 n dpP 0 n rng 22000 n 2nd
  TRG 1 N ;

: .ram@ ( addr - )
    $F + ramspace +
    $10 0 do
      dup c@ 1 .r 1-
    loop drop space ;

CREATE SBuf $80 allot

: $>N ( $ - n ) \ HEX
   $30 - dup 9 >
   if $30 + $DF AND $37 - then ;

0 value addr

: ram! ( addr - | val ) \ INTERP ONLY
    to addr
    $20 WORD
    COUNT dup>r SBuf swap cmove
    r> 0
    do
      i
      SBuf + c@ $>N
      ramspace addr + $F i - + c!
    loop
   ;

: G ( A n - )
  K tobreak .T ;

: DVTST
\ C0 = 0000000642857142
\ D0 = 0000000006400000
  \        _______.________
  $20 RAM! 000004500000000
  $A0 RAM! 000007000000000
  $C0 RAM! 000000000000000
  $D0 RAM! 000000000000000
  $5CF PCPNTR !
  $5D9 TOBREAK ;

: H DUP 4 / RamStatus +
    4 0 DO
      DUP c@ $F AND 1 .R 1+
    LOOP DROP
    SPACE .RAM@ ;
: Y TOBREAK .T ;
