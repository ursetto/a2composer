
*---------------------------------------------------------*
*     Disassembled with The Flaming Bird Disassembler     *
*    (c) Phoenix corp. 1992,93  -  All rights reserved    *
*---------------------------------------------------------*

          TYP BIN

          ORG $000800
          MX %11
          LDA TXTSET
          LDA TXTPAGE1
          LDA HIRES
          LDA MIXCLR
          LDA CLR80VID
          JSR SETVID
          JSR $03EA
          LDA #$FF
          STA $D9
          LDA #$00
          STA $76
          STA $33
          LDA #$00
          STA SOFTEV
          LDA #$08
          STA SOFTEV+1
          JSR SETPWRC
START     LDA #$00
          STA $0B
          TAY
:ZEROTABLES LDA #$00
          STA $14AC,Y    ; OVERLAP
          STA FILETBL,Y
          LDA #$FF
          STA $4040,Y
          INY
          BNE :ZEROTABLES
          JSR OUTPUT
          ASC 8D
          ASC 84
          ASC "BLOAD LOGO,A$2000"8D00
          LDA TXTCLR
          JSR INITnDIE
          JSR OUTPUT
          ASC "STANDBY...!"00
          STA KBDSTROBE
          LDY #$20
:WAIT     LDA KBD
          BMI TXTTITLE   ; keypress ends logo
          LDA #$FF
          JSR SUMDELAY
          DEY
          BPL :WAIT
TXTTITLE  STA KBDSTROBE
          LDA TXTSET
          LDA TXTPAGE1
          JSR HOME
          JSR OUTPUT
          ASC "!!!!  MIDIMAGIC PLAYER!  DEVELOPED BY B"
          ASC "OB KOVACS!  COPYRIGHT 1985!  ALL RIGHTS"
          ASC " RESERVED!  MICROFANTICS INC.!"00
          JMP PRESSANYKEY

MAINLOOP  LDA $0B        ; $0b=current song or 0
          BEQ SELECT
          INC CURSONG
          LDA CURSONG
          CMP SONGCNT
          BCC PLAYSEL
          LDA #$00
          STA $0B
          DEC CURSONG
          JMP MAINLOOP

SELECT    JSR MAINMENU
          JSR GETKEY
          JSR COUT       ; A=user's selection
          PHA
          LDA #$FF
          JSR SUMDELAY
          PLA
          LDY #$0B
:NEXT     CMP CHOICES,Y  ; find index of char
          BEQ :FOUND     ; in CHOICES array
          DEY
          BPL :NEXT
          BMI MAINLOOP   ; nope
:FOUND    TYA
PLAYSEL   ASL
          TAX
          LDY RTSTBL,X   ; get corresponding
          LDA RTSTBL+1,X ; addr in RTSTBL
          PHA
          TYA
          PHA            ; push addr on stack
          TXA
          LSR
          PHA
          JSR HOME
          PLA
          RTS            ; jump to selection

RTSTBL    DA $0E16
          DA $0E16
          DA $0E16
          DA $0E16
          DA $0E16
          DA $0E16
          DA $0E16
          DA $0E16
          DA $0E61
          DA $0E6B
          DA $0E6E
          DA $13B5
CHOICES   ASC "12345678ARI?"
          SEI
          JMP $097D

          LDY #$27
          LDA #$AE
          STA $0750,Y
          STA $07D0,Y
          DEY
          BPL $0974
          LDA #$13
          STA SSC_TDREG
          LDA #$80
          JSR SUMDELAY
          LDA #$11
          STA SSC_TDREG
          LDA #$0A
          STA SSC_COMMAND
          LDA #$00       ; 115200 8N1
          STA SSC_CONTROL
          LDA #$3F
          STA $00        ; SONGPTR
          LDA #$40
          STA $01
          LDA #$00
          STA $0305
          STA KBDSTROBE
          JSR $09AA
          RTS

          LDY #$BF
          JSR $09B5
          LDY #$BE
          JSR $09B5
          RTS

          LDA $1236,Y
          STA $06
          LDA $12F6,Y
          CLC
          ADC #$20
          STA $07
          LDY #$27
          LDA #$00
          STA ($06),Y
          DEY
          BPL $09C6
          RTS

          LDA TEMPO
          CMP #$9F
          BCS $09D9
          INC TEMPO
          JSR $09F2
          LDA #$00
          STA $0305
          RTS

          LDA TEMPO
          CMP #$21
          BCC $09EC
          DEC TEMPO
          JSR $09F2
          LDA #$00
          STA $0305
          RTS

          JSR CURSONGIDX
          LDA TEMPO
          ORA #$80
          STA FILETBL,Y
          JSR $09AA
          LDA #$00
          STA $0A
          LDA TEMPO
          SEC
          SBC #$20
          EOR #$FF
          AND #$7F
          LSR
          PHA
          LDY #$BF
          JSR $10E2
          PLA
          LDY #$BE
          JSR $10E2
          RTS

