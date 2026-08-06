-- test_ledger.lua — run with: lua5.1 test_ledger.lua  (from mods/tests/)
-- Data-integrity for the §8 ledger charge profiles: every entry must be a
-- well-formed remaining-charge spec so the fill-time pass can't set an
-- out-of-range UsedDelta. The fill handler itself is game-facing (pcall-
-- guarded), but the DATA that drives it is checkable here.

AH = { Data = {} }
dofile("../AmericanHousehold/42/media/lua/shared/AH05_Data_Ledger.lua")

local fails = 0
local function check(label, cond)
    if cond then print("PASS " .. label)
    else fails = fails + 1; print("FAIL " .. label) end
end

local L = AH.Data.Ledger
check("ledger table present", type(L) == "table")
check("charge profiles present", type(L.charge) == "table")
check("foodScale present", type(L.foodScale) == "table")

-- every charge profile: lo/hi in [0,1], lo<=hi, deadChance in [0,1]
local okAll, count = true, 0
for id, p in pairs(L.charge) do
    count = count + 1
    if type(id) ~= "string" or id:sub(1, 5) ~= "Base." then okAll = false end
    if not (p.lo and p.hi and p.lo >= 0 and p.hi <= 1 and p.lo <= p.hi) then okAll = false end
    if p.deadChance and (p.deadChance < 0 or p.deadChance > 1) then okAll = false end
end
check("all charge profiles well-formed (" .. count .. ")", okAll and count > 0)

-- foodScale factors are non-negative multipliers
local okFood = true
for pool, f in pairs(L.foodScale) do
    if type(pool) ~= "string" or type(f) ~= "number" or f < 0 then okFood = false end
end
check("foodScale factors valid", okFood)

-- the design's ledger lines D/E/F must each have at least one profile
check("battery charge present (line D)", L.charge["Base.Battery"] ~= nil)
check("medicine charge present (line E)", L.charge["Base.Pills"] ~= nil)
check("fuel charge present (line F)",
    L.charge["Base.PetrolCan"] ~= nil or L.charge["Base.PropaneTank"] ~= nil)
-- battery must be able to spawn dead
check("battery can spawn dead", (L.charge["Base.Battery"].deadChance or 0) > 0)

-- setLedgerCharge must NEVER throw and must not call missing methods
-- (regression: a PetrolCan in a garage spammed console.txt with caught
-- pcall exceptions while driving). Load the pass with stubs; verify the
-- charge function is well-behaved on each item shape.
AH.B = AH.B or {}
AH.Options = { enabled = function() return true end,
               ledgerEnabled = function() return true end }
AH.log = function() end
AH.warnOnce = function() end
Events = nil  -- skip the OnFillContainer registration branch
dofile("../AmericanHousehold/42/media/lua/server/AHB14_Ledger.lua")

local setC = AH.B.setLedgerCharge
check("setLedgerCharge exposed", type(setC) == "function")

-- a drainable: has setUsedDelta -> gets called, returns true
local gotDelta = nil
local drainable = { setUsedDelta = function(self, v) gotDelta = v end }
local okDrain = select(1, pcall(setC, drainable, 0.4))
check("drainable: no throw", okDrain)
check("drainable: setUsedDelta called with frac", gotDelta == 0.4)
check("drainable: returns true", (function() gotDelta=nil; return setC(drainable, 0.5) end)())

-- a fluid item WITHOUT a capacity supplied -> must not charge (returns false,
-- no throw). Guards against emptying a can we can't size.
local noCapCalled = false
local fluidNoCap = { getFluidContainer = function(self)
    return { adjustAmount = function() noCapCalled = true end } end }
local okNC, resNC = pcall(setC, fluidNoCap, 0.3, nil)
check("fluid without capacity: no throw", okNC)
check("fluid without capacity: returns false", resNC == false)
check("fluid without capacity: adjustAmount not called", noCapCalled == false)

-- a fluid container missing adjustAmount -> no throw, no missing-method call
local badFluidCalled = false
local badFluid = { getFluidContainer = function(self)
    return { getAmount = function() badFluidCalled = true end } end }
local okBad, resBad = pcall(setC, badFluid, 0.3, 10)
check("missing adjustAmount: no throw", okBad)
check("missing adjustAmount: returns false", resBad == false)
check("missing adjustAmount: never called a missing method", badFluidCalled == false)

-- a plain item (no charge methods at all) -> no throw, false
local okPlain, resPlain = pcall(setC, {}, 0.2, nil)
check("plain item: no throw", okPlain)
check("plain item: returns false", resPlain == false)

-- a fluid container with adjustAmount + capacity -> absolute litre set,
-- and IDEMPOTENT (same input -> same absolute value, no compounding)
local setTo = nil
local goodFluid = { getFluidContainer = function(self)
    return { adjustAmount = function(_, a) setTo = a end } end }
local okGood = select(1, pcall(setC, goodFluid, 0.4, 10.0))
check("working fluid API: no throw", okGood)
check("working fluid API: adjustAmount = capacity*frac", setTo == 4)
setC(goodFluid, 0.4, 10.0)  -- run again
check("fluid charge idempotent (absolute, no compounding)", setTo == 4)

print(fails == 0 and "ALL TESTS PASSED" or (fails .. " FAILURES"))
os.exit(fails == 0 and 0 or 1)
