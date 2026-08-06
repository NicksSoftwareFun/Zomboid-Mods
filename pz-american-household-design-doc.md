# The American Household
### A loot distribution and crafting design specification for Project Zomboid, Build 42

**Version:** 0.6 — the collapse layer
**Target build:** 42.20 stable
**Setting:** Knox Country, Kentucky — Ohio Valley / Fort Knox corridor, July 1993
**Scope:** All loot-bearing structures and the full crafting tree. Residential gets realism *plus* variance; the specialized world gets realism *minus* variance.

> **Version history:**
> - **v0.2** — regional layer rebased from Appalachia to the Ohio Valley / Fort Knox corridor; archetypes replaced the unimplementable rural/suburban split; per-container math corrected; ledger rebuilt with numbers.
> - **v0.3** — restructured as two mods; disposition layer added (loot-state only; world-state cut permanently as P9); implementation hooks corrected (merge event for global work, `OnFillContainer` for per-building work); vehicle spawn baseline added.
> - **v0.4** — vehicles made fuel-neutral at launch; firearms doctrine inverted — guns common as durables, dispositions supply the scarcity, ammo caliber-matched per archetype (§6.4).
> - **v0.5** — P6 (residential only) retired. The philosophy extends to the entire game: setpiece doctrine (§10) — rare, fixed buildings are **resource pools**, no disposition logic, balanced by access cost, one lore-baked panic exception for food/gun/pharmacy retail. Recipe substitution extends to all crafting domains (§7). All v0.5 work is Mod A technology.
> - **v0.6 — this version.** The collapse layer: historically grounded creative direction from real societal-turmoil records. New principle **P12 (the 72-hour error / wealth inversion)** · **the 1993 calendar** (§5.14) — LA riots, Storm of the Century, Waco, and the concurrent Great Flood of 1993 as lore anchors · **survivalist archetype** (§5.13) · **barter caches and worthless-cash texture** (§6.5) · **fridge notes** (§6.6) · **church relief hub** setpiece (§10.6) · electronics retail added to the panic layer. **Consolidated households: designed but deferred** (open question 10) — the two-building manifest mechanism multiplies test surface; revisit after Mod B stabilizes.

---

## 0. Read this first — verified vs. assumed

**Verified:**

- Build 42.20 went stable in July 2026; correct target.
- B42 replaced the B41 `recipe` block with `craftRecipe` (separate `inputs`/`outputs`, tag-based matching).
- Global loot is driven by `ProceduralDistributions.lua` (named pools) and `Distributions.lua` (room/container → pool mapping), mutable at merge time. **Commercial and institutional room types have their own named pools in the same tables — the §10 work uses the identical proven mechanism.**
- `OnFillContainer(roomType, containerType, container)` exists, server-side, fires on first fill and respawn; documented `ItemPickerContainer` substitution gotcha.
- `IsoBuilding:getID()` exists.
- B41.78 baseline, `KitchenKnife`: 4–6% per residential kitchen container; restaurant kitchens 16–20%; **knife retail 100% — vanilla already concedes the §10 principle that a store is a warehouse of its own category. It just applies it inconsistently.**
- Vehicle spawns are zone-driven; distribution tables mutable from server Lua (established Workshop pattern).
- B42 added basements to map generation.

**Assumed, pending the Phase 0 probe (§12):**

1. **Walk-up chain** (container → object → square → room → building) — Mod B's single unverified link.
2. **Building ID stability** across save/reload and MP; fallback is coordinate hash from `BuildingDef`.
3. **B42 parity for `OnFillContainer`.**
4. Exact B42 vehicle table names and sandbox variable.
5. All container/pool/tag names herein are illustrative until confirmed against the local install.
6. Which specialized room types exist as distinct distribution pools in B42 (auto parts vs. generic storage, farm supply, surplus) — determines whether §10 edits existing pools or must define new room-type mappings. Both are Mod A tech; the second is more work.

### 0.1 Project structure: two mods

| | Contents | Tech status | Ships |
|---|---|---|---|
| **Mod A — "The American Household"** | Residential baseline rebalance (§4) · **the specialized world (§10)** · full-tree recipe substitution (§7) · scarcity ledger (§8) · vehicle baseline (§9) | **Proven end to end** — merge-hook mutation, `craftRecipe` overrides, vehicle-table edits | First, independently |
| **Mod B — "Knox County Households"** | Archetypes (§5) × dispositions (§6) · house-level guarantees (Approach C) · caliber-coherent firearm spawns (§6.4) | **Gated on the Phase 0 probe** — all unproven assumptions live here | Second, requires Mod A |

The v0.5 expansion adds nothing to Mod B. Setpieces need no per-building variance, so the entire specialized world rides Mod A's proven mechanism. Mod A alone now delivers: the sandwich fix, honest stores, a full recipe tree, and more cars.

---

## 1. Design thesis

The loot model has a category error: **it treats durable goods as consumables.** A can opener is bought once and lives in a drawer for twenty years. So is a socket set, a headlight in a parts store's inventory, a box of brake pads in its stockroom. Presence should be near-certain; the game rolls dice instead.

### 1.1 The defect is variance, not rate

The B41.78 kitchen-knife figure is per container: ~6 containers at 4–6% gives ~26% per-room presence — a quarter of kitchens, not a twentieth, but still noise where reality has certainty. Real households own exactly one to five knives with near-certainty; the game models drawers that independently and rarely conjure them. The player experiences the variance, not the mean: three knives in one kitchen, none in most. **The goal is not "more knives" — it is "exactly one knife block, where a knife block goes, in essentially every kitchen."**

### 1.2 Scarcity relocation

| Category | Reality in 1993 | Should be |
|---|---|---|
| Knives, tools, cookware, buckets | Owned permanently | Near-certain, low variance, quality-variable |
| Firearms | ~Half of KY households; durable goods | Common, archetype-typed, disposition-filtered (§6.4) |
| Ammunition | Boxes matched to the guns owned | Archetype-scaled, caliber-coherent; the consumable half of the gun system |
| Fuel, batteries, propane, kerosene | Small quantities on hand | Scarce, depleting |
| Medicine | A bottle with a pill count | Present, quantity-limited |
| Fresh/frozen food | Abundant, then spoils | Abundant, then a liability |
| Canned/preserved food | A pantry, not a bunker | Modest — except canning households |