CURSONGIDX LDA #$00      ; Y=$303*32
          LDY CURSONG
          BEQ :DONE
          CLC
:ADD20    ADC #$20
          DEY
          BNE :ADD20
:DONE     TAY
          RTS

          JSR CURSONGIDX
          LDA FILETBL,Y  ; filename byte 0
          AND #$7F       ; lower 7 bits
          STA TEMPO      ; are the tempo
          LDA KBD
          STA KBDSTROBE
          BPL $0A4F
          STA $0305
          CMP #$95
          BNE $0A48
          JSR $09DF
          CMP #$88
          BNE $0A4F
          JSR $09CC
          LDA $0305
          BPL $0A57
          JMP $0B44

          JSR $0B2D
          CMP #$FF
          BNE $0A82
          JSR $0B2D
          BEQ $0A36
          CMP #$FF
          BNE $0A6E
          LDA #$FF
          STA $0305
          BNE $0A36
          STA $0306
          LDA TEMPO
          JSR SUMDELAY
          JSR $1125
          DEC $0306
          BNE $0A71
          JMP $0A36

          PHA
          LDA #$90
          JSR $0AEF
          PLA
          PHA
          AND #$7F
          STA $0307
          JSR $0AEF
          PLA
          BMI $0A99
          LDA #$40
          BNE $0A9B
          LDA #$00
          STA $0308
          JSR $0AEF
          LDA #$00
          LDX $0308
          BEQ $0AAA
          LDA #$FF
          STA $0A
          LDA $0307
          JSR $10D7
          JMP $0ADD

          LDA $0309
          SEC
          SBC #$1C
          BMI $0ADD
          ROR
          PHP
          ROL
          LSR
          TAY
          LDA #$AE
          LDX #$80
          CPX $0308
          BEQ $0AD2
          LDX $0307
          BEQ $0AD2
          LDA #$AA
          PLP
          BCC $0ADA
          STA $0750,Y
          BCS $0ADD
          STA $07D0,Y
          LDY #$00
          STY $0308
          STY $0307
          JMP $0A36

          PHA
          LDA #$0A
          JSR SUMDELAY
          PLA
          STA $09
          TXA
          PHA
          TYA
          PHA
          LDX #$08
          STX SSC_COMMAND
          JSR $0B2A
          LDA $09
          LDY #$07
          LSR
          BCC $0B08
          LDX #$00
          BEQ $0B0B
          LDX #$08
          NOP
          STX SSC_COMMAND
          JSR $0B2A
          DEY
          BPL $0B01
          NOP
          NOP
          NOP
          NOP
          LDX #$00
          STX SSC_COMMAND
          JSR $0B2A
          PLA
          TAY
          PLA
          TAX
          LDA $09
          STA SSC_STATUS
          RTS

          BIT $00
          RTS

          INC $00
          BNE $0B33
          INC $01
          LDY #$00
          LDA ($00),Y
          RTS

SUMDELAY  SEC            ; loop x+(x-1)+...+1 times
:outer    PHA
:inner    SBC #$01
          BNE :inner
          PLA
          SBC #$01
          BNE :outer
          RTS

          SEI
          LDA KBD
          AND #$7F
          CMP #$1B
          BNE $0B52
          LDA #$00
          STA $0B
          STA KBDSTROBE
          JSR $0B5D
          JSR $0B5D
          CLI
          RTS

          LDY #$7F
          LDA #$90
          JSR $0AE8
          TYA
          JSR $0AE8
          LDA #$00
          JSR $0AE8
          DEY
          BNE $0B5F
          RTS

