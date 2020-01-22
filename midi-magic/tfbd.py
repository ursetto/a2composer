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
        print(f'# Total {record_count} records')
        
        section_2x = decode_2x(f)
        section_4x = decode_4x(f)
        section_6x = decode_6x(f)


def decode_2x(f):
    # TODO: Properly compute ORG offset
    (section_count, ) = read_unpack(f, "<H")
    print(f"# 2x section ({section_count} records)")
    for i in range(section_count):
        (rtype, var_len, offset, area_len) = read_unpack(f, "<BBIH")
        assert (rtype & 0xf0) == 0x20
        if rtype == 0x29:
            assert var_len == 0
            print(f"ASC ORG+${offset:04x}, ${area_len:02x}")
        elif rtype == 0x23:
            assert var_len == 0
            print(f"DA  ORG+${offset:04x}, ${area_len:02x}")
        else:
            print(f"{rtype:02x} {var_len:02x} {offset:08x} {area_len:04x}")


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
            print(f"EQU ${address:04x}, {var_data}")
        elif rtype == 0x40:
            # No idea what count field does. Seen 1, 2, 3, 9, $c.
            print(f"LAB ORG+${address:04x}, {var_data}         # {count:04x}")
        else:
            print(f"{rtype:02x} {var_len:02x} {address:08x} {count:04x} {var_data}")


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
            # ARG resembles a IIGS slow ram addr E0/XXXX here.
            print(f"COM ORG+${offset:04x}, {var_data}        # {arg:08x}")
        elif rtype == 0x61:
            assert count == 1
            assert var_len == 0
            print(f"MX ORG+${offset:04X}, %{arg:02x}")
        elif rtype == 0x60:
            assert var_len == 0
            print(f"ORG +${offset:04x}, ${arg:04x}, L${count:04x}")

            
        else:
            print(f"{rtype:02x} {var_len:02x} {offset:08x} {count:08x} {arg:08x} {var_data}")
            



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
