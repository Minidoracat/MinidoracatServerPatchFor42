require "ArcadiaRefillablePropane_Shared"

-- B42.20 loads media/lua/server on connected clients too. Only the authority
-- may initialize depot state, change item fuel, or transmit object modData.
if isClient() then return end

ArcadiaRefillablePropaneServer = ArcadiaRefillablePropaneServer or {}

local Server = ArcadiaRefillablePropaneServer
local Depot = ArcadiaRefillablePropane

local function randomUnit()
    if ZombRand then return ZombRand(1000000) / 999999.0 end
    return math.random()
end

local function findPlayerItem(player, itemId)
    local requestedId = tonumber(itemId)
    if not requestedId then return nil end
    local items = player:getInventory():getAllEvalRecurse(function(item)
        return item and item:getID() == requestedId
    end)
    if not items or items:isEmpty() then return nil end
    local item = items:get(0)
    if not player:getInventory():containsRecursive(item) then return nil end
    return item
end

local function sendReply(player, command, args)
    args = args or {}
    args.playerOnlineId = player:getOnlineID()
    args.playerNum = player:getPlayerNum()

    if not isServer() and player:isLocalPlayer() then
        if ArcadiaRefillablePropaneClient and
            ArcadiaRefillablePropaneClient.receiveCommand then
            ArcadiaRefillablePropaneClient.receiveCommand(command, args)
        end
        return
    end
    sendServerCommand(player, Depot.NET_MODULE, command, args)
end

local function sendError(player, key)
    sendReply(player, "error", { key = key })
end

local function syncItem(item)
    item:updateWeight()
    item:syncItemFields()
    sendItemStats(item)
end

local function setVehicleAmount(vehicle, part, amount)
    local capacity = Depot.getVehiclePropaneCapacity(part)
    local normalized = math.max(0, math.min(capacity, amount))
    part:setContainerContentAmount(normalized)
    local syncPart = Depot.getVirtualFilibusterTankBackingPart(part) or part
    vehicle:transmitPartModData(syncPart)
    -- Filibuster uses this exact broadcast to keep FRPropaneTank amounts in
    -- sync on every multiplayer client. Reuse it without replacing or
    -- monkey-patching any function in the original mod.
    if isServer() and not Depot.isVirtualFilibusterTankTwo(part) then
        sendServerCommand('FR_UpdateParts', 'FR_FuelTankAmountClient', {
            partTankID = part:getId(),
            sourceVehicleID = vehicle:getId(),
            tankAmount = normalized,
        })
    end
end

local function sendVehicleUpdated(player, part, transferred, direction)
    sendReply(player, "vehicleUpdated", {
        transferred = transferred,
        stored = Depot.getVehiclePropaneAmount(part),
        capacity = Depot.getVehiclePropaneCapacity(part),
        direction = direction,
    })
end

function Server.ensureDepot(object)
    object = Depot.resolveDepotObject(object)
    if not Depot.isDepotObject(object) then return false end
    local data = Depot.getData(object)
    if not data then return false end

    local changed = false
    if data[Depot.MODDATA_MARKER] ~= true then
        data[Depot.MODDATA_MARKER] = true
        changed = true
    end
    if tonumber(data[Depot.MODDATA_VERSION]) ~= Depot.DATA_VERSION then
        data[Depot.MODDATA_VERSION] = Depot.DATA_VERSION
        changed = true
    end
    local capacity = Depot.getCapacity(object)
    if data[Depot.MODDATA_AMOUNT] == nil then
        data[Depot.MODDATA_AMOUNT] = Depot.calculateInitialAmount(
            randomUnit(),
            randomUnit(),
            object
        )
        changed = true
    else
        local normalized = math.max(
            0,
            math.min(capacity, tonumber(data[Depot.MODDATA_AMOUNT]) or 0)
        )
        if Depot.isInfinite() then normalized = capacity end
        if normalized ~= data[Depot.MODDATA_AMOUNT] then
            data[Depot.MODDATA_AMOUNT] = normalized
            changed = true
        end
    end
    if data[Depot.MODDATA_REVISION] == nil then
        data[Depot.MODDATA_REVISION] = 0
        changed = true
    end
    if changed then object:transmitModData() end
    return true
