#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Generate meta/engine.d.lua from ScriptDocumentation.html.

The HTML is the engine's own API dump. It is rigidly structured: entries are
separated by <hr>, each carrying one <a name="..."> anchor and one <h2> signature,
followed by Parameters / Return Value / Description sections.

Emits a lua-language-server declaration file so an editor can complete and check
engine calls. Nothing here is invented: types and text come straight from the
dump, including its mistakes. Where a declared return type contradicts its own
description, the contradiction is reported and the output stays faithful.

    python tools/modding_helpers/gen_engine_meta.py

Regeneration is stable: functions are sorted, so a diff shows only real changes.
"""
import html
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, 'ScriptDocumentation.html')
TARGET = os.path.join(ROOT, 'meta', 'engine.d.lua')

# The dump's own type words. Anything not listed becomes `any` and keeps its
# original word in the description, so no information is lost.
SIMPLE_TYPES = {
    'string': 'string',
    'number': 'number',
    'boolean': 'boolean',
    'nil': 'nil',
    # Eight entries in the dump were written with C type words instead, typed
    # into the name field (see MALFORMED_NAME_RE). Their Return Value section
    # carries no type word at all, so this is the only place the type appears.
    'bool': 'boolean',
    'int': 'number',
    'float': 'number',
}
ALIAS_RE = re.compile(r'^alias\b', re.I)
ALIAS_OF_RE = re.compile(r'of\s+type\s+([^)]*)', re.I)

LUA_KEYWORDS = {
    'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
    'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then',
    'true', 'until', 'while',
}
IDENT_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')

# `<a name="bool<tab>BossCreate">` -- the author typed the return type into the
# name field, tab separated, leaving the h2 return font empty. Eight entries.
MALFORMED_NAME_RE = re.compile(r'^(\S+)\s+(\S+)$')

# A declared Nil / absent return sitting next to a description that plainly
# speaks of a result. Reported for a human to judge, never auto-corrected.
RETURNS_SOMETHING_RE = re.compile(
    r'^\s*(gets?|returns?|delivers?|retrieves?|checks?|tests?|calculates?|counts?|'
    r'finds?|is\s|has\s|are\s|liefert)', re.I)


# Notes verified against this repo and a running game, keyed by function name. The
# dump documents the signature; these record what it does not say. They are emitted
# as extra doc lines, so they survive regeneration -- add here, never to the output.
NOTES = {
    'MsgSay': [
        "A **text label**, not a string: `\"_MEASURE_X_BODY_+0\"` raw, or `\"@L\"` followed",
        "by the key **including its leading underscore** where a label argument is",
        "expected. Formatting codes inside the text: `$N` line break, `$C[r,g,b]` colour",
        "for the rest of the string, `$S[2000-2255]` a symbol from SetGame30.dds,",
        "`$L`/`$R` alignment, `#E[NT_NEUTRAL]` an emotion for speech (never shown).",
        "Arguments are `%1n`/`%1i` integer, `%1t` integer plus a coin symbol, `%1l` a",
        "label, `%1SN`/`%1SV` sim full name and forename, `%1GG`/`%1DN`/`%1NAME`",
        "building, dynasty and city, `%1SA`/`%1ST`/`%1SK` office, title and class.",
        "Two traps. A **literal per cent must be doubled** (`20%%`) or the text system",
        "logs `[Textsystem] Error at Substitutioncommand` when the row renders -- and",
        "unescaped per cents are widespread in the vanilla table. But `%>` and `%<` are",
        "**engine quote markers, not per cents**: escaping those breaks the row. Only",
        "escape a per cent that directly follows a digit.",
        "A `\"` may never appear inside the text; use `>word<`, which renders quoted.",
        "An **unbalanced** quote silently breaks the row: the text system cannot parse",
        "it and the string is lost. Three Spanish rows shipped that way -- 18235, 18616",
        "and 18871 -- two of them also had every word gap padded to the three-space",
        "field separator. Check `line.count(chr(34)) == 4` after editing any table.",
        "Talent symbol codes for `$S[]`, which render in the on-screen-help impact",
        "tooltips but **not** in the measure info panel: 2016 Dexterity, 2017",
        "Constitution, 2018 Fighting, 2019 Craftsmanship, 2020 Shadow Arts, 2021",
        "Rhetoric, 2022 Empathy, 2023 Bargaining, 2024 Secret Knowledge, 2025 Charisma.",
    ],
    'MsgBox': ["See MsgSay for label form, formatting codes and the per-cent traps."],
    'MsgQuick': ["See MsgSay for label form, formatting codes and the per-cent traps."],
    'MsgNews': ["See MsgSay for label form, formatting codes and the per-cent traps."],
    'MeasureRun': [
        "Dispatch is gated by DB/MeasureToObjects.dbt before any Lua runs: columns",
        "selectionmode, targetfilter, objectfilter, object, mouseicon, targets,",
        "targetflag. The filter columns are Filter.dbt ids, where **0 is `None`** -- a",
        "row asking for `MEASUREINIT_SELECTION` with 0 in the selection slot gives the",
        "player nothing valid to click, so the measure never starts and `Run()` is never",
        "entered. `ms_003_Walk` is the reference for a ground click: filter 1,",
        "`TargetFilterWalk`, accepting a Position, Sim, Cart or Building.",
        "Rows 90, 110, 140, 150 and 190 have **no vanilla counterpart**, so a `~` in one",
        "of their cells inherits nothing at all.",
    ],
    'MeasureStart': ["See MeasureRun for the MeasureToObjects.dbt dispatch gate."],
    'GetCurrentMeasureName': [
        "The `name` column of Measures.dbt, which is also the text key stem:",
        "`_MEASURE_<name>_NAME_+0` is the button label and `_MEASURE_<name>_TOOLTIP_+0`",
        "the description. Matching is case-insensitive in practice --",
        "`ASSIGNTOTHIEFOFLOVE` resolves for a measure named `AssignToThiefOfLove`.",
        "Handy but unreliable: the measure id is the filename number times ten for 62 of",
        "the 64 rows that declare a script. Id 481 is ms_048_HireEmployeeBuildingRandom",
        "and id 1800 is ms_211_OrderCollectEvidence. Work measures are `type = 5`.",
        "**No table declares which talent a measure uses** -- Action.dbt's",
        "`observerskill` is about who notices an illegal act, not the actor's stat.",
    ],
    'LogText': ["The scripts use the undocumented `LogMessage` instead; see its notes."],
    'f_MoveTo': [
        "**Omitting Speed walks.** No default is applied on the Lua side and the doc",
        "calls WALK \"normal\", so a two-argument call is a walking call. That is the",
        "usual reason a worker loses half a day on the road -- not an explicit WALK,",
        "just a missing third argument. Of 429 movement calls under Scripts/Measures,",
        "118 approach legs run, 50 walk explicitly and 79 omit the speed.",
        "Work measures (`type = 5` in Measures.dbt) should run the approach; movement",
        "inside the work loop is usually deliberate and should be left alone.",
    ],
    'f_MoveToNoWait': ["See f_MoveTo: omitting Speed walks."],
    'GetNobilityTitle': [
        "Returns the **1-based id of DB/NobilityTitle.dbt** -- 1 at the bottom of the",
        "ladder, 14 at the top. `constants_Title_to_string_map` holds the names.",
        "The Nobility passive is granted at **Patrician (7)**; the imperial fame gate",
        "is one rung higher, at Nobleman (8), where `minimperialfame` first rises",
        "above zero. Two boundaries that are easy to conflate.",
    ],
    'GetNobilityTitleLabel': [
        "Returns a **text label id, not a string**. Lua cannot turn it into a string;",
        "pass it on as a `%1l` argument to a Msg* or OSH label call. The English title",
        "names are in no shipped text table -- the whole vanilla Text.dbt was searched.",
    ],
    'OSHSetMeasureRepeat': [
        "One of exactly **three** rows a measure's info panel can show, set from",
        "`GetOSHData(MeasureID)`: repeat, runtime and cost. There is no talent row and",
        "no fourth slot, so anything else has to borrow one of these.",
        "`labelKey` is `@L` followed by the text key **including its leading",
        "underscore**. The integer is optional -- some measures pass a label alone,",
        "which is what makes these generic text rows rather than time or money widgets.",
        "Confirmed in game: GetOSHData fires for work-assignment measures too, not only",
        "for character action buttons. Colour codes render on this panel; `$S[]` symbol",
        "codes do **not**.",
    ],
    'OSHSetMeasureRuntime': ["See OSHSetMeasureRepeat. Renders as plain text -- no clock decoration."],
    'OSHSetMeasureCost': ["See OSHSetMeasureRepeat."],
    'SimGetAssignedArea': [
        "Engine-managed and effectively the sim's working place. **There is no setter**",
        "in the API and no script sets it. Overwriting a freshly dispatched Destination",
        "with this is what made an assigned cocotte work where she stood instead of",
        "walking to the clicked spot -- only fall back to it when handed no Destination.",
    ],
    'SimGetAssignedAreaID': ["See SimGetAssignedArea. No setter exists."],
    'GetSkillValue': [
        "Talent **display names differ from the constants**: FIGHTING is Martial Arts,",
        "CRAFTSMANSHIP is Handicraft, SHADOW_ARTS is Stealth, SECRET_KNOWLEDGE is",
        "Arcane Knowledge. 239 call sites carry every talent dependency in the game;",
        "no database table declares them. `chr_GetSkillValue` is a wrapper that clamps",
        "the result to 15 -- only 7 files use it, so the two are not interchangeable.",
        "Two shapes of dependency, neither reachable from the UI. Social measures have a",
        "declarative `MeasureData[id].talent` in GamePlayFormulas.lua -- but it is",
        "`local`, declared five separate times, and CalcMinFavor disagrees with",
        "CalcFavorWon for several ids including Flirt and BewitchCharacter. CalcFavorWon",
        "decides the favour actually won, so trust that one. Everything else reads a",
        "talent inline in the measure body.",
    ],
    'SimGetLevel': [
        "Drives the income of measures that scale with the character rather than a",
        "talent -- hush money and the thief of love both multiply it.",
    ],
    'GetDatabaseValue': [
        "How Lua reads any .dbt column, e.g. `GetDatabaseValue(\"Measures\", id,",
        "\"duration\")`. The mod ships deltas of the core tables, where a `~` cell means",
        "inherit the vanilla value -- and several tables have **no** vanilla row to",
        "inherit from, in which case `~` resolves to nothing.",
        "Measures.dbt columns: id, script, classscript, name, interruptvalue, icon_path,",
        "runtype, type, basexp, panel, panelparam, guiorder, repeat_time, duration,",
        "rangeeffect, rangeradius, notargetattach.",
    ],
}


# Facts with no single owning function. Emitted once, under the file header.
FILE_NOTES = [
    "Text tables. DB/Languages/Text.dbt is UTF-16LE **with a BOM**, CRLF, rows shaped",
    "`<id>   \"<label>\"   \"<text>\"   |` -- three spaces between fields everywhere",
    "except #russian, which uses tabs. Columns are id, label and the language name;",
    "the Portuguese file misspells its own column `porutguese`. The game ships one",
    "full English table (3.1 MB) and the mod ships a ~2700-row delta at the same path,",
    "loaded as an overlay -- rows match by **label, not id**, so a mod row overrides a",
    "vanilla row even at a different id. Per-language files override the same way and a",
    "label missing from one **falls back to English**, which is the full base table for",
    "every language: the vanilla install has no Text.dbt in any #<lang> folder at all.",
    "Vanilla ids run below ~18000 and the mod's additions start at 18000. Duplicate ids",
    "already exist at HEAD in nine files; only the first row with a given id or label is",
    "read.",
    "",
    "Talent display names differ from the Lua constants: FIGHTING is Martial Arts,",
    "CRAFTSMANSHIP is Handicraft, SHADOW_ARTS is Stealth, SECRET_KNOWLEDGE is Arcane",
    "Knowledge. Harvest them per language from _ONSCREENHELP_1_CHARACTER_TALENTS_+0..9",
    "(the character sheet, in the order Constitution, Dexterity, Charisma, Fighting,",
    "Craftsmanship, Shadow Arts, Rhetoric, Empathy, Bargaining, Secret Knowledge) or",
    "from the Requirements: clause of _ABILITIES_<name>_DESCRIPTION_+0; the sheet wins",
    "on conflict. German, French, Russian, Hungarian, Portuguese, Chinese and Korean",
    "have all ten; Italian, Spanish, Polish and Romanian ship none anywhere in the repo",
    "or the install. Polish uses a substituted alphabet -- a for c-cedilla and so on per",
    "Translations/Translation-Kit.txt -- and Hungarian writes o-tilde for o-double-acute.",
    "The base language is German: the kit states the intended wording always comes from",
    "the German table.",
    "",
    "Rich tooltips. DB/Languages/Tooltips.dbt is a Reforged addition, table 4 in",
    "Tables.dbt, columns id/key/title/description/image/portrait_role, 99 rows. Unlike",
    "the Text table it resolves **live placeholders** -- 34 in use including %gold%,",
    "%treasury%, %settlement_level%, %wealth%, %hp_cur%, %char_name% -- and can pull a",
    "measure's own text with %measure:<Name>:name% and :desc%. That makes it the only",
    "channel where a description carries live values. Exactly one measure uses it, and",
    "resolution is engine-side: a placeholder outside that list cannot be added in Lua.",
]

# Engine globals the scripts demonstrably call that the dump omits entirely. The
# signatures are reconstructed from call sites, not from the documentation, and are
# marked as such -- everything above this line is faithful to the dump.
UNDOCUMENTED = [
    ('Rand', ['n'], 'number', [
        "**Not in the API dump.** Signature reconstructed from 1239 call sites.",
        "Returns an integer in **0 .. n-1**: `Rand(2) == 0` is used as a coin flip,",
        "`Rand(3)+1` for 1..3, and `\"Sims\"..Rand(NumSims-1)` to index a found list.",
    ]),
    ('LogMessage', ['Text'], None, [
        "**Not in the API dump.** Reconstructed from 310 call sites.",
        "Writes one line to `<game>/logfile.log`, which is **overwritten every launch**.",
        "Unconditional -- there is no debug gate; the only switch is `DisableLogging` in",
        "configs/Reforged/config.ini, where 0 means logging is on.",
        "A leading `@TAG ` becomes `[TAG]` in the log, which is how you make a probe",
        "greppable. Useful engine lines to grep alongside it: `[Script] Executing",
        "Measures/<file> on <sim>` marks a measure actually starting, `[StartMeasure]",
        "<sim>: Canceled ...` marks a rejection, and `[TEXTSYSTEM] Content-mod loca for",
        "table <name>` confirms an overlay table loaded.",
    ]),
    ('ScenarioGetDifficulty', [], 'number', [
        "**Not in the API dump.** Reconstructed from 72 call sites.",
        "Scenario difficulty, fed through `math.floor(math.pow(x, 0.54))` where scripts",
        "turn it into a detection or failure chance.",
    ]),
    ('IncrementXPQuiet', ['pSim', 'Amount'], None, [
        "**Not in the API dump.** Reconstructed from 28 call sites.",
        "Grants experience without the floating feedback the noisy variant shows.",
    ]),
    ('FindNode', ['Path'], None, [
        "**Not in the API dump.** Reconstructed from 198 call sites.",
        "Reaches into the live GUI tree, e.g. `FindNode(\"\\GUI\\HudRoot\")` or",
        "`\"\\application\\game\\Hud\"` -- note the doubled backslashes.",
        "The returned node supports `GetChildCnt()`, `GetChildAt(i)`, `GetName()`,",
        "`FindChildDepth(name)`, `GetParent()`, and `GetValueInt/String(property)` with",
        "`SetValueInt/String(property, value)`. Hud/Debug/HudRootAnalyser.lua is the",
        "worked example.",
        "This is the only practical way to change a panel: the .gui files under GUI/ are",
        "**binary serialised**, not text, so their properties -- ABS_WIDTH, ABS_HEIGHT,",
        "TEXTAREAWIDTH, TEXTAREAHEIGHT, SHOW_VERTICAL_SCROLLBAR, RESIZE, WINDOW_MARGIN*",
        "-- can be read out of the file as names but not safely edited there.",
        "Panels are registered in Scripts/Hud/GameHud.lua with",
        "`this:AddPanel(name, class, guifile, visible)`; the measure info window is",
        "HelpMeasures / Helppanels/measures.gui.",
        "",
        "**Runtime writes take, but reading back a changed value proves nothing.**",
        "ABS_HEIGHT, RESIZE and SHOW_VERTICAL_SCROLLBAR all read back changed on all 11",
        "panels; only ABS_HEIGHT had any visible effect. RESIZE does not make a window",
        "fit its content and SHOW_VERTICAL_SCROLLBAR produces no scrollbar -- the engine",
        "consults both when it builds a panel and never again. Geometry is the exception:",
        "a panel grown at HudInit is still grown when it is displayed much later, so the",
        "write survives into layout. All of it is per-session and gone on restart, which",
        "makes a bad write recoverable and also means nothing persists without",
        "re-applying it at HudInit.",
        "",
        "**Finding a specific panel is the hard part.** HudRoot has 137 children and:",
        "a panel is NOT named after its AddPanel name -- it takes NODE_NAME from its",
        ".gui, so all thirteen help windows are plain `Container`; the AddPanel order",
        "does not map onto the child order (child 37 is the multiplayer lobby,",
        "NameList/PingList, and child 39 is the character help panel, SkillBars /",
        "Lifecandle / Shield); and a TEXT match on `@LProduction` hits 13 children.",
        "measures.gui, items.gui and upgrades.gui share **every** extractable string --",
        "same layout, distinguishable only once populated at display time -- so no",
        "offline fingerprint for the measure window exists.",
        "",
        "What does work: all thirteen Helppanels/*.gui carry the texture",
        "`Hud/sheets/onscreenhelp/bg.tga` and nothing else does, so",
        "`GetValueString(\"TEXTURE_FILENAME\")` on descendants identifies the help-panel",
        "cohort exactly. Treat the cohort, do not try to single one out.",
        "",
        "**A help window is three siblings, each holding its own height.** Growing the",
        "panel alone just exposes its backdrop below the border. On panel 43 the child",
        "`cl_WinContainer` reads ABS_HEIGHT equal to the panel's own (394) and keeps it",
        "when the panel grows -- that is the bordered frame. The description text is in a",
        "child named `Label` (217x402 on the measures family) and its height is what cuts",
        "a long description off mid-sentence. To show more text, set ABS_HEIGHT on the",
        "panel, the frame and the Label.",
        "",
        "Useful child names, from a geometry dump of all 11: `cl_WinContainer` (frame,",
        "full height), `Label` and `Desc` (text), `Icon` / `cl_Sprite` / `Artefact`",
        "(art), `Header` (~27-32px), `Container` (38px button strip). Only ABS_HEIGHT and",
        "ABS_WIDTH carry values -- HEIGHT, WIDTH and ABS_YPOS all read 0. There is no way",
        "to ask how tall wrapped text came out, so a fixed headroom is the only option.",
        "Break bones is panel 43 or 45: identical twins, the measures / items / upgrades",
        "family sharing one layout.",
        "",
        "None of this needs rediscovering: `Scripts/Library/guilayout.lua` wraps it as",
        "`guilayout_GrowHelpPanels()`, `guilayout_GrowPanel(node, px)` and",
        "`guilayout_FindPanelsByTexture(root, texture)`, and",
        "`tools/modding_helpers/check_guilayout.lua` exercises the rules offline against",
        "node trees dumped from a running game. Grow the frame and text nodes BY NAME, not",
        "by height: a height-share rule stretched a 313px portrait on the character panel",
        "and still missed a 226px Label on a taller one.",
    ]),
]


def strip_tags(fragment):
    """Tag soup to one clean line."""
    text = re.sub(r'(?is)<br\s*/?>', ' ', fragment)
    text = re.sub(r'(?s)<[^>]*>', ' ', text)
    text = text.replace('&nbsp', ' ')
    text = html.unescape(text)
    return re.sub(r'\s+', ' ', text).strip()


def map_type(engine_type):
    """(lua type, note to append to the description) for one engine type word."""
    raw = (engine_type or '').strip()
    key = raw.lower().rstrip(' :')
    if key in SIMPLE_TYPES:
        return SIMPLE_TYPES[key], ''
    if ALIAS_RE.match(key):
        of = ALIAS_OF_RE.search(raw)
        return 'Alias', ('(%s)' % of.group(1).strip()) if of else ''
    if not raw:
        return 'any', ''
    return 'any', '(%s)' % raw


def safe_name(name, index):
    """A usable Lua parameter name. Never returns something invalid."""
    cleaned = re.sub(r'[^A-Za-z0-9_]', '', name or '')
    if not cleaned or not IDENT_RE.match(cleaned):
        return 'arg%d' % (index + 1)
    if cleaned in LUA_KEYWORDS:
        return cleaned + '_'
    return cleaned


def bracketed_positions(signature_html):
    """Indices of parameters wrapped in [ ] in the h2 signature."""
    open_paren = signature_html.find('(')
    close_paren = signature_html.rfind(')')
    if open_paren < 0 or close_paren < open_paren:
        return set()
    inside = signature_html[open_paren + 1:close_paren]
    optional = set()
    depth = 0
    position = 0
    started = False
    in_tag = False
    for char in inside:
        if char == '<':
            in_tag = True
            continue
        if char == '>':
            in_tag = False
            continue
        if in_tag:
            continue
        if char == '[':
            depth += 1
        elif char == ']':
            depth = max(0, depth - 1)
        elif char == ',' and depth == 0:
            position += 1
            started = False
        elif not char.isspace() and not started:
            started = True
            if depth > 0:
                optional.add(position)
    return optional


def parse_params(section):
    """Each <p> in the Parameters section is one parameter."""
    params = []
    for para in re.findall(r'(?is)<p[^>]*>(.*?)</p>', section):
        type_m = re.search(r'(?is)color:blue"?\s*>(.*?)</font>', para)
        name_m = re.search(r'(?is)color:gr[ae]y"?\s*>(.*?)</font>', para)
        if not type_m and not name_m:
            continue
        desc_m = re.search(r'(?is)color:green"?\s*>(.*?)</font>', para)
        params.append({
            'type': strip_tags(type_m.group(1)) if type_m else '',
            'name': strip_tags(name_m.group(1)) if name_m else '',
            'optional': bool(re.search(r'(?is)color:red"?\s*>\s*OPTIONAL', para)),
            'desc': strip_tags(desc_m.group(1)) if desc_m else '',
        })
    return params


def split_name(brown):
    """(return type recovered from a malformed name, real function name)."""
    text = brown.strip()
    m = MALFORMED_NAME_RE.match(text)
    if m:
        return m.group(1), m.group(2)
    return '', text


def parse_block(block):
    anchor = re.search(r'<a\s+name="([^"]+)"', block)
    head = re.search(r'(?is)<h2>(.*?)</h2>', block)
    if not anchor or not head:
        return None
    signature = head.group(1)
    name_m = re.search(r'(?is)color:brown"?\s*>(.*?)</font>', signature)
    ret_m = re.search(r'(?is)color:blue"?\s*>(.*?)</font>', signature)
    name_hint, name = split_name(strip_tags(name_m.group(1)) if name_m else anchor.group(1))

    sections = dict(re.findall(
        r'(?is)<h3>\s*(Parameters|Return Value|Description)\s*:?\s*</h3>(.*?)(?=<h3>|$)',
        block))

    params = parse_params(sections.get('Parameters', ''))
    for index in sorted(bracketed_positions(signature)):
        if index < len(params):
            params[index]['optional'] = True

    ret_section = sections.get('Return Value', '')
    ret_type, ret_desc = None, ''
    if ret_section and 'no return value' not in strip_tags(ret_section).lower():
        blue = re.search(r'(?is)color:blue"?\s*>(.*?)</font>', ret_section)
        green = re.search(r'(?is)color:green"?\s*>(.*?)</font>', ret_section)
        declared = strip_tags(blue.group(1)) if blue else ''
        if not declared:
            # Empty type font: fall back to the h2, then to the mangled name.
            declared = (strip_tags(ret_m.group(1)) if ret_m else '') or name_hint
        if declared.lower() not in ('', 'nil'):
            ret_type = declared
            ret_desc = strip_tags(green.group(1)) if green else ''

    return {
        'name': name,
        'anchor': anchor.group(1),
        'malformed_name': bool(name_hint),
        'declared_return': (strip_tags(ret_m.group(1)) if ret_m else '') or name_hint,
        'params': params,
        'return_type': ret_type,
        'return_desc': ret_desc,
        'description': strip_tags(sections.get('Description', '')),
    }


def signature_of(entry):
    """`fun(a: string, b?: Alias): boolean` for an @overload line."""
    parts = []
    for index, param in enumerate(entry['params']):
        lua_type, _ = map_type(param['type'])
        parts.append('%s%s: %s' % (safe_name(param['name'], index),
                                   '?' if param['optional'] else '', lua_type))
    text = 'fun(%s)' % ', '.join(parts)
    if entry['return_type']:
        lua_type, _ = map_type(entry['return_type'])
        text += ': %s' % lua_type
    return text


def render(name, entries):
    """One function stub, with any extra signatures as @overload lines above it."""
    primary = entries[0]
    lines = ['---' + primary['description']] if primary['description'] else ['---']
    for extra_line in NOTES.get(name, []):
        lines.append('---' + extra_line)

    for index, param in enumerate(primary['params']):
        lua_type, note = map_type(param['type'])
        tail = ' '.join(part for part in (param['desc'], note) if part)
        lines.append('---@param %s%s %s%s' % (
            safe_name(param['name'], index),
            '?' if param['optional'] else '',
            lua_type,
            (' ' + tail) if tail else ''))

    if primary['return_type']:
        lua_type, note = map_type(primary['return_type'])
        tail = ' '.join(part for part in (primary['return_desc'], note) if part)
        lines.append('---@return %s%s' % (lua_type, (' # ' + tail) if tail else ''))

    for extra in entries[1:]:
        lines.append('---@overload %s' % signature_of(extra))

    args = ', '.join(safe_name(p['name'], i) for i, p in enumerate(primary['params']))
    lines.append('function %s(%s) end' % (name, args))
    return '\n'.join(lines)


def structural_check(text):
    """No Lua binary on this machine, so check the shape of every emitted line."""
    problems = []
    seen = set()
    for number, line in enumerate(text.splitlines(), 1):
        if not line or line.startswith('---') or line.startswith('--'):
            continue
        m = re.match(r'^function ([A-Za-z_][A-Za-z0-9_]*)\(([^()]*)\) end$', line)
        if not m:
            problems.append('line %d is neither a comment nor a stub: %s' % (number, line[:70]))
            continue
        if m.group(1) in seen:
            problems.append('line %d re-declares %s' % (number, m.group(1)))
        seen.add(m.group(1))
        args = [a.strip() for a in m.group(2).split(',') if a.strip()]
        for arg in args:
            if not IDENT_RE.match(arg) or arg in LUA_KEYWORDS:
                problems.append('line %d has a bad parameter %r' % (number, arg))
        if len(args) != len(set(args)):
            problems.append('line %d repeats a parameter name' % number)
    return problems, len(seen)


def main():
    raw = open(SOURCE, 'rb').read().decode('latin-1')
    anchors = re.findall(r'<a\s+name="([^"]+)"', raw)

    entries = []
    for block in re.split(r'(?i)<hr\s*/?>', raw):
        parsed = parse_block(block)
        if parsed:
            entries.append(parsed)

    grouped = {}
    for entry in entries:
        grouped.setdefault(entry['name'], []).append(entry)

    out = ['---@meta', '',
           '-- Generated by tools/modding_helpers/gen_engine_meta.py from',
           '-- ScriptDocumentation.html. Do not edit by hand; regenerate instead.',
           '-- Types and text are faithful to the dump, including its errors;',
           '-- notes on top come from NOTES/FILE_NOTES in the generator.',
           '']
    for note_line in FILE_NOTES:
        out.append(('-- ' + note_line).rstrip())
    out += ['',
           '---An engine object handle. Scripts address these by alias name.',
           '---@class Alias', '']
    for name in sorted(grouped, key=lambda s: (s.lower(), s)):
        out.append(render(name, grouped[name]))
        out.append('')
    out.append('-- ' + '-' * 74)
    out.append('-- Reconstructed from call sites, NOT from the documentation dump.')
    out.append('-- ' + '-' * 74)
    out.append('')
    for fname, params, ret, note in UNDOCUMENTED:
        for note_line in note:
            out.append('---' + note_line)
        for param in params:
            out.append('---@param %s any' % param)
        if ret:
            out.append('---@return %s' % ret)
        out.append('function %s(%s) end' % (fname, ', '.join(params)))
        out.append('')

    text = '\n'.join(out)

    os.makedirs(os.path.dirname(TARGET), exist_ok=True)
    with open(TARGET, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write(text)

    print('anchors in source      : %d' % len(anchors))
    print('entries parsed         : %d' % len(entries))
    print('unique function names  : %d' % len(grouped))
    overloaded = sorted(k for k, v in grouped.items() if len(v) > 1)
    print('overloaded names       : %d %s' % (len(overloaded), overloaded))
    print('unparsed blocks        : %d' % (len(anchors) - len(entries)))
    counts = {}
    for entry in entries:
        counts[entry['name']] = counts.get(entry['name'], 0) + 1
    repeats = sorted((n, c) for n, c in counts.items() if c > 1)
    print('names appearing twice+ : %d %s' % (len(repeats), repeats))
    print('   %d anchors - %d duplicate occurrences = %d unique names'
          % (len(anchors), sum(c - 1 for _, c in repeats), len(grouped)))
    malformed = sorted(e['name'] for e in entries if e['malformed_name'])
    print('malformed source names : %d %s' % (len(malformed), malformed))
    print("   their anchors read like 'bool<tab>BossCreate'; the leading word is "
          "the return type and is recovered from there")

    noted = sorted(n for n in NOTES if n in grouped)
    print('functions carrying notes : %d %s' % (len(noted), noted))
    print('file-level note lines    : %d' % len(FILE_NOTES))
    print('reconstructed stubs      : %d %s'
          % (len(UNDOCUMENTED), [f for f, _, _, _ in UNDOCUMENTED]))
    clash = [f for f, _, _, _ in UNDOCUMENTED if f in grouped]
    if clash:
        print('RECONSTRUCTED name also in the dump: %s' % clash)
    orphan = sorted(n for n in NOTES if n not in grouped)
    if orphan:
        print('NOTES for unknown names  : %s' % orphan)

    problems, stub_count = structural_check(text)
    print('function stubs emitted : %d' % stub_count)
    print('structural problems    : %d' % len(problems))
    for problem in problems[:20]:
        print('   ' + problem)

    late_required = set()
    for name, group in grouped.items():
        for entry in group:
            seen_optional = False
            for param in entry['params']:
                if param['optional']:
                    seen_optional = True
                elif seen_optional:
                    late_required.add(name)
                    break
    print('required param after an optional: %d %s'
          % (len(late_required), sorted(late_required)[:12]))

    contradictions = []
    for name, group in sorted(grouped.items()):
        entry = group[0]
        if entry['return_type'] is None and RETURNS_SOMETHING_RE.match(entry['description']):
            contradictions.append((name, entry['declared_return'] or 'none',
                                   entry['description'][:70]))
    print('\ndeclared no return, description says otherwise: %d' % len(contradictions))
    for name, declared, description in contradictions:
        print('   %-32s declared %-4s | %s' % (name, declared, description))

    print('\nwrote %s (%d lines)' % (os.path.relpath(TARGET, ROOT), text.count('\n') + 1))
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
