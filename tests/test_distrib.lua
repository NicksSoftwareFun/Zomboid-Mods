-- test_distrib.lua — run with: lua5.1 test_distrib.lua  (from mods/tests/)
-- AH10 helpers against a fake ProceduralDistributions shaped exactly like
-- the CONFIRMED B42.20 pool shape (flat pairs, short names, junk subtable,
-- stray scalar flags). Guards the Base.-prefix normalization: an upsert of
-- "Base.Pan" must hit vanilla's "Pan" entry, not add a duplicate.

dofile("../AmericanHousehold/42/media/lua/shared/AH00_Options.lua")

-- fake vanilla table, B42.20 shape (verbatim style from ProceduralDistributions.lua)
ProceduralDistributions = {
    list = {
        KitchenPots = {
            rolls = 4,
            ignoreZombieDensity = true, -- stray flags must be tolerated
            items = {
                "Pan", 10,
                "Pot", 8,
                "Base.LouisvilleMap1", 2, -- rare fully-qualified vanilla style
            },
            junk = { rolls = 1, items = { "DishCloth", 10 } },
        },
        WeirdPool = {
            rolls = 1,
            items = { { name = "Structured", weight = 1 } }, -- unknown shape
        },
    },
}

dofile("../AmericanHousehold/42/media/lua/server/AH10_DistribHelpers.lua")

local D = AH.Distrib
local pool = ProceduralDistributions.list.KitchenPots
local fails = 0
local function check(label, cond)
    if cond then print("PASS " .. label)
    else fails = fails + 1; print("FAIL " .. label) end
end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-9) end

-- shape acceptance
check("getPool accepts confirmed shape", D.getPool("KitchenPots") ~= nil)
check("getPool refuses unknown shape", D.getPool("WeirdPool") == nil)
check("getPool nil on missing pool", D.getPool("NoSuchPool") == nil)
check("rolls read", D.rolls("KitchenPots") == 4)

-- totalWeight, with and without self-exclusion
check("totalWeight", near(D.totalWeight("KitchenPots"), 20))
check("totalWeight excludes Base.Pan", near(D.totalWeight("KitchenPots", "Base.Pan"), 10))
check("totalWeight excludes short-name arg", near(D.totalWeight("KitchenPots", "Pot"), 12))
check("totalWeight excludes qualified vanilla entry",
    near(D.totalWeight("KitchenPots", "Base.LouisvilleMap1"), 18))

-- THE prefix bug: upsert "Base.Pan" must update "Pan" in place, not append
local n0 = #pool.items
check("upsert existing returns true", D.setItemWeight("KitchenPots", "Base.Pan", 25))
check("upsert did not grow the list", #pool.items == n0)
check("upsert updated vanilla entry", pool.items[1] == "Pan" and pool.items[2] == 25)

-- new item inserted under the short name
check("insert new returns true", D.setItemWeight("KitchenPots", "Base.GridlePan", 7))
check("insert grew the list by one pair", #pool.items == n0 + 2)
check("insert used short name", pool.items[n0 + 1] == "GridlePan" and pool.items[n0 + 2] == 7)

-- idempotence: repeating the upsert changes nothing structural
D.setItemWeight("KitchenPots", "Base.GridlePan", 7)
check("upsert idempotent", #pool.items == n0 + 2)

-- removeItem under either spelling
check("remove by full name", D.removeItem("KitchenPots", "Base.GridlePan"))
check("remove shrank the list", #pool.items == n0)
check("remove absent returns false", D.removeItem("KitchenPots", "Base.GridlePan") == false)

-- scalePool touches items only (junk untouched)
local potW = pool.items[4]
D.scalePool("KitchenPots", 2)
check("scalePool scaled", near(pool.items[4], potW * 2))
check("scalePool left junk alone", pool.junk.items[2] == 10)

-- setRolls
D.setRolls("KitchenPots", 6)
check("setRolls", pool.rolls == 6)

print(fails == 0 and "ALL TESTS PASSED" or (fails .. " FAILURES"))
os.exit(fails == 0 and 0 or 1)
