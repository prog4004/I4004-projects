\ MYSIM for manuever board inclused keyboard entry and
\ maneuver board display
\ Also several simulation debug words that are useful
FLOAD SIM4
READROM MANEUVER.BBN \ get binary image
HEX  \ entry is in BCD for board address in HEX
0 ROMIN C! 0 ROMIN 1+ C!
: S0 0 ROMIN 1+ C! ;
: K ( K# - ) \ K# is keyboard table number
   DUP $10 AND 4 / ROMIN 1+ DUP>R C!
   $F AND ROMIN C!
   r@ C@ 8 OR R> C! ;
: WS S0 11 TOBREAK ; \ run sim until waiting for key input
: WNS 44 TOBREAK ;
: WT 3E TOBREAK ;
: Z ( K# - )  \ EXECUTES ONE KEY CODE VAlUE IN TABLE
    \ breaks when waiting for next key
   K
   BEGIN
     4004ENGINE
     PCPNTR @ 44 = \ look for error light
   UNTIL
   ROMOUT 4 + C@ IF ." Err" CR THEN
   WS ;

: DISP \ mod to correct decimal point display
  $10 0 DO
     I 1 =
     I 6 = OR
     I $0A = OR IF SPACE THEN \ separates the fields 
   \ removed older incorrect decimal point print
   \ status nibble has decimal point location
    $0F I - 4 /mod RamStatus + c@ \ get status nibble
    swap 0 ?do 2* loop $8 and \ remainder has bit position
    if ." ." then \ DP is infront of digit
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
;

: N ( NUMBER - ) \ input number as from keyboard
                 \ must be in hex for BCD
   $10 SWAP BEGIN $10 /MOD DUP 0= UNTIL
   DROP
   BEGIN
     DUP 0 = IF $10 + THEN Z
     DUP $10 =
   UNTIL DROP ;

\ keyboard keys
: CLR $0D Z ; \ clear entry
: SPD $15 Z ; \ OS speed
: TRG $1F Z ; \ target ship number
: TIM $1E Z ; \ time 2400 hour
: 1ST $1D Z ; \ first observe
: 2ND $1C Z ; \ second observe
: CPA $1A Z ; \ display CPA
: BRG $17 Z ; \ Relitive bearing of target
: RNG $16 Z ; \ range of target
: CRS $13 Z ; \ true bearing of OS
: OS $12 Z ;  \ Own Ship
: DP $0B Z ;  \ Decimal point
: CMP $11 Z ; \ Do calculation for target
: TS $18 Z ;  \ Display targets true bearing and speed
: SAV $14 Z ; \ save and reuse one observe


\ test that all works using key inputs
WS CLR SPD 15 N DP 0 N CRS 0350 N DP 0 N DISP CR OS
TRG 1 N BRG 12 N DP TIM 0910 N RNG 27600 N DISP CR 1ST
TRG 1 N BRG 0 N DP 0 N TIM 0920 N RNG 22000 N DISP CR 2ND
TRG 1 N CMP DISP CR
TS DISP CR

\ should display test case
\ _ indicate blank display location
\ _ _____ 350.0 ___15.0  own ship entry
\ 1 _910_ _12._ _27600   First siting for ship 1
\ 1 _920_ __0.0 _22000   second for ship 1
\ 1 0938.9 318.9 _16594  CPA calculation
\ 1 _____ 269.3 ___19.8  target ships true bearing and speed


WS $0C ROMIN 1+ C! WT

\ Note X in simulator is single step like Y below

: Y ( addr - ) TOBREAK .T ;

: G ( ADDR K# - ) \ K# is keyboard number
   K TOBREAK .T ;

: DISP2 \ show status nibbles as well
   RAMSTATUS
   4 0 DO DUP i + C@ 1 .R LOOP DROP SPACE
   DISP ;
