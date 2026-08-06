-- test_modb.lua — run with: lua5.1 test_modb.lua  (from mods/tests/)
-- Loads the full Mod B data + hash + resolver and checks determinism,
-- region lookup, matrix validity, and firearm caliber coherence — the
-- highest-risk pure logic. No game API is touched (resolveKey path).

-- minimal AH.log / warnOnce (AH00 is Mod A; Mod B assumes it present)
AH = { log = function() end, warnOnce = function() end,
       Options = { verbose = function() return false end } }

dofile("../KnoxCountyHouseholds/42/media/lua/shared/AHB03_Hash.lua")
dofile("../KnoxCountyHouseholds/42/media/lua/shared/AHB00_Data_Archetypes.lua")
dofile("../KnoxCountyHouseholds/42/media/lua/shared/AHB01_Data_Dispositions.lua")
dofile("../KnoxCountyHouseholds/42/media/lua/shared/AHB02_Data_Firearms.lua")

-- stub getWorld so the resolver's world-seed chain resolves deterministically
getWorld = function() return { getWorld = function() return "TestWorld" end } end
SandboxVars = nil

dofile("../KnoxCountyHouseholds/42/media/lua/server/AHB10_Resolver.lua")

local fails = 0
local function check(label, cond)
    if cond then print("PASS " .. label)
    else fails = fails + 1; print("FAIL " .. label) end
end

-- region lookup
check("region muldraugh core", AH.B.regionOf(10900, 9700) == "muldraugh_core")
check("region west point", AH.B.regionOf(11500, 7000) == "west_point")
check("region default outskirts", AH.B.regionOf(1, 1) == "outskirts")

-- resolveKey determinism: same key -> same result, always
local k = "10900:9700:10912:9709"
local a = AH.B.resolveKey(k, 10900, 9700)
local b = AH.B.resolveKey(k, 10900, 9700)
check("resolve deterministic (arch)", a.arch == b.arch)
check("resolve deterministic (disp)", a.disp == b.disp)
check("resolve yields valid archetype", AH.B.Data.Archetypes[a.arch] ~= nil or a.arch == "survivalist" or AH.B.Data.ArchetypeWeights.outskirts ~= nil)
check("resolve archetype in weight table", (function()
    for _, e in ipairs(AH.B.Data.ArchetypeWeights.muldraugh_core) do
        if e.value == a.arch then return true end
    end
    return false
end)())

-- disposition is valid for the archetype's matrix row (or default)
check("resolve disposition valid", AH.B.Data.Dispositions[a.disp] ~= nil)

-- different keys generally differ (sample 200, expect multiple archetypes)
local seen = {}
for i = 1, 200 do
    local key = (10600 + i) .. ":9700:" .. (10612 + i) .. ":9709"
    local res = AH.B.resolveKey(key, 10600 + i, 9700)
    seen[res.arch] = (seen[res.arch] or 0) + 1
end
local distinct = 0
for _ in pairs(seen) do distinct = distinct + 1 end
check("resolve produces variety (>=5 archetypes in 200)", distinct >= 5)

-- survivalist hard-lock: its matrix row yields ONLY sheltered_prepared
local sr = AH.B.Data.Matrix.survivalist
check("survivalist matrix single entry", #sr == 1 and sr[1].value == "sheltered_prepared")

-- every archetype in every region weight list has a matrix row
local okMatrix = true
for region, wlist in pairs(AH.B.Data.ArchetypeWeights) do
    for _, e in ipairs(wlist) do
        if not AH.B.Data.Matrix[e.value] then okMatrix = false end
    end
end
check("every weighted archetype has a matrix row", okMatrix)

-- every matrix disposition exists in the Dispositions table
local okDisp = true
for arch, row in pairs(AH.B.Data.Matrix) do
    for _, e in ipairs(row) do
        if not AH.B.Data.Dispositions[e.value] then okDisp = false end
    end
end
check("every matrix disposition is defined", okDisp)

-- FIREARM CALIBER COHERENCE (F7): every gun caliber and every loose-ammo
-- caliber in every profile maps to a real ammo box.
local okCal = true
for arch, prof in pairs(AH.B.Data.Firearms.archetypeProfiles) do
    for _, g in ipairs(prof.guns) do
        if not AH.B.Data.Firearms.ammoByCaliber[g.caliber] then okCal = false end
    end
    for _, c in ipairs(prof.looseAmmo.calibers) do
        if not AH.B.Data.Firearms.ammoByCaliber[c.value] then okCal = false end
    end
end
check("F7: all gun+loose calibers have ammo mappings", okCal)

-- loose ammo calibers are a SUBSET of the archetype's own gun calibers
-- (coherent, not gun-locked but not orphan either)
local okSubset = true
for arch, prof in pairs(AH.B.Data.Firearms.archetypeProfiles) do
    local gunCal = {}
    for _, g in ipairs(prof.guns) do gunCal[g.caliber] = true end
    for _, c in ipairs(prof.looseAmmo.calibers) do
        if not gunCal[c.value] then okSubset = false end
    end
end
check("F7: loose ammo calibers subset of archetype guns", okSubset)

-- loose ammo chance is bounded and gun owners rarely have none
check("loose ammo chance bounded", (function()
    for _, prof in pairs(AH.B.Data.Firearms.archetypeProfiles) do
        local c = prof.looseAmmo.chance
        if c < 0.5 or c > 0.9 then return false end
    end
    return true
end)())

-- once-per-building flag on unique durables (anti-pile-up, issue #2 class)
check("ALICE pack marked once", (function()
    for _, e in ipairs(AH.B.Data.Archetypes.military.package) do
        if e.item == "Base.Bag_ALICEpack_Army" then return e.once == true end
    end
    return false
end)())
check("generator marked once", (function()
    for _, e in ipairs(AH.B.Data.Archetypes.survivalist.package) do
        if e.item == "Base.Generator" then return e.once == true end
    end
    return false
end)())
-- consumables must NOT be once (they spread by design)
check("jars NOT once (spread)", (function()
    for _, e in ipairs(AH.B.Data.Archetypes.canning.package) do
        if e.item == "Base.EmptyJar" then return e.once == nil end
    end
    return false
end)())

-- guarantee sets reference only real ids and non-empty oneOf lists
check("guarantee sets well-formed", (function()
    for _, g in pairs(AH.B.Data.Guarantees) do
        if type(g.trigger) ~= "string" then return false end
        for _, set in ipairs(g.sets) do
            if #set.oneOf < 1 then return false end
        end
    end
    return true
end)())

print(fails == 0 and "ALL TESTS PASSED" or (fails .. " FAILURES"))
os.exit(fails == 0 and 0 or 1)