### 1.3 Friction from condition, not absence

A house always has a knife; it might be a dull paring knife with a loose handle. Absence is binary and frustrating; condition is analog and interesting.

### 1.4 What encumbrance does and does not solve

Tools are heavy and mostly don't stack; durable abundance is substantially self-limiting. Exceptions needing explicit payment: **bags** (raise the carry ceiling itself — ledger B) and **fuel** (ledger F; vehicle fuel deferred per §9.3).

### 1.5 Dispositions close the fiction gap

Residential abundance is diegetic: the stocked kitchen belongs to the family that never made it home. Dispositions also supply the variance that keeps one-house completion (F1) at bay.

### 1.6 The two regimes

v0.5 completes the thesis. The same realism principle produces **opposite treatments** at the two ends of the world:

| | Residential | Specialized (stores, industrial, institutional) |
|---|---|---|
| Frequency | Everywhere | Rare, fixed, known locations |
| Realism means | What a household owns | What a business stocks |
| Variance | **Added** — archetypes × dispositions make every house a story | **Removed** — a setpiece is a reliable resource pool |
| Balance mechanism | Disposition filtering + ledger | **Access cost**: distance, zombie density, logistics |
| Fiction | "Who lived here, and what did they do?" | "Nobody emptied a warehouse in a week" |

A house is a *story*; a store is a *destination*. Rolling looted-vs-intact on an auto parts store wastes the one thing a setpiece has that houses don't: the player plans an expedition around it. The store's job is to be worth the trip; the trip's job is to be expensive.

---

## 2. Design principles

- **P1 — Ownership realism.** Household ownership rate maps to per-room presence; a ceiling, not a synonym for certainty.
- **P2 — Durables are low-variance, consumables are high-variance.**
- **P3 — Additions to the consumable pool are paid for.** Durables pay by encumbrance (exceptions per §1.4).
- **P4 — Condition over absence.**
- **P5 — Guarantee the category, randomize the instance.**
- **P6 — Two regimes.** *(Rewritten in v0.5; formerly "residential only.")* Residential buildings get the archetype × disposition treatment. Specialized buildings are **resource pools**: full commercial-inventory stocking, no disposition logic, no per-building variance. Balance is access cost, never RNG. One exception: the §10.2 panic layer — a uniform, lore-baked reduction on food, gun, and pharmacy *retail*, applied identically to every instance. It is written into the pools themselves, not rolled per building.
- **P7 — Period accuracy is a hard constraint.** July 1993.
- **P8 — No vanilla file replacement.** Definition-level overrides permitted and documented as the conflict surface.
- **P9 — Dispositions filter, never build.**
- **P10 — Respect player settings.** Sandbox choices compose; they are never silently overwritten.
- **P11 — Substitution bows to physics.** *(New in v0.5.)* Degrade-don't-gate extends to every crafting domain, but the substitution floor is physical plausibility. Any wrench turns a bolt badly; no campfire TIG-welds. Where reality has a hard gate, the game keeps it — and nowhere else.
- **P12 — The 72-hour error.** *(New in v0.6.)* Panic loots the *old* world's valuables. In every real riot and collapse on record, the first 72 hours strip what had pre-crisis value — electronics, liquor, sneakers, jewelry — while the newly priceless sits untouched, because nobody yet knows the world changed categories. The same law inverted at household scale: pre-collapse wealth correlates *negatively* with post-collapse utility. The doctor's house is golf clubs, art, and a gun safe with one pistol; the handyman's trailer is the jackpot. Applied at retail in §10.2, at households through archetype design, and discovered by the player rather than told.

---

## 3. Availability tiers (residential)

Per-room presence, contiguous bands. T0 is house-scoped with one owning room (§4.9).

| Tier | Name | Per-room presence |
|---|---|---|
| **T0** | Fixture | 90–100% |
| **T1** | Common | 60–90% |
| **T2** | Occasional | 25–60% |
| **T3** | Uncommon | 8–25% |
| **T4** | Rare | under 8% — leave vanilla |

### 3.1 The per-container problem

Per-room presence at per-container chance *p* over *n* containers is 1 − (1 − p)ⁿ, expected count *np*; naive weight increases multiply counts. **Approach A** — confine the item to one container sub-type (n = 1; real ceiling is pool competition, ~85%). **Approach B** — deliberate spread where multiples are plausible. **Approach C** — house-level guarantee pass at fill time; T0 items and the junk drawer only (~12–15 items); Mod B. Standing test: 3+ of one durable in a room is a bug (F3).

*Setpieces don't need this machinery — high counts are the point. §10 stocking uses plain high-weight, high-roll pool entries.*

---

## 4. Room-by-room residential baseline — Mod A

Baseline for every household regardless of archetype. **[new]** = requires art/scripts, Phase 7 only.

### 4.1 Kitchen

**Counters and lower cabinets**

