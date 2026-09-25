MirageWardrobeCore = MirageWardrobeCore or {}
local NETWORK_BUILD = "20260817-context-menu-release"
if MirageWardrobeCore.networkBuild ~= NETWORK_BUILD then
    MirageWardrobeCore.networkBuild = NETWORK_BUILD
    print("[MirageWardrobe] Network build=" .. NETWORK_BUILD)
end
MirageWardrobeCore.APPEARANCE_MODDATA_KEY = MirageWardrobeCore.APPEARANCE_MODDATA_KEY or "MirageWardrobeTransmogData"
MirageWardrobeCore.NETWORK_MODULE = MirageWardrobeCore.NETWORK_MODULE or "MirageWardrobeTransmog"
MirageWardrobeCore.PRESET_MODDATA_KEY = MirageWardrobeCore.PRESET_MODDATA_KEY or "MirageWardrobeOutfitPresetData"
MirageWardrobeCore.COLLECTION_MODDATA_KEY =
        MirageWardrobeCore.COLLECTION_MODDATA_KEY or "MirageWardrobeCollectionData"
MirageWardrobeCore.RULES_MODDATA_KEY =
        MirageWardrobeCore.RULES_MODDATA_KEY or "MirageWardrobeGameplayRulesData"
MirageWardrobeCore.CHARACTER_COLLECTION_KEY =
        MirageWardrobeCore.CHARACTER_COLLECTION_KEY or "mirageWardrobeCollection"
MirageWardrobeCore.serverClientOrder = MirageWardrobeCore.serverClientOrder or {}
MirageWardrobeCore.serverPresetClientOrder = MirageWardrobeCore.serverPresetClientOrder or {}
MirageWardrobeCore.MAX_OUTFIT_PRESETS = MirageWardrobeCore.MAX_OUTFIT_PRESETS or 32
MirageWardrobeCore.MAX_OUTFIT_PRESET_NAME_BYTES = MirageWardrobeCore.MAX_OUTFIT_PRESET_NAME_BYTES or 96
MirageWardrobeCore.MAX_OUTFIT_PRESET_SLOT_ENTRIES = MirageWardrobeCore.MAX_OUTFIT_PRESET_SLOT_ENTRIES or 128
MirageWardrobeCore.MAX_OUTFIT_PRESET_HIDDEN_ENTRIES = MirageWardrobeCore.MAX_OUTFIT_PRESET_HIDDEN_ENTRIES or 128
MirageWardrobeCore.MAX_OUTFIT_PRESET_TOTAL_ENTRIES = MirageWardrobeCore.MAX_OUTFIT_PRESET_TOTAL_ENTRIES or 1024
MirageWardrobeCore.MAX_OUTFIT_PRESET_VALUE_BYTES = MirageWardrobeCore.MAX_OUTFIT_PRESET_VALUE_BYTES or 256
MirageWardrobeCore.MAX_SLOT_VARIANT_ENTRIES = MirageWardrobeCore.MAX_SLOT_VARIANT_ENTRIES or 128
MirageWardrobeCore.MAX_TEXTURE_VARIANT_INDEX = MirageWardrobeCore.MAX_TEXTURE_VARIANT_INDEX or 127
MirageWardrobeCore.MAX_STATE_TRANSMOG_ENTRIES = MirageWardrobeCore.MAX_STATE_TRANSMOG_ENTRIES or 256
MirageWardrobeCore.MAX_STATE_SLOT_TRANSMOG_ENTRIES =
        MirageWardrobeCore.MAX_STATE_SLOT_TRANSMOG_ENTRIES or 128
MirageWardrobeCore.MAX_STATE_HIDDEN_ENTRIES = MirageWardrobeCore.MAX_STATE_HIDDEN_ENTRIES or 128
MirageWardrobeCore.MAX_STATE_ORIGINAL_CLOTHING_ENTRIES =
        MirageWardrobeCore.MAX_STATE_ORIGINAL_CLOTHING_ENTRIES or 128
MirageWardrobeCore.MAX_STATE_WORN_VISUAL_ENTRIES =
        MirageWardrobeCore.MAX_STATE_WORN_VISUAL_ENTRIES or 128
MirageWardrobeCore.MAX_STATE_TOTAL_ENTRIES = MirageWardrobeCore.MAX_STATE_TOTAL_ENTRIES or 512
MirageWardrobeCore.MAX_CLIENT_SEQUENCE = MirageWardrobeCore.MAX_CLIENT_SEQUENCE or 2147483647
MirageWardrobeCore.MAX_SERVER_ORDER_ACCOUNTS = MirageWardrobeCore.MAX_SERVER_ORDER_ACCOUNTS or 512
MirageWardrobeCore.GAMEPLAY_DISCOVER_MIN_INTERVAL_MS =
        MirageWardrobeCore.GAMEPLAY_DISCOVER_MIN_INTERVAL_MS or 250
MirageWardrobeCore.serverOrderTouch = MirageWardrobeCore.serverOrderTouch or 0
local SLOT_HIDDEN_PREFIX = "slot:"
MirageWardrobeCore.ORIGINAL_CLOTHING_OVERRIDES_KEY =
        MirageWardrobeCore.ORIGINAL_CLOTHING_OVERRIDES_KEY or
        "mirageWardrobeOriginalClothingOverrides"
MirageWardrobeCore.ORIGINAL_CLOTHING_HIDDEN =
        MirageWardrobeCore.ORIGINAL_CLOTHING_HIDDEN or "hidden"
MirageWardrobeCore.ORIGINAL_CLOTHING_SHOWN =
        MirageWardrobeCore.ORIGINAL_CLOTHING_SHOWN or "shown"
local CLEAN_APPEARANCE_OPTION_KEYS = { "blood", "holes", "patches" }
local CLEAN_APPEARANCE_OPTION_DEFAULTS = {
    blood = false,
    holes = true,
    patches = true,
}

local function copyCleanAppearanceOptions(source, strict)
    if source ~= nil and type(source) ~= "table" then
        if strict then return nil end
        source = nil
    end
    local result = {}
    for _, key in ipairs(CLEAN_APPEARANCE_OPTION_KEYS) do
        local value = nil
        if source then value = source[key] end
        if value == nil then
            result[key] = CLEAN_APPEARANCE_OPTION_DEFAULTS[key]
        elseif type(value) == "boolean" then
            result[key] = value == true
        elseif strict then
            return nil
        else
            result[key] = CLEAN_APPEARANCE_OPTION_DEFAULTS[key]
        end
    end
    return result
end

local function isSafeStateString(value)
    return type(value) == "string" and value ~= "" and
            string.len(value) <= MirageWardrobeCore.MAX_OUTFIT_PRESET_VALUE_BYTES and
            not string.find(value, "%c")
end

local function consumeStateBudget(budget)
    if type(budget) ~= "table" then return true end
    budget.count = (budget.count or 0) + 1
    return budget.count <= MirageWardrobeCore.MAX_STATE_TOTAL_ENTRIES
end

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and
            value ~= math.huge and value ~= -math.huge
end

local function copyStringMap(source, strict, limit, budget)
    local result = {}
    if source == nil then return result end
    if type(source) ~= "table" then return strict and nil or result end
    limit = limit or MirageWardrobeCore.MAX_STATE_TRANSMOG_ENTRIES
    local scanned = 0
    for key, value in pairs(source) do
        scanned = scanned + 1
        if scanned > limit or not consumeStateBudget(budget) then
            if strict then return nil end
            break
        end
        if isSafeStateString(key) and isSafeStateString(value) then
            result[key] = value
        elseif strict then
            return nil
        end
    end
    return result
end

local function copyBooleanMap(source, strict, limit, budget)
    local result = {}
    if source == nil then return result end
    if type(source) ~= "table" then return strict and nil or result end
    limit = limit or MirageWardrobeCore.MAX_STATE_HIDDEN_ENTRIES
    local scanned = 0
    for key, value in pairs(source) do
        scanned = scanned + 1
        if scanned > limit or not consumeStateBudget(budget) then
            if strict then return nil end
            break
        end
        if isSafeStateString(key) and type(value) == "boolean" then
            result[key] = value
        elseif strict then
            return nil
        end
    end
    return result
end

