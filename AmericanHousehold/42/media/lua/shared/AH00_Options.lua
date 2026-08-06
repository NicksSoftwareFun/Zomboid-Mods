--------------------------------------------------------------------------------
-- AH00_Options.lua — namespace, logging, options. Loads first (filename order).
-- Tech spec §2.3/§2.7. Pure Lua except the SandboxVars reads (pcall-guarded).
--------------------------------------------------------------------------------

AH = AH or {}
AH.VERSION = "0.1.0"

-- Logging ---------------------------------------------------------------------
function AH.log(msg)
    print("[AH] " .. tostring(msg))
end

local warned = {}
-- log an error-class message once per unique site key, then go quiet.
function AH.warnOnce(key, msg)
    if warned[key] then return end
    warned[key] = true
    print("[AH][WARN] " .. tostring(msg))
end

-- File log ---------------------------------------------------------------------
-- A dedicated playtesting log written to <Zomboid>/Lua/AH_log.txt (getFileWriter
-- is Kahlua's only file-output path; it is rooted at Lua/, one folder below
-- console.txt). Captures verbose-level and QA info BY DEFAULT, independent of
-- the Verbose console toggle. Buffered, flushed every in-game minute + at 40
-- lines. Each session starts with a "==== SESSION ... ====" banner.
--
-- LogMode sandbox option:
--   1 Session (default) — truncate at the start of each launch (bounded to
--     one run; the safe default for normal players).
--   2 Append — accumulate across launches for multi-session debugging, and
--     ROTATE at CAP bytes: copy AH_log.txt -> AH_log.1.txt, then start a fresh
--     AH_log.txt. Total on disk stays under ~2x CAP. Byte count persists in a
--     tiny sidecar (AH_log.size) so boot doesn't re-read the whole file.
AH.FLog = {
    _buf = {}, _started = false, _bytes = nil,
    FILE = "AH_log.txt", ROTFILE = "AH_log.1.txt", SIZEFILE = "AH_log.size",
    CAP = 10 * 1024 * 1024,  -- 10 MB before rotation
}

local function flogAppendMode()
    return AH.Options and AH.Options.logMode and AH.Options.logMode() == 2
end

local function flogSessionBanner()
    local ts = ""
    pcall(function() if getTimestampMs then ts = " @" .. tostring(getTimestampMs()) end end)
    return "==== SESSION  The American Household v" .. tostring(AH.VERSION) .. ts .. " ===="
end

-- append mode: read the persisted byte count once (cheap, one integer)
local function flogReadSize()
    if AH.FLog._bytes ~= nil then return end
    AH.FLog._bytes = 0
    pcall(function()
        local r = getFileReader(AH.FLog.SIZEFILE, false)
        if r then
            local n = tonumber(r:readLine() or "")
            if n then AH.FLog._bytes = n end
            r:close()
        end
    end)
end

local function flogWriteSize()
    pcall(function()
        local w = getFileWriter(AH.FLog.SIZEFILE, true, false)
        if w then w:write(tostring(math.floor(AH.FLog._bytes or 0))); w:close() end
    end)
end

-- copy FILE -> ROTFILE, then truncate FILE. Best-effort: if the reader API is
-- unavailable the copy is skipped but FILE is still truncated, so the log
-- stays bounded either way.
local function flogRotate()
    local copied = pcall(function()
        local r = getFileReader(AH.FLog.FILE, false)
        if not r then error("no reader") end
        local w = getFileWriter(AH.FLog.ROTFILE, true, false)
        if not w then r:close(); error("no writer") end
        local line = r:readLine()
        while line ~= nil do w:write(line .. "\r\n"); line = r:readLine() end
        w:close(); r:close()
    end)
    pcall(function()
        local w = getFileWriter(AH.FLog.FILE, true, false)  -- truncate
        if w then
            w:write("==== ROTATED (previous run -> " .. AH.FLog.ROTFILE ..
                (copied and "" or "; copy unavailable") .. ") ====\r\n")
            w:close()
        end
    end)
    AH.FLog._bytes = 80
    flogWriteSize()
end

