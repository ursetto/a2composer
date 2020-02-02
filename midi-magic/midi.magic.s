
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
          JSR RECONNECTIO ;  CONNECT DOS KBD/SCRN INTERCEPT
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
          STA DISKNAME,Y ; OVERLAP
          STA FILETBL,Y
          LDA #$FF
          STA $4040,Y
          INY
          BNE :ZEROTABLES
          JSR OUTSTR
          ASC 8D
          ASC 84
          ASC "BLOAD LOGO,A$2000"8D00
          LDA TXTCLR
          JSR INITCAT
          JSR OUTSTR
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
          JSR OUTSTR
          ASC "!!!!  MIDIMAGIC PLAYER!  DEVELOPED BY B"
          ASC "OB KOVACS!  COPYRIGHT 1985!  ALL RIGHTS"
          ASC " RESERVED!  MICROFANTICS INC.!"00
          JMP PRESSANYKEY

MAINLOOP  LDA $0B        ; ISPLAYING
          BEQ SELECT
          INC CURSONG
          LDA CURSONG
          CMP SONGCNT
          BCC PLAYSEL
          LDA #$00
          STA $0B        ; ISPLAYING
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
SETUP     SEI
          JMP SETUP2

          LDY #$27       ; is this ever called?
          LDA #$AE
          STA $0750,Y    ; FILL 750-777 W/$AE
          STA $07D0,Y    ; FILL 7D0-7F7 W/$AE
          DEY
          BPL $0974
SETUP2    LDA #$13
          STA SSC_TDREG
          LDA #$80
          JSR SUMDELAY
          LDA #$11
          STA SSC_TDREG
          LDA #$0A       ;  MARK parity?
          STA SSC_COMMAND
          LDA #$00       ; 115200 8M1 (?)
          STA SSC_CONTROL
          LDA #$3F
          STA $00        ; SONGPTR
          LDA #$40
          STA $01
          LDA #$00
          STA LASTKEY
          STA KBDSTROBE
          JSR CLRBOTTOM
          RTS

CLRBOTTOM LDY #$BF       ; clr last 2 HGR lines
          JSR CLRLINE
          LDY #$BE
          JSR CLRLINE
          RTS

CLRLINE   LDA HGRLO,Y    ; Y=hgr line # to clr
          STA $06
          LDA HGRHI,Y
          CLC
          ADC #$20
          STA $07
          LDY #$27       ; 40 bytes / HGR line
          LDA #$00
]1        STA ($06),Y
          DEY
          BPL ]1
          RTS

INCTEMPO  LDA TEMPO
          CMP #$9F       ; max tempo 159
          BCS :ret
          INC TEMPO
          JSR UPDATETEMPO
:ret      LDA #$00
          STA LASTKEY
          RTS

DECTEMPO  LDA TEMPO
          CMP #$21       ; min tempo 32
          BCC :ret
          DEC TEMPO
          JSR UPDATETEMPO
:ret      LDA #$00
          STA LASTKEY
          RTS

UPDATETEMPO JSR CURSONGIDX
          LDA TEMPO
          ORA #$80       ; make into ascii char
          STA FILETBL,Y  ; for filename
          JSR CLRBOTTOM
          LDA #$00
          STA $0A        ; DRAWROLL white pxl
          LDA TEMPO
          SEC
          SBC #$20
          EOR #$FF       ; seems to convert
          AND #$7F       ; tempo 32-159 to
          LSR            ; 63-0 (reversed)
          PHA
          LDY #$BF       ; reuse drawroll to
          JSR DRAWROLL   ; show tempo as
          PLA            ; "note" on bottom
          LDY #$BE       ; 2 lines of scrn
          JSR DRAWROLL
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

PLAY      JSR CURSONGIDX
          LDA FILETBL,Y  ; filename byte 0
          AND #$7F       ; lower 7 bits
          STA TEMPO      ; are the tempo
PLAY2     LDA KBD
          STA KBDSTROBE
          BPL :nokey
          STA LASTKEY    ; save last keypress?
          CMP #$95       ; right arrow key
          BNE :next      ; decreases tempo val
          JSR DECTEMPO
:next     CMP #$88       ; left arrow key
          BNE :nokey
          JSR INCTEMPO
