COMPOSER
========

Found on the QRS MIDI-MAGIC demo disk, COMPOSER is a simple composition program
I wrote that generates files compatible with the MIDI MAGIC piano roll
interface. It can also call into the MIDI-MAGIC driver to play files from
BASIC.  It's possible I reverse-engineered the file format given that this was 
just a demo disk, that there are multiple iterations of my data files at 
different load addresses with and without headers, and that I was
generally pretty desperate. However the tempo variable and the entry points for 
playing a song would have been far too complex for me, and the valid note range
too hard to determine accurately. So, I suspect they provided a bit of documentation
for hackers.

The original disk is somewhat corrupt; the full extent is unknown but the MIDI-MAGIC driver
does not run and some of the COMPOSER versions do not load or have problems during extraction.
This could extend to the music files themselves but that is impossible to test.
Fortunately a full copy of COMPOSER is available on the backup disk /DOUBLEDOS.

The intent of this project is to recover as much data as possible, decode the file formats,
and convert them to MIDI files.


Files
-----

    COMPOSER2.BAS -- Expects loaded files at $4000; BSAVEs without header (at $4040). Music data starts with FF 0A. Accepts notes like C0, A#3, B5. Stops notes by numeric value.
    COMPOSER3.BAS -- Relocates to $3000. Loads and saves files without header at $5000. Music data starts with FF 0A 00. Sets $99b to $50 and $997 to $00 (to tell driver where data is). Adds hidden Adjust Tempo option (8). Stops notes by name.
    COMPOSER4.BAS -- Sets $4FBD..4FBF to 0. This corresponds exactly in location to this file's 00 00 00 end of BASIC file signature (!!) -- perhaps a workaround for the end of file corruption plaguing these programs. Removed in COMPOSER6.
    COMPOSER5.BAS -- lost
    COMPOSER6.BAS -- Relocates to $4000, expects files at $5000, data at $503F ($99b,$997 = $503F). Note default data location in driver is $403F (not $4040). If filename does NOT begin with "^^", playback starts at $5000. Saves with header. Note parsing looks buggy due to use of MID$: octave will always be 0 for sharps. Tempo is at $4038 instead of $5038, which is a bug and explains why the header REMs have a control character at file offset $37 -- BASIC area is corrupted at runtime.
    MIDI-MAGIC.BIN -- serial port midi driver and piano roll file player. Crashes on BRUN.

DO YOU THINK I'M SEXY -- file looks corrupt at offset $20FC, modifying this to FF FF should allow it
to play up to that point.

Recovery
--------

- COMPOSER6.BAS was recovered from /DOUBLEDOS, but was a slightly earlier (non-working) version.
  We recovered it by repairing the file length and setting last line pointer to NULL. See Notes below.
- COMPOSER3 and COMPOSER4 were also recovered by repairing the files. Note that COMPOSER4 contains what looks like self-repairing code to fix this at runtime!
- MIDI-MAGIC looks like it has bad sectors ($00 bytes) from $0BFE - $0DFF, in the middle of code.
- MIDIMAGIC (from /DOUBLEDOS), is identical to MIDI-MAGIC until $0A00 (and truncated there).

Files in this repository
------------------------

- `COMPOSER2.BAS`: Version 2 of COMPOSER.
- `COMPOSER6.BAS`: Version 6 (latest) of COMPOSER.

Entry points
------------

These are called to play a song.

$097D
$0A36

File format
-----------

Info files are used only by COMPOSER and are not necessary to decode the music. They are TXT files containing 3 integer values: 
 - NT (number of notes entered, excluding rests and note off); completely unused, even for display.
 - NC (byte index of next note)
 - TM (tempo).

### Header

The header on the demo files consists of 64 zero bytes ($4000 - $403F in memory).

We know tempo is stored at $4038. Without looking at the code, my guess is these
locations are used for temporary variables or parameter passing. A few of my files
were saved with some data from $5000-$503F; I can't tell if this is just BASIC file
data that overlapped the music file, other corruption, or whether the driver modified 
it while playing.

### Title

All songs playable by the official player begin with `^`. It appears the second character has meaning, perhaps the tempo. The driver always does a 'BLOAD ^' followed by the rest of the filename.

### Data

Official files start data with FF 0F. My files start with either FF 0F, FF 0A, FF 0F 00 (?), or FF 0A 00 depending
on which version of COMPOSE generated them.  In practice I don't see any existing files with FF 0A 00 which is the signature of COMPOSER6. Furthermore, 00 is an illegal value.

These values don't correspond to MIDI messages. MIDI messages have no DURATION, just NOTE ON and OFF. Note on/off are 3 bytes and include a KEY byte and VELOCITY byte and CHANNEL. In particular, MIDI 0xFF is hard reset.  In fact, it's very strange that there's no VELOCITY or CHANNEL component, and that they chose to use DURATION, which implies a lot of bookkeeping and a list of recently used notes and remaining durations, rather than letting the MIDI hardware take care of it.

#### Data in COMPOSER

Note on is a single byte; NOTENUM.  Note off is a single byte with the high bit set, NOTENUM | 0x80.

A REST (really, a time step) is generated with the pair (FF, DURATION) where DURATION is (arbitrarily?) 20x the number entered as input. Empirically, step values are much higher in COMPOSER than in the official files (often we see steps of 1 or 2, whereas my durations are 10x higher). It is possible setting the tempo too high is too taxing or disallows high polyphony, for the same reason high jiffies used to be a problem in Linux.)

