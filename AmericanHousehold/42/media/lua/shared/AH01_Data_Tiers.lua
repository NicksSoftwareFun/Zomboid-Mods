--------------------------------------------------------------------------------
-- AH01_Data_Tiers.lua — tier system and tier->weight math. PURE LUA:
-- no game API calls anywhere in this file. Unit-tested outside the game
-- (tests/test_tiers.lua). Tech spec §2.4; design doc §3.
--------------------------------------------------------------------------------

AH = AH or {}
AH.Tiers = {}

-- Per-room presence targets: midpoint of each design-doc band (§3).
AH.Tiers.TARGET = {
    T0 = 0.935,   -- Fixture   (90-100)  house-scoped; Approach C ideally
    T1 = 0.75,    -- Common    (60-90)
    T2 = 0.425,   -- Occasional(25-60)
    T3 = 0.165,   -- Uncommon  (8-25)
    -- T4: leave vanilla alone; no target, no edits.
}

-- Pool-competition ceiling (tech spec §2.4): no single item may take more
-- than this share of a pool's total weight after our edit.
AH.Tiers.MAX_POOL_SHARE = 0.60

-- Per-room presence for chance p across n independent containers.
function AH.Tiers.presence(p, n)
    return 1 - (1 - p) ^ n
end

-- Expected duplicate count.
function AH.Tiers.expectedCount(p, n)
    return p * n
end

-- Per-fill inclusion probability for weight w in pool of total weight W
-- drawing R rolls (with-replacement approximation, adequate at these sizes):
--   P(included) = 1 - (1 - w/W)^R
function AH.Tiers.inclusionProb(w, W, R)
    if W <= 0 or R <= 0 then return 0 end
    return 1 - (1 - w / W) ^ R
end

-- THE SOLVER. Given target presence P, the pool's CURRENT total weight W
-- (read from the live table at merge time, never hardcoded) and roll count R,
-- return the weight w to assign.
--
-- Derivation: we add w to the pool, so the pool total becomes W + w and
--   P = 1 - (1 - w/(W+w))^R  =>  (W/(W+w))^R = 1-P
--   =>  W+w = W * (1-P)^(-1/R)  =>  w = W * ((1-P)^(-1/R) - 1)
--
-- Returns: w, clamped (boolean — true if the pool-share ceiling bit).
-- A clamped result means this item cannot reach its tier via Approach A in
-- this pool: it needs Approach C (Mod B) or a less contested pool. Callers
-- must warn on clamp (F-condition material), not silently accept.
function AH.Tiers.solveWeight(P, W, R)
    assert(P and P > 0 and P < 1, "target presence must be in (0,1)")
    assert(W and W > 0, "pool weight must be positive (read the live pool)")
    assert(R and R >= 1, "roll count must be >= 1")

    local w = W * ((1 - P) ^ (-1 / R) - 1)

    -- ceiling: w/(W+w) <= MAX_POOL_SHARE  =>  w <= W*s/(1-s)
    local s = AH.Tiers.MAX_POOL_SHARE
    local wMax = W * s / (1 - s)
    if w > wMax then
        return wMax, true
    end
    return w, false
end

-- Convenience: achieved presence if we assign weight w into pool (W, R).
function AH.Tiers.achieved(w, W, R)
    return AH.Tiers.inclusionProb(w, W + w, R)
end

-- One pool often serves SEVERAL containers in a room (a kitchen's counters
-- all draw KitchenRandom). To hit room-level presence P across n such
-- containers, each individual container needs only:
--   p = 1 - (1-P)^(1/n)
-- Feed this p to solveWeight as the per-container target. Expected duplicate
-- count is then n*p — callers targeting one-per-room items should keep n*p
-- under ~1.3 or move the item to a narrower pool / Approach C (F3 guard).
function AH.Tiers.perContainerTarget(P, n)
    assert(n and n >= 1, "container count must be >= 1")
    return 1 - (1 - P) ^ (1 / n)
end
