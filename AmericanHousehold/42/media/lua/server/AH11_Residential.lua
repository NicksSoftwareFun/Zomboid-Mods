--------------------------------------------------------------------------------
-- AH11_Residential.lua — applies AH02 at merge time. Tech spec §2.2.
--
-- COUNT MODEL (issue #2 fix). Entries are GROUPED BY POOL and solved together
-- through AH01's order-independent planPool, which targets a bounded expected
-- COUNT per tier and enforces two caps: per-item share (no 3-of-a-kind) and
-- per-pool total added share (our edits stay a minority so vanilla variety
-- survives and rooms stop looking identical). Reads live pool weight/rolls;
-- never hardcodes. True T0 certainty is Mod B's guarantee pass, not weight.
--------------------------------------------------------------------------------

AH = AH or {}

local function applyResidential()
    if not AH.Options.enabled() then
        AH.log("disabled via sandbox option; no changes")
        return
    end

    local abundance = AH.Options.abundanceFactor()
    -- true iff Mod B is enabled AND its guarantee data actually loaded
    -- (evaluated at merge time — all mods' shared files are loaded by then)
    local modBGuarantees = (AH.B and AH.B.Data and AH.B.Data.Guarantees) and true or false
    if modBGuarantees then
        AH.log("Mod B guarantees detected — approachC entries drop to minimal pool presence")
    end

    -- Pass 1: validate items, resolve per-item target COUNT, bucket by pool.
    local buckets = {}          -- poolName -> { entries = {{key,mu,n}}, order }
    local order = {}
    local skipped = 0
    for _, e in ipairs(AH.Data.Residential) do
        repeat
            if not AH.Distrib.itemExists(e.item) then
                AH.warnOnce("item:" .. e.item, "unknown item id " .. e.item)
                skipped = skipped + 1
                break
            end
            local mu = AH.Tiers.COUNT[e.tier]
            if not mu then
                AH.warnOnce("tier:" .. tostring(e.tier), "unknown tier on " .. e.item)
                skipped = skipped + 1
                break
            end
            -- Approach C handshake: when Mod B guarantees this item, the pool
            -- only needs to add flavor (minimal count) — the guarantee pass
            -- delivers the certainty, and keeping the pool contribution tiny
            -- is what prevents the issue-#2 duplication in the pool layer.
            if e.approachC and modBGuarantees then
                mu = AH.Tiers.COUNT.T3
            end
            -- abundance slider scales the count target (±20%), never presence.
            mu = mu * abundance

            local b = buckets[e.pool]
            if not b then
                b = { entries = {} }
                buckets[e.pool] = b
                order[#order + 1] = e.pool
            end
            b.entries[#b.entries + 1] = { key = e.item, mu = mu, n = e.nContainers or 1 }
        until true
    end

    -- Pass 2: solve each pool as a group and apply.
    local applied, clamps, scaledPools = 0, 0, 0
    for _, poolName in ipairs(order) do
        local entries = buckets[poolName].entries
        local R = AH.Distrib.rolls(poolName)
        local Worig = AH.Distrib.totalWeight(poolName)   -- live original total
        if R and Worig and Worig > 0 then
            -- summed vanilla weight of the entries we will overwrite
            local w0sum = 0
            for i = 1, #entries do
                w0sum = w0sum + (AH.Distrib.itemWeight(poolName, entries[i].key) or 0)
            end
            local weights, info = AH.Tiers.planPool(entries, Worig, w0sum, R)
            for i = 1, #entries do
                local key = entries[i].key
                AH.Distrib.setItemWeight(poolName, key, weights[key])
                applied = applied + 1
            end
            if info.scaled then
                scaledPools = scaledPools + 1
                AH.warnOnce("scaled:" .. poolName,
                    poolName .. " hit the pool add-share cap (" ..
                    string.format("%.0f%%", AH.Tiers.MAX_POOL_ADD_SHARE * 100) ..
                    ") — targets scaled down to preserve vanilla variety")
            end
            clamps = clamps + #info.clampedItems
        else
            skipped = skipped + #entries -- getPool/rolls already warned
        end
    end

    AH.log(string.format(
        "residential pass: %d applied, %d skipped, %d item-clamps, %d pools scaled",
        applied, skipped, clamps, scaledPools))
    if AH.Options.verbose() then AH.Distrib.logDiff() end
end

if Events and Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(applyResidential)
    AH.log("v" .. AH.VERSION .. " residential pass registered")
else
    AH.log("FATAL-ish: OnPreDistributionMerge missing; mod inert (probe said it exists — investigate)")
end
