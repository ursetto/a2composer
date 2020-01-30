from invoke import task
from shlex import quote as q

def qq(*L): return " ".join(map(q, L))   # shlex.join, py>=3.8
def j(*L): return " ".join(L)

# A major problem with applecommander is that it returns 0 on error.
# Currently, we run a wrapper for it which converts non-empty stderr to rc=1.

disk = "../../../System 6_0_4 jim.hdv"
prefix = "TFBD/ASM"
filename = 'midi.magic'
origbinfile = 'MIDI-MAGIC.BIN'

fns = []
for ext in '.s', '.e.s', '.x.s', '.t', '.t.txt':
    fns.append(filename + ext)

@task
def precheck(c):
    import sys
    cmd = c.run("git status -s -uno " + qq(*fns))
    if cmd.stdout:
        sys.exit(1)

@task(precheck)
def commit(c):
    c.run("git add " + qq(*fns))
    c.run("git commit -uno -m 'Update asm files'")  # note: returns rc=1 if no changes

@task(pre=[precheck], post=[commit])
def pull(c):
    print("Pulling from disk image...")
    for fn in fns:
        qsrc = q(prefix + '/' + fn)
        qfn = q(fn)
        if fn.endswith('.t'):
            c.run(f"./ac -g {q(disk)} {qsrc} > {qfn}")
            c.run(f"./tfbd.py decode {qfn} > {qfn}.txt")
            # template files can be read by clearing high-bit, but it does not
            # work in the other direction
        elif fn.endswith('.t.txt'):
            pass
        else:
            c.run(f"./ac -e {q(disk)} {qsrc} > {qfn}")

        #c.run("./ac -e " + qq(disk, prefix + '/' + fn) + " > " + q(fn))
        #c.run(j("./ac", "-e", qq(disk, prefix + '/' + fn), ">", q(fn)))
        #c.run("./ac -e {disk} {src} > {dst}".format(
        #    disk=q(disk), src=q(prefix + '/' + fn), dst=q(fn)))

@task
def push(c):
    # Note: pushing is currently pointless. TFBD does not use the .S files, only
    # the .T file, and we cannot decode/encode the .T file to change it.
    # .T file is type $5E, auxtype $8002 (in other words:
    #    cadius replacefile ../../../../System\ 6_0_4\ jim.hdv /gsharddrive/tfbd/asm MX.T\#5E8002
    print("Pushing to disk image...")
    for fn in fns:
        dst = prefix + '/' + fn
        if fn.endswith('.t') or fn.endswith('.t.txt'):
            print("Skipping template file")
            pass
        else:
            # c.run(f"./ac -pt {q(disk)} {q(dst)} {q(fn)}")
            # c.run("./ac -pt " + qq(disk, dst, fn))
            # c.run(f"./ac -pt {qq(disk, dst, fn)}")
            c.run(qq("./ac", "-pt", disk, dst, fn))

@task
def build(c):
    c.run(f'merlin32 -V /usr/local/opt/merlin32/lib {filename}.all.s')
    c.run(f'cmp {filename}.all {origbinfile}')

@task
def mcat(c):
    c.run('merlin32 -V /usr/local/opt/merlin32/lib mcat.s')
    c.run('applecommander -d "midi magic remix.dsk" mcat')                  # kinda dumb -- ignore errors
    c.run('./ac -p "midi magic remix.dsk" mcat B 0x13fc < mcat')
