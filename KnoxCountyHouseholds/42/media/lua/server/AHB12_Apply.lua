--------------------------------------------------------------------------------
-- AHB12_Apply.lua — package application + filter execution. Tech spec §3.6.
-- The order of the six steps is LOAD-BEARING; do not reorder.
--
-- Determinism: every roll keys off
--     base = worldSeed .. "|" .. buildingKey
-- with a purpose-tag plus, for per-container streams, the container's parent
-- SQUARE coordinates (sqx:sqy) — available at fill time, identical across
-- respawns/server/clients, and unique per physical container. This is what
-- lets two wardrobes in one house roll independently while each stays
-- stable across loot respawn (idempotence, tech spec §4).
--
-- DATA CONTRACTS consumed here (authored in AHB00/01/02):
--   AH.B.Data.Archetypes[arch].package = {
--     { item="Base.X", count={min,max}, chance=0.x,
--       rooms={kitchen=true,...}|nil, containers={counter=true,...}|nil,
--       nContainers=2,           -- est. eligible containers/building (chance
--                                -- is per BUILDING; solver converts, §3.1)
--       condition={0.4,0.9}|nil },  ...
--   }
--   AH.B.Data.Archetypes[arch].conditionProfile = {0.35, 0.95}
--   AH.B.Data.Guarantees[roomType] = { trigger="counter",
--     sets = { { name="knife", oneOf={"Base.KitchenKnife", ...} }, ... } }
--   AH.B.Data.Firearms.archetypeProfiles[arch] = {
--     chance=0.97, nContainers=2, rooms={...}, containers={...},
--     guns={ {item="Base.X", caliber="308", w=4}, ... },
--     gunCount={2,4}, ammoRounds={60,150} }
--   AH.B.Data.Firearms.ammoByCaliber["308"] = { box="Base.308Box", perBox=20 }
--   AH.B.Data.Dispositions[disp] = {
--     removeCategories = { gun=true, ammo=true, bag=true, med=true }|nil,
--     partialRemove    = { gun=0.5, ... }|nil,   -- fraction removed
--     deplete          = { food={0.8,1.0} }|nil, -- fraction removed, range
--     barterEligible   = true|nil }
--
-- Simplifications vs the design doc, on the record (tech spec §3.6 step 2
-- licenses the first):
--   * Guarantees fire on the room's designated trigger container without
--     sibling inspection — the rng picks WHICH knife, never whether.
--   * scatter (§6.1 evac-panicked) is NOT implemented in v1: sibling
--     containers fill in separate events, so cross-container relocation
--     cannot be done statelessly. Logged once at first use. The panicked
--     signature survives via partialRemove.
--   * Fridge notes (§6.6) are a stub hook — Phase 6 [new] items.
--------------------------------------------------------------------------------

AH = AH or {}
AH.B = AH.B or {}

local floor = math.floor

-- rng helper: uniform integer in [lo, hi]
local function rint(r, lo, hi)
    return lo + floor(r() * (hi - lo + 1))
end