| Item | Tier | Notes |
|---|---|---|
| Kitchen knife (chef's) | T0 | Approach C (Mod B); Mod A ships ~85% interim |
| Paring knife | T1 | |
| Bread knife | T1 | |
| Steak knife set | T1 | |
| Frying pan | T0 | At least one heat vessel per kitchen |
| Saucepan | T1 | |
| Stock pot | T1 | |
| Baking sheet | T1 | |
| Casserole dish | T1 | |
| Mixing bowl set | T1 | |
| Cutting board | T1 | |
| Colander | T2 | |
| Rolling pin | T2 | |
| Measuring cups / spoons | T1 | Never gates (§7.4) |

**Small appliances** — microwave (T0, ~80–85%) · coffee maker (T1, ~78%) · toaster (T1) · Crock-Pot (T1) · hand mixer (T2) · blender (T2) · food processor (T2) · electric can opener (T2) · bread machine (T4, ~3% in July 1993). Powered appliances: early-game convenience, late-game scrap — keep them.

**Junk drawer** — every American kitchen has exactly one. Room-scoped guarantee → Approach C → Mod B; most contents [new] → Phase 7. Mod A ships a reduced vanilla-items version (batteries ~30% dead · matches · lighter · duct tape · screwdrivers · scissors · tape measure · dead-battery flashlight · can opener · bottle opener · corkscrew · loose fasteners) in one designated counter pool.

**Under-sink** — bleach (T0, owning room) · dish soap · sponges · trash bags · rubber gloves · bucket (secondary) · scouring pads
**Overhead** — plates/glasses/mugs (T0, vanilla) · food storage (T1) · foil (T1) · plastic wrap (T1) · wax paper (T2) · thermos (T2)
**Pantry** — ~14 days shelf-stable per ledger C; canning archetype inverts.

### 4.2 Bathroom

**Medicine cabinet** — aspirin/acetaminophen/ibuprofen (T0, quantity-limited) · antacid (T1) · cough syrup (T1) · cold medicine (T1) · bandages (T0) · hydrogen peroxide (T1) · rubbing alcohol (T1) · antibiotic ointment (T1) · cotton (T1) · tweezers (T1) · nail clippers (T1) · small scissors (T1) · thermometer (T2) · razor (T1) · prescription bottles (T2)

**Linen closet** — towels (T0, Approach B) · washcloths (T0) · toilet paper (T0, multiple) · soap (T0) · shampoo (T1) · first aid kit (T2) · heating pad (T3) · plunger (T1)

Medical scarcity belongs on antibiotics, sutures, real painkillers — not dressing a scratch. The deep pools are institutional (§10.6).

### 4.3 Bedroom

**Nightstand** — flashlight (T1) · batteries (secondary) · reading glasses (T2) · paperback (T1) · tissues (T1) · alarm clock (T1) · handgun (commuter pattern, §6.4) · change · wristwatch
**Closet** — clothing (vanilla) · luggage/duffels/backpacks (T1, ledger B; good packs military-only) · blankets (T1) · shoeboxes (T1) · sewing kit (T2) · board games (T2) · photo album (T1)

### 4.4 Living room, hall closet, den

**Living room** — TV (T0, ~98%) · VCR (T1, ~75–80%) · tapes (T1) · magazines (T1) · books (T1) · candles (T1) · matches/lighter (T1) · ashtray (T2) · sewing basket (T2) · phone book (T1) · answering machine (T1/T2) · home computer (T2, ~22–24%) · game console (T2) · halogen torchiere (T2)
**Hall closet** — vacuum (T0, ~98%) · iron and board (T0/T1) · coats (T1) · umbrella (T1) · fire extinguisher (T2, owning room) · board games · household toolbox (T2)

### 4.5 Laundry and utility

Detergent (T0) · bucket (T1, owning room) · mop (T1) · broom (T0) · dustpan (T1) · clothesline and pins (T2) · work gloves (T1) · laundry basket (T1) · cleaning supplies (T1) · smoke detector (T0, 9V battery source)

### 4.6 Garage and carport

> Gated on the Phase 0 map audit — Muldraugh skews postwar-small; mobile homes have neither garage nor basement.

**Toolbox/workbench** — hammer (T0) · screwdriver set (T0) · pliers (T0) · adjustable wrench (T1) · socket set (T1) · tape measure (T1) · utility knife (T1) · level (T2) · handsaw (T1) · hacksaw (T2) · corded drill (T1) · cordless drill (T2, dead NiCds) · vise grips (T2) · fastener can (T1) · sandpaper · chisel (T3) · crowbar (T2) · pipe wrench (T2)
**Automotive** — gas can (T1, 0–40%) · motor oil (T1) · jumper cables (T1) · tire iron and jack (T1) · funnel (T2) · WD-40 (T1) · antifreeze (T2) · battery charger (T3) · rags (T1)
**Yard** — mower (T2, near-empty) · rake (T1) · shovel (T1) · hoe (T2) · trowel (T1) · hose (T1) · watering can (T2) · wheelbarrow (T2) · fertilizer (T2) · seed (T2) · trimmer (T2)
**Outdoor living** — charcoal/propane grill (T1) · lighter fluid (T1) · cooler (T1) · lawn chairs (T1) · tarp (T1) · rope (T1) · bungees (T1) · extension cords (T1) · work light (T2)
**Storage/hobby** — step ladder (T1) · extension ladder (T2) · bicycle (T2) · sports equipment incl. bat (T2) · camping set (T2) · paint (T2) · scrap lumber (T2)

### 4.7 Shed and outbuilding

Push mower · gas can · garden tools · fertilizer/seed · axe (T2) · maul (T3) · chainsaw (T3) · wheelbarrow · sawhorses · lumber · chicken wire · fence posts · tarp · twine · post hole digger (T3). Wood-heat archetype overrides upward.

### 4.8 Basement

> B42 added basements to map generation — Phase 0 confirms density. Kentucky context: crawlspace dominates statewide, but full basements concentrate in exactly this northern band.

Canning shelves · water heater (overlooked water source) · workbench · storage · holiday decorations · furniture · deep freezer (§4.9) · gun cabinet (T3) · sump pump (T2) · laundry

### 4.9 Cross-room dedupe table

| Item | Owning room | Secondary |
|---|---|---|
| Bleach | Kitchen under-sink | — |
| Fire extinguisher | Hall closet (T2) | — |
| Deep freezer | Garage **or** basement (T2) | — |
| Flashlight | Nightstand (T1) | Junk drawer (dead) |
| Batteries | Junk drawer | Nightstand, garage (reduced) |
| Bucket | Laundry (T1) | Kitchen under-sink |
| Toolbox | Hall closet **or** garage | — |

---

## 5. Background archetypes — Mod B, layer one

Primary archetype (optional secondary) per residential building, seeded deterministically from building identity — stable across saves, identical server/client, re-derivable at respawn (pure function, never stored). Regional weighting: military near Muldraugh, farms outskirts, commuters toward West Point.

| Archetype | Signature |
|---|---|
| **5.2 Military** | The defining archetype — Muldraugh exists because of Fort Knox. Footlockers · duffels and ALICE packs (only reliable source of *good* packs) · BDUs · canteens · e-tool · ammo cans · surplus first-aid · poncho · boots · MREs (T3) · disproportionately complete toolsets |
| **5.3 Canning/garden** | Mason jars in quantity · lids/rings · **pressure canner near-certain** (green beans are low-acid; water-bath canning them is a food-safety impossibility) · deep freezer · garden tools/seed · shelves of home-canned goods |
| **5.4 Wood-heat** | Stove/insert · firewood in quantity · **chainsaw and maul near-certain** · fuel and bar oil · kerosene backup · oil lamps · wedges/sledge |
| **5.5 Hunting/fishing** | Long guns — .30-30/.30-06, 12ga pump, .22 · closet/cabinet storage · deepest ammo stock (§6.4) · tackle box · rod/reel · hunting knife · camo · game bags · meat grinder · freezer venison |
| **5.6 Handy/workshop** | Full §4.6 at elevated tiers · vise · organized fasteners · power tools · stock lumber · manuals · project vehicle |
| **5.7 Commuter** | Minimal garage · computer likelier · convenience/frozen food · better electronics · starter toolset · nightstand handgun pattern · briefcase |
| **5.8 Elderly** | More medicine · more shelf-stable · older appliances, worse condition · mending supplies · no computer/console · more canned · walker/cane (T3) · decades of garage accumulation |
| **5.9 Starter/renter** | Sparse everything · one cheap knife set · mismatched cookware · milk crates · no garage tools · futon. **Keeps the mod honest.** |
| **5.10 Mobile home** | No basement/garage/shed · exterior storage box · propane tank · window AC. Phase 0 confirms map presence |
| **5.13 Survivalist (T4-rare)** | Post-Ruby Ridge, pre-militia-boom — period-perfect for mid-1993. Reloading bench · a year of stored food · buried-cache map · water storage · 1993 prepper literature (Soldier of Fortune, survivalist manuals — knowledge loot) · fuel and ammo depth no other archetype has. **Disposition-locked to sheltered-prepared, found empty anyway** (§6.2): half the ammo spent, one rifle missing, the food stores broken into by the family itself. Preparation bought weeks, not salvation. The player inherits the estate of a doctrine that half-worked — the mod's scarcity-honesty thesis pointed at the one household that saw it coming |

**5.11 Regional food/culture** — Ohio Valley, not Appalachia. Keep: country ham · self-rising flour · cornmeal · lard · stove-top bacon grease can · buttermilk · sweet tea · Kool-Aid · biscuits · bourbon (T2) · cast iron (T2 baseline, elevated farm/elderly). Cut: sorghum, chow-chow, moonshine. Add: **burley tobacco** (KY led national production; pre-buyout) · **wet/dry county law** (verify Meade/Hardin 1993 status) · community cookbook **[new]** (T2).

**5.12 Weather/isolation** — battery radio (T1) · **gallon water jugs** (not PET bottles — Aquafina 1994) · candles (T1) · oil lamps (T2) · generator (T3) · kerosene heater (archetype-linked). *Stock freshness justified by §5.14: the Storm of the Century restock was four months old when the Event hit.*

### 5.14 The 1993 calendar

The setting has a real crisis calendar around it, and the mod should open that gift. Eighteen months of American history, each item earning specific loot:

| Event | Date | Loot consequence |
|---|---|---|
| **LA riots** | April 1992 | Fifteen months of memory — households watched Koreatown defend itself on CNN. Justifies *recent* gun purchases: a receipt in the case, a barely-fired box of shells, the commuter's nightstand pistol bought last spring |
| **Ruby Ridge** | August 1992 | Survivalist anxiety as a live current — licenses archetype 5.13 |
| **Storm of the Century** | March 1993 | Hit Kentucky directly, **four months before the Event**. §5.12's storm stocks stop being a design choice and become a documented fact: candles, jugs, and kerosene were *just replenished* |
| **Waco** | Feb–April 1993 | Ended ten weeks before the Event; reinforces 5.13 and the period's institutional-distrust texture |
| **Great Flood of 1993** | **Concurrent — July 1993** | The Midwest was underwater *that month*. Guard units, FEMA logistics, and Red Cross capacity were committed up the Mississippi when Knox happened. **Canon-compatible explanation for the thin official response**, and flavor loot: sandbags, flood-relief pamphlets, a staged Guard pallet that never shipped |

All calendar content is loot and paper — P9-clean, zero mechanics cost, and it converts the mod's setting from "the early 90s, vaguely" into a month with a newspaper.

---

## 6. Dispositions — Mod B, layer two

What they did when it happened. A second deterministic function filtering the archetype's inventory at fill time. Per P9: remove, deplete, relocate — never build. The Knox Event quarantine gives every state its fiction; *looted* is weighted low and framed as pre-quarantine.

### 6.1 The roster

| Disposition | Filter |
|---|---|
| **Never came home** | No filter. Full pantry, full freezer, mail on the counter. The jackpot — and the diegetic cover for the mod's abundance |
| **Evacuated, organized** | **All firearms and ammo gone — first thing packed** · meds, cash, photos, **bags** gone. Food, cookware, tools untouched — nobody flees with a socket set |
| **Evacuated, panicked** | Partial randomized removal — **grabbed the handgun, left the long guns** · contents scattered across wrong containers |
| **Sheltered, prepared** | Food heavily depleted · candles burned · **guns present, ammo 30–70% spent** · water containers empty · tools present |
| **Sheltered, unprepared** | Food consumed to near-zero; else untouched |
| **Looted (pre-quarantine)** | **Guns and ammo first**, then food and meds. **Heavy tools left** — same encumbrance logic as §1.4. Low weight |

### 6.2 Correlation matrix, constrained

Not the full product — ~25–30 sensible pairings (the full cross product × 8 rooms is an un-QA-able state space; the pruned combos had no story anyway). Anchors: military → sheltered-prepared/evacuated-organized · elderly → never-came-home/sheltered-unprepared · starter → evacuated-panicked · canning/wood-heat → sheltered-prepared · commuter → evacuated-organized · **survivalist → locked to sheltered-prepared, always found empty** (the only hard lock in the matrix; §5.13). Authoring: 10 packages + 6 filters = **16 pieces**; combinations free.

### 6.3 Ledger interaction

F4 metrics evaluate as **weighted averages across the disposition distribution**. A never-came-home house legitimately exceeds targets; the population average must not.

### 6.4 Firearms: the disposition showcase

**Guns are fun, and a player searching a neighborhood should find some.** Firearms are durables owned by ~half of 1993 KY households — P1/P2 apply. They are also the category *most* sensitive to disposition: first packed, first looted. Guns are where the disposition system earns its keep.

**Baseline ownership (pre-disposition), ~45–55% of households:**

| Archetype | Firearms | Compatible ammo stored with them |
|---|---|---|
| Hunting/fishing | 2–4 long guns, near-certain | **60–150 rounds**, calibers matching the guns, cabinet/closet |
| Military | Sidearm, often a rifle · organized | **100–200 rounds in ammo cans**, matched — best-organized stock on the map |
| Wood-heat/canning/mobile | Shotgun or .22 (~60%) | 20–60 rounds |
| Handy/workshop | Rural utility (~50%) | 20–60 rounds |
| Commuter | Nightstand handgun (~40%) | One partial box, 15–40 |
| Elderly | Old revolver or shotgun (~50%) | Half a box, 10–25 |
| Starter/renter | Cheap handgun (~25%) | 5–20 loose |

**Caliber coherence rule.** Ammo spawns as a *function of the gun rolled*, same or adjacent container — never independently. Orphan calibers only as deliberate low-weight flavor. Mismatch is an F7 violation. Implementation: the firearm roll returns a caliber; the ammo insertion consumes it — correlated-spawn logic only Mod B's fill handler can do. Mod A raises global weights modestly (uncorrelated interim); the full experience ships with Mod B.

**Disposition is the balance.** Evacuated-organized and looted contribute zero; panicked leaves long guns; sheltered keeps guns with spent ammo; never-came-home keeps all. Net: **~2–4 firearms per ten-house route** — findable without every house being an armory. Scarcity shifts onto ammunition — consumable, caliber-fragmented, partially spent — and PZ's noise mechanics tax every trigger pull.

*Retail gun counters are governed by §10.2's panic layer, not by dispositions.*

### 6.5 Collapse-economy texture *(new in v0.6)*

What becomes currency when currency dies is consistent across the historical record — postwar Germany, the sieges, the Soviet collapse: **cigarettes, liquor, ammunition, antibiotics, coffee, batteries.** Someone in every neighborhood figured this out in week one.

**Barter caches.** A rare additive flavor on *sheltered* dispositions (~5–8% of them): a hoard far past personal use — a footlocker of cigarette cartons, a case of bourbon under a bed, shoeboxes of batteries, coffee cans of loose ammo. The player who knows history recognizes what they're looking at; the player who doesn't just found cigarettes. P9-clean: it is only loot quantity.

**Worthless cash.** The other half of the same truth, applied at setpieces: registers open with bills scattered and left, cash on floors nobody bent down for, banks untouched (nothing inside could buy anything by day four), the jewelry store hit on day one and never entered again. Pure P12 texture — implemented as pool composition, costs nothing.

### 6.6 Fridge notes *(new in v0.6)*

> **SUPERSEDED — no new art (Aug 2026, tech spec settled decision 7).** Shipped
> using EXISTING B42 lore items repurposed by disposition (`Note`,
> `LetterHandwritten`, `Journal`, `Newspaper`; survivalist = `Map`). Not
> `[new]` items, not deferred — implemented. The design intent below stands;
> only the "authored paper item" part is replaced by repurposing.

Real disasters leave paper: evacuation notes, door markings, "gone to mother's." One note style per disposition, spawned by the disposition filter: the organized evacuation leaves a note taped to the fridge for a relative who never came · the panicked one leaves nothing · sheltered-unprepared has a grocery list from the last normal day · the survivalist's is a hand-drawn cache map (§5.13). Cheapest possible [new] item class — paper and text, no real art — and it converts every disposition from a loot *pattern* into a legible *story*. Moved to the front of Phase 6 on value-per-effort.

---

## 7. Recipe and tool substitution — all domains — Mod A

### 7.1 Core principle

**A recipe should specify a capability, not a SKU.** v0.5 extends this from food to the entire B42 crafting tree: mechanics, carpentry, metalwork, electrical, medical, tailoring. B42's tag system exists for exactly this.

### 7.2 Substitution degrades, never gates — within physics (P11)

Always possible, always taxed — time, yield, injury chance, item damage — **except where reality itself gates.** Any wrench turns a bolt badly. No campfire TIG-welds. Hard gates survive only where a physical impossibility backs them: welding needs a welder, precision electronics need a soldering iron, forging needs forge heat. Everywhere else, a ladder, not a wall.

### 7.3 Substitution matrix — food and general

| Capability | Ideal | Acceptable | Improvised (penalized) |
|---|---|---|---|
| Cutting | Kitchen knife | Paring/bread/steak/hunting knife, cleaver, box cutter, machete | Sharpened stone, broken bottle, scissors, sharpened screwdriver |
| Opening cans | Can opener | Hunting knife, machete, cleaver | Screwdriver + hammer, sharp rock, concrete — contents-loss chance |
| Heat vessel | Saucepan/stock pot | Frying pan, cast iron, roasting pan, kettle, Dutch oven | Tin can, hubcap, metal bucket |
| Mixing | Mixing bowl | Pot, pan, jar, bucket | Any watertight container |
| Stirring | Spoon/spatula | Ladle, whisk, fork, knife | Clean stick |
| Measuring | Measuring cups | Marked container | **No tool** — yield penalty only |
| Grinding | Mortar and pestle | Food processor (powered), meat grinder | Rolling pin + bag, rocks, hammer + cloth |
| Grating | Box grater | Knife, slow | Punctured can lid |
| Straining | Colander | Cheesecloth, clean shirt | Lid held ajar, punctured can |
| Cooking heat | Stove (powered) | Grill, campfire, wood stove, camp stove | Trash-can fire |

### 7.4 Substitution matrix — trades (new in v0.5)

| Capability | Ideal | Acceptable | Improvised (penalized) | Hard gate? |
|---|---|---|---|---|
| Fastening (screws) | Powered drill/driver | Any screwdriver | Knife tip, coin (slotted only) — slow, cam-out damage chance | No |
| Wrenching | Socket set | Adjustable wrench, box wrench | Pipe wrench, vise grips — rounds fasteners, damage chance | No |
| Sawing lumber | Circular saw (powered) | Handsaw | Hacksaw (very slow), axe (rough cut, material loss) | No |
| Sawing metal | Hacksaw | Angle grinder (powered) | — | Cutting torch/grinder for heavy stock: **gate** |
| Drilling | Drill | Awl + effort | Heated nail (small holes) — slow | Large bores: gate |
| Prying | Crowbar | Claw hammer, tire iron | Screwdriver — break and injury chance | No |
| Hammering | Hammer | Mallet, hatchet flat, pipe wrench | Rock, cast iron skillet | No |
| Vehicle work | Correct socket + jack | Adjustable + jack | Vise grips + jack — damage chance to the part | No jack for under-car work: **gate** (physics) |
| Welding | Welder + mask | — | — | **Gate** — P11's canonical example |
| Soldering | Soldering iron | — | Heated wire for crude joins, high failure | Fine electronics: gate |
| Suturing | Suture kit | Sterilized needle + thread — infection risk | Fishing line + needle — worse infection risk | No |
| Splinting | Splint | Sturdy stick + any fabric | — | No |
| Sewing/tailoring | Sewing kit | Any needle + thread | Fishing line, dental floss | No |
| Digging | Shovel | Trowel (slow) | E-tool (military archetype shines), sturdy stick + hands | No |

### 7.5 Specific corrections

Sandwich/salad: cutting capability only · cutting board: bonus, never gate · measuring: never gates · any watertight vessel holds water · **B42's learned-recipe and skill gating stays untouched** — this mod changes what tools a known recipe needs, never whether the player knows it. Knowledge is the progression system; tools are logistics. The audit method: walk every `craftRecipe` in the B42 tree, classify each tool input as capability-taggable / already-tagged / physics-gated, and widen the first class. Expect the audit itself to be a Phase 4 work item comparable in size to the residential loot pass.

---

## 8. The compensating scarcity ledger — Mod A

Durables pay by encumbrance (§1.4); the ledger covers consumables plus the two exceptions. Numbered so F4 is testable.

| # | Line | Target | Rationale |
|---|---|---|---|
| A | Residential firearms & ammo | Per §6.4 table; ~2–4 guns per ten-house route post-disposition; ammo caliber-matched, archetype-capped | Guns common as durables; dispositions supply scarcity; ammo is the constraint |
| B | Bags | 40–70% condition; ~20% capacity reduction; good packs military-only | The addition encumbrance can't self-limit |
| C | Shelf-stable food | ~14 days baseline; canning archetype 90+ | Weekly shopping; variance is the improvement |
| D | Batteries | 2–6 loose per house, ~30% dead, ~25% shorter life | Half the junk drawer is dead |
| E | OTC medicine | 10–40 doses per container | A bottle has a pill count |
| F | Fuel | Gas cans 0–40%; mower near-empty; propane 0–60%. Vehicle fuel excluded — fuel-neutral per §9.3, revisit post-playtest | Fuel is the binding constraint |
| G | Cheap tool durability | Consumer-grade 30–70% condition, elevated break chance | A six-dollar screwdriver is not a Snap-on |
| H | Perishables | Mechanics unchanged; freezer contents large enough that loss is felt | The deep-freezer arc |

**Setpiece interaction (v0.5):** the ledger governs the *residential* economy. Setpiece pools (§10) deliberately sit outside it — they are the reward economy, priced by access instead. The seam between the two is guarded by F8.

---

## 9. Vehicle spawn baseline — Mod A

The map should read as a place where every household owned one to two cars, because in 1993 Kentucky it did.

**9.1 Mechanism** — vehicle spawns are zone-driven (`ParkingStall` zones typed into pools), scaled by the sandbox setting. The mod multiplies per-zone chance in the distribution tables — default ~1.5×, sandbox slider 1.0–3.0×, composing with (never overwriting) the player's vanilla setting per P10. Phase 0 confirms B42 table names and composition.

**9.2 Exclusions** — per-building driveway logic stays cut with disposition-as-world-state. Zones are map data; this is a global knob, which is why it lives in Mod A.

**9.3 Fuel — deferred by decision.** Added vehicles are **fuel-neutral**: unmodified vanilla fuel/condition distribution. The tension (more cars = more siphonable fuel, pressuring ledger F) is on the record as a **future balancing subject, not a launch constraint**. If playtest fuel metrics show breakage, the designed-but-dormant lever: skew only the *added* margin toward low tanks and worse condition. Dormant sandbox option if cheap; else deferred.

**9.4 Conflicts** — vehicle-adding mods compose (they add to pools; this scales chance). Table-replacing mods conflict; document known ones.

---

## 10. The specialized world — setpiece doctrine — Mod A *(new in v0.5)*

### 10.1 Doctrine

Rare + fixed + known = setpiece. A specialized building's inventory is its *stock*, and 1993 commercial stocking ran deep: an auto parts store carries **dozens of each part** because that is what an auto parts store *is*. Vanilla already concedes this exactly once — the knife store at 100% — then reverts to lottery logic for every other specialty. v0.5 applies the knife-store standard uniformly.

**No dispositions. No per-building variance. No apology.** The player should be able to plan an expedition around a setpiece and have the destination honor the plan. Balance is the access-cost trinity — **distance** (setpieces are far from safehouses), **density** (commercial zones carry the hordes; the mod does *not* touch zombie distributions — vanilla density is the price as-is), and **logistics** (you cannot carry a parts counter; §9's vehicles exist so hauling is possible, and setpieces exist so vehicles have a purpose — the two systems justify each other).

**Front/back structure.** Everywhere applicable, retail splits into front-of-house (shelves) and back-of-house (stockroom), with the stockroom equal or richer. This matters most under the panic layer (§10.2) and rewards the player who clears the whole building.

### 10.2 The panic layer — the one exception

Pre-quarantine panic buying is canon and real: food, guns, and medicine strip first in any crisis. Applied as a **uniform, lore-baked reduction written into the pools themselves** — every grocery looks post-panic because the panic *happened*, not because a die rolled:

| Retail type | Front of house | Back of house |
|---|---|---|
| Grocery / Gigamart / convenience | **20–40% remaining** — stripped shelves, scattered stock | **60–80%** — the panic hit shelves, not stockrooms. Checking the back becomes the play |
| Gun stores | Display cases **10–30%** — cleaned out first | Locked storage **50–70%** — what the owner didn't sell at any price |
| Pharmacies | OTC shelves **20–40%** | Behind-counter **60–80%** — panic buyers grabbed painkillers, not amoxicillin they didn't know to want |
| Electronics / liquor retail *(v0.6, per P12)* | **10–30%** — TVs, VCRs, and camcorders that will never be plugged in again; the liquor wall stripped | **40–60%** — boxed stock the crowd didn't reach |

Everything else — auto parts, hardware, farm supply, industrial, institutional — full stock. Nobody panic-buys brake pads. **The electronics row is the P12 monument: someone died for a camcorder while the crowbars sat in their rack next door.** The stripped-useless/untouched-priceless contrast between adjacent storefronts is the mod's single cheapest piece of environmental storytelling.

### 10.3 Auto parts, hardware, farm supply

**Auto parts store** — the archetypal case. Dozens of each: headlights, brake pads, filters (oil/air/fuel), belts, hoses, spark plugs, wiper blades, fuses, gaskets, bulbs · car batteries (charge variable) · tires in size runs · cases of oil, coolant, brake fluid, power steering fluid · a full tool aisle · Haynes/Chilton manuals (mechanics skill literature — the *knowledge* loot may outvalue the parts). **Mechanic shops** distinct from retail: lifts, used parts in ranged condition, partial vehicles, shop tools, the good toolbox.

**Hardware store** — aisle-scale: fastener runs (boxes, not handfuls) · hand tools in retail multiples · power tools · plumbing runs and fittings · electrical (wire spools, boxes, tape) · paint and supplies · propane exchange rack · rope/chain by the reel · ladders · tarps · padlocks · wheelbarrows · seasonal rack. Generators stay rare even here (T3-equivalent) — a small-town hardware store stocked one or two, and the generator remains a strategic find, not a shelf item.

**Farm supply** — feed and seed by the pallet · fencing wire, T-posts · fertilizer in quantity · animal medications (period-accurate, some human-usable — flag for a design pass) · work clothes and boots · implements · twine · troughs · sprayers · tractor consumables.

### 10.4 Gun stores, police, surplus

**Gun retail** — governed by §10.2: cases stripped, locked storage worth the trouble. What remains skews to what panic buyers passed over: odd calibers, black powder, optics, cleaning kits, reloading supplies, gun safes (intact, locked — a prize needing tools).
**Police stations** — **not retail; not panic-stripped.** The station was manned through the Event; the armory sits intact behind locked doors (P4: entry needs tools, not luck). 1993 small-town Kentucky armory: 12ga pumps, service revolvers/early autos, boxed ammo in quantity, vests, batons, cuffs, radios. Evidence room as flavor + oddities.
**Military surplus** — the Fort Knox economy in retail form and the civilian mirror of archetype 5.2: ALICE packs, BDUs, canteens, e-tools, ammo cans (mostly empty — sold as cans), MREs, ponchos, boots, field manuals. **No weapons** — 1993 surplus stores sold gear, not guns.

### 10.5 Industrial, warehouse, factory

Bulk raw materials by building type — the endgame base-building pools: lumber yard (dimensional lumber by the stack, sheet goods, posts) · metal supply (sheet, bar, pipe, angle) · welding shop (rods, gas, masks, the welder — the §7.4 hard gate made findable) · machine shops (tooling, stock, manuals) · warehouses typed by goods (a *specific* warehouse should be a *specific* jackpot — assign each a category rather than generic crates: paper goods, appliances, food distribution [panic-exempt: wholesale, not retail], hardware overstock) · factories per their line (the map's existing spiffo/bottling/etc. get coherent line-appropriate pools) · pallets, hand trucks, industrial shelving · propane and fuel in industrial quantity (ledger F note: industrial fuel is *the* designed late-game fuel source — residential scarcity pushes the player here; this is intended flow, not leakage).

### 10.6 Medical and institutional

**Pharmacies** — §10.2 split; behind-counter is the antibiotics source.
**Clinics/hospital** — the deep medical pool and the medical endgame: sutures, antibiotics, real painkillers, bandages by the case, splints, wheelchairs/crutches, scrubs. Priced by the map's own density — hospitals are death zones in vanilla and that is the correct price for this pool.
**Schools** — institutional kitchen (big cookware runs), first aid office, tool shop/home-ec rooms (a quiet full toolset source), library (skill books in quantity — knowledge setpiece), gym equipment, buses.
**Fire stations** — turnout gear (protection), axes and forcible-entry tools (crowbar-class), first aid, extinguishers, hose, the truck.
**Church relief hubs** *(new in v0.6)* — the most Kentucky setpiece available, and grounded in the real 1993: during the concurrent Great Flood (§5.14), churches *were* the relief infrastructure. The map is full of churches doing nothing; a share of them become active relief sites: folding tables, sorted donation boxes (canned food, clothes by size), cots and blankets, coffee urns, a first-aid table, a hand-lettered sign. **Full resource-pool treatment, no panic reduction** — the congregation *brought* things here; that is what the building is. Disaster sociology's actual finding — mutual aid dominates the first weeks — expressed in loot, in the one building type players already trust to be gentle.

### 10.7 Feasibility note

Everything in §10 is pool-editing on room types that already exist — the same merge-hook mechanism as §4, zero dependence on the Mod B probe. Assumption 6 (§0) is the only open item: whether B42 already defines distinct pools for every specialty here (likely for auto/hardware/gun/medical; less certain for farm supply and typed warehouses). Where a pool is missing, the work is defining a new room-type mapping — more effort, same proven tech.

---

## 11. Implementation notes

**Two hooks, strictly divided:** merge event (`OnPreDistributionMerge`) for Mod A — §4 residential baseline, §9 vehicle tables, **§10 setpiece pools** — global edits, once. `OnFillContainer` for Mod B — archetype packages, disposition filters, Approach C, §6.4 caliber coherence, §1.3 condition variance.

**Mod B handler:** guard `ItemPickerContainer` · walk-up failure degrades that container to Mod A behavior, log once, never break · cache archetype/disposition per building · pure functions of building identity, never stored state.

**General:** recipe overrides by name are the primary conflict surface — enumerate all; the v0.5 all-domains audit multiplies this list, so the enumeration is now a shipped document, not a description paragraph · sandbox options minimum six: global toggle, household abundance, archetype layer, ledger, vehicle multiplier, **setpiece stocking level** · MP: server-authoritative fill logic, client-side recipe scripts · `common/` + `42/` folders.

## 12. Phase 0 — the probe

1. **Probe script** — hook `OnFillContainer`, attempt the walk-up chain, log everything, count `ItemPickerContainer` occurrences. (Assumptions 1, 3.)
2. **ID stability** — log, save, reload, diff; MP server/client compare. (Assumption 2.)
3. **Vehicle tables** — locate, confirm multiplier composition. (Assumption 4.)
4. **Map audit** — count garages, basements, sheds, mobile homes; **inventory the map's specialized buildings** (how many auto parts stores, hardware, gun stores, warehouses by type — §10's actual surface area).
5. **Rate dump** — B42 rates for the §4.1 tool list **and the §10 specialty pools; enumerate which specialty room types have distinct pools** (assumption 6).
6. **Ten-house route** — fixed, repeatable, baseline metrics.

## 13. Guardrails and playtest protocol

**Failure conditions:** F1 one-house completion (most-not-all after one; ~80% after two to three) · F2 homogenization (P5 + archetypes) · F3 duplication (§3.1 test) · F4 unpaid contract (§8 metrics, disposition-weighted) · F5 encumbrance irrelevance (bags are the watch item) · F6 anachronism · F7 archetype incoherence (wood stove without a maul; a gun with mismatched-caliber ammo) · **F8 — economy inversion (new):** if setpiece pools make residential looting pointless — if the optimal play is "skip every house, drive to the hardware store" — the two-regime design has failed. Residential must stay worth it for the daily economy (food, dispositions, the story layer); setpieces are for *projects*. Watch item: hardware-store tool depth vs. the residential tool baseline. If playtest shows inversion, the lever is setpiece *count* per category, not per-item depth — a store that is boring to loot is worse than a store that is far away.

**Protocol:** Muldraugh, Apocalypse defaults, loot Normal, `-debug`. Residential route per v0.4 (all ledger metrics, guns/calibers, archetype/disposition once Mod B lands) **plus a setpiece route:** one building per §10 category, recording haul weight, trips required, vehicle necessity, and time-in-building — the access-cost trinity measured, not assumed. Loot rolls once at first load; every run needs fresh saves or unvisited cells. **Still the dominant time cost; budget it.**

## 14. Phasing

- **Phase 0** — probe + map/pool audits (§12). Gates Mod B design and sizes §10.
- **Phase 1** — kitchen vertical slice. *The thesis test — if it doesn't feel better, stop.*
- **Phase 2** — full residential + ledger + vehicles.
- **Phase 3** — **the specialized world (§10)**, in the user's priority order: auto/hardware/farm supply → guns/police/surplus → industrial/warehouse → medical/institutional.
- **Phase 4** — recipe audit and substitution, all domains (§7). **← Mod A ships here.**
- **Phase 5** — Mod B: archetypes × dispositions, military first; Approach C; §6.4 coherence.
- **Phase 6** — [new] items, in value order: **fridge notes first (§6.6)**, then full junk drawer, cookbook, 1993-calendar paper items (§5.14), surplus variants, canning variants.

## 15. Open questions

1. Sandbox knobs beyond the minimum six.
2. ~~Commercial loot~~ — resolved by v0.5: two regimes, F8 guards the seam.
3. Modular release beyond A/B?
4. Meade/Hardin 1993 wet/dry status.
5. Disposition weights — never-came-home share (F1 lever).
6. Vehicle fuel compensation — dormant option or pure deferral; decide on playtest metrics.
7. Farm-supply animal meds: which period compounds are human-usable, and is modeling that worth it?
8. Typed warehouses: how many categories before the novelty is spent?
9. Police armory access: vanilla lock mechanics sufficient, or does "needs tools, not luck" require a light touch on door/lock definitions?
10. **Consolidated households — designed, deferred by decision.** Two adjacent buildings sharing one story (donor stripped orderly-empty, host boosted with the donor archetype's signature items imported). The mechanism is fully worked out — offline mutual-nearest-neighbor pairing over map data, shipped as a static coordinate-keyed manifest; pure-function archetype derivation lets the host compute the donor's package without the donor loaded — but it doubles the QA surface of every disposition test and requires the map-extraction tool before anything else can use it. **Revisit after Mod B stabilizes.** The manifest pattern generalizes to any future cross-building story (the block food pool, the fortified cul-de-sac), so the deferred design keeps its value.

---

## Sources

- [Build 42 Stable Plans — The Indie Stone](https://projectzomboid.com/blog/news/2026/07/build-42-stable-plans/)
- [Build 42.20 Released — The Indie Stone](https://projectzomboid.com/blog/news/2026/07/project-zomboid-build-42-20-released/)
- [PZwiki — OnFillContainer](https://pzwiki.net/wiki/OnFillContainer)
- [PZ Lua Docs — Events](https://demiurgequantified.github.io/ProjectZomboidLuaDocs/md_Events.html)
- [IsoBuilding API](https://projectzomboid.com/modding/zombie/iso/areas/IsoBuilding.html)
- [PZwiki — Vehicle zones](https://pzwiki.net/wiki/Vehicle_zones)
- [PZwiki — Procedural distributions](https://pzwiki.net/wiki/Procedural_distributions)
- [PZwiki — CraftRecipe (scripts)](https://pzwiki.net/wiki/CraftRecipe_(scripts))
- [PZwiki — Item tags](https://pzwiki.net/wiki/Item_tags)
- [Kitchen Knife distribution data, B41.78 baseline](https://undeniable.info/pz/wiki/item.php?Name=KitchenKnife)
- [Zomboid Modding Guide — API reference](https://github.com/FWolfe/Zomboid-Modding-Guide/blob/master/api/README.md)
- [BLS — Computer ownership in the 1990s](https://www.bls.gov/opub/btn/archive/computer-ownership-up-sharply-in-the-1990s.pdf)
- [EIA — RECS appliance data](https://www.eia.gov/consumption/residential/data/2001/appliances/appliances.php)