GETKEY    STA KBDSTROBE
:WAITKEY  LDA KBD        ; WAIT FOR KEYPRESS
          BPL :WAITKEY
          STA KBDSTROBE
          CMP #$E0
          BCC $0B83
          SEC
          SBC #$20
          RTS

MAINMENU  LDA TXTSET
          LDA TXTPAGE1
          JSR HOME
          JSR OUTPUT
          ASC "!***** QRS DIGITAL PRESENTS *****!! MID"
          ASC "IMAGIC PLAYER FOR THE APPLE!"00
          LDA #$A0
          JSR COUT
          LDY #$00
PRINTDISK LDA $14AC,Y
          CMP #$8D
          BEQ $0BE8
          JSR COUT
          INY
          BNE PRINTDISK
          JSR CROUT
          JSR CROUT
          LDY #$00
          STY SONGCNT
PRINTSONG INY
          LDA FILETBL,Y
          BEQ MENU
          JSR OUTPUT
          ASC "     "00
          INC SONGCNT
          LDA SONGCNT
          CLC
          ADC #$B0       ; int->digit
          JSR COUT
          JSR OUTPUT
          ASC " ... "00
          JSR PRFILNAM
          JSR CROUT
          INY
          INY
          INY
          BNE PRINTSONG
MENU      JSR CROUT
          JSR OUTPUT
          ASC "     A ... PLAY ALL SONGS!     R ... RE"
          ASC "PEAT LAST SONG!     I ... INSTRUCTIONS!"
          ASC "!!     SELECTION --> "
          ASC ''8800
          RTS

PRFILNAM  LDA FILETBL,Y
          CMP #$8D
          BEQ :end
          JSR COUT
          INY
          BNE PRFILNAM
:end      RTS

LOADFILE  LDA #$00
          LDY CURSONG
          BEQ :x32END
          CLC
:x32      ADC #$20
          DEY
          BNE :x32
:x32END   TAY            ; CURSONG*32
          STY $09        ; IDX INTO FILETBL
          LDY #$1D       ; LOADING: 
          JSR BLOADCMD
          LDY $09        ; 
          INY
          JSR PRFILNAM
          JSR OUTPUT
          ASC "!!YOU CAN STOP THE SONG AT ANY TIME!WHI"
          ASC "LE IT IS PLAYING BY PRESSING THE!SPACE "
          ASC "BAR.!!IF YOU ARE PLAYING ALL SONGS THEN"
          ASC "!THE NEXT SONG ON THE LIST WILL LOAD.!P"
          ASC "RESSING THE ESC KEY WILL STOP PLAYING!A"
          ASC "LL SONGS AS WELL.!!THE SONG TEMPO CAN B"
          ASC "E ADJUSTED BY!PRESSING THE LEFT OR RIGH"
          ASC "T ARROW KEYS!"00
          LDY #$09       ; "NOMONIOC:BLOAD ^"
          JSR BLOADCMD
          LDY $09
          JSR PRFILNAM   ; FILENAME
          LDY #$00
          JSR BLOADCMD   ; ",A$4000"
          JMP HOME

PRESSANYKEY LDA #$17
          JSR TABV
          JSR CLREOL
          JSR OUTPUT
          ASC "Press Any Key To Continue"00
          JSR GETKEY
          JMP MAINLOOP

NEXTSONGP CMP SONGCNT
          BCC NEXTSONG
          JMP MAINLOOP

