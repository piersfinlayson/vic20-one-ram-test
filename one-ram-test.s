; VIC-20 One RAM Tester
;
; (c) 2026 Piers Finlayson
;
; Based on dead-test by Simon Rowe
;
; Tests One ROM operating as RAM at $1000-$17FF or $1800-$1FFF (or both)
;
; Use the Makefile to build
;
; NOTE - xa65 treats colons in comments as statement separators!
;        Do not use colons in comments or you will get mysterious errors.

#define VERSION "V0.1"

; Test address selection
TEST_BASE_HIGH_START = $10
TEST_BASE_HIGH_END = $20

INIT_TEST_VAL = $AA

; Zero page variables
ORIG    = $10                   ; Original value read
WROTE   = $11                   ; Value we wrote
READBK  = $12                   ; Value read back
PTR     = $14                   ; General purpose pointer (word)
TMP_Y   = $16                   ; Temporary Y storage (byte)
TEST_VAL= $17                   ; Test value to write
FAILURES= $18                   ; Number of failures (word)
SAVED_VAL=$1A                   ; Saved starting test value

; Screen and colour
SCBASE  = $0200                 ; Video memory
ROW0    = $0200
ROW1    = $0200+22
ROW2    = $0200+44
ROW3    = $0200+66
ROW4    = $0200+88
ROW5    = $0200+110
ROW6    = $0200+132
ROW7    = $0200+154
ROW8    = $0200+176
ROW21   = $0200+440
ROW22   = $0200+462
ROW23   = $0200+484
CLBASE  = $9600                 ; Colour memory
CLBASE5 = $9600+110

; VIC registers
VICCR0  = $9000
VICCR2  = $9002
VICCR5  = $9005
VICCRF  = $900F

; Colours
Yellow  = 7
Blue    = 6
Green   = 5
Purple  = 4
Cyan    = 3
Red     = 2
White   = 1
Black   = 0

; PAL/NTSC
VICPALNTSC = $FFF9
NTSC_VERSION = $00
PAL_VERSION = $01

;=======================================================================================================
; Code start
;=======================================================================================================

* = $E000

DEDCOLD
.(
    ; Initialize VIC chip
    LDX #VICINIT_END-VICINIT
ILOOP
    LDA VICINIT-1,X
    STA VICCR0-1,X
    DEX
    BNE ILOOP

    ; Set video to $0200, character ROM at $8000 IMMEDIATELY
    ; This must happen before any screen writes
    LDA #$82                    ; Video=$0200, Char=$8000
    STA VICCR5

    ; PAL/NTSC adjust
    LDA #PAL_VERSION
    CMP VICPALNTSC
    BEQ PAL

NTSC
    LDA #$05
    STA VICCR0
    LDA #$19
    STA VICCR0+1
    JMP INIT_SCREEN

PAL
    LDA #$0C
    STA VICCR0
    LDA #$26
    STA VICCR0+1
.)

INIT_SCREEN
.(
    ; Clear screen and colour RAM
    LDA #$20                    ; Space character
    LDY #0
CLEAR_LOOP
    STA SCBASE,Y
    STA SCBASE+$100,Y
    INY
    BNE CLEAR_LOOP

    LDA #Black
    LDY #0
COLOUR_LOOP
    STA CLBASE,Y
    STA CLBASE+$100,Y
    INY
    BNE COLOUR_LOOP
.)

INIT_VARs
    LDX #INIT_TEST_VAL
    STX TEST_VAL
    LDX #$00
    STX FAILURES
    STX FAILURES+1
INIT_VARS_DONE

    ; Display title
    LDX #0
TITLE_LOOP
    LDA TITLE,X
    BEQ TITLE_DONE
    STA ROW0,X
    INX
    BNE TITLE_LOOP
TITLE_DONE
    LDA #Yellow
    STA CLBASE+12

    LDX #0
TITLE2_LOOP
    LDA TITLE2,X
    BEQ TITLE2_DONE
    STA ROW1,X
    INX
    BNE TITLE2_LOOP
TITLE2_DONE

    LDX #0
FOOTER_LOOP
    LDA FOOTER,X
    BEQ FOOTER_DONE
    STA ROW21,X
    INX
    BNE FOOTER_LOOP
FOOTER_DONE

    LDX #0
FOOTER2_LOOP
    LDA FOOTER2,X
    BEQ FOOTER2_DONE
    STA ROW22,X
    INX
    BNE FOOTER2_LOOP
FOOTER2_DONE

    LDX #0
FOOTER3_LOOP
    LDA FOOTER3,X
    BEQ FOOTER3_DONE
    STA ROW23,X
    INX
    BNE FOOTER3_LOOP
