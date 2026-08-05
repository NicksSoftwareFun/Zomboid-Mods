# Handoff — Code session pickup point

**State as of this commit** (Code session, Aug 5 2026, after game-file verification pass):

## What exists and is TESTED (lua5.1, tests/ directory, all green)
- `AH01_Data_Tiers.lua` — tier→weight solver, presence math, per-container targets, pool-share clamp. 19 passing tests including design-doc §1.1 worked example.
- `AHB03_Hash.lua` — Kahlua-safe FNV-1a (no bitops, split-multiply mod 2^32) verified against independently generated reference vectors, incl. a real probe building key; deterministic LCG rng; pickWeighted. 13 passing tests.
- `AH10_DistribHelpers.lua` — pool mutation, now against the **confirmed** B42.20 pool shape, with `Base.X`↔short-name normalization. New `tests/test_distrib.lua` (21 checks) guards the upsert/remove/exclude paths against a verbatim-shaped fake pool.
- `AH13_Vehicles.lua` — §2.6 vehicle spawn multiplier, written against the verified `spawnRate` field (implicit default 16), with business2–12 alias dedupe and the 1.0 true-no-op. `tests/test_vehicles.lua` (12 checks) covers scaling, cap at 100, alias-once, and the no-op.

Run tests: `cd tests && lua5.1 test_tiers.lua && lua5.1 test_hash.lua && lua5.1 test_distrib.lua && lua5.1 test_vehicles.lua`

## Resolved this session (from uploaded B42.20 game files — extracts in `reference/`)
- **Pool entry shape (was open item 2): CONFIRMED** — B41-style flat `{name,w,...}` pairs + `junk` sub-table + optional flags (`ignoreZombieDensity`, `cookFood`, `onlyOne`). `shapeOf()` was already correct.
- **Entry naming trap found & fixed:** vanilla entries are SHORT names (`"Pan"`); upserting `"Base.Pan"` would have added a duplicate instead of updating. AH10 now matches either spelling and inserts short form.
- **Solver correctness fix:** nearly every AH02 item already exists in its vanilla pool, and the AH01 solve assumes the item is *added* — `totalWeight(pool, excludeItem)` now excludes the item's own vanilla weight from W (AH11 passes it).
- **All AH02 item IDs verified** against the 5,120-id index (`reference/b42.20_item_ids.txt`). Three were wrong and are fixed: `MixingBowl`→`Bowl`, `SpoonWooden`→`Spoon`, `CuttingBoard`→`CuttingBoardWooden`+`CuttingBoardPlastic` (moved to KitchenPots, vanilla's placement, T2 each ≈ combined T1). No `unverified` flags remain.
- **Sandbox options (was open item 6):** B42 format = B41 format (verified against a live B42 mod). `sandbox-options.txt` + EN translations written for both mods, matching AH00's `SandboxVars.AmericanHousehold.*` accessors exactly.
- **Vehicle zones (was open item 1):** `VehicleZoneDistribution` moved to `media/lua/shared/Vehicles/VehicleZoneDefinition.lua` in B42. Chance field = `spawnRate` (%, implicit default 16). `spawnChance` inside `vehicles` is a model pick-share — never scale it. `business2`–`business12` alias one table (dedupe by identity). AH13 written + tested; ticket 6 code-complete pending in-game verify.

## Still open
- Item-tag patching syntax (open item 3), world-seed accessor (4), junk-drawer trigger (5) — unchanged.

## Immediate next actions
1. **In-game smoke test (user):** copy both mod folders into `Zomboid/mods/`, enable American Household only, new save, read console. Expected now: **zero shape warnings, zero item-ID warnings**, a `residential pass: 17 applied, 0 skipped` line, and a `vehicle pass: multiplier 1.50` block listing every zone scaled once (business aliases logged as such). Turn on Verbose in sandbox options for per-change logDiff. Any warning at all is a finding — copy console.txt out before relaunching.
2. Ticket 4 acceptance: ten fresh kitchens, count knives/pans/openers vs §4.1 tiers ±10%. Tune `nContainers` estimates from observation (vanilla pool weights for offline sanity checks are in `reference/b42.20_kitchen_pools.lua`).
3. Ticket 6 acceptance: multiplier visibly raises street/parking vehicle counts; set VehicleMultiplier=1.0 and confirm the console shows the no-op line and counts match vanilla.
4. Then tickets 5–8 (full residential, setpieces, recipes) per tech spec §7.
5. Mod B: scaffold exists (mod.info + AHB03 only). Next file is `AHB10_Resolver.lua` per tech spec §3.4 — coordinate key from `getDef()` bounds (PROBED: `getX/getY/getX2/getY2` confirmed; `getID()` disqualified — sequential counters).

## Read-first documents
1. `pz-american-household-design-doc.md` v0.6 — the contract. Settled decisions in tech spec §0.2; do not relitigate.
2. `pz-mod-technical-spec.md` — architecture + [PROBED]/[VERIFIED] annotations + 14-ticket order.
3. `reference/README.md` — what was extracted from the game files and what it settled.
4. Probe logs (console_run1/2.txt) if odd behavior appears — 1,421 fills of ground truth.

## Known booby traps (all documented, all already survived once)
- Kahlua: zero-indexed Java collections (`:size()`/`:get(i)`), no `require`, no bitops, alphabetical file load order (hence AH00/AH01/... prefixes).
- Loot fills once per container at first load — every observation needs a fresh save. Budget it.
- `roomType == "Container"` fills are nested bags; `"all"` is outdoors. Mod B skips both.
- `console.txt` is overwritten per launch. Copy before relaunching.
- Vanilla pool entries are short names, module implied — never insert `Base.`-prefixed names into pools (AH10 normalizes, but data files elsewhere must not bypass AH10).
- Game files use CRLF and mixed tabs/spaces (`KitchenMicrowave` is space-indented) — pattern-matching scripts against them must tolerate both.
