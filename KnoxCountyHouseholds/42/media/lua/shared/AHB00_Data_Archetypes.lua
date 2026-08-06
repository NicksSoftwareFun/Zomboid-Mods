--------------------------------------------------------------------------------
-- AHB00_Data_Archetypes.lua — §5 archetypes, regions, the Approach-C
-- guarantee sets, and barter caches. PURE DATA consumed by AHB10/AHB12.
--
-- All item ids VERIFIED against reference/b42.20_item_ids.txt. Container and
-- room-type names VERIFIED against the B42.20 Distributions mapping and the
-- Phase-0 probe (roomTypeArg=kitchen/bedroom/livingroom/garagestorage/shed).
--
-- Package entry contract (AHB12 step 1):
--   { item="Base.X", count={min,max}, chance=0..1, nContainers=<eligible/bldg>,
--     rooms={room=true,...}|nil, containers={ctype=true,...}|nil,
--     condition={lo,hi}|nil }
-- chance is PER BUILDING; AHB12 converts to per-container via nContainers.
--------------------------------------------------------------------------------

AH = AH or {}
AH.B = AH.B or {}
AH.B.Data = AH.B.Data or {}

--== Residential room whitelist (§3.5 step 5) ==================================
-- Fill handler only applies to these; everything else is Mod A's (setpieces,
-- commercial). Names are the literal roomType strings the game passes.
AH.B.Data.ResidentialRooms = {
    kitchen = true, bedroom = true, kidsbedroom = true, livingroom = true,
    bathroom = true, closet = true, laundry = true, garagestorage = true,
    shed = true, storage = true, hall = true, dining = true,
}

--== Regions (§3.4) — point-in-rectangle over Muldraugh-area map coords ========
-- APPROXIMATE and TUNABLE (this is data, per design §3.4). Probe buildings
-- clustered ~x10700-11000, y9480-9830 (Muldraugh). West Point sits NE, farm
-- country to the outskirts. Rectangles bias archetype weights only; getting
-- them slightly wrong shifts flavor, never breaks determinism.
AH.B.Data.Regions = {
    default = "outskirts",
    list = {
        { name = "muldraugh_core", x1 = 10600, y1 = 9300, x2 = 11200, y2 = 10200 },
        { name = "west_point",     x1 = 11000, y1 = 6400, x2 = 12200, y2 = 7700 },
        { name = "highway",        x1 = 10600, y1 = 7700, x2 = 11400, y2 = 9300 },
    },
}

--== Archetype weights per region (§5 regional weighting) ======================
-- "military near Muldraugh (Fort Knox), farms outskirts, commuters toward
-- West Point." survivalist is T4-rare everywhere. Weights are relative.
local function wl(t)
    local r = {}
    for i = 1, #t, 2 do r[#r + 1] = { value = t[i], w = t[i + 1] } end
    return r
end
AH.B.Data.ArchetypeWeights = {
    muldraugh_core = wl {
        "military", 22, "commuter", 16, "elderly", 14, "handy", 12,
        "starter", 12, "woodheat", 6, "canning", 6, "hunting", 6,
        "mobile", 4, "survivalist", 2 },
    west_point = wl {
        "commuter", 24, "elderly", 14, "handy", 12, "starter", 12,
        "military", 12, "canning", 8, "hunting", 6, "woodheat", 6,
        "mobile", 4, "survivalist", 2 },
    highway = wl {
        "handy", 16, "commuter", 16, "hunting", 12, "mobile", 12,
        "elderly", 12, "military", 10, "woodheat", 8, "canning", 8,
        "starter", 4, "survivalist", 2 },
    outskirts = wl {
        "hunting", 16, "canning", 14, "woodheat", 14, "handy", 14,
        "elderly", 12, "mobile", 10, "military", 8, "commuter", 6,
        "starter", 4, "survivalist", 2 },
}

--== Archetype packages (§5) ===================================================
-- Signature ADDITIONS only — the baseline every house gets is Mod A's job.
-- These are what make a military house read military. conditionProfile is
-- the archetype's tool/durable wear band (design §1.3, ledger G).
local ROOMS_STORAGE = { bedroom = true, closet = true, storage = true,
                        garagestorage = true, shed = true }
local CONT_STORAGE  = { wardrobe = true, locker = true, crate = true,
                        metal_shelves = true, other = true, counter = true }

