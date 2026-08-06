--------------------------------------------------------------------------------
-- AHB13_Debug.lua — QA console commands. Tech spec §5: "build this FIRST in
-- Mod B; without this, nothing is testable." Run from the -debug Lua console.
-- All output through print() -> console.txt with [AHB] prefixes.
--------------------------------------------------------------------------------

AH = AH or {}
AH.B = AH.B or {}

-- Building under the player: key, archetype, disposition, region, cache state.
function AHB_where()
    local ok, msg = pcall(function()
        local p = getPlayer()
        if not p then return "no player" end
        local sq = p:getCurrentSquare()
        if not sq then return "no square" end
        local room = sq:getRoom()
        if not room then return "not in a room (outdoors?)" end
        local b = room:getBuilding()
        if not b then return "room without building" end
        local r = AH.B.resolve(b)
        if not r then return "unresolvable (keyOf failed)" end
        return string.format("key=%s region=%s archetype=%s disposition=%s roomType=%s cached=%d",
            r.key, r.region, r.arch, r.disp,
            tostring(room:getName()), AH.B.cacheStats())
    end)
    print("[AHB] where: " .. tostring(msg))
end

-- Distribution sanity without walking the map: resolve n synthetic buildings
-- per region and print the archetype/disposition histogram. Uses the SAME
-- resolver math as real fills (resolveKey), so weight bugs show here first.
function AHB_audit(n)
    n = n or 200
    local regions = AH.B.Data.Regions.list
    for ri = 0, #regions do
        local rname, cx, cy
        if ri == 0 then
            rname, cx, cy = AH.B.Data.Regions.default, -1000, -1000 -- outside all rects
        else
            local r = regions[ri]
            rname = r.name
            cx = math.floor((r.x1 + r.x2) / 2)
            cy = math.floor((r.y1 + r.y2) / 2)
        end
        local archCount, dispCount = {}, {}
        for i = 1, n do
            -- synthetic-but-stable keys: offset a fake footprint per index
            local key = (cx + i) .. ":" .. (cy + i) .. ":" .. (cx + i + 9) .. ":" .. (cy + i + 8)
            local res = AH.B.resolveKey(key, cx, cy)
            archCount[res.arch] = (archCount[res.arch] or 0) + 1
            dispCount[res.disp] = (dispCount[res.disp] or 0) + 1
        end
        print(string.format("[AHB] audit region=%s n=%d", rname, n))
        for k, v in pairs(archCount) do
            print(string.format("[AHB]   arch %-14s %4d (%.1f%%)", k, v, 100 * v / n))
        end
        for k, v in pairs(dispCount) do
            print(string.format("[AHB]   disp %-18s %4d (%.1f%%)", k, v, 100 * v / n))
        end
    end
end

-- Item counts for the room the player is standing in (walk each room and
-- re-run; building:getRooms() does not exist per the probe). F3 duplication
-- check: any durable appearing 3+ times in one room is a bug.
function AHB_recount()
    local ok, err = pcall(function()
        local p = getPlayer()
        local room = p and p:getCurrentSquare() and p:getCurrentSquare():getRoom()
        if not room then print("[AHB] recount: not in a room") return end
        local counts, total = {}, 0
        local squares = room:getSquares()
        for i = 0, squares:size() - 1 do
            local sq = squares:get(i)
            local objs = sq:getObjects()
            for j = 0, objs:size() - 1 do
                local obj = objs:get(j)
                local cont = obj.getContainer and obj:getContainer()
                if cont then
                    local items = cont:getItems()
                    for k = 0, items:size() - 1 do
                        local it = items:get(k)
                        local t = it:getFullType()
                        counts[t] = (counts[t] or 0) + 1
                        total = total + 1
                    end
                end
            end
        end
        print(string.format("[AHB] recount room=%s items=%d", tostring(room:getName()), total))
        for t, c in pairs(counts) do
            print(string.format("[AHB]   %-40s %d%s", t, c, c >= 3 and "  <-- F3 CHECK" or ""))
        end
    end)
    if not ok then print("[AHB] recount failed: " .. tostring(err)) end
end

-- Mod A: re-print the merge-time change log.
function AH_diff()
    if AH.Distrib and AH.Distrib.logDiff then
        AH.Distrib.logDiff()
    else
        print("[AHB] AH.Distrib.logDiff unavailable (Mod A not loaded?)")
    end
end

-- Fill-handler counters (skip-path accounting; §3.5 steps 2a-2c/3/5). Also
-- written to the playtest log so the run's totals are captured there.
function AHB_counters()
    local C = AH.B.counters
    local line = string.format(
        "fills=%d applied=%d nested=%d outdoor=%d picker=%d nochain=%d nonres=%d",
        C.fills, C.applied, C.skippedNested, C.skippedOutdoor,
        C.skippedPicker, C.skippedNoChain, C.skippedNonRes)
    print("[AHB] " .. line)
    if AH.FLog then AH.FLog.line("[COUNTERS] " .. line); AH.FLog.flush() end
end

-- Force the playtest-log buffer to disk (it also auto-flushes every in-game
-- minute and every 40 lines).
function AH_flush()
    if AH.FLog then AH.FLog.flush() end
    print("[AH] playtest log flushed -> <Zomboid>/Lua/" .. (AH.FLog and AH.FLog.FILE or "AH_log.txt"))
end

AH.log("[AHB] debug commands: AHB_where() AHB_audit(n) AHB_recount() AHB_counters() AH_diff() AH_flush()")