FOOTER3_DONE

    ; Display Failures text
    LDA #'R'-$40
    STA ROW4
    LDA #'U'-$40
    STA ROW4+1
    LDA #'N'-$40
    STA ROW4+2
    LDA #'S'-$40
    STA ROW4+3
    LDA #$3A
    STA ROW4+4
    ;===================================
    ; THE TEST
    ;===================================

TEST_SETUP:
    ;===================================
    ; MULTI-PAGE BURST WRITE (8 pages)
    ;===================================
    
    ; Display "WRITING"
    LDA #'W'-$40
    STA ROW2+0
    LDA #'R'-$40
    STA ROW2+1
    LDA #'I'-$40
    STA ROW2+2
    LDA #'T'-$40
    STA ROW2+3
    LDA #'E'-$40
    STA ROW2+4
    LDA #$24
    STA ROW3+1
    
    LDA #TEST_BASE_HIGH_START
    STA PTR+1
    JSR HEXTOSCREEN
    STX ROW3+2
    STA ROW3+3

    LDA #$00
    STA PTR
    
    LDA TEST_VAL
    STA SAVED_VAL               ; Save starting value
    
BURST_WRITE_PAGE:
    LDX #$00
BURST_WRITE:
    INC TEST_VAL
    LDA TEST_VAL
    STA (PTR,X)
    INC PTR
    BNE BURST_WRITE
    INC PTR+1
    LDA PTR+1

    JSR HEXTOSCREEN
    STX ROW3+2
    STA ROW3+3
    LDX #$00
    LDA PTR+1
    
    CMP #TEST_BASE_HIGH_END
    BNE BURST_WRITE
    
    ;===================================
    ; MULTI-PAGE BURST READ (8 pages)
    ;===================================
    
    ; Display "READING"
    LDA #'R'-$40
    STA ROW2+6
    LDA #'E'-$40
    STA ROW2+7
    LDA #'A'-$40
    STA ROW2+8
    LDA #'D'-$40
    STA ROW2+9
    LDA #$24
    STA ROW3+6
    
    LDA #TEST_BASE_HIGH_START
    STA PTR+1

    JSR HEXTOSCREEN
    STX ROW3+7
    STA ROW3+8

    LDA #$00
    STA PTR
    
    LDA SAVED_VAL
    STA TEST_VAL                ; Restore starting value
    
BURST_READ_PAGE:
    LDX #$00
BURST_READ:
    INC TEST_VAL
    LDA TEST_VAL
    STA WROTE
    
    LDA (PTR,X)
    STA READBK
    
    CMP WROTE
    BNE BURST_FAIL
    
    INC PTR
    BNE BURST_READ
    INC PTR+1
    LDA PTR+1

    JSR HEXTOSCREEN
    STX ROW3+7
    STA ROW3+8
    LDX #$00
    LDA PTR+1

    CMP #TEST_BASE_HIGH_END
    BNE BURST_READ
    
    ;===================================
    ; SUCCESS - loop again
    ;===================================
    LDA #'P'-$40
    STA ROW5+0
    LDA #'A'-$40
    STA ROW5+1
    
    LDA #'S'-$40
    STA ROW5+2
    STA ROW5+3
    LDA #Green
    STA CLBASE5+0
    STA CLBASE5+1
    STA CLBASE5+2
    STA CLBASE5+3
    
    ; Increment pass counter
    INC FAILURES
    BNE PASS_DISPLAY
    INC FAILURES+1
PASS_DISPLAY:
    LDA FAILURES+1
    JSR HEXTOSCREEN
    STX ROW4+5
    STA ROW4+6
    LDA FAILURES
    JSR HEXTOSCREEN
    STX ROW4+7
    STA ROW4+8
    
    JMP TEST_SETUP              ; Run again
BURST_FAIL:
    ;===================================
    ; FAILURE - Display diagnostics
    ;===================================
    
    ; Row 1 FAILED
    LDA #'F'-$40
    STA ROW5
    LDA #'A'-$40
    STA ROW5+1
    LDA #'I'-$40
    STA ROW5+2
    LDA #'L'-$40
    STA ROW5+3
    LDA #'E'-$40
    STA ROW5+4
    LDA #'D'-$40
    STA ROW5+5
    LDA #Purple
    STA CLBASE5+0
    STA CLBASE5+1
    STA CLBASE5+2
    STA CLBASE5+3
    STA CLBASE5+4
    STA CLBASE5+5
    
    ; Row 2 ADDR and address value
    LDA #'A'-$40
    STA ROW6+0
    LDA #'D'-$40
    STA ROW6+1
    LDA #'D'-$40
    STA ROW6+2
    LDA #'R'-$40
    STA ROW6+3
    LDA #$3A                    
    STA ROW6+4
    LDA #$24                    
    STA ROW6+5
    
    LDA PTR+1
    JSR HEXTOSCREEN
    STX ROW6+6
    STA ROW6+7
    TYA
    JSR HEXTOSCREEN
    STX ROW6+8
    STA ROW6+9
    
    ; Row 3 EXP and GOT values
    LDA #'E'-$40
    STA ROW7+0
    LDA #'X'-$40
    STA ROW7+1
    LDA #'P'-$40
    STA ROW7+2
    LDA #$3A
    STA ROW7+3
    LDA #$24
    STA ROW7+4
    
    LDA WROTE
    JSR HEXTOSCREEN
    STX ROW7+5
    STA ROW7+6
    
    LDA #$20
    STA ROW7+7
    LDA #'G'-$40
    STA ROW7+8
    LDA #'O'-$40
    STA ROW7+9
    LDA #'T'-$40
    STA ROW7+10
    LDA #$3A
    STA ROW7+11
    LDA #$24
    STA ROW7+12
    
    LDA READBK
    JSR HEXTOSCREEN
    STX ROW7+13
    STA ROW7+14
    
    JSR INCFAILURES
    JMP HALT

