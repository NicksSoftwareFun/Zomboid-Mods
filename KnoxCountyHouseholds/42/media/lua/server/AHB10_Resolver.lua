--------------------------------------------------------------------------------
-- AHB10_Resolver.lua — buildingKey -> {archetype, disposition, region}.
-- Tech spec §3.2/§3.4. Server context.
--
-- IDENTITY [PROBED]: coordinate key from BuildingDef bounds — getX/getY/
-- getX2/getY2 confirmed real map coordinates on B42.20. getID() is
-- DISQUALIFIED (sequential load-order counters); never use it here.
--
-- DETERMINISM: resolution is a pure function of (worldSeed, buildingKey).
-- The cache is a session-local memo ONLY — eviction never changes answers.
-- Never persist it; never ModData it (design §11).
--
-- WORLD SEED (tech spec open item 4): resolved by a defensive chain, first
-- hit wins, logged once:
--   1. SandboxVars.AmericanHousehold.WorldSeedString (server-set override;
--      lets an MP admin pin the seed explicitly)
--   2. getWorld():getRandomizedZoneSeed() — pcall probe; may not exist
--   3. getWorld():getWorld() — the save/world name string; stable per save
--   4. constant "AHB" + warn (assignments identical across saves — degraded
--      but functional; the warning is the work item)
-- All per-building math keys off AH.B.worldSeed() so the source is swappable.
--------------------------------------------------------------------------------

AH = AH or {}
AH.B = AH.B or {}

local cache = {}        -- buildingKey -> {arch=, disp=, region=, key=}
local cacheCount = 0

-- Coordinate key from a building's def. Returns nil (logged once) on any
-- failure — callers treat nil as "Mod A only" per the degrade policy.
function AH.B.keyOf(building)
    local ok, key = pcall(function()
        local def = building:getDef()
        return def:getX() .. ":" .. def:getY() .. ":"
            .. def:getX2() .. ":" .. def:getY2()
    end)
    if ok and key then return key end
    AH.warnOnce("keyOf", "building def bounds unavailable — building skipped")
    return nil
end

-- World-seed chain. Cached after first resolution; source logged once.
local seedString = nil
function AH.B.worldSeed()
    if seedString then return seedString end
    local candidates = {
        { "sandbox", function()
            local v = SandboxVars and SandboxVars.AmericanHousehold
                  and SandboxVars.AmericanHousehold.WorldSeedString
            if v and v ~= "" then return tostring(v) end
        end },
        { "randomizedZoneSeed", function()
            local w = getWorld()
            if w and w.getRandomizedZoneSeed then
                local v = w:getRandomizedZoneSeed()
                if v then return tostring(v) end
            end
        end },
        { "worldName", function()
            local w = getWorld()
            if w and w.getWorld then
                local v = w:getWorld()
                if v and v ~= "" then return tostring(v) end
            end
        end },
    }
    for i = 1, #candidates do
        local name, fn = candidates[i][1], candidates[i][2]
        local ok, v = pcall(fn)
        if ok and v then
            seedString = v
            AH.log("[AHB] world seed source: " .. name)
            return seedString
        end
    end
    seedString = "AHB"
    AH.warnOnce("seed",
        "[AHB] no world-seed source found — using constant (identical " ..
        "assignments across saves; open item 4 still needs an accessor)")
    return seedString
end

-- Region lookup: first rectangle containing (x,y) wins; else the default.
-- Rectangles are DATA (AHB00) — tune there, never here.
function AH.B.regionOf(x, y)
    local regions = AH.B.Data and AH.B.Data.Regions
    if not regions then return "outskirts" end
    for i = 1, #regions.list do
        local r = regions.list[i]
        if x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2 then
            return r.name
        end
    end
    return regions.default
end

-- The resolver. building -> {arch, disp, region, key} or nil.
function AH.B.resolve(building)
    local key = AH.B.keyOf(building)
    if not key then return nil end
    local hit = cache[key]
    if hit then return hit end

    -- region from the building's top-left corner
    local x = tonumber(string.match(key, "^(%-?%d+):")) or 0
    local y = tonumber(string.match(key, "^%-?%d+:(%-?%d+):")) or 0
    local region = AH.B.regionOf(x, y)

    local base = AH.B.worldSeed() .. "|" .. key
    local archWeights = AH.B.Data.ArchetypeWeights[region]
        or AH.B.Data.ArchetypeWeights[AH.B.Data.Regions.default]
    local arch = AH.B.pickWeighted(archWeights,
        AH.B.rng(AH.B.hash(base .. "|arch")))

    local row = AH.B.Data.Matrix[arch]
    if not row then
        AH.warnOnce("matrix:" .. tostring(arch),
            "[AHB] no disposition row for archetype " .. tostring(arch))
        row = AH.B.Data.Matrix.__default
    end
    local disp = AH.B.pickWeighted(row, AH.B.rng(AH.B.hash(base .. "|disp")))

    local result = { arch = arch, disp = disp, region = region, key = key }
    cache[key] = result
    cacheCount = cacheCount + 1
    return result
end

-- Pure-input variant for offline tests and AHB_audit: resolve from a raw
-- key + coordinates without a live building object.
function AH.B.resolveKey(key, x, y)
    local region = AH.B.regionOf(x, y)
    local base = AH.B.worldSeed() .. "|" .. key
    local archWeights = AH.B.Data.ArchetypeWeights[region]
        or AH.B.Data.ArchetypeWeights[AH.B.Data.Regions.default]
    local arch = AH.B.pickWeighted(archWeights,
        AH.B.rng(AH.B.hash(base .. "|arch")))
    local row = AH.B.Data.Matrix[arch] or AH.B.Data.Matrix.__default
    local disp = AH.B.pickWeighted(row, AH.B.rng(AH.B.hash(base .. "|disp")))
    return { arch = arch, disp = disp, region = region, key = key }
end

function AH.B.cacheStats()
    return cacheCount
end