NEXTSONG  STA CURSONG
          JSR INITnDIE
          JSR LOADFILE
          JSR $096C
          LDY #$31
          LDA $1236,Y
          CLC
          ADC #$0A
          STA $06
          LDA $12F6,Y
          ADC #$20
          STA $07
          LDY #$12
          LDA #$7F
          STA ($06),Y
          DEY
          BPL $0E40
          LDA #$29
          STA $02
          JSR $1125
          DEC $02
          BPL $0E49
          STA TXTCLR
          STA HIRES
          STA MIXCLR
          JSR $0A2B
          STA TXTSET
          JMP MAINLOOP

          LDA #$FF
          STA $0B
          STA CURSONG
          JMP MAINLOOP
          JMP $0E28

          JSR OUTPUT
          ASC "THIS PROGRAM IS COMPATIBLE WITH THE!ENT"
          ASC "IRE APPLE II FAMILY OF COMPUTERS.!!IF Y"
          ASC "OU ARE USING AN APPLE II C THEN!MAKE SU"
          ASC "RE THAT THE COLORED PLUG!OF THE MIDIMAG"
          ASC "IC CABLE IS INSERTED!INTO SERIAL PORT #"
          ASC "2.!!ALL OTHER APPLE II COMPTERS REQUIRE"
          ASC " A!PASSPORT MIDI INTERFACE CARD OR A!SU"
          ASC "PERSERIAL CARD IN SLOT 2.!!!FOR ADDITIO"
          ASC "NAL INFORMATION ON MIDI!PRODUCTS - INCL"
          ASC "UDING SONG DISKETTES -!CALL MICROFANTIC"
          ASC "S INC. (201) 838-5606!!OR WRITE US AT:!"
          ASC "!           33 ADALIST AVENUE!         "
          ASC "  BUTLER, NJ 07405!"00
          JMP PRESSANYKEY

OUTPUT    TSX
          INX
          LDA $0100,X
          STA $02
          INX
          LDA $0100,X
          STA $03
          TYA
          PHA
          JSR $1094
          LDY #$00
          LDA ($02),Y
          BEQ $1084
          CMP #$A1
          BNE $107B
          LDA #$8D
          JSR COUT
          JSR $1094
          CLC
          BCC $106F
          PLA
          TAY
          TSX
          INX
          LDA $02
          STA $0100,X
          INX
          LDA $03
          STA $0100,X
          RTS

          INC $02
          BNE $109A
          INC $03
          RTS

BLOADCMD  LDA :STRS,Y    ; 
          BEQ $10AC
          CMP #$A1       ; 
          BNE $10A6
          LDA #$8D
          JSR COUT
          INY
          BNE BLOADCMD
          RTS