:nokey    LDA LASTKEY
          BPL $0A57
          JMP $0B44

          JSR NEXTSONGBYTE
          CMP #$FF
          BNE NOTEMSG
          JSR NEXTSONGBYTE
          BEQ PLAY2
          CMP #$FF
          BNE $0A6E
          LDA #$FF
          STA LASTKEY
          BNE PLAY2
          STA $0306
          LDA TEMPO
          JSR SUMDELAY   ; the tick delay
          JSR SCROLLROLL
          DEC $0306
          BNE $0A71
          JMP PLAY2

NOTEMSG   PHA            ; send note on or off
          LDA #$90       ; note ON
          JSR SEND2
          PLA
          PHA
          AND #$7F
          STA NOTENUM    ; temp -- note num
          JSR SEND2      ; send byte in A
          PLA
          BMI :off       ; note>127 is off
          LDA #$40       ; vel 64
          BNE $0A9B      ; skip next inst
:off      LDA #$00       ; vel 0 (note off)
          STA NOTEVEL
          JSR SEND2      ; send byte in A
          LDA #$00
          LDX NOTEVEL
          BEQ :draw
          LDA #$FF
:draw     STA $0A        ; 00=off, FF=note on
          LDA NOTENUM
          JSR DRAWNOTE
          JMP ENDMSG

ANIMATE   LDA $0309
          SEC
          SBC #$1C
          BMI ENDMSG
          ROR
          PHP
          ROL
          LSR
          TAY
          LDA #$AE       ; '.'
          LDX #$80
          CPX NOTEVEL
          BEQ $0AD2
          LDX NOTENUM
          BEQ $0AD2
          LDA #$AA       ; '*'
          PLP
          BCC $0ADA
          STA $0750,Y    ; 23RD TEXT LINE
          BCS ENDMSG
          STA $07D0,Y    ; 24TH TEXT LINE
ENDMSG    LDY #$00
          STY NOTEVEL
          STY NOTENUM
          JMP PLAY2

SEND      PHA
          LDA #$0A       ; preserves A,X,Y
          JSR SUMDELAY   ; X,Y unused
          PLA
SEND2     STA $09        ; A -> $09
          TXA
          PHA
          TYA
          PHA
          LDX #$08       ; this oddly seems to
          STX SSC_COMMAND ; send 1 bit at a time
          JSR $0B2A      ; by frobbing some
          LDA $09        ; line (TX or DTR?)
          LDY #$07
          LSR            ; COMMAND bit 3 is
          BCC $0B08      ; underdocumented so
          LDX #$00       ; hard to be sure
          BEQ $0B0B      ; always
          LDX #$08
          NOP
          STX SSC_COMMAND
          JSR $0B2A
          DEY
          BPL $0B01      ; send 8 bits?
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
          STA SSC_STATUS ; reset, maybe
          RTS

          BIT $00        ; just a delay?
          RTS

NEXTSONGBYTE INC $00     ; A=($00++)
          BNE $0B33      ; Read next song byte
          INC $01        ; and inc songptr
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

          SEI            ; critical SSC section
          LDA KBD
          AND #$7F
          CMP #$1B       ; ESC
          BNE :continue
          LDA #$00       ; stop song on ESC
          STA $0B
:continue STA KBDSTROBE
          JSR ALLOFF
          JSR ALLOFF     ; why twice
          CLI
          RTS

ALLOFF    LDY #$7F       ; send 90 7F 00
:loop     LDA #$90       ; thru 90 01 00
          JSR SEND       ; ie NOTE ON VEL 0
          TYA            ; for all KEYs
          JSR SEND       ; on CHAN 0
          LDA #$00
          JSR SEND
          DEY
          BNE :loop      ; 127 times
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
          JSR OUTSTR
          ASC "!***** QRS DIGITAL PRESENTS *****!! MID"
          ASC "IMAGIC PLAYER FOR THE APPLE!"00
          LDA #$A0
          JSR COUT
          LDY #$00
PRINTDISK LDA DISKNAME,Y
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
          JSR OUTSTR
          ASC "     "00
          INC SONGCNT
          LDA SONGCNT
          CLC
          ADC #$B0       ; int->digit
          JSR COUT
          JSR OUTSTR
          ASC " ... "00
          JSR PRFILNAM
          JSR CROUT
          INY
          INY
          INY
          BNE PRINTSONG
