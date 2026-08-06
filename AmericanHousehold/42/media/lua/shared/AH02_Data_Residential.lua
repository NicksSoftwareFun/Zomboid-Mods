--------------------------------------------------------------------------------
-- AH02_Data_Residential.lua — declarative residential loot spec. PURE DATA.
-- Design doc §4. Pool names verified against the B42.20 Distributions.lua
-- room->container->pool mapping (extraction, Aug 2026); item IDs verified
-- against reference/b42.20_item_ids.txt.
--
-- PHASE 2 SCOPE: full §4 residential. Kitchen slice was Phase 1 (in-game
-- verified). nContainers = typical containers per room drawing the pool,
-- from the Distributions mapping (e.g. kitchen counters+overheads+shelves
-- all draw KitchenDishes -> nContainers 3).
--
-- approachC = true marks T0 entries whose certainty Mod B's guarantee pass
-- supplies (design §3.1 Approach C). When Mod B is loaded (AH.B present at
-- merge), AH11 solves these at T2 instead — pools supply variety, the
-- guarantee supplies certainty, and F3 duplication stays controlled.
--
-- B42.20 REALITY NOTES (F6 honesty — items the design lists that do NOT
-- exist, verified missing): antacid, cough syrup, cold medicine, ointment,
-- thermometer, shampoo, dustpan, clothes pins, smoke detector, 9V battery,
-- spirit level, hacksaw tool (blade only), powered drills, sandpaper,
-- motor oil, WD-40, antifreeze, jumper cables, lawn mower, wheelbarrow,
-- hedge trimmer, bungee, extension cord, step ladder, bicycle, splitting
-- maul, chainsaw, blender, mixer, crock pot, measuring cups, thermos,
-- tin foil, plastic wrap. Their design roles are either dropped, covered
-- by a substitute noted inline, or deferred to Phase 7 [new] items.
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

-- Phase 1 entries above get approachC flags now that Mod B exists:
for _, e in ipairs(AH.Data.Residential) do
    if e.tier == "T0" then e.approachC = true end
end

