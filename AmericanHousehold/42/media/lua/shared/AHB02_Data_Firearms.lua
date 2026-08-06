--------------------------------------------------------------------------------
-- AHB02_Data_Firearms.lua — §6.4 caliber-coherent firearm system. PURE DATA.
--
-- Gun ids, calibers, and ammo-box ids VERIFIED against B42.20 weapon.txt
-- (AmmoType / AmmoBox fields) and reference/b42.20_item_ids.txt. Period
-- filter (July 1993): the modern tactical guns present in B42.20 —
-- JS-2000/JS-14, MSR7T, and the cap-gun toys — are EXCLUDED. What remains
-- is period-plausible Kentucky civilian iron.
--
-- Caliber COHERENCE (the F7 guard, refined): coherence means the ammo a
-- household holds fits the guns that household plausibly owns — NOT that ammo
-- may only appear beside a gun. A gun owner almost always has loose ammo, and
-- ammo outlives the gun that got grabbed on the way out the door. So:
--   * ammo rolled WITH a gun is always that gun's caliber (unchanged);
--   * archetypes with ammo depth ALSO spawn independent "loose" ammo, drawn
--     from that archetype's OWN gun calibers — a hunting house has loose .308
--     and 12ga in a drawer even when the rifle is elsewhere or gone. This is
--     coherent (right calibers for the household) without being gun-locked.
-- Orphan/mismatched calibers are still an F7 violation; loose ammo only ever
-- uses calibers the archetype's guns[] list can fire.
--
-- perBox = rounds per retail box (1993 norms; not in the scripts, which only
-- carry the reload-UI AmmoBox link). AHB12 converts an archetype's rounds
-- range into a box count via round(rounds / perBox).
--------------------------------------------------------------------------------

AH = AH or {}
AH.B = AH.B or {}
AH.B.Data = AH.B.Data or {}

