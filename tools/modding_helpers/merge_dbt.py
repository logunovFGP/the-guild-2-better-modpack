"""Three-way merge for a UTF-16 .dbt table, which git refuses to merge itself.

    python tools/modding_helpers/merge_dbt.py <base> <ours> <theirs> [-o OUT]

.gitattributes marks *.dbt as -text, so git treats these tables as binary: any two
commits touching the same table conflict outright, even when they edit rows a
thousand apart. That is every language table in DB/Languages, and it is why a
contribution branch stops rebasing the moment upstream changes one string - a
version bump in row 18000 was enough to conflict two open merge requests.

They are not really binary. They are UTF-16LE with a BOM and CRLF endings, and
decoded they are ordinary line-oriented text, so git's own merge handles them
correctly. This decodes the three sides, hands them to `git merge-file`, and
re-encodes the result: byte-identical to the input when nothing changed, and a
normal conflicted file (with <<<<<<< markers) when two sides really do edit the
same row.

Rows must not be sorted or re-keyed on the way through: Text.dbt is not strictly
ascending by id and does contain duplicate ids (18549 and 20458 as of 1.70), so
anything that rebuilds the table from a dict silently drops rows. This only ever
reorders nothing - it is a line merge, like git's own.

Use it during a rebase, once git has staged the three sides:

    git show :1:DB/Languages/Text.dbt > /tmp/base.dbt
    git show :2:DB/Languages/Text.dbt > /tmp/ours.dbt
    git show :3:DB/Languages/Text.dbt > /tmp/theirs.dbt
    python tools/modding_helpers/merge_dbt.py /tmp/base.dbt /tmp/ours.dbt /tmp/theirs.dbt \\
        -o DB/Languages/Text.dbt
    git add DB/Languages/Text.dbt

During a rebase, :2 is the commit being replayed onto and :3 is your commit, so
naming them "ours"/"theirs" reads backwards; it makes no difference to the merge,
only to which side a conflict marker labels.

Exit 0 when the merge was clean, 1 when it conflicted (the output still holds the
markers, as git merge-file leaves them), 2 on a usage or encoding error.
"""
import argparse
import os
import subprocess
import sys
import tempfile

BOM_LE = b"\xff\xfe"
BOM_BE = b"\xfe\xff"


def decode(path):
    """A .dbt as text. Refuses anything without a UTF-16 BOM: writing a mangled table
    back over a language file is worse than stopping."""
    raw = open(path, "rb").read()
    if not raw.startswith((BOM_LE, BOM_BE)):
        sys.exit("%s: not a UTF-16 .dbt (no BOM); refusing to guess its encoding" % path)
    return raw.decode("utf-16")


def encode(text):
    return BOM_LE + text.encode("utf-16-le")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("base")
    ap.add_argument("ours")
    ap.add_argument("theirs")
    ap.add_argument("-o", "--out", help="default: overwrite OURS")
    args = ap.parse_args(argv)

    tmp = tempfile.mkdtemp(prefix="dbt-merge-")
    try:
        side = {}
        for name in ("base", "ours", "theirs"):
            p = os.path.join(tmp, name)
            # newline="" so the CRLF endings survive into the text merge unchanged
            open(p, "w", encoding="utf-8", newline="").write(decode(getattr(args, name)))
            side[name] = p
        r = subprocess.run(["git", "merge-file", "--stdout",
                            "-L", "ours", "-L", "base", "-L", "theirs",
                            side["ours"], side["base"], side["theirs"]],
                           capture_output=True)
        if r.returncode < 0:
            sys.exit("git merge-file failed: %s" % r.stderr.decode("utf-8", "replace"))
        out = args.out or args.ours
        open(out, "wb").write(encode(r.stdout.decode("utf-8")))
        if r.returncode == 0:
            print("clean: %s" % out)
            return 0
        print("CONFLICT: %d hunk(s) need a decision, markers left in %s"
              % (r.returncode, out), file=sys.stderr)
        return 1
    finally:
        for f in os.listdir(tmp):
            os.remove(os.path.join(tmp, f))
        os.rmdir(tmp)


if __name__ == "__main__":
    sys.exit(main())
