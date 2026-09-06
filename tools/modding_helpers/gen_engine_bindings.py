"""Recover every engine Lua binding's native address from GuildII.exe.

    python tools/modding_helpers/gen_engine_bindings.py [path-to-GuildII.exe]

Writes meta/engine.bindings.tsv (name, virtual address, whether engine.d.lua
declares it) and prints a cross-reference summary.

Why this exists
---------------
meta/engine.d.lua is scraped from ScriptDocumentation.html, which is incomplete
and in places wrong. The binary is ground truth: the engine registers each Lua
function by pushing its native address and then its name. Walking those call
sites gives the real API surface, which is substantially larger than the dump.

How the walk works
------------------
Each registration compiles to roughly:

    6a 00              push 0
    68 c0 8a 70 00     push 0x708ac0        <- native function
    56                 push esi             <- the binding object ("this")
    e8 9b ea 0f 00     call 0x0081e1f0      <- RegisterFunction
    83 c4 48           add  esp, 0x48       <- optional stack cleanup
    68 f8 4c ae 00     push 0x00ae4cf8      <- "CommitAction"

Three details cost real debugging time and are why the matcher is loose:
  * the "this" pointer is pushed from whichever register the compiler picked,
    so accept any one-byte push (0x50-0x57), not just push esi,
  * a stack cleanup or a register reload can sit between the call and the name
    push, so scan forward a short window instead of demanding adjacency,
  * only accept a name that parses as a Lua identifier, which rejects the
    unrelated string constants that otherwise slip in.

Known gap (~67 declared names are not found this way)
-----------------------------------------------------
Almost all of them are blocking calls that come in Wait/NoWait pairs -- MsgBox,
PlayAnimation, SendCommand, ShowPanel, SquadWait. Their name strings are in
.rdata, so they are registered through a second path this walk does not model,
most likely the one that wraps a call so it can yield. A handful more (f_MoveTo,
f_Follow, StartVision) have no string in the binary at all: those are mod Lua
library functions that the documentation dump lists as if they were engine API.
"""
import os
import re
import struct
import sys

DEFAULT_EXE = r"G:/SteamLibrary/steamapps/common/The Guild 2 Renaissance/GuildII.exe"
DECLARATIONS = os.path.join("meta", "engine.d.lua")
TARGET = os.path.join("meta", "engine.bindings.tsv")

# PE32, fixed image base, no ASLR: file offset + 0x400000 == virtual address.
# (paddr, size, vaddr) for .text, .rdata, .data
SECTIONS = [(0x1000, 0x690000, 0x401000),
            (0x691000, 0x129000, 0xA91000),
            (0x7BA000, 0x3B000, 0xBBA000)]
TEXT_PADDR, TEXT_SIZE, TEXT_VADDR = SECTIONS[0]

# ahead::gamebase Lua binding registrar, found by taking the most common call
# target of the "push imm32; push reg; call" shape inside .text.
REGISTER_FUNCTION = 0x0081E1F0

IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

# Pairs read by hand out of the disassembler. If the matcher ever drifts these
# fail loudly rather than quietly returning a plausible-looking wrong table.
CONTROLS = {
    "CommitAction": 0x708AC0,
    "StopAction": 0x708C40,
    "ActionLock": 0x708D10,
    "IsInLoadingRange": 0x707D00,
    "StartSingleShotParticle": 0x712F90,
    "AliasExists": 0x638FD0,
    "LogMessage": 0x5CC7B0,
}


def offset_to_va(offset):
    for paddr, size, vaddr in SECTIONS:
        if paddr <= offset < paddr + size:
            return vaddr + (offset - paddr)
    return None


def va_to_offset(va):
    for paddr, size, vaddr in SECTIONS:
        if vaddr <= va < vaddr + size:
            return paddr + (va - vaddr)
    return None


def read_identifier(image, va, cap=64):
    """The NUL-terminated string at va, but only if it looks like a Lua name."""
    start = va_to_offset(va)
    if start is None:
        return None
    end = image.find(b"\x00", start, start + cap)
    if end in (-1, start):
        return None
    try:
        text = image[start:end].decode("ascii")
    except UnicodeDecodeError:
        return None
    return text if IDENTIFIER.match(text) else None


def walk(image):
    """Every (name, native address) the registrar is called with, in file order."""
    found = []
    limit = TEXT_PADDR + TEXT_SIZE - 32
    for i in range(TEXT_PADDR, limit):
        # <push reg> <call rel32>, preceded by push imm32
        if image[i + 1] != 0xE8 or not 0x50 <= image[i] <= 0x57:
            continue
        if image[i - 5] != 0x68:
            continue
        relative = struct.unpack_from("<i", image, i + 2)[0]
        if offset_to_va(i + 2) + 4 + relative != REGISTER_FUNCTION:
            continue
        native = struct.unpack_from("<I", image, i - 4)[0]
        if not TEXT_VADDR <= native < TEXT_VADDR + TEXT_SIZE:
            continue
        for k in range(i + 6, i + 20):
            if image[k] == 0x68:
                name = read_identifier(image, struct.unpack_from("<I", image, k + 1)[0])
                if name:
                    found.append((name, native))
                break
    return found


def declared_names(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return set(re.findall(r"^function ([A-Za-z_]\w*)", handle.read(), re.M))
    except OSError:
        return set()


def main():
    exe = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_EXE
    try:
        with open(exe, "rb") as handle:
            image = handle.read()
    except OSError as error:
        sys.exit("cannot read %s: %s" % (exe, error))

    sites = walk(image)
    bindings = {}
    for name, native in sites:
        bindings.setdefault(name, native)

    failures = [(n, want, bindings.get(n))
                for n, want in sorted(CONTROLS.items()) if bindings.get(n) != want]
    print("registration sites      : %d" % len(sites))
    print("unique names            : %d" % len(bindings))
    print("hand-checked controls   : %d/%d matched"
          % (len(CONTROLS) - len(failures), len(CONTROLS)))
    for name, want, got in failures:
        print("  MISMATCH %-26s expected 0x%06x got %s"
              % (name, want, "0x%06x" % got if got else "missing"))
    if failures:
        sys.exit("control pairs failed; the matcher no longer fits this build")

    declared = declared_names(DECLARATIONS)
    registered = set(bindings)
    undocumented = sorted(registered - declared)
    unmatched = sorted(declared - registered)

    print("declared in engine.d.lua: %d" % len(declared))
    print("in both                 : %d" % len(registered & declared))
    print("registered, UNdocumented: %d" % len(undocumented))
    print("declared, not registered: %d" % len(unmatched))

    os.makedirs(os.path.dirname(TARGET), exist_ok=True)
    with open(TARGET, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("name\tva\tdocumented\n")
        for name in sorted(bindings, key=lambda s: (s.lower(), s)):
            handle.write("%s\t0x%08x\t%s\n"
                         % (name, bindings[name], "yes" if name in declared else "no"))
    print("wrote %s" % TARGET)

    if undocumented:
        print("\nfirst 20 undocumented natives:")
        for name in undocumented[:20]:
            print("  %-34s 0x%08x" % (name, bindings[name]))
    if unmatched:
        print("\ndeclared but not found by this walk (see module docstring):")
        print("  " + ", ".join(unmatched))


if __name__ == "__main__":
    main()