AH.B.Data.Firearms = {
    -- caliber -> retail box item + rounds/box
    ammoByCaliber = {
        ["9mm"]   = { box = "Base.Bullets9mmBox",   perBox = 50 },
        ["45"]    = { box = "Base.Bullets45Box",    perBox = 50 },
        ["44"]    = { box = "Base.Bullets44Box",    perBox = 50 },
        ["357"]   = { box = "Base.Bullets357Box",   perBox = 50 },
        ["38"]    = { box = "Base.Bullets38Box",    perBox = 50 },
        ["308"]   = { box = "Base.308Box",          perBox = 20 },
        ["3030"]  = { box = "Base.3030Box",         perBox = 20 },
        ["556"]   = { box = "Base.556Box",          perBox = 20 },
        ["shotgun"] = { box = "Base.ShotgunShellsBox", perBox = 25 },
    },

    -- Per-archetype profiles. chance = per-building ownership (§6.4 table,
    -- PRE-disposition — dispositions supply the scarcity). nContainers =
    -- eligible storage containers/building (AHB12 converts chance to
    -- per-container). rooms/containers restrict where guns may appear.
    -- guns[].w = relative weight within the archetype's rack.
    archetypeProfiles = {
        -- Deepest ammo, long guns, cabinet/closet. .30-06 & .30-30 deer
        -- rifles, 12ga pump, .22-class varmint.
        hunting = {
            chance = 0.97, nContainers = 2,
            rooms = { bedroom = true, closet = true, storage = true },
            containers = { wardrobe = true, locker = true, crate = true,
                           metal_shelves = true, other = true },
            guns = {
                { item = "Base.HuntingRifle",  caliber = "308",  w = 4 },
                { item = "Base.L94_Rifle",     caliber = "3030", w = 4 }, -- lever .30-30
                { item = "Base.Shotgun",       caliber = "shotgun", w = 4 },
                { item = "Base.VarmintRifle",  caliber = "556",  w = 3 }, -- small-game
                { item = "Base.DoubleBarrelShotgun", caliber = "shotgun", w = 2 },
                { item = "Base.Revolver",      caliber = "357",  w = 1 },
            },
            gunCount = { 2, 4 }, ammoRounds = { 60, 150 },
            gunCondition = { 0.6, 1.0 },
        },
        -- Sidearm + often a rifle, best-organized. Ammo cans (§5.2).
        military = {
            chance = 0.9, nContainers = 2,
            rooms = { bedroom = true, closet = true, storage = true, garagestorage = true },
            containers = { wardrobe = true, locker = true, crate = true, other = true },
            guns = {
                { item = "Base.Pistol",        caliber = "9mm",  w = 5 }, -- M9-pattern
                { item = "Base.AssaultRifle2", caliber = "308",  w = 2 }, -- M14
                { item = "Base.Shotgun",       caliber = "shotgun", w = 2 },
                { item = "Base.Revolver",      caliber = "357",  w = 1 },
            },
            gunCount = { 1, 3 }, ammoRounds = { 100, 200 },
            gunCondition = { 0.75, 1.0 },
            ammoContainer = "Base.Bag_AmmoBox", -- flavor; §5.2 ammo cans
        },
        -- Shotgun or .22 (~60%).
        woodheat = {
            chance = 0.6, nContainers = 2,
            rooms = { bedroom = true, closet = true, storage = true },
            containers = { wardrobe = true, locker = true, other = true },
            guns = {
                { item = "Base.Shotgun",      caliber = "shotgun", w = 5 },
                { item = "Base.VarmintRifle", caliber = "556", w = 3 },
                { item = "Base.Revolver_Short", caliber = "38", w = 2 },
            },
            gunCount = { 1, 1 }, ammoRounds = { 20, 60 },
            gunCondition = { 0.4, 0.9 },
        },
        canning = {
            chance = 0.6, nContainers = 2,
            rooms = { bedroom = true, closet = true, storage = true },
            containers = { wardrobe = true, locker = true, other = true },
            guns = {
                { item = "Base.Shotgun",      caliber = "shotgun", w = 5 },
                { item = "Base.Revolver_Short", caliber = "38", w = 3 },
            },
            gunCount = { 1, 1 }, ammoRounds = { 20, 60 },
            gunCondition = { 0.4, 0.9 },
        },
        -- Rural utility (~50%).
        handy = {
            chance = 0.5, nContainers = 2,
            rooms = { bedroom = true, closet = true, garagestorage = true },
            containers = { wardrobe = true, locker = true, other = true },
            guns = {
                { item = "Base.Shotgun",      caliber = "shotgun", w = 4 },
                { item = "Base.Pistol",       caliber = "9mm", w = 3 },
                { item = "Base.Revolver",     caliber = "357", w = 2 },
            },
            gunCount = { 1, 2 }, ammoRounds = { 20, 60 },
            gunCondition = { 0.4, 0.85 },
        },
        -- Nightstand handgun (~40%).
        commuter = {
            chance = 0.4, nContainers = 1,
            rooms = { bedroom = true },
            containers = { sidetable = true, dresser = true },
            guns = {
                { item = "Base.Pistol",       caliber = "9mm", w = 4 }, -- recent purchase (§5.14 LA riots)
                { item = "Base.Revolver_Short", caliber = "38", w = 4 },
                { item = "Base.Pistol2",      caliber = "45", w = 2 },
            },
            gunCount = { 1, 1 }, ammoRounds = { 15, 40 },
            gunCondition = { 0.6, 1.0 },
        },
        -- Old revolver or break shotgun (~50%).
        elderly = {
            chance = 0.5, nContainers = 1,
            rooms = { bedroom = true, closet = true },
            containers = { sidetable = true, dresser = true, wardrobe = true },
            guns = {
                { item = "Base.Revolver_Short", caliber = "38", w = 5 },
                { item = "Base.Revolver_Long",  caliber = "44", w = 2 },
                { item = "Base.DoubleBarrelShotgun", caliber = "shotgun", w = 3 },
            },
            gunCount = { 1, 1 }, ammoRounds = { 10, 25 },
            gunCondition = { 0.3, 0.7 },
        },
        -- Cheap handgun (~25%). Keeps the mod honest (§5.9).
        starter = {
            chance = 0.25, nContainers = 1,
            rooms = { bedroom = true },
            containers = { sidetable = true, dresser = true },
            guns = {
                { item = "Base.Revolver_Short", caliber = "38", w = 4 },
                { item = "Base.Pistol",        caliber = "9mm", w = 3 },
            },
            gunCount = { 1, 1 }, ammoRounds = { 5, 20 },
            gunCondition = { 0.3, 0.7 },
        },
        -- Depth no other archetype has (§5.13). Found HALF-EMPTY by the
        -- sheltered_prepared lock: the deplete filter spends the ammo.
        survivalist = {
            chance = 1.0, nContainers = 2,
            rooms = { bedroom = true, closet = true, storage = true, garagestorage = true },
            containers = { wardrobe = true, locker = true, crate = true, other = true },
            guns = {
                { item = "Base.AssaultRifle2", caliber = "308", w = 3 }, -- M14
                { item = "Base.Shotgun",       caliber = "shotgun", w = 3 },
                { item = "Base.HuntingRifle",  caliber = "308", w = 2 },
                { item = "Base.Pistol",        caliber = "9mm", w = 3 },
                { item = "Base.Revolver",      caliber = "357", w = 2 },
            },
            gunCount = { 2, 4 }, ammoRounds = { 150, 300 },
            gunCondition = { 0.6, 1.0 },
        },
        -- mobile home: shotgun or .22 (~60%), like woodheat.
        mobile = {
            chance = 0.6, nContainers = 1,
            rooms = { bedroom = true },
            containers = { sidetable = true, dresser = true, wardrobe = true },
            guns = {
                { item = "Base.Shotgun",      caliber = "shotgun", w = 4 },
                { item = "Base.Revolver_Short", caliber = "38", w = 3 },
                { item = "Base.VarmintRifle", caliber = "556", w = 2 },
            },
            gunCount = { 1, 1 }, ammoRounds = { 15, 45 },
            gunCondition = { 0.35, 0.8 },
        },
    },
}

--------------------------------------------------------------------------------
-- Independent (loose) ammo, derived from each profile so calibers stay
-- coherent. "It is rare to be a gun owner with no ammo": loose-ammo presence
-- tracks the archetype's gun-ownership rate. calibers is a weighted list
-- built from the profile's OWN guns[], so a hunting drawer holds .308/.30-30/
-- 12ga and never, say, 9mm the household has no pistol for. AHB12 rolls this
-- independently of whether a gun spawned in the container; the disposition
-- filter (evac_organized/looted -> removeCategories.ammo) still strips it
-- where the story calls for it.
--------------------------------------------------------------------------------
do
    local P = AH.B.Data.Firearms.archetypeProfiles
    for _, prof in pairs(P) do
        -- weighted caliber list from this archetype's guns
        local cal = {}
        for i = 1, #prof.guns do
            cal[#cal + 1] = { value = prof.guns[i].caliber, w = prof.guns[i].w }
        end
        prof.looseAmmo = {
            -- a gun owner rarely has zero ammo: scale with ownership, floor high
            chance = math.min(0.9, 0.5 + prof.chance * 0.45),
            nContainers = prof.nContainers,
            calibers = cal,
            -- loose stashes are smaller than the gun's matched allotment
            rounds = { math.floor(prof.ammoRounds[1] * 0.4),
                       math.floor(prof.ammoRounds[2] * 0.6) },
        }
    end
end
