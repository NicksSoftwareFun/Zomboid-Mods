--------------------------------------------------------------------------------
-- AH12_Setpieces.lua — applies AH03 (setpiece stocking) and AH04 (panic
-- layer) at merge time. Tech spec §2.1; design §10.
--
-- Setpiece doctrine (P6): full commercial stocking, NO per-building variance
-- — everything here is a uniform pool edit through AH10, so every instance
-- of a store type reads identically. Balance is access cost, never RNG.
--
-- The panic layer (§10.2) is the one exception: a uniform, lore-baked
-- reduction on food/gun/pharmacy/electronics RETAIL pools, written into the
-- pools themselves. SetpieceStocking sandbox option: 1=Panic (default,
-- factors applied) 2=Full (pre-outbreak inventories, factors skipped).
--
-- AH03 spec shape (AH.Data.Setpieces, list):
--   { pool="ToolStoreTools",
--     rolls=8,                       -- optional setRolls
--     scale=2.0,                     -- optional scalePool (stock depth)
--     ensure={ {item="Base.X", weight=10}, ... } }  -- optional upserts
-- AH04 shape (AH.Data.Panic, list):
--   { factor=0.3, pools={ "GigamartFood", ... },
--     note="grocery front-of-house 20-40% remaining" }
--------------------------------------------------------------------------------

AH = AH or {}

local function applySetpieces()
    if not AH.Options.enabled() then return end

    local specs = AH.Data.Setpieces or {}
    local edits, skipped = 0, 0
    for i = 1, #specs do
        local s = specs[i]
        local pool = AH.Distrib.getPool(s.pool)
        if not pool then
            skipped = skipped + 1 -- getPool warned already
        else
            if s.rolls then
                AH.Distrib.setRolls(s.pool, s.rolls); edits = edits + 1
            end
            if s.scale and s.scale ~= 1.0 then
                AH.Distrib.scalePool(s.pool, s.scale); edits = edits + 1
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
    AH.log(string.format("setpiece pass: %d edits, %d skipped", edits, skipped))

    -- Panic layer: skipped entirely on Full stocking (option respects P10 —
    -- the player asked for pre-outbreak stores, they get vanilla-or-richer).
    if AH.Options.setpieceStocking() ~= 1 then
        AH.log("panic layer: OFF (SetpieceStocking=Full)")
        return
    end
    local panic = AH.Data.Panic or {}
    local scaled = 0
    for i = 1, #panic do
        local p = panic[i]
        for j = 1, #p.pools do
            if AH.Distrib.scalePool(p.pools[j], p.factor) then
                scaled = scaled + 1
            end
        end
    end
    AH.log(string.format("panic layer: %d pools scaled", scaled))
end

if Events and Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(applySetpieces)
    AH.log("v" .. AH.VERSION .. " setpiece pass registered")
end
