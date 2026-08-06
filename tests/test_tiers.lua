-- test_tiers.lua — run with: lua5.1 test_tiers.lua  (from mods/tests/)
dofile("../AmericanHousehold/42/media/lua/shared/AH01_Data_Tiers.lua")

local T = AH.Tiers
local fails = 0
local function check(label, cond)
    if cond then print("PASS " .. label)
    else fails = fails + 1; print("FAIL " .. label) end
end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-9) end

-- presence math: the design doc §1.1 worked example — 5% over 6 containers ≈ 26%
check("presence(0.05,6) ~= 0.2649", near(T.presence(0.05, 6), 1 - 0.95^6))
check("presence doc value ~26%", T.presence(0.05, 6) > 0.26 and T.presence(0.05, 6) < 0.27)
check("expectedCount", near(T.expectedCount(0.39, 6), 2.34, 1e-6))

-- solver round-trip: solved weight must achieve the target presence
for _, tier in ipairs({"T0", "T1", "T2", "T3"}) do
    local P = T.TARGET[tier]
    local W, R = 120, 4
    local w, clamped = T.solveWeight(P, W, R)
    if not clamped then
        local got = T.achieved(w, W, R)
        check("round-trip " .. tier .. " (P=" .. P .. ")", near(got, P, 1e-9))
    else
        -- clamp is legitimate for T0 in small pools; verify the clamp honors the ceiling
        check("clamp share " .. tier, w / (W + w) <= T.MAX_POOL_SHARE + 1e-9)
    end
end

-- ceiling behavior: T0 in a single-roll pool MUST clamp (0.935 > 0.60 share cap)
local w, clamped = T.solveWeight(0.935, 100, 1)
check("T0 R=1 clamps", clamped == true)
check("clamped share == ceiling", near(w / (100 + w), T.MAX_POOL_SHARE, 1e-9))

-- T0 in a 4-roll pool: (1-P)^(1/R) route should NOT clamp
local w2, c2 = T.solveWeight(0.935, 100, 4)
check("T0 R=4 no clamp", c2 == false)
check("T0 R=4 achieves", near(T.achieved(w2, 100, 4), 0.935, 1e-9))

-- monotonicity: higher tier target => higher weight, same pool
local wT1 = T.solveWeight(T.TARGET.T1, 100, 3)
local wT2 = T.solveWeight(T.TARGET.T2, 100, 3)
local wT3 = T.solveWeight(T.TARGET.T3, 100, 3)
check("monotone T1>T2>T3", wT1 > wT2 and wT2 > wT3)

-- guard rails
check("bad P asserts", not pcall(T.solveWeight, 1.0, 100, 3))
check("bad W asserts", not pcall(T.solveWeight, 0.5, 0, 3))

-- perContainerTarget: room presence must reassemble from the per-container p
local P, n = 0.935, 3
local p = T.perContainerTarget(P, n)
check("perContainer round-trip", near(T.presence(p, n), P, 1e-9))
check("perContainer n=1 identity", near(T.perContainerTarget(0.75, 1), 0.75, 1e-9))
-- T0 across 3 containers: p≈0.596, dup expectation ≈1.79 — documents the F3 tension
check("T0/3-container dup expectation", near(T.expectedCount(p, n), n * p, 1e-9))

--==============================================================================
-- COUNT MODEL + planner (issue #2 fix)
--==============================================================================

-- shareForCount: expected count = R*n*share, so share = mu/(R*n) capped
local s, cl = T.shareForCount(1.0, 4, 1)
check("shareForCount basic", near(s, 0.12) and cl == true) -- 0.25 clamped to 0.12
local s2, cl2 = T.shareForCount(0.6, 4, 2)
check("shareForCount unclamped", near(s2, 0.075) and cl2 == false)
check("shareForCount count identity", near(T.expectedPerContainer(s2, 4) * 2, 0.6))

-- planPool: THE issue-#2 regression. Reproduce KitchenPots: Worig~183.5,
-- R=4, six boosted items. Assert (a) no item exceeds MAX_ITEM_SHARE of the
-- final pool, (b) our total add stays <= MAX_POOL_ADD_SHARE, (c) per-
-- container expected count of the worst item is well under 1 (was ~2 in the
-- bug), so 3-4 of one item is near-impossible.
local Worig, R = 183.5, 4
local items = {
    { key = "Base.Pan",  mu = 1.0, n = 2 },
    { key = "Base.Pot",  mu = 0.6, n = 2 },
    { key = "Base.Saucepan", mu = 0.6, n = 2 },
    { key = "Base.GridlePan", mu = 0.3, n = 2 },
    { key = "Base.CuttingBoardWooden", mu = 0.3, n = 2 },
    { key = "Base.CuttingBoardPlastic", mu = 0.3, n = 2 },
}
local w0sum = 10 + 8 + 10 + 8 + 4 + 4 -- vanilla weights we overwrite
local weights, info = T.planPool(items, Worig, w0sum, R)
-- final pool total
local Wnm = Worig - w0sum
local A = 0
for _, w in pairs(weights) do A = A + w end
local Wf = Wnm + A
check("planPool add-share respects pool cap",
    A / Wf <= T.MAX_POOL_ADD_SHARE + 1e-6)
check("planPool reports scaled", info.scaled == true) -- sum of raw shares > 0.35
local worstShare = 0
for _, w in pairs(weights) do worstShare = math.max(worstShare, w / Wf) end
check("planPool no item exceeds item cap", worstShare <= T.MAX_ITEM_SHARE + 1e-6)
check("planPool worst per-container count < 1",
    T.expectedPerContainer(worstShare, R) < 1.0)
-- the actual regression assertion: worst container count must be far below
-- the buggy ~2. Target: under 0.5.
check("issue #2: worst container count << the 2+ bug",
    T.expectedPerContainer(worstShare, R) < 0.5)

-- small pool that does NOT hit the pool cap: shares pass through unscaled
local w2, info2 = T.planPool(
    { { key = "A", mu = 0.3, n = 1 }, { key = "B", mu = 0.3, n = 1 } }, 200, 20, 4)
check("planPool no scale when under cap", info2.scaled == false)
-- expected count for A = R * share ; share = w/Wf, target mu=0.3, n=1
do
    local Wf2 = (200 - 20) + w2.A + w2.B
    check("planPool hits count target when unclamped",
        near(T.expectedPerContainer(w2.A / Wf2, 4) * 1, 0.3, 1e-6))
end

-- degenerate guard: our items were the whole original pool
local w3 = T.planPool({ { key = "X", mu = 0.5, n = 1 } }, 50, 50, 2)
check("planPool degenerate w0sum handled", w3.X ~= nil and w3.X > 0)

print(fails == 0 and "ALL TESTS PASSED" or (fails .. " FAILURES"))
os.exit(fails == 0 and 0 or 1)
