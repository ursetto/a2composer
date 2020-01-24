#!/usr/bin/env python3

import argparse
import struct


def read_unpack(f, fmt):
    return struct.unpack(fmt, f.read(struct.calcsize(fmt)))
        

def apple_to_ascii(a2str):
    bytestr = bytes(map(lambda x: x & 0x7f, a2str))
    return bytestr.decode('ascii')


def decode(args):
    with open(args.filename, 'rb') as f:
        (record_count, ) = read_unpack(f, '<H')
        print(f'# TFBD ({record_count} records total)')
        
        decode_2x(f)
        decode_4x(f)
        decode_6x(f)


def decode_2x(f):
    # TODO: Properly compute ORG offset
    (section_count, ) = read_unpack(f, "<H")
    print(f"# 2x section ({section_count} records)")
    for i in range(section_count):
        (rtype, var_len, offset, area_len) = read_unpack(f, "<BBIH")
        assert (rtype & 0xf0) == 0x20
        if rtype == 0x20:
            assert var_len == 0
            print(f"DB  +${offset:04X}, ${area_len:02X}")
        elif rtype == 0x21:
            assert var_len == 0
            print(f"DW  +${offset:04X}, ${area_len:02X}")            
        elif rtype == 0x23:
            assert var_len == 0
            print(f"DA  +${offset:04X}, ${area_len:02X}")
        elif rtype == 0x28:
            assert var_len == 0
            print(f"DS  +${offset:04X}, ${area_len:02X}")
        elif rtype == 0x29:
            assert var_len == 0
            print(f"ASC +${offset:04X}, ${area_len:02X}")
        else:
            print(f"{rtype:02X} {var_len:02X} {offset:08X} {area_len:04X}")


def decode_4x(f):
    # TODO: Properly compute ORG offset
    (section_count, ) = read_unpack(f, "<H")
    print(f"# 4x section ({section_count} records)")

    for i in range(section_count):
        (rtype, var_len, address, count) = read_unpack(f, "<BBIH")
        var_data = b''
        assert (rtype & 0xf0) == 0x40
        if var_len != 0:   # FIXME: abstract this
            assert var_len == read_unpack(f, "<B")[0]
            (var_data, ) = struct.unpack(f'{var_len}s', f.read(var_len))
            var_data = apple_to_ascii(var_data)
    
        if rtype == 0x44:
            assert count == 1
            print(f"EQU  ${address:04X}, {var_data}")
        elif rtype == 0x40:
            # Count field appears to be either the length of the instruction
            # at the label, or the length of the data (constant) at the label.
            # For example it will be 3 at LDA $1234, and $C0 at :DB addr,C0.
            # It is not known whether this needs to be accurate in the file,
            # or if it's just a memory dump, like the :COM arg pointer.
            print(f"LAB +${address:04X}, {var_data}         # {count:04X}")
        else:
            print(f"{rtype:02X} {var_len:02X} {address:08X} {count:04X} {var_data}")


def decode_6x(f):
    (section_count, ) = read_unpack(f, "<H")
    print(f"# 6x section ({section_count} records)")

    for i in range(section_count):
        # Don't know what count is nor if it's an int or 2 shorts.
        # Don't know what ARG is.
        (rtype, var_len, offset, count, arg) = read_unpack(f, "<BBIII")
        var_data = b''
        assert (rtype & 0xf0) == 0x60
        if var_len != 0:   # FIXME: abstract this
            assert var_len == read_unpack(f, "<B")[0]
            (var_data, ) = struct.unpack(f'{var_len}s', f.read(var_len))
            var_data = apple_to_ascii(var_data)

        if rtype == 0x66:
            assert count == 1
            # ARG resembles a IIGS slow ram addr E0/XXXX here. I suspect it
            # is a pointer to live memory and will be ignored -- it is
            # randomly updated after a save/load cycle.
            print(f"COM +${offset:04X}, {var_data}")  # # {arg:08X}")
        elif rtype == 0x61:
            assert count == 1
            assert var_len == 0
            print(f"MX  +${offset:04X}, %{arg:02X}")
        elif rtype == 0x60:
            assert var_len == 0
            print(f"ORG +${offset:04X}, ${arg:04X}, L${count:04X}")
        else:
            print(f"{rtype:02X} {var_len:02X} {offset:08X} {count:08X} {arg:08X} {var_data}")


def parse_args():
    ap = argparse.ArgumentParser()

    sp = ap.add_subparsers()
    sp_command = sp.add_parser('decode')
    sp_command.add_argument('filename')
    sp_command.set_defaults(func=decode)

    return ap.parse_args()


def main():
    args = parse_args()
    args.func(args)


if __name__ == '__main__':
    main()
