# Handoff — implementation status

**One mod now.** `AmericanHousehold` contains everything; the former
`KnoxCountyHouseholds` (Mod B) was merged in as the `AHB*` file family after
its Phase 0 assumptions were all proven. The archetype/disposition layer is
gated by the `ArchetypesEnabled` sandbox option (default on). No `require`, no
second Workshop item.

## What is DONE and unit-tested (lua5.1, `tests/`, all green)

Run: `cd tests && for t in test_tiers test_hash test_distrib test_vehicles test_modb; do lua5.1 $t.lua; done`

**Merge-time layer (formerly Mod A) — global loot rebalance:**
- `AH00_Options` namespace/logging/sandbox accessors · `AH01_Data_Tiers` the
  COUNT model + `planPool` (issue #2 fix) · `AH02_Data_Residential` full §4
  data, verified IDs · `AH03_Data_Setpieces` §10 stocking · `AH04_Data_Panic`
  §10.2 panic layer · `AH05_Data_Ledger` §8 numbers.
- `AH10_DistribHelpers` pool mutation (confirmed B42 shape, name normalization)
  · `AH11_Residential` pool-grouped count solve · `AH12_Setpieces` rolls-based
  stocking/panic · `AH13_Vehicles` spawn multiplier.
- `scripts/AH_recipes_food.txt` — 16 verbatim recipe overrides (mixing-vessel
  and rolling-pin lists widened) + 4 improvised can-opening recipes.
  `OVERRIDES.md` is the shipped conflict-surface doc.

**Fill-time layer (formerly Mod B) — per-building archetypes:**
- `AHB00_Data_Archetypes` 10 packages, region rectangles, archetype weights,
  Approach-C guarantee sets, barter caches, once-per-building durable flags ·
  `AHB01_Data_Dispositions` 6 filters + correlation matrix (survivalist
  hard-locked) · `AHB02_Data_Firearms` real gun/caliber/ammo IDs + coherent
  loose ammo · `AHB03_Hash` FNV-1a + PRNG (13 vectors).
- `AHB10_Resolver` coordinate-key resolver + world-seed chain · `AHB11_FillHandler`
  §3.5 contract · `AHB12_Apply` the six-step pass with anti-pile-up memos +
  fridge notes (§6.6, one existing lore item per disposition — no new art) ·
  `AHB13_Debug` `AHB_where/AHB_audit/AHB_recount/AHB_counters/AH_diff`.

**Scope: NO NEW ART (settled decision 7).** The mod is pure data + Lua. Every
`[new]`-item feature the design flagged is cut or repurposed from an existing
B42 item; nothing waits on art. No `poster.png` or icons needed to ship.

**Issue #2 (kitchen repetition) — FIXED.** Root cause: presence-targeting in a
4-roll pool forces high counts and pool domination. Now: bounded expected
COUNT per tier, two caps (item ≤12%, pool add ≤35%), order-independent
`planPool`. Plus fill-time anti-pile-up memos so guarantees/barter/unique
durables fire once per room/building. Locked in as a named regression in
`test_tiers.lua`. Reply posted on the issue.

## What is UNTESTED IN-GAME (the whole thing — needs a fresh save)

No part of this has run inside the actual game yet. The unit tests cover the
pure logic; the game-facing API calls (AddItem, getItems, walk-up chain,
condition/charge setters) are pcall-guarded and follow documented B42
signatures but need one live run. `TESTPLAN.md` is the script: boot
expectations, the ten-house route, the setpiece route, F1–F8 checks, and the
determinism/MP protocol.

## Ledger (§8) — now fully wired
- Quantity lines (Mod A merge-time) + charge lines D/E/F (`AHB14_Ledger`,
  fill-time, residential-only, gated by `LedgerEnabled`): batteries spawn
  ~30% dead, fuel/propane/lighter-fluid partial, pill bottles part-used.
  `LedgerEnabled` is now actually consumed.
- Line B bag-capacity −20% still needs item patching (open item 3). Line C
  food scarcity ships neutral by decision (measure first).

## Open items (tech spec §8) still genuinely open
- **3. Item-tag patching syntax** — the safe way to add a capability tag to a
  vanilla item (e.g. `base:wrench` on PipeWrench) is unresolved; the research
  agent hit the session limit mid-investigation. The recipe overrides don't
  need it (they widen item lists directly), so nothing is blocked — but a few
  substitutions would be cleaner as tag additions. Pick up here.
- **4. World-seed accessor** — the resolver uses a defensive chain
  (sandbox override → `getRandomizedZoneSeed` probe → world name → constant).
  Confirm which link fires in-game; `constant` means saves share assignments.
- **5. Junk-drawer trigger container** — chose `counter`/`KitchenRandom`;
  validate it feels right on the route.

## Immediate next actions
1. **In-game smoke test (you):** one mod in `Zomboid/mods/`, enable it, new
   save, read console. Expect zero WARN lines and the pass summaries
   (residential/vehicle/setpiece/panic + `[AHB] fill handler registered` +
   `world seed source`). Then walk the issue-#2 kitchens: knife/vessel/opener
   ~one each, cutting boards rare, no two kitchens identical.
2. Work the F1–F8 route in `TESTPLAN.md`; feed `AHB_recount()` output back.
3. Resolve open items 3–5 from observations.

## Reference material (so the game files never need re-uploading)
`reference/` holds the B42.20 item-ID index (5,120), per-pool stats (1,424),
verbatim kitchen pools, and the vehicle zone file. `reference/README.md`
records what each settled.

## Known booby traps (all survived once)
- Kahlua: zero-indexed Java collections (`:size()`/`:get(i)`), no `require`,
  no bitops, alphabetical load order (hence the numeric filename prefixes).
- Loot fills once per container at first load — every observation needs a
  fresh save. `console.txt` is overwritten per launch; copy it first.
- Within a pool the game normalizes weights, so scaling all weights is a
  no-op — depth/scarcity is controlled by a pool's ROLL COUNT (see AH12).
- Vanilla pool entries are short names (`"Pan"`, module implied); never insert
  `Base.`-prefixed names into pools outside AH10 (it normalizes).
- Fill-time duplication: anything meant to happen once per room/building needs
  a session-local memo (guarantees, barter, unique durables) — OnFillContainer
  fires per container, and a room has many.