function AH.FLog.flush()
    local buf = AH.FLog._buf
    if #buf == 0 then return end
    AH.FLog._buf = {}
    local append = flogAppendMode()
    local truncate = (not append) and (not AH.FLog._started)
    local newSession = not AH.FLog._started
    AH.FLog._started = true
    if append then flogReadSize() end
    pcall(function()
        -- getFileWriter(name, createIfNull, append); truncate only in Session
        -- mode's first flush, otherwise append.
        local w = getFileWriter(AH.FLog.FILE, true, not truncate)
        if not w then return end
        if newSession then
            local banner = flogSessionBanner()
            w:write(banner .. "\r\n")
            if append then AH.FLog._bytes = (AH.FLog._bytes or 0) + #banner + 2 end
        end
        for i = 1, #buf do
            local s = tostring(buf[i])
            w:write(s .. "\r\n")
            if append then AH.FLog._bytes = (AH.FLog._bytes or 0) + #s + 2 end
        end
        w:close()
    end)
    if append then
        flogWriteSize()
        if (AH.FLog._bytes or 0) > AH.FLog.CAP then flogRotate() end
    end
end

function AH.FLog.line(s)
    local buf = AH.FLog._buf
    buf[#buf + 1] = s
    if #buf >= 40 then AH.FLog.flush() end
end

-- Verbose log: ALWAYS to the file; to console only when Verbose is on. This is
-- the "verbose mode by default" the log file provides — playtesting detail is
-- captured even with the console quiet.
function AH.vlog(msg)
    AH.FLog.line(msg)
    if AH.Options and AH.Options.verbose and AH.Options.verbose() then
        AH.log(msg)
    end
end

-- Flush regularly so a crash doesn't lose the tail; and once at game start so
-- the boot/merge block lands immediately.
if Events then
    if Events.EveryOneMinute then Events.EveryOneMinute.Add(AH.FLog.flush) end
    if Events.OnGameStart then Events.OnGameStart.Add(AH.FLog.flush) end
    if Events.OnSave then Events.OnSave.Add(AH.FLog.flush) end
end

-- Options ---------------------------------------------------------------------
-- Reads SandboxVars.AmericanHousehold.* if present; every accessor has a
-- default so the mod works before sandbox-options wiring lands (open item 6).
local function sv(name, default)
    local ok, v = pcall(function()
        return SandboxVars and SandboxVars.AmericanHousehold
               and SandboxVars.AmericanHousehold[name]
    end)
    if ok and v ~= nil then return v end
    return default
end

AH.Options = {
    enabled            = function() return sv("Enabled", true) end,
    -- 1=Low(-20%) 2=Design 3=High(+20%), per tech spec §2.7
    abundance          = function() return sv("HouseholdAbundance", 2) end,
    ledgerEnabled      = function() return sv("LedgerEnabled", true) end,
    vehicleMultiplier  = function() return sv("VehicleMultiplier", 1.5) end,
    -- 1=Panic 2=Full, design §10.2
    setpieceStocking   = function() return sv("SetpieceStocking", 1) end,
    verbose            = function() return sv("Verbose", false) end,
    -- Mod B reads this from the same namespace
    archetypesEnabled  = function() return sv("ArchetypesEnabled", true) end,
    -- AH_log.txt retention: 1=Session (wipe each launch), 2=Append (+rotate)
    logMode            = function() return sv("LogMode", 1) end,
}

function AH.Options.abundanceFactor()
    local a = AH.Options.abundance()
    if a == 1 then return 0.8 elseif a == 3 then return 1.2 end
    return 1.0
end

-- One boot block for the file log: the option values + a pointer, written once.
-- Called by the first merge pass so it lands with the merge summaries.
local bootLogged = false
function AH.FLog.boot()
    if bootLogged then return end
    bootLogged = true
    local o = AH.Options
    AH.FLog.line(string.format(
        "[OPTIONS] enabled=%s abundance=%s ledger=%s vehicleMult=%s setpiece=%s archetypes=%s verbose=%s logMode=%s",
        tostring(o.enabled()), tostring(o.abundance()), tostring(o.ledgerEnabled()),
        tostring(o.vehicleMultiplier()), tostring(o.setpieceStocking()),
        tostring(o.archetypesEnabled()), tostring(o.verbose()), tostring(o.logMode())))
    -- tell the player where to find the file (console, once)
    AH.log("playtest log -> <Zomboid>/Lua/" .. AH.FLog.FILE ..
           (o.logMode() == 2 and " (append+rotate mode)" or " (per-session)"))
end
