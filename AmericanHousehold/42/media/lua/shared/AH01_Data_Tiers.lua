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

--==============================================================================
-- COUNT MODEL (added to fix issue #2 — kitchen repetition/over-count).
--
-- The presence model above couples presence to expected COUNT through a
-- pool's roll count R: forcing 93.5% presence in a 4-roll pool puts ~2 of
-- the item in every container, and boosting several items makes our edits
-- dominate the pool so every room looks identical. Residential loot must
-- instead target a bounded expected COUNT and stay a MINORITY of each pool
-- so vanilla variety survives (design §1.1: "exactly one, where it goes" —
-- low variance, not high weight; §3.1: "naive weight increases multiply
-- counts").
--
-- True T0 certainty is Mod B's guarantee pass (Approach C), never pool
-- weight. Mod A pools only ever *raise the odds*, capped.
--==============================================================================

-- Target EXPECTED COUNT per room, per tier. Low by design — a household
-- owns ~1 of a fixture, not four. Presence falls out of the count and the
-- pool's roll count; we no longer target presence directly.
AH.Tiers.COUNT = {
    T0 = 1.00,   -- Fixture   — ~one per room (Mod B guarantee finishes to certainty)
    T1 = 0.60,   -- Common
    T2 = 0.30,   -- Occasional
    T3 = 0.12,   -- Uncommon
}

-- Dual caps that keep loot varied (issue #2):
--   * no single item may exceed this share of a pool's FINAL weight — bounds
--     per-container count at R * share, so 3+ of one item is near-impossible.
AH.Tiers.MAX_ITEM_SHARE = 0.12
--   * our TOTAL additions to a pool may never exceed this share of its final
--     weight — vanilla items keep the majority of rolls, so each room's draw
--     is mostly different vanilla loot and rooms stop looking identical.
AH.Tiers.MAX_POOL_ADD_SHARE = 0.35

-- Desired FINAL pool share for an item, from its target room count.
-- Expected room count = R * n * share, so share = mu / (R*n). Clamped to the
-- per-item cap. Returns share, clamped(boolean).
function AH.Tiers.shareForCount(mu, R, n)
    assert(mu and mu >= 0, "count target must be >= 0")
    assert(R and R >= 1, "pool rolls must be >= 1")
    assert(n and n >= 1, "container count must be >= 1")
    local s = mu / (R * n)
    if s > AH.Tiers.MAX_ITEM_SHARE then
        return AH.Tiers.MAX_ITEM_SHARE, true
    end
    return s, false
end

-- Pool planner — PURE and ORDER-INDEPENDENT. Solves all of a pool's items
-- together against the ORIGINAL pool total, enforcing both caps. This is the
-- one entry point AH11 uses; it exists here (not in the game-facing file) so
-- it is unit-testable.
--
-- Args:
--   items = { { key=id, mu=roomCount, n=nContainers }, ... }
--   Worig = original pool total weight (before our edits)
--   w0sum = summed ORIGINAL weight of the items we are about to overwrite
--           (their vanilla entries; subtracted so we replace, not add on top)
--   R     = pool roll count
-- Returns:
--   { key -> weight }  (the weight to set for each item)
--   info = { addShare=<final total added share>, scaled=<bool>, clampedItems={...} }
--
-- Math: with final pool Wf = (Worig - w0sum) + A where A = sum of our final
-- weights, and target shares s_i (of Wf), we get A = S*Wnm/(1-S) and
-- w_i = s_i * Wnm/(1-S), where Wnm = Worig - w0sum and S = sum s_i. If S
-- exceeds MAX_POOL_ADD_SHARE, every s_i is scaled down proportionally so the
-- pool-level cap holds exactly.
function AH.Tiers.planPool(items, Worig, w0sum, R)
    assert(Worig and Worig > 0, "pool weight must be positive")
    local Wnm = Worig - (w0sum or 0)
    if Wnm <= 0 then Wnm = Worig end   -- degenerate: our items were the whole pool

    local shares, clampedItems = {}, {}
    local S = 0
    for i = 1, #items do
        local it = items[i]
        local s, clamped = AH.Tiers.shareForCount(it.mu, R, it.n or 1)
        shares[i] = s
        S = S + s
        if clamped then clampedItems[#clampedItems + 1] = it.key end
    end

    local scaled = false
    if S > AH.Tiers.MAX_POOL_ADD_SHARE then
        local k = AH.Tiers.MAX_POOL_ADD_SHARE / S
        for i = 1, #shares do shares[i] = shares[i] * k end
        S = AH.Tiers.MAX_POOL_ADD_SHARE
        scaled = true
    end

    local denom = 1 - S
    if denom < 0.01 then denom = 0.01 end  -- guard; caps keep S<=0.35 anyway
    local weights = {}
    for i = 1, #items do
        weights[items[i].key] = shares[i] * Wnm / denom
    end
    return weights, { addShare = S, scaled = scaled, clampedItems = clampedItems }
end

-- Expected count of an item in one container drawing a pool, given its final
-- share and the pool's roll count. Diagnostic / test helper.
function AH.Tiers.expectedPerContainer(share, R)
    return R * share
end

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
