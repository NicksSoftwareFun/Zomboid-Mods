# reference/ — extracted B42 ground truth

Extracted from a B42.20 install's game files (user-uploaded, Aug 2026) so ID
verification and solver planning work without re-uploading the game. If the
game updates and something misbehaves, regenerate these before debugging code.

| File | Source | Use |
|---|---|---|
| `b42.20_item_ids.txt` | every `item X` in `media/scripts/**/*.txt` (5,120 ids, all module `Base`) | verify item IDs before adding to any AH data file — an ID not in this list is wrong |
| `b42.20_pool_stats.tsv` | parsed `media/lua/server/Items/ProceduralDistributions.lua` (1,424 pools) | pool name / rolls / item count / total weight — offline solver estimates |
| `b42.20_kitchen_pools.lua` | same file, verbatim blocks | the ten `Kitchen*` pools with exact vanilla weights; ticket 4 tuning |

Facts these files settled (tech spec §8):

- **Pool entry shape (open item 2):** B42 kept the B41 flat shape —
  `{ rolls=n, items={"Name",w,...}, junk={rolls,items} }` plus optional
  scalar flags (`ignoreZombieDensity`, `cookFood`, `onlyOne`).
- **Entry naming:** short names with module `Base` implied; fully-qualified
  `Base.X` entries are rare (maps). AH10 normalizes both spellings.
- **Sandbox options (open item 6):** B42 uses the B41 `sandbox-options.txt`
  format (`VERSION = 1,` + `option Page.Name { ... }` blocks) — confirmed
  against a current B42 Workshop mod.
- **Still missing:** `VehicleZoneDistribution` is NOT defined in
  `media/lua/server/Vehicles/` — the zone spawn tables live elsewhere
  (B41 had them in `VehicleZoneDefinition.lua`). Ticket 6 needs that file.