:STRS     ASC ",A$4000!"00
          ASC 8D
          ASC 84
          ASC "NOMONIOC"8D
          ASC 84
          ASC "BLOAD ^"00
          ASC "!!!"
          ASC 'LOADING'
          ASC ": "00
          SEC
          SBC #$23
          BMI $1124
          CMP #$42
          BCS $1124
          LDY #$31
          PHA
          LDA $1236,Y
          CLC
          ADC #$0A
          STA $06
          LDA $12F6,Y
          ADC #$20
          STA $07
          PLA
          TAX
          LDA $11D4,X
          TAY
          LDA $1180,X
          TAX
          BIT $0A
          BMI $1114
          LDA $1164,X
          ORA ($06),Y
          STA ($06),Y
          INX
          LDA $1164,X
          INY
          ORA ($06),Y
          STA ($06),Y
          CLC
          BCC $1124
          BRK $BD
          ADC ($11)
          AND ($06),Y
          STA ($06),Y
          INX
          LDA $1172,X
          INY
          AND ($06),Y
          STA ($06),Y
          RTS

          LDY #$5A
          LDA $1236,Y
          CLC
          ADC #$0A
          STA $04
          LDA $12F6,Y
          ADC #$20
          STA $05
          DEY
          STY $08
          LDA $04
          STA $06
          LDA $05
          STA $07
          LDY $08
          LDA $1236,Y
          CLC
          ADC #$0A
          STA $04
          LDA $12F6,Y
          ADC #$20
          STA $05
          LDY #$12
          LDA ($04),Y
          STA ($06),Y
          DEY
          BPL $1154
          DEC $08
          LDY $08
          CPY #$31
          BCS $1139
          RTS

          ORA $00,S
          TSB $3000
          BRK $40
          ORA ($00,X)
          ASL $00
          CLC
          BRK $60
          JMP ($737F,X)

          ADCL $3F7F4F,X
          ROR $797F,X
          ADCL $1F7F67,X
          BRK $02
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB $0200
          TSB $06
          PHP
          ASL
          TSB |SONGPTR
          BRK $00
          BRK $00
          BRK $02
          COP $02
          COP $02
          COP $02
          TSB $04
          TSB $04
          TSB $04
          TSB $06
          ASL $06
          ASL $06
          ASL $06
          PHP
          PHP
          PHP
          PHP
          PHP
          PHP
          PHP
          ASL
          ASL
          ASL
          ASL
          ASL
          ASL
          ASL
          TSB $0C0C
          TSB $0C0C
          TSB $0E0E
          ASL $0E0E
          ASL $100E
          BPL $121F
          BPL $1221
          BPL $1223
          ORA ($12)
          ORA ($12)
          ORA ($12)
          ORA ($14)
          TRB $14
          TRB $14
          TRB $14
          ASL $16,X
          ASL $16,X
          ASL $16,X
          ASL $18,X
          CLC
          CLC
          CLC
          CLC
          CLC
          CLC
          INC
          INC
          INC
          INC
          INC
          INC
          INC
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRA $11C0
          BRA $11C2
          BRA $11C4
          BRA $11C6
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRA $11D0
          BRA $11D2
          BRA $11D4
          BRA $11D6
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRA $11E0
          BRA $11E2
          BRA $11E4
          BRA $11E6
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRA $11F0
          BRA $11F2
          BRA $11F4
          BRA $11F6
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          PLP
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          TAY
          BVC $1308
          BVC $130A
          BVC $130C
          BVC $130E
          BNE $1290
          BNE $1292
          BNE $1294
          BNE $1296
          BVC $1318
          BVC $131A
          BVC $131C
          BVC $131E
          BNE $12A0
          BNE $12A2
          BNE $12A4
          BNE $12A6
          BVC $1328
          BVC $132A
          BVC $132C
          BVC $132E
          BNE $12B0
          BNE $12B2
          BNE $12B4
          BNE $12B6
          BVC $1338
          BVC $133A
          BVC $133C
          BVC $133E
          BNE $12C0
          BNE $12C2
          BNE $12C4
          BNE $12C6
          BRK $04
          PHP
          TSB $1410
          CLC
          TRB $0400
          PHP
          TSB $1410
          CLC
          TRB $0501
          ORA #$0D
          ORA ($15),Y
          ORA $011D,Y
          ORA $09
          ORA $1511
          ORA $021D,Y
          ASL $0A
          ASL $1612
          INC
          ASL $0602,X
          ASL
          ASL $1612
          INC
          ASL $0703,X
          PHD
          ORAL $1B1713
          ORAL $0B0703,X
          ORAL $1B1713
          ORAL $080400,X
          TSB $1410
          CLC
          TRB $0400
          PHP
          TSB $1410
          CLC
          TRB $0501
          ORA #$0D
          ORA ($15),Y
          ORA $011D,Y
          ORA $09
          ORA $1511
          ORA $021D,Y
          ASL $0A
          ASL $1612
          INC
          ASL $0602,X
          ASL
          ASL $1612
          INC
          ASL $0703,X
          PHD
          ORAL $1B1713
          ORAL $0B0703,X
          ORAL $1B1713
          ORAL $080400,X
          TSB $1410
          CLC
          TRB $0400
          PHP
          TSB $1410
          CLC
          TRB $0501
          ORA #$0D
          ORA ($15),Y
          ORA $011D,Y
          ORA $09
          ORA $1511
          ORA $021D,Y
          ASL $0A
          ASL $1612
          INC
          ASL $0602,X
          ASL
          ASL $1612
          INC
          ASL $0703,X
          PHD
          ORAL $1B1713
          ORAL $0B0703,X
          ORAL $1B1713
          ORAL $105D20,X
          ASC "TEMPO       SONG NAME!!"00
          LDY #$00
          JSR OUTPUT
          ASC "  "00
          LDA FILETBL,Y
          BEQ $13F3
          JSR COUT
          JSR OUTPUT
          ASC "  "00
          INY
          JSR PRFILNAM
          JSR CROUT
          INY
          INY
          INY
          BNE $13D3
          JSR PRESSANYKEY
INITnDIE  LDA #$00
          STA $05
          STA $06
          BRK $00        ; BAD SECTORS TO END
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00        ; 14AC-15CC ZEROED AT STARTUP
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
FILETBL   BRK $00        ; MAYBE 32 BYTE ENTRIES
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
          BRK $00
