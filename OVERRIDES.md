# The American Household — Vanilla Override Surface

This document is the mod's complete conflict surface (design doc §11). If a
recipe is not listed here, this mod does not touch it.

All overrides live in a single file:
`AmericanHousehold/42/media/scripts/AH_recipes_food.txt`

Design rule applied throughout (design doc §7.3): **a recipe should specify a
capability, not a SKU.** Mixing can be done in any adequate vessel; rolling can
be done with a bottle. Substitution degrades but never gates.

## Table 1 — Overridden vanilla recipes

Each block is a **verbatim copy** of the Build 42.20 vanilla block with only
the noted input line(s) widened:

- **mixing vessel list widened** — `[Base.Bowl;Base.ClayBowl]` extended to
  `[Base.Bowl;Base.ClayBowl;Base.Pot;Base.Saucepan;Base.SaucepanCopper;Base.Pan;Base.RoastingPan;Base.BakingPan;Base.BucketEmpty]`
  (mode and flags unchanged).
- **roller list widened** — the rolling-pin requirement (`[Base.RollingPin]`
  or `tags[base:rollingpin]`) replaced by `[Base.RollingPin;Base.Wine;Base.Wine2]`
  (mode and flags unchanged). A full wine bottle is the classic improvised
  roller; Wine/Wine2 are B42 fluid-container bottles, valid empty or full.

| Overridden recipe | Vanilla source file (B42.20 `scripts/generated/recipes/`) | Exact change |
|---|---|---|
| `MakeBaguetteDough` | `recipes_baking.txt` | mixing vessel list widened + roller list widened |
| `MakeBiscuits` | `recipes_baking.txt` | mixing vessel list widened |
| `MakeBreadDough` | `recipes_baking.txt` | mixing vessel list widened + roller list widened |
| `MakeChocolateChipCookieDough` | `recipes_baking.txt` | mixing vessel list widened + roller list widened |
| `MakeChocolateCookieDough` | `recipes_baking.txt` | mixing vessel list widened + roller list widened |
| `MakeFriedOnionRings` | `recipes_cooking.txt` | mixing vessel list widened |
| `MakeGravy` | `recipes_cooking.txt` | mixing vessel list widened |
| `MakeGuacamole` | `recipes_cooking.txt` | mixing vessel list widened |
| `MakeOatmealCookieDough` | `recipes_baking.txt` | mixing vessel list widened + roller list widened |
| `MakePancake` | `recipes_cooking.txt` | mixing vessel list widened |
| `MakePieDough` | `recipes_baking.txt` | mixing vessel list widened + roller list widened |
| `MakeShortbreadCookieDough` | `recipes_baking.txt` | mixing vessel list widened + roller list widened |
| `MakeSugarCookieDough` | `recipes_baking.txt` | mixing vessel list widened + roller list widened |
| `PrepareMuffins` | `recipes_baking.txt` | mixing vessel list widened |
| `MakePizza` | `recipes_cooking.txt` | roller list widened (its vessel input is already tag-based `tags[base:bowl]`, so it needs no vessel edit) |
| `PlacePieInBakingPan` | `recipes_baking.txt` | roller list widened (has no mixing-vessel input) |

## Table 2 — New `AH_` recipes (additions, not overrides)

Improvised can opening per design §7.3: screwdriver + hammer, penalized.
Each is a copy of the named vanilla template with the knife/can-opener tool
input replaced by two kept tool inputs
(`tags[base:screwdriver]` flags[MayDegradeLight] and
`tags[base:hammer;base:ballpeenhammer]` flags[MayDegradeVeryLight]) and
`time = 250` (the vanilla knife variant is 80). Everything else — OnCreate,
itemMapper, outputs, Tags, category, timedAction, Tooltip — is copied
unchanged from the template.

| New recipe | Copied from (template) | What it does |
|---|---|---|
| `AH_OpenCannedFoodImprovised` | `OpenCannedFoodWithKnifeOrSharpStoneFlake` (`recipes_cannedFood.txt`) | Opens any labeled canned food (full 16-entry `foodType` itemMapper) with screwdriver + hammer, at heavy time penalty |
| `AH_OpenUnlabeledCanImprovised` | `OpenUnlabeledCan` (`recipes_cannedFood.txt`) | Opens `Base.MysteryCan` with screwdriver + hammer, at heavy time penalty |
| `AH_OpenDentedUnlabeledCanImprovised` | `OpenDentedUnlabeledCan` (`recipes_cannedFood.txt`) | Opens `Base.DentedCan` with screwdriver + hammer, at heavy time penalty |
| `AH_OpenWaterRationCanImprovised` | `OpenWaterRationCan` (`recipes_cannedFood.txt`) | Opens `Base.WaterRationCan` with screwdriver + hammer, at heavy time penalty |

> Deferred: the design's contents-loss chance for improvised opening needs a
> custom lua `OnCreate`; these recipes currently reuse the vanilla `OnCreate`
> handlers unchanged.

## Maintenance

The override blocks are **verbatim copies from the B42.20 generated scripts**
(`scripts/generated/recipes/recipes_baking.txt` and `recipes_cooking.txt`),
with only the input lines noted in Table 1 changed. On **any game update**:

1. Locate each recipe named in Table 1 in the new vanilla generated scripts.
2. Diff the new vanilla block against the block in `AH_recipes_food.txt`.
3. If vanilla changed anything beyond the widened input lines (times, XP,
   ingredients, outputs, flags, tags), re-copy the new vanilla block verbatim
   and re-apply only the Table 1 widenings.
4. The Table 2 templates (`recipes_cannedFood.txt`) should be re-diffed the
   same way — in particular the `foodType` itemMapper in
   `AH_OpenCannedFoodImprovised`, which must track vanilla's canned-food list.

## Conflicts

- **Overrides (Table 1):** any other mod that overrides the same
  `craftRecipe` names conflicts with this mod — **last-loaded wins**, per the
  game's script loading. If another mod also widens these recipes, load order
  decides which version players get; there is no merging.
- **Additions (Table 2):** the `AH_`-prefixed recipes are new names that exist
  in no other mod or in vanilla — they **never conflict**.

## Why the §7.4 trades matrix is not overridden (audit conclusion)

Design §7.4 asks for tool-requirement widening across the trades (wrenching,
sawing, hammering, drilling, prying, etc.). An audit of all **1,171** B42.20
craftRecipes (`reference/`-backed, `recipes_stats.md`) found:

- **808** recipes have kept-tool inputs; **246** distinct tool specs.
- Tool inputs are **already tag-based** in B42 — e.g. `tags[base:hammer]`,
  `tags[base:saw;base:smallsaw;base:crudesaw]`, `tags[base:wrench]` — and a
  tag matches *every* item carrying it (29 knives satisfy `base:sharpknife`,
  6 openers satisfy `base:canopener`, etc.). This is exactly the
  "capability, not a SKU" model §7.1 asks for; vanilla already implements it.
- Only **42** kept-tool lines hard-require a single specific item. **All 42**
  are molds, crucibles, presses, glass-blowing pipes, or calipers — i.e. the
  tool *is* the physical form (a brick mold, a crucible). These are P11
  physics gates, not SKU gates, and are correctly left alone.

**Conclusion:** the only capability-widening that vanilla did NOT already do
was food mixing-vessels and rolling-pins (Table 1) and the improvised
can-opener path (Table 2). Those are shipped. The trades matrix needs no
overrides — B42's tag system already satisfies it. Documented here so the
absence is a verified decision, not an oversight.