AH.B.Data.Archetypes = {
    military = {
        conditionProfile = { 0.7, 1.0 },
        package = {
            { item = "Base.Bag_ALICEpack_Army", count = {1,1}, chance = 0.7, nContainers = 2, rooms = ROOMS_STORAGE, containers = CONT_STORAGE },
            { item = "Base.CanteenMilitary", count = {1,2}, chance = 0.8, nContainers = 2, rooms = ROOMS_STORAGE, containers = CONT_STORAGE },
            { item = "Base.EntrenchingTool", count = {1,1}, chance = 0.6, nContainers = 2, rooms = ROOMS_STORAGE, containers = CONT_STORAGE, condition = {0.6,1.0} },
            { item = "Base.Shoes_ArmyBoots", count = {1,1}, chance = 0.7, nContainers = 2, rooms = ROOMS_STORAGE, containers = CONT_STORAGE },
            { item = "Base.Jacket_ArmyCamoGreen", count = {1,2}, chance = 0.7, nContainers = 2, rooms = ROOMS_STORAGE, containers = CONT_STORAGE },
            { item = "Base.Trousers_CamoGreen", count = {1,2}, chance = 0.6, nContainers = 2, rooms = ROOMS_STORAGE, containers = CONT_STORAGE },
            { item = "Base.PonchoGreen", count = {1,1}, chance = 0.4, nContainers = 2, rooms = ROOMS_STORAGE, containers = CONT_STORAGE },
            { item = "Base.Bag_AmmoBox", count = {1,3}, chance = 0.6, nContainers = 2, rooms = ROOMS_STORAGE, containers = CONT_STORAGE },
        },
    },
    canning = {
        conditionProfile = { 0.5, 0.95 },
        package = {
            { item = "Base.EmptyJar", count = {4,12}, chance = 0.95, nContainers = 3, rooms = { kitchen=true, closet=true, storage=true, shed=true }, containers = { counter=true, shelves=true, metal_shelves=true, other=true, crate=true } },
            { item = "Base.JarLid", count = {4,12}, chance = 0.9, nContainers = 3, rooms = { kitchen=true, closet=true, storage=true, shed=true }, containers = { counter=true, shelves=true, metal_shelves=true, other=true, crate=true } },
            { item = "Base.BoxOfJars", count = {1,2}, chance = 0.5, nContainers = 2, rooms = { closet=true, storage=true, shed=true }, containers = { crate=true, other=true, metal_shelves=true } },
            { item = "Base.Pot", count = {1,1}, chance = 0.6, nContainers = 1, rooms = { kitchen=true }, containers = { counter=true } }, -- water-bath canner stand-in (§5.3: no pressure canner item exists)
            { item = "Base.Fertilizer", count = {1,2}, chance = 0.5, nContainers = 1, rooms = { shed=true, garagestorage=true }, containers = { crate=true, other=true } },
        },
    },
    woodheat = {
        conditionProfile = { 0.4, 0.9 },
        package = {
            { item = "Base.WoodAxe", count = {1,1}, chance = 0.9, nContainers = 2, rooms = { shed=true, garagestorage=true, storage=true }, containers = { counter=true, metal_shelves=true, other=true }, condition = {0.5,1.0} },
            { item = "Base.Sledgehammer", count = {1,1}, chance = 0.6, nContainers = 2, rooms = { shed=true, garagestorage=true }, containers = { counter=true, metal_shelves=true, other=true }, condition = {0.4,0.9} }, -- maul stand-in (no maul item)
            { item = "Base.Log", count = {3,8}, chance = 0.9, nContainers = 2, rooms = { shed=true, garagestorage=true, storage=true }, containers = { crate=true, other=true } },
            { item = "Base.Hatchet_Bone", count = {1,1}, chance = 0.2, nContainers = 1, rooms = { shed=true }, containers = { other=true } },
            { item = "Base.Lantern_Hurricane", count = {1,1}, chance = 0.4, nContainers = 2, rooms = { shed=true, storage=true, closet=true }, containers = { other=true, metal_shelves=true } },
        },
    },
    hunting = {
        conditionProfile = { 0.5, 0.95 },
        package = {
            { item = "Base.HuntingKnife", count = {1,1}, chance = 0.8, nContainers = 2, rooms = { bedroom=true, closet=true, garagestorage=true }, containers = { wardrobe=true, locker=true, other=true }, condition = {0.5,1.0} },
            { item = "Base.FishingRod", count = {1,1}, chance = 0.6, nContainers = 2, rooms = { closet=true, garagestorage=true, shed=true }, containers = { locker=true, crate=true, other=true } },
            { item = "Base.Tacklebox", count = {1,1}, chance = 0.5, nContainers = 2, rooms = { closet=true, garagestorage=true, shed=true }, containers = { locker=true, crate=true, other=true } },
            { item = "Base.Jacket_HuntingCamo", count = {1,2}, chance = 0.7, nContainers = 2, rooms = { bedroom=true, closet=true }, containers = { wardrobe=true, locker=true } },
            { item = "Base.Trousers_HuntingCamo", count = {1,1}, chance = 0.5, nContainers = 2, rooms = { bedroom=true, closet=true }, containers = { wardrobe=true, locker=true } },
        },
    },
    handy = {
        conditionProfile = { 0.4, 0.9 },
        package = {
            { item = "Base.ViseGrips", count = {1,1}, chance = 0.6, nContainers = 2, rooms = { garagestorage=true, shed=true }, containers = { counter=true, metal_shelves=true, other=true }, condition = {0.4,0.9} },
            { item = "Base.HandDrill", count = {1,1}, chance = 0.6, nContainers = 2, rooms = { garagestorage=true, shed=true }, containers = { counter=true, metal_shelves=true } },
            { item = "Base.CarpentryChisel", count = {1,2}, chance = 0.5, nContainers = 2, rooms = { garagestorage=true, shed=true }, containers = { counter=true, metal_shelves=true } },
            { item = "Base.NailsBox", count = {1,3}, chance = 0.8, nContainers = 2, rooms = { garagestorage=true, shed=true }, containers = { counter=true, metal_shelves=true, crate=true } },
            { item = "Base.ScrewsBox", count = {1,3}, chance = 0.8, nContainers = 2, rooms = { garagestorage=true, shed=true }, containers = { counter=true, metal_shelves=true, crate=true } },
            { item = "Base.Plank", count = {2,6}, chance = 0.7, nContainers = 2, rooms = { shed=true, garagestorage=true }, containers = { crate=true, other=true } },
            { item = "Base.Woodglue", count = {1,1}, chance = 0.5, nContainers = 1, rooms = { garagestorage=true }, containers = { metal_shelves=true } },
        },
    },
    commuter = {
        conditionProfile = { 0.6, 1.0 },
        package = {
            { item = "Base.Briefcase", count = {1,1}, chance = 0.5, nContainers = 2, rooms = { bedroom=true, closet=true, hall=true }, containers = { wardrobe=true, locker=true, other=true } },
            { item = "Base.VideoGame", count = {1,2}, chance = 0.4, nContainers = 2, rooms = { livingroom=true, bedroom=true }, containers = { shelves=true, sidetable=true, other=true } },
            { item = "Base.CDplayer", count = {1,1}, chance = 0.4, nContainers = 2, rooms = { livingroom=true, bedroom=true }, containers = { shelves=true, sidetable=true } },
            { item = "Base.Coffee2", count = {1,2}, chance = 0.6, nContainers = 2, rooms = { kitchen=true }, containers = { counter=true, overhead=true } },
        },
    },
    elderly = {
        conditionProfile = { 0.3, 0.75 },
        package = {
            { item = "Base.PillsVitamins", count = {1,3}, chance = 0.8, nContainers = 1, rooms = { bathroom=true, bedroom=true }, containers = { medicine=true, sidetable=true } },
            { item = "Base.PillsBeta", count = {1,2}, chance = 0.6, nContainers = 1, rooms = { bathroom=true, bedroom=true }, containers = { medicine=true, sidetable=true } },
            { item = "Base.SewingKit", count = {1,1}, chance = 0.6, nContainers = 2, rooms = { bedroom=true, closet=true }, containers = { dresser=true, wardrobe=true, other=true } },
            { item = "Base.Needle", count = {1,3}, chance = 0.5, nContainers = 2, rooms = { bedroom=true, closet=true }, containers = { dresser=true, other=true } },
            { item = "Base.PhotoAlbum", count = {1,2}, chance = 0.7, nContainers = 2, rooms = { bedroom=true, livingroom=true }, containers = { dresser=true, sidetable=true, other=true } },
        },
    },
    starter = {
        conditionProfile = { 0.3, 0.7 },
        -- Sparse everything — the honest archetype (§5.9). Its "signature" is
        -- mostly the disposition (evac_panicked) and a thin package.
        package = {
            { item = "Base.Paperback", count = {1,3}, chance = 0.5, nContainers = 2, rooms = { bedroom=true, livingroom=true }, containers = { sidetable=true, shelves=true } },
        },
    },
    mobile = {
        conditionProfile = { 0.35, 0.8 },
        package = {
            { item = "Base.PropaneTank", count = {1,1}, chance = 0.6, nContainers = 1, rooms = { storage=true, shed=true, garagestorage=true }, containers = { other=true, crate=true } },
            { item = "Base.Cooler", count = {1,1}, chance = 0.4, nContainers = 1, rooms = { storage=true, garagestorage=true }, containers = { other=true } },
        },
    },
    survivalist = {
        conditionProfile = { 0.5, 1.0 },
        -- Depth no one else has, found HALF-EMPTY by the sheltered_prepared
        -- lock (§5.13). The deplete filter spends the ammo; the family broke
        -- into the food stores. Package is generous; disposition guts it.
        package = {
            { item = "Base.WaterBottle", count = {2,6}, chance = 0.9, nContainers = 2, rooms = { storage=true, shed=true, garagestorage=true, closet=true }, containers = { crate=true, other=true, metal_shelves=true } },
            { item = "Base.Bag_AmmoBox", count = {1,4}, chance = 0.8, nContainers = 2, rooms = ROOMS_STORAGE, containers = CONT_STORAGE },
            { item = "Base.PetrolCan", count = {1,3}, chance = 0.7, nContainers = 2, rooms = { storage=true, shed=true, garagestorage=true }, containers = { other=true, crate=true } },
            { item = "Base.Candle", count = {2,6}, chance = 0.8, nContainers = 2, rooms = { storage=true, closet=true }, containers = { crate=true, other=true } },
            { item = "Base.Generator", count = {1,1}, chance = 0.25, nContainers = 1, rooms = { shed=true, garagestorage=true, storage=true }, containers = { other=true } },
            { item = "Base.Machete", count = {1,1}, chance = 0.5, nContainers = 2, rooms = ROOMS_STORAGE, containers = CONT_STORAGE, condition = {0.6,1.0} },
        },
    },
}