Note numbers (NOTENUM) range from 36 to 96 ($24 to $60) in COMPOSER4, or 36 to 107 ($24 to $6b) in COMPOSER6. 
Note off for a particular NOTENUM is generated by setting bit 7 in NOTENUM.

End of song is represented by (255, 255).

Generally, you issue a sequence of blocks consisting of a time step, note offs and note ons.

#### Data in official files

Official files start with FF 0F and end with FF 0F, likely to produce a nice lead-in and lead-out time.

End of file is always FF FF. There may be a bit of garbage after that.

Note range isn't that high. Observed low of $24 and high of $60 (so note off $A4 - $E0). That corresponds to my COMPOSER4 limits. Since this would have been hard for me to verify at the time, it's plausible that I had a bit of documentation. There is no velocity control--it's a true old-time piano roll.

"DO YOU THINK I'M SEXY" has some assembly language garbage at the end that looks like a tight hardware timing loop. It appears that offset $20FC and later got mixed up with another file.


Notes
-----

COMPOSER relocates itself from $801 to $4001 (via poke 104,64 (0068: 40) +
LOAD). This is because MIDI-MAGIC resides at $800. That's also why music data
files were relocated from $4000 to $5000. (Not sure why we didn't relocate
COMPOSER to $6000 and keep the music files the same; this would have allowed
playing native QRS music files from within COMPOSER.) Even though the file
header apparently has a load address of $4001 on disk, BASIC ignores this and 
will load it at the current value of $67-$68.
- In the earliest version, COMPOSER is at $3001. I'm guessing I moved it to $4001
  to avoid accidentally wiping out the program with HGR.
- COMPOSER6 is $1006 bytes long, and will overlap the start of the music file at $5000!
  If you load a music file, the very end of the BASIC program gets corrupted.

If we had left the music file at $4000, data at $4040 and relocated COMPOSER to $1800, 
we would have plenty of token space and have been able to play official files.

Addresses 174,175 (AF.B0) contain the address + 1 of the last byte of the
Applesoft program currently loaded in memory. Some saved versions of COMPOSER
have either/both of the following problems: the length is 1 less than the correct value,
and the last byte contains a random value instead of 00. In other words, a
BASIC program normally ends in 00 00 00 where 00 is the end-of-statement token and
the 00 00 is a NULL address indicating end of linked list. Instead, COMPOSER6
had 00 0b <EOF>, so Apple Commander fails to load it (out of bounds access as it
expected 00 0b xx), and AppleSoft may fail to LIST based on what's in $xx0b in
memory. To fix this, we LOAD the file, increment the 16-bit address in $AF by 1,
then NULL out the linked list pointer.

    ]LOAD COMPOSER6,D1
    ]CALL-151
    *AF.B0
    00AF: 06
    00B0: 18
    *AF: 07
    *1805: 00 00
    *SAVE COMPOSER6,D2

COMPOSER4 actually writes 00 00 00 to the end of file location in memory at startup time (the address is hardcoded). Obviously, this bit me at the time, but I didn't know how to properly fix it. I'm guessing the music file clobbered the last pointer at some point, then I saved the program. I don't know how the program length was corrupted though.

MIDI conversion
---------------

qrs2midi.py

Driver disassembly
------------------

zp $09 : FILENAME points to current filename (apparently, the character after the first ^). CURSONG*32.
    the first byte is also stored in the SSC_STATUS register (?!)
zp $0B : ISPLAYING bool: 0 if no song playing, $FF if playing (test is for 0)
$303 : CURSONG whatever's here, it's multiplied by 32 and stored in $09. The currently playing
       song, I think.
14ac : a CR-terminated string. may be populated near EOF in the bad sectors.
       Surmising this is "DEMO DISK FOR MIDI MAGIC" obtained by scanning catalog for
       file beginning with "@".
14cc-15cc : a 256-byte (table) containing 8 (?) 32-byte (?) entries.
            Somewhere in here is the current filename.
            This might be a list of all songs on disk.


### Recovery of MIDI-MAGIC

The last 3 sectors of MIDI-MAGIC are on T04,S0D-0F are corrupt as
track 4 is unreadable. Unfortunately there are no copies of this data elsewhere.

    T22,S08 is "unused" but contains a copy of $0AEF-$0B2C of MIDI-MAGIC.
    T16,S00-03 contains deleted or missing COMPOSER stuff
    T16,S04-0D contains valid assembly of an unknown executable, not the driver
    T14,S00-02 contains garbage (?) data
    T13,S03-09 contains deleted for missing COMPOSER stuff
    T08,S06-0A contains deleted for missing COMPOSER stuff (probably COMPOSER2)
    T04 appears destroyed. It contained MIDI-MAGIC and LOGO data.

Further information
-------------------

MIDI MAGIC was apparently written by Bob Kovacs of Microfantics in 1985. QRS Digital probably bought this program for the Apple version of their player piano library.

This disk doesn't appear to be archived anywhere and info is scarce. The player contains this contact information:

    CALL MICROFANTICS INC. (201) 838-5606
    OR WRITE US AT:
    33 ADALIST AVENUE
    BUTLER, NJ 07405

I also found the following at https://homepages.abdn.ac.uk/d.j.benson/pages/html/dx7software.html:

    MICRO W DISTRIBUTING INC
    1342-B Rt. 23, Butler NJ 07405

    MIDI Magic Digital Disks

    Digital music disks from the 10,000 song QRS piano roll library of past and present music. Available for Yamaha and the MIDI DJ sequencer as well as Atari ST, Apple IIC, II+, IIE, Laser 128, Commodore 64/128, PC XT and other popular computers and sequencers. Retail $19.95 (6 song disk), $29.95 (10 song disk). (1988 prices).

