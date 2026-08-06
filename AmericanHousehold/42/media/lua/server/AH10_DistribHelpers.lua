--------------------------------------------------------------------------------
-- AH10_DistribHelpers.lua — the ONLY code that touches vanilla distribution
-- tables. Tech spec §2.2. Server context; runs at merge time.
--
-- Pool shape CONFIRMED against B42.20 ProceduralDistributions.lua (open
-- item 2 resolved, Aug 2026):
--   pool = { rolls = <n>, items = { "Name", w, "Name", w, ... },
--            junk = { rolls = <n>, items = {...} }, <extra flags ok> }
-- Same flat pair list as B41; pools may carry extra scalar fields
-- (e.g. ignoreZombieDensity) which we ignore. We never touch `junk`.
--
-- NAMING: vanilla entries are SHORT names ("Pan") with module Base implied;
-- fully-qualified names ("Base.LouisvilleMap1") appear only rarely. All AH
-- data uses full "Base.X" ids (needed for FindItem validation), so the
-- helpers normalize: match either form, insert the short form. Without this,
-- setItemWeight("KitchenPots","Base.Pan",w) would ADD a duplicate entry
-- alongside vanilla's "Pan" instead of updating it.
--------------------------------------------------------------------------------

AH = AH or {}
AH.Distrib = {}

local changes = {}   -- audit log for logDiff()

local function pools()
    return ProceduralDistributions and ProceduralDistributions.list
end

-- "Base.Pan" -> "Pan"; other modules and already-short names pass through.
local function shortName(itemName)
    return (itemName:gsub("^Base%.", ""))
end

-- True if pool entry `entry` refers to `itemName` under either spelling.
local function sameItem(entry, itemName)
    return entry == itemName or entry == shortName(itemName)
        or shortName(entry) == shortName(itemName)
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

-- Total pool weight. `excludeItem` (optional): skip that item's own entry —
-- the AH01 solver derives w assuming the item is NOT yet in the pool
-- (total becomes W+w), so when upserting an item vanilla already stocks
-- (Pan is already in KitchenPots at 10) its old weight must not count
-- toward W or the solve comes out low.
function AH.Distrib.totalWeight(name, excludeItem)
    local pool = AH.Distrib.getPool(name)
    if not pool then return nil end
    local total, it = 0, pool.items
    for i = 2, #it, 2 do
        if not (excludeItem and sameItem(it[i - 1], excludeItem)) then
            total = total + it[i]
        end
    end
    return total
end

-- Current weight of an item in a pool (either name spelling), or nil if
-- the item is not present. Used by the residential planner to subtract the
-- vanilla weight it is about to overwrite.
function AH.Distrib.itemWeight(poolName, itemName)
    local pool = AH.Distrib.getPool(poolName)
    if not pool then return nil end
    local it = pool.items
    for i = 1, #it, 2 do
        if sameItem(it[i], itemName) then return it[i + 1] end
    end
    return nil
end

-- Idempotent upsert: sets the item's weight, adding the entry if absent.
-- Mutates IN PLACE (P8: other mods' earlier edits must survive). Matches
-- vanilla's short-name entries; inserts short form for consistency.
function AH.Distrib.setItemWeight(poolName, itemName, weight)
    local pool = AH.Distrib.getPool(poolName)
    if not pool then return false end
    local it = pool.items
    for i = 1, #it, 2 do
        if sameItem(it[i], itemName) then
            changes[#changes + 1] = { poolName, it[i], it[i + 1], weight }
            it[i + 1] = weight
            return true
        end
    end
    local short = shortName(itemName)
    it[#it + 1] = short
    it[#it + 1] = weight
    changes[#changes + 1] = { poolName, short, 0, weight }
    return true
end

function AH.Distrib.removeItem(poolName, itemName)
    local pool = AH.Distrib.getPool(poolName)
    if not pool then return false end
    local it = pool.items
    for i = 1, #it, 2 do
        if sameItem(it[i], itemName) then
            changes[#changes + 1] = { poolName, it[i], it[i + 1], 0 }
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
