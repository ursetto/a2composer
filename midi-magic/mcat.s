* CATALOG routines - Beneath Apple DOS, PDF page 109
* File descriptive entry format - Beneath Apple DOS, PDF page 41

* Issues: BRUN crashes (tries to read empty sector 11 0D)
* Note: clear $48 after RWTS call to avoid corrupting P flag and setting decimal mode,
*       which will break everything (even ROM calls), when debugging with monitor.

BUFPTR      equ $9600         ; buffer 3, typically unused
IOB         equ $B7E8
IOB_VOL     equ IOB + 3
IOB_TRACK   equ IOB + 4
IOB_SECTOR  equ IOB + 5
IOB_BUFR    equ IOB + 8
IOB_CMD     equ IOB + $C
IOB_ERR     equ IOB + $D
CAT         equ BUFPTR
CAT_TRACK   equ CAT + 1
CAT_SECTOR  equ CAT + 2
CAT_FDIDX   equ $0B           ; first file descriptive entry in catalog sector
FD_TRACK    equ BUFPTR + 0    ; immediate index into FILEDESC
FD_NAME     equ BUFPTR + 3    ; immediate index into FILEDESC
RWTS        equ $03D9         ; or direct to $B7B5
PRBYTE      equ $FDDA
CROUT       equ $FD8E
COUT        equ $FDED

* Warning: Although Wagner's Assembly Lines says file buffer 3 is
* typically unused, IOB_BUFR is actually $9600 at DOS boot time, 
* implying it is in use.
TRK         equ $05           ; track to read in READSECT
SECT        equ $06           ; sector to read in READSECT
FDIDX       equ $07           ; index to current file descriptive entry

        org $13FC

* Read VTOC sector.
START
        lda #$11
        sta TRK
        lda #$00
        sta SECT
        jsr READSECT
        bcc READCAT
        brk
READCAT
        lda CAT_TRACK      ; track/sector at same offset in VTOC and CAT
        beq :end
        ldy CAT_SECTOR
        sta TRK            ; don't really need this indirection
        sty SECT           ; but it's useful for debugging
        jsr READSECT
        bcc :readfiles
        brk

* Note: DOS CATALOG exits if it encounters a filename descriptor
* entry with track == 0.  The catalog is initialized to
* 15 empty blocks all linked together, and deleted files are
* flagged with $FF (not zeroed), so traversing the whole
* catalog is wasteful.

:readfiles
        ldx #CAT_FDIDX
        stx FDIDX
:readname
        lda FD_TRACK,x
        beq :end                ; available entry -- end of catalog
        bmi :nxtfile            ; deleted file, ignore
        ldy #30
:nxtchr lda FD_NAME,x           ; indexed from start of struct
        jsr COUT
        inx
        dey
        bne :nxtchr
        jsr CROUT
:nxtfile 
        clc
        lda FDIDX
        adc #$23                ; next file descriptive entry
        beq READCAT             ; end of sector
        tax
        stx FDIDX
        jmp :readname
:end    rts

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
        lda #$00            ; zero RWTS scratch byte to avoid trashing P flag
        sta $48             ; via monitor... only needed when debugging
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
        jsr CROUT
        rts
