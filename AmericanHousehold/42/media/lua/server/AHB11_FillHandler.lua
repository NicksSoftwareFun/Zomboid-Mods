--------------------------------------------------------------------------------
-- AHB11_FillHandler.lua — OnFillContainer entry point. Tech spec §3.5,
-- implemented step-for-step; the numbered comments ARE the contract.
--
-- FAILURE POLICY (design §11): degrade, never break. Every game-API touch is
-- pcall-guarded; on unexpected error, log once per error-site and return —
-- the container silently stays Mod A-only, which is a valid game.
--
-- IDEMPOTENCE: loot respawn re-fires this handler. Everything downstream is
-- a pure function of (worldSeed, buildingKey, roomType, containerType), so
-- re-running IS the design — never add a "have I run" flag (tech spec §4).
--------------------------------------------------------------------------------

AH = AH or {}
AH.B = AH.B or {}

AH.B.counters = { fills = 0, applied = 0, skippedNested = 0, skippedOutdoor = 0,
                  skippedPicker = 0, skippedNoChain = 0, skippedNonRes = 0 }

local function onFill(roomType, containerType, container)
    local C = AH.B.counters
    C.fills = C.fills + 1

    -- 1. master toggle
    if not AH.Options.archetypesEnabled() then return end
    if not AH.Options.enabled() then return end

    -- 2a. nested-bag fills arrive as literal roomType "Container" with a nil
    --     parent [PROBED: 357/357 of the probe's getParent failures]. The
    --     owning furniture gets its own fill event; skipping loses nothing.
    if roomType == "Container" then
        C.skippedNested = C.skippedNested + 1
        return
    end

    -- 2b. outdoor/zone containers (mailboxes, BBQs, dumpsters) pass "all"
    --     and have no room. Mod A-only by design [PROBED].
    if roomType == "all" then
        C.skippedOutdoor = C.skippedOutdoor + 1
        return
    end

    -- 2c. ItemPickerContainer guard [PROBED: 0 occurrences in 1,421 fills;
    --     kept because it costs three lines]
    local okCls, cls = pcall(function() return tostring(container) end)
    if okCls and cls and string.find(cls, "ItemPicker", 1, true) then
        C.skippedPicker = C.skippedPicker + 1
        return
    end

    -- 3. walk up: container -> parent object -> square -> room -> building.
    --    Any nil: roomless residual, Mod A-only BY DESIGN — return silently.
    local okWalk, building = pcall(function()
        local parent = container:getParent()
        if not parent then return nil end
        local square = parent:getSquare()
        if not square then return nil end
        local room = square:getRoom()
        if not room then return nil end
        return room:getBuilding()
    end)
    if not okWalk then
        AH.warnOnce("walkup", "[AHB] walk-up chain threw — containers degrade to Mod A")
        C.skippedNoChain = C.skippedNoChain + 1
        return
    end
    if not building then
        C.skippedNoChain = C.skippedNoChain + 1
        return
    end

    -- 5. residential whitelist BEFORE resolving (cheap check first; setpieces
    --    are Mod A's; ordering differs from the spec listing only in that it
    --    saves a resolve on commercial fills — same observable behavior).
    if not AH.B.Data.ResidentialRooms[roomType] then
        C.skippedNonRes = C.skippedNonRes + 1
        return
    end

    -- 4. resolve building identity -> (archetype, disposition, region)
    local r = AH.B.resolve(building)
    if not r then return end -- keyOf already warned

    -- 6. apply (AHB12): packages -> guarantees -> firearms -> filters -> condition
    local okApply, err = pcall(AH.B.apply, container, roomType, containerType, r)
    if not okApply then
        AH.warnOnce("apply:" .. tostring(roomType),
            "[AHB] apply failed in " .. tostring(roomType) .. ": " .. tostring(err))
        return
    end
    C.applied = C.applied + 1

    if AH.Options.verbose() then
        AH.log(string.format("[AHB] fill %s/%s -> %s/%s (%s)",
            tostring(roomType), tostring(containerType), r.arch, r.disp, r.region))
    end
end

if Events and Events.OnFillContainer then
    Events.OnFillContainer.Add(onFill)
    AH.log("[AHB] v" .. AH.VERSION .. " fill handler registered")
else
    AH.log("[AHB] FATAL-ish: OnFillContainer missing; Mod B inert (probe said it exists — investigate)")
end