--== Approach-C guarantees (§3.1, §4.1) — the certainty layer ==================
-- Fires once per (building, roomType) on the trigger container. The rng
-- decides WHICH item, never WHETHER — this is what makes "a knife in every
-- kitchen" true without pool over-weighting (issue #2: pools supply variety,
-- guarantees supply presence). oneOf lists are all VERIFIED ids.
AH.B.Data.Guarantees = {
    kitchen = {
        trigger = "counter",
        sets = {
            { oneOf = { "Base.KitchenKnife", "Base.KnifeParing", "Base.BreadKnife" } }, -- a kitchen knife
            { oneOf = { "Base.Pan", "Base.Pot", "Base.Saucepan" } },                    -- a heat vessel
            { oneOf = { "Base.TinOpener", "Base.TinOpener_Old" } },                      -- a can opener
        },
    },
    bathroom = {
        trigger = "medicine",
        sets = {
            { oneOf = { "Base.Pills" } },     -- painkillers (doses = ledger E)
            { oneOf = { "Base.Bandaid", "Base.Bandage" } },
        },
    },
    laundry = {
        trigger = "counter",
        sets = {
            { oneOf = { "Base.Broom" } },
        },
    },
    garagestorage = {
        trigger = "counter",
        sets = {
            { oneOf = { "Base.Hammer" } },
            { oneOf = { "Base.Screwdriver", "Base.Screwdriver_Old" } },
        },
    },
}

--== Barter caches (§6.5) — rare additive flavor on sheltered dispositions ====
-- barterEligible dispositions (AHB01) may roll ONE of these per building.
AH.B.Data.BarterCaches = {
    trigger = "other",   -- an unremarkable container, deep in the house
    chance = 0.07,       -- ~5-8% of eligible (sheltered) houses
    hoards = {
        { name = "cigarettes", items = { { item = "Base.CigaretteCarton", count = {2,5} } } },
        { name = "liquor",     items = { { item = "Base.Whiskey", count = {3,8} } } },
        { name = "batteries",  items = { { item = "Base.Battery", count = {6,16} } } },
        { name = "coffee",     items = { { item = "Base.Coffee2", count = {4,10} } } },
    },
}
