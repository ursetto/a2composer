empty.t -- empty template, with a file of length $0E00 loaded at $0800.
L03EA.t -- `EQU $03EA,L03EA` -- note the file record has disappeared, this randomly happens
L03EA2.T -- `EQU $03EA,L03EA` with the file A$0800,L$0E00 loaded
L03EACOUT.t -- `EQU $03EA,L03EA`, `EQU $FDED,COUT`
MX.t -- L03EACOUT.t + `MX $0800,%11`
MX2.t -- MX.T +  `MX $0803,%11`
tclr.t -- template after tclr -- 8 zero bytes


File format
-----------

The template files essentially contain lists of commands and arguments,
separated into 3 sections. They are compressed into a bytecode and probably
stored the same way in memory.  Within a section, commands are not really
sorted by address or type, but probably just by order inputted.

The story so far:

    2 bytes, total number of records
    2 bytes, number of records in 2x (definitions) section [
        1 byte, record type
        1 byte, record variable len
        4 bytes, offset
        2 bytes, length of area
    ]
    2 bytes, number of records in 4x (labels) section [
        1 byte, record type
        1 byte, record variable len
        4 bytes, record data (perhaps always address)
        2 bytes, record count (??)
        Optional counted string
    ]
    2 bytes, number of records in 6x (directives) section [
        1 byte, record type
        1 byte, record variable len
        4 bytes, offset
        4 bytes, count (??)
        4 bytes, argument (?)
        Optional counted string
    ]
 ]

All records in the same section seem to have a fixed header length,
and if their len byte is non-zero, are followed by a counted string.

If a particular section has 0 records, it is still present,
and collapsed to 0000 (its number of records).


# note: empty file seems to have a "number of records of next type" as 0,
# followed by 1 record of type 60
# note: total number of records looked like 4 bytes, because second pair
# is often zero, but later I found 7F00 3000 2900 which seems to mean 
# 127 records total, now 48 of type $29

Seems like 40 & 44 count as same type for purpose of "number of records of next type".
So do 60 & 61. May take the top 4 bits of the type, with bottom benig the subtype?


type/len:

    23 00 OFFSET32 LEN16               -- DA ORG+OFFSET32, LEN16
    29 00 OFFSET32 LEN16               -- ASC ORG+OFFSET32, LEN16 (max len = $27)
    40 NN ADDR32 XXXX NN LABEL        -- LAB ADDR32, LABEL            (XXXX usually $0001, have seen $0002 & 3)
    44 NN ADDR32 XXXX NN LABEL        -- EQU ADDR32, LABEL
    60 00 0000 0000 LEN32 ORG32         -- ORG or file info?
    61 00 / 03 00 / 00 00 / 01 00 / 00 00 / 11 00 / 00 00     -- MX $803, %11     (when file addr is $800)
    66 NN OFFSET32 CNT16? / 00 00 / XXXX / X0 00 / NN / COMMENT    -- COM

