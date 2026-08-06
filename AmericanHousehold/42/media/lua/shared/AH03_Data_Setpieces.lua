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

--== Hardware store (§10.3) — the tool-store pools, commercial-only ===========
-- NOTE (correctness): the generic Crate* pools (CrateTools/Mechanics/Farming/
-- Lumber/SheetMetal/...) are DELIBERATELY NOT boosted here. They are SHARED
-- with residential garages/sheds/closets (verified in the Distributions
-- room->pool map), so raising their per-crate rolls would over-tool every
-- house and bypass the residential count model (issue #2 discipline). A
-- warehouse is deep because the map places MANY crate containers, not because
-- each crate is deeper — that depth is container-count (map data), not ours
-- to touch. So the industrial "jackpot" feel comes for free from the map; we
-- only boost pools that exist ONLY in commercial buildings.
for _, p in ipairs({
    "ToolStoreTools","ToolStoreCarpentry","ToolStoreMetalwork","ToolStoreAccessories",
    "ToolStoreHandles","ToolStoreMisc","ToolStorePaint","ToolStoreKeymaking",
    "ToolStoreBooks","BarnTools","FarmerTools","ToolCabinetMechanics",
}) do stock(p, 1.6) end

--== Farm supply (§10.3 gap — assembled from pieces, scheduled last) ==========
-- ToolCabinetFarming/ToolStoreFarming are farm-store pools; ProduceStorage* is
-- farm/grocery. CrateFarming excluded (shared with residential sheds).
for _, p in ipairs({
    "ToolCabinetFarming","ToolStoreFarming","ProduceStorageEquipment",
    "ProduceStorageLooseVeg","ProduceStorageLooseFruit",
}) do stock(p, 1.6) end

--== Schools (§10.6) — library knowledge, tool shop, gym, cafeteria ===========
-- The library skill-book pools are the knowledge jackpot. LibraryBooks is
-- already deep (80); a bump makes a school library worth the trip. SchoolLab
-- (first-aid/science), gym gear, and the school-shop toolset.
for _, p in ipairs({
    "LibraryBooks","LibraryMedical","LibraryOutdoors","LibraryScience",
    "CrateBooksSchool","SchoolLab","SchoolGymSportsGear","GigamartSchool",
}) do stock(p, 1.6) end

--== Fire stations (§10.6) — turnout gear, forcible-entry tools, first aid ====
for _, p in ipairs({
    "FireStorageTools","FireStorageOutfit","FireStorageMechanics",
    "FireDeptLockers","BinFireStation",
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
-- ONE entry (rolls + ensure together) so the roll factor is not compounded.
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
