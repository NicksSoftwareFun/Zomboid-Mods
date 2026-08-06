--------------------------------------------------------------------------------
-- AH05_Data_Ledger.lua — §8 scarcity ledger numbers. PURE DATA, single
-- source of truth for every ledger line. Which mod APPLIES each line:
--
--   Line                        | Mechanism                | Applied by
--   ---------------------------+--------------------------+---------------
--   A firearms & ammo          | §6.4 correlated spawns   | Mod B (AHB02/12)
--   B bags: condition          | condition pass           | Mod B (AHB12 step 5)
--   B bags: capacity -20%      | item script patch        | DEFERRED (open item 3)
--   C shelf-stable ~14 days    | food pool scaling        | Mod A (AH14) — factors
--                              |                          | ship NEUTRAL (1.0) until
--                              |                          | the ten-house route
--                              |                          | measures the baseline
--                              |                          | (design §13: measure,
--                              |                          | then tune — no blind cuts)
--   D batteries ~30% dead      | charge pass              | Mod B (AHB12 step 5)
--   E medicine dose counts     | drainable charge pass    | Mod B (AHB12 step 5)
--   F fuel containers 0-40%    | charge pass              | Mod B (AHB12 step 5)
--   G cheap tools 30-70% cond  | archetype conditionProfile| Mod B (AHB00 data)
--   H perishables              | vanilla mechanics        | untouched by design
--
-- Mod A alone = quantity lines only; charge/condition lines need Mod B's
-- fill handler. Documented degrade, not a bug (design §0.1: Mod A is a
-- valid game on its own).
--------------------------------------------------------------------------------

AH = AH or {}
AH.Data = AH.Data or {}

AH.Data.Ledger = {
    -- Line C: multiplicative factors on residential food pools. NEUTRAL at
    -- 1.0 until route metrics exist; the mechanism ships so tuning is a
    -- data edit, not a code change.
    foodScale = {
        KitchenCannedFood = 1.0,
        KitchenDryFood    = 1.0,
        KitchenBreakfast  = 1.0,
        FridgeGeneric     = 1.0,
        FreezerGeneric    = 1.0,
    },

    -- Lines D/E/F: per-fullType charge profiles consumed by Mod B's charge
    -- pass. deadChance: probability the item spawns fully spent; otherwise
    -- remaining charge is uniform in [lo, hi]. setUsedDelta semantics are
    -- pcall-guarded in AHB12 and verified in-game (TESTPLAN).
    -- APPLIED by AHB14_Ledger.lua (fill-time, residential only, gated by
    -- LedgerEnabled). Battery/Pills/PropaneTank/LighterFluid are base:drainable
    -- and charge correctly via setUsedDelta (confirmed in-game).
    -- PetrolCan is base:normal + a FluidContainer; B42.20.2's FluidContainer
    -- exposes no getCapacity()/setAmount(), so its charge NO-OPS today (the
    -- can spawns full) — kept here so it self-heals if a build adds those
    -- accessors. Charging fuel-can fluid is otherwise DEFERRED (needs the
    -- confirmed B42 fluid API). It never throws (AHB14.setLedgerCharge guards
    -- every call) — the earlier console spam is fixed.
    charge = {
        ["Base.Battery"]    = { deadChance = 0.30, lo = 0.20, hi = 1.00 }, -- D
        ["Base.Pills"]      = { deadChance = 0.00, lo = 0.25, hi = 1.00 }, -- E: 10-40 doses of a full bottle
        ["Base.PetrolCan"]  = { deadChance = 0.15, lo = 0.05, hi = 0.40 }, -- F: 0-40% (fluid — no-ops until API confirmed)
        ["Base.PropaneTank"]= { deadChance = 0.10, lo = 0.10, hi = 0.60 }, -- F: 0-60%
        ["Base.LighterFluid"]={ deadChance = 0.10, lo = 0.20, hi = 0.80 },
    },
}
