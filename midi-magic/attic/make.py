#!/usr/bin/env python3

from plumbum import local, FG
from plumbum.commands.processes import ProcessExecutionError

disk = "../../../System 6_0_4 jim.hdv"
prefix = "TFBD/ASM"

# A major problem with applecommander is that it returns 0 on error. We formerly
# checked its stderr non-empty here. Currently, we run a wrapper for it which
# converts non-empty stderr to rc=1.
#
# Useful things that `make` provides: echoing of commands, basic shell syntax, dry run, and running
# tasks by name. Outside of make, I have to implement these every time, or they don't fit well with the goals 
# of the libraries I'm using, like simplicity of syntax.

fns = ['midi.magic.s', 'midi.magic.e.s', 'midi.magic.x.s']

#for fn in fns:
#    cmd = applecommander['-e', disk, prefix + '/' + fn] > fn
#    (rc, stdout, stderr) = cmd.run()
#    if stderr:
#        # not quite right, quoting-wise
#        raise ProcessExecutionError(cmd.formulate(), rc, stdout, stderr)

applecommander = local["./ac"]
for fn in fns:
    cmd = applecommander['-e', disk, prefix + '/' + fn] > fn
    cmd()    # FG works, but stderr appears outside the error message.