--------------------------------------------------------------------------------
-- Phase 2: the rest of §4, same shape. Appended so the Phase 1 slice stays
-- readable as the worked example.
--------------------------------------------------------------------------------
local R = AH.Data.Residential
local function add(t) R[#R + 1] = t end

-- ===== Kitchen: junk drawer, Mod A reduced version (§4.1) =====
-- KitchenRandom is the designated junk-drawer pool (open item 5 decision:
-- it serves every counter, and vanilla already stocks it with keys/clutter).
-- Dead-battery flavor is fill-time work (Mod B ledger-charge pass).
add { item = "Base.Battery",           pool = "KitchenRandom", tier = "T1", nContainers = 3 }
add { item = "Base.Matches",           pool = "KitchenRandom", tier = "T1", nContainers = 3 }
add { item = "Base.LighterDisposable", pool = "KitchenRandom", tier = "T1", nContainers = 3 }
add { item = "Base.DuctTape",          pool = "KitchenRandom", tier = "T2", nContainers = 3 }
add { item = "Base.Screwdriver",       pool = "KitchenRandom", tier = "T2", nContainers = 3 }
add { item = "Base.MeasuringTape",     pool = "KitchenRandom", tier = "T2", nContainers = 3 }
add { item = "Base.BottleOpener",      pool = "KitchenRandom", tier = "T1", nContainers = 3 }
add { item = "Base.Corkscrew",         pool = "KitchenRandom", tier = "T2", nContainers = 3 }
add { item = "Base.Bleach",            pool = "KitchenRandom", tier = "T1", nContainers = 3 } -- under-sink; T0 via Mod B guarantee
add { item = "Base.Sponge",            pool = "KitchenRandom", tier = "T1", nContainers = 3 }
add { item = "Base.Kettle",            pool = "KitchenPots",   tier = "T1", nContainers = 1 }
add { item = "Base.Strainer",          pool = "KitchenPots",   tier = "T2", nContainers = 1 } -- colander

-- ===== Bathroom (§4.2) =====
-- Medicine cabinet pool: BathroomCabinet (the 'medicine' container, 1/room).
add { item = "Base.Pills",              pool = "BathroomCabinet", tier = "T0", nContainers = 1, approachC = true } -- generic painkillers; doses = ledger E (fill-time)
add { item = "Base.Bandaid",            pool = "BathroomCabinet", tier = "T0", nContainers = 1, approachC = true }
add { item = "Base.Bandage",            pool = "BathroomCabinet", tier = "T1", nContainers = 1 }
add { item = "Base.Disinfectant",       pool = "BathroomCabinet", tier = "T1", nContainers = 1 } -- peroxide/rubbing alcohol role
add { item = "Base.AlcoholWipes",       pool = "BathroomCabinet", tier = "T2", nContainers = 1 }
add { item = "Base.CottonBalls",        pool = "BathroomCabinet", tier = "T1", nContainers = 1 }
add { item = "Base.Tweezers",           pool = "BathroomCabinet", tier = "T1", nContainers = 1 }
add { item = "Base.ScissorsBlunt",      pool = "BathroomCabinet", tier = "T1", nContainers = 1 } -- small scissors
add { item = "Base.Razor",              pool = "BathroomCabinet", tier = "T1", nContainers = 1 }
add { item = "Base.PillsVitamins",      pool = "BathroomCabinet", tier = "T2", nContainers = 1 }
add { item = "Base.PillsSleepingTablets", pool = "BathroomCabinet", tier = "T3", nContainers = 1 }
add { item = "Base.PillsBeta",          pool = "BathroomCabinet", tier = "T3", nContainers = 1 } -- prescription texture
-- Linen: BathroomShelf + BathroomCounter (one each per room typically).
add { item = "Base.BathTowel",          pool = "BathroomShelf",   tier = "T0", nContainers = 1, approachC = true } -- Approach B: multiples plausible
add { item = "Base.ToiletPaper",        pool = "BathroomShelf",   tier = "T0", nContainers = 1, approachC = true }
add { item = "Base.Soap2",              pool = "BathroomCounter", tier = "T0", nContainers = 1, approachC = true }
add { item = "Base.DishCloth",          pool = "BathroomShelf",   tier = "T1", nContainers = 1 } -- washcloth
add { item = "Base.FirstAidKit",        pool = "BathroomShelf",   tier = "T2", nContainers = 1 }
add { item = "Base.Plunger",            pool = "BathroomCounter", tier = "T1", nContainers = 1 }

-- ===== Bedroom (§4.3) =====
-- Nightstand pool BedroomSidetable; most bedrooms have 1-2 -> nContainers 2.
add { item = "Base.Torch",             pool = "BedroomSidetable", tier = "T1", nContainers = 2 }
add { item = "Base.Battery",           pool = "BedroomSidetable", tier = "T2", nContainers = 2 } -- secondary (§4.9)
add { item = "Base.Glasses_Reading",   pool = "BedroomSidetable", tier = "T2", nContainers = 2 }
add { item = "Base.Paperback",         pool = "BedroomSidetable", tier = "T1", nContainers = 2 }
add { item = "Base.Tissue",            pool = "BedroomSidetable", tier = "T1", nContainers = 2 }
add { item = "Base.AlarmClock2",       pool = "BedroomSidetable", tier = "T1", nContainers = 2 }
-- Closet/wardrobe: bags are ledger B — present but taxed (condition via Mod B).
add { item = "Base.Suitcase",          pool = "WardrobeGeneric",  tier = "T1", nContainers = 2 }
add { item = "Base.Bag_Schoolbag",     pool = "WardrobeGeneric",  tier = "T2", nContainers = 2 }
add { item = "Base.Bag_DuffelBag",     pool = "WardrobeGeneric",  tier = "T2", nContainers = 2 }
add { item = "Base.Sheet",             pool = "WardrobeGeneric",  tier = "T1", nContainers = 2 }
add { item = "Base.SewingKit",         pool = "BedroomDresser",   tier = "T2", nContainers = 2 }
add { item = "Base.PhotoAlbum",        pool = "BedroomDresser",   tier = "T1", nContainers = 2 }

-- ===== Living room (§4.4) =====
-- TV/VCR/computer are map furniture, not loot (Mov_ items excluded by
-- decision — inserting carryable appliances into loot pools reads wrong).
add { item = "Base.VHS_Home",          pool = "LivingRoomShelf",     tier = "T1", nContainers = 2 }
add { item = "Base.VHS_Retail",        pool = "LivingRoomShelf",     tier = "T1", nContainers = 2 }
add { item = "Base.Book",              pool = "LivingRoomShelf",     tier = "T1", nContainers = 2 }
add { item = "Base.Magazine",          pool = "LivingRoomShelf",     tier = "T1", nContainers = 2 }
add { item = "Base.Candle",            pool = "LivingRoomShelf",     tier = "T1", nContainers = 2 }
add { item = "Base.Phonebook",         pool = "LivingRoomSideTable", tier = "T1", nContainers = 2 }
add { item = "Base.Remote",            pool = "LivingRoomSideTable", tier = "T1", nContainers = 2 }
add { item = "Base.Matches",           pool = "LivingRoomSideTable", tier = "T1", nContainers = 2 }
add { item = "Base.Lighter",           pool = "LivingRoomSideTable", tier = "T2", nContainers = 2 }
add { item = "Base.RadioBlack",        pool = "LivingRoomSideTable", tier = "T2", nContainers = 2 } -- §5.12 battery radio
add { item = "Base.CDplayer",          pool = "LivingRoomShelf",     tier = "T2", nContainers = 2 }
add { item = "Base.VideoGame",         pool = "LivingRoomShelf",     tier = "T2", nContainers = 2 }

-- ===== Laundry / utility (§4.5) =====
-- LaundryCleaning serves counter + other; residential laundry rooms are
-- uncommon in Muldraugh housing stock, cheap either way.
add { item = "Base.Broom",             pool = "LaundryCleaning", tier = "T0", nContainers = 2, approachC = true }
add { item = "Base.Mop",               pool = "LaundryCleaning", tier = "T1", nContainers = 2 }
add { item = "Base.Bucket",            pool = "LaundryCleaning", tier = "T1", nContainers = 2 } -- owning room (§4.9)
add { item = "Base.CleaningLiquid2",   pool = "LaundryCleaning", tier = "T1", nContainers = 2 }
add { item = "Base.Soap2",             pool = "LaundryCleaning", tier = "T1", nContainers = 2 } -- detergent role
add { item = "Base.Sponge",            pool = "LaundryCleaning", tier = "T1", nContainers = 2 }
add { item = "Base.Gloves_LeatherGloves", pool = "LaundryCleaning", tier = "T1", nContainers = 2 } -- work gloves role
add { item = "Base.BathTowel",         pool = "LaundryCleaning", tier = "T1", nContainers = 2 }

-- ===== Garage & shed (§4.6/§4.7) =====
-- Residential garages are room type 'garagestorage' (the map's 'garage'
-- room aliases the MECHANIC tables — commercial). GarageTools serves
-- locker+counter+shelves (n=2 typical); Carpentry/Mechanics/Metalwork one
-- counter/shelf each. Sheds draw the same Garage* pools.
add { item = "Base.Hammer",            pool = "GarageTools",     tier = "T0", nContainers = 2, approachC = true }
add { item = "Base.Screwdriver",       pool = "GarageTools",     tier = "T0", nContainers = 2, approachC = true }
add { item = "Base.Pliers",            pool = "GarageTools",     tier = "T0", nContainers = 2, approachC = true }
add { item = "Base.Wrench",            pool = "GarageTools",     tier = "T1", nContainers = 2 }
add { item = "Base.Ratchet",           pool = "GarageTools",     tier = "T1", nContainers = 2 } -- socket set role
add { item = "Base.MeasuringTape",     pool = "GarageTools",     tier = "T1", nContainers = 2 }
add { item = "Base.KnifePocket",       pool = "GarageTools",     tier = "T1", nContainers = 2 } -- utility knife role
add { item = "Base.ViseGrips",         pool = "GarageTools",     tier = "T2", nContainers = 2 }
add { item = "Base.Crowbar",           pool = "GarageTools",     tier = "T2", nContainers = 2 }
add { item = "Base.PipeWrench",        pool = "GarageTools",     tier = "T2", nContainers = 2 }
add { item = "Base.ClubHammer",        pool = "GarageTools",     tier = "T2", nContainers = 2 }
add { item = "Base.DuctTape",          pool = "GarageTools",     tier = "T1", nContainers = 2 }
add { item = "Base.Rope",              pool = "GarageTools",     tier = "T1", nContainers = 2 }
add { item = "Base.Axe",               pool = "GarageTools",     tier = "T2", nContainers = 2 } -- shed axe (§4.7)
add { item = "Base.WoodAxe",           pool = "GarageTools",     tier = "T3", nContainers = 2 }
add { item = "Base.Sledgehammer",      pool = "GarageTools",     tier = "T3", nContainers = 2 } -- maul does not exist; nearest heavy splitter
-- Carpentry bench
add { item = "Base.Saw",               pool = "GarageCarpentry", tier = "T1", nContainers = 1 }
add { item = "Base.NailsBox",          pool = "GarageCarpentry", tier = "T1", nContainers = 1 }
add { item = "Base.ScrewsBox",         pool = "GarageCarpentry", tier = "T1", nContainers = 1 }
add { item = "Base.Woodglue",          pool = "GarageCarpentry", tier = "T2", nContainers = 1 }
add { item = "Base.HandDrill",         pool = "GarageCarpentry", tier = "T2", nContainers = 1 } -- no powered drills exist in B42.20
add { item = "Base.CarpentryChisel",   pool = "GarageCarpentry", tier = "T3", nContainers = 1 }
-- Automotive shelf (fuel fill % is ledger F, fill-time)
add { item = "Base.LugWrench",         pool = "GarageMechanics", tier = "T1", nContainers = 1 }
add { item = "Base.Jack",              pool = "GarageMechanics", tier = "T1", nContainers = 1 }
add { item = "Base.TireIron",          pool = "GarageMechanics", tier = "T2", nContainers = 1 }
add { item = "Base.PetrolCan",         pool = "GarageMechanics", tier = "T1", nContainers = 1 }
add { item = "Base.Funnel",            pool = "GarageMechanics", tier = "T2", nContainers = 1 }
add { item = "Base.CarBattery1",       pool = "GarageMechanics", tier = "T2", nContainers = 1 }
add { item = "Base.RubberHose",        pool = "GarageMechanics", tier = "T2", nContainers = 1 }
-- Yard & outdoor living (CrateFarming serves sheds + garage crates)
add { item = "Base.Rake",              pool = "CrateFarming",    tier = "T1", nContainers = 1 }
add { item = "Base.Shovel",            pool = "CrateFarming",    tier = "T1", nContainers = 1 }
add { item = "Base.GardenHoe",         pool = "CrateFarming",    tier = "T2", nContainers = 1 }
add { item = "Base.HandShovel",        pool = "CrateFarming",    tier = "T1", nContainers = 1 } -- trowel
add { item = "Base.WateredCan",        pool = "CrateFarming",    tier = "T2", nContainers = 1 }
add { item = "Base.Fertilizer",        pool = "CrateFarming",    tier = "T2", nContainers = 1 }
add { item = "Base.Twine",             pool = "CrateFarming",    tier = "T2", nContainers = 1 }
add { item = "Base.Charcoal",          pool = "GarageTools",     tier = "T2", nContainers = 2 } -- grill fuel
add { item = "Base.LighterFluid",      pool = "GarageTools",     tier = "T2", nContainers = 2 }
add { item = "Base.Cooler",            pool = "GarageTools",     tier = "T2", nContainers = 2 }
add { item = "Base.Tarp",              pool = "CrateFarming",    tier = "T2", nContainers = 1 }

-- ===== Regional texture (§5.11/§5.12) — Mod A share =====
add { item = "Base.Lard",              pool = "KitchenBaking",     tier = "T2", nContainers = 1 }
add { item = "Base.Cornmeal2",         pool = "KitchenBaking",     tier = "T2", nContainers = 1 }
add { item = "Base.Teabag2",           pool = "KitchenDryFood",    tier = "T2", nContainers = 2 }
add { item = "Base.Coffee2",           pool = "KitchenDryFood",    tier = "T1", nContainers = 2 }
add { item = "Base.Whiskey",           pool = "KitchenBottles",    tier = "T2", nContainers = 2 } -- bourbon; wet/dry nuance is open question 4
add { item = "Base.Lantern_Hurricane", pool = "ClosetShelfGeneric", tier = "T2", nContainers = 1 } -- §5.12 oil lamp
add { item = "Base.CandleBox",         pool = "ClosetShelfGeneric", tier = "T3", nContainers = 1 }
