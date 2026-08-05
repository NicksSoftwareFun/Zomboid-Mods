--------------------------------------------------------------------------------
-- AH02_Data_Residential.lua — declarative residential loot spec. PURE DATA.
-- Design doc §4; pool names are PROBE-CONFIRMED (tech spec §0.3).
--
-- PHASE 1 SCOPE: kitchen vertical slice only (design §13). The rest of §4
-- lands here in Phase 2 as more entries in the same shape — no code changes.
--
-- Entry shape:
--   item    = full item name. ALL IDs below VERIFIED against the B42.20
--             media/scripts item definitions (Aug 2026 upload; index kept in
--             reference/b42.20_item_ids.txt). The merge pass still validates
--             via FindItem and skips+warns on unknowns, so a future game
--             update that renames an item costs a log line, not a crash.
--   pool    = probe-confirmed pool the item lives in (Approach A placement)
--   tier    = T0..T3 (AH01 targets)
--   nContainers = estimated containers per room drawing this pool (for
--             perContainerTarget). Tune from in-game observation, ticket 4.
--------------------------------------------------------------------------------

AH = AH or {}
AH.Data = AH.Data or {}

AH.Data.Residential = {
    -- ===== Kitchen: the thesis test (design §1.1, §4.1) =====
    -- The knife block: T0. KitchenRandom serves several counters, so the
    -- per-container solve keeps duplicates in check; true one-per-room
    -- precision is Mod B's Approach C. This gets us to ~"almost every
    -- kitchen, occasionally two" — acceptable for the Phase 1 signal.
    { item = "Base.KitchenKnife",  pool = "KitchenRandom", tier = "T0", nContainers = 3 },
    { item = "Base.BreadKnife",    pool = "KitchenRandom", tier = "T1", nContainers = 3 },
    { item = "Base.KnifeParing",   pool = "KitchenRandom", tier = "T1", nContainers = 3 },
    { item = "Base.TinOpener",     pool = "KitchenRandom", tier = "T0", nContainers = 3 },
    { item = "Base.Scissors",      pool = "KitchenRandom", tier = "T1", nContainers = 3 },

    -- Heat vessels: KitchenPots is the narrow pool — closest thing to a
    -- true Approach A container in the confirmed list.
    { item = "Base.Pan",           pool = "KitchenPots", tier = "T0", nContainers = 1 },
    { item = "Base.Pot",           pool = "KitchenPots", tier = "T1", nContainers = 1 },
    { item = "Base.Saucepan",      pool = "KitchenPots", tier = "T1", nContainers = 1 },
    { item = "Base.GridlePan",     pool = "KitchenPots", tier = "T2", nContainers = 1 },

    -- Cutting boards: vanilla splits the concept into two items and already
    -- places both in KitchenPots (w=4 each) — we follow that placement.
    -- Two variants at T2 each gives combined presence 1-(1-.425)^2 ≈ 0.67,
    -- an acceptable Phase 1 approximation of the design's T1 target for
    -- "a cutting board, either kind" (exact split solving is not worth the
    -- machinery at this scope; revisit only if route metrics miss).
    { item = "Base.CuttingBoardWooden",  pool = "KitchenPots", tier = "T2", nContainers = 1 },
    { item = "Base.CuttingBoardPlastic", pool = "KitchenPots", tier = "T2", nContainers = 1 },

    -- Baking / prep. "MixingBowl" does not exist in B42 — the generic
    -- Base.Bowl is the mixing/prep bowl (and the cooking-recipe vessel).
    { item = "Base.BakingTray",    pool = "KitchenBaking", tier = "T1", nContainers = 1 },
    { item = "Base.RoastingPan",   pool = "KitchenBaking", tier = "T1", nContainers = 1 },
    { item = "Base.Bowl",          pool = "KitchenBaking", tier = "T1", nContainers = 1 },
    { item = "Base.RollingPin",    pool = "KitchenBaking", tier = "T2", nContainers = 1 },

    -- Utensils. "SpoonWooden" does not exist in B42 — Base.Spoon is the
    -- stirring spoon (vanilla puts it in both KitchenDishes and KitchenBaking).
    { item = "Base.Spatula",       pool = "KitchenDishes", tier = "T1", nContainers = 2 },
    { item = "Base.Spoon",         pool = "KitchenDishes", tier = "T1", nContainers = 2 },
    { item = "Base.Whisk",         pool = "KitchenDishes", tier = "T2", nContainers = 2 },
}