local function copyOriginalClothingOverrides(source, strict, budget)
    local result = {}
    if source == nil then return result end
    if type(source) ~= "table" then return strict and nil or result end
    local scanned = 0
    for slot, value in pairs(source) do
        scanned = scanned + 1
        if scanned > MirageWardrobeCore.MAX_STATE_ORIGINAL_CLOTHING_ENTRIES or
                not consumeStateBudget(budget) then
            if strict then return nil end
            break
        end
        local valid = isSafeStateString(slot) and
                (value == MirageWardrobeCore.ORIGINAL_CLOTHING_HIDDEN or
                        value == MirageWardrobeCore.ORIGINAL_CLOTHING_SHOWN)
        if valid then
            result[slot] = value
        elseif strict then
            return nil
        end
    end
    return result
end

local function copyWornVisualSlots(source, strict, budget)
    local function invalid()
        if strict then return nil end
        return {}
    end
    if source == nil then return {} end
    if type(source) ~= "table" then return invalid() end

    local limit = MirageWardrobeCore.MAX_STATE_WORN_VISUAL_ENTRIES
    local indexed = {}
    local count = 0
    for index, record in pairs(source) do
        if type(index) ~= "number" or index ~= math.floor(index) or
                index < 1 or index > limit or indexed[index] ~= nil or
                type(record) ~= "table" then
            return invalid()
        end
        local fieldCount = 0
        for key in pairs(record) do
            fieldCount = fieldCount + 1
            if key ~= "itemType" and key ~= "slot" and
                    key ~= "occurrence" then
                return invalid()
            end
        end
        if fieldCount ~= 3 or not isSafeStateString(record.itemType) or
                not isSafeStateString(record.slot) or
                not isFiniteNumber(record.occurrence) or
                record.occurrence ~= math.floor(record.occurrence) or
                record.occurrence < 1 or record.occurrence > limit then
            return invalid()
        end
        indexed[index] = record
        count = count + 1
    end
    if count > limit then return invalid() end

    local result = {}
    local occurrences = {}
    for index = 1, count do
        local record = indexed[index]
        if not record or not consumeStateBudget(budget) then return invalid() end
        occurrences[record.itemType] =
                (occurrences[record.itemType] or 0) + 1
        if record.occurrence ~= occurrences[record.itemType] then
            return invalid()
        end
        result[index] = {
            itemType = record.itemType,
            slot = record.slot,
            occurrence = record.occurrence,
        }
    end
    return result
end

local function normalizeSlotVariant(source)
    if type(source) ~= "table" then return nil end
    local result = {}
    local hasTexture = source.textureMode ~= nil or source.textureIndex ~= nil
    if hasTexture then
        if (source.textureMode ~= "choice" and source.textureMode ~= "base") or
                not isFiniteNumber(source.textureIndex) or source.textureIndex < 0 or
                source.textureIndex > MirageWardrobeCore.MAX_TEXTURE_VARIANT_INDEX or
                source.textureIndex ~= math.floor(source.textureIndex) then
            return nil
        end
        result.textureMode = source.textureMode
        result.textureIndex = source.textureIndex
    end

    local hasTint = source.tintR ~= nil or source.tintG ~= nil or source.tintB ~= nil
    if hasTint then
        if not isFiniteNumber(source.tintR) or not isFiniteNumber(source.tintG) or
                not isFiniteNumber(source.tintB) or source.tintR < 0 or source.tintR > 1 or
                source.tintG < 0 or source.tintG > 1 or source.tintB < 0 or source.tintB > 1 then
            return nil
        end
        result.tintR = source.tintR
        result.tintG = source.tintG
        result.tintB = source.tintB
    end
    if not hasTexture and not hasTint then return nil end
    return result
end

local function copySlotVariantMap(source, strict, allowedSlots, budget)
    local result = {}
    if source == nil then return result end
    if type(source) ~= "table" then return strict and nil or result end

    local count = 0
    for slot, variant in pairs(source) do
        count = count + 1
        if count > MirageWardrobeCore.MAX_SLOT_VARIANT_ENTRIES or
                not consumeStateBudget(budget) then
            if strict then return nil end
            break
        end
        local normalized = normalizeSlotVariant(variant)
        local slotValid = isSafeStateString(slot) and
                (type(allowedSlots) ~= "table" or type(allowedSlots[slot]) == "string")
        if not slotValid or not normalized then
            if strict then return nil end
        else
            result[slot] = normalized
        end
    end
    return result
end

local function normalizePresetName(name)
    if type(name) ~= "string" then return nil end
    local trimmed = string.match(name, "^%s*(.-)%s*$")
    if not trimmed or trimmed == "" or trimmed ~= name then return nil end
    if string.len(trimmed) > MirageWardrobeCore.MAX_OUTFIT_PRESET_NAME_BYTES then return nil end
    if string.find(trimmed, "%c") then return nil end
    return trimmed
end

local function isSafePresetValue(value)
    return type(value) == "string" and value ~= "" and
            string.len(value) <= MirageWardrobeCore.MAX_OUTFIT_PRESET_VALUE_BYTES and
            not string.find(value, "%c")
end

local function getSlotFromHiddenKey(key)
    if type(key) ~= "string" or string.sub(key, 1, string.len(SLOT_HIDDEN_PREFIX)) ~=
            SLOT_HIDDEN_PREFIX then return nil end
    local slot = string.sub(key, string.len(SLOT_HIDDEN_PREFIX) + 1)
    if slot == "" then return nil end
    return slot
end

local function copyPreset(source)
    if type(source) ~= "table" or type(source.slotTransmogTable) ~= "table" or
            type(source.hiddenItemsTable) ~= "table" then return nil end

    local result = {
        slotTransmogTable = {},
        slotVariantTable = {},
        hiddenItemsTable = {},
        originalClothingOverrides = {},
    }
    if source.cleanAppearance ~= nil then
        if type(source.cleanAppearance) ~= "boolean" then return nil end
        result.cleanAppearance = source.cleanAppearance == true
    end
    result.cleanAppearanceOptions = copyCleanAppearanceOptions(
            source.cleanAppearanceOptions, true)
    if not result.cleanAppearanceOptions then return nil end
    if source.hideOriginalClothing ~= nil then
        if type(source.hideOriginalClothing) ~= "boolean" then return nil end
        result.hideOriginalClothing = source.hideOriginalClothing == true
    end
    local slotCount = 0
    local hiddenCount = 0
    local hiddenResultCount = 0

    local function addHiddenSlot(slot)
        local key = SLOT_HIDDEN_PREFIX .. slot
        if result.hiddenItemsTable[key] ~= true then
            hiddenResultCount = hiddenResultCount + 1
            if hiddenResultCount > MirageWardrobeCore.MAX_OUTFIT_PRESET_HIDDEN_ENTRIES then return false end
            result.hiddenItemsTable[key] = true
        end
        return true
    end

    for slot, donorFullName in pairs(source.slotTransmogTable) do
        slotCount = slotCount + 1
        if slotCount > MirageWardrobeCore.MAX_OUTFIT_PRESET_SLOT_ENTRIES or
                not isSafePresetValue(slot) or not isSafePresetValue(donorFullName) then
            return nil
        end
        if donorFullName == "Base.Belt2" then
            if not addHiddenSlot(slot) then return nil end
        else
            result.slotTransmogTable[slot] = donorFullName
        end
    end
    result.slotVariantTable = copySlotVariantMap(source.slotVariantTable, true,
            result.slotTransmogTable)
    if not result.slotVariantTable then return nil end
    result.originalClothingOverrides = copyOriginalClothingOverrides(
            source.originalClothingOverrides, true)
    if not result.originalClothingOverrides then return nil end

    for key, value in pairs(source.hiddenItemsTable) do
        hiddenCount = hiddenCount + 1
        local slot = getSlotFromHiddenKey(key)
        if hiddenCount > MirageWardrobeCore.MAX_OUTFIT_PRESET_HIDDEN_ENTRIES or value ~= true or
                not slot or not isSafePresetValue(slot) then
            return nil
        end
        if not addHiddenSlot(slot) then return nil end
    end
    return result
end

local function countPresetEntries(preset)
    local count = 0
    if type(preset) ~= "table" then return count end
    if type(preset.slotTransmogTable) == "table" then
        for _ in pairs(preset.slotTransmogTable) do count = count + 1 end
    end
    if type(preset.slotVariantTable) == "table" then
        for _ in pairs(preset.slotVariantTable) do count = count + 1 end
    end
    if type(preset.hiddenItemsTable) == "table" then
        for _ in pairs(preset.hiddenItemsTable) do count = count + 1 end
    end
    if type(preset.originalClothingOverrides) == "table" then
        for _ in pairs(preset.originalClothingOverrides) do count = count + 1 end
    end
    return count
