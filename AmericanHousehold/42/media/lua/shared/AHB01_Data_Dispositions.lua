--------------------------------------------------------------------------------
-- AHB01_Data_Dispositions.lua — §6: what they did when it happened.
-- PURE DATA consumed by AHB12 step 4. Per P9: remove, deplete — never build.
--
-- Filter fields (all optional):
--   removeCategories = { cat=true }   -- every item of category removed
--   partialRemove    = { cat=frac }   -- each item of cat removed with p=frac
--   deplete          = { cat={lo,hi} }-- per-container removal fraction drawn
--                                     -- from [lo,hi], then applied per item
--   barterEligible   = true           -- §6.5 cache may spawn (sheltered only)
--   scatter          = true           -- §6.1 evac-panicked flavor; v1 logs a
--                                     -- documented simplification, no relocation
-- Categories come from AHB12.categoryOf: gun, ammo, bag, med, food, tool, other.
--------------------------------------------------------------------------------

AH = AH or {}
AH.B = AH.B or {}
AH.B.Data = AH.B.Data or {}

-- Fridge notes (§6.6) — NO NEW ART. Each disposition's note is an EXISTING
-- B42 lore item repurposed (verified ids), placed once per house in the
-- kitchen by AHB12. This turns each disposition from a loot pattern into a
-- legible story with zero art cost. nil = the disposition leaves no paper.
-- (survivalist overrides to a hand-drawn cache Map in AHB12 per §5.13.)
AH.B.Data.Dispositions = {
    -- The jackpot — and the diegetic cover for the mod's abundance (§1.5).
    -- The newspaper on the counter, never read: life stopped mid-morning.
    never_came_home = { note = "Base.Newspaper" },

    -- First thing packed: guns, ammo, meds, cash, photos, BAGS. Food,
    -- cookware, tools untouched — nobody flees with a socket set.
    -- A handwritten note left for a relative who never came.
    evac_organized = {
        removeCategories = { gun = true, ammo = true, bag = true, med = true },
        note = "Base.LetterHandwritten",
    },

    -- Grabbed the handgun, left the long guns; house in disarray. The
    -- partial fractions are the "randomized removal"; scatter is the
    -- documented v1 simplification (AHB12 header). No note — no time.
    evac_panicked = {
        partialRemove = { gun = 0.5, ammo = 0.5, bag = 0.4, med = 0.3 },
        scatter = true,
    },

    -- Food heavily depleted, candles burned, guns present with ammo
    -- 30-70% spent, tools present. §6.5: barter caches live here.
    -- A journal kept through the sheltering.
    sheltered_prepared = {
        deplete = { food = { 0.6, 0.9 }, ammo = { 0.3, 0.7 } },
        barterEligible = true,
        note = "Base.Journal",
    },

    -- Food consumed to near-zero; else untouched. A grocery list from the
    -- last normal day (a plain Note, repurposed).
    sheltered_unprepared = {
        deplete = { food = { 0.85, 1.0 } },
        barterEligible = true,
        note = "Base.Note",
    },

    -- Pre-quarantine looting: guns and ammo first, then food and meds.
    -- Heavy tools LEFT (§1.4 encumbrance logic). Low matrix weight.
    looted = {
        removeCategories = { gun = true, ammo = true },
        deplete = { food = { 0.5, 0.8 }, med = { 0.5, 0.8 }, bag = { 0.3, 0.6 } },
    },
}

--------------------------------------------------------------------------------
-- §6.2 correlation matrix — constrained, ~sensible pairings only, anchors
-- from the design doc verbatim:
--   military -> sheltered-prepared / evacuated-organized
--   elderly  -> never-came-home / sheltered-unprepared
--   starter  -> evacuated-panicked
--   canning/wood-heat -> sheltered-prepared
--   commuter -> evacuated-organized
--   survivalist -> LOCKED to sheltered_prepared (the only hard lock; §5.13 —
--                  the estate of a doctrine that half-worked)
-- Weights are relative within a row (pickWeighted normalizes).
-- F1 lever (open question 5): never_came_home lands ~20-25% population-wide.
--------------------------------------------------------------------------------

local D = {
    NCH = "never_came_home",  EO = "evac_organized",  EP = "evac_panicked",
    SP  = "sheltered_prepared", SU = "sheltered_unprepared", LO = "looted",
}

local function row(t)
    local r = {}
    for i = 1, #t, 2 do r[#r + 1] = { value = t[i], w = t[i + 1] } end
    return r
end

AH.B.Data.Matrix = {
    military    = row { D.SP, 30, D.EO, 30, D.NCH, 20, D.SU, 10, D.EP, 5,  D.LO, 5 },
    canning     = row { D.SP, 40, D.NCH, 25, D.SU, 15, D.EO, 10, D.EP, 5,  D.LO, 5 },
    woodheat    = row { D.SP, 40, D.NCH, 20, D.SU, 15, D.EO, 10, D.EP, 10, D.LO, 5 },
    hunting     = row { D.SP, 25, D.NCH, 25, D.EO, 20, D.EP, 15, D.SU, 10, D.LO, 5 },
    handy       = row { D.NCH, 25, D.SP, 20, D.EO, 20, D.EP, 15, D.SU, 15, D.LO, 5 },
    commuter    = row { D.EO, 35, D.EP, 20, D.NCH, 20, D.SU, 15, D.SP, 5,  D.LO, 5 },
    elderly     = row { D.NCH, 35, D.SU, 30, D.SP, 10, D.EO, 10, D.EP, 10, D.LO, 5 },
    starter     = row { D.EP, 35, D.NCH, 20, D.EO, 15, D.SU, 15, D.LO, 10, D.SP, 5 },
    mobile      = row { D.NCH, 25, D.EP, 20, D.SU, 20, D.SP, 15, D.EO, 10, D.LO, 10 },
    survivalist = row { D.SP, 100 },                       -- the hard lock
    __default   = row { D.NCH, 25, D.EO, 15, D.EP, 15, D.SP, 15, D.SU, 20, D.LO, 10 },
}
