--------------------------------------------------------------------------------
-- AH11_Residential.lua — applies AH02 at merge time. Tech spec §2.2.
-- Reads live pool weight/rolls (never hardcoded), solves per-container
-- targets, clamps at the pool-competition ceiling with a warning.
--------------------------------------------------------------------------------

AH = AH or {}

local function applyResidential()
    if not AH.Options.enabled() then
        AH.log("disabled via sandbox option; no changes")
        return
    end

    local abundance = AH.Options.abundanceFactor()
    local applied, skipped, clamps = 0, 0, 0

    for _, e in ipairs(AH.Data.Residential) do
        repeat
            if not AH.Distrib.itemExists(e.item) then
                AH.warnOnce("item:" .. e.item,
                    "unknown item id " .. e.item ..
                    (e.unverified and " (was flagged unverified — fix the ID in AH02)" or
                     " (was VERIFIED-marked; investigate)"))
                skipped = skipped + 1
                break
            end

            local W = AH.Distrib.totalWeight(e.pool)
            local R = AH.Distrib.rolls(e.pool)
            if not W or W <= 0 or not R then
                skipped = skipped + 1
                break -- getPool already warned
            end

            local roomP = AH.Tiers.TARGET[e.tier]
            if not roomP then
                AH.warnOnce("tier:" .. tostring(e.tier), "unknown tier on " .. e.item)
                skipped = skipped + 1
                break
            end
            -- abundance slider scales the presence target, capped sane
            roomP = math.min(0.985, roomP * abundance)

            local p = AH.Tiers.perContainerTarget(roomP, e.nContainers or 1)
            local w, clamped = AH.Tiers.solveWeight(p, W, R)
            if clamped then
                clamps = clamps + 1
                AH.warnOnce("clamp:" .. e.item,
                    e.item .. " clamped at pool-share ceiling in " .. e.pool ..
                    " — needs Approach C or a narrower pool (design §3.1)")
            end

            AH.Distrib.setItemWeight(e.pool, e.item, w)
            applied = applied + 1
        until true
    end

    AH.log(string.format("residential pass: %d applied, %d skipped, %d clamped",
        applied, skipped, clamps))
    if AH.Options.verbose() then AH.Distrib.logDiff() end
end

if Events and Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(applyResidential)
    AH.log("v" .. AH.VERSION .. " residential pass registered")
else
    AH.log("FATAL-ish: OnPreDistributionMerge missing; mod inert (probe said it exists — investigate)")
end
