--------------------------------------------------------------------------------
-- AHB03_Hash.lua — deterministic hashing + PRNG for Mod B. PURE LUA 5.1:
-- no bitwise operators, no bit library (Kahlua has neither), no game calls.
-- Unit-tested against independently generated FNV-1a vectors
-- (tests/test_hash.lua). Tech spec §3.3.
--
-- Everything per-building derives from these two functions. If they are
-- wrong, houses change personality between sessions or disagree between
-- MP server and clients — which is why they are tested outside the game
-- against reference vectors before any in-game use.
--------------------------------------------------------------------------------

AH = AH or {}
AH.B = AH.B or {}

-- 8-bit XOR via nibble lookup table (Kahlua-safe, allocation-free at call time)
local xt = {}
do
    for a = 0, 15 do
        xt[a] = {}
        for b = 0, 15 do
            -- compute a XOR b arithmetically, bit by bit
            local r, bit, x, y = 0, 1, a, b
            for _ = 1, 4 do
                local xa, yb = x % 2, y % 2
                if xa ~= yb then r = r + bit end
                x = (x - xa) / 2
                y = (y - yb) / 2
                bit = bit * 2
            end
            xt[a][b] = r
        end
    end
end

local floor = math.floor

local function xor8(a, b)
    local al, bl = a % 16, b % 16
    return xt[al][bl] + 16 * xt[(a - al) / 16][(b - bl) / 16]
end

-- (h * m) mod 2^32 via 16-bit half multiplies. Intermediates stay below
-- 2^49 — inside Lua's exact-integer double range (2^53). Tech spec §3.3.
local function mulmod32(h, m)
    local h0 = h % 65536
    local h1 = (h - h0) / 65536
    local m0 = m % 65536
    local m1 = (m - m0) / 65536
    -- (h1*65536 + h0)(m1*65536 + m0) mod 2^32
    --   = (h0*m0 + ((h1*m0 + h0*m1) mod 65536)*65536) mod 2^32
    local mid = (h1 * m0 + h0 * m1) % 65536
    return (h0 * m0 + mid * 65536) % 4294967296
end

-- FNV-1a, 32-bit. Only the low byte of the accumulator changes under XOR
-- with a byte-sized operand, so xor8 on the low byte suffices.
function AH.B.hash(str)
    local h = 2166136261
    for i = 1, #str do
        local lo = h % 256
        h = h - lo + xor8(lo, string.byte(str, i))
        h = mulmod32(h, 16777619)
    end
    return h
end

-- Deterministic PRNG: 32-bit LCG (Numerical Recipes constants), seeded from
-- a hash. Returns a function yielding uniform [0,1). Good enough for loot
-- picks; NOT cryptographic, doesn't need to be.
function AH.B.rng(seed)
    local state = seed % 4294967296
    return function()
        state = (mulmod32(state, 1664525) + 1013904223) % 4294967296
        return state / 4294967296
    end
end

-- Weighted pick: entries = { {value=..., w=number}, ... }, r = rng function.
-- Deterministic given the same entries order and rng state.
function AH.B.pickWeighted(entries, r)
    local total = 0
    for i = 1, #entries do total = total + entries[i].w end
    if total <= 0 then return nil end
    local x = r() * total
    for i = 1, #entries do
        x = x - entries[i].w
        if x < 0 then return entries[i].value end
    end
    return entries[#entries].value -- float-edge fallback
end

-- The canonical seeding pattern (tech spec §3.3): purpose-tags decorrelate
-- the archetype stream from the disposition stream.
--   local base = AH.B.hash(worldSeed .. "|" .. buildingKey)
--   local arch = AH.B.pickWeighted(weights, AH.B.rng(AH.B.hash(base .. "|arch")))
--   local disp = AH.B.pickWeighted(row,     AH.B.rng(AH.B.hash(base .. "|disp")))
