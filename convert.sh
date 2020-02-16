#!/bin/sh

set -e
cd $(dirname $0)/midi
for i in ../roll/^*; do
    ../qrs2midi.py "$i"
done
