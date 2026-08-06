--------------------------------------------------------------------------------
-- AHB14_Ledger.lua — the scarcity-ledger CHARGE pass (design §8 lines D/E/F).
-- Applies AH05's charge profiles to spawned drainables: batteries spawn
-- ~30% dead, fuel/propane partial, pill bottles part-used. This is the code
-- that was missing — AH05 had the numbers, nothing consumed them.
--
-- SCOPE (design §8): the ledger governs the RESIDENTIAL economy only —
-- "setpiece pools deliberately sit outside it" (F8 guards the seam). So this
-- runs on residential rooms and skips stores. Gated by LedgerEnabled, and
-- INDEPENDENT of ArchetypesEnabled (the ledger is a merge-/fill-time Mod A
-- concept; it works with the archetype layer off).
--
-- LOAD ORDER: AHB14 > AHB13, so this fires AFTER the archetype apply pass —
-- archetype-added drainables (survivalist propane, etc.) get charged too.
--
-- DETERMINISM/IDEMPOTENCE: charge is a pure function of (worldSeed, square,
-- item fullType, occurrence index). Loot respawn re-fires and reproduces the
-- same charge; no stored "already done" flag (design §4).
--
-- API [VERIFIED from scripts]: Battery/Pills/PropaneTank/LighterFluid are
-- base:drainable -> setUsedDelta(fraction remaining, 1=full/0=empty).
-- PetrolCan is base:normal with a fluid container -> getFluidContainer():
-- setAmount(capacity*frac). Both paths pcall-guarded; unknown -> no-op.
--------------------------------------------------------------------------------

AH = AH or {}
AH.B = AH.B or {}

local floor = math.floor

-- Set an item's remaining charge to `frac` (0..1). Returns true if applied.
--
-- MUST NOT THROW. PZ dumps *caught* pcall exceptions to console.txt with a
-- full stack trace, so error()-for-control-flow and calling a missing Java
-- method both spam the log — one pair per matching item, i.e. every gas can
-- in every garage you drive past. So this uses pure capability checks and
-- guards every method before calling it; a type it can't charge just returns
-- false, silently.
--
-- Drainable path (Battery/Pills/PropaneTank/LighterFluid) is confirmed
-- working in-game via setUsedDelta (fraction remaining; 1 = full).
--
-- Fluid-container path (PetrolCan is base:normal + a FluidContainer). B42's
-- FluidContainer exposes getAmount() and adjustAmount() — the latter is an
-- ABSOLUTE setter (verified from vanilla ISFluidEmptyAction:updateEmpty,
-- which sets targetFillAmount = startAmount*(1-progress) through it). There
-- is NO capacity getter in the accessible API, so we pass the capacity in
-- from data (the item script's declared Capacity) and set an absolute litre
-- target = capacity*frac. Absolute (not relative to current amount) makes it
-- IDEMPOTENT across loot respawn — re-running sets the same litres, no
-- compounding. `capacity` is nil for non-fluid items.
function AH.B.setLedgerCharge(item, frac, capacity)
    if item.setUsedDelta then
        item:setUsedDelta(frac)
        return true
    end
    if capacity and item.getFluidContainer then
        local fc = item:getFluidContainer()
        if fc and fc.adjustAmount then
            fc:adjustAmount(capacity * frac)
            return true
        end
    end
    return false
end
local setCharge = AH.B.setLedgerCharge

local function chargeContainer(roomType, container, seedBase)
    local profiles = AH.Data.Ledger and AH.Data.Ledger.charge
    if not profiles then return end
    local ok = pcall(function()
        local items = container:getItems()
        local counts = {}      -- fullType -> occurrence index (idempotent key)
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local ft = item:getFullType()
            local prof = profiles[ft]
            if prof then
                counts[ft] = (counts[ft] or 0) + 1
                local rng = AH.B.rng(AH.B.hash(
                    seedBase .. "|ledger|" .. ft .. "|" .. counts[ft]))
                local frac
                if prof.deadChance and rng() < prof.deadChance then
                    frac = 0.0
                else
                    frac = prof.lo + rng() * (prof.hi - prof.lo)
                end
                setCharge(item, frac, prof.capacity)
            end
        end
    end)
    if not ok then
        AH.warnOnce("ledger", "[AH] ledger charge scan failed on a container — skipped")
    end
end

local function onFillLedger(roomType, containerType, container)
    if not AH.Options.enabled() then return end
    if not AH.Options.ledgerEnabled() then return end
    -- residential only (§8): skip nested bags, outdoor, and all setpieces
    if roomType == "Container" or roomType == "all" then return end
    if not (AH.B.Data and AH.B.Data.ResidentialRooms
            and AH.B.Data.ResidentialRooms[roomType]) then return end

    -- deterministic seed from the container's square (stable across respawn)
    local seedBase = "L"
    pcall(function()
        local sq = container:getParent():getSquare()
        seedBase = AH.B.worldSeed() .. "|" ..
            sq:getX() .. ":" .. sq:getY() .. ":" .. sq:getZ()
    end)
    chargeContainer(roomType, container, seedBase)
end

if Events and Events.OnFillContainer then
    Events.OnFillContainer.Add(onFillLedger)
    AH.log("[AH] v" .. AH.VERSION .. " ledger charge pass registered")
end
