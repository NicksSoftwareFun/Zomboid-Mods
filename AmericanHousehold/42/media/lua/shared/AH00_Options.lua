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
-- the Verbose console toggle, so a normal run still records what happened.
-- Truncated at the start of each launch (like console.txt), buffered, and
-- flushed every in-game minute + at 40 lines, so it is cheap and crash-safe.
AH.FLog = { _buf = {}, _started = false, FILE = "AH_log.txt", _header = nil }

function AH.FLog.flush()
    local buf = AH.FLog._buf
    if #buf == 0 then return end
    AH.FLog._buf = {}
    local truncate = not AH.FLog._started
    AH.FLog._started = true
    pcall(function()
        -- getFileWriter(name, createIfNull, append); append = not truncate
        local w = getFileWriter(AH.FLog.FILE, true, not truncate)
        if not w then return end
        if truncate and AH.FLog._header then w:write(AH.FLog._header .. "\r\n") end
        for i = 1, #buf do w:write(tostring(buf[i]) .. "\r\n") end
        w:close()
    end)
end

function AH.FLog.line(s)
    local buf = AH.FLog._buf
    buf[#buf + 1] = s
    if #buf >= 40 then AH.FLog.flush() end
end

function AH.FLog.setHeader(h) AH.FLog._header = h end

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
}

function AH.Options.abundanceFactor()
    local a = AH.Options.abundance()
    if a == 1 then return 0.8 elseif a == 3 then return 1.2 end
    return 1.0
end

AH.FLog.setHeader("==== The American Household  -  AH_log  -  v" .. AH.VERSION .. " ====")

-- One boot block for the file log: the option values + a pointer, written once.
-- Called by the first merge pass so it lands with the merge summaries.
local bootLogged = false
function AH.FLog.boot()
    if bootLogged then return end
    bootLogged = true
    local o = AH.Options
    AH.FLog.line(string.format(
        "[OPTIONS] enabled=%s abundance=%s ledger=%s vehicleMult=%s setpiece=%s archetypes=%s verbose=%s",
        tostring(o.enabled()), tostring(o.abundance()), tostring(o.ledgerEnabled()),
        tostring(o.vehicleMultiplier()), tostring(o.setpieceStocking()),
        tostring(o.archetypesEnabled()), tostring(o.verbose())))
    -- tell the player where to find the file (console, once)
    AH.log("playtest log -> <Zomboid>/Lua/" .. AH.FLog.FILE ..
           " (verbose detail written there by default)")
end