MENU      JSR CROUT
          JSR OUTSTR
          ASC "     A ... PLAY ALL SONGS!     R ... RE"
          ASC "PEAT LAST SONG!     I ... INSTRUCTIONS!"
          ASC "!!     SELECTION --> "
          HEX 7F8800
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
          LDY $09
          INY
          JSR PRFILNAM
          JSR OUTSTR
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
          JSR OUTSTR
          ASC "Press Any Key To Continue"00
          JSR GETKEY
          JMP MAINLOOP

NEXTSONGP CMP SONGCNT
          BCC NEXTSONG
          JMP MAINLOOP

NEXTSONG  STA CURSONG
          JSR INITCAT
          JSR LOADFILE
          JSR SETUP
CLEARROLL LDY #$31       ; HPLOT 70,49 TO
          LDA HGRLO,Y    ; 195,49
          CLC
          ADC #$0A       ; 10*7=70
          STA $06
          LDA HGRHI,Y
          ADC #$20
          STA $07
          LDY #$12       ; 18*7=126 pixels
          LDA #$7F       ; white
:plot     STA ($06),Y
          DEY
          BPL :plot      ; draw top line
          LDA #$29
          STA $02
:scroll   JSR SCROLLROLL ; scroll $2A times
          DEC $02        ; to clear whole roll
          BPL :scroll    ; to white
          STA TXTCLR
          STA HIRES
          STA MIXCLR     ; full screen HGR
          JSR PLAY
          STA TXTSET     ; back to text mode
          JMP MAINLOOP

          LDA #$FF
          STA $0B
          STA CURSONG
          JMP MAINLOOP
          JMP $0E28

          JSR OUTSTR
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

OUTSTR    TSX
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

BLOADCMD  LDA :STRS,Y
          BEQ $10AC
          CMP #$A1
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
DRAWNOTE  SEC            ; DRAW SOMETHING 
          SBC #$23       ; (maybe note num?)
          BMI DRAWEND    ; Accept A = 35-100
          CMP #$42       ; and rescale to
          BCS DRAWEND    ; A = 0-65
          LDY #$31       ; HGR y=49
DRAWROLL  PHA            ; main entry point
          LDA HGRLO,Y
          CLC
          ADC #$0A       ; HGR x=70 y=Y
          STA $06
          LDA HGRHI,Y
          ADC #$20
          STA $07
          PLA
          TAX            ; note is index
          LDA XINDEX,X   ; index into HGR line
          TAY
          LDA MASKIDX,X  ; index into PIXMASK
          TAX
          BIT $0A        ; #00 or #FF
          BMI :on        ; -
          LDA PIXMASKOFF,X ; OR in 2 mask bytes
          ORA ($06),Y    ; per note; each note
          STA ($06),Y    ; is 2 pixels wide
          INX            ; (white) so 2 bytes
          LDA PIXMASKOFF,X ; hold 7 notes
          INY            ; (14 pixel bits)
          ORA ($06),Y
          STA ($06),Y
          CLC
          BCC DRAWEND    ; always
          DB $00
:on       LDA PIXMASKON,X
          AND ($06),Y    ; turn note on (black)
          STA ($06),Y    ; as above, using
          INX            ; AND mask
          LDA PIXMASKON,X
          INY
          AND ($06),Y
          STA ($06),Y
DRAWEND   RTS

SCROLLROLL LDY #$5A      ; Scroll the area
          LDA HGRLO,Y    ; from 70,49-195,90
          CLC            ; down by 1 pixel
          ADC #$0A
          STA $04
          LDA HGRHI,Y
          ADC #$20
          STA $05
          DEY
          STY $08        ; $08: curline
:2        LDA $04        ; $04-05: this addr
          STA $06        ; $06-07: prev addr
          LDA $05
          STA $07        ; *prev = *this
          LDY $08
          LDA HGRLO,Y
          CLC
          ADC #$0A       ; x=70
          STA $04
          LDA HGRHI,Y    ; *this = next line
          ADC #$20
          STA $05
          LDY #$12       ; 126 pixels wide
:1        LDA ($04),Y    ; copy line above
          STA ($06),Y    ; to line below
          DEY
          BPL :1
          DEC $08        ; line--
          LDY $08
          CPY #$31       ; while line >= 49
          BCS :2
          RTS

PIXMASKOFF DW $0003      ; mask ORed into
          DW $000C       ; 2 adjacent bytes
          DW $0030       ; 1 DW per note
          DW $0140       ; 2 white pixels
          DW $0600       ; per note
          DW $1800
          DW $6000
