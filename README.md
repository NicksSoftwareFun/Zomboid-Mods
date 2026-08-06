# The American Household

A loot overhaul for Project Zomboid, Build 42. It fixes the thing every player has quietly made peace with: you can tear apart six kitchen drawers and walk away without a single knife.

Set in Knox County, Kentucky, July 1993.

---

## The problem it solves

Vanilla treats a can opener like a can of beans. Both roll the dice every time a container fills. But a can opener isn't a consumable — somebody bought it once in 1987 and it's been in the same drawer ever since. Real houses own one to five knives with near-certainty. The game models drawers that occasionally, randomly, conjure one.

You don't notice the average. You notice the *variance*: three spatulas in one kitchen, no knife in the next four. A chef's knife shows up in about **a third of kitchens** in vanilla. That's not scarcity, it's noise — and it's the reason "make a sandwich" can turn into a twenty-minute scavenger hunt.

This mod's thesis in one line: **the goal isn't more knives, it's exactly one knife block, where a knife block goes, in essentially every kitchen.** Presence goes up. Variance comes down. Scarcity moves off the stuff you'd own forever and onto the stuff you actually run out of — fuel, batteries, ammunition, medicine.

---

## What changes, in numbers

Everything below is measured against the real B42.20 loot tables, not guessed.

**Kitchens stop lying to you.**

| | Vanilla | This mod |
|---|---|---|
| Chef's knife present | ~32% of kitchens | ~every kitchen, and almost never two |
| Frying pans in a lower cabinet | ~2 on a bad roll (4+ if you weight it up naively) | ~0.44 per cabinet — you find *a* pan, not a pan rack |
| Share of the pool the mod touches | — | capped at 35%, so **two-thirds of every drawer is still vanilla loot** |

That last row is the important one. The mod never floods a pool. Roughly two of every three items you pull are still whatever vanilla would have spawned, so no two kitchens read the same — you get a knife and a pot for certain, and a different random spread of everything else each time. (An earlier build got this wrong and every kitchen ended up with the same four pots and six cutting boards. That's fixed, and there's a regression test so it stays fixed.)

**Stores become destinations, not lottery tickets.**

A 1993 auto parts store carried dozens of each part, because that's what an auto parts store *is*. Vanilla concedes this exactly once — the knife store at 100% — then reverts to slot-machine logic for everything else. This mod applies the knife-store standard across the board:

| Setpiece | What happens |
|---|---|
| Auto parts shelf | **twice** the parts per shelf — filters, plugs, belts, brake pads by the row |
| Hardware / tool store | full aisles: fasteners by the box, tools in retail multiples |
| Church relief hub | thin vanilla pool (a handful of items) → **stocked like the flood-relief site it would have been** (canned food, blankets, cots, first aid) |
| Police armory | left intact — the station was manned through the outbreak; the guns are behind a locked door, not gone |

Balance isn't a dice roll — it's the drive. Setpieces are far, the commercial districts are thick with the dead, and you can't carry a parts counter home in your pockets. That's also why the mod raises car spawns: the two systems justify each other.

**The panic actually happened.**

Food, guns, and pharmacies get stripped first in any real crisis, so they spawn already looted — not because a die rolled, because the panic is canon:

| Retail | Front of house | Back of house |
|---|---|---|
| Grocery / Gigamart | ~**75% emptier** shelves | stockroom keeps ~75% — *check the back* |
| Gun store | display cases down to a quarter | locked storage keeps ~60% |
| Pharmacy | painkillers gone off the shelf | antibiotics still behind the counter (nobody panic-bought amoxicillin) |
| Electronics & liquor | gutted | some boxed stock survives |
| Jewelry counter | picked clean day one | — |

Here's the part that sells it: the jewelry counter is stripped and the **hardware store next door is untouched**, because on day one nobody knew a crowbar was worth more than a gold chain. Two adjacent storefronts telling you exactly what week the world ended. Costs nothing, it's just how the shelves are stocked.

**More cars, because Kentucky.**

