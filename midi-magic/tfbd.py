#!/usr/bin/env python3

import argparse
import struct


def read_unpack(f, fmt):
    return struct.unpack(fmt, f.read(struct.calcsize(fmt)))
        

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
        if var_len != 0:
            assert var_len == read_unpack(f, "<B")[0]
            (var_data, ) = struct.unpack(f'{var_len}s', f.read(var_len))
            var_data = bytes(map(lambda x: x & 0x7f, var_data))
            var_data = var_data.decode('ascii')
        if rtype == 0x44:
            print(f"EQU ${address:04x}, {var_data}")
        else:
            print(f"{rtype:02x} {var_len:02x} {address:08x} {count:04x} {var_data}")


def decode_6x(f):
    pass


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
