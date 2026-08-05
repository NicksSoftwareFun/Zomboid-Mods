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
