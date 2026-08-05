# TESTPLAN — The American Household / Knox County Households

Operationalizes design doc §13 (guardrails) and tech spec §6. Every loot
observation needs a **fresh save** or unvisited cells — loot rolls once at
first load. Copy `console.txt` out before every relaunch (it is overwritten).

Protocol baseline: Muldraugh spawn, Apocalypse defaults, loot Normal, `-debug`.

## Console tooling

| Command | What it gives you |
|---|---|
| `AH_diff()` | every merge-time pool change, one line each |
| `AHB_where()` | building under player: key, archetype, disposition, region |
| `AHB_audit(n)` | archetype/disposition histogram per region, n synthetic buildings — weight sanity WITHOUT walking the map |
| `AHB_recount()` | item counts for the current room, F3 flags at 3+ |
| `AHB_counters()` | fill-handler skip-path accounting (nested/outdoor/nochain/nonres) |

Boot expectations (both mods on, fresh save): `[AH] loaded` lines for every
registered pass, `residential pass: N applied, 0 skipped`, `vehicle pass`
block, `setpiece pass` + `panic layer` lines, `[AHB] fill handler registered`,
`[AHB] world seed source: <name>` — and **zero `[WARN]` lines**. Any WARN is a
finding; the warning text names the fix.

## The ten-house residential route

Fixed route through Muldraugh's residential core (south of the gas station,
the grid between Bass Road and the trailer park). On the FIRST run, stand in
each front room, run `AHB_where()`, and record the ten coordinate keys here —
they are stable forever after (map data). Re-use the same ten keys every run.

| # | Coordinate key (fill in run 1) | Archetype | Disposition |
|---|---|---|---|
| 1-10 | `___:___:___:___` | | |

Per house, per room: `AHB_recount()` output pasted into the run sheet.

## Failure-condition checks

- **F1 one-house completion** — after looting house 1 of the route: the player
  should still LACK most of: working flashlight+batteries, full tool set, gun,
  14 days food. After houses 1-3: ~80% coverage acceptable. Measured from the
  run sheet.
- **F2 homogenization** — across the ten houses, no two should read identical:
  compare archetype/disposition assignments (ten-house route must show ≥4
  distinct archetypes; `AHB_audit(500)` must match AHB00 weights ±3%).
- **F3 duplication** — `AHB_recount()` flags any item ×3+ in one room. Zero
  tolerance for durables (knives, openers, hammers). Kitchen knife across the
  route: expect ~1 per kitchen, occasionally 2, never 3.
- **F4 unpaid contract (ledger)** — disposition-weighted averages across the
  route vs §8 targets: shelf-stable food ~14 days/house; batteries 2-6 loose;
  guns per §6.4 (~2-4 per ten houses POST-disposition); ammo only ever
  caliber-matched to a gun in the same house.
- **F5 encumbrance irrelevance** — bags: no more than ~1 usable pack per
  two houses; good packs (ALICE/military) ONLY from military archetype or
  surplus setpiece.
- **F6 anachronism** — spot-check inserted items against July 1993: no
  post-1993 electronics, no PET water bottles (gallon jugs only), bourbon not
  moonshine. Any AHB00/AH02/AH03 item failing period review is a bug.
- **F7 archetype incoherence** — per archetype house: wood-heat has maul or
  axe near the stove; every gun's ammo caliber matches a gun IN THAT HOUSE
  (check via `AHB_recount()` output); military house has organized ammo cans.
- **F8 economy inversion** — after the setpiece route: residential looting
  must still beat setpieces for FOOD and daily consumables. If hardware-store
  runs replace house loops entirely, reduce setpiece *count*, not depth.

## The setpiece route (one per §10 category)

Auto parts store → hardware store → gun store → police armory → surplus →
Gigamart (front AND stockroom counts) → pharmacy (OTC vs behind-counter) →
warehouse → church relief hub. Record per stop: haul weight, trips, vehicle
needed?, time-in-building, zombies cleared (the access-cost trinity measured,
not assumed).

Panic-layer verification: grocery/gun/pharmacy/electronics FRONT pools read
visibly stripped; their stockrooms read 60-80%; auto parts/hardware read FULL.
Set `SetpieceStocking=Full` on a second save: fronts restock.

## Vehicle pass

Same parking lots, three saves: multiplier 1.0 (console must log the no-op,
counts match vanilla), 1.5 (default), 3.0. Count vehicles across the
Muldraugh main-street lots and the trailer park.

## Determinism / MP checks

- Same save reloaded: `AHB_where()` on the same building returns identical
  archetype/disposition (cache OFF path: restart game between checks).
- Loot respawn (sandbox respawn ON, accelerated): container contents after
  respawn identical to first fill for the same building.
- Two different saves (different world seed source): assignments differ.
- Dedicated server + client: `AHB_where()` server-side values match what the
  client observes in fills; recipe scripts present client-side.

## Known-degraded paths (expected, documented)

- Scatter (evac-panicked relocation) logs a one-line simplification notice.
- World-seed fallback chain logs its source; `constant` source = open item 4
  still unresolved on that install.
- Any `AddItem failed` warning = bad item id in AHB00/AHB02 — the warning
  names it; fix the data file.
