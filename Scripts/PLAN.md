# PLAN: Prepare Scripts for AI coding workflow

Scope:
- Focus on `Scripts` repository onboarding and context quality.
- No gameplay behavior changes are included in this pass.
- Goal is to make AI-assisted coding faster and safer by improving local context and process.

Assumptions:
- Repository already includes API docs in `docs/ScriptDocumentation.html`.
- No `AGENTS.md`, `PLAN.md`, or `llm.txt` files currently exist.
- I will only add context/plan files unless you request functional script changes.

Decision Log:
- Non-trivial choice: added lightweight documentation + context files only, avoiding runtime/script logic edits to reduce regression risk during onboarding work.

## Work items

- [ ] Add `Scripts/llm.txt` with a concise inventory of script domains and onboarding notes for AI helpers.
  - Status: implemented, awaiting user confirmation
  - Touched: `Scripts/llm.txt`

- [ ] Add `Scripts/AI/llm.txt` with AI-specific behavior context and pointers into existing AI docs.
  - Status: implemented, awaiting user confirmation
  - Touched: `Scripts/AI/llm.txt`

- [ ] Add `Scripts/PLAN.md` process file for the current request and record remaining context work.
  - Status: implemented, awaiting user confirmation
  - Touched: `Scripts/PLAN.md`

- [ ] Add root `AGENTS.md` with repository-wide AI coding constraints for this session.
  - Status: implemented, awaiting user confirmation
  - Touched: `AGENTS.md`

- [ ] Add `Scripts/AGENTS.md` with Scripts-focused editing conventions and safety guardrails.
  - Status: implemented, awaiting user confirmation
  - Touched: `Scripts/AGENTS.md`

- [ ] Add `Scripts/AI/AGENTS.md` with AI subtree context and high-risk edit constraints.
  - Status: implemented, awaiting user confirmation
  - Touched: `Scripts/AI/AGENTS.md`

- [ ] Add nested `AGENTS.md` files for every immediate `Scripts/*` subdirectory.
  - Status: implemented, awaiting user confirmation
  - Touched:
    - `Scripts/AI/AGENTS.md`
    - `Scripts/Buildings/AGENTS.md`
    - `Scripts/Campaign/AGENTS.md`
    - `Scripts/City/AGENTS.md`
    - `Scripts/Cutscenes/AGENTS.md`
    - `Scripts/GameModule/AGENTS.md`
    - `Scripts/GameState/AGENTS.md`
    - `Scripts/Hud/AGENTS.md`
    - `Scripts/Library/AGENTS.md`
    - `Scripts/Maps/AGENTS.md`
    - `Scripts/Measures/AGENTS.md`
    - `Scripts/Privileges/AGENTS.md`
    - `Scripts/Ships/AGENTS.md`
    - `Scripts/States/AGENTS.md`
    - `Scripts/Weather/AGENTS.md`

Decision Log:
- Chosen to create one immediate-subdirectory AGENTS file per folder to satisfy local-scope guidance requirements and reduce context ambiguity for future AI edits.

- [ ] Add AI README for reusable Lua AI libraries and architecture references.
  - Status: implemented, awaiting user confirmation
  - Touched: `Scripts/AI/README.md`

- [ ] Add reusable AI library references to `Scripts/AI/BaseTree/readme.mkd`.
  - Status: implemented, awaiting user confirmation
  - Touched: `Scripts/AI/BaseTree/readme.mkd`

- [ ] Quacksalve: every miracle cure sold costs the buyer's favour toward the seller's family, and may earn a lampoon.
  - Status: implemented, awaiting user confirmation
  - Rule: loss = max(4 - difficulty, ceil((5 + difficulty) * (1 - rhetoric/10))) favour per sale (chr_ModifyFavor, buyer toward seller; not guild fame);
    the buyer pins a lampoon against the seller with 7 * difficulty % chance. A hired quack's
    employer answers for it. One `@QUACK sale ...` / `@QUACK refused ...` log line per buyer.
  - Sale: flat 10% lucky sale, else buyer Empathy vs seller Rhetoric + level bonus (max(0, level - 4)), the chr_SkillCheck roll.
  - Price: 30 + 10 * Rhetoric + Bargaining * (8 + Rand(6)) + 12 * level bonus + Rand(41); was 20 * Rhetoric + Rand(101).
  - Touched: `Scripts/Library/GamePlayFormulas.lua`, `Scripts/Measures/Behaviour/behavior_ListenQuacksalver.lua`,
    `tools/modding_helpers/check_quacksalve.lua`; icons `Textures/Hud/{Buttons,MouseIcons,MouseIcons_highlighted}/btn_Quacksalver.tga`
    (originals kept beside them as `btn_Quacksalver_old.tga`)

- [ ] Bank Actions tab: Grant credits and Collect debts, driven by the tab like the hospital.
  - Status: implemented, awaiting user confirmation
  - `Scripts/Library/lib_ManageActions.lua` is the vanilla file plus `mact_RegisterMods` (bank def);
    `bank_SetOfferCredit.lua` reads the tab via `gameplayformulas_MActRule`; new `bank_SetCollectDebts.lua`
    (a player bank never collected: only the AI dynasty tree ran CollectDebts).
  - Debt policy per bank (`DebtPolicy`, set from the bank account dialog, button 9): ask each time, always
    more time, always abate, always demand, or decide by purse; a hand-ordered collection always asks.
  - Actions-tab wording: the priority button now reads as the current setting in all 12 tables.
