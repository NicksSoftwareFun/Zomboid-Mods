-- test_flog.lua — run with: lua5.1 test_flog.lua  (from mods/tests/)
-- AH_log.txt file logger: Session mode (truncate each launch) and Append mode
-- (accumulate + rotate at CAP). getFileWriter/getFileReader are mocked with a
-- per-file in-memory store so the truncate/append/rotate paths are checkable.

local files = {}     -- name -> content string
local opens = {}     -- { {name, append}, ... }

function getFileWriter(name, createIfNull, append)
    opens[#opens + 1] = { name = name, append = append }
    if not append then
        files[name] = ""
    elseif files[name] == nil then
        files[name] = createIfNull and "" or nil
    end
    if files[name] == nil then return nil end
    return {
        write = function(_, s) files[name] = files[name] .. s end,
        close = function() end,
    }
end
function getFileReader(name, createIfNull)
    local c = files[name]
    if c == nil then
        if not createIfNull then return nil end
        files[name] = ""; c = ""
    end
    local lines, i = {}, 0
    for ln in (c .. "\r\n"):gmatch("(.-)\r\n") do lines[#lines + 1] = ln end
    return {
        readLine = function(self) i = i + 1; return lines[i] end,
        close = function() end,
    }
end
Events = nil
SandboxVars = nil

dofile("../AmericanHousehold/42/media/lua/shared/AH00_Options.lua")

local fails = 0
local function check(label, cond)
    if cond then print("PASS " .. label)
    else fails = fails + 1; print("FAIL " .. label) end
end
local function has(name, s) return files[name] and files[name]:find(s, 1, true) ~= nil end
local function reset()
    files = {}; opens = {}
    AH.FLog._buf = {}; AH.FLog._started = false; AH.FLog._bytes = nil
end

check("FLog present", type(AH.FLog) == "table")
check("logMode defaults to Session (1)", AH.Options.logMode() == 1)

-- ===== Session mode (default) =====
reset()
AH.FLog.line("alpha"); AH.FLog.line("beta")
check("session: buffered, not written yet", #opens == 0)
AH.FLog.flush()
check("session: first flush truncates (append=false)", opens[1].append == false)
check("session: banner written", has(AH.FLog.FILE, "SESSION"))
check("session: lines written", has(AH.FLog.FILE, "alpha") and has(AH.FLog.FILE, "beta"))
AH.FLog.line("gamma"); AH.FLog.flush()
check("session: later flush appends (append=true)", opens[#opens].append == true)
check("session: no size sidecar in session mode", files[AH.FLog.SIZEFILE] == nil)

-- ===== Append mode =====
reset()
SandboxVars = { AmericanHousehold = { LogMode = 2 } }
check("append mode active", AH.Options.logMode() == 2)
AH.FLog.line("one"); AH.FLog.flush()
check("append: first flush APPENDS not truncates", opens[1].append == true)
check("append: session banner written", has(AH.FLog.FILE, "SESSION"))
check("append: size sidecar written", files[AH.FLog.SIZEFILE] ~= nil)
check("append: byte count tracked > 0", (AH.FLog._bytes or 0) > 0)

-- size persistence across "sessions": reset in-memory count, keep files;
-- flogReadSize should re-read the sidecar
local sizeOnDisk = tonumber(files[AH.FLog.SIZEFILE])
AH.FLog._bytes = nil
AH.FLog._started = false
AH.FLog.line("two"); AH.FLog.flush()
check("append: size restored from sidecar (grew, not reset)",
    (AH.FLog._bytes or 0) > sizeOnDisk)

-- ===== Rotation at CAP =====
reset()
SandboxVars = { AmericanHousehold = { LogMode = 2 } }
AH.FLog.CAP = 300   -- tiny cap so a few lines trip it
for i = 1, 20 do AH.FLog.line("rotation-fodder-line-" .. i) end
AH.FLog.flush()
check("rotate: backup AH_log.1.txt created", files[AH.FLog.ROTFILE] ~= nil)
check("rotate: backup holds the pre-rotation content", has(AH.FLog.ROTFILE, "rotation-fodder-line-1"))
check("rotate: live file truncated to a ROTATED marker", has(AH.FLog.FILE, "ROTATED"))
check("rotate: live file no longer holds old fodder", not has(AH.FLog.FILE, "rotation-fodder-line-1"))
check("rotate: byte count reset small", (AH.FLog._bytes or 0) < AH.FLog.CAP)

-- writing continues cleanly after a rotation
AH.FLog.line("post-rotate"); AH.FLog.flush()
check("rotate: appends resume after rotation", has(AH.FLog.FILE, "post-rotate"))

AH.FLog.CAP = 10 * 1024 * 1024
SandboxVars = nil

print(fails == 0 and "ALL TESTS PASSED" or (fails .. " FAILURES"))
os.exit(fails == 0 and 0 or 1)
