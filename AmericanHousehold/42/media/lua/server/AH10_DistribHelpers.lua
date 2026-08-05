--------------------------------------------------------------------------------
-- AH10_DistribHelpers.lua — the ONLY code that touches vanilla distribution
-- tables. Tech spec §2.2. Server context; runs at merge time.
--
-- UNVERIFIED-IN-GAME as of this commit: written against the B41-documented
-- pool entry shape (open item 2 in the tech spec):
--   pool = { rolls = <n>, items = { "Name", w, "Name", w, ... }, junk = {...} }
-- shapeOf() detects this and refuses to touch pools it doesn't recognize —
-- first in-game run will print any unrecognized shapes; fix shapeOf first
-- if that happens, nothing else.
--------------------------------------------------------------------------------

AH = AH or {}
AH.Distrib = {}

local changes = {}   -- audit log for logDiff()

local function pools()
    return ProceduralDistributions and ProceduralDistributions.list
end

-- Returns "flat" (B41-style alternating name/weight list) or nil.
local function shapeOf(pool)
    if type(pool) ~= "table" or type(pool.items) ~= "table" then return nil end
    local it = pool.items
    if #it == 0 then return "flat" end -- empty is fine, we can insert
    if type(it[1]) == "string" and type(it[2]) == "number" then return "flat" end
    return nil
end

function AH.Distrib.getPool(name)
    local list = pools()
    if not list then
        AH.warnOnce("nolist", "ProceduralDistributions.list missing at merge time")
        return nil
    end
    local pool = list[name]
    if not pool then
        AH.warnOnce("nopool:" .. name, "pool not found: " .. name)
        return nil
    end
    if not shapeOf(pool) then
        AH.warnOnce("shape:" .. name,
            "pool '" .. name .. "' has unrecognized shape — update shapeOf() (open item 2)")
        return nil
    end
    return pool
end

function AH.Distrib.rolls(name)
    local pool = AH.Distrib.getPool(name)
    return pool and (pool.rolls or 1) or nil
end

function AH.Distrib.totalWeight(name)
    local pool = AH.Distrib.getPool(name)
    if not pool then return nil end
    local total, it = 0, pool.items
    for i = 2, #it, 2 do total = total + it[i] end
    return total
end

-- Idempotent upsert: sets the item's weight, adding the entry if absent.
-- Mutates IN PLACE (P8: other mods' earlier edits must survive).
function AH.Distrib.setItemWeight(poolName, itemName, weight)
    local pool = AH.Distrib.getPool(poolName)
    if not pool then return false end
    local it = pool.items
    for i = 1, #it, 2 do
        if it[i] == itemName then
            changes[#changes + 1] = { poolName, itemName, it[i + 1], weight }
            it[i + 1] = weight
            return true
        end
    end
    it[#it + 1] = itemName
    it[#it + 1] = weight
    changes[#changes + 1] = { poolName, itemName, 0, weight }
    return true
end

function AH.Distrib.removeItem(poolName, itemName)
    local pool = AH.Distrib.getPool(poolName)
    if not pool then return false end
    local it = pool.items
    for i = 1, #it, 2 do
        if it[i] == itemName then
            changes[#changes + 1] = { poolName, itemName, it[i + 1], 0 }
            table.remove(it, i + 1)
            table.remove(it, i)
            return true
        end
    end
    return false
end

-- Multiply every weight in a pool (panic layer, §10.2).
function AH.Distrib.scalePool(poolName, factor)
    local pool = AH.Distrib.getPool(poolName)
    if not pool then return false end
    local it = pool.items
    for i = 2, #it, 2 do
        changes[#changes + 1] = { poolName, it[i - 1], it[i], it[i] * factor }
        it[i] = it[i] * factor
    end
    return true
end

function AH.Distrib.setRolls(poolName, n)
    local pool = AH.Distrib.getPool(poolName)
    if not pool then return false end
    changes[#changes + 1] = { poolName, "<rolls>", pool.rolls or 1, n }
    pool.rolls = n
    return true
end

-- Item existence check so bad IDs fail LOUDLY at merge, not silently at fill.
-- Accessor name unverified in B42 (tech spec open list) — pcall-guarded; if
-- unavailable we validate nothing and say so once.
function AH.Distrib.itemExists(fullName)
    local ok, item = pcall(function()
        return getScriptManager():FindItem(fullName)
    end)
    if not ok then
        AH.warnOnce("noFindItem",
            "getScriptManager():FindItem unavailable — item validation OFF")
        return true
    end
    return item ~= nil
end

-- The audit trail. Non-negotiable per tech spec §2.2: this is the
-- compatibility debugging story when other loot mods are installed.
function AH.Distrib.logDiff()
    AH.log("merge changes: " .. #changes)
    for i = 1, #changes do
        local c = changes[i]
        AH.log(string.format("  %s / %s : %.3f -> %.3f", c[1], c[2], c[3], c[4]))
    end
end