end

function Server.completeTimedAction(player, object, itemId)
    object = Depot.resolveDepotObject(object)
    if not player or not object or not Server.ensureDepot(object) then
        if player then sendError(player, "UI_RPT_NotReady") end
        return false
    end
    if object:getObjectIndex() == -1 or
        not Depot.isPlayerAdjacent(player, object) then
        sendError(player, "UI_RPT_TooFar")
        return false
    end

    local item = findPlayerItem(player, itemId)
    if not item or not Depot.getTargetKind(item) then
        sendError(player, "UI_RPT_InvalidTarget")
        return false
    end

    local data = Depot.getData(object)
    local infinite = Depot.isInfinite()
    local capacity = Depot.getCapacity(object)
    local storedAmount = infinite and capacity or data[Depot.MODDATA_AMOUNT]
    local plan = Depot.makeTransferPlan(item, storedAmount)
    if not plan or plan.transferredUnits <= Depot.MIN_TRANSFER then
        if Depot.getStoredAmount(object) <= Depot.MIN_TRANSFER then
            sendError(player, "UI_RPT_Empty")
        else
            sendError(player, "UI_RPT_AlreadyFull")
        end
        return false
    end

    item:setUsedDelta(plan.targetFraction)
    syncItem(item)

    data[Depot.MODDATA_AMOUNT] = infinite and capacity or plan.remainingUnits
    data[Depot.MODDATA_REVISION] = Depot.getRevision(object) + 1
    object:transmitModData()

    sendReply(player, "refilled", {
        itemId = item:getID(),
        itemName = item:getDisplayName(),
        transferred = plan.transferredUnits,
        stored = data[Depot.MODDATA_AMOUNT],
        capacity = capacity,
        infinite = infinite,
    })
    return true
end

function Server.completeVehicleToItem(player, vehicle, partId, itemId)
    local part = Depot.getFilibusterPropanePart(vehicle, partId)
    if not player or not part then
        if player then sendError(player, "UI_RPT_VehicleNotReady") end
        return false
    end
    if not Depot.isPlayerAdjacentToVehiclePart(player, part) then
        sendError(player, "UI_RPT_VehicleTooFar")
        return false
    end

    local item = findPlayerItem(player, itemId)
    if not item or not Depot.getTargetKind(item) then
        sendError(player, "UI_RPT_InvalidTarget")
        return false
    end

    local fullCost = Depot.getTargetFullCost(item)
    local currentFraction = Depot.getTargetFraction(item)
    local missing = math.max(0, (1.0 - currentFraction) * fullCost)
    local availableVehicle = Depot.getVehiclePropaneAmount(part)
    local availableDepot = Depot.vehiclePropaneToDepotUnits(availableVehicle)
    local transferred = math.min(missing, availableDepot)
    if transferred <= Depot.MIN_TRANSFER then
        if availableVehicle <= Depot.MIN_TRANSFER then
            sendError(player, "UI_RPT_VehicleEmpty")
        else
            sendError(player, "UI_RPT_AlreadyFull")
        end
        return false
    end

    item:setUsedDelta(math.min(1.0, currentFraction + transferred / fullCost))
    syncItem(item)
    setVehicleAmount(
        vehicle,
        part,
        availableVehicle - Depot.depotPropaneToVehicleUnits(transferred)
    )

    sendReply(player, "refilled", {
        itemId = item:getID(),
        itemName = item:getDisplayName(),
        transferred = transferred,
        stored = Depot.getVehiclePropaneAmount(part),
        capacity = Depot.getVehiclePropaneCapacity(part),
        infinite = false,
    })
    return true
end