HALT
    JMP HALT

;=======================================================================================================
; HEXTOSCREEN - Convert byte in A to two screen codes
; Returns X = high nibble screen code, A = low nibble screen code
;=======================================================================================================
HEXTOSCREEN
.(
    STY TMP_Y
    PHA
    LSR
    LSR
    LSR
    LSR
    TAX
    LDA HEXTABLE,X
    TAX
    PLA
    AND #$0F
    TAY
    LDA HEXTABLE,Y
    LDY TMP_Y
    RTS
.)

;=======================================================================================================
; INCFAILURES
; FAILURES is 2 bytes at $18
; Updates number of failures in hex on screen at 97
;=======================================================================================================
INCFAILURES
.(
    LDA FAILURES
    CLC
    ADC #1
    STA FAILURES
    LDA FAILURES+1
    ADC #0
    STA FAILURES+1
    ; Update on screen
    LDA FAILURES+1
    JSR HEXTOSCREEN
    STX ROW4+5
    STA ROW4+6
    LDA FAILURES
    JSR HEXTOSCREEN
    STX ROW4+7
    STA ROW4+8
    RTS
.)

HEXTABLE
    .BYT $30,$31,$32,$33,$34,$35,$36,$37,$38,$39  ; 0-9
    .BYT $01,$02,$03,$04,$05,$06                  ; A-F (screen codes)

;=======================================================================================================
; Data
;=======================================================================================================

; Title
TITLE
    .BYT 'V'-$40,'I'-$40,'C'-$40,$2D,$32,$30,' '
    .BYT 'O'-$40,'N'-$40,'E'-$40,' '
    .BYT 'R'-$40,'A'-$40,'M'-$40,' '
    .BYT 'T'-$40,'E'-$40,'S'-$40,'T'-$40,'E'-$40,'R'-$40
    .BYT 0

; Delimiter
TITLE2
    .BYT $78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,$78,0

; Delimiter
FOOTER
    .BYT $79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,$79,0

; Version
FOOTER2
    .BYTE 'V'-$40,$30,$2E,$31,$2E,$30,0

; Copyright
FOOTER3
    .BYT $28,'C'-$40,$29,$20,$32,$30,$32,$36,$20
    .BYT 'P'-$40,'I'-$40,'E'-$40,'R'-$40,'S'-$40,$2E
    .BYT 'R'-$40,'O'-$40,'C'-$40,'K'-$40,'S'-$40
    .BYT 0

; VIC initialization table
VICINIT
    .byt $0C                    ; $9000 - Interlace/horiz origin (PAL default)
    .byt $26                    ; $9001 - Vertical origin (PAL default)
    .byt $96                    ; $9002 - Video addr bit 9 + columns (22 cols, bit 7 set for $9600 colour)
    .byt $2E                    ; $9003 - Rows + char height
    .byt $00                    ; $9004 - Raster
    .byt $82                    ; $9005 - Video=$0200, Char=$8000
    .byt $00                    ; $9006 - Light pen X
    .byt $00                    ; $9007 - Light pen Y
    .byt $00                    ; $9008 - Paddle X
    .byt $00                    ; $9009 - Paddle Y
    .byt $00                    ; $900A - Osc 1
    .byt $00                    ; $900B - Osc 2
    .byt $00                    ; $900C - Osc 3
    .byt $00                    ; $900D - Noise
    .byt $00                    ; $900E - Aux colour + volume
    .byt 26                     ; $900F - Background/border (red border, white background)
VICINIT_END

;=======================================================================================================
; Pad and vectors
;=======================================================================================================

.dsb $FFF9 - *, $FF

* = $FFF9
#ifdef NTSC_VER
    .byt NTSC_VERSION
#else
#ifdef PAL_VER
    .byt PAL_VERSION
#else
#error "Define either NTSC_VER or PAL_VER"
#endif
#endif

* = $FFFA
    .word $0000                 ; NMI
    .word DEDCOLD               ; RESET
    .word $0000                 ; IRQ