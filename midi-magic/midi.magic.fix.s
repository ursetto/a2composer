* CATALOG routines - Beneath Apple DOS, PDF page 109
* File descriptive entry format - Beneath Apple DOS, PDF page 41

* Note: clear $48 after RWTS call to avoid corrupting P flag and setting decimal mode,
*       which will break everything (even ROM calls), when debugging with monitor.
* Note: this ungracefully executes a BRK on disk error.
* Note: can be built standalone for testing.

* Debugging output (track/sector read info) will appear on loading screen
* because the entire catalog is reread when loading every file (MIDI-MAGIC $0E22). 
* So debug should be disabled for production build, and maybe this odd reread
* should be commented out.
DEBUG       equ 0             ; debugging output

* Although Wagner's Assembly Lines says file buffer 3 is typically 
* unused, IOB_BUFR is actually $9600 at DOS boot time. It seems to
* work fine though.
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
REENTRY     equ $03D0
PRBYTE      equ $FDDA

FDIDX       equ $07           ; index to current file descriptive entry
FNCNT       equ $08           ; chars processed in current filename
YSAV        equ $09

PRTRKSEC MAC
        DO DEBUG
        jsr PRBYTE      ; A=track
        tya
        jsr PRBYTE      ; Y=sector
        jsr $FD8E       ; CROUT -- avoid dup equate
        FIN
        <<<

        org $13F6

INITCAT
* Read VTOC sector.
        lda #$11
        ldy #$00
        jsr READSECT
        ldy #0             ; init FILETBL index
        bcc READCAT
        brk
READCAT
        sty YSAV           ; save FILETBL index thru READSECT -- use zp as READSECT returns err in A
        lda CAT_TRACK      ; track/sector at same offset in VTOC and CAT
        beq :end
        ldy CAT_SECTOR
        jsr READSECT
        ldy YSAV
        bcc :readfiles
        brk

* Like DOS, exit when an entry with track == 0 is encountered.
* Deleted files are flagged (not zeroed) so there will never be a hole.
* At INIT time a linked list of 15 empty blocks is generated;
* reading null entries is slow and unnecessary.

* X is index into file buffer (file descriptive entry or FDE) and
* Y is index into filename table. FDE and filename are different lengths
* so we use two indices. The number of filename chars copied is kept
* in a temp var as both indices are in use.
* (File buffer is fixed address so we can use Absolute,X. We could use
* Indirect,Y for both at the cost of extra bookkeeping.)

:readfiles
        ldx #CAT_FDIDX
        stx FDIDX

* On entry, X is the first byte of the current FDE n, i.e. $0B + (35 * n).
* Y is first byte of filename entry (32 * fn).
* Terminate when X=0 (end of this file buffer). Treat FILETBL as a ring
* buffer, wrapping around after 8 ^ files, as @ file may occur afterward.

:readname
        lda FD_TRACK,x          ; BUFPTR + CAT_FDIDX + (35*N)
        beq :end                ; available entry -- end of catalog
        bmi :nxtfile            ; deleted file, ignore

        lda #29
        sta FNCNT

        lda FD_NAME,x           ; check first char
        inx
        cmp #"@"
        beq :atfile
        cmp #"^"
        bne :nxtfile

:nxtchr lda FD_NAME,x           ; BUFPTR + CAT_FDIDX + (35*N) + 3
        sta FILETBL,y
        inx
        iny
        dec FNCNT
        bne :nxtchr

        lda #$8D
        sta FILETBL,y
        iny
        iny                     ; wrap to y=0 is ok
        iny
:nxtfile 
        clc
        lda FDIDX
        adc #$23                ; next file descriptive entry
        beq READCAT             ; end of sector
        tax
        stx FDIDX
        jmp :readname           ; bne might work
:end    rts   ; jmp REENTRY             ; instead of RTS to safely BRUN

* Handle @ file. Similar to nxtchr but reimplement due to fixed address.

:atfile 
        sty YSAV
        ldy #0
:nxtat
        lda FD_NAME,x           ; BUFPTR + CAT_FDIDX + (35*N) + 3
        sta DISKNAME,y
        inx
        iny
        dec FNCNT
        bne :nxtat

        lda #$8D
        sta DISKNAME,y
        ldy YSAV
        jmp :nxtfile            ; always

* Use standard DOS IOB which is already set up to
* refer to the current slot and drive. We only need
* to set track, sector, buffer and command (read).
* Volume is also set to 0 (any) because I've seen the
* default be FF (invalid).
* Input: A=trk, Y=sector  Output: A = err (valid if carry set), Y=?
READSECT
        sta IOB_TRACK
        sty IOB_SECTOR

        PRTRKSEC

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
        lda IOB_ERR
        rts

* Fill remaining space until DISKNAME at $14AC. If we overran available space,
* Merlin32 will SIGBUS (lol).

        ds $14AC - *

DISKNAME  DS $20         ; 14AC-15CC ZEROED AT STARTUP
FILETBL   DS $100        ; 8x 32 byte entries

* $34 bytes at end of MIDI-MAGIC are either unused or used for something
* we don't need, so omit them. This saves 1 sector as the original was 4
* bytes over.
;          DS $34         ; unused space