-- Per-building chance converted to per-container chance over n estimated
-- eligible containers (same math as AH01's perContainerTarget).
local function perContainer(P, n)
    if not n or n <= 1 then return P end
    return 1 - (1 - P) ^ (1 / n)
end

-- Category predicates, pcall-guarded, cached per full type. Unknown -> "other".
local catCache = {}
local function categoryOf(item)
    local ft
    local okFt, v = pcall(function() return item:getFullType() end)
    if okFt then ft = v end
    if ft and catCache[ft] then return catCache[ft] end
    local cat = "other"
    local ok = pcall(function()
        if item.IsFood and item:IsFood() then cat = "food" return end
        if item.IsWeapon and item:IsWeapon() then
            local okR, ranged = pcall(function() return item:isRanged() end)
            cat = (okR and ranged) and "gun" or "tool"
            return
        end
        if item.IsInventoryContainer and item:IsInventoryContainer() then
            cat = "bag" return
        end
        local dc = item.getDisplayCategory and item:getDisplayCategory()
        if dc == "Ammo" then cat = "ammo" return end
        if dc == "FirstAid" then cat = "med" return end
        if dc == "Tool" then cat = "tool" return end
    end)
    if not ok then cat = "other" end
    if ft then catCache[ft] = cat end
    return cat
end

-- Insert `count` of fullType, optional condition fraction range applied.
local function insert(container, fullType, count, condRange, r)
    for _ = 1, count do
        local okAdd, item = pcall(function() return container:AddItem(fullType) end)
        if not okAdd or not item then
            AH.warnOnce("add:" .. fullType,
                "[AHB] AddItem failed for " .. fullType .. " — check the id")
            return false
        end
        if condRange then
            pcall(function()
                local cmax = item:getConditionMax()
                if cmax and cmax > 1 then
                    local frac = condRange[1] + r() * (condRange[2] - condRange[1])
                    item:setCondition(math.max(1, floor(cmax * frac)))
                end
            end)
        end
    end
    return true
end

-- Square coords for the per-container stream; nil-safe.
local function squareKey(container)
    local ok, key = pcall(function()
        local sq = container:getParent():getSquare()
        return sq:getX() .. ":" .. sq:getY() .. ":" .. sq:getZ()
    end)
    if ok and key then return key end
    return "0:0:0" -- degraded: still deterministic, just shared stream
end

-- == Step 1: archetype package ================================================
local function applyPackage(container, roomType, containerType, r, base, sqk)
    local arch = AH.B.Data.Archetypes[r.arch]
    if not arch or not arch.package then return end
    local rng = AH.B.rng(AH.B.hash(base .. "|pkg|" .. sqk))
    for i = 1, #arch.package do
        local e = arch.package[i]
        local roomOk = (not e.rooms) or e.rooms[roomType]
        local contOk = (not e.containers) or e.containers[containerType]
        if roomOk and contOk then
            local p = perContainer(e.chance or 1.0, e.nContainers)
            if rng() < p then
                local count = e.count and rint(rng, e.count[1], e.count[2]) or 1
                insert(container, e.item, count, e.condition, rng)
            else
                -- burn the draws the taken branch would have used, so entry
                -- N+1's outcome never depends on entry N's roll result
                rng()
            end
        end
    end
end

-- == Step 2: Approach C guarantees (T0 + junk drawer) =========================
local function applyGuarantees(container, roomType, containerType, r, base)
    local g = AH.B.Data.Guarantees[roomType]
    if not g or containerType ~= g.trigger then return end
    -- keyed by room type only: ONE guarantee pass per room per building
    -- (two kitchens = two passes; acceptable, F3 threshold is 3+)
    local rng = AH.B.rng(AH.B.hash(base .. "|guar|" .. roomType))
    for i = 1, #g.sets do
        local set = g.sets[i]
        local pick = set.oneOf[rint(rng, 1, #set.oneOf)]
        insert(container, pick, set.count or 1, set.condition, rng)
    end
end

-- == Step 3: firearm roll + caliber-matched ammo (§6.4) =======================
local function applyFirearms(container, roomType, containerType, r, base, sqk)
    local prof = AH.B.Data.Firearms.archetypeProfiles[r.arch]
    if not prof then return end
    if prof.rooms and not prof.rooms[roomType] then return end
    if prof.containers and not prof.containers[containerType] then return end

    local rng = AH.B.rng(AH.B.hash(base .. "|guns|" .. sqk))
    if rng() >= perContainer(prof.chance, prof.nContainers) then return end

    local nGuns = rint(rng, prof.gunCount[1], prof.gunCount[2])
    local calibers = {}
    for _ = 1, nGuns do
        local gun = AH.B.pickWeighted(prof.guns, rng)
        if gun then
            insert(container, gun.item, 1, prof.gunCondition or { 0.5, 0.95 }, rng)
            calibers[#calibers + 1] = gun.caliber
        end
    end
    -- ONE code path for ammo: caliber comes only from the guns just rolled
    -- (F7 guard). Rounds split evenly across the calibers present.
    if #calibers == 0 then return end
    local rounds = rint(rng, prof.ammoRounds[1], prof.ammoRounds[2])
    local per = floor(rounds / #calibers)
    for i = 1, #calibers do
        local a = AH.B.Data.Firearms.ammoByCaliber[calibers[i]]
        if a then
            local boxes = math.max(1, floor(per / a.perBox + 0.5))
            insert(container, a.box, boxes, nil, rng)
        else
            AH.warnOnce("ammo:" .. tostring(calibers[i]),
                "[AHB] no ammo mapping for caliber " .. tostring(calibers[i]))
        end
    end
end

-- == Step 4: disposition filter over FINAL contents ===========================
local function applyDisposition(container, roomType, containerType, r, base, sqk)
    local d = AH.B.Data.Dispositions[r.disp]
    if not d then return end
    if not (d.removeCategories or d.partialRemove or d.deplete) then return end

    local rng = AH.B.rng(AH.B.hash(base .. "|filter|" .. sqk))
    local toRemove = {}
    local ok = pcall(function()
        local items = container:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local cat = categoryOf(item)
            if d.removeCategories and d.removeCategories[cat] then
                toRemove[#toRemove + 1] = item
            elseif d.partialRemove and d.partialRemove[cat] then
                if rng() < d.partialRemove[cat] then toRemove[#toRemove + 1] = item end
            elseif d.deplete and d.deplete[cat] then
                local range = d.deplete[cat]
                local frac = range[1] + rng() * (range[2] - range[1])
                if rng() < frac then toRemove[#toRemove + 1] = item end
            end
        end
    end)
    if not ok then
        AH.warnOnce("filter", "[AHB] disposition scan failed — container left unfiltered")
        return
    end
    for i = 1, #toRemove do
        pcall(function() container:Remove(toRemove[i]) end)
    end
    if d.scatter then
        AH.warnOnce("scatter",
            "[AHB] scatter is a documented v1 simplification — items removed, not relocated")
    end
end

-- == Step 5: condition variance (design §1.3) =================================
local function applyCondition(container, r, base, sqk)
    local arch = AH.B.Data.Archetypes[r.arch]
    local prof = arch and arch.conditionProfile
    if not prof then return end
    local rng = AH.B.rng(AH.B.hash(base .. "|cond|" .. sqk))
    pcall(function()
        local items = container:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local cat = categoryOf(item)
            if cat == "tool" or cat == "gun" then
                local cmax = item:getConditionMax()
                if cmax and cmax > 1 then
                    local frac = prof[1] + rng() * (prof[2] - prof[1])
                    item:setCondition(math.max(1, floor(cmax * frac)))
                end
            end
        end
    end)
end

-- == Step 6: barter cache (§6.5) + fridge-note stub (§6.6) ====================
local function applyBarter(container, roomType, containerType, r, base)
    local d = AH.B.Data.Dispositions[r.disp]
    if not d or not d.barterEligible then return end
    local B = AH.B.Data.BarterCaches
    if not B or containerType ~= B.trigger then return end
    -- per-building stream: at most one cache per house, ~5-8% of sheltered
    local rng = AH.B.rng(AH.B.hash(base .. "|barter"))
    if rng() >= B.chance then return end
    local hoard = B.hoards[rint(rng, 1, #B.hoards)]
    for i = 1, #hoard.items do
        local e = hoard.items[i]
        insert(container, e.item, rint(rng, e.count[1], e.count[2]), nil, rng)
    end
    if AH.Options.verbose() then
        AH.log("[AHB] barter cache (" .. hoard.name .. ") in " .. r.key)
    end
end

function AH.B.fridgeNoteStub(container, r)
    -- Phase 6: one note style per disposition ([new] paper items). Hook kept
    -- so the disposition data can carry note ids without engine changes.
end

-- == The entry point ==========================================================
function AH.B.apply(container, roomType, containerType, r)
    local base = AH.B.worldSeed() .. "|" .. r.key
    local sqk = squareKey(container)
    applyPackage(container, roomType, containerType, r, base, sqk)
    applyGuarantees(container, roomType, containerType, r, base)
    applyFirearms(container, roomType, containerType, r, base, sqk)
    applyDisposition(container, roomType, containerType, r, base, sqk)
    applyCondition(container, r, base, sqk)
    applyBarter(container, roomType, containerType, r, base)
    AH.B.fridgeNoteStub(container, r)
end