PIXMASKON DW $7F7C       ; mask ANDed to
          DW $7F73       ; turn on notes
          DW $7F4F
          DW $7E3F       ; this is just
          DW $797F       ; PIXMASK EOR #$7F
          DW $677F
          DW $1F7F
MASKIDX   DB $00         ; Index into PIXMASK
          DB $02         ; based on note num
          DB $04
          DB $06         ; Len=$54 but only
          DB $08         ; first $42 is used
          DB $0A
          DB $0C         ; Repeats every
          DB $00         ; 7 notes
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
          DB $00
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
          DB $00
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
          DB $00
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
          DB $00
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
          DB $00
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
          DB $00
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
          DB $00
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
          DB $00
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
          DB $00
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
          DB $00
          DB $02
          DB $04
          DB $06
          DB $08
          DB $0A
          DB $0C
XINDEX    DB $00         ; Index into HGR byte
          DB $00         ; based on note num
          DB $00
          DB $00         ; These are in groups
          DB $00         ; of 7 pixels
          DB $00
          DB $00
          DB $02
          DB $02
          DB $02
          DB $02
          DB $02
          DB $02
          DB $02
          DB $04
          DB $04
          DB $04
          DB $04
          DB $04
          DB $04
          DB $04
          DB $06
          DB $06
          DB $06
          DB $06
          DB $06
          DB $06
          DB $06
          DB $08
          DB $08
          DB $08
          DB $08
          DB $08
          DB $08
          DB $08
          DB $0A
          DB $0A
          DB $0A
          DB $0A
          DB $0A
          DB $0A
          DB $0A
          DB $0C
          DB $0C
          DB $0C
          DB $0C
          DB $0C
          DB $0C
          DB $0C
          DB $0E
          DB $0E
          DB $0E
          DB $0E
          DB $0E
          DB $0E
          DB $0E
          DB $10
          DB $10
          DB $10
          DB $10
          DB $10
          DB $10
          DB $10
          DB $12
          DB $12
          DB $12
          DB $12
          DB $12
          DB $12
          DB $12
          DB $14
          DB $14
          DB $14
          DB $14
          DB $14
          DB $14
          DB $14
          DB $16
          DB $16
          DB $16
          DB $16
          DB $16
          DB $16
          DB $16
UNUSEDX   DB $18         ; Appears unused as
          DB $18         ; MASKIDX len is $54.
          DB $18
          DB $18
          DB $18
          DB $18
          DB $18
          DB $1A
          DB $1A
          DB $1A
          DB $1A
          DB $1A
          DB $1A
          DB $1A
