--------------------------------------------------------------------------------
-- AH13_Vehicles.lua — §9 vehicle spawn multiplier. Tech spec §2.6.
--
-- Field names VERIFIED against B42.20 media/lua/shared/Vehicles/
-- VehicleZoneDefinition.lua (open item 1 resolved, Aug 2026; verbatim copy
-- in reference/):
--   zone.spawnRate    = per-zone % chance of adding a vehicle; the game
--                       defaults it to 16 when the zone omits the field,
--                       so scaling must write (spawnRate or 16) * mult.
--   vehicles[id].spawnChance = pick-share out of ~100 choosing WHICH model
--                       spawns — scaling it would not add a single car.
--                       Never touched.
--   baseVehicleQuality / chanceToPartDamage / chanceToSpawnKey / burnt and
--   over-car chances = condition & character fields. Never touched
--   (settled decision 3: fuel/condition neutral).
--
-- TRAP (from the real file): business2..business12 are ALIASES of the one
-- business table — twelve keys, one table. Dedupe by table identity or the
-- multiplier compounds twelve times on that zone.
--------------------------------------------------------------------------------

AH = AH or {}
AH.Vehicles = {}

local DEFAULT_SPAWN_RATE = 16 -- game-side default when a zone omits spawnRate
local MAX_SPAWN_RATE     = 100

function AH.Vehicles.apply()
    if not AH.Options.enabled() then return end

    local mult = AH.Options.vehicleMultiplier()
    if not mult or mult == 1.0 then
        AH.log("vehicle pass: multiplier 1.0 — no-op, tables untouched")
        return
    end

    if type(VehicleZoneDistribution) ~= "table" then
        AH.warnOnce("novzd",
            "VehicleZoneDistribution missing at merge time — vehicle pass skipped")
        return
    end

    AH.log(string.format("vehicle pass: multiplier %.2f", mult))
    local seen, touched = {}, 0   -- table identity -> zone name (alias dedupe)
    for zoneName, zone in pairs(VehicleZoneDistribution) do
        if type(zone) == "table" and type(zone.vehicles) == "table" then
            if seen[zone] then
                AH.log(string.format("  zone %-18s aliases '%s' — already scaled",
                    tostring(zoneName), seen[zone]))
            else
                seen[zone] = tostring(zoneName)
                local base = zone.spawnRate or DEFAULT_SPAWN_RATE
                local rate = base * mult
                if rate > MAX_SPAWN_RATE then rate = MAX_SPAWN_RATE end
                zone.spawnRate = rate
                touched = touched + 1
                AH.log(string.format("  zone %-18s spawnRate %.1f -> %.1f",
                    tostring(zoneName), base, rate))
            end
        end
    end
    AH.log(string.format("vehicle pass: %d zones scaled", touched))
    AH.FLog.boot()
    AH.FLog.line(string.format("[MERGE] vehicle pass: x%.2f, %d zones scaled", mult, touched))
    AH.FLog.flush()  -- boot block complete; get it on disk now
end

if Events and Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(AH.Vehicles.apply)
    AH.log("v" .. AH.VERSION .. " vehicle pass registered")
else
    AH.log("FATAL-ish: OnPreDistributionMerge missing; vehicle pass inert")
end