end

local function copyPresetLibrary(source, strict)
    if type(source) ~= "table" then return strict and nil or {} end

    local result = {}
    local count = 0
    local scanned = 0
    local totalEntries = 0
    for name, preset in pairs(source) do
        scanned = scanned + 1
        if scanned > MirageWardrobeCore.MAX_OUTFIT_PRESETS * 4 then
            if strict then return nil end
            break
        end

        local normalizedName = normalizePresetName(name)
        local snapshot = normalizedName and copyPreset(preset) or nil
        if not normalizedName or not snapshot then
            if strict then return nil end
        else
            local presetEntries = countPresetEntries(snapshot)
            if totalEntries + presetEntries > MirageWardrobeCore.MAX_OUTFIT_PRESET_TOTAL_ENTRIES then
                if strict then return nil end
            else
                count = count + 1
                if count > MirageWardrobeCore.MAX_OUTFIT_PRESETS then
                    if strict then return nil end
                    break
                end
                result[normalizedName] = snapshot
                totalEntries = totalEntries + presetEntries
            end
        end
    end
    return result
end

local function countEntries(source)
    local count = 0
    if type(source) ~= "table" then return count end
    for _ in pairs(source) do count = count + 1 end
    return count
end

local function countPresetLibraryEntries(source)
    local count = 0
    if type(source) ~= "table" then return count end
    for _, preset in pairs(source) do
        count = count + countPresetEntries(preset)
    end
    return count
end

local function copyState(state, strict)
    if type(state) ~= "table" then
        if strict then return nil end
        return { transmogTable = {}, slotTransmogTable = {}, slotVariantTable = {},
            hiddenItemsTable = {}, originalClothingOverrides = {}, wornVisualSlots = {},
            cleanAppearance = false,
            cleanAppearanceOptions = copyCleanAppearanceOptions(nil, false),
            hideOriginalClothing = false }
    end

    local budget = { count = 0 }
    local transmogSource = state.transmogTable
    if not strict and transmogSource == nil then transmogSource = state end
    local transmogTable = copyStringMap(transmogSource, strict,
            MirageWardrobeCore.MAX_STATE_TRANSMOG_ENTRIES, budget)
    if not transmogTable then return nil end
    local slotTransmogTable = copyStringMap(state.slotTransmogTable, strict,
            MirageWardrobeCore.MAX_STATE_SLOT_TRANSMOG_ENTRIES, budget)
    if not slotTransmogTable then return nil end
    local slotVariantTable = copySlotVariantMap(state.slotVariantTable, strict,
            slotTransmogTable, budget)
    if not slotVariantTable then return nil end
    local hiddenItemsTable = copyBooleanMap(state.hiddenItemsTable, strict,
            MirageWardrobeCore.MAX_STATE_HIDDEN_ENTRIES, budget)
    if not hiddenItemsTable then return nil end
    local originalClothingOverrides = copyOriginalClothingOverrides(
            state.originalClothingOverrides, strict, budget)
    if not originalClothingOverrides then return nil end
    local wornVisualSlots = copyWornVisualSlots(
            state.wornVisualSlots, strict, budget)
    if not wornVisualSlots then return nil end
    local cleanAppearanceOptions = copyCleanAppearanceOptions(
            state.cleanAppearanceOptions, strict)
    if not cleanAppearanceOptions then return nil end
    return {
        transmogTable = transmogTable,
        slotTransmogTable = slotTransmogTable,
        slotVariantTable = slotVariantTable,
        hiddenItemsTable = hiddenItemsTable,
        originalClothingOverrides = originalClothingOverrides,
        wornVisualSlots = wornVisualSlots,
        cleanAppearance = state.cleanAppearance == true,
        cleanAppearanceOptions = cleanAppearanceOptions,
        hideOriginalClothing = state.hideOriginalClothing == true,
    }
end

local function copyPlayers(source)
    local result = {}
    if type(source) ~= "table" then return result end
    for playerKey, state in pairs(source) do
        if type(playerKey) == "string" and type(state) == "table" then
            result[playerKey] = copyState(state, false)
        end
    end
    return result
end

local function getPlayerConnection(player)
    if not player then return nil end
    if player.getOwner then
        local ok, owner = pcall(player.getOwner, player)
        if ok and owner then return owner end
    end
    return player
end

local function samePlayerConnection(left, right)
    if left == right then return true end
    local leftConnection = getPlayerConnection(left)
    local rightConnection = getPlayerConnection(right)
    return leftConnection ~= nil and leftConnection == rightConnection
end

local function isSafePresetSession(session)
    return type(session) == "string" and session ~= "" and string.len(session) <= 256 and
            not string.find(session, "%c")
end

local function isSafeNetworkKey(playerKey)
    return type(playerKey) == "string" and playerKey ~= "" and string.len(playerKey) <= 256 and
            not string.find(playerKey, "%c")
end

local function isSafeClientSequence(sequence)
    return isFiniteNumber(sequence) and sequence == math.floor(sequence) and
            sequence >= 1 and sequence <= MirageWardrobeCore.MAX_CLIENT_SEQUENCE
end

local function isStoredClientSequence(sequence)
    return isFiniteNumber(sequence) and sequence == math.floor(sequence) and
            sequence >= 0 and sequence <= MirageWardrobeCore.MAX_CLIENT_SEQUENCE
end

local function nextServerOrderTouch()
    local touch = MirageWardrobeCore.serverOrderTouch
    if not isStoredClientSequence(touch) or touch >= MirageWardrobeCore.MAX_CLIENT_SEQUENCE then
        for _, cache in ipairs({ MirageWardrobeCore.serverClientOrder,
                MirageWardrobeCore.serverPresetClientOrder }) do
            for _, order in pairs(cache) do
                if type(order) == "table" then order.touch = 0 end
            end
        end
        touch = 0
    end
    touch = touch + 1
    MirageWardrobeCore.serverOrderTouch = touch
    return touch
end

local function trimServerOrderCache(cache)
    local count = 0
    for _ in pairs(cache) do count = count + 1 end
    while count > MirageWardrobeCore.MAX_SERVER_ORDER_ACCOUNTS do
        local oldestKey = nil
        local oldestTouch = nil
        for key, order in pairs(cache) do
            local touch = type(order) == "table" and order.touch or -1
            if not isStoredClientSequence(touch) then touch = -1 end
            if oldestKey == nil or touch < oldestTouch or
                    (touch == oldestTouch and tostring(key) < tostring(oldestKey)) then
                oldestKey = key
                oldestTouch = touch
            end
        end
        if oldestKey == nil then break end
        cache[oldestKey] = nil
        count = count - 1
    end
end

local function storeServerOrder(cache, playerKey, session, sequence)
    local order = {
        session = session,
        sequence = sequence,
        touch = nextServerOrderTouch(),
    }
    cache[playerKey] = order
    trimServerOrderCache(cache)
    return order
end

local function touchServerOrder(order)
    order.touch = nextServerOrderTouch()
    return order
end