function Server.completeItemToVehicle(player, vehicle, partId, itemId)
    local part = Depot.getFilibusterPropanePart(vehicle, partId)
    if not player or not part then
        if player then sendError(player, "UI_RPT_VehicleNotReady") end
        return false
    end
    if not Depot.isPlayerAdjacentToVehiclePart(player, part) then
        sendError(player, "UI_RPT_VehicleTooFar")
        return false
    end

    local item = findPlayerItem(player, itemId)
    if not item or not Depot.getTargetKind(item) then
        sendError(player, "UI_RPT_InvalidTarget")
        return false
    end

    local fullCost = Depot.getTargetFullCost(item)
    local available = Depot.getItemStoredUnits(item)
    local missingVehicle = Depot.getVehiclePropaneMissingUnits(part)
    local missingDepot = Depot.vehiclePropaneToDepotUnits(missingVehicle)
    local transferred = math.min(available, missingDepot)
    if transferred <= Depot.MIN_TRANSFER then
        if missingVehicle <= Depot.MIN_TRANSFER then
            sendError(player, "UI_RPT_VehicleAlreadyFull")
        else
            sendError(player, "UI_RPT_ItemEmpty")
        end
        return false
    end

    item:setUsedDelta(math.max(0, (available - transferred) / fullCost))
    syncItem(item)
    setVehicleAmount(
        vehicle,
        part,
        Depot.getVehiclePropaneAmount(part) +
            Depot.depotPropaneToVehicleUnits(transferred)
    )
    sendVehicleUpdated(player, part, transferred, "item_to_vehicle")
    return true
end

function Server.completeDepotToVehicle(player, object, vehicle, partId)
    object = Depot.resolveDepotObject(object)
    local part = Depot.getFilibusterPropanePart(vehicle, partId)
    if not player or not object or not part or not Server.ensureDepot(object) then
        if player then sendError(player, "UI_RPT_NotReady") end
        return false
    end
    if object:getObjectIndex() == -1 or
        not Depot.isPlayerAdjacent(player, object) or
        not Depot.isVehicleNearDepot(vehicle, object) then
        sendError(player, "UI_RPT_TooFar")
        return false
    end

    local data = Depot.getData(object)
    local infinite = Depot.isInfinite()
    local depotCapacity = Depot.getCapacity(object)
    local stored = infinite and depotCapacity or data[Depot.MODDATA_AMOUNT]
    local missingVehicle = Depot.getVehiclePropaneMissingUnits(part)
    local transferred = math.min(
        Depot.vehiclePropaneToDepotUnits(missingVehicle),
        stored
    )
    if transferred <= Depot.MIN_TRANSFER then
        if stored <= Depot.MIN_TRANSFER then
            sendError(player, "UI_RPT_Empty")
        else
            sendError(player, "UI_RPT_VehicleAlreadyFull")
        end
        return false
    end

    setVehicleAmount(
        vehicle,
        part,
        Depot.getVehiclePropaneAmount(part) +
            Depot.depotPropaneToVehicleUnits(transferred)
    )
    data[Depot.MODDATA_AMOUNT] = infinite and depotCapacity or
        math.max(0, stored - transferred)
    data[Depot.MODDATA_REVISION] = Depot.getRevision(object) + 1
    object:transmitModData()
    sendVehicleUpdated(player, part, transferred, "depot_to_vehicle")
    return true
end

-- Tank 2 is an integrated virtual reservoir stored in Tank 1's part modData.
-- It exists only for the exact Filibuster propane vehicle while that mod is
-- active, requires no second Mod ID, and begins empty exactly once.
function Server.initializeFilibusterTankTwo(vehicle)
    local part = Depot.getFilibusterPropanePart(
        vehicle,
        Depot.FILIBUSTER_PROPANE_TANK_TWO_ID
    )
    if not part or not part.getModData then return end
    local data = part:getModData()
    if data[Depot.FILIBUSTER_TANK_TWO_INITIALIZED_KEY] then return end
    data[Depot.FILIBUSTER_TANK_TWO_INITIALIZED_KEY] = true
    setVehicleAmount(vehicle, part, 0)
end

function Server.onLoadGridSquare(square)
    local objects = square and square:getObjects() or nil
    if not objects then return end
    for index = 0, objects:size() - 1 do
        local object = objects:get(index)
        if Depot.isPersistentAnchorObject(object) then
            Server.ensureDepot(object)
        end
    end
    local vehicle = square.getVehicleContainer and
        square:getVehicleContainer() or nil
    if vehicle then Server.initializeFilibusterTankTwo(vehicle) end
end

if Events and Events.LoadGridsquare then
    Events.LoadGridsquare.Add(Server.onLoadGridSquare)
end

return Server
