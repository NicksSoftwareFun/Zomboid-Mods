-- test_hash.lua — run with: lua5.1 test_hash.lua  (from mods/tests/)
dofile("../KnoxCountyHouseholds/42/media/lua/shared/AHB03_Hash.lua")

local fails = 0
local function check(label, cond)
    if cond then print("PASS " .. label)
    else fails = fails + 1; print("FAIL " .. label) end
end

-- FNV-1a 32-bit reference vectors, generated independently (Python):
local vectors = {
    { "",                                          2166136261 },
    { "a",                                         3826002220 },
    { "foobar",                                    3214735720 },
    { "10994:9696:11001:9708",                     635755523  },  -- real probe building key
    { "worldseed42|10994:9696:11001:9708|arch",    734432692  },  -- canonical seeding pattern
}
for _, v in ipairs(vectors) do
    check("fnv1a(" .. string.format("%q", v[1]) .. ")", AH.B.hash(v[1]) == v[2])
end

-- determinism: same seed -> identical stream
local a, b = AH.B.rng(12345), AH.B.rng(12345)
local same = true
for _ = 1, 100 do if a() ~= b() then same = false break end end
check("rng deterministic", same)

-- different purpose-tags -> different streams (decorrelation)
local s1 = AH.B.rng(AH.B.hash("k|arch"))
local s2 = AH.B.rng(AH.B.hash("k|disp"))
local diff = false
for _ = 1, 10 do if s1() ~= s2() then diff = true break end end
check("purpose-tags decorrelate", diff)

-- range + rough uniformity: 10k draws into 10 buckets, all within 20% of mean
local r = AH.B.rng(AH.B.hash("uniformity"))
local buckets = {0,0,0,0,0,0,0,0,0,0}
local inRange = true
for _ = 1, 10000 do
    local x = r()
    if x < 0 or x >= 1 then inRange = false end
    local i = math.floor(x * 10) + 1
    buckets[i] = buckets[i] + 1
end
check("rng in [0,1)", inRange)
local ok = true
for i = 1, 10 do if buckets[i] < 800 or buckets[i] > 1200 then ok = false end end
check("rng roughly uniform (10 buckets, 10k draws)", ok)

-- pickWeighted: distribution tracks weights (60/30/10 over 10k picks)
local entries = { {value="a", w=6}, {value="b", w=3}, {value="c", w=1} }
local counts = { a=0, b=0, c=0 }
local pr = AH.B.rng(AH.B.hash("picks"))
for _ = 1, 10000 do
    local v = AH.B.pickWeighted(entries, pr)
    counts[v] = counts[v] + 1
end
check("pickWeighted ~60%", counts.a > 5700 and counts.a < 6300)
check("pickWeighted ~30%", counts.b > 2700 and counts.b < 3300)
check("pickWeighted ~10%", counts.c > 800  and counts.c < 1200)

-- pickWeighted determinism with fresh equal-seed rngs
local p1 = AH.B.pickWeighted(entries, AH.B.rng(999))
local p2 = AH.B.pickWeighted(entries, AH.B.rng(999))
check("pickWeighted deterministic", p1 == p2)

print(fails == 0 and "ALL TESTS PASSED" or (fails .. " FAILURES"))
os.exit(fails == 0 and 0 or 1)