Every household owned one or two. Default is **1.5× spawns** (a parking lot that rolled 16% per stall now rolls 24%), on a slider from 1.0 to 3.0. Fuel and condition are left alone — this is a "more cars," not a "free cars," change.

**Recipes ask for a capability, not a brand.**

A recipe should want *something that cuts*, not one specific SKU. Good news: Build 42 already does most of this with its tag system — any of 29 knives satisfies a "sharp blade" requirement out of the box. Where vanilla still gated on one exact item, the mod widens it: you can mix dough in a pot or a bucket, roll it with a wine bottle, and open a can with a screwdriver and a hammer if that's what you've got (slower, and you might spill it). Welding still needs a welder. Physics gets a vote.

---

## The part that makes every house a story

Turn on the archetype layer (it's a sandbox toggle, default on) and every house in the county gets a hidden identity, fixed to the building itself — the same house is the same story on every character, every save, single-player or server.

**Who lived here:** a military family near Fort Knox, with footlockers and ALICE packs and organized ammo cans. A canning household with mason jars by the dozen and a chest freezer full of green beans. A hunting family, long guns in the closet and the deepest ammo on the map. A wood-heat house with a maul by the stove. A commuter with a nightstand handgun and a better computer. The elderly couple with a decade of medicine and no console. The starter apartment that keeps the whole thing honest with one cheap knife set and a milk crate for a nightstand. And, rarely, the survivalist — a year of stored food, a reloading bench, a buried-cache map — found half-empty, because preparation bought weeks, not salvation.

**What they did when it happened:** the same house plays differently depending on the family's last decision. *Never came home* — full pantry, full freezer, mail on the counter, the jackpot. *Evacuated, organized* — guns, cash, and the good bags gone; they packed. *Evacuated, panicked* — grabbed the handgun, left the rifles, everything in the wrong drawer. *Sheltered* — food eaten down, candles burned, guns present but the ammo half spent. *Looted* — guns and drugs first, heavy tools left behind, because looters have the same encumbrance problem you do.

Guns follow the household, not a global dice roll. A hunting family's closet is an armory; the fled commuter's is empty. Every gun that spawns has ammo in its own caliber nearby — no more finding a rifle you'll never feed. Across a ten-house street you'll turn up roughly **two to four firearms**, which is findable without every home being an arsenal.

And there's a note on the fridge. The organized evacuee left one for a relative who never came. The survivalist left a hand-drawn map. The last normal grocery list is still stuck to the door of a house whose owners ate everything and waited. All of it built from items already in the game.

---

## How it's built (for the cautious)

- **No vanilla files are replaced.** The mod edits the loot tables in memory at world load and hooks container fills at runtime. Other loot mods that add to the same pools compose with it; only mods that wholesale-replace the same tables conflict, and it logs every change it makes so you can see exactly what happened.
- **One mod, two layers.** The global rebalance (kitchens, stores, cars, recipes) runs for everyone. The per-house archetype system is a separate toggle — flip it off and you get the loot overhaul alone, with the fill-time code idling at basically zero cost.
- **Multiplayer-safe.** All the loot logic is server-authoritative, and house identities are derived from map coordinates, so the server and every client agree without syncing anything.
- **Sandbox options:** master toggle, household abundance (Low / Design / High), the scarcity ledger, vehicle multiplier, store stocking (Panic / Full), the archetype layer, and a verbose logging switch for the curious.

---

## Status

The loot math is done and tested (six unit-test suites over the tier solver, the hashing/PRNG determinism, the pool mutations, the vehicle scaling, the archetype resolver, and the ledger). It's been run in-game on Build 42.20.2 — kitchens confirmed fixed, clean boot, no errors. Broader playtesting across the full ten-house route is the next step; if you run it and something reads wrong, that's exactly the feedback that's useful.

Design rationale, every decision, and the period sourcing live in [`pz-american-household-design-doc.md`](pz-american-household-design-doc.md). The recipe changes are enumerated in [`OVERRIDES.md`](OVERRIDES.md) (the compatibility surface for other crafting mods).

Build 42 only. No Build 41 backport planned.
