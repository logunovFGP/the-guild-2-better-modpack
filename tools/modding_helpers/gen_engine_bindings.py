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
import subprocess
import sys

DEFAULT_EXE = r"G:/SteamLibrary/steamapps/common/The Guild 2 Renaissance/GuildII.exe"
DECLARATIONS = os.path.join("meta", "engine.d.lua")
TARGET = os.path.join("meta", "engine.bindings.tsv")
STUBS = os.path.join("meta", "engine.undocumented.d.lua")

# Argument fetchers, and the Lua type each one produces. Derived by taking every
# documented native, matching each fetch call against the parameter position it
# reads, and tallying the type the dump declares there: 0x6373c0 came out Alias in
# 95% of 556 samples, 0x637320 boolean in 94%, 0x637230 number in 100%.
ARG_FETCHERS = {
    0x6373C0: "Alias", 0x81E290: "Alias",
    0x637320: "boolean",
    0x637230: "number", 0x6372D0: "number", 0x637280: "number", 0x81DCD0: "number",
    0x637370: "string",
}
# Entry macro. Its arguments carry the .cpp file and line the binding lives on.
PROLOGUE = 0x637560

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


def function_end(image, va, cap=0x2000):
    """Length of the function at va. MSVC pads with int3, so a ret followed by
    0xCC is the last byte."""
    start = va_to_offset(va)
    i = start
    while i < start + cap:
        if image[i] == 0xC3 and image[i + 1] == 0xCC:
            return i + 1 - start
        if image[i] == 0xC2 and image[i + 3] == 0xCC:
            return i + 3 - start
        i += 1
    return cap


def disassemble(addresses, exe, chunk=60):
    """rizin's view of every push/call in the given functions.

    Byte-walking backwards from a call to find its pushes does not work -- x86
    instruction lengths vary, so the walk guesses boundaries and silently returns
    wrong operands (it read GetDistance, which takes two Aliases, as one Alias and
    one string). rizin gives exact boundaries. Chunked because a single -c string
    for a thousand functions exceeds the command-line limit, and -i script files
    are not usable: rizin rejects a script written with CRLF endings.
    """
    line = re.compile(r"0x([0-9a-f]{8})\s+(push|call)\s+(.*)")
    out = []
    for i in range(0, len(addresses), chunk):
        commands = ";".join("af @ 0x%x;pdf @ 0x%x~push,call" % (a, a)
                            for a in addresses[i:i + chunk])
        try:
            result = subprocess.run(
                ["rizin", "-q", "-e", "scr.color=0", "-c", commands, exe],
                capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.SubprocessError):
            return None
        for text in result.stdout.splitlines():
            found = line.search(text)
            if found:
                out.append((int(found.group(1), 16), found.group(2), found.group(3)))
    return out


def _target(operand):
    found = re.search(r"fcn\.([0-9a-f]{8})|^(0x[0-9a-f]+)", operand.strip())
    return int(found.group(1) or found.group(2), 16) if found else None


def _literal(operand):
    found = re.match(r"^(0x[0-9a-f]+)", operand.strip())
    return int(found.group(1), 16) if found else None


def recover_signature(image, instructions, va):
    """(source file, line), {index: (type, required)} for one native.

    Both shapes are positional, counting back from the call:

        push <type descriptor>   push <flag>
        push <required>          push <line>
        push <0>                 push <"...\\Foo.cpp">
        push <parameter index>   push <reg>
        push <reg>               call PROLOGUE
        call <fetcher>
    """
    low, high = va, va + function_end(image, va)
    body = [x for x in instructions if low <= x[0] < high]
    params, source = {}, None
    for i, (_, mnemonic, operand) in enumerate(body):
        if mnemonic != "call":
            continue
        called = _target(operand)
        if called == PROLOGUE and i >= 4:
            name = body[i - 2][2]
            if "SourceCode" in name:
                tail = name.split(";")[-1].strip().strip('"')
                leaf = tail.replace(chr(92), "/").split("/")[-1]
                source = (leaf, _literal(body[i - 3][2]))
        elif called in ARG_FETCHERS and i >= 5:
            index = _literal(body[i - 2][2])
            required = _literal(body[i - 4][2])
            if index is not None and 1 <= index <= 12:
                params.setdefault(index, (ARG_FETCHERS[called], required))
    return source, params


def write_stubs(image, instructions, bindings, undocumented):
    """LuaLS stubs for natives the documentation dump never mentions."""
    out = [
        "---@meta",
        "",
        "-- Engine functions that ARE registered by GuildII.exe but do not appear in",
        "-- ScriptDocumentation.html. Generated by",
        "-- tools/modding_helpers/gen_engine_bindings.py; do not edit by hand.",
        "--",
        "-- There are no descriptions here on purpose. Nothing in the binary says what",
        "-- these functions mean, and inventing prose would be worse than silence.",
        "-- What IS recovered is mechanical: the native address, the .cpp file and line",
        "-- the binding sits on, how many parameters it reads, each parameter's type,",
        "-- and which are optional.",
        "--",
        "-- Accuracy, measured by running the same recovery against 60 documented natives",
        "-- and comparing with the dump: arity correct 53/60; of 111 parameter positions,",
        "-- 7 genuine type disagreements (6%), and a further 9 where the dump says 'any'",
        "-- and this is more specific; optional flags agree 97/107.",
        "--",
        "-- No @return anywhere: the likeliest return-pusher also correlates with Alias",
        "-- PARAMETERS, so return types cannot be established this way.",
        "--",
        "-- Where no parameter could be read the stub is `(...)`, NOT `()`. Those natives",
        "-- (the CC_* character-creation family and others) use a shorter fetch shape",
        "-- carrying no type descriptor. Declaring them as taking nothing would make the",
        "-- language server flag correct calls as errors, so they accept anything instead.",
        "",
        "---@class Alias",
        "",
    ]
    written = 0
    for name in undocumented:
        va = bindings[name]
        source, params = recover_signature(image, instructions, va)
        arity = max(params) if params else 0
        where = "%s:%s" % source if source and source[1] else (source[0] if source else "")
        out.append("---Undocumented. Native at 0x%08x%s"
                   % (va, (", " + where) if where else ""))
        if not arity:
            out.append("---Parameters not recoverable; accepts anything rather than")
            out.append("---claiming it takes none.")
            out.append("---@param ... any")
            out.append("function %s(...) end" % name)
            out.append("")
            written += 1
            continue
        for i in range(1, arity + 1):
            kind, required = params.get(i, ("any", None))
            out.append("---@param p%d%s %s" % (i, "?" if required == 0 else "", kind))
        out.append("function %s(%s) end"
                   % (name, ", ".join("p%d" % i for i in range(1, arity + 1))))
        out.append("")
        written += 1
    with open(STUBS, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out))
    return written


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
        print("\nrecovering signatures for the undocumented set (needs rizin)...")
        instructions = disassemble([bindings[n] for n in undocumented], exe)
        if instructions is None:
            print("  rizin not runnable; skipped %s" % STUBS)
        else:
            written = write_stubs(image, instructions, bindings, undocumented)
            print("  wrote %s (%d stubs)" % (STUBS, written))
        print("\nfirst 20 undocumented natives:")
        for name in undocumented[:20]:
            print("  %-34s 0x%08x" % (name, bindings[name]))
    if unmatched:
        print("\ndeclared but not found by this walk (see module docstring):")
        print("  " + ", ".join(unmatched))


if __name__ == "__main__":
    main()
