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
    -- true iff Mod B is enabled AND its guarantee data actually loaded
    -- (evaluated at merge time — all mods' shared files are loaded by then)
    local modBGuarantees = AH.B and AH.B.Data and AH.B.Data.Guarantees and true or false
    if modBGuarantees then
        AH.log("Mod B guarantees detected — approachC entries solve at T2")
    end

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

            -- exclude the item's own vanilla entry (if any) from W: the
            -- solver assumes the item is being ADDED to the pool.
            local W = AH.Distrib.totalWeight(e.pool, e.item)
            local R = AH.Distrib.rolls(e.pool)
            if not W or W <= 0 or not R then
                skipped = skipped + 1
                break -- getPool already warned
            end

            local tier = e.tier
            -- Approach C handshake: when Mod B is present its guarantee pass
            -- supplies the T0 certainty, so the pool entry drops to T2 —
            -- pools supply variety, the guarantee supplies presence, and the
            -- F3 duplicate expectation stays under control (design §3.1).
            if e.approachC and AH.B and modBGuarantees then
                tier = "T2"
            end
            local roomP = AH.Tiers.TARGET[tier]
            if not roomP then
                AH.warnOnce("tier:" .. tostring(tier), "unknown tier on " .. e.item)
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
