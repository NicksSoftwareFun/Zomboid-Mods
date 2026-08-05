--------------------------------------------------------------------------------
-- AH02_Data_Residential.lua — declarative residential loot spec. PURE DATA.
-- Design doc §4; pool names are PROBE-CONFIRMED (tech spec §0.3).
--
-- PHASE 1 SCOPE: kitchen vertical slice only (design §13). The rest of §4
-- lands here in Phase 2 as more entries in the same shape — no code changes.
--
-- Entry shape:
--   item    = full item name.  !! IDs marked unverified=true are GUESSES
--             pending a read of the B42 scripts (Code-session task: verify
--             against steamapps/common/ProjectZomboid/media/scripts). The
--             merge pass validates via FindItem and skips+warns on unknowns,
--             so a wrong guess costs a log line, not a crash.
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
    { item = "Base.BreadKnife",    pool = "KitchenRandom", tier = "T1", nContainers = 3, unverified = true },
    { item = "Base.KnifeParing",   pool = "KitchenRandom", tier = "T1", nContainers = 3, unverified = true },
    { item = "Base.TinOpener",     pool = "KitchenRandom", tier = "T0", nContainers = 3 },
    { item = "Base.Scissors",      pool = "KitchenRandom", tier = "T1", nContainers = 3 },

    -- Heat vessels: KitchenPots is the narrow pool — closest thing to a
    -- true Approach A container in the confirmed list.
    { item = "Base.Pan",           pool = "KitchenPots", tier = "T0", nContainers = 1 },
    { item = "Base.Pot",           pool = "KitchenPots", tier = "T1", nContainers = 1 },
    { item = "Base.Saucepan",      pool = "KitchenPots", tier = "T1", nContainers = 1 },
    { item = "Base.GridlePan",     pool = "KitchenPots", tier = "T2", nContainers = 1, unverified = true },

    -- Baking / prep
    { item = "Base.BakingTray",    pool = "KitchenBaking", tier = "T1", nContainers = 1 },
    { item = "Base.RoastingPan",   pool = "KitchenBaking", tier = "T1", nContainers = 1 },
    { item = "Base.MixingBowl",    pool = "KitchenBaking", tier = "T1", nContainers = 1, unverified = true },
    { item = "Base.RollingPin",    pool = "KitchenBaking", tier = "T2", nContainers = 1 },
    { item = "Base.CuttingBoard",  pool = "KitchenRandom", tier = "T1", nContainers = 3, unverified = true },

    -- Utensils
    { item = "Base.Spatula",       pool = "KitchenDishes", tier = "T1", nContainers = 2, unverified = true },
    { item = "Base.SpoonWooden",   pool = "KitchenDishes", tier = "T1", nContainers = 2, unverified = true },
    { item = "Base.Whisk",         pool = "KitchenDishes", tier = "T2", nContainers = 2, unverified = true },
}