HGRLO     DB $00         ; looks like an HGR
HGRLO+1   DB $00
HGRLO+2   DB $00         ; address index table
HGRLO+3   DB $00
HGRLO+4   DB $00
HGRLO+5   DB $00
HGRLO+6   DB $00
HGRLO+7   DB $00
HGRLO+8   DB $80
HGRLO+9   DB $80
HGRLO+$A  DB $80
HGRLO+$B  DB $80
HGRLO+$C  DB $80
HGRLO+$D  DB $80
HGRLO+$E  DB $80
HGRLO+$F  DB $80
HGRLO+$10 DB $00
HGRLO+$11 DB $00
HGRLO+$12 DB $00
HGRLO+$13 DB $00
HGRLO+$14 DB $00
HGRLO+$15 DB $00
HGRLO+$16 DB $00
HGRLO+$17 DB $00
HGRLO+$18 DB $80
HGRLO+$19 DB $80
HGRLO+$1A DB $80
HGRLO+$1B DB $80
HGRLO+$1C DB $80
HGRLO+$1D DB $80
HGRLO+$1E DB $80
HGRLO+$1F DB $80
HGRLO+$20 DB $00
HGRLO+$21 DB $00
HGRLO+$22 DB $00
HGRLO+$23 DB $00
HGRLO+$24 DB $00
HGRLO+$25 DB $00
HGRLO+$26 DB $00
HGRLO+$27 DB $00
HGRLO+$28 DB $80
HGRLO+$29 DB $80
HGRLO+$2A DB $80
HGRLO+$2B DB $80
HGRLO+$2C DB $80
HGRLO+$2D DB $80
HGRLO+$2E DB $80
HGRLO+$2F DB $80
HGRLO+$30 DB $00
HGRLO+$31 DB $00
HGRLO+$32 DB $00
HGRLO+$33 DB $00
HGRLO+$34 DB $00
HGRLO+$35 DB $00
HGRLO+$36 DB $00
HGRLO+$37 DB $00
HGRLO+$38 DB $80
HGRLO+$39 DB $80
HGRLO+$3A DB $80
HGRLO+$3B DB $80
HGRLO+$3C DB $80
HGRLO+$3D DB $80
HGRLO+$3E DB $80
HGRLO+$3F DB $80
HGRLO+$40 DB $28
HGRLO+$41 DB $28
HGRLO+$42 DB $28
HGRLO+$43 DB $28
HGRLO+$44 DB $28
HGRLO+$45 DB $28
HGRLO+$46 DB $28
HGRLO+$47 DB $28
HGRLO+$48 DB $A8
HGRLO+$49 DB $A8
HGRLO+$4A DB $A8
HGRLO+$4B DB $A8
HGRLO+$4C DB $A8
HGRLO+$4D DB $A8
HGRLO+$4E DB $A8
HGRLO+$4F DB $A8
HGRLO+$50 DB $28
HGRLO+$51 DB $28
HGRLO+$52 DB $28
HGRLO+$53 DB $28
HGRLO+$54 DB $28
HGRLO+$55 DB $28
HGRLO+$56 DB $28
HGRLO+$57 DB $28
HGRLO+$58 DB $A8
HGRLO+$59 DB $A8
HGRLO+$5A DB $A8
HGRLO+$5B DB $A8
HGRLO+$5C DB $A8
HGRLO+$5D DB $A8
HGRLO+$5E DB $A8
HGRLO+$5F DB $A8
HGRLO+$60 DB $28
HGRLO+$61 DB $28
HGRLO+$62 DB $28
HGRLO+$63 DB $28
HGRLO+$64 DB $28
HGRLO+$65 DB $28
HGRLO+$66 DB $28
HGRLO+$67 DB $28
HGRLO+$68 DB $A8
HGRLO+$69 DB $A8
HGRLO+$6A DB $A8
HGRLO+$6B DB $A8
HGRLO+$6C DB $A8
HGRLO+$6D DB $A8
HGRLO+$6E DB $A8
HGRLO+$6F DB $A8
HGRLO+$70 DB $28
HGRLO+$71 DB $28
HGRLO+$72 DB $28
HGRLO+$73 DB $28
HGRLO+$74 DB $28
HGRLO+$75 DB $28
HGRLO+$76 DB $28
HGRLO+$77 DB $28
HGRLO+$78 DB $A8
HGRLO+$79 DB $A8
HGRLO+$7A DB $A8
HGRLO+$7B DB $A8
HGRLO+$7C DB $A8
HGRLO+$7D DB $A8
HGRLO+$7E DB $A8
HGRLO+$7F DB $A8
HGRLO+$80 DB $50
HGRLO+$81 DB $50
HGRLO+$82 DB $50
HGRLO+$83 DB $50
HGRLO+$84 DB $50
HGRLO+$85 DB $50
HGRLO+$86 DB $50
HGRLO+$87 DB $50
HGRLO+$88 DB $D0
HGRLO+$89 DB $D0
HGRLO+$8A DB $D0
HGRLO+$8B DB $D0
HGRLO+$8C DB $D0
HGRLO+$8D DB $D0
HGRLO+$8E DB $D0
HGRLO+$8F DB $D0
HGRLO+$90 DB $50
HGRLO+$91 DB $50
HGRLO+$92 DB $50
HGRLO+$93 DB $50
HGRLO+$94 DB $50
HGRLO+$95 DB $50
HGRLO+$96 DB $50
HGRLO+$97 DB $50
HGRLO+$98 DB $D0
HGRLO+$99 DB $D0
HGRLO+$9A DB $D0
HGRLO+$9B DB $D0
HGRLO+$9C DB $D0
HGRLO+$9D DB $D0
HGRLO+$9E DB $D0
HGRLO+$9F DB $D0
HGRLO+$A0 DB $50
HGRLO+$A1 DB $50
HGRLO+$A2 DB $50
HGRLO+$A3 DB $50
HGRLO+$A4 DB $50
HGRLO+$A5 DB $50
HGRLO+$A6 DB $50
HGRLO+$A7 DB $50
HGRLO+$A8 DB $D0
HGRLO+$A9 DB $D0
HGRLO+$AA DB $D0
HGRLO+$AB DB $D0
HGRLO+$AC DB $D0
HGRLO+$AD DB $D0
HGRLO+$AE DB $D0
HGRLO+$AF DB $D0
HGRLO+$B0 DB $50
HGRLO+$B1 DB $50
HGRLO+$B2 DB $50
HGRLO+$B3 DB $50
HGRLO+$B4 DB $50
HGRLO+$B5 DB $50
HGRLO+$B6 DB $50
HGRLO+$B7 DB $50
HGRLO+$B8 DB $D0
HGRLO+$B9 DB $D0
HGRLO+$BA DB $D0
HGRLO+$BB DB $D0
HGRLO+$BC DB $D0
HGRLO+$BD DB $D0
HGRLO+$BE DB $D0
HGRLO+$BF DB $D0
HGRHI     DB $00
HGRHI+1   DB $04
HGRHI+2   DB $08
HGRHI+3   DB $0C
HGRHI+4   DB $10
HGRHI+5   DB $14
HGRHI+6   DB $18
HGRHI+7   DB $1C
HGRHI+8   DB $00
HGRHI+9   DB $04
HGRHI+$A  DB $08
HGRHI+$B  DB $0C
HGRHI+$C  DB $10
HGRHI+$D  DB $14
HGRHI+$E  DB $18
HGRHI+$F  DB $1C
HGRHI+$10 DB $01
HGRHI+$11 DB $05
HGRHI+$12 DB $09
HGRHI+$13 DB $0D
HGRHI+$14 DB $11
HGRHI+$15 DB $15
HGRHI+$16 DB $19
HGRHI+$17 DB $1D
HGRHI+$18 DB $01
HGRHI+$19 DB $05
HGRHI+$1A DB $09
HGRHI+$1B DB $0D
HGRHI+$1C DB $11
HGRHI+$1D DB $15
HGRHI+$1E DB $19
HGRHI+$1F DB $1D
HGRHI+$20 DB $02
HGRHI+$21 DB $06
HGRHI+$22 DB $0A
HGRHI+$23 DB $0E
HGRHI+$24 DB $12
HGRHI+$25 DB $16
HGRHI+$26 DB $1A
HGRHI+$27 DB $1E
HGRHI+$28 DB $02
HGRHI+$29 DB $06
HGRHI+$2A DB $0A
HGRHI+$2B DB $0E
HGRHI+$2C DB $12
HGRHI+$2D DB $16
HGRHI+$2E DB $1A
HGRHI+$2F DB $1E
HGRHI+$30 DB $03
HGRHI+$31 DB $07
HGRHI+$32 DB $0B
HGRHI+$33 DB $0F
HGRHI+$34 DB $13
HGRHI+$35 DB $17
HGRHI+$36 DB $1B
HGRHI+$37 DB $1F
HGRHI+$38 DB $03
HGRHI+$39 DB $07
HGRHI+$3A DB $0B
HGRHI+$3B DB $0F
HGRHI+$3C DB $13
HGRHI+$3D DB $17
HGRHI+$3E DB $1B
HGRHI+$3F DB $1F
HGRHI+$40 DB $00
HGRHI+$41 DB $04
HGRHI+$42 DB $08
HGRHI+$43 DB $0C
HGRHI+$44 DB $10
HGRHI+$45 DB $14
HGRHI+$46 DB $18
HGRHI+$47 DB $1C
HGRHI+$48 DB $00
HGRHI+$49 DB $04
HGRHI+$4A DB $08
HGRHI+$4B DB $0C
HGRHI+$4C DB $10
HGRHI+$4D DB $14
HGRHI+$4E DB $18
HGRHI+$4F DB $1C
HGRHI+$50 DB $01
HGRHI+$51 DB $05
HGRHI+$52 DB $09
HGRHI+$53 DB $0D
HGRHI+$54 DB $11
HGRHI+$55 DB $15
HGRHI+$56 DB $19
HGRHI+$57 DB $1D
HGRHI+$58 DB $01
HGRHI+$59 DB $05
HGRHI+$5A DB $09
HGRHI+$5B DB $0D
HGRHI+$5C DB $11
HGRHI+$5D DB $15
HGRHI+$5E DB $19
HGRHI+$5F DB $1D
HGRHI+$60 DB $02
HGRHI+$61 DB $06
HGRHI+$62 DB $0A
HGRHI+$63 DB $0E
HGRHI+$64 DB $12
HGRHI+$65 DB $16
HGRHI+$66 DB $1A
HGRHI+$67 DB $1E
HGRHI+$68 DB $02
HGRHI+$69 DB $06
HGRHI+$6A DB $0A
HGRHI+$6B DB $0E
HGRHI+$6C DB $12
HGRHI+$6D DB $16
HGRHI+$6E DB $1A
HGRHI+$6F DB $1E
HGRHI+$70 DB $03
HGRHI+$71 DB $07
HGRHI+$72 DB $0B
HGRHI+$73 DB $0F
HGRHI+$74 DB $13
HGRHI+$75 DB $17
HGRHI+$76 DB $1B
HGRHI+$77 DB $1F
HGRHI+$78 DB $03
HGRHI+$79 DB $07
HGRHI+$7A DB $0B
HGRHI+$7B DB $0F
HGRHI+$7C DB $13
HGRHI+$7D DB $17
HGRHI+$7E DB $1B
HGRHI+$7F DB $1F
HGRHI+$80 DB $00
HGRHI+$81 DB $04
HGRHI+$82 DB $08
HGRHI+$83 DB $0C
HGRHI+$84 DB $10
HGRHI+$85 DB $14
HGRHI+$86 DB $18
HGRHI+$87 DB $1C
HGRHI+$88 DB $00
HGRHI+$89 DB $04
HGRHI+$8A DB $08
HGRHI+$8B DB $0C
HGRHI+$8C DB $10
HGRHI+$8D DB $14
HGRHI+$8E DB $18
HGRHI+$8F DB $1C
HGRHI+$90 DB $01
HGRHI+$91 DB $05
HGRHI+$92 DB $09
HGRHI+$93 DB $0D
HGRHI+$94 DB $11
HGRHI+$95 DB $15
HGRHI+$96 DB $19
HGRHI+$97 DB $1D
HGRHI+$98 DB $01
HGRHI+$99 DB $05
HGRHI+$9A DB $09
HGRHI+$9B DB $0D
HGRHI+$9C DB $11
HGRHI+$9D DB $15
HGRHI+$9E DB $19
HGRHI+$9F DB $1D
HGRHI+$A0 DB $02
HGRHI+$A1 DB $06
HGRHI+$A2 DB $0A
HGRHI+$A3 DB $0E
HGRHI+$A4 DB $12
HGRHI+$A5 DB $16
HGRHI+$A6 DB $1A
HGRHI+$A7 DB $1E
HGRHI+$A8 DB $02
HGRHI+$A9 DB $06
HGRHI+$AA DB $0A
HGRHI+$AB DB $0E
HGRHI+$AC DB $12
HGRHI+$AD DB $16
HGRHI+$AE DB $1A
HGRHI+$AF DB $1E
HGRHI+$B0 DB $03
HGRHI+$B1 DB $07
HGRHI+$B2 DB $0B
HGRHI+$B3 DB $0F
HGRHI+$B4 DB $13
HGRHI+$B5 DB $17
HGRHI+$B6 DB $1B
HGRHI+$B7 DB $1F
HGRHI+$B8 DB $03
HGRHI+$B9 DB $07
HGRHI+$BA DB $0B
HGRHI+$BB DB $0F
HGRHI+$BC DB $13
HGRHI+$BD DB $17
HGRHI+$BE DB $1B
HGRHI+$BF DB $1F
          JSR OUTSTR
          ASC "TEMPO       SONG NAME!!"00
          LDY #$00
          JSR OUTSTR
          ASC "  "00
          LDA FILETBL,Y
          BEQ $13F3
          JSR COUT
          JSR OUTSTR
          ASC "  "00
          INY
          JSR PRFILNAM
          JSR CROUT
          INY
          INY
          INY
          BNE $13D3
          JSR PRESSANYKEY
INITCAT   LDA #$00
          STA $05
          STA $06
BADSECT   DS $B0         ; BAD SECTORS TO END
DISKNAME  DS $20         ; 14AC-15CC ZEROED AT STARTUP
FILETBL   DS $100        ; 8x 32 byte entries
          DS $34         ; unused space
