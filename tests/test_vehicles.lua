-- test_vehicles.lua — run with: lua5.1 test_vehicles.lua  (from mods/tests/)
-- AH13 against a fake VehicleZoneDistribution shaped like the real B42.20
-- VehicleZoneDefinition.lua, including the business2..12 alias trap and
-- zones that omit spawnRate (game default 16).

dofile("../AmericanHousehold/42/media/lua/shared/AH00_Options.lua")

local function zone(spawnRate)
    return { vehicles = { ["Base.CarNormal"] = { index = -1, spawnChance = 100 } },
             spawnRate = spawnRate, baseVehicleQuality = 0.7 }
end

VehicleZoneDistribution = {
    parkingstall = zone(nil),      -- omits spawnRate: implicit default 16
    good         = zone(8),
    luxuryDealership = zone(50),
    hot          = zone(80),       -- must cap at 100 under 1.5x
    business     = zone(nil),
    notAZone     = 42,             -- stray scalar must be skipped
    noVehicles   = { spawnRate = 16 }, -- no vehicles subtable: skip
}
-- the alias trap, verbatim pattern from the game file
for i = 2, 12 do
    VehicleZoneDistribution["business" .. i] = VehicleZoneDistribution.business
end

dofile("../AmericanHousehold/42/media/lua/server/AH13_Vehicles.lua")

local V = VehicleZoneDistribution
local fails = 0
local function check(label, cond)
    if cond then print("PASS " .. label)
    else fails = fails + 1; print("FAIL " .. label) end
end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-9) end

-- default multiplier is 1.5 (no SandboxVars in stock lua)
AH.Vehicles.apply()

check("implicit default scaled: 16*1.5", near(V.parkingstall.spawnRate, 24))
check("explicit low scaled: 8*1.5", near(V.good.spawnRate, 12))
check("explicit high scaled: 50*1.5", near(V.luxuryDealership.spawnRate, 75))
check("capped at 100: 80*1.5", near(V.hot.spawnRate, 100))
check("alias scaled ONCE: 16*1.5 not *1.5^12", near(V.business.spawnRate, 24))
check("alias shares the table", V.business12.spawnRate == V.business.spawnRate
    and V.business12 == V.business)
check("stray scalar untouched", V.notAZone == 42)
check("vehicles-less table untouched", near(V.noVehicles.spawnRate, 16))
check("spawnChance never scaled",
    V.parkingstall.vehicles["Base.CarNormal"].spawnChance == 100)
check("quality never scaled", near(V.parkingstall.baseVehicleQuality, 0.7))

-- 1.0 must be a true no-op: fresh table, multiplier forced to 1.0
SandboxVars = { AmericanHousehold = { VehicleMultiplier = 1.0 } }
VehicleZoneDistribution = { z = zone(nil) }
AH.Vehicles.apply()
check("1.0 is a no-op (field not even written)",
    VehicleZoneDistribution.z.spawnRate == nil)

-- idempotence note: re-running compounds BY DESIGN (merge fires once per
-- boot); guard here only documents that apply() is not self-inhibiting.
SandboxVars = { AmericanHousehold = { VehicleMultiplier = 2.0 } }
VehicleZoneDistribution = { z = zone(10) }
AH.Vehicles.apply()
check("2.0 multiplier", near(VehicleZoneDistribution.z.spawnRate, 20))

print(fails == 0 and "ALL TESTS PASSED" or (fails .. " FAILURES"))
os.exit(fails == 0 and 0 or 1)
