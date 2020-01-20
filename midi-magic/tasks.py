from invoke import task
from shlex import quote as q

def qq(*L): return " ".join(map(q, L))   # shlex.join, py>=3.8
def j(*L): return " ".join(L)

# A major problem with applecommander is that it returns 0 on error.
# Currently, we run a wrapper for it which converts non-empty stderr to rc=1.

disk = "../../../System 6_0_4 jim.hdv"
prefix = "TFBD/ASM"
fns = ['midi.magic.s', 'midi.magic.e.s', 'midi.magic.x.s']

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
        src = prefix + '/' + fn
        c.run(f"./ac -e {q(disk)} {q(src)} > {q(fn)}")
        #c.run("./ac -e " + qq(disk, prefix + '/' + fn) + " > " + q(fn))
        #c.run(j("./ac", "-e", qq(disk, prefix + '/' + fn), ">", q(fn)))
        #c.run("./ac -e {disk} {src} > {dst}".format(
        #    disk=q(disk), src=q(prefix + '/' + fn), dst=q(fn)))

@task
def push(c):
    print("Pushing to disk image...")
    for fn in fns:
        dst = prefix + '/' + fn
        # c.run(f"./ac -pt {q(disk)} {q(dst)} {q(fn)}")
        # c.run("./ac -pt " + qq(disk, dst, fn))
        # c.run(f"./ac -pt {qq(disk, dst, fn)}")
        c.run(qq("./ac", "-pt", disk, dst, fn))


