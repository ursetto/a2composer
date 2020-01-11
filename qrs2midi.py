#!/usr/bin/env python

from __future__ import print_function
import os
from pprint import pprint as pp
import argparse

def decode_file_to_bytes(f):
    # type: file -> bytes or bytearray (really an integer iterable)
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

def encode_ir_to_midi(ir):
    raise NotImplementedException

ap = argparse.ArgumentParser()
ap.add_argument('filename')
ap.add_argument('--offset', type=int, default=0x40)
args = ap.parse_args()

with open(args.filename, "rb") as f:
    pp(decode_qrs_to_ir(f, args.offset))
