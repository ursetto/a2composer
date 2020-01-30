
BUFPTR      equ $9600         ; buffer 3, typically unused
IOB         equ $B7E8
IOB_VOL     equ IOB + 3
IOB_TRACK   equ IOB + 4
IOB_SECTOR  equ IOB + 5
IOB_BUFR    equ IOB + 8
IOB_CMD     equ IOB + $C
IOB_ERR     equ IOB + $D
VTOC        equ BUFPTR
VTOC_TRACK  equ VTOC + 1
VTOC_SECTOR equ VTOC + 2
RWTS        equ $03D9         ; or direct to $B7B5
PRBYTE      equ $FDDA
COUT        equ $FDED

* Warning: Although Wagner's Assembly Lines says file buffer 3 is
* typically unused, IOB_BUFR is actually $9600 at DOS boot time, 
* implying it is in use.
TRK         equ $05
SECT        equ $06

        org $13FC

* Read VTOC sector.
        lda #$11
        sta TRK
        lda #$00
        sta SECT
        jsr READSECT
        bcc :cont
        brk
:cont
        lda VTOC_TRACK
        ldy VTOC_SECTOR
* read catalog sector A,Y and 
:cat    sta TRK            ; don't really need this indirection
        sty SECT           ; but it's useful for debugging
        jsr READSECT
        bcc :read
        brk
:readname
* Here we should process all filenames in this catalog sector,
* then fall through to this code.

        ldy VTOC_SECTOR
        lda VTOC_TRACK
        bne :cat           ; fixme -- unknown end condition
        rts


* Use standard DOS IOB which is already set up to
* refer to the current slot and drive. We only need
* to set track, sector, buffer and command (read).
* Volume is also set to 0 (any) because I've seen the
* default be FF (invalid).
* Input: TRK, SECT  Output: A = err (if carry set).
READSECT
        jsr PRTRKSEC       ; debugging

        lda TRK
        sta IOB_TRACK
        lda SECT
        sta IOB_SECTOR
        lda #$00           ; any volume
        sta IOB_VOL
        lda #<BUFPTR
        sta IOB_BUFR
        lda #>BUFPTR
        sta IOB_BUFR+1
        lda #$01
        sta IOB_CMD
        ldy #<IOB
        lda #>IOB
        jsr RWTS
        bcc :end
        lda IOB_ERR
:end    rts

PRTRKSEC
        lda TRK
        jsr PRBYTE
        lda #" "
        jsr COUT
        lda SECT
        jsr PRBYTE
        lda #$8D
        jsr COUT
        rts
        
