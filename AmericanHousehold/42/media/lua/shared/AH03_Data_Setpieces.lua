--------------------------------------------------------------------------------
-- AH03_Data_Setpieces.lua — §10 setpiece STOCKING. PURE DATA.
-- Pool names verified against reference/b42.20_pool_stats.tsv. rollsFactor
-- raises a pool's roll count so a resource-pool setpiece reads as a warehouse
-- of its own category (design §10.1: "dozens of each"). No disposition logic,
-- no per-building variance (P6). ensure{} adds/emphasises specific staples
-- (relative weight — not a no-op, unlike whole-pool scaling).
--
-- These pools are the FULL-STOCK world: auto parts, hardware, tools, farm,
-- surplus, police, industrial, medical storage. Panic-stripped RETAIL is the
-- separate AH04 layer. Everything here is the "worth the trip" reward economy
-- (design §1.6), priced by access cost (distance/density/logistics), not RNG.
--------------------------------------------------------------------------------

AH = AH or {}
AH.Data = AH.Data or {}

local S = {}
local function stock(pool, factor) S[#S + 1] = { pool = pool, rollsFactor = factor } end

--== Auto parts store (§10.3, the archetypal deep setpiece) ====================
-- Dozens of each: the Car* families each have only ~4 items and rolls 4;
-- doubling rolls makes a parts aisle feel like a parts aisle.
for _, p in ipairs({
    "CarBrakesModern1","CarBrakesModern2","CarBrakesModern3",
    "CarBrakesNormal1","CarBrakesNormal2","CarBrakesNormal3",
    "CarMufflerModern1","CarMufflerModern2","CarMufflerModern3",
    "CarMufflerNormal1","CarMufflerNormal2","CarMufflerNormal3",
    "CarSuspensionModern1","CarSuspensionModern2","CarSuspensionModern3",
    "CarSuspensionNormal1","CarSuspensionNormal2","CarSuspensionNormal3",
    "CarTiresModern1","CarTiresModern2","CarTiresModern3",
    "CarTiresNormal1","CarTiresNormal2","CarTiresNormal3",
    "CarSupplyBatteries","CarSupplyGasCans","CarSupplyTools",
    "CarSupplyLiterature","CarSupplyMagazines","CarSupplyGloves",
}) do stock(p, 2.0) end

--== Mechanic shop (§10.3, distinct from retail) ==============================
for _, p in ipairs({
    "MechanicShelfBrakes","MechanicShelfElectric","MechanicShelfMisc",
    "MechanicShelfMufflers","MechanicShelfSuspension","MechanicShelfTools",
    "MechanicShelfWheels","MechanicShelfBooks","MechanicShelfOutfit",
}) do stock(p, 1.8) end

--== Hardware / industrial bulk (§10.3, §10.5) ================================
-- The base-building endgame pools. Already dense (Crate* 75-120 items) — a
-- modest roll bump makes them jackpots without runaway counts.
for _, p in ipairs({
    "CrateMechanics","CrateTools","CrateFarming","CrateLumber","CrateSheetMetal",
    "CrateMetalBars","CratePropane","CrateFertilizer","CrateAnimalFeed",
    "ToolStoreTools","ToolStoreBooks","BarnTools","FarmerTools",
}) do stock(p, 1.6) end

--== Farm supply (§10.3 gap — assembled from pieces, scheduled last) ==========
for _, p in ipairs({
    "ToolCabinetFarming","ProduceStorageEquipment","ProduceStorageLooseVeg",
    "ProduceStorageLooseFruit",
}) do stock(p, 1.6) end

--== Gun retail deep stock (§10.4 — the panic layer AH04 strips the front) ====
-- Here we only DEEPEN the categories panic buyers passed over (accessories,
-- literature, knives, body armor). Guns/ammo depth is handled by leaving
-- vanilla + the panic reduction; over-stocking guns would break F8/balance.
for _, p in ipairs({
    "GunStoreAccessories","GunStoreLiterature","GunStoreKnives",
    "GunStoreMagazineRack","GunStoreBodyArmor",
}) do stock(p, 1.5) end

--== Police armory (§10.4 — NOT panic-stripped; manned through the Event) =====
for _, p in ipairs({
    "PoliceStorageGuns","PoliceStorageAmmunition","PoliceStorageArmor",
    "PoliceStorageMechanics","PoliceEvidence",
}) do stock(p, 1.5) end

--== Military surplus (§10.4 — gear, no weapons) ==============================
for _, p in ipairs({
    "ArmySurplusBackpacks","ArmySurplusFootwear","ArmySurplusOutfit",
    "ArmySurplusHeadwear","ArmySurplusTools","ArmySurplusMisc",
    "ArmySurplusLiterature","ArmySurplusCots","ArmySurplusWater",
    "ArmySurplusSnacks","ArmySurplusCases","ArmySurplusAmmoBoxes",
}) do stock(p, 1.6) end

--== Medical storage (§10.6 — the deep pool, priced by hospital density) ======
for _, p in ipairs({
    "MedicalStorageDrugs","MedicalStorageTools","MedicalStorageOutfit",
    "MedicalClinicTools","HospitalRoomShelves",
}) do stock(p, 1.6) end

--== Church relief hub (§10.6 — the most Kentucky setpiece) ====================
-- ChurchStorageMisc is thin (6 items). The concurrent Great Flood (§5.14)
-- made churches the relief infrastructure: the congregation BROUGHT things.
-- Full resource-pool treatment, NO panic reduction — extend + deepen.
stock("ChurchStorageMisc", 2.5)
S[#S + 1] = { pool = "ChurchStorageMisc", rollsFactor = 2.5, ensure = {
    { item = "Base.TinnedSoup",  weight = 30 },
    { item = "Base.TinnedBeans", weight = 30 },
    { item = "Base.CannedChili", weight = 20 },
    { item = "Base.CannedCorn",  weight = 20 },
    { item = "Base.Sheet",       weight = 16 }, -- blankets/bedding (no Blanket item)
    { item = "Base.Pillow",      weight = 10 },
    { item = "Base.WaterBottle", weight = 20 },
    { item = "Base.Bandage",     weight = 12 },
    { item = "Base.FirstAidKit", weight = 6 },
    { item = "Base.BathTowel",   weight = 12 },
} }

AH.Data.Setpieces = S
