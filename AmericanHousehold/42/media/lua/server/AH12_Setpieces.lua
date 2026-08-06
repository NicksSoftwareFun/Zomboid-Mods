--------------------------------------------------------------------------------
-- AH12_Setpieces.lua — applies AH03 (stocking) + AH04 (panic layer) at merge
-- time. Tech spec §2.1; design §10. Setpiece doctrine (P6): uniform full
-- stocking, NO per-building variance — every instance of a store reads the
-- same. Balance is access cost, not RNG.
--
-- MECHANISM NOTE (load-bearing): within a single pool the game NORMALISES
-- weights, so multiplying every weight by k is a NO-OP for what spawns. The
-- real lever for "how much a container holds" is the pool's ROLL COUNT. So:
--   * stocking depth  -> raise rolls (rollsFactor > 1, or absolute rolls)
--   * panic reduction -> lower rolls (rollsFactor < 1), min 1
--   * changing the MIX (add a staple, emphasise an item) -> ensure{} sets one
--     item's weight RELATIVE to the rest (that is not a no-op).
-- Whole-pool scalePool is deliberately NOT used here.
--
-- AH03 entry (AH.Data.Setpieces list):
--   { pool="CarSupplyTools", rollsFactor=2.0 | rolls=8,
--     ensure={ {item="Base.X", weight=20}, ... } }
-- AH04 entry (AH.Data.Panic list):
--   { rollsFactor=0.3, pools={ "GigamartCannedFood", ... }, note="..." }
--------------------------------------------------------------------------------

AH = AH or {}

local function newRolls(cur, factor)
    local n = math.floor((cur or 1) * factor + 0.5)
    if n < 1 then n = 1 end
    return n
end

local function applySetpieces()
    if not AH.Options.enabled() then return end

    -- Stocking depth (AH03)
    local specs = AH.Data.Setpieces or {}
    local edits, skipped = 0, 0
    for i = 1, #specs do
        local s = specs[i]
        local cur = AH.Distrib.rolls(s.pool)   -- also validates the pool exists
        if not cur then
            skipped = skipped + 1
        else
            if s.rolls then
                AH.Distrib.setRolls(s.pool, s.rolls); edits = edits + 1
            elseif s.rollsFactor then
                AH.Distrib.setRolls(s.pool, newRolls(cur, s.rollsFactor)); edits = edits + 1
            end
            if s.ensure then
                for j = 1, #s.ensure do
                    local e = s.ensure[j]
                    if AH.Distrib.itemExists(e.item) then
                        AH.Distrib.setItemWeight(s.pool, e.item, e.weight)
                        edits = edits + 1
                    else
                        AH.warnOnce("sp-item:" .. e.item,
                            "unknown item id in setpiece spec: " .. e.item)
                        skipped = skipped + 1
                    end
                end
            end
        end
    end
    AH.FLog.boot()
    AH.log(string.format("setpiece pass: %d edits, %d skipped", edits, skipped))
    AH.FLog.line(string.format("[MERGE] setpiece pass: %d edits, %d skipped", edits, skipped))

    -- Panic layer (AH04). Skipped entirely on Full stocking (P10: player asked
    -- for pre-outbreak stores). Reduces ROLLS on front-of-house retail.
    if AH.Options.setpieceStocking() ~= 1 then
        AH.log("panic layer: OFF (SetpieceStocking=Full)")
        AH.FLog.line("[MERGE] panic layer: OFF (SetpieceStocking=Full)")
        return
    end
    local panic = AH.Data.Panic or {}
    local scaled = 0
    for i = 1, #panic do
        local p = panic[i]
        for j = 1, #p.pools do
            local cur = AH.Distrib.rolls(p.pools[j])
            if cur then
                AH.Distrib.setRolls(p.pools[j], newRolls(cur, p.rollsFactor))
                scaled = scaled + 1
            end
        end
    end
    AH.log(string.format("panic layer: %d pools reduced", scaled))
    AH.FLog.line(string.format("[MERGE] panic layer: %d pools reduced", scaled))
end

if Events and Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(applySetpieces)
    AH.log("v" .. AH.VERSION .. " setpiece pass registered")
end
