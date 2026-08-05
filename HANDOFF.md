# Handoff — Code session pickup point

**State as of this commit** (built in Cowork, Aug 5 2026, after the Phase 0 probe GO):

## What exists and is TESTED (lua5.1, tests/ directory, all green)
- `AH01_Data_Tiers.lua` — tier→weight solver, presence math, per-container targets, pool-share clamp. 19 passing tests including design-doc §1.1 worked example.
- `AHB03_Hash.lua` — Kahlua-safe FNV-1a (no bitops, split-multiply mod 2^32) verified against independently generated reference vectors, incl. a real probe building key; deterministic LCG rng; pickWeighted. 13 passing tests.

Run tests: `cd tests && lua5.1 test_tiers.lua && lua5.1 test_hash.lua`

## What exists and is UNTESTED IN-GAME (written defensively, degrades with warnings)
- `AH00_Options.lua` — namespace, logging, sandbox-var accessors with defaults.
- `AH10_DistribHelpers.lua` — pool mutation. **Assumes B41 flat `{name,w,...}` item shape; `shapeOf()` refuses unknown shapes with a warning.** First in-game task: load, check console for shape warnings (tech spec open item 2).
- `AH02_Data_Residential.lua` — kitchen slice data. **Item IDs marked `unverified=true` are guesses** — verify each against `steamapps/common/ProjectZomboid/media/scripts/` (item scripts). Bad IDs log a warning and skip; the warning list IS the work list.
- `AH11_Residential.lua` — merge pass wiring it together.
- Both mod.info files + required `common/` folders (B42 silently ignores mods without `common/` — learned the hard way).

## Immediate next actions (tech spec ticket order)
1. Copy both mod folders into `Zomboid/mods/`, enable American Household only, new save, read console: shape warnings? item-ID warnings? Fix AH02 IDs / AH10 shapeOf as indicated.
2. Ticket 4 acceptance: ten fresh kitchens, count knives/pans/openers vs §4.1 tiers ±10%. Tune `nContainers` estimates from observation.
3. Then tickets 5–8 (full residential, vehicles, setpieces, recipes) per tech spec §7.
4. Mod B: scaffold exists (mod.info + AHB03 only). Next file is `AHB10_Resolver.lua` per tech spec §3.4 — coordinate key from `getDef()` bounds (PROBED: `getX/getY/getX2/getY2` confirmed; `getID()` disqualified — sequential counters).

## Read-first documents
1. `pz-american-household-design-doc.md` v0.6 — the contract. Settled decisions in tech spec §0.2; do not relitigate.
2. `pz-mod-technical-spec.md` — architecture + [PROBED] annotations + 14-ticket order.
3. Probe logs (console_run1/2.txt) if odd behavior appears — 1,421 fills of ground truth.

## Known booby traps (all documented, all already survived once)
- Kahlua: zero-indexed Java collections (`:size()`/`:get(i)`), no `require`, no bitops, alphabetical file load order (hence AH00/AH01/... prefixes).
- Loot fills once per container at first load — every observation needs a fresh save. Budget it.
- `roomType == "Container"` fills are nested bags; `"all"` is outdoors. Mod B skips both.
- `console.txt` is overwritten per launch. Copy before relaunching.
