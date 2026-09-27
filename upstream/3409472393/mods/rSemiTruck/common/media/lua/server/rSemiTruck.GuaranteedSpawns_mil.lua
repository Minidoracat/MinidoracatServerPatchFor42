-- Guaranteed Military Vehicle Spawns at fixed coordinates
-- These vehicles will ALWAYS spawn at these locations

local function guaranteed_military_spawns_enabled()
    return not SandboxVars
        or not SandboxVars.rSemiTruck
        or SandboxVars.rSemiTruck.GuaranteedMilitarySpawns ~= false
end

local function cartrailer_spawns_enabled()
    local sandboxVars = rawget(_G, "SandboxVars")
    return not sandboxVars
        or not sandboxVars.rSemiTruck
        or sandboxVars.rSemiTruck.CarTrailerSpawns ~= false
end

local guaranteedSpawns = {
    -- Format: {vehicleType, x, y, z, direction, alwaysActive}
    -- x, y = world coordinates
    -- z = 0 for ground level
    -- direction = IsoDirections name: "N", "NE", "E", "SE", "S", "SW", "W", "NW"  (or nil for random)
    -- alwaysActive = true bypasses the sandbox toggle for that fixed spawn only

    
    {"Base.SemiTruckBox_mil", 10670, 10411, 0, "S"},-- Muldraugh Police impound
    {"Base.SemiTruckBox_mil", 11668, 9940, 0, "S"}, -- Railyard

    {"Base.SemiTrailerVan_mil", 12449, 4261, 0, "S"}, -- Louisville checkpoint
    {"Base.SemiTruck_mil", 12466, 4313, 0, "N"},       -- Louisville checkpoint

    {"Base.SemiTrailerVan_mil", 15468, 3004, 0, "S"}, -- Louisville Airport


    {"Base.SemiTrailerCartrailer", 5758,5372,0, "S", true}, -- Riverside Scrap Yard
    {"Base.SemiTrailerCartrailer", 5628,5889,0, "S", true}, -- Riverside Industrial Park

    {"Base.SemiTrailerCartrailer", 10312,9257,0, "N", true}, -- Muldraugh McCoy's Garage

    {"Base.SemiTrailerCartrailer", 852,12947,0, "W", true}, -- Irvington Speedway

    {"Base.SemiTrailerCartrailer", 12411,2769,0, "S", true}, -- Louisville Chapelmount

    {"Base.SemiTrailerCartrailer", 8251,12200,0, "E", true} -- Rosewood Gas Station
}

-- Inject additional spawns when specific map mods are active


--Secretz42 W.I.P. - add more locations as needed

if getActivatedMods():contains("\\Secretz42") then 
    -- Secretz42 map mod locations
    table.insert(guaranteedSpawns, {"Base.SemiTruck_mil",       9775, 13152,  0, "E"})
    table.insert(guaranteedSpawns, {"Base.SemiTrailerVan_mil",  10329, 12521, 0, "S"}) -- March Ridge checkpoint
end


if getActivatedMods():contains("\\RavenCreekB42") then 
    -- RavenCreekB42 map mod locations
    table.insert(guaranteedSpawns, {"Base.SemiTruck_mil",       6499, 15337,  0, "W"})
    table.insert(guaranteedSpawns, {"Base.SemiTrailerVan_mil",  6514, 15338, 0, "W"}) -- RavenCreekB42
end


-- if activeMods:contains("SomeOtherMod") then
--     table.insert(guaranteedSpawns, {"Base.SemiTruckBox_mil", 12345, 6789, 0, "W"})
-- end

Events.OnInitGlobalModData.Add(function()
    Events.LoadGridsquare.Add(function(square)
        local sx = square:getX()
        local sy = square:getY()

        for i, spawnData in ipairs(guaranteedSpawns) do
            if spawnData[2] == sx and spawnData[3] == sy then
                local vehicleType = spawnData[1]
                if vehicleType == "Base.SemiTrailerCartrailer" and not cartrailer_spawns_enabled() then
                    break
                end

                local alwaysActive = spawnData[6] == true
                if not alwaysActive and not guaranteed_military_spawns_enabled() then
                    break
                end
                local direction   = spawnData[5]
                local spawnKey    = vehicleType .. "_" .. sx .. "_" .. sy

                local modData = ModData.getOrCreate("rSemiTruck_GuaranteedSpawns")
                if not modData[spawnKey] then
                    if not square:isVehicleIntersecting() then
                        local isoDir = direction and IsoDirections.fromString(direction) or IsoDirections.getRandom()
                        local vehicle = addVehicleDebug(vehicleType, isoDir, nil, square)
                        if vehicle then
                            modData[spawnKey] = true
                            ModData.transmit("rSemiTruck_GuaranteedSpawns")
                            --print(("rSemiTruck: Spawned " .. vehicleType .. " at (" .. sx .. ", " .. sy .. ")")
                        else
                            --print(("rSemiTruck: ERROR - addVehicleDebug returned nil for " .. vehicleType)
                        end
                    end
                end
                break
            end
        end
    end)
end)