local function sanitizeServerOrderCache(source)
    local candidates = {}
    if type(source) == "table" then
        for playerKey, order in pairs(source) do
            if isSafeNetworkKey(playerKey) and type(order) == "table" and
                    isSafePresetSession(order.session) and
                    isStoredClientSequence(order.sequence) then
                local touch = isStoredClientSequence(order.touch) and order.touch or 0
                candidates[#candidates + 1] = {
                    playerKey = playerKey, session = order.session,
                    sequence = order.sequence, touch = touch,
                }
            end
        end
    end
    table.sort(candidates, function(left, right)
        if left.touch ~= right.touch then return left.touch > right.touch end
        return left.playerKey < right.playerKey
    end)
    local result = {}
    for index = 1, math.min(#candidates, MirageWardrobeCore.MAX_SERVER_ORDER_ACCOUNTS) do
        local sourceOrder = candidates[index]
        result[sourceOrder.playerKey] = {
            session = sourceOrder.session,
            sequence = sourceOrder.sequence,
            touch = sourceOrder.touch,
        }
        if sourceOrder.touch > MirageWardrobeCore.serverOrderTouch then
            MirageWardrobeCore.serverOrderTouch = sourceOrder.touch
        end
    end
    return result
end

if not isStoredClientSequence(MirageWardrobeCore.serverOrderTouch) then
    MirageWardrobeCore.serverOrderTouch = 0
end
MirageWardrobeCore.serverClientOrder = sanitizeServerOrderCache(MirageWardrobeCore.serverClientOrder)
MirageWardrobeCore.serverPresetClientOrder = sanitizeServerOrderCache(MirageWardrobeCore.serverPresetClientOrder)

local function findCurrentOnlinePlayer(playerKey)
    if not getOnlinePlayers then return nil end
    local ok, players = pcall(getOnlinePlayers)
    if not ok or not players then return nil end
    local sizeOk, size = pcall(players.size, players)
    if not sizeOk or type(size) ~= "number" then return nil end
    for index = 0, size - 1 do
        local player = players:get(index)
        if player and player.getUsername and player:getUsername() == playerKey then
            return player
        end
    end
    return nil
end

local function clearPlayerAppearanceTracking(player)
    if not player then return end
    for _, tableName in ipairs({
        "cleanAppearancePending",
        "cleanAppearanceRendered",
        "appearanceWearSignatures",
        "activeAppearanceSnapshots",
        "appearanceRevisions",
        "appearanceCapturePlayers",
        "fixedTextureTrackingCache",
        "renderCompatibilityCache",
    }) do
        local tracked = MirageWardrobeCore[tableName]
        if type(tracked) == "table" then tracked[player] = nil end
    end
end

local function getNetworkAppliedBindings()
    if type(MirageWardrobeCore.networkAppliedBindings) ~= "table" then
        MirageWardrobeCore.networkAppliedBindings = {}
    end
    return MirageWardrobeCore.networkAppliedBindings
end

local function clearNetworkAppliedBindings()
    local bindings = getNetworkAppliedBindings()
    for _, binding in pairs(bindings) do
        if type(binding) == "table" then
            clearPlayerAppearanceTracking(binding.player)
        end
    end
    MirageWardrobeCore.networkAppliedBindings = {}
end

local function ensureNetworkAppliedBindingSession()
    local session = MirageWardrobeCore.networkSessionId
    if MirageWardrobeCore.networkAppliedBindingSessionKnown ~= true or
            MirageWardrobeCore.networkAppliedBindingSessionId ~= session then
        clearNetworkAppliedBindings()
        MirageWardrobeCore.networkAppliedBindingSessionKnown = true
        MirageWardrobeCore.networkAppliedBindingSessionId = session
    end
end

local function installNetworkSessionBindingReset()
    local beginSession = MirageWardrobeCore.beginNetworkSession
    if type(beginSession) ~= "function" then return false end
    if MirageWardrobeCore.networkAppliedBindingsBeginWrapper == beginSession then
        return true
    end

    local function wrappedBeginNetworkSession(...)
        clearNetworkAppliedBindings()
        MirageWardrobeCore.networkAppliedBindingSessionKnown = false
        MirageWardrobeCore.networkAppliedBindingSessionId = nil
        local result = beginSession(...)
        MirageWardrobeCore.networkAppliedBindingSessionKnown = true
        MirageWardrobeCore.networkAppliedBindingSessionId =
                MirageWardrobeCore.networkSessionId
        return result
    end

    MirageWardrobeCore.networkAppliedBindingsBeginWrapper =
            wrappedBeginNetworkSession
    MirageWardrobeCore.beginNetworkSession = wrappedBeginNetworkSession
    return true
end

local function getNetworkPlayerKey(player)
    if not player then return nil end
    if MirageWardrobeCore.getPlayerSyncKey then
        local ok, playerKey =
                pcall(MirageWardrobeCore.getPlayerSyncKey, player)
        if ok and isSafeNetworkKey(playerKey) then return playerKey end
    end
    if player.getUsername then
        local ok, playerKey = pcall(player.getUsername, player)
        if ok and isSafeNetworkKey(playerKey) then return playerKey end
    end
    return nil
end

local function getLocalPlayer()
    if not getPlayer then return nil end
    local ok, player = pcall(getPlayer)
    return ok and player or nil
end

local function rememberNetworkAppliedBinding(playerKey, player)
    if not isSafeNetworkKey(playerKey) or not player or
            player == getLocalPlayer() then
        return false
    end
    local state = type(MirageWardrobeCore.networkPlayerData) == "table" and
            MirageWardrobeCore.networkPlayerData[playerKey] or nil
    if type(state) ~= "table" then return false end
    getNetworkAppliedBindings()[playerKey] = {
        player = player,
        state = state,
        revision = type(MirageWardrobeCore.networkPlayerRevisions) == "table" and
                MirageWardrobeCore.networkPlayerRevisions[playerKey] or nil,
    }
    return true
end

local function copyNetworkPlayerStateIdentities()
    local result = {}
    local playerData = MirageWardrobeCore.networkPlayerData
    if type(playerData) ~= "table" then return result end
    for playerKey, state in pairs(playerData) do
        if isSafeNetworkKey(playerKey) and type(state) == "table" then
            result[playerKey] = state
        end
    end
    return result
end

local function collectOnlinePlayersByKey()
    if not getOnlinePlayers then return nil, false end
    local ok, players = pcall(getOnlinePlayers)
    if not ok or not players then return nil, false end
    local sizeOk, size = pcall(players.size, players)
    if not sizeOk or type(size) ~= "number" then return nil, false end

    local result = {}
    for index = 0, size - 1 do
        local playerOk, player = pcall(players.get, players, index)
        if not playerOk or not player then return nil, false end
        local playerKey = getNetworkPlayerKey(player)
        if not playerKey or (result[playerKey] and result[playerKey] ~= player) then
            return nil, false
        end
        result[playerKey] = player
    end
    return result, true
end

local function reconcileNetworkSnapshotBindings(previousStates)
    ensureNetworkAppliedBindingSession()
    local onlinePlayers, complete = collectOnlinePlayersByKey()
    if not complete then return end

    local localPlayer = getLocalPlayer()
    local playerData = type(MirageWardrobeCore.networkPlayerData) == "table" and
            MirageWardrobeCore.networkPlayerData or {}
    previousStates = type(previousStates) == "table" and previousStates or {}
    for playerKey, player in pairs(onlinePlayers) do
        local state = playerData[playerKey]
        if player ~= localPlayer and type(state) == "table" and
                state ~= previousStates[playerKey] then
            -- setNetworkSnapshot created a new sanitized state and, because
            -- this exact player is online, applied it before returning.
            rememberNetworkAppliedBinding(playerKey, player)
        end
    end
    MirageWardrobeCore.onMiniScoreboardUpdate()
end

MirageWardrobeCore.onMiniScoreboardUpdate = function ()
    if not isClient() then return end
    installNetworkSessionBindingReset()
    ensureNetworkAppliedBindingSession()

    local onlinePlayers, complete = collectOnlinePlayersByKey()
    if not complete then return end

    local bindings = getNetworkAppliedBindings()
    local playerData = type(MirageWardrobeCore.networkPlayerData) == "table" and
            MirageWardrobeCore.networkPlayerData or {}
    for playerKey, binding in pairs(bindings) do
        local onlinePlayer = onlinePlayers[playerKey]
        local cachedState = playerData[playerKey]
        if type(binding) ~= "table" or type(cachedState) ~= "table" or
                not onlinePlayer or binding.player ~= onlinePlayer then
            if type(binding) == "table" then
                clearPlayerAppearanceTracking(binding.player)
            end
            bindings[playerKey] = nil
        end
    end

    if not MirageWardrobeCore.applyNetworkState then return end
    local localPlayer = getLocalPlayer()
    for playerKey, player in pairs(onlinePlayers) do
        if player ~= localPlayer then
            local cachedState = playerData[playerKey]
            local binding = bindings[playerKey]
            if type(cachedState) == "table" and
                    (not binding or binding.player ~= player or
                            binding.state ~= cachedState) then
                local revision =
                        type(MirageWardrobeCore.networkPlayerRevisions) == "table" and
                                MirageWardrobeCore.networkPlayerRevisions[playerKey] or nil
                local ok, visualChanged, stateReady =
                        pcall(MirageWardrobeCore.applyNetworkState,
                                playerKey, cachedState, revision, false, player)
                local remembered = false
                if ok and stateReady == true then
                    remembered = rememberNetworkAppliedBinding(playerKey, player)
                end
            end
        end
    end
end

local function registerClientSession(playerKey, args, player)
    local session = type(args) == "table" and args.session or nil
    if not isSafePresetSession(session) then return nil end

    local order = MirageWardrobeCore.serverClientOrder[playerKey]
    if not order or order.session ~= session then
        order = storeServerOrder(MirageWardrobeCore.serverClientOrder, playerKey, session, 0)
    else
        touchServerOrder(order)
    end
    return order
end

local function acceptClientUpdate(playerKey, args, player)
    local session = type(args) == "table" and args._clientSession or nil
    local sequence = type(args) == "table" and args._clientSequence or nil
    local order = MirageWardrobeCore.serverClientOrder[playerKey]

    -- Compatibility with an older client is allowed only until a sequenced session
    -- has been established for this account. Partial or malformed sequence metadata
    -- is never treated as a legacy packet.
    if session == nil and sequence == nil then
        return order == nil
    end
    if not isSafePresetSession(session) or not isSafeClientSequence(sequence) then return false end
    -- Appearance reconnects must establish their new session with Request first.
    if not order or order.session ~= session then return false end

    if sequence <= order.sequence then return false end
    order.sequence = sequence
    touchServerOrder(order)
    return true
end

local function acceptGameplayDiscover(playerKey, args)
    local session = type(args) == "table" and args.session or nil
    local order = MirageWardrobeCore.serverClientOrder[playerKey]
    if not order or not isSafePresetSession(session) or order.session ~= session then
        return false
    end

    if getTimestampMs then
        local ok, now = pcall(getTimestampMs)
        if ok and isFiniteNumber(now) then
            local previous = order.gameplayDiscoverAt
            if isFiniteNumber(previous) and now >= previous and
                    now - previous < MirageWardrobeCore.GAMEPLAY_DISCOVER_MIN_INTERVAL_MS then
                return false
            end
            order.gameplayDiscoverAt = now
        end
    end
    return true
end

local function registerPresetClientSession(playerKey, args, player)
    local session = type(args) == "table" and args.session or nil
    if not isSafePresetSession(session) then return nil end

    local order = MirageWardrobeCore.serverPresetClientOrder[playerKey]
    if not order or order.session ~= session then
        order = storeServerOrder(MirageWardrobeCore.serverPresetClientOrder, playerKey, session, 0)
    else
        touchServerOrder(order)
    end
    return order
end

local function acceptPresetClientUpdate(playerKey, args, player)
    local session = type(args) == "table" and args._clientSession or nil
    local sequence = type(args) == "table" and args._clientSequence or nil
    if not isSafePresetSession(session) or not isSafeClientSequence(sequence) then
        return false
    end

    local order = MirageWardrobeCore.serverPresetClientOrder[playerKey]
    if not order or order.session ~= session then
        -- The authenticated current connection may save before its Request packet.
        -- The top-level online-player check rejects packets from an old connection.
        order = storeServerOrder(MirageWardrobeCore.serverPresetClientOrder,
                playerKey, session, 0)
    end

    if sequence <= order.sequence then return false end
    order.sequence = sequence
    touchServerOrder(order)
    return true
end

local function getPresetData()
    local data = ModData.getOrCreate(MirageWardrobeCore.PRESET_MODDATA_KEY)
    if type(data) ~= "table" then data = {} end
    return data
end

local function getStoredPresetLibrary(data, playerKey)
    local record = type(data) == "table" and data[playerKey] or nil
    if type(record) ~= "table" or type(record.presets) ~= "table" then
        return nil
    end
    return copyPresetLibrary(record.presets, false)
end

local function getGameplayEngine()
    return type(MirageWardrobeGameplay) == "table" and MirageWardrobeGameplay or nil
end

local function fallbackGameplayRules()
    return {
        accessMode = "all",
        unlockTrigger = "acquired",
        collectionScope = "character",
        variantMode = "item",
        nearbyRadius = 4,
        nearbySources = {
            onPerson = true,
            ground = true,
            containers = true,
            corpses = true,
            vehicles = true,
        },
        showLocked = true,
    }
end

local function fallbackGameplayCollection()
    return { schemaVersion = 1, items = {}, styles = {} }
end

local function sanitizeGameplayRules(source)
    local engine = getGameplayEngine()
    if engine and engine.sanitizeRules then
        local ok, rules = pcall(engine.sanitizeRules, source)
        if ok and type(rules) == "table" then return rules end
    end
    return fallbackGameplayRules()
end

local function sanitizeGameplayCollection(source)
    local engine = getGameplayEngine()
    if engine and engine.sanitizeCollection then
        local ok, collection = pcall(engine.sanitizeCollection, source)
        if ok and type(collection) == "table" then return collection end
    end
    return fallbackGameplayCollection()
end

local function newGameplayCollection()
    local engine = getGameplayEngine()
    if engine and engine.newCollection then
        local ok, collection = pcall(engine.newCollection)
        if ok and type(collection) == "table" then
            return sanitizeGameplayCollection(collection)
        end
    end
    return fallbackGameplayCollection()
end

local function getGameplayRulesData()
    local data = ModData.getOrCreate(MirageWardrobeCore.RULES_MODDATA_KEY)
    if type(data) ~= "table" then
        data = {}
        ModData.add(MirageWardrobeCore.RULES_MODDATA_KEY, data)
    end
    return data
end

local function getServerGameplayRules()
    local rulesData = getGameplayRulesData()
    local source = type(rulesData.rules) == "table" and rulesData.rules or nil
    local engine = getGameplayEngine()
    if not source and engine and engine.rulesFromSandbox then
        local ok, sandboxRules = pcall(engine.rulesFromSandbox)
        if ok and type(sandboxRules) == "table" then source = sandboxRules end
    end
    local rulesRevision = isFiniteNumber(rulesData.revision) and
            math.floor(rulesData.revision) or 0
    if rulesRevision < 0 then rulesRevision = 0 end
    if rulesRevision > MirageWardrobeCore.MAX_CLIENT_SEQUENCE then
        rulesRevision = MirageWardrobeCore.MAX_CLIENT_SEQUENCE
    end
    return sanitizeGameplayRules(source),
            rulesRevision
end

local function getGameplayCollectionData()
    local data = ModData.getOrCreate(MirageWardrobeCore.COLLECTION_MODDATA_KEY)
    if type(data) ~= "table" then data = {} end
    if not isFiniteNumber(data._revision) or data._revision < 0 then
        data._revision = 0
    else
        data._revision = math.min(MirageWardrobeCore.MAX_CLIENT_SEQUENCE,
                math.floor(data._revision))
    end
    if type(data.accounts) ~= "table" then data.accounts = {} end
    return data
end

local function getPlayerCharacterData(player)
    if not player or not player.getModData then return nil end
    local ok, data = pcall(player.getModData, player)
    if ok and type(data) == "table" then return data end
    return nil
end

local function getServerGameplayCollection(player, playerKey, rules)
    local collectionData = getGameplayCollectionData()
    local collection
    local characterData
    if rules.collectionScope == "account" then
        collection = collectionData.accounts[playerKey]
        -- Upgrade the early single-player layout, which stored account records
        -- directly under the authenticated username.
        if type(collection) ~= "table" and playerKey ~= "_revision" and
                playerKey ~= "accounts" then
            collection = collectionData[playerKey]
        end
        if type(collection) ~= "table" then collection = newGameplayCollection() end
        collection = sanitizeGameplayCollection(collection)
        collectionData.accounts[playerKey] = collection
    else
        characterData = getPlayerCharacterData(player)
        collection = characterData and
                characterData[MirageWardrobeCore.CHARACTER_COLLECTION_KEY] or nil
        if type(collection) ~= "table" then collection = newGameplayCollection() end
        collection = sanitizeGameplayCollection(collection)
        if characterData then
            characterData[MirageWardrobeCore.CHARACTER_COLLECTION_KEY] = collection
        end
    end
    return collection, collectionData, characterData
end

local function storeServerGameplayCollection(playerKey, rules, collection,
        collectionData, characterData, changed)
    collection = sanitizeGameplayCollection(collection)
    if rules.collectionScope == "account" then
        collectionData.accounts[playerKey] = collection
    elseif characterData then
        characterData[MirageWardrobeCore.CHARACTER_COLLECTION_KEY] = collection
    end
    if changed then
        local revision = isFiniteNumber(collectionData._revision) and
                math.max(0, math.floor(collectionData._revision)) or 0
        collectionData._revision = math.min(MirageWardrobeCore.MAX_CLIENT_SEQUENCE,
                revision + 1)
    end
    -- The global record is also the monotonic revision source for character-scoped
    -- collections, so reconnecting clients can discard an older Collection packet.
    ModData.add(MirageWardrobeCore.COLLECTION_MODDATA_KEY, collectionData)
    return collection, collectionData._revision
end

local function scanServerGameplay(player, playerKey)
    local rules, rulesRevision = getServerGameplayRules()
    local collection, collectionData, characterData =
            getServerGameplayCollection(player, playerKey, rules)
    local changed = false
    local engine = getGameplayEngine()
    local collectionMode = rules.accessMode == "unlocked" or
            rules.accessMode == "unlocked_or_nearby" or
            rules.accessMode == "unlocked_and_nearby"
    if collectionMode and engine and engine.scanDiscovery then
        local ok, result = pcall(engine.scanDiscovery, player, collection, rules)
        changed = ok and result == true
    end
    local collectionRevision
    collection, collectionRevision = storeServerGameplayCollection(playerKey,
            rules, collection, collectionData, characterData, changed)
    return rules, collection, collectionRevision, rulesRevision, changed
end

local function sendGameplayCollection(player, rules, collection,
        collectionRevision, rulesRevision, session)
    sendServerCommand(player, MirageWardrobeCore.NETWORK_MODULE, "Collection", {
        gameplayRules = sanitizeGameplayRules(rules),
        gameplayCollection = sanitizeGameplayCollection(collection),
        gameplayCollectionRevision = collectionRevision,
        gameplayRulesRevision = rulesRevision,
        session = isSafePresetSession(session) and session or nil,
    })
end

local function validateGameplayStateDelta(player, previousState, nextState,
        rules, collection)
    if rules.accessMode == "all" then return true end
    local engine = getGameplayEngine()
    if not engine or not engine.buildAccessSnapshot or
            not engine.validateStateDelta then
        return false, "validation_unavailable"
    end

    local snapshotOk, snapshot = pcall(engine.buildAccessSnapshot,
            player, collection, rules)
    if not snapshotOk or type(snapshot) ~= "table" then
        return false, "access_scan_error"
    end
    local callOk, allowed, reason, slot, donor = pcall(
            engine.validateStateDelta, previousState, nextState, snapshot, rules)
    if not callOk then return false, "validation_error" end
    if type(allowed) == "table" then
        local detail = allowed
        allowed = detail.allowed
        if allowed == nil then allowed = detail.available end
        if allowed == nil then allowed = detail.valid end
        reason = detail.reason or reason
        slot = detail.slot or slot
        donor = detail.donor or detail.fullName or donor
    elseif type(reason) == "table" then
        local detail = reason
        reason = detail.reason
        slot = detail.slot or slot
        donor = detail.donor or detail.fullName or donor
    end
    return allowed == true, reason, slot, donor
end

local function safeGameplayDetail(value, fallback)
    if type(value) ~= "string" then
        if value == nil then return fallback end
        value = tostring(value)
    end
    if value == "" or string.len(value) >
            MirageWardrobeCore.MAX_OUTFIT_PRESET_VALUE_BYTES or string.find(value, "%c") then
        return fallback
    end
    return value
end

MirageWardrobeCore.onWardrobeGlobalDataInit = function ()
    if isServer() then
        local globalData = ModData.getOrCreate(MirageWardrobeCore.APPEARANCE_MODDATA_KEY)
        if type(globalData._revision) ~= "number" then
            globalData._revision = 0
            ModData.add(MirageWardrobeCore.APPEARANCE_MODDATA_KEY, globalData)
        end
        local presetData = ModData.getOrCreate(MirageWardrobeCore.PRESET_MODDATA_KEY)
        if type(presetData) ~= "table" then
            ModData.add(MirageWardrobeCore.PRESET_MODDATA_KEY, {})
        end
        local collectionData = getGameplayCollectionData()
        ModData.add(MirageWardrobeCore.COLLECTION_MODDATA_KEY, collectionData)
        local rulesData = getGameplayRulesData()
        if not isFiniteNumber(rulesData.revision) or rulesData.revision < 0 then
            rulesData.revision = 0
        else
            rulesData.revision = math.min(MirageWardrobeCore.MAX_CLIENT_SEQUENCE,
                    math.floor(rulesData.revision))
        end
        ModData.add(MirageWardrobeCore.RULES_MODDATA_KEY, rulesData)
    end
end

MirageWardrobeCore.onClientCommand = function (module, command, player, args)
    if not isServer() or module ~= MirageWardrobeCore.NETWORK_MODULE or not player then return end

    local playerKey = player:getUsername()
    if not isSafeNetworkKey(playerKey) then return end

    -- A delayed packet from a disconnected connection can carry the same
    -- username as a newly connected player.  Ignore it once the server's
    -- online-player list identifies a different live object for that name.
    local currentPlayer = findCurrentOnlinePlayer(playerKey)
    if currentPlayer and not samePlayerConnection(currentPlayer, player) then return end

    local globalData = ModData.getOrCreate(MirageWardrobeCore.APPEARANCE_MODDATA_KEY)
    if type(globalData) ~= "table" then globalData = {} end

    if command == "Request" then
        local hasRequesterState = type(globalData[playerKey]) == "table"
        registerClientSession(playerKey, args, player)
        local presetOrder = registerPresetClientSession(playerKey, args, player)
        local presetData = getPresetData()
        local ownPresets = getStoredPresetLibrary(presetData, playerKey)
        local hasPresetState = ownPresets ~= nil
        if not hasPresetState and presetOrder then
            -- One-time upgrade migration. Once a record exists, including an
            -- intentionally empty record after Delete, the server stays authoritative.
            local migrated = copyPresetLibrary(type(args) == "table" and
                    args.outfitPresets or {}, true)
            if migrated then
                ownPresets = migrated
                presetData[playerKey] = { presets = ownPresets }
                ModData.add(MirageWardrobeCore.PRESET_MODDATA_KEY, presetData)
                hasPresetState = true
            else
                ownPresets = {}
            end
        elseif hasPresetState then
            -- Rewrite a sanitized copy so damaged disk entries never travel back out.
            presetData[playerKey] = { presets = ownPresets }
            ModData.add(MirageWardrobeCore.PRESET_MODDATA_KEY, presetData)
        else
            ownPresets = {}
        end

        local gameplayRules, gameplayCollection, gameplayCollectionRevision,
                gameplayRulesRevision = scanServerGameplay(player, playerKey)
        local state = {}
        local onlineKeys = {}
        local haveOnlineList = false
        if getOnlinePlayers then
            local listOk, players = pcall(getOnlinePlayers)
            if listOk and players then
                local sizeOk, size = pcall(players.size, players)
                if sizeOk and type(size) == "number" then
                    haveOnlineList = true
                    for index = 0, size - 1 do
                        local onlinePlayer = players:get(index)
                        if onlinePlayer and onlinePlayer.getUsername then
                            local onlineKey = onlinePlayer:getUsername()
                            if onlineKey and onlineKey ~= "" then onlineKeys[onlineKey] = true end
                        end
                    end
                end
            end
        end
        onlineKeys[playerKey] = true
        if haveOnlineList then
            for onlineKey in pairs(onlineKeys) do
                if type(globalData[onlineKey]) == "table" then
                    state[onlineKey] = copyState(globalData[onlineKey], false)
                end
            end
        else
            -- Compatibility fallback for unusual server builds without the
            -- online-player accessor; correctness is preferred to pruning.
            state = copyPlayers(globalData)
        end
        sendServerCommand(player, MirageWardrobeCore.NETWORK_MODULE, "Snapshot", {
            players = state,
            revision = type(globalData._revision) == "number" and globalData._revision or 0,
            session = type(args) == "table" and args.session or nil,
            requestId = type(args) == "table" and args.requestId or nil,
            requesterKey = playerKey,
            hasRequesterState = hasRequesterState,
            requestGeneration = type(args) == "table" and args.requestGeneration or nil,
            presetGeneration = type(args) == "table" and args.presetGeneration or nil,
            hasOutfitPresetState = hasPresetState,
            outfitPresets = copyPresetLibrary(ownPresets, false),
            gameplayRules = sanitizeGameplayRules(gameplayRules),
            gameplayCollection = sanitizeGameplayCollection(gameplayCollection),
            gameplayCollectionRevision = gameplayCollectionRevision,
            gameplayRulesRevision = gameplayRulesRevision,
        })
        return
    end

    if command == "Discover" then
        -- Discover is only a wake-up hint. The server derives both identity and
        -- inventory/worn-item discovery from its own authoritative player object.
        if not acceptGameplayDiscover(playerKey, args) then return end
        local gameplayRules, gameplayCollection, gameplayCollectionRevision,
                gameplayRulesRevision = scanServerGameplay(player, playerKey)
        sendGameplayCollection(player, gameplayRules, gameplayCollection,
                gameplayCollectionRevision, gameplayRulesRevision,
                type(args) == "table" and args.session or nil)
        return
    end

    if command == "PresetUpdate" and type(args) == "table" then
        local action = args.action
        local presetData = getPresetData()
        local presets = getStoredPresetLibrary(presetData, playerKey) or {}
        if action == "save" then
            local name = normalizePresetName(args.name)
            local preset = copyPreset(args.preset)
            if not name or not preset then return end
            if presets[name] == nil and countEntries(presets) >= MirageWardrobeCore.MAX_OUTFIT_PRESETS then
                return
            end
            local nextTotalEntries = countPresetLibraryEntries(presets) -
                    countPresetEntries(presets[name]) + countPresetEntries(preset)
            if nextTotalEntries > MirageWardrobeCore.MAX_OUTFIT_PRESET_TOTAL_ENTRIES then return end
            presets[name] = preset
        elseif action == "delete" then
            local name = normalizePresetName(args.name)
            if not name then return end
            presets[name] = nil
        elseif action == "replace" then
            presets = copyPresetLibrary(args.presets, true)
            if not presets then return end
        else
            return
        end
        if not acceptPresetClientUpdate(playerKey, args, player) then return end

        presetData[playerKey] = { presets = presets }
        ModData.add(MirageWardrobeCore.PRESET_MODDATA_KEY, presetData)
        return
    end

    if command == "Update" and type(args) == "table" then
        local nextState = copyState(args, true)
        if not nextState then
            return
        end
        if not acceptClientUpdate(playerKey, args, player) then
            return
        end

        local previousState = copyState(globalData[playerKey], false)
        local gameplayRules, gameplayCollection, gameplayCollectionRevision,
                gameplayRulesRevision, gameplayChanged =
                scanServerGameplay(player, playerKey)
        local allowed, reason, slot, donor = validateGameplayStateDelta(player,
                previousState, nextState, gameplayRules, gameplayCollection)
        if not allowed then
            local safeReason = safeGameplayDetail(reason, "unavailable")
            local safeSlot = safeGameplayDetail(slot, nil)
            local safeDonor = safeGameplayDetail(donor, nil)
            local safeRules = sanitizeGameplayRules(gameplayRules)
            local safeCollection = sanitizeGameplayCollection(gameplayCollection)
            sendServerCommand(player, MirageWardrobeCore.NETWORK_MODULE, "UpdateRejected", {
                state = previousState,
                revision = type(globalData._revision) == "number" and
                        globalData._revision or 0,
                rules = safeRules,
                collection = safeCollection,
                collectionRevision = gameplayCollectionRevision,
                gameplayRulesRevision = gameplayRulesRevision,
                reason = safeReason,
                slot = safeSlot,
                donor = safeDonor,
                session = args._clientSession,
                sequence = args._clientSequence,
                requesterKey = playerKey,
            })
            return
        end

        -- Never trust a username supplied by the client; use the authenticated player object.
        globalData[playerKey] = nextState
        globalData._revision = (type(globalData._revision) == "number" and globalData._revision or 0) + 1
        ModData.add(MirageWardrobeCore.APPEARANCE_MODDATA_KEY, globalData)
        if gameplayChanged then
            sendGameplayCollection(player, gameplayRules, gameplayCollection,
                    gameplayCollectionRevision, gameplayRulesRevision,
                    args._clientSession)
        end

        -- Broadcast only the changed player's state. This avoids last-writer-wins table clobbering.
        sendServerCommand(MirageWardrobeCore.NETWORK_MODULE, "State", {
            playerKey = playerKey,
            state = globalData[playerKey],
            revision = globalData._revision,
            session = args._clientSession,
            sequence = args._clientSequence,
        })

        -- Full Global ModData is requested on join/reconnect. Do not transmit the
        -- entire historical player table for every click: State is the realtime
        -- delta channel, and avoiding redundant reliable packets prevents a queue
        -- buildup during rapid apply/reset operations.
    end
end

MirageWardrobeCore.onWardrobeGlobalDataReceived = function (key, data)
    if not isClient() or key ~= MirageWardrobeCore.APPEARANCE_MODDATA_KEY or type(data) ~= "table" then return end
    if not MirageWardrobeCore.setNetworkSnapshot then return end

    local players = type(data.players) == "table" and data.players or data
    local revision = type(data.revision) == "number" and data.revision or data._revision
    local previousStates = copyNetworkPlayerStateIdentities()
    MirageWardrobeCore.setNetworkSnapshot(players, revision, true)
    reconcileNetworkSnapshotBindings(previousStates)
end

local function loadClientGameplayPayload(args)
    if type(args) ~= "table" then return false end
    local incomingRules = type(args.gameplayRules) == "table" and
            args.gameplayRules or args.rules
    local incomingCollection = type(args.gameplayCollection) == "table" and
            args.gameplayCollection or args.collection
    if type(incomingRules) ~= "table" and type(incomingCollection) ~= "table" then
        return true
    end
    if not MirageWardrobeCore.loadGameplaySnapshot then return false end

    local collectionRevision = args.gameplayCollectionRevision
    if type(collectionRevision) ~= "number" then
        collectionRevision = args.collectionRevision
    end
    collectionRevision = isFiniteNumber(collectionRevision) and
            math.max(0, math.floor(collectionRevision)) or 0
    local currentCollectionRevision =
            type(MirageWardrobeCore.networkGameplayCollectionRevision) == "number" and
                    MirageWardrobeCore.networkGameplayCollectionRevision or 0
    if collectionRevision < currentCollectionRevision and
            type(MirageWardrobeCore.networkGameplayCollection) == "table" then
        incomingCollection = MirageWardrobeCore.networkGameplayCollection
        collectionRevision = currentCollectionRevision
    end

    local rulesRevision = isFiniteNumber(args.gameplayRulesRevision) and
            math.max(0, math.floor(args.gameplayRulesRevision)) or 0
    local currentRulesRevision =
            type(MirageWardrobeCore.networkGameplayRulesRevision) == "number" and
                    MirageWardrobeCore.networkGameplayRulesRevision or 0
    if rulesRevision < currentRulesRevision and
            type(MirageWardrobeCore.networkGameplayRules) == "table" then
        incomingRules = MirageWardrobeCore.networkGameplayRules
        rulesRevision = currentRulesRevision
    end

    local ok, loaded = pcall(MirageWardrobeCore.loadGameplaySnapshot,
            incomingRules, incomingCollection, collectionRevision)
    if not ok or loaded == false then return false end
    MirageWardrobeCore.networkGameplayRulesRevision = rulesRevision
    return true
end

MirageWardrobeCore.onServerCommand = function (module, command, args)
    if not isClient() or module ~= MirageWardrobeCore.NETWORK_MODULE then return end
    if type(args) ~= "table" then
        return
    end

    if command == "State" then
        if MirageWardrobeCore.applyNetworkState then
            local localKey = MirageWardrobeCore.getPlayerSyncKey and MirageWardrobeCore.getPlayerSyncKey() or nil
            local selfMatch = args.playerKey == localKey
            local ownerAcknowledged = selfMatch and
                    type(args.session) == "string" and
                    args.session == MirageWardrobeCore.networkSessionId and
                    isFiniteNumber(args.sequence) and
                    math.floor(args.sequence) == MirageWardrobeCore.networkUpdateSequence
            if selfMatch and type(args.session) == "string" and
                    type(MirageWardrobeCore.networkSessionId) == "string" and
                    args.session ~= MirageWardrobeCore.networkSessionId then
                return
            end
            -- The sender receives its own broadcast too.  That packet may be
            -- an older echo than the local Apply/Reset, so treat local State
            -- messages as acknowledgements/cache updates only; the local
            -- modData remains the source of truth until the next Snapshot.
            ensureNetworkAppliedBindingSession()
            local _, stateReady =
                    MirageWardrobeCore.applyNetworkState(args.playerKey, args.state,
                            args.revision, selfMatch, nil, ownerAcknowledged)
            if stateReady == true and MirageWardrobeCore.findPlayerByNetworkKey then
                rememberNetworkAppliedBinding(args.playerKey,
                        MirageWardrobeCore.findPlayerByNetworkKey(args.playerKey))
            end
        end
        return
    end

    if command == "Collection" then
        if type(args.session) == "string" and
                type(MirageWardrobeCore.networkSessionId) == "string" and
                args.session ~= MirageWardrobeCore.networkSessionId then
            return
        end
        local loaded = loadClientGameplayPayload(args)
        if loaded then
            MirageWardrobeCore.gameplayDiscoveryPending = false
        end
        return
    end

    if command == "UpdateRejected" then
        if type(args.session) == "string" and
                type(MirageWardrobeCore.networkSessionId) == "string" and
                args.session ~= MirageWardrobeCore.networkSessionId then
            return
        end
        loadClientGameplayPayload(args)

        local rejectedSequence = isFiniteNumber(args.sequence) and
                math.floor(args.sequence) or nil
        if rejectedSequence and type(MirageWardrobeCore.networkUpdateSequence) == "number" and
                rejectedSequence ~= MirageWardrobeCore.networkUpdateSequence then
            -- Only the current local mutation may decide the final local state.
            -- A later mutation is already in flight when the rejected number is
            -- lower; a higher number cannot belong to this authenticated session.
            return
        end

        -- Current clients always attach a sequence to Update. Once this
        -- session has emitted one, a rejection without it is an old or
        -- uncorrelatable packet; it must not overwrite a newer local state.
        if not rejectedSequence and
                type(MirageWardrobeCore.networkUpdateSequence) == "number" and
                MirageWardrobeCore.networkUpdateSequence > 0 then
            if MirageWardrobeCore.networkSnapshotPending ~= true and
                    MirageWardrobeCore.requestAppearanceSnapshot then
                pcall(MirageWardrobeCore.requestAppearanceSnapshot)
            end
            return
        end

        local player = getPlayer()
        if not player or type(args.state) ~= "table" then
            return
        end
        local playerKey = isSafeNetworkKey(args.requesterKey) and
                args.requesterKey or
                (MirageWardrobeCore.getPlayerSyncKey and
                        MirageWardrobeCore.getPlayerSyncKey(player) or nil)
        if not isSafeNetworkKey(playerKey) then
            return
        end

        local restored = false
        local applyStatus
        if MirageWardrobeCore.applyNetworkState then
            local ok, _, ready, status = pcall(MirageWardrobeCore.applyNetworkState,
                    playerKey, args.state, args.revision, false, player)
            restored = ok and ready == true
            applyStatus = ok and status or nil
        end
        if applyStatus == "stale-revision" then
            return
        end
        if not restored and MirageWardrobeCore.loadPlayerTransmogState then
            local ok, loaded = pcall(MirageWardrobeCore.loadPlayerTransmogState,
                    args.state, player)
            restored = ok and loaded == true
            if restored and MirageWardrobeCore.applyWardrobeAppearance then
                pcall(MirageWardrobeCore.applyWardrobeAppearance, player, args.state)
            end
        end

        MirageWardrobeCore.lastGameplayDenial = {
            reason = safeGameplayDetail(args.reason, "unavailable"),
            slot = safeGameplayDetail(args.slot, nil),
            donor = safeGameplayDetail(args.donor, nil),
            revision = isFiniteNumber(args.revision) and
                    math.floor(args.revision) or 0,
            restored = restored,
        }
        return
    end

    if command == "Snapshot" then
        if type(args.session) == "string" and type(MirageWardrobeCore.networkSessionId) == "string" and
                args.session ~= MirageWardrobeCore.networkSessionId then
            return
        end

        local requestId = type(args.requestId) == "number" and math.floor(args.requestId) or nil
        if requestId and type(MirageWardrobeCore.networkSnapshotRequestId) == "number" and
                requestId ~= math.floor(MirageWardrobeCore.networkSnapshotRequestId) then
            return
        end
        if requestId and MirageWardrobeCore.networkSnapshotCompletedRequestId == requestId then
            return
        end

        local player = getPlayer()
        if not player or type(args.players) ~= "table" then
            return
        end
        loadClientGameplayPayload(args)

        local requesterKey = args.requesterKey
        local authenticatedRequester = isSafeNetworkKey(requesterKey)
        if not authenticatedRequester then
            requesterKey = MirageWardrobeCore.getPlayerSyncKey and
                    MirageWardrobeCore.getPlayerSyncKey(player) or nil
            if not isSafeNetworkKey(requesterKey) then
                return
            end
            -- A legacy server cannot prove that an absent key belongs to this
            -- client. Wait for a retry/server restart instead of migrating an
            -- empty placeholder identity over an authenticated saved state.
            if MirageWardrobeCore.networkSnapshotPending == true and
                    type(args.players[requesterKey]) ~= "table" then
                return
            end
        else
            -- This value is derived from server-side player:getUsername(), not client payload.
            MirageWardrobeCore.networkAuthenticatedPlayerKey = requesterKey
        end

        local requestGeneration = type(args.requestGeneration) == "number" and
                math.floor(args.requestGeneration) or MirageWardrobeCore.networkSnapshotRequestGeneration or 0
        local preserveLocalState = (MirageWardrobeCore.localMutationGeneration or 0) > requestGeneration
        local presetGeneration = type(args.presetGeneration) == "number" and
                math.floor(args.presetGeneration) or
                MirageWardrobeCore.networkPresetSnapshotRequestGeneration or 0
        local preserveLocalPresets = (MirageWardrobeCore.outfitPresetMutationGeneration or 0) > presetGeneration

        if not MirageWardrobeCore.setNetworkSnapshot then
            return
        end
        local previousStates = copyNetworkPlayerStateIdentities()
        local hasLocalState, localStateReady = MirageWardrobeCore.setNetworkSnapshot(
                args.players, args.revision, preserveLocalState, requesterKey)
        reconcileNetworkSnapshotBindings(previousStates)
        local hasRequesterState = args.hasRequesterState
        if type(hasRequesterState) ~= "boolean" then
            hasRequesterState = type(args.players[requesterKey]) == "table"
        end
        if hasRequesterState and (not hasLocalState or not localStateReady) then
            return
        end
        if not hasRequesterState and not player then return end

        local presetReady = true
        if args.hasOutfitPresetState == true then
            presetReady = MirageWardrobeCore.loadOutfitPresetSnapshot and
                    MirageWardrobeCore.loadOutfitPresetSnapshot(args.outfitPresets, presetGeneration, player) == true
        elseif MirageWardrobeCore.loadOutfitPresetSnapshot then
            presetReady = MirageWardrobeCore.loadOutfitPresetSnapshot({}, presetGeneration, player) == true
        end
        if not presetReady then return end

        MirageWardrobeCore.networkSnapshotPending = false
        MirageWardrobeCore.networkSnapshotRequestAttempts = 0
        MirageWardrobeCore.networkSnapshotRetryUpdates = 0
        MirageWardrobeCore.networkSnapshotCompletedRequestId = requestId

        -- Only a fully parsed authoritative Snapshot may be re-announced. This
        -- prevents a placeholder username or missing local state from replacing
        -- persisted server data with an empty client table.
        if MirageWardrobeCore.publishAppearanceState then
            MirageWardrobeCore.publishAppearanceState(false)
        end
        if preserveLocalPresets and
                MirageWardrobeCore.syncOutfitPresetTableToServer then
            MirageWardrobeCore.syncOutfitPresetTableToServer()
        end
    end
end
installNetworkSessionBindingReset()
Events.OnInitGlobalModData.Add(MirageWardrobeCore.onWardrobeGlobalDataInit)
if isServer() then
    Events.OnClientCommand.Add(MirageWardrobeCore.onClientCommand)
end
if isClient() then
    if Events.OnGameBoot then
        Events.OnGameBoot.Add(installNetworkSessionBindingReset)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(installNetworkSessionBindingReset)
    end
    if Events.OnMiniScoreboardUpdate then
        Events.OnMiniScoreboardUpdate.Add(
                MirageWardrobeCore.onMiniScoreboardUpdate)
    end
    Events.OnServerCommand.Add(MirageWardrobeCore.onServerCommand)
    Events.OnReceiveGlobalModData.Add(MirageWardrobeCore.onWardrobeGlobalDataReceived)
end
