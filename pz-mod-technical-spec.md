# The American Household — Technical Implementation Specification
### Companion to design doc v0.6 · written for coding agents with zero prior context

**Status:** **Phase 0 probe COMPLETE (Aug 5 2026, B42.20, 1,421 fills / 52 buildings). Verdict: GO for both mods.** Probe findings are folded into this spec as [PROBED] annotations; the §0.1 gate table records the results. Implementation may begin.
**Read first:** `pz-american-household-design-doc.md` v0.6 — this document assumes its section numbers (§4 residential spec, §5 archetypes, §6 dispositions, §7 recipes, §8 ledger, §9 vehicles, §10 setpieces).
**Prime directive:** the design doc is the contract. Where this spec and the design doc disagree, the design doc wins. Where either disagrees with what the probe found in the actual game, the game wins — update both documents, then code.

---

## 0. Orientation for a fresh agent

You are implementing two Project Zomboid Build 42 mods:

- **Mod A — "The American Household"**: global loot rebalance + full-tree recipe substitution + vehicle spawn multiplier. Pure data-table mutation at merge time plus `craftRecipe` script overrides. No novel API use. Build this first.
- **Mod B — "Knox County Households"**: per-building archetype × disposition system. Depends on `OnFillContainer` and a container→building walk-up chain whose viability the Phase 0 probe (shipped separately as `AHProbe`) either confirmed or refuted. **Do not start Mod B until you have read the probe results.**

> **UPDATE (Aug 2026): shipped as ONE mod.** The probe passed; A and B are now
> a single `AmericanHousehold` mod (Mod B = the `AHB*` files, gated by the
> `ArchetypesEnabled` sandbox option). See the §3 header. Read "Mod A / Mod B"
> throughout this doc as "merge-time layer / fill-time layer."

### 0.1 Probe results gate — RESOLVED

Probe run Aug 5 2026 on B42.20, two sessions (1,081 + 340 fills, 35 + 17 buildings). Results:

