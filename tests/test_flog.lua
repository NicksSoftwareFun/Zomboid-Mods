-- test_flog.lua — run with: lua5.1 test_flog.lua  (from mods/tests/)
-- The AH_log.txt file logger: buffering, truncate-first-then-append, header
-- written once, and vlog routing to file always / console only when verbose.
-- getFileWriter is mocked to capture what would hit disk.

-- capture every getFileWriter open + the bytes written to it
local opens = {}          -- { {name, createIfNull, append}, ... }
local written = {}        -- flat list of written strings
function getFileWriter(name, createIfNull, append)
    opens[#opens + 1] = { name = name, createIfNull = createIfNull, append = append }
    return {
        write = function(_, s) written[#written + 1] = s end,
        close = function() end,
    }
end
Events = nil  -- skip the event registration branch

dofile("../AmericanHousehold/42/media/lua/shared/AH00_Options.lua")

local fails = 0
local function check(label, cond)
    if cond then print("PASS " .. label)
    else fails = fails + 1; print("FAIL " .. label) end
end
local function joined() return table.concat(written, "") end

check("FLog present", type(AH.FLog) == "table")
check("vlog present", type(AH.vlog) == "function")

-- buffering: line() should NOT open the file until flush
AH.FLog.line("alpha")
AH.FLog.line("beta")
check("buffered, not yet written", #opens == 0)

-- first flush: truncates (append=false) and writes header + both lines
AH.FLog.flush()
check("first flush opened once", #opens == 1)
check("first flush truncates (append=false)", opens[1].append == false)
check("header written", joined():find("AH_log", 1, true) ~= nil)
check("buffered lines written", joined():find("alpha", 1, true) and joined():find("beta", 1, true))

-- second flush: appends (append=true), no second header
local hdrCountBefore = select(2, joined():gsub("AH_log", "AH_log"))
AH.FLog.line("gamma")
AH.FLog.flush()
check("second flush appends (append=true)", opens[2].append == true)
check("header not repeated", select(2, joined():gsub("AH_log", "AH_log")) == hdrCountBefore)
check("later line written", joined():find("gamma", 1, true) ~= nil)

-- empty flush is a no-op (no extra open)
local opensBefore = #opens
AH.FLog.flush()
check("empty flush does nothing", #opens == opensBefore)

-- vlog: always writes to the file; console only when verbose (default false)
local consoleHits = 0
local realLog = AH.log
AH.log = function() consoleHits = consoleHits + 1 end
AH.vlog("delta")
AH.FLog.flush()
AH.log = realLog
check("vlog wrote to file", joined():find("delta", 1, true) ~= nil)
check("vlog silent on console when verbose off", consoleHits == 0)

-- auto-flush at 40 buffered lines
local opensPre = #opens
for i = 1, 40 do AH.FLog.line("bulk" .. i) end
check("auto-flush fired at 40 lines", #opens > opensPre)

print(fails == 0 and "ALL TESTS PASSED" or (fails .. " FAILURES"))
os.exit(fails == 0 and 0 or 1)
