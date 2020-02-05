#!/usr/bin/env python

from __future__ import print_function

from pprint import pprint as pp
import argparse
import sys


def decode_file_to_bytes(f):
    # type file -> bytes or bytearray (really an integer iterable)
    data = f.read()
    if isinstance(data, str):    # py2 compat
        data = bytearray(data)
    return data


def decode_qrs_to_ir(f, offset):
    """Decode a QRS piano roll file to an intermediate representation,
    which is a list of pairs ["instruction", value]. Valid instructions
    are "wait" (delay for n ticks), "on" (note on), "off" (note off). 
    If an illegal byte is detected, it is included as instruction "???".
    """
    class State(object):
        data = 0             # normal input
        message = 1          # message byte 0xFF encountered

    f.seek(offset)
    data = decode_file_to_bytes(f)
    state = State.data
    ir = []

    for byte in data:
        if state == State.message:
            if byte == 0xff:
                return ir
            else:
                ir.append(["wait", byte])
                state = State.data
        elif byte == 0xff:
            state = State.message
        elif byte >= 0x24 and byte <= 0x60:
            ir.append(["on", byte])
        elif byte >= (0x24 | 0x80) and byte <= (0x60 | 0x80):
            ir.append(["off", byte & 0x7f])
        else:
            ir.append(["???", byte])
    return ir


def encode_ir_to_midi(ir, filename, tempo=94):
    import midi
    # Instantiate a MIDI Pattern (contains a list of tracks)
    pattern = midi.Pattern()
    # Instantiate a MIDI Track (contains a list of MIDI events)
    track = midi.Track()
    # Append the track to the pattern
    pattern.append(track)

    tick = 0
    velocity = 70
    # 5.55 divisor is pretty accurate for CHORUS LINE MEDLEY and RHAPSODY IN BLUE.
    # Speed may vary during song -- perhaps Apple is slower when more
    # notes are played? CALL ME IRRESPONSIBLE is not quite as accurate,
    # nor is DO YOU THINK I'M SEXY (which is also corrupt).
    delay = tempo / 5.55              # 5.5 too slow, 5.75 too fast, 5.6 *slightly* too fast
    
    for inst in ir:
        op, val = inst
        if op == 'wait':
            # Default tempo (^) = 94
            # Other tempo (H) = 72
            # Tempo is actually just delay time, so is probably a straight division
            # Perhaps multiplier = tempo / 4 is a good start
            tick = int(round(val * delay))   # delay is about 15 for my stuff, about 25 for theirs
        elif op == 'on':
            track.append(midi.NoteOnEvent(tick=tick, velocity=velocity, pitch=val))
            tick = 0
        elif op == 'off':
            track.append(midi.NoteOffEvent(tick=tick, pitch=val))
            tick = 0
                         
    track.append(midi.EndOfTrackEvent(tick=tick))

    # Save the pattern to disk
    midi.write_midifile(filename, pattern)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('filename')
    ap.add_argument('--offset', type=int, default=0x40)
    ap.add_argument('--tempo', type=int)    # no default here
    args = ap.parse_args()

    tempo = 94
    if args.tempo:
        tempo = args.tempo
    elif args.filename[0] == '^':
        tempo = ord(args.filename[1])

    with open(args.filename, "rb") as f:
        print("Transcoding to " + args.filename + ".mid, tempo " + str(tempo), file=sys.stderr)
        ir = decode_qrs_to_ir(f, args.offset)
        # pp(ir)
        encode_ir_to_midi(ir, args.filename + '.mid', tempo)

if __name__ == '__main__':
    main()