| Probe finding | Result | Consequence |
|---|---|---|
| Walk-up chain | **CONFIRMED** — 52 `CHAIN OK` across all room types; zero failures on real furniture containers | Mod B architecture is viable as designed |
| `chain STOP at getParent` | 357 total, **100% of them `room=Container`** — bags spawning nested inside furniture (`Bag_Satchel, parent:null`), not furniture failures | Fill handler must skip `roomType == "Container"` (§3.5 step 2a). These are sub-container fills; the owning furniture's fill was already handled |
| `ItemPickerContainer` | **0 occurrences in 1,421 fills** | Guard retained (cheap) but expect it never to fire on B42.20 |
| Building ID stability | **UNSTABLE, proven** — IDs are sequential load-order counters (run 1: 0,1,2,3…; run 2 continues 22…47) | `getID()` is disqualified. Coordinate keying mandatory (§3.2) |
| BuildingDef bounds | **WORK** — `def:getX/getY/getX2/getY2/getW/getH` all return real map coordinates | Coordinate-hash key confirmed as the building identity |
| `building:getRooms()` | Does not exist (probe's one FAIL line) | Do not use; irrelevant to the design |
| Merge hook | `OnPreDistributionMerge fired` | Mod A mechanism confirmed |
| Pool inventory | **1,420 pools dumped by name** (`AHProbe_pools.txt`) | Design assumption 6 resolved — see §0.3 |
| Vehicle tables | `VehicleZoneDistribution` (55 zone keys: parkingstall, trailerpark, bad/medium/good, sport, junkyard, trafficjamw/e/n/s, police, fire, specialty…) + `VehicleDistributions` + `SandboxVars.CarSpawnRate/CarGeneralCondition/LockedCar/RecentlySurvivorVehicles` | §9 surface fully mapped; ticket 6 unblocked pending one look at the per-zone chance field shape |
| Outdoor containers | 174 `no room at square`, arriving as `roomTypeArg=all` (mailboxes, BBQs, dumpsters) | Bypass Mod B by design, as planned. Note: outdoor fills pass roomType `"all"` |

### 0.3 Confirmed pool names (from the dump — use these, not guesses)

- **Residential kitchen:** `KitchenBaking, KitchenBook, KitchenBottles, KitchenBreakfast, KitchenCannedFood, KitchenDishes, KitchenDryFood, KitchenMicrowave, KitchenPots, KitchenRandom` — the §4.1 Approach-A container-specialization targets.
- **Residential other:** `BathroomCabinet/Counter/Shelf`, `BedroomDresser/Sidetable` (+ `Child/Classy/Redneck` variants), `LivingRoomShelf/SideTable` (+ variants), `WardrobeGeneric/Child/Classy/Redneck`, `ClosetShelfGeneric`, `GarageCarpentry/Firearms/Mechanics/Metalwork/Tools`, `FreezerGarage/Generic/Hunter/Hoarder/TrailerPark/Rich`, `FridgeGeneric/…` (same variant family), `LaundryLoad1–8`, `JunkBin`, `CrateRandomJunk`.
- **KEY FINDING — vanilla proto-archetypes exist:** the `Redneck/Classy/Child/TrailerPark/Hunter/Hoarder/Rich` pool variants and the `DerelictHouse*` family (`Crime/Drugs/Junk/Party/Squatter/Stove`) mean B42 already varies containers by house character. Mod B archetype packages should **reference and extend these themed pools** rather than author from zero — and Phase 0's remaining question for ticket 10 is *what map data selects them* (room def? building class?), since that selector may be reusable.
- **Setpieces, ready-made:** auto parts (`CarBrakes/Muffler/Suspension/Tires{Modern,Normal}1–3`, `CarSupplyBatteries/GasCans/Tools/Literature`), gun retail (15 `GunStore*` pools incl. `Pistols/Rifles/Shotguns/Ammunition/BodyArmor/DisplayCase`), police (`PoliceStorageGuns/Ammunition/Armor`, `PoliceEvidence`), surplus (12 `ArmySurplus*` pools — the store type exists in vanilla), mechanic (`MechanicShelf*`), tool store (12 `ToolStore*`), welding (`WeldingWorkshop*`), electronics (`ElectronicStore*`), liquor (`LiquorStore*` incl. per-spirit pools), tobacco (`TobaccoStore*` incl. `Chew`), grocery (`Gigamart*` ~24 pools, `ProduceStorage*`), industrial bulk (`Crate*` ~200 pools incl. `CrateLumber/SheetMetal/MetalBars/Propane/Tools`), church (`ChurchStorageMisc` — thin; the §10.6 relief hub extends it), medical (`MedicalClinic*`, `MedicalStorage*`, `HospitalRoom*`).
- **Gap:** no `FarmSupply*` room pools. Farm supply is assembled from pieces (`CrateAnimalFeed/Farming/Fertilizer`, `ToolStoreFarming`, `ToolCabinetFarming`, `BarnTools`, `FarmerTools`). The §10.3 farm-supply category requires new room-type mapping — more work than the other three setpiece categories; schedule it last within ticket 7.
- **Curiosity with design relevance:** `FirearmWeapons_Mid/_Late` and `Safehouse*_Mid/_Late` pools show B42 stages some loot by days-survived. Not used by this design, but agents should not be surprised when pool selection has a time dimension.

### 0.2 What is settled and must not be relitigated

Decisions the user has made explicitly (do not "improve" these):

1. Disposition-as-world-state is cut. Dispositions filter loot only (P9). No object spawning, no barricades, no furniture, no per-building vehicle logic.
2. Setpieces (§10) get **no** disposition logic. Uniform pools + the panic layer baked in.
3. Added vehicles are **fuel-neutral** at launch. The compensation lever exists in the doc but is dormant.
4. Firearms are common (per §6.4's archetype table); dispositions supply gun scarcity; ammo is caliber-matched to the gun rolled.
5. Consolidated households (two-building pairing) are **deferred** — do not implement, the design is preserved in open question 10.
6. B42 only. No B41 backport.

---

## 1. Runtime environment — read before writing any Lua

PZ embeds **Kahlua**, a Lua 5.1-subset interpreter, with the game API exposed as Java objects. The following will bite you if you write idiomatic modern Lua:

- **Java collections are not Lua tables.** Anything returned as `ArrayList`/`Vector` uses `:size()` and `:get(i)` with **zero-based** index: `for i = 0, list:size() - 1 do local item = list:get(i) end`. Using `#list` or `ipairs` on these fails or silently does nothing.
- **No `os`, no `io`.** File output only via the game's `getFileWriter(name, createIfNull, append)` → writes under `<Zomboid>/Lua/`. `print()` goes to `console.txt`.
- **No `require`.** All files under `media/lua/{client,server,shared}/` load automatically, alphabetically within folder. Use filename prefixes (`AH00_`, `AH10_`, …) to control load order. Share state via a single global namespace table (see §2.3).
- **Load contexts:** `shared/` loads first (both sides), then `client/`, then `server/`. Distribution and fill logic is **server** context. In singleplayer everything runs in one process, which hides MP bugs — test MP-critical determinism logic with a local dedicated server before shipping.
- **`math.random` is not deterministic across clients.** Never use it for anything that must agree between server/client or across respawns. Use the seeded PRNG in §4.3.
- **Reload workflow:** Lua reloads on game restart. In `-debug` mode the Lua console can hot-reload some files, but distribution merges happen once at world init — **loot changes always need a fresh save to observe.** This is the dominant iteration cost; batch changes accordingly.
- **Version folders:** all code lives under `42/media/...`. `common/media/` only for build-agnostic assets (there are none planned).

---

## 2. Mod A — architecture

### 2.1 File layout

```
AmericanHousehold/
  42/
    mod.info
    poster.png
    media/
      lua/
        shared/
          AH00_Options.lua        -- sandbox option definitions + accessors
          AH01_Data_Tiers.lua     -- tier->weight math (pure functions, no game calls)
          AH02_Data_Residential.lua  -- §4 item tables, declarative
          AH03_Data_Setpieces.lua    -- §10 pool specs, declarative
          AH04_Data_Panic.lua        -- §10.2 panic multipliers, declarative
        server/
          AH10_DistribHelpers.lua -- pool mutation utilities (the only code that touches tables)
          AH11_Residential.lua    -- applies AH02 via helpers at merge time
          AH12_Setpieces.lua      -- applies AH03/AH04
          AH13_Vehicles.lua       -- §9 zone-chance multiplier
      scripts/
        AH_recipes_food.txt       -- §7.3 craftRecipe overrides
        AH_recipes_trades.txt     -- §7.4 craftRecipe overrides
        AH_item_tags.txt          -- tag additions to vanilla items (see §2.5)
```

**Separation rule:** `AH0x_Data_*` files are pure declarative tables + pure functions — no game API calls, unit-testable outside the game in stock Lua 5.1. All game interaction concentrates in `AH1x_*`. Hold this line; it is what makes the mod testable at all.

### 2.2 The merge hook

```lua
-- AH11_Residential.lua (shape, not final code)
Events.OnPreDistributionMerge.Add(function()
    if not AH.Options.enabled() then return end
    AH.Distrib.applyRoomSpecs(AH.Data.Residential)  -- §4 tables
end)
```

All mutation goes through `AH10_DistribHelpers` so there is exactly one place that knows the vanilla table shapes. Required helper surface:

- `setItemWeight(poolName, itemFullName, weight)` — idempotent upsert into a pool's `items` list. **[VERIFIED Aug 2026 against B42.20 game files]** — B42 kept the B41 flat `{name, weight, ...}` shape, plus optional pool flags (`ignoreZombieDensity`, `cookFood`, `onlyOne`) and a `junk` sub-table. Entries use SHORT names (`"Pan"`, module Base implied); AH10 normalizes `Base.X`↔`X` so upserts hit vanilla entries instead of duplicating them. See `reference/README.md`.
- `removeItem(poolName, itemFullName)`
- `scalePool(poolName, factor)` — multiply all weights (panic layer).
- `setRolls(poolName, n)`
- `logDiff()` — after merge, print every change made, one line each, prefix `[AH]`. Non-negotiable: this log is the compatibility debugging story when other loot mods are installed.

**Never** replace a pool table wholesale (`pd.list.X = {...}`); always mutate in place, so other mods' earlier edits survive. This is P8 in code form.

### 2.3 Namespace

One global: `AH = AH or {}` with sub-tables `AH.Options`, `AH.Data`, `AH.Distrib`, `AH.Util`. Mod B extends the same namespace (`AH.B = {}`). No other globals, ever.

### 2.4 Tier → weight math (AH01)

The design doc specifies per-room presence tiers; pools take per-container weights. The bridge, given the design's Approach A (item confined to one container sub-type):

- Target presence `P` for the tier midpoint (T0 .935, T1 .75, T2 .425, T3 .165).
- With Approach A, per-container chance ≈ presence, so solve for weight within the pool's roll count: for a pool drawing `R` rolls where item weight is `w` in total pool weight `W`, per-fill inclusion ≈ `1 - (1 - w/W)^R`. Set equal to `P`, solve `w = W * (1 - (1-P)^(1/R))`.
- `W` and `R` come from reading the actual vanilla pool at merge time — never hardcode; other mods change `W`.
- Cap any single item at 60% of post-edit `W` (pool-competition ceiling; design §3.1). If the solve demands more, log a warning and clamp — that item needs Approach C (Mod B) instead.

Worked example in comments of AH01 required, with the kitchen knife numbers from design §1.1.

### 2.5 Recipe and tag overrides

- `craftRecipe` overrides: redeclare the vanilla recipe name in `AH_recipes_*.txt`; last-loaded definition wins. **Enumerate every overridden name in a generated `OVERRIDES.md`** — build a tiny script or manual checklist; this file ships in the Workshop description (design §11).
- Adding tags to vanilla items: B42 supports item property patching via script `item` blocks in override mode. **Exact syntax unverified** — check how established B42 mods add tags (search Workshop for tag-widening mods) before committing to a pattern. If script-side patching proves unreliable, fallback: `ScriptManager` item mutation from Lua at boot (`getScriptManager():getItem(name)` — verify accessor). Flag whichever path wins in OVERRIDES.md.
- The §7.4 trades matrix ships as data: `AH.Data.Capabilities = { cutting = { ideal={...}, acceptable={...}, improvised={...} }, ... }` — then a generator emits the recipe text or the overrides are written by hand against it. Hand-written is acceptable for v1; the table is still the source of truth for QA.

### 2.6 Vehicles (AH13)

[PROBED] Surface confirmed: `VehicleZoneDistribution` (55 zone keys — `parkingstall`, `trailerpark`, `bad`, `medium`, `good`, `sport`, `junkyard`, `trafficjamw/e/n/s`, `police`, `fire`, `ranger`, plus branded/specialty zones) and `VehicleDistributions` both exist as globals at merge time. Relevant sandbox vars observed: `CarSpawnRate`, `VehicleStoryChance`, `CarGeneralCondition`, `LockedCar`, `RecentlySurvivorVehicles`.

**[VERIFIED Aug 2026]** Field names resolved from `media/lua/shared/Vehicles/VehicleZoneDefinition.lua` (verbatim copy in `reference/`): the per-zone spawn chance is `zone.spawnRate` (%, implicit game default **16** when absent — the multiplier must write `(spawnRate or 16) * m`). Per-vehicle `spawnChance` is a pick-share out of ~100 selecting WHICH model and is never scaled. `business2`–`business12` are aliases of the single `business` table — iterate with table-identity dedupe or the multiplier compounds 12×. AH13 implemented + unit-tested (`tests/test_vehicles.lua`). Requirements met:
- Multiplier from sandbox option, default 1.5, range 1.0–3.0, step 0.1.
- Apply by scaling per-zone spawn *chance* fields only — never touch fuel/condition fields (settled decision 3).
- 1.0 must be a true no-op (skip the loop entirely).
- Log applied multiplier and every zone touched at boot, `[AH]` prefix.

### 2.7 Sandbox options (AH00)

B42 mod sandbox options via `sandbox-options.txt` — **[VERIFIED Aug 2026]** format is unchanged from B41 (`VERSION = 1,` + `option Page.Name { type, min, default, max, page, translation }`), confirmed against a current B42 Workshop mod. Both mods' options ship under the shared `AmericanHousehold` page/namespace (AH00 reads `SandboxVars.AmericanHousehold.*`). Minimum set, per design §11: `AH.Enabled` (bool, default true) · `AH.HouseholdAbundance` (enum Low/Design/High, default Design — scales §4 weights ±20%) · `AH.LedgerEnabled` (bool, true) · `AH.VehicleMultiplier` (float 1.0–3.0, 1.5) · `AH.SetpieceStocking` (enum Panic/Full, Panic) · Mod B adds `AH.ArchetypesEnabled` (bool, true).

---

## 3. Mod B — architecture

> **SHIPPED AS ONE MOD (Aug 2026 decision).** The A/B split existed only to
> gate Mod B behind the Phase 0 probe. The probe passed and all of B's
> assumptions are proven, so the "Mod B" files now live inside the single
> `AmericanHousehold` mod as the `AHB*` prefix family. There is no separate
> mod, no `require`, no second Workshop item. The archetype/disposition layer
> is gated at runtime by the `ArchetypesEnabled` sandbox option instead — off
> = the global loot rebalance only, at near-zero cost (the fill handler
> returns immediately). "Mod A" / "Mod B" below now mean the merge-time layer
> vs. the fill-time layer of one mod.

### 3.1 File layout (as shipped — one mod)

```
AmericanHousehold/
  42/
    mod.info                       -- single mod, no require
    media/
      sandbox-options.txt          -- all options incl. ArchetypesEnabled
      lua/
        shared/
          AH00_Options … AH05_Data_Ledger.lua   -- merge-time layer (Mod A)
          AHB00_Data_Archetypes.lua  -- §5: 10 packages, declarative
          AHB01_Data_Dispositions.lua-- §6: 6 filters + correlation matrix
          AHB02_Data_Firearms.lua    -- §6.4: gun/caliber/ammo + loose ammo
          AHB03_Hash.lua             -- FNV-1a + PRNG, pure functions
        server/
          AH10 … AH13.lua            -- merge-time appliers (distrib/setpiece/vehicle)
          AHB10_Resolver.lua         -- buildingKey -> {archetype, disposition}, cached
          AHB11_FillHandler.lua      -- OnFillContainer entry point
          AHB12_Apply.lua            -- package/guarantee/firearm/filter/condition
          AHB13_Debug.lua            -- debug commands (see §5)
      scripts/
        AH_recipes_food.txt          -- §7 craftRecipe overrides + improvised
```

Load order is alphabetical within `shared/` then `server/`: the `AH0x` data
and `AH1x` appliers load before the `AHB*` family, so the fill-time layer sees
a fully-populated `AH` namespace. This is exactly the old cross-mod ordering,
now guaranteed within one mod instead of via `require`.

### 3.2 Building identity — DECIDED [PROBED]

**Coordinate key, no fallback:** `key = x .. ":" .. y .. ":" .. x2 .. ":" .. y2` from `BuildingDef` via `building:getDef()` — accessors `getX/getY/getX2/getY2` confirmed returning real map coordinates on B42.20. Map data cannot drift across saves, is identical on server and every client, and survives loot respawn.

`building:getID()` is **disqualified by probe evidence**: IDs are sequential load-order counters (session 1 assigned 0,1,2,3…; session 2 continued 22…47). Any code using `getID()` for persistence or seeding is a bug by definition. It remains acceptable as a session-local cache key only if the coordinate key has already been derived and stored against it — but the simple rule is: coordinate key everywhere, always.

### 3.3 Determinism stack (AHB03)

Everything per-building must be a **pure function of (buildingKey, worldSeed, purpose-tag)**:

```lua
-- FNV-1a 32-bit over a string; arithmetic-only (Kahlua has no bit library).
-- Standard constants: offset 2166136261, prime 16777619; emulate uint32
-- with % 4294967296 after each multiply. Multiplication of numbers up to
-- 2^32 * 16777619 exceeds 2^52 — SPLIT the multiply into high/low 16-bit
-- halves to stay inside Lua's exact-integer double range. This is the one
-- subtle function in the mod; unit-test it against known FNV-1a vectors
-- outside the game first.
AH.B.hash(str) -> uint32

-- Deterministic PRNG: mulberry32-style mixer seeded from hash.
-- Same constraint: implement with 16-bit half multiplies.
AH.B.rng(seed) -> function() -> [0,1)
```

Usage pattern — the purpose-tag prevents correlated streams:

```lua
local seed = AH.B.hash(buildingKey .. "|" .. getWorld():getWeather() ... )
-- NO. Nothing environmental. Only:
local seed  = AH.B.hash(worldSeedString .. "|" .. buildingKey)
local arch  = pickWeighted(archetypeWeightsFor(region), AH.B.rng(AH.B.hash(seed .. "|arch")))
local disp  = pickWeighted(matrixRow(arch),             AH.B.rng(AH.B.hash(seed .. "|disp")))
```

`worldSeedString`: use the save's world seed if accessible (probe/verify `getWorld():getRandomizedZoneSeed()` or similar); else a sandbox-option string the server sets once. Purpose: two saves shouldn't have identical house assignments.

### 3.4 The resolver (AHB10)

```lua
local cache = {}  -- buildingKey -> {arch=, disp=, region=}
function AH.B.resolve(building)
    local key = AH.B.keyOf(building)          -- §3.2
    local hit = cache[key]
    if hit then return hit end
    -- region: point-in-rectangle over a small static list of map regions
    -- (Muldraugh core, outskirts, West Point, highway corridor) using the
    -- building's x/y. Rectangles are data in AHB00.
    ...
    cache[key] = result
    return result
end
```

Cache is session-local and safe *because* resolution is pure — eviction never changes answers. Do not persist it; do not ModData it. (ModData would turn a pure function into stored state and break respawn determinism — design §11 requirement.)

### 3.5 Fill handler (AHB11) — the contract

```
OnFillContainer(roomType, containerType, container):
  1. if not AH.Options.archetypesEnabled() return
  2a. if roomType == "Container" -> return                              [PROBED: nested-bag
      fills (e.g. Bag_Satchel spawned inside a wardrobe) arrive with this literal roomType
      and a nil parent — 357/357 of the probe's getParent failures were these. The owning
      furniture container gets its own separate fill event; skipping loses nothing.]
  2b. if roomType == "all" -> return                                    [PROBED: outdoor/
      zone containers (mailboxes, BBQs, dumpsters) pass "all" and have no room. Mod A-only.]
  2c. if classOf(container) contains "ItemPicker" -> counter++, return  [PROBED: never fired
      in 1,421 fills on B42.20; keep the guard anyway, it costs three lines]
  3. walk up: getParent -> getSquare -> getRoom -> getBuilding
     any nil -> return silently (roomless residual cases are Mod A-only BY DESIGN)
  4. r = AH.B.resolve(building)
  5. if building is not residential (room types whitelist) -> return    (setpieces are Mod A's)
  6. AH.B.apply(container, roomType, containerType, r)                  (AHB12)
```

Failure policy (design §11): **degrade, never break.** Every step pcall-guarded; on unexpected error, log once per session per error-site, return. The mod without Mod B is just Mod A, which is a valid game.

### 3.6 Apply semantics (AHB12)

Order of operations per container, and this order is load-bearing:

1. **Archetype package**: additive insertions for this (archetype, roomType, containerType). Data-driven from AHB00: `{item="Base.X", count={min,max}, condition={min,max}, rooms={...}, containers={...}}`.
2. **Approach C guarantees** (T0 categories + junk drawer): fires only on a designated trigger container per room (e.g., first `counter` fill in a `kitchen`); checks category presence across *already-filled sibling containers is impossible* at this granularity — so instead: guarantee runs on the trigger container deterministically (the rng decides which knife, not whether). Simpler and sufficient; document the simplification.
3. **Firearm roll** (§6.4): archetype table -> gun pick -> `caliber` returned -> ammo insertion in same container using caliber-keyed ammo table (AHB02). One code path; no independent ammo rolls anywhere in Mod B.
4. **Disposition filter**: category-based removal/depletion over the container's *final* contents: `{removeCategories={...}, depleteRanges={food={0.0,0.2}}, scatter=bool}`. Category membership = item tag / script category lookup, cached per item type. Scatter=true relocates a fraction of removed items into other containers *in the same room* (never across rooms; never spawns).
5. **Condition variance** (design §1.3): final pass, sets condition on tools/durables from the archetype's condition profile.
6. **Barter cache / fridge note** (v0.6): keyed off (disposition, rng) — cache is step-1-style insertion; notes are Phase 6 items, stub the hook now.

### 3.7 Firearm data shape (AHB02)

```lua
AH.B.Data.Firearms = {
  archetypeProfiles = {
    hunting = { chance=0.97, guns={ {item="Base.HuntingRifle", caliber="308", w=4}, ... },
                gunCount={2,4}, ammoRounds={60,150}, container="wardrobe|gunCabinet" },
    commuter = { chance=0.40, guns={...}, gunCount={1,1}, ammoRounds={15,40}, container="nightstand" },
    ...
  },
  ammoByCaliber = { ["308"]={"Base.308Box"}, ... },  -- fill from B42 item list at Phase 0
}
```

Vanilla B42 item names for guns/ammo must come from the actual `media/scripts` — **do not guess item IDs**; wrong IDs fail silently in insertion code.

---

## 4. Cross-cutting requirements

- **Logging:** every mutation path logs at boot/first-use with `[AH]`/`[AHB]` prefixes. A `AH.Options.verbose()` sandbox toggle gates per-fill logging (off by default; on = the QA mode).
- **Idempotence:** loot respawn re-fires OnFillContainer. Steps 1–6 in §3.6 must produce identical results for identical (buildingKey, container) — guaranteed by the determinism stack, but never add a "have I run before" flag; re-running IS the design.
- **MP:** all logic server-side; clients need the mod only for recipe scripts and item definitions. Test matrix: SP, host-local co-op, dedicated server.
- **Performance budget:** resolver O(1) after first hit per building; apply pass O(items in container). No global scans in the fill path. The pool-mutation pass at merge time may be arbitrarily slow (runs once).

## 5. Debug tooling (AHB13) — build this FIRST in Mod B

Without this, nothing is testable. Lua console functions (available in `-debug`):

- `AHB_where()` — building under player: key, archetype, disposition, region, cache state.
- `AHB_audit(n)` — resolve n random known buildings, print distribution histogram (checks archetype weighting sanity without walking the map).
- `AHB_recount()` — dump per-room item counts for the building under the player vs. the design targets (F3 duplication check, semi-automated).
- `AH_diff()` — Mod A: re-print the merge-time change log.

## 6. Testing protocol (from design §13, operationalized)

- Every loot observation requires a **fresh save** or unvisited cells. Script the route: the design's ten-house Muldraugh route, addresses fixed in `TESTPLAN.md` (create at Phase 1; keep with the repo).
- Metrics collection: `AHB_recount()` output per house, pasted into a per-run sheet. Automate later if iteration count justifies it; do not build tooling speculatively.
- Unit tests for pure code (AH01 math, AHB03 hash/PRNG against FNV test vectors, tier solver clamps): run in stock Lua 5.1 outside the game. These are the only fast tests; maximize what lives behind them.
- Failure conditions F1–F8 (design §13) each get a named check in `TESTPLAN.md` with its measurement procedure.

## 7. Suggested implementation order (tickets)

| # | Ticket | Depends on | Acceptance |
|---|---|---|---|
| 1 | Repo scaffold, mod.info ×2, namespace, logging util | — | Mods load, `[AH] loaded` in console |
| 2 | AH01 tier math + unit tests | — | Vectors pass in stock Lua |
| 3 | AH10 helpers + logDiff | probe: pool table shape | One test edit visible in-game |
| 4 | AH02/AH11 kitchen slice (design Phase 1) | 2,3 | Ten-kitchen route hits §4.1 tiers ±10% |
| 5 | Full §4 residential + §8 ledger data | 4 | Route metrics vs design targets |
| 6 | AH13 vehicles | probe: A4 | Multiplier visible; 1.0 no-op verified |
| 7 | AH03/AH12 setpieces + panic layer | probe: A6 pool names | Auto parts store reads per §10.3 |
| 8 | §7 recipe audit + overrides + OVERRIDES.md | — (parallel) | Sandwich craftable with any blade; welding still gated |
| 9 | AHB03 hash/PRNG + unit tests | — | FNV vectors pass; distribution uniform |
| 10 | AHB10 resolver + AHB13 debug tools | probe: chain, key | `AHB_where()` stable across reload |
| 11 | AHB11/12 military archetype only, no dispositions | 10 | Military houses visibly military; F3 clean |
| 12 | Remaining archetypes | 11 | Histogram matches design weights |
| 13 | Dispositions + §6.4 firearms | 12 | Ten-house route: 2–4 guns, calibers coherent |
| 14 | Barter caches, survivalist lock, panic-electronics | 13 | Spot checks |

Tickets 1–8 are Mod A and can proceed **regardless of probe outcome**. Tickets 9–14 are gated.

## 8. Open items this spec inherits (do not resolve silently)

1. ~~Vehicle table names / per-zone chance field~~ — **fully resolved Aug 2026**: `VehicleZoneDistribution` lives in `media/lua/shared/Vehicles/VehicleZoneDefinition.lua` in B42; chance field is `spawnRate` (§2.6). AH13 written and unit-tested.
2. ~~B42 pool *entry* shape~~ — **resolved Aug 2026 from game files**: B41-style flat pairs confirmed; short names, module Base implied; optional pool flags. See §2.2 and `reference/README.md`. AH10 updated + unit-tested (`tests/test_distrib.lua`).
3. Item-tag patching syntax in B42 — research against current Workshop mods (§2.5).
4. World-seed accessor for the determinism stack (§3.3).
5. Junk-drawer trigger-container choice (§3.6 step 2 simplification) — pick during ticket 4, document in code.
6. ~~B42 `sandbox-options.txt` format~~ — **resolved Aug 2026**: matches B41 (§2.7); both mods' options files written.
7. **New (from probe):** what map data selects the vanilla themed pool variants (`WardrobeRedneck`, `FridgeTrailerPark`, `DerelictHouse*`) — room def property or building class? If accessible at fill time, Mod B's archetype system can piggyback on the game's own house-character signal. Investigate during ticket 10.
8. **New (from probe):** farm supply has no dedicated room pools (§0.3 gap) — that §10.3 category needs new room-type mapping; schedule last within ticket 7.
