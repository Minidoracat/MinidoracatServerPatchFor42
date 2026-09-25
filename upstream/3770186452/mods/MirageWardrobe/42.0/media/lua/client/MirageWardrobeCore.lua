require "Moveables/ISMoveableSpriteProps"
require "TimedActions/ISInventoryTransferAction"

MirageWardrobeCore = MirageWardrobeCore or {}

MirageWardrobeCore.originalClothingAssets = MirageWardrobeCore.originalClothingAssets or {}
MirageWardrobeCore.appearanceUpdateInProgress = false
MirageWardrobeCore.networkPlayerData = MirageWardrobeCore.networkPlayerData or {}
MirageWardrobeCore.networkRevision = MirageWardrobeCore.networkRevision or 0
MirageWardrobeCore.networkPlayerRevisions = MirageWardrobeCore.networkPlayerRevisions or {}
MirageWardrobeCore.networkPlayerStateSources = MirageWardrobeCore.networkPlayerStateSources or {}
MirageWardrobeCore.networkSessionId = MirageWardrobeCore.networkSessionId or nil
MirageWardrobeCore.networkUpdateSequence = MirageWardrobeCore.networkUpdateSequence or 0
MirageWardrobeCore.outfitPresetUpdateSequence = MirageWardrobeCore.outfitPresetUpdateSequence or 0
MirageWardrobeCore.outfitPresetMutationGeneration = MirageWardrobeCore.outfitPresetMutationGeneration or 0
MirageWardrobeCore.networkPresetSnapshotRequestGeneration =
        MirageWardrobeCore.networkPresetSnapshotRequestGeneration or 0
MirageWardrobeCore.networkSessionCounter = MirageWardrobeCore.networkSessionCounter or 0
MirageWardrobeCore.localMutationGeneration = MirageWardrobeCore.localMutationGeneration or 0
MirageWardrobeCore.networkSnapshotPending = MirageWardrobeCore.networkSnapshotPending or false
MirageWardrobeCore.networkSnapshotRequestGeneration = MirageWardrobeCore.networkSnapshotRequestGeneration or 0
MirageWardrobeCore.networkSnapshotRequestAttempts = MirageWardrobeCore.networkSnapshotRequestAttempts or 0
MirageWardrobeCore.networkSnapshotRetryUpdates = MirageWardrobeCore.networkSnapshotRetryUpdates or 0
MirageWardrobeCore.networkSnapshotRequestId = MirageWardrobeCore.networkSnapshotRequestId or 0
MirageWardrobeCore.networkSnapshotCompletedRequestId = MirageWardrobeCore.networkSnapshotCompletedRequestId or nil
MirageWardrobeCore.networkAuthenticatedPlayerKey = MirageWardrobeCore.networkAuthenticatedPlayerKey or nil
MirageWardrobeCore.networkSessionInitialized = MirageWardrobeCore.networkSessionInitialized or false
MirageWardrobeCore.transmogSourceEligibilityCache = MirageWardrobeCore.transmogSourceEligibilityCache or {}
MirageWardrobeCore.transmogSourceSlotCache = MirageWardrobeCore.transmogSourceSlotCache or {}
MirageWardrobeCore.transmogCoverageCache =
        MirageWardrobeCore.transmogCoverageCache or {}
MirageWardrobeCore.transmogSlotReplacementCache =
        MirageWardrobeCore.transmogSlotReplacementCache or {}
MirageWardrobeCore.renderCarrierBindings =
        MirageWardrobeCore.renderCarrierBindings or {}
MirageWardrobeCore.renderCarrierNextIndex =
        MirageWardrobeCore.renderCarrierNextIndex or {}
MirageWardrobeCore.compatibilityWarnings =
        MirageWardrobeCore.compatibilityWarnings or {}
MirageWardrobeCore.renderCompatibilityCache =
        MirageWardrobeCore.renderCompatibilityCache or {}
MirageWardrobeCore.hoodieSubmenuCache =
        MirageWardrobeCore.hoodieSubmenuCache or {}
local CORE_BUILD = "20260817-context-menu-release"
if MirageWardrobeCore.coreBuild ~= CORE_BUILD then
    MirageWardrobeCore.coreBuild = CORE_BUILD
    print("[MirageWardrobe] Compatibility build=" .. CORE_BUILD)
end
MirageWardrobeCore.lastPublishedWornVisualSlotSignature =
        MirageWardrobeCore.lastPublishedWornVisualSlotSignature or nil
MirageWardrobeCore.localOutfitPresetLibraries = MirageWardrobeCore.localOutfitPresetLibraries or {}
MirageWardrobeCore.serverOutfitPresetLibrary = MirageWardrobeCore.serverOutfitPresetLibrary or {}
MirageWardrobeCore.cleanAppearancePending = MirageWardrobeCore.cleanAppearancePending or {}
MirageWardrobeCore.cleanAppearanceRendered = MirageWardrobeCore.cleanAppearanceRendered or {}
MirageWardrobeCore.appearanceWearSignatures =
        MirageWardrobeCore.appearanceWearSignatures or {}
MirageWardrobeCore.appearanceRevisions = MirageWardrobeCore.appearanceRevisions or {}
MirageWardrobeCore.appearanceRevisionCounter = MirageWardrobeCore.appearanceRevisionCounter or 0
MirageWardrobeCore.fixedTextureTrackingCache =
        MirageWardrobeCore.fixedTextureTrackingCache or {}
MirageWardrobeCore.cleanAppearanceTickCounter = MirageWardrobeCore.cleanAppearanceTickCounter or 0
MirageWardrobeCore.appearanceCapturePlayers = MirageWardrobeCore.appearanceCapturePlayers or {}
MirageWardrobeCore.appearancePreviewTransactions =
        MirageWardrobeCore.appearancePreviewTransactions or {}
MirageWardrobeCore.appearancePreviewTokenGeneration =
        MirageWardrobeCore.appearancePreviewTokenGeneration or 0
MirageWardrobeCore.activeAppearanceSnapshots = MirageWardrobeCore.activeAppearanceSnapshots or {}
MirageWardrobeCore.appearanceRenderBridges = MirageWardrobeCore.appearanceRenderBridges or {}
MirageWardrobeCore.appearanceSnapshotFailures =
        MirageWardrobeCore.appearanceSnapshotFailures or {}
MirageWardrobeCore.isCapturingCleanAppearance = false
MirageWardrobeCore.cleanAppearanceCaptureDisabled = false
MirageWardrobeCore.cleanAppearancePreCharacterRenderSeen =
        MirageWardrobeCore.cleanAppearancePreCharacterRenderSeen or false
MirageWardrobeCore.networkGameplayRules = MirageWardrobeCore.networkGameplayRules or nil
MirageWardrobeCore.networkGameplayRulesRevision =
        MirageWardrobeCore.networkGameplayRulesRevision or 0
MirageWardrobeCore.networkGameplayCollection = MirageWardrobeCore.networkGameplayCollection or nil
MirageWardrobeCore.networkGameplayCollectionRevision =
        MirageWardrobeCore.networkGameplayCollectionRevision or 0
MirageWardrobeCore.gameplayAccessSnapshot = MirageWardrobeCore.gameplayAccessSnapshot or nil
MirageWardrobeCore.gameplayAccessDirty = MirageWardrobeCore.gameplayAccessDirty or false
MirageWardrobeCore.gameplayAccessDirtyDelay =
        MirageWardrobeCore.gameplayAccessDirtyDelay or 0
MirageWardrobeCore.gameplayAccessRevision =
        MirageWardrobeCore.gameplayAccessRevision or 0
MirageWardrobeCore.gameplayAccessSquare =
        MirageWardrobeCore.gameplayAccessSquare or nil
MirageWardrobeCore.gameplayAccessUpdateTick =
        MirageWardrobeCore.gameplayAccessUpdateTick or 0
MirageWardrobeCore.gameplayAccessLastRefreshTick =
        MirageWardrobeCore.gameplayAccessLastRefreshTick or nil
MirageWardrobeCore.gameplayDiscoveryPending = MirageWardrobeCore.gameplayDiscoveryPending or false
MirageWardrobeCore.lastGameplayDenial = MirageWardrobeCore.lastGameplayDenial or nil
MirageWardrobeCore.APPEARANCE_MODDATA_KEY = MirageWardrobeCore.APPEARANCE_MODDATA_KEY or "MirageWardrobeTransmogData"
MirageWardrobeCore.NETWORK_MODULE = MirageWardrobeCore.NETWORK_MODULE or "MirageWardrobeTransmog"
MirageWardrobeCore.PRESET_MODDATA_KEY = MirageWardrobeCore.PRESET_MODDATA_KEY or "MirageWardrobeOutfitPresetData"
MirageWardrobeCore.COLLECTION_MODDATA_KEY =
        MirageWardrobeCore.COLLECTION_MODDATA_KEY or "MirageWardrobeCollectionData"
MirageWardrobeCore.RULES_MODDATA_KEY =
        MirageWardrobeCore.RULES_MODDATA_KEY or "MirageWardrobeGameplayRulesData"
MirageWardrobeCore.GAMEPLAY_MOVEMENT_SETTLE_TICKS = 10
MirageWardrobeCore.GAMEPLAY_NEARBY_REFRESH_COOLDOWN_TICKS = 30
MirageWardrobeCore.CHARACTER_COLLECTION_KEY = "mirageWardrobeCollection"
MirageWardrobeCore.ITEM_ORIGINAL_VISUAL_KEY = "MirageWardrobeOriginalVisualType"
MirageWardrobeCore.ITEM_APPLIED_VISUAL_KEY = "MirageWardrobeAppliedVisualType"
MirageWardrobeCore.ITEM_ORIGINAL_ALTERNATE_MODEL_KEY = "MirageWardrobeOriginalAlternateModelName"
MirageWardrobeCore.ITEM_ORIGINAL_STYLE_KEY = "MirageWardrobeOriginalStyleStored"
MirageWardrobeCore.ITEM_ORIGINAL_VARIANT_KEY = "MirageWardrobeOriginalVariantStored"
MirageWardrobeCore.ITEM_ORIGINAL_TEXTURE_CHOICE_KEY = "MirageWardrobeOriginalTextureChoice"
MirageWardrobeCore.ITEM_ORIGINAL_BASE_TEXTURE_KEY = "MirageWardrobeOriginalBaseTexture"
MirageWardrobeCore.ITEM_ORIGINAL_TINT_R_KEY = "MirageWardrobeOriginalTintR"
MirageWardrobeCore.ITEM_ORIGINAL_TINT_G_KEY = "MirageWardrobeOriginalTintG"
MirageWardrobeCore.ITEM_ORIGINAL_TINT_B_KEY = "MirageWardrobeOriginalTintB"
MirageWardrobeCore.ITEM_ORIGINAL_HUE_KEY = "MirageWardrobeOriginalHue"
MirageWardrobeCore.ITEM_ORIGINAL_DECAL_KEY = "MirageWardrobeOriginalDecal"
MirageWardrobeCore.VISUAL_PROXY_MARKER_PREFIX = "MirageWardrobeProxy:"
MirageWardrobeCore.MAX_VISUAL_PROXIES = 96
-- HumanVisual serializes this count as a signed byte in B42.  Staying well
-- below 128 leaves room for tattoos/body visuals owned by the game and mods.
MirageWardrobeCore.MAX_BODY_VISUALS_WITH_PROXIES = 96
MirageWardrobeCore.HIDDEN_VISUAL_TYPE = "Base.Belt2"
local HOODIE_RENDER_SLOT_REPLACEMENTS = {
    ["base:jackethat_bulky"] = "base:jacket_bulky",
    ["base:sweaterhat"] = "base:sweater",
    ["base:jackethat"] = "base:jacket_down",
}
local RENDER_CARRIER_POOL_SIZE = 64
local RENDER_CARRIER_SPECS = {
    ["base:jacket_bulky"] = "JacketBulky",
    ["base:sweater"] = "Sweater",
    ["base:jacket_down"] = "JacketDown",
}
MirageWardrobeCore.SLOT_HIDDEN_PREFIX = "slot:"
MirageWardrobeCore.OUTFIT_PRESETS_KEY = "mirageWardrobeOutfitPresets"
MirageWardrobeCore.CLEAN_APPEARANCE_KEY = "mirageWardrobeCleanAppearance"
MirageWardrobeCore.CLEAN_APPEARANCE_OPTIONS_KEY =
        "mirageWardrobeCleanAppearanceOptions"
MirageWardrobeCore.HIDE_ORIGINAL_CLOTHING_KEY = "mirageWardrobeHideOriginalClothing"
MirageWardrobeCore.ORIGINAL_CLOTHING_OVERRIDES_KEY =
        "mirageWardrobeOriginalClothingOverrides"
MirageWardrobeCore.ORIGINAL_CLOTHING_HIDDEN = "hidden"
MirageWardrobeCore.ORIGINAL_CLOTHING_SHOWN = "shown"
MirageWardrobeCore.MAX_OUTFIT_PRESETS = 32
MirageWardrobeCore.MAX_OUTFIT_PRESET_NAME_BYTES = 96
MirageWardrobeCore.MAX_OUTFIT_PRESET_SLOT_ENTRIES = 128
MirageWardrobeCore.MAX_OUTFIT_PRESET_HIDDEN_ENTRIES = 128
MirageWardrobeCore.MAX_OUTFIT_PRESET_TOTAL_ENTRIES = 1024
MirageWardrobeCore.MAX_OUTFIT_PRESET_VALUE_BYTES = 256
MirageWardrobeCore.MAX_SLOT_VARIANT_ENTRIES = 128
MirageWardrobeCore.MAX_TEXTURE_VARIANT_INDEX = 127
MirageWardrobeCore.NETWORK_SNAPSHOT_RETRY_UPDATES = MirageWardrobeCore.NETWORK_SNAPSHOT_RETRY_UPDATES or 120
MirageWardrobeCore.NETWORK_SNAPSHOT_MAX_ATTEMPTS = MirageWardrobeCore.NETWORK_SNAPSHOT_MAX_ATTEMPTS or 10
MirageWardrobeCore.NETWORK_SNAPSHOT_SLOW_RETRY_UPDATES = MirageWardrobeCore.NETWORK_SNAPSHOT_SLOW_RETRY_UPDATES or 1800
MirageWardrobeCore.LOCAL_PRESET_CACHE_KEY = "__mirageWardrobe_local_account__"
MirageWardrobeCore.OUTFIT_PRESET_FILE = "MirageWardrobeOutfitPresets.txt"
MirageWardrobeCore.OUTFIT_PRESET_FILE_VERSION = "2"
-- Short retry delay used when a native model/texture job is still in flight.
MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_DELAY_TICKS = 1
MirageWardrobeCore.CLEAN_APPEARANCE_RETRY_TICKS = 10
MirageWardrobeCore.CLEAN_APPEARANCE_MAX_RETRY_TICKS = 1800
MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_SCAN_TICKS = 30
MirageWardrobeCore.CLEAN_APPEARANCE_MAX_CAPTURES_PER_TICK = 2
MirageWardrobeCore.APPEARANCE_SNAPSHOT_FAILURE_RETRY_TICKS = 10

local function compatibilityValue(value, maxLength)
    local text = tostring(value == nil and "<none>" or value)
    text = string.gsub(text, "%s+", " ")
    maxLength = tonumber(maxLength) or 192
    if string.len(text) > maxLength then
        text = string.sub(text, 1, maxLength) .. "..."
    end
    return text
end

local RELEASE_COMPATIBILITY_FAILURES = {
    ["snapshot-failed"] = true,
    ["bridge-install-failed"] = true,
    ["preview-panel-failed"] = true,
    ["carrier-asset-unavailable"] = true,
    ["carrier-manager-unavailable"] = true,
    ["carrier-pool-exhausted"] = true,
    ["carrier-script-unavailable"] = true,
    ["carrier-bind-failed"] = true,
}

local function warnCompatibility(phase, itemType, slot, reason)
    if not RELEASE_COMPATIBILITY_FAILURES[phase] then return end
    phase = compatibilityValue(phase, 64)
    itemType = compatibilityValue(itemType, 160)
    slot = compatibilityValue(slot, 128)
    reason = compatibilityValue(reason, 256)
    local key = table.concat({ phase, itemType }, "|")
    if MirageWardrobeCore.compatibilityWarnings[key] then return end
    MirageWardrobeCore.compatibilityWarnings[key] = true
    print("[MirageWardrobe] Compatibility phase=" .. phase ..
            " item=" .. itemType .. " slot=" .. slot ..
            " detail=" .. reason)
end


local function copyStringMap(source)
    local result = {}
    if type(source) ~= "table" then return result end

    for key, value in pairs(source) do
        if type(key) == "string" and type(value) == "string" then
            result[key] = value
        end
    end
    return result
end

local function copyBooleanMap(source)
    local result = {}
    if type(source) ~= "table" then return result end

    for key, value in pairs(source) do
        if type(key) == "string" and type(value) == "boolean" then
            result[key] = value
        end
    end
    return result
end

local CLEAN_APPEARANCE_OPTION_KEYS = { "blood", "holes", "patches" }
local CLEAN_APPEARANCE_OPTION_DEFAULTS = {
    blood = false,
    holes = true,
    patches = true,
}
local CLEAN_APPEARANCE_OPTION_SET = {
    blood = true,
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

local function cleanAppearanceOptionsEqual(left, right)
    left = copyCleanAppearanceOptions(left, false)
    right = copyCleanAppearanceOptions(right, false)
    for _, key in ipairs(CLEAN_APPEARANCE_OPTION_KEYS) do
        if left[key] ~= right[key] then return false end
    end
    return true
end

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and
            value ~= math.huge and value ~= -math.huge
end

local function normalizeSlotVariant(source)
    if type(source) ~= "table" then return nil, false end

    local result = {}
    local hasTexture = source.textureMode ~= nil or source.textureIndex ~= nil
    if hasTexture then
        local mode = source.textureMode
        local index = source.textureIndex
        if (mode ~= "choice" and mode ~= "base") or not isFiniteNumber(index) or
                index < 0 or index > MirageWardrobeCore.MAX_TEXTURE_VARIANT_INDEX or
                index ~= math.floor(index) then
            return nil, false
        end
        result.textureMode = mode
        result.textureIndex = index
    end

    local hasTint = source.tintR ~= nil or source.tintG ~= nil or source.tintB ~= nil
    if hasTint then
        if not isFiniteNumber(source.tintR) or not isFiniteNumber(source.tintG) or
                not isFiniteNumber(source.tintB) or source.tintR < 0 or source.tintR > 1 or
                source.tintG < 0 or source.tintG > 1 or source.tintB < 0 or source.tintB > 1 then
            return nil, false
        end
        result.tintR = source.tintR
        result.tintG = source.tintG
        result.tintB = source.tintB
    end

    if not hasTexture and not hasTint then return nil, false end
    return result, true
end

local function variantsEqual(left, right)
    if left == right then return true end
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    return left.textureMode == right.textureMode and
            left.textureIndex == right.textureIndex and
            left.tintR == right.tintR and left.tintG == right.tintG and
            left.tintB == right.tintB
end

local function copySlotVariantMap(source, strict, allowedSlots)
    local result = {}
    if source == nil then return result end
    if type(source) ~= "table" then return strict and nil or result end

    local count = 0
    for slot, variant in pairs(source) do
        count = count + 1
        if count > MirageWardrobeCore.MAX_SLOT_VARIANT_ENTRIES then
            if strict then return nil end
            break
        end
        local normalized, valid = normalizeSlotVariant(variant)
        local slotValid = type(slot) == "string" and slot ~= "" and
                string.len(slot) <= MirageWardrobeCore.MAX_OUTFIT_PRESET_VALUE_BYTES and
                not string.find(slot, "%c") and
                (type(allowedSlots) ~= "table" or type(allowedSlots[slot]) == "string")
        if not slotValid or not valid then
            if strict then return nil end
        else
            result[slot] = normalized
        end
    end
    return result
end

local function variantMapsEqual(left, right)
    if left == right then return true end
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    for slot, variant in pairs(left) do
        if not variantsEqual(variant, right[slot]) then return false end
    end
    for slot, variant in pairs(right) do
        if not variantsEqual(variant, left[slot]) then return false end
    end
    return true
end

local function getSlotHiddenKey(slot)
    if type(slot) ~= "string" or slot == "" then return nil end
    return MirageWardrobeCore.SLOT_HIDDEN_PREFIX .. slot
end

local function getSlotFromHiddenKey(key)
    if type(key) ~= "string" then return nil end
    local prefix = MirageWardrobeCore.SLOT_HIDDEN_PREFIX
    if string.sub(key, 1, string.len(prefix)) ~= prefix then return nil end

    local slot = string.sub(key, string.len(prefix) + 1)
    if slot == "" then return nil end
    return slot
end

local function copySlotHiddenMap(source)
    local result = {}
    if type(source) ~= "table" then return result end

    for key, value in pairs(source) do
        if value == true and getSlotFromHiddenKey(key) then
            result[key] = true
        end
    end
    return result
end

local function migrateLegacyHiddenSlots(slotTransmogTable, hiddenItemsTable)
    if type(slotTransmogTable) ~= "table" or type(hiddenItemsTable) ~= "table" then
        return false
    end

    local legacySlots = {}
    local invalidLegacySlots = {}
    for slot, donorFullName in pairs(slotTransmogTable) do
        if donorFullName == MirageWardrobeCore.HIDDEN_VISUAL_TYPE then
            if type(slot) == "string" and slot ~= "" then
                legacySlots[#legacySlots + 1] = slot
            else
                invalidLegacySlots[#invalidLegacySlots + 1] = slot
            end
        end
    end

    for _, slot in ipairs(invalidLegacySlots) do
        slotTransmogTable[slot] = nil
    end
    for _, slot in ipairs(legacySlots) do
        slotTransmogTable[slot] = nil
        hiddenItemsTable[getSlotHiddenKey(slot)] = true
    end
    return #legacySlots > 0 or #invalidLegacySlots > 0
end

local function safeNoArgMethod(object, methodName)
    if not object or not object[methodName] then return nil, false end
    local ok, value = pcall(object[methodName], object)
    if ok then return value, true end
    return nil, false
end

local function getModelIdentity(player)
    if not player or not player.getModelInstance then return nil end
    local model, ok = safeNoArgMethod(player, "getModelInstance")
    if ok then return model end
    return nil
end

local function getItemScript(item)
    if not item then return nil end
    if item.getScriptItem then
        local scriptItem, ok = safeNoArgMethod(item, "getScriptItem")
        if ok and scriptItem then return scriptItem end
    end
    return item
end

local function getItemFullName(item)
    local scriptItem = getItemScript(item)
    if scriptItem and scriptItem.getFullName then
        local fullName, ok = safeNoArgMethod(scriptItem, "getFullName")
        if ok and fullName then return fullName end
    end
    if item and item.getFullType then
        local fullType, ok = safeNoArgMethod(item, "getFullType")
        if ok then return fullType end
    end
    return nil
end

local function getItemVisual(item)
    if item and item.getVisual then
        local visual, ok = safeNoArgMethod(item, "getVisual")
        if ok then return visual end
    end
    return nil
end

local function getPlayerBodyVisuals(player)
    if not player or not player.getHumanVisual then return nil end

    local humanVisual, humanVisualOk = safeNoArgMethod(player, "getHumanVisual")
    if not humanVisualOk or not humanVisual or not humanVisual.getBodyVisuals then return nil end

    local bodyVisuals, bodyVisualsOk = safeNoArgMethod(humanVisual, "getBodyVisuals")
    if bodyVisualsOk then return bodyVisuals end
    return nil
end

local function getVisualProxySlot(visual)
    if not visual or not visual.getAlternateModelName then return nil end

    local marker, markerOk = safeNoArgMethod(visual, "getAlternateModelName")
    if not markerOk or type(marker) ~= "string" then return nil end

    local prefix = MirageWardrobeCore.VISUAL_PROXY_MARKER_PREFIX
    if string.sub(marker, 1, string.len(prefix)) ~= prefix then return nil end

    local slot = string.sub(marker, string.len(prefix) + 1)
    if slot == "" then return nil end
    return slot
end

local function isLocalPlayer(player)
    local localPlayer = getPlayer()
    return player ~= nil and localPlayer ~= nil and player == localPlayer
end

local function getActiveAppearancePreviewState(player)
    local transaction = player and
            MirageWardrobeCore.appearancePreviewTransactions[player] or nil
    return type(transaction) == "table" and
            type(transaction.previewState) == "table" and
            transaction.previewState or nil
end


MirageWardrobeCore.markAppearanceChanged = function (player)
    player = player or (getPlayer and getPlayer() or nil)
    if not player then return 0 end
    MirageWardrobeCore.appearanceRevisionCounter =
            (MirageWardrobeCore.appearanceRevisionCounter or 0) + 1
    MirageWardrobeCore.appearanceRevisions[player] =
            MirageWardrobeCore.appearanceRevisionCounter
    MirageWardrobeCore.appearanceSnapshotFailures[player] = nil
    return MirageWardrobeCore.appearanceRevisionCounter
end

MirageWardrobeCore.getAppearanceRevision = function (player)
    player = player or (getPlayer and getPlayer() or nil)
    if not player then return 0 end
    return MirageWardrobeCore.appearanceRevisions[player] or 0
end

local function isMapEmpty(map)
    if type(map) ~= "table" then return true end
    -- Project Zomboid's Kahlua runtime doesn't expose Lua's global next().
    for _ in pairs(map) do
        return false
    end
    return true
end

local function mapsEqual(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    for key, value in pairs(left) do
        if right[key] ~= value then return false end
    end
    for key, value in pairs(right) do
        if left[key] ~= value then return false end
    end
    return true
end

local function collectTrackedPlayers()
    local result = {}
    local localPlayer = getPlayer and getPlayer() or nil
    if localPlayer then result[localPlayer] = true end
    if not getOnlinePlayers then return result, false end
    local listOk, players = pcall(getOnlinePlayers)
    if not listOk or not players or not players.size or not players.get then
        return result, false
    end
    local sizeOk, size = pcall(players.size, players)
    if not sizeOk or type(size) ~= "number" then return result, false end
    for index = 0, size - 1 do
        local playerOk, onlinePlayer = pcall(players.get, players, index)
        if playerOk and onlinePlayer then result[onlinePlayer] = true end
    end
    return result, true
end

local function hasCurrentNetworkBinding(player)
    if not player then return false end
    local bindings = MirageWardrobeCore.networkAppliedBindings or {}
    local states = MirageWardrobeCore.networkPlayerData or {}
    for playerKey, binding in pairs(bindings) do
        if type(binding) == "table" and binding.player == player and
                type(states[playerKey]) == "table" and
                binding.state == states[playerKey] then
            return true
        end
    end
    return false
end

MirageWardrobeCore.isCleanAppearanceEnabled = function (player)
    player = player or (getPlayer and getPlayer() or nil)
    if not player then return false end

    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    if previewState then return previewState.cleanAppearance == true end

    if isLocalPlayer(player) or not (isClient and isClient()) then
        local playerData = player.getModData and player:getModData() or nil
        return type(playerData) == "table" and
                playerData[MirageWardrobeCore.CLEAN_APPEARANCE_KEY] == true
    end

    local playerKey = MirageWardrobeCore.getPlayerSyncKey and
            MirageWardrobeCore.getPlayerSyncKey(player) or nil
    local state = playerKey and MirageWardrobeCore.networkPlayerData[playerKey] or nil
    if type(state) == "table" then return state.cleanAppearance == true end

    local playerData = player.getModData and player:getModData() or nil
    return type(playerData) == "table" and
            playerData[MirageWardrobeCore.CLEAN_APPEARANCE_KEY] == true
end

MirageWardrobeCore.getCleanAppearanceOptions = function (player)
    player = player or (getPlayer and getPlayer() or nil)
    if not player then return copyCleanAppearanceOptions(nil, false) end

    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    if previewState then
        return copyCleanAppearanceOptions(
                previewState.cleanAppearanceOptions, false)
    end

    if not isLocalPlayer(player) and isClient and isClient() then
        local playerKey = MirageWardrobeCore.getPlayerSyncKey and
                MirageWardrobeCore.getPlayerSyncKey(player) or nil
        local state = playerKey and MirageWardrobeCore.networkPlayerData[playerKey] or nil
        if type(state) == "table" then
            return copyCleanAppearanceOptions(
                    state.cleanAppearanceOptions, false)
        end
    end

    local playerData = player.getModData and player:getModData() or nil
    return copyCleanAppearanceOptions(type(playerData) == "table" and
            playerData[MirageWardrobeCore.CLEAN_APPEARANCE_OPTIONS_KEY] or nil, false)
end

local function getStateCleanAppearanceOptions(player, state)
    if type(state) == "table" and state.cleanAppearanceOptions ~= nil then
        return copyCleanAppearanceOptions(state.cleanAppearanceOptions, false)
    end
    return MirageWardrobeCore.getCleanAppearanceOptions(player)
end

MirageWardrobeCore.isHideOriginalClothingEnabled = function (player)
    player = player or (getPlayer and getPlayer() or nil)
    if not player then return false end

    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    if previewState then return previewState.hideOriginalClothing == true end

    if isLocalPlayer(player) or not (isClient and isClient()) then
        local playerData = player.getModData and player:getModData() or nil
        return type(playerData) == "table" and
                playerData[MirageWardrobeCore.HIDE_ORIGINAL_CLOTHING_KEY] == true
    end

    local playerKey = MirageWardrobeCore.getPlayerSyncKey and
            MirageWardrobeCore.getPlayerSyncKey(player) or nil
    local state = playerKey and MirageWardrobeCore.networkPlayerData[playerKey] or nil
    if type(state) == "table" then return state.hideOriginalClothing == true end

    local playerData = player.getModData and player:getModData() or nil
    return type(playerData) == "table" and
            playerData[MirageWardrobeCore.HIDE_ORIGINAL_CLOTHING_KEY] == true
end

MirageWardrobeCore.queueCleanAppearanceRefresh = function (player, delayTicks, desired,
        force, requiresModelReset)
    player = player or (getPlayer and getPlayer() or nil)
    if not player or MirageWardrobeCore.cleanAppearanceCaptureDisabled == true then return false end

    if type(desired) ~= "boolean" then
        desired = MirageWardrobeCore.isCleanAppearanceEnabled(player)
    end
    delayTicks = type(delayTicks) == "number" and math.max(0, math.floor(delayTicks)) or 0

    local pending = MirageWardrobeCore.cleanAppearancePending[player]
    local rendered = MirageWardrobeCore.cleanAppearanceRendered[player]
    local currentModel = getModelIdentity(player)
    if force ~= true and not pending and rendered and rendered.enabled == desired and
            (not currentModel or not rendered.model or rendered.model == currentModel) then
        return false
    end
    local normalizedDesired = desired == true
    local desiredChanged = pending and pending.desired ~= normalizedDesired
    local needsModelReset = requiresModelReset ~= false

    if not pending then
        pending = { delay = delayTicks, generation = 0, failureCount = 0 }
        MirageWardrobeCore.cleanAppearancePending[player] = pending
    elseif desiredChanged or force == true then
        -- A new target must not inherit a long exponential backoff from the
        -- opposite state. Explicit UI mutations also supersede a busy retry.
        pending.delay = delayTicks
    else
        pending.delay = math.max(pending.delay or 0, delayTicks)
    end
    pending.desired = normalizedDesired
    pending.requiresModelReset = pending.requiresModelReset == true or
            needsModelReset
    pending.generation = (pending.generation or 0) + 1
    if desiredChanged or force == true then
        pending.failureCount = 0
        pending.lastError = nil
    end
    return true
end

local function clearCleanAppearanceWear(visual, options)
    if not visual then error("ItemVisual wear API is unavailable") end
    options = copyCleanAppearanceOptions(options, false)
    if options.blood then
        if not visual.removeBlood then
            error("ItemVisual blood API is unavailable")
        end
        visual:removeBlood()
    end
    if not options.holes and not options.patches then return end
    if (options.holes and not visual.removeHole) or
            (options.patches and not visual.removePatch) then
        error("ItemVisual damage API is unavailable")
    end
    if not BloodBodyPartType or not BloodBodyPartType.MAX or
            not BloodBodyPartType.MAX.index then
        error("BloodBodyPartType API is unavailable")
    end
    local partCount = BloodBodyPartType.MAX:index()
    if type(partCount) ~= "number" or partCount < 0 then
        error("invalid body-part count")
    end
    for partIndex = 0, partCount - 1 do
        if options.holes then visual:removeHole(partIndex) end
        if options.patches then visual:removePatch(partIndex) end
    end
end

local applyVariantToVisual
local resolveDetachedVisualStyle
local getBodyLocationSortIndex
local getBodyLocationObjectForSlot
local getHoodieRenderSlot
local getRenderSlotForItem
local getRenderSlotForDonor
local getRenderCarrierForItem
local selectRenderRecords
local copyOriginalClothingOverrides
local shouldHideOriginalClothing

local function copyPreviewVisualIdentity(sourceVisual, targetVisual)
    if not sourceVisual or not targetVisual then return false end
    if targetVisual.setItemType and sourceVisual.getItemType then
        targetVisual:setItemType(sourceVisual:getItemType())
    end
    if targetVisual.setClothingItemName and sourceVisual.getClothingItemName then
        targetVisual:setClothingItemName(sourceVisual:getClothingItemName())
    end
    if targetVisual.setAlternateModelName and sourceVisual.getAlternateModelName then
        targetVisual:setAlternateModelName(sourceVisual:getAlternateModelName())
    end
    -- instanceItem() may create a random decal.  B42 copyVisualFrom() copies
    -- a source decal only when it is non-nil, so clear the clone first.
    if targetVisual.setDecal then targetVisual:setDecal(nil) end
    if targetVisual.copyVisualFrom then
        -- B42 ItemVisual.copyFrom() first calls pickUninitializedValues() on
        -- the source.  While Hide Originals is active that source temporarily
        -- resolves against Base.Belt2, destroying the real clothing style.
        -- copyVisualFrom() copies only raw identity fields and never mutates
        -- the real worn visual.
        targetVisual:copyVisualFrom(sourceVisual)
        return true
    end

    local mappings = {
        { "getHue", "setHue" },
        { "getTint", "setTint" },
        { "getBaseTexture", "setBaseTexture" },
        { "getTextureChoice", "setTextureChoice" },
    }
    for _, mapping in ipairs(mappings) do
        local getter = sourceVisual[mapping[1]]
        local setter = targetVisual[mapping[2]]
        if getter and setter then
            local ok, value = pcall(getter, sourceVisual)
            if ok then pcall(setter, targetVisual, value) end
        end
    end
    local decalOk, decal = pcall(function () return sourceVisual.decal end)
    if decalOk and targetVisual.setDecal then targetVisual:setDecal(decal) end
    return true
end

local function copyPreviewWear(sourceVisual, targetVisual)
    local methods = { "copyBlood", "copyDirt", "copyHoles", "copyPatches" }
    for _, methodName in ipairs(methods) do
        local method = targetVisual and targetVisual[methodName] or nil
        if not method or not sourceVisual then
            error("preview ItemVisual wear-copy API is unavailable")
        end
        method(targetVisual, sourceVisual)
    end
end

local function clonePreviewVisual(sourceVisual, cleanAppearance, cleanOptions)
    if not sourceVisual or not ItemVisual or not ItemVisual.new then return nil end
    local clone = ItemVisual.new()
    if not clone or not copyPreviewVisualIdentity(sourceVisual, clone) then
        return nil
    end
    copyPreviewWear(sourceVisual, clone)
    if cleanAppearance then clearCleanAppearanceWear(clone, cleanOptions) end
    if clone.setInventoryItem then clone:setInventoryItem(nil) end
    return clone
end

local function getColorComponent(color, floatMethod, plainMethod, field)
    if not color then return nil end
    if color[floatMethod] then
        local ok, value = pcall(color[floatMethod], color)
        if ok and isFiniteNumber(value) then return value end
    end
    if color[plainMethod] then
        local ok, value = pcall(color[plainMethod], color)
        if ok and isFiniteNumber(value) then
            return value > 1 and value / 255 or value
        end
    end
    local value = color[field]
    return isFiniteNumber(value) and value or nil
end

local function syncDetachedItemColor(cloneItem, cloneVisual, sourceItem, variant)
    local red, green, blue = nil, nil, nil
    if type(variant) == "table" and
            isFiniteNumber(variant.tintR) and
            isFiniteNumber(variant.tintG) and
            isFiniteNumber(variant.tintB) then
        red, green, blue =
                variant.tintR, variant.tintG, variant.tintB
    elseif sourceItem and sourceItem.isCustomColor then
        local customOk, custom = pcall(sourceItem.isCustomColor, sourceItem)
        if customOk and custom == true then
            local getters = {
                sourceItem.getColorRed,
                sourceItem.getColorGreen,
                sourceItem.getColorBlue,
            }
            if getters[1] and getters[2] and getters[3] then
                local rOk, r = pcall(getters[1], sourceItem)
                local gOk, g = pcall(getters[2], sourceItem)
                local bOk, b = pcall(getters[3], sourceItem)
                if rOk and gOk and bOk then red, green, blue = r, g, b end
            end
        end
    end
    if red == nil and cloneVisual and cloneVisual.getTint then
        local ok, tint = pcall(cloneVisual.getTint, cloneVisual)
        if ok and tint then
            red = getColorComponent(tint, "getRedFloat", "getRed", "r")
            green = getColorComponent(tint, "getGreenFloat", "getGreen", "g")
            blue = getColorComponent(tint, "getBlueFloat", "getBlue", "b")
        end
    end

    if isFiniteNumber(red) and isFiniteNumber(green) and
            isFiniteNumber(blue) and cloneItem.setColorRed and
            cloneItem.setColorGreen and cloneItem.setColorBlue then
        cloneItem:setColorRed(red)
        cloneItem:setColorGreen(green)
        cloneItem:setColorBlue(blue)
        if cloneItem.setCustomColor then cloneItem:setCustomColor(true) end
    end
    if cloneItem.synchWithVisual then cloneItem:synchWithVisual() end
end

local function cloneDetachedItemAppearance(sourceItem, cleanAppearance, cleanOptions)
    local ok, result = pcall(function ()
        local fullName = getItemFullName(sourceItem)
        if type(fullName) ~= "string" or fullName == "" then
            error("attached item type is unavailable")
        end
        local cloneItem = instanceItem(fullName)
        if not cloneItem then
            error("attached item clone is unavailable")
        end

        local sourceVisual = getItemVisual(sourceItem)
        local cloneVisual = getItemVisual(cloneItem)
        if sourceVisual and not cloneVisual then
            error("attached ItemVisual clone is unavailable")
        end
        if sourceVisual then
            if not copyPreviewVisualIdentity(sourceVisual, cloneVisual) then
                error("attached ItemVisual identity copy failed")
            end
            if cloneVisual.setInventoryItem then
                cloneVisual:setInventoryItem(cloneItem)
            end
            copyPreviewWear(sourceVisual, cloneVisual)
            if cleanAppearance == true then
                clearCleanAppearanceWear(cloneVisual, cleanOptions)
            end
        elseif cloneVisual and cleanAppearance == true then
            clearCleanAppearanceWear(cloneVisual, cleanOptions)
        end

        local colorMappings = {
            { "getColorRed", "setColorRed" },
            { "getColorGreen", "setColorGreen" },
            { "getColorBlue", "setColorBlue" },
        }
        for _, mapping in ipairs(colorMappings) do
            local getter = sourceItem[mapping[1]]
            local setter = cloneItem[mapping[2]]
            if getter then
                if not setter then
                    error("attached item color-copy API is unavailable")
                end
                local value = getter(sourceItem)
                setter(cloneItem, value)
            end
        end
        if sourceItem.isCustomColor then
            if not cloneItem.setCustomColor then
                error("attached item custom-color API is unavailable")
            end
            cloneItem:setCustomColor(sourceItem:isCustomColor() == true)
        end

        -- Some item subclasses derive their visible model from backing fields
        -- rather than InventoryItem.staticModel.  Copy those fields before
        -- modelIndex so the derived getter resolves to the same asset.
        local function copyModelList(value)
            if not value or not value.size or not value.get then return value end
            if ArrayList and ArrayList.new then
                local ok, copy = pcall(function () return ArrayList.new() end)
                if ok and copy and copy.add then
                    for index = 0, value:size() - 1 do
                        copy:add(value:get(index))
                    end
                    return copy
                end
            end
            return value
        end
        local backingMappings = {
            { "getWeaponSprite", "setWeaponSprite" },
            { "getWeaponSpritesByIndex", "setWeaponSpritesByIndex" },
            { "getModelWeaponPart", "setModelWeaponPart" },
            { "getStaticModelsByIndex", "setStaticModelsByIndex" },
            { "getWorldStaticModelsByIndex", "setWorldStaticModelsByIndex" },
        }
        for _, mapping in ipairs(backingMappings) do
            local getter = sourceItem[mapping[1]]
            if getter then
                local setter = cloneItem[mapping[2]]
                if not setter then
                    error("attached item model backing-copy API is unavailable")
                end
                setter(cloneItem, copyModelList(getter(sourceItem)))
            end
        end

        local scalarMappings = {
            { "getModelIndex", "setModelIndex" },
            { "getStaticModel", "setStaticModel" },
            { "getWorldStaticModel", "setWorldStaticModel" },
            { "getAttachedToModel", "setAttachedToModel" },
        }
        for _, mapping in ipairs(scalarMappings) do
            local getter = sourceItem[mapping[1]]
            if getter then
                local setter = cloneItem[mapping[2]]
                if not setter then
                    error("attached item model-copy API is unavailable")
                end
                local value = getter(sourceItem)
                -- String/ModelKey setter overloads are ambiguous for nil.
                -- A clone of the same script already has the same nil default.
                if value ~= nil then setter(cloneItem, value) end
            end
        end
        if sourceItem.getBloodLevel then
            if not cloneItem.setBloodLevel then
                error("attached item blood-copy API is unavailable")
            end
            local bloodLevel = cleanAppearance == true and
                    copyCleanAppearanceOptions(cleanOptions, false).blood and 0 or
                    sourceItem:getBloodLevel()
            cloneItem:setBloodLevel(bloodLevel)
        end

        if sourceItem.getFluidContainerFromSelfOrWorldItem then
            local sourceFluid =
                    sourceItem:getFluidContainerFromSelfOrWorldItem()
            if sourceFluid then
                if not cloneItem.getFluidContainerFromSelfOrWorldItem then
                    error("attached fluid clone API is unavailable")
                end
                local cloneFluid =
                        cloneItem:getFluidContainerFromSelfOrWorldItem()
                if not cloneFluid or not cloneFluid.copyFluidsFrom then
                    error("attached fluid copy API is unavailable")
                end
                cloneFluid:copyFluidsFrom(sourceFluid)
            end
        end

        if sourceItem.getAllWeaponParts then
            if not cloneItem.getAllWeaponParts or
                    not cloneItem.clearAllWeaponParts or
                    not cloneItem.setWeaponPart then
                error("attached weapon-part copy API is unavailable")
            end
            local parts = sourceItem:getAllWeaponParts()
            if not parts or not parts.size or not parts.get then
                error("attached weapon-part list is unavailable")
            end
            cloneItem:clearAllWeaponParts()
            for index = 0, parts:size() - 1 do
                local part = parts:get(index)
                if not part then
                    error("attached weapon-part record is incomplete")
                end
                cloneItem:setWeaponPart(part)
            end
        end

        local function detachedModelValuesEqual(left, right)
            if left == right then return true end
            if left == nil or right == nil then return false end
            -- Java String values can be distinct objects with equal content.
            return tostring(left) == tostring(right)
        end

        for _, mapping in ipairs({
            { "getModelIndex", "model index" },
            { "getStaticModel", "static model" },
            { "getWorldStaticModel", "world static model" },
            { "getAttachedToModel", "attached-to model" },
        }) do
            local sourceGetter = sourceItem[mapping[1]]
            local cloneGetter = cloneItem[mapping[1]]
            if sourceGetter then
                local sourceValue = sourceGetter(sourceItem)
                local cloneValue = cloneGetter and cloneGetter(cloneItem) or nil
                if not cloneGetter or
                        not detachedModelValuesEqual(sourceValue, cloneValue) then
                    error("attached item " .. mapping[2] ..
                            " did not clone exactly")
                end
            end
        end
        return cloneItem
    end)
    if not ok then return nil, result end
    return result
end

local function readAttachedItemRecords(attachedItems, cloneItems,
        cleanAppearance, cleanOptions)
    if not attachedItems or not attachedItems.size then
        return nil, "attached-items-api-unavailable"
    end
    local sizeOk, count = pcall(attachedItems.size, attachedItems)
    if not sizeOk or type(count) ~= "number" or count < 0 then
        return nil, "attached-items-count-unavailable"
    end

    local records = {}
    for index = 0, count - 1 do
        local item = nil
        local location = nil
        if attachedItems.getItemByIndex then
            local itemOk, value = pcall(
                    attachedItems.getItemByIndex, attachedItems, index)
            if itemOk then item = value end
        end
        if item and attachedItems.getLocation then
            local locationOk, value = pcall(
                    attachedItems.getLocation, attachedItems, item)
            if locationOk then location = value end
        end
        if (not item or not location) and attachedItems.get then
            local entryOk, entry = pcall(
                    attachedItems.get, attachedItems, index)
            if entryOk and entry then
                if not item then
                    item = safeNoArgMethod(entry, "getItem")
                end
                if not location then
                    location = safeNoArgMethod(entry, "getLocation")
                end
            end
        end
        if not item or type(location) ~= "string" or location == "" then
            local missing = {}
            if not item then missing[#missing + 1] = "item" end
            if type(location) ~= "string" or location == "" then
                missing[#missing + 1] = "location"
            end
            return nil, "attached-record-incomplete index=" ..
                    tostring(index) .. " missing=" ..
                    table.concat(missing, ",")
        end
        if cloneItems == true then
            local cloned, cloneError = cloneDetachedItemAppearance(
                    item, cleanAppearance == true, cleanOptions)
            if not cloned then
                return nil, "attached-clone-failed index=" ..
                        tostring(index) .. " location=" ..
                        compatibilityValue(location, 96) .. " item=" ..
                        compatibilityValue(getItemFullName(item), 160) ..
                        " detail=" .. compatibilityValue(cloneError, 256)
            end
            item = cloned
        end
        records[#records + 1] = {
            item = item,
            location = location,
        }
    end
    return records
end

local function replaceAttachedItems(attachedItems, records)
    if not attachedItems or not attachedItems.clear or
            not attachedItems.setItem then
        error("attached-items-swap-api-unavailable")
    end
    attachedItems:clear()
    for _, record in ipairs(records or {}) do
        attachedItems:setItem(record.location, record.item)
    end
end

local function copyPreviewHumanAppearance(source, target)
    if not source or not target or not target.clear then
        error("preview HumanVisual API is unavailable")
    end

    if not target.copyFrom then
        error("preview HumanVisual copy API is unavailable")
    end
    target:clear()
    target:copyFrom(source)
end

MirageWardrobeCore.createAppearancePreviewSurvivorDesc = function (player, cleanAppearance, state)
    player = player or (getPlayer and getPlayer() or nil)
    if not player or not SurvivorFactory or not SurvivorFactory.CreateSurvivor or
            not instanceItem then
        return nil, "preview-api-unavailable"
    end
    cleanAppearance = cleanAppearance == true
    local cleanOptions = getStateCleanAppearanceOptions(player, state)

    local ok, result, warning = pcall(function ()
        local previewDesc = SurvivorFactory.CreateSurvivor()
        if not previewDesc or not previewDesc.getHumanVisual or
                not previewDesc.getWornItems or not previewDesc.setWornItem then
            error("preview descriptor API is unavailable")
        end
        local copiedGender = false
        local sourceDescriptor = player.getDescriptor and player:getDescriptor() or nil
        if sourceDescriptor and sourceDescriptor.getCharacterGender and
                previewDesc.setCharacterGender then
            local genderOk, gender =
                    pcall(sourceDescriptor.getCharacterGender, sourceDescriptor)
            if genderOk and gender ~= nil then
                previewDesc:setCharacterGender(gender)
                copiedGender = true
            end
        end
        if not copiedGender and player.isFemale and previewDesc.setFemale then
            local femaleOk, female = pcall(player.isFemale, player)
            if femaleOk then
                previewDesc:setFemale(female == true)
            end
        end

        local sourceHumanVisual = player.getHumanVisual and player:getHumanVisual() or nil
        local previewHumanVisual = previewDesc:getHumanVisual()
        copyPreviewHumanAppearance(sourceHumanVisual, previewHumanVisual)

        -- Rebuild detached body visuals so previews never share mutable data
        -- with the real character. Old persistent proxies are ignored; current
        -- empty-slot appearances are added from saved slot state below.
        local previewBodyVisuals = nil
        if sourceHumanVisual.getBodyVisuals and previewHumanVisual.getBodyVisuals then
            local sourceBodyVisuals = sourceHumanVisual:getBodyVisuals()
            previewBodyVisuals = previewHumanVisual:getBodyVisuals()
            if sourceBodyVisuals and previewBodyVisuals and sourceBodyVisuals.size and
                    sourceBodyVisuals.get and previewBodyVisuals.clear and previewBodyVisuals.add then
                previewBodyVisuals:clear()
                for index = 0, sourceBodyVisuals:size() - 1 do
                    local sourceVisual = sourceBodyVisuals:get(index)
                    if not getVisualProxySlot(sourceVisual) then
                        local sourceType = sourceVisual and
                                sourceVisual.getItemType and
                                safeNoArgMethod(sourceVisual, "getItemType") or nil
                        local clone = clonePreviewVisual(
                                sourceVisual, cleanAppearance, cleanOptions)
                        if not clone then
                            return nil, "preview-body-visual-clone-failed index=" ..
                                    tostring(index) .. " item=" ..
                                    compatibilityValue(sourceType, 160) ..
                                    " detail=clone-api-unavailable"
                        end
                        if resolveDetachedVisualStyle and
                                not resolveDetachedVisualStyle(clone) then
                            return nil, "preview-body-visual-style-failed index=" ..
                                    tostring(index) .. " item=" ..
                                    compatibilityValue(sourceType, 160) ..
                                    " detail=style-unavailable"
                        end
                        previewBodyVisuals:add(clone)
                    end
                end
            end
        end

        -- A normalized state is supplied for remote/world captures. Direct UI
        -- callers keep using the player's current local tables.
        local stateIsTable = type(state) == "table"
        local transmogTable = stateIsTable and
                (type(state.transmogTable) == "table" and
                        state.transmogTable or state) or
                MirageWardrobeCore.getItemAppearanceMap(player)
        local slotTransmogTable = stateIsTable and
                (type(state.slotTransmogTable) == "table" and
                        state.slotTransmogTable or {}) or
                MirageWardrobeCore.getSlotTransmogTable(player)
        local slotVariantTable = stateIsTable and
                copySlotVariantMap(state.slotVariantTable, false,
                        slotTransmogTable) or
                MirageWardrobeCore.getSlotVariantTable(player)
        local hiddenItemsTable = stateIsTable and
                (type(state.hiddenItemsTable) == "table" and
                        state.hiddenItemsTable or {}) or
                MirageWardrobeCore.getHiddenSlotMap(player)
        local originalClothingOverrides = stateIsTable and
                copyOriginalClothingOverrides(
                        state.originalClothingOverrides, false) or
                MirageWardrobeCore.getOriginalClothingOverrides(player)
        local hideOriginalClothing = false
        if stateIsTable then
            hideOriginalClothing = state.hideOriginalClothing == true
        else
            hideOriginalClothing =
                    MirageWardrobeCore.isHideOriginalClothingEnabled(player)
        end
        local manager = getScriptManager and getScriptManager() or nil
        local occupiedSlots = {}

        local function validDonor(fullName)
            return type(fullName) == "string" and fullName ~= "" and
                    manager and manager.FindItem and manager:FindItem(fullName) ~= nil
        end

        local function resolveDonor(item, slot, fullName)
            local requestedDonor = slot and slotTransmogTable[slot] or nil
            requestedDonor = requestedDonor or
                    (fullName and transmogTable[fullName] or nil)
            local donorFullName = requestedDonor
            local variant = slot and slotVariantTable[slot] or nil
            local sourceKind = "original"
            if slot and hiddenItemsTable[getSlotHiddenKey(slot)] == true then
                donorFullName = MirageWardrobeCore.HIDDEN_VISUAL_TYPE
                variant = nil
                sourceKind = "slot-hidden"
            elseif requestedDonor ~= nil then
                if not validDonor(requestedDonor) then
                    warnCompatibility(
                            "local-missing-donor", requestedDonor, slot,
                            "saved donor script is unavailable; using the original appearance")
                    donorFullName = nil
                    variant = nil
                    if slot and shouldHideOriginalClothing(slot,
                            hideOriginalClothing, originalClothingOverrides) then
                        donorFullName = MirageWardrobeCore.HIDDEN_VISUAL_TYPE
                        sourceKind = "original-hidden"
                    end
                    return donorFullName, variant, sourceKind
                end
                sourceKind = "transmog"
            elseif slot and shouldHideOriginalClothing(slot,
                    hideOriginalClothing, originalClothingOverrides) then
                donorFullName = MirageWardrobeCore.HIDDEN_VISUAL_TYPE
                variant = nil
                sourceKind = "original-hidden"
            end
            if donorFullName == nil then return nil, nil, sourceKind end
            if not validDonor(donorFullName) then
                error("preview donor is unavailable")
            end
            return donorFullName, variant, sourceKind
        end

        local previewWornItems = previewDesc:getWornItems()
        if not previewWornItems or not previewWornItems.clear then
            return nil, "preview-worn-items-api-unavailable"
        end
        previewWornItems:clear()
        local wornGroup = previewWornItems.getBodyLocationGroup and
                previewWornItems:getBodyLocationGroup() or nil
        local sourceWornItems = player.getWornItems and player:getWornItems() or nil
        if not sourceWornItems or not sourceWornItems.size then
            return nil, "source-worn-items-api-unavailable"
        end
        local wornCandidates = {}

        local function createWornCandidate(item, locationObj, slot, sourceVisual,
                fullName, donorFullName, variant, sourceKind, sourceIndex)
            -- Instantiate the donor type itself. Retyping a clone of the
            -- receiver leaks receiver tint/texture/decal into the donor and
            -- breaks dedicated one-texture clothing.
            local cloneItem = instanceItem(donorFullName or fullName)
            local cloneVisual = getItemVisual(cloneItem)
            if not cloneItem or not cloneVisual then
                error("preview item clone API is unavailable")
            end
            if donorFullName then
                if not cloneVisual.setItemType then
                    error("preview donor visual API is unavailable")
                end
                cloneVisual:setItemType(donorFullName)
                if cloneVisual.setAlternateModelName then
                    cloneVisual:setAlternateModelName(nil)
                end
                if variant and applyVariantToVisual then
                    applyVariantToVisual(cloneVisual, variant)
                end
            elseif not copyPreviewVisualIdentity(sourceVisual, cloneVisual) then
                error("preview item clone API is unavailable")
            end
            copyPreviewWear(sourceVisual, cloneVisual)
            if cleanAppearance then
                clearCleanAppearanceWear(cloneVisual, cleanOptions)
            end
            syncDetachedItemColor(cloneItem, cloneVisual,
                    donorFullName and nil or item, variant)
            if resolveDetachedVisualStyle and
                    not resolveDetachedVisualStyle(cloneVisual) then
                error("preview worn-item style is unavailable")
            end

            -- Keep the donor's native body-location ordering. The receiver
            -- slot remains the state key, while the native donor location
            -- controls outside/inside and hide-model relationships in B42.
            local renderScript = manager:FindItem(donorFullName or fullName)
            local renderSlot = slot
            if donorFullName and
                    donorFullName ~= MirageWardrobeCore.HIDDEN_VISUAL_TYPE then
                renderSlot = getRenderSlotForDonor(item, renderScript, slot)
            elseif not donorFullName then
                renderSlot = getHoodieRenderSlot(renderScript) or slot
            end
            local carrierFullType, carrierScript =
                    getRenderCarrierForItem(renderScript)
            if carrierFullType and cloneVisual.setItemType then
                cloneVisual:setItemType(carrierFullType)
                renderScript = carrierScript
            end
            local renderFallback = tostring(renderSlot) == slot and
                    locationObj or nil
            local renderLocation = getBodyLocationObjectForSlot(
                    player, renderSlot, renderFallback)
            local locationKnown = renderLocation ~= nil
            if locationKnown and renderSlot ~= slot and wornGroup and
                    wornGroup.indexOf then
                local indexOk, locationIndex = pcall(
                        wornGroup.indexOf, wornGroup, renderLocation)
                locationKnown = indexOk and type(locationIndex) == "number" and
                        locationIndex >= 0
            end
            local bodyVisual = not locationKnown
            if bodyVisual and cloneVisual.setInventoryItem then
                cloneVisual:setInventoryItem(nil)
            end
            local priority = sourceKind == "transmog" and 30 or
                    (sourceKind == "slot-hidden" and 25 or
                    (sourceKind == "original-hidden" and 20 or 10))
            return {
                item = locationKnown and cloneItem or nil,
                location = locationKnown and renderLocation or nil,
                locationKnown = locationKnown,
                visual = cloneVisual,
                bodyVisual = bodyVisual,
                scriptItem = renderScript,
                appearanceType = donorFullName or fullName,
                sourceKind = sourceKind,
                carrierType = carrierFullType,
                compatibilityRoute = carrierFullType ~= nil,
                renderSlot = renderSlot,
                receiverSlot = slot,
                sourceIndex = sourceIndex,
                priority = priority,
            }
        end

        if sourceWornItems and sourceWornItems.size then
            for index = 0, sourceWornItems:size() - 1 do
                local itemContextType = nil
                local itemContextSlot = nil
                local donorContextType = nil
                local itemOk, itemComplete, itemError = pcall(function ()
                    local item = nil
                    local locationObj = nil
                    if sourceWornItems.getItemByIndex then
                        local getOk, value = pcall(
                                sourceWornItems.getItemByIndex,
                                sourceWornItems, index)
                        if getOk then item = value end
                    end
                    if item and sourceWornItems.getLocation then
                        local getOk, value = pcall(
                                sourceWornItems.getLocation,
                                sourceWornItems, item)
                        if getOk then locationObj = value end
                    end
                    if (not item or not locationObj) and sourceWornItems.get then
                        local entryOk, entry = pcall(
                                sourceWornItems.get, sourceWornItems, index)
                        if entryOk and entry then
                            if not item then
                                item = safeNoArgMethod(entry, "getItem")
                            end
                            if not locationObj then
                                locationObj = safeNoArgMethod(
                                        entry, "getLocation")
                            end
                        end
                    end
                    if item and not locationObj and
                            MirageWardrobeCore.getTransmogSourceSlot and
                            getBodyLocationObjectForSlot then
                        local sourceSlot =
                                MirageWardrobeCore.getTransmogSourceSlot(item)
                        if sourceSlot then
                            locationObj = getBodyLocationObjectForSlot(
                                    player, sourceSlot, nil)
                        end
                    end
                    local slot = locationObj and tostring(locationObj) or nil
                    if slot == "" then slot = nil end

                    local sourceVisual = getItemVisual(item)
                    local fullName = getItemFullName(item)
                    if (type(fullName) ~= "string" or fullName == "") and
                            sourceVisual and sourceVisual.getItemType then
                        local visualType, visualTypeOk = safeNoArgMethod(
                                sourceVisual, "getItemType")
                        if visualTypeOk and type(visualType) == "string" and
                                visualType ~= "" then
                            fullName = visualType
                        end
                    end
                    itemContextType = fullName
                    itemContextSlot = slot
                    if not item or not locationObj or not slot then
                        local missing = {}
                        if not item then missing[#missing + 1] = "item" end
                        if not locationObj then
                            missing[#missing + 1] = "location"
                        end
                        if not slot then missing[#missing + 1] = "slot" end
                        return false,
                                "source-worn-record-incomplete index=" ..
                                tostring(index) .. " missing=" ..
                                table.concat(missing, ",")
                    end
                    if not sourceVisual or type(fullName) ~= "string" or
                            fullName == "" then
                        local missing = {}
                        if not sourceVisual then
                            missing[#missing + 1] = "visual"
                        end
                        if type(fullName) ~= "string" or fullName == "" then
                            missing[#missing + 1] = "type"
                        end
                        warnCompatibility("local-worn-physical-only",
                                fullName, slot,
                                "index=" .. tostring(index) .. " missing=" ..
                                table.concat(missing, ",") ..
                                "; visual snapshot uses the saved slot donor")
                        return true
                    end

                    occupiedSlots[slot] = true
                    if item and locationObj and slot and sourceVisual and fullName then
                        local donorFullName, variant, sourceKind =
                                resolveDonor(item, slot, fullName)
                        donorContextType = donorFullName or fullName
                        local candidateOk, candidateOrError = pcall(
                                createWornCandidate, item, locationObj, slot,
                                sourceVisual, fullName, donorFullName, variant,
                                sourceKind, index)
                        if not candidateOk and sourceKind == "transmog" then
                            warnCompatibility("local-donor-fallback",
                                    donorFullName, slot, candidateOrError)
                            donorFullName = nil
                            variant = nil
                            sourceKind = "original"
                            if shouldHideOriginalClothing(slot,
                                    hideOriginalClothing,
                                    originalClothingOverrides) then
                                donorFullName =
                                        MirageWardrobeCore.HIDDEN_VISUAL_TYPE
                                sourceKind = "original-hidden"
                            end
                            donorContextType = donorFullName or fullName
                            candidateOk, candidateOrError = pcall(
                                    createWornCandidate, item, locationObj, slot,
                                    sourceVisual, fullName, donorFullName, variant,
                                    sourceKind, index)
                        end
                        if not candidateOk then
                            return false, tostring(candidateOrError)
                        end
                        wornCandidates[#wornCandidates + 1] = candidateOrError
                    end
                    return true
                end)
                if not itemOk then
                    warnCompatibility(
                            "local-worn-item", donorContextType or itemContextType,
                            itemContextSlot, itemComplete)
                    return nil, tostring(itemComplete)
                elseif itemComplete ~= true then
                    warnCompatibility(
                            "local-worn-item", donorContextType or itemContextType,
                            itemContextSlot, itemError)
                    return nil, tostring(itemError)
                end
            end
        end
        -- A saved slot can have no currently worn receiver. Put its donor in
        -- the detached descriptor's WornItems so Build 42 applies the same
        -- native ordering, hide-model, alt-model, and exclusivity rules as it
        -- does for ordinary clothing. The bridge installs these detached
        -- records only after world simulation and restores the physical list
        -- before UI/gameplay readers; persistent equipment is never changed.
        do
            local emptySlots = {}
            for slot, donorFullName in pairs(slotTransmogTable) do
                if type(slot) ~= "string" or slot == "" or
                        type(donorFullName) ~= "string" or
                        donorFullName == "" then
                    return nil, "saved-preview-slot-record-invalid"
                elseif not occupiedSlots[slot] and
                        donorFullName ~= MirageWardrobeCore.HIDDEN_VISUAL_TYPE and
                        hiddenItemsTable[getSlotHiddenKey(slot)] ~= true then
                    if not validDonor(donorFullName) then
                        warnCompatibility(
                                "local-missing-empty-donor", donorFullName, slot,
                                "saved donor script is unavailable; empty slot was skipped")
                    else
                        emptySlots[#emptySlots + 1] = slot
                    end
                end
            end
            table.sort(emptySlots, function (left, right)
                local leftDonor = slotTransmogTable[left]
                local rightDonor = slotTransmogTable[right]
                local leftScript = leftDonor and manager:FindItem(leftDonor) or nil
                local rightScript = rightDonor and manager:FindItem(rightDonor) or nil
                local leftRender = getRenderSlotForItem(leftScript, left)
                local rightRender = getRenderSlotForItem(rightScript, right)
                local leftIndex = getBodyLocationSortIndex(player, leftRender)
                local rightIndex = getBodyLocationSortIndex(player, rightRender)
                if leftIndex ~= rightIndex then return leftIndex < rightIndex end
                if leftRender ~= rightRender then
                    return tostring(leftRender or "") < tostring(rightRender or "")
                end
                return left < right
            end)
            if #emptySlots > MirageWardrobeCore.MAX_VISUAL_PROXIES then
                return nil, "preview-proxy-limit-exceeded count=" ..
                        tostring(#emptySlots)
            end
            for index = 1, #emptySlots do
                local slot = emptySlots[index]
                local donorFullName = slotTransmogTable[slot]
                local donorOk, donorError = pcall(function ()
                    local cloneItem = instanceItem(donorFullName)
                    local cloneVisual = getItemVisual(cloneItem)
                    if not cloneItem or not cloneVisual or
                            not cloneVisual.setItemType then
                        error("preview proxy clone API is unavailable")
                    end
                    cloneVisual:setItemType(donorFullName)
                    if cloneVisual.setAlternateModelName then
                        cloneVisual:setAlternateModelName(nil)
                    end
                    local variant = slotVariantTable[slot]
                    if variant and applyVariantToVisual then
                        applyVariantToVisual(cloneVisual, variant)
                    end
                    if cleanAppearance then
                        clearCleanAppearanceWear(cloneVisual, cleanOptions)
                    end
                    if resolveDetachedVisualStyle and
                            not resolveDetachedVisualStyle(cloneVisual) then
                        error("preview proxy style is unavailable")
                    end
                    local donorScript = manager:FindItem(donorFullName)
                    local renderSlot = getRenderSlotForItem(donorScript, slot)
                    local carrierFullType, carrierScript =
                            getRenderCarrierForItem(donorScript)
                    if carrierFullType and cloneVisual.setItemType then
                        cloneVisual:setItemType(carrierFullType)
                        donorScript = carrierScript
                    end
                    local renderLocation = getBodyLocationObjectForSlot(
                            player, renderSlot, nil)
                    local locationKnown = renderLocation ~= nil
                    if locationKnown and wornGroup and wornGroup.indexOf then
                        local indexOk, locationIndex = pcall(
                                wornGroup.indexOf, wornGroup, renderLocation)
                        locationKnown = indexOk and type(locationIndex) == "number" and
                                locationIndex >= 0
                    end
                    syncDetachedItemColor(cloneItem, cloneVisual, nil, variant)
                    wornCandidates[#wornCandidates + 1] = {
                        item = locationKnown and cloneItem or nil,
                        location = locationKnown and renderLocation or nil,
                        locationKnown = locationKnown,
                        visual = cloneVisual,
                        bodyVisual = not locationKnown,
                        scriptItem = donorScript,
                        appearanceType = donorFullName,
                        sourceKind = "transmog",
                        carrierType = carrierFullType,
                        compatibilityRoute = carrierFullType ~= nil,
                        renderSlot = renderSlot,
                        receiverSlot = slot,
                        sourceIndex = sourceWornItems:size() + index,
                        -- Keep an actual worn receiver ahead of an empty-slot
                        -- proxy when both resolve to the same native location.
                        priority = 29,
                    }
                    if not locationKnown and cloneVisual.setInventoryItem then
                        cloneVisual:setInventoryItem(nil)
                    end
                end)
                if not donorOk then
                    warnCompatibility("local-empty-donor-skip",
                            donorFullName, slot, donorError)
                end
            end
        end

        local selectedRecords = selectRenderRecords(
                player, wornCandidates, wornGroup)
        local selectedBodyVisualCount = 0
        for _, candidate in ipairs(selectedRecords) do
            if candidate.bodyVisual == true then
                selectedBodyVisualCount = selectedBodyVisualCount + 1
            end
        end
        local bodyVisualCount = previewBodyVisuals and previewBodyVisuals.size and
                previewBodyVisuals:size() or nil
        if selectedBodyVisualCount > 0 and
                (type(bodyVisualCount) ~= "number" or
                bodyVisualCount + selectedBodyVisualCount >
                        MirageWardrobeCore.MAX_BODY_VISUALS_WITH_PROXIES) then
            return nil, "preview-body-visual-limit-exceeded count=" ..
                    tostring(bodyVisualCount) .. " added=" ..
                    tostring(selectedBodyVisualCount)
        end
        for _, candidate in ipairs(selectedRecords) do
            if candidate.bodyVisual == true then
                previewBodyVisuals:add(candidate.visual)
            else
                previewDesc:setWornItem(candidate.location, candidate.item)
            end
        end
        return previewDesc
    end)
    if not ok then return nil, result end
    return result, warning
end

MirageWardrobeCore.createCleanPreviewSurvivorDesc = function (player)
    return MirageWardrobeCore.createAppearancePreviewSurvivorDesc(player, true)
end

MirageWardrobeCore.captureCleanAppearanceTextures = function (player, desired,
        requiresModelReset)
    if not MirageWardrobeCore.captureAppearanceTexturesImpl then
        return false, "appearance-capture-unavailable"
    end
    return MirageWardrobeCore.captureAppearanceTexturesImpl(player, desired == true,
            requiresModelReset ~= false)
end

local function inspectCleanAppearancePlayer(player, modelDelay)
    if not player then return end
    local cleanEnabled = MirageWardrobeCore.isCleanAppearanceEnabled(player)
    local tracksAppearance = cleanEnabled or
            (MirageWardrobeCore.shouldTrackAppearance and
                    MirageWardrobeCore.shouldTrackAppearance(player) == true)
    local pending = MirageWardrobeCore.cleanAppearancePending[player]
    local rendered = MirageWardrobeCore.cleanAppearanceRendered[player]
    local model = getModelIdentity(player)

    if not tracksAppearance then
        -- Keep the final restore request alive after the last transmog, hidden
        -- slot, Hide Originals, or Clean Appearance flag is removed.
        if pending then return end
        if rendered and (rendered.completionFrames or 0) > 0 then
            rendered.completionFrames = rendered.completionFrames - 1
            return
        end
        MirageWardrobeCore.cleanAppearanceRendered[player] = nil
        MirageWardrobeCore.activeAppearanceSnapshots[player] = nil
        MirageWardrobeCore.appearanceSnapshotFailures[player] = nil
        return
    end
    if pending then return end
    if not rendered or rendered.enabled ~= cleanEnabled or
            (model and model ~= rendered.model) then
        MirageWardrobeCore.queueCleanAppearanceRefresh(player,
                modelDelay or 0,
                cleanEnabled, true, true)
    end
end

MirageWardrobeCore.onCleanAppearanceTick = function ()
    if MirageWardrobeCore.cleanAppearanceCaptureDisabled == true then return end
    MirageWardrobeCore.cleanAppearanceTickCounter =
            (MirageWardrobeCore.cleanAppearanceTickCounter or 0) + 1

    local scanDue = MirageWardrobeCore.cleanAppearanceTickCounter %
            MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_SCAN_TICKS == 0
    local localPlayer = getPlayer and getPlayer() or nil
    local hasState = not isMapEmpty(MirageWardrobeCore.cleanAppearancePending) or
            not isMapEmpty(MirageWardrobeCore.cleanAppearanceRendered)
    if not hasState then return end

    -- Timed actions can either replace the native root model or queue a new
    -- full-character texture on the existing root without a clothing event.
    -- Inspect only the local model and its one active creator each frame; the
    -- render-boundary handler then replaces either kind of native update before
    -- the character is submitted.
    if localPlayer then
        inspectCleanAppearancePlayer(localPlayer, 0)
    end

    local remoteStateExists = false
    if scanDue then
        for renderedPlayer in pairs(MirageWardrobeCore.cleanAppearanceRendered) do
            if renderedPlayer ~= localPlayer then
                remoteStateExists = true
                break
            end
        end
        if not remoteStateExists then
            for pendingPlayer in pairs(MirageWardrobeCore.cleanAppearancePending) do
                if pendingPlayer ~= localPlayer then
                    remoteStateExists = true
                    break
                end
            end
        end
    end

    -- Remote model checks and stale-player cleanup are deliberately periodic.
    -- The old loop enumerated every online player and treated creator churn as
    -- a post-render recapture signal every frame, amplifying large-server cost.
    local trackedPlayers = nil
    local trackedListComplete = false
    local function ensureTrackedPlayers()
        if trackedPlayers == nil then
            trackedPlayers, trackedListComplete = collectTrackedPlayers()
        end
        return trackedPlayers, trackedListComplete
    end
    if scanDue and remoteStateExists then
        local tracked, complete = ensureTrackedPlayers()
        for trackedPlayer in pairs(tracked) do
            if trackedPlayer ~= localPlayer then
                inspectCleanAppearancePlayer(trackedPlayer, 0)
            end
        end
        if complete then
            for renderedPlayer in pairs(MirageWardrobeCore.cleanAppearanceRendered) do
                if renderedPlayer ~= localPlayer and not tracked[renderedPlayer] then
                    MirageWardrobeCore.cleanAppearanceRendered[renderedPlayer] = nil
                end
            end
        end
    end

    local captures = 0
    for player, pending in pairs(MirageWardrobeCore.cleanAppearancePending) do
        local playerIsTracked = player == localPlayer or
                hasCurrentNetworkBinding(player)
        local playerTrackingKnown = playerIsTracked
        if not playerIsTracked then
            local tracked, complete = ensureTrackedPlayers()
            playerIsTracked = tracked[player] == true
            playerTrackingKnown = complete
        end

        if playerTrackingKnown and not playerIsTracked then
            MirageWardrobeCore.cleanAppearancePending[player] = nil
            MirageWardrobeCore.cleanAppearanceRendered[player] = nil
        elseif not playerIsTracked then
            -- A transient online-list failure must not discard remote state.
            pending.delay = math.max(pending.delay or 0,
                    MirageWardrobeCore.CLEAN_APPEARANCE_RETRY_TICKS)
        elseif (pending.delay or 0) > 0 then
            pending.delay = pending.delay - 1
        elseif captures < MirageWardrobeCore.CLEAN_APPEARANCE_MAX_CAPTURES_PER_TICK then
            captures = captures + 1
            local captured, reason = MirageWardrobeCore.captureCleanAppearanceTextures(
                    player, pending.desired == true,
                    pending.requiresModelReset ~= false)
            if captured then
                if MirageWardrobeCore.rememberCapturedAppearance then
                    MirageWardrobeCore.rememberCapturedAppearance(
                            player, pending.desired == true)
                elseif pending.desired == true then
                    MirageWardrobeCore.cleanAppearanceRendered[player] = {
                        enabled = true,
                        model = getModelIdentity(player),
                    }
                else
                    MirageWardrobeCore.cleanAppearanceRendered[player] = nil
                end
                MirageWardrobeCore.cleanAppearancePending[player] = nil
            else
                if MirageWardrobeCore.cleanAppearanceCaptureDisabled == true then return end
                local transient = reason == "model-inactive" or
                        reason == "texture-creator-busy" or reason == "capture-busy"
                if reason == "texture-api-unavailable" then
                    MirageWardrobeCore.cleanAppearanceCaptureDisabled = true
                    MirageWardrobeCore.cleanAppearancePending = {}
                    MirageWardrobeCore.cleanAppearanceRendered = {}
                    print("[MirageWardrobe] Clean appearance is unsupported by this game build.")
                    return
                elseif transient then
                    pending.delay = MirageWardrobeCore.CLEAN_APPEARANCE_RETRY_TICKS
                else
                    pending.failureCount = (pending.failureCount or 0) + 1
                    local multiplier = 2 ^ math.min(pending.failureCount - 1, 7)
                    pending.delay = math.min(MirageWardrobeCore.CLEAN_APPEARANCE_MAX_RETRY_TICKS,
                            MirageWardrobeCore.CLEAN_APPEARANCE_RETRY_TICKS * multiplier)
                end
                local reasonText = tostring(reason)
                if not transient and pending.lastError ~= reasonText then
                    pending.lastError = reasonText
                    print("[MirageWardrobe] Clean appearance capture deferred: " ..
                            reasonText)
                end
            end
        end
    end
end

MirageWardrobeCore.setCleanAppearanceEnabled = function (enabled, player)
    player = player or (getPlayer and getPlayer() or nil)
    if not player or not player.getModData then return false end
    enabled = enabled == true

    if enabled and MirageWardrobeCore.cleanAppearanceCaptureDisabled == true then
        return false
    end

    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    local playerData = player:getModData()
    if previewState then
        previewState.cleanAppearanceOptions = copyCleanAppearanceOptions(
                previewState.cleanAppearanceOptions, false)
    else
        playerData[MirageWardrobeCore.CLEAN_APPEARANCE_OPTIONS_KEY] =
                copyCleanAppearanceOptions(
                        playerData[MirageWardrobeCore.CLEAN_APPEARANCE_OPTIONS_KEY], false)
    end
    local previous
    if previewState then
        previous = previewState.cleanAppearance == true
    else
        previous = playerData[MirageWardrobeCore.CLEAN_APPEARANCE_KEY] == true
    end
    if previous == enabled then return false end
    if previewState then
        previewState.cleanAppearance = enabled
    else
        playerData[MirageWardrobeCore.CLEAN_APPEARANCE_KEY] = enabled
    end

    -- Synchronize only the boolean state. The temporary render capture happens
    -- afterwards and never overlaps any save or network send.
    if isLocalPlayer(player) then MirageWardrobeCore.publishAppearanceState() end
    if not enabled and MirageWardrobeCore.cleanAppearanceCaptureDisabled == true then
        MirageWardrobeCore.cleanAppearancePending[player] = nil
        MirageWardrobeCore.cleanAppearanceRendered[player] = nil
        return true
    end
    -- The world model also owns attached tools/weapons. A clothing-only
    -- texture refresh leaves those mounted models dirty, so toggle the full
    -- model rebuild path for both enabling and disabling clean appearance.
    MirageWardrobeCore.queueCleanAppearanceRefresh(player, 0, enabled, true, true)
    return true
end

MirageWardrobeCore.setCleanAppearanceOptionEnabled = function (optionKey, enabled, player)
    if not CLEAN_APPEARANCE_OPTION_SET[optionKey] then return false end
    player = player or (getPlayer and getPlayer() or nil)
    if not player or not player.getModData then return false end

    local options = MirageWardrobeCore.getCleanAppearanceOptions(player)
    enabled = enabled == true
    if options[optionKey] == enabled then return false end
    options[optionKey] = enabled
    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    if previewState then
        previewState.cleanAppearanceOptions =
                copyCleanAppearanceOptions(options, false)
    else
        player:getModData()[MirageWardrobeCore.CLEAN_APPEARANCE_OPTIONS_KEY] =
                copyCleanAppearanceOptions(options, false)
    end

    if isLocalPlayer(player) then MirageWardrobeCore.publishAppearanceState() end
    if MirageWardrobeCore.isCleanAppearanceEnabled(player) then
        MirageWardrobeCore.queueCleanAppearanceRefresh(player, 0, true, true, true)
    end
    return true
end

MirageWardrobeCore.getHiddenSlotMap = function (player)
    player = player or getPlayer()
    if not player then return {} end

    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    if previewState then
        previewState.hiddenItemsTable = type(previewState.hiddenItemsTable) ==
                "table" and previewState.hiddenItemsTable or {}
        previewState.slotTransmogTable = type(previewState.slotTransmogTable) ==
                "table" and previewState.slotTransmogTable or {}
        migrateLegacyHiddenSlots(previewState.slotTransmogTable,
                previewState.hiddenItemsTable)
        return previewState.hiddenItemsTable
    end

    local playerData = player:getModData()
    if type(playerData.mirageWardrobeHiddenItemsTable) ~= "table" then playerData.mirageWardrobeHiddenItemsTable = {} end
    if type(playerData.mirageWardrobeSlotTransmogTable) ~= "table" then playerData.mirageWardrobeSlotTransmogTable = {} end
    migrateLegacyHiddenSlots(playerData.mirageWardrobeSlotTransmogTable, playerData.mirageWardrobeHiddenItemsTable)
    return playerData.mirageWardrobeHiddenItemsTable
end

local function copyWornVisualSlots(source)
    local result = {}
    if type(source) ~= "table" then return result end
    local limit = MirageWardrobeCore.MAX_STATE_WORN_VISUAL_ENTRIES or 128
    for index = 1, limit do
        local record = source[index]
        if record == nil then break end
        if type(record) ~= "table" or
                type(record.itemType) ~= "string" or record.itemType == "" or
                type(record.slot) ~= "string" or record.slot == "" or
                type(record.occurrence) ~= "number" or
                record.occurrence ~= math.floor(record.occurrence) or
                record.occurrence < 1 or record.occurrence > limit then
            return {}
        end
        result[index] = {
            itemType = record.itemType,
            slot = record.slot,
            occurrence = record.occurrence,
        }
    end
    return result
end

MirageWardrobeCore.getOriginalClothingOverrides = function (player)
    player = player or getPlayer()
    if not player then return {} end

    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    if previewState then
        previewState.originalClothingOverrides =
                copyOriginalClothingOverrides(
                        previewState.originalClothingOverrides, false)
        return previewState.originalClothingOverrides
    end

    if not isLocalPlayer(player) and isClient and isClient() then
        local playerKey = MirageWardrobeCore.getPlayerSyncKey and
                MirageWardrobeCore.getPlayerSyncKey(player) or nil
        local state = playerKey and MirageWardrobeCore.networkPlayerData[playerKey] or nil
        if type(state) == "table" then
            return copyOriginalClothingOverrides(
                    state.originalClothingOverrides, false)
        end
    end

    local playerData = player:getModData()
    local key = MirageWardrobeCore.ORIGINAL_CLOTHING_OVERRIDES_KEY
    local overrides = copyOriginalClothingOverrides(playerData[key], false)
    playerData[key] = overrides
    return overrides
end

MirageWardrobeCore.getOriginalClothingOverride = function (slot, player)
    if slot == nil then return nil end
    slot = tostring(slot)
    if slot == "" then return nil end
    return MirageWardrobeCore.getOriginalClothingOverrides(player)[slot]
end

MirageWardrobeCore.getItemAppearanceMap = function (player)
    player = player or getPlayer()
    if not player then return {} end

    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    if previewState then
        previewState.transmogTable = type(previewState.transmogTable) ==
                "table" and previewState.transmogTable or {}
        return previewState.transmogTable
    end

    local playerData = player:getModData()
    if type(playerData.mirageWardrobeTransmogTable) ~= "table" then playerData.mirageWardrobeTransmogTable = {} end
    return playerData.mirageWardrobeTransmogTable
end

MirageWardrobeCore.getSlotTransmogTable = function (player)
    player = player or getPlayer()
    if not player then return {} end

    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    if previewState then
        previewState.slotTransmogTable = type(previewState.slotTransmogTable) ==
                "table" and previewState.slotTransmogTable or {}
        previewState.hiddenItemsTable = type(previewState.hiddenItemsTable) ==
                "table" and previewState.hiddenItemsTable or {}
        migrateLegacyHiddenSlots(previewState.slotTransmogTable,
                previewState.hiddenItemsTable)
        return previewState.slotTransmogTable
    end

    local playerData = player:getModData()
    if type(playerData.mirageWardrobeSlotTransmogTable) ~= "table" then playerData.mirageWardrobeSlotTransmogTable = {} end
    if type(playerData.mirageWardrobeHiddenItemsTable) ~= "table" then playerData.mirageWardrobeHiddenItemsTable = {} end
    migrateLegacyHiddenSlots(playerData.mirageWardrobeSlotTransmogTable, playerData.mirageWardrobeHiddenItemsTable)
    return playerData.mirageWardrobeSlotTransmogTable
end

MirageWardrobeCore.getSlotVariantTable = function (player)
    player = player or getPlayer()
    if not player then return {} end

    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    if previewState then
        local sanitized = copySlotVariantMap(
                previewState.slotVariantTable, false,
                MirageWardrobeCore.getSlotTransmogTable(player))
        previewState.slotVariantTable = sanitized
        return sanitized
    end

    local playerData = player:getModData()
    local slotTransmogTable = MirageWardrobeCore.getSlotTransmogTable(player)
    local sanitized = copySlotVariantMap(playerData.mirageWardrobeSlotVariantTable, false, slotTransmogTable)
    playerData.mirageWardrobeSlotVariantTable = sanitized
    return sanitized
end

MirageWardrobeCore.isUnsupportedItem = function (item)
    return getItemFullName(item) == "Base.KeyRing"
end

local function hasLocation(value)
    return value ~= nil and tostring(value) ~= ""
end

local function normalizeSlot(value)
    if not hasLocation(value) then return nil end
    return tostring(value)
end

MirageWardrobeCore.getItemWornSlot = function (item, player)
    player = player or getPlayer()
    if not item or not player or not player.getWornItems then return nil end

    local wornItems = player:getWornItems()
    if not wornItems or not wornItems.getLocation then return nil end

    local succeeded, location = pcall(wornItems.getLocation, wornItems, item)
    if succeeded then
        return normalizeSlot(location)
    end
    return nil
end

MirageWardrobeCore.getItemPreferredSlot = function (item, player)
    if not item then return nil end

    local wornSlot = MirageWardrobeCore.getItemWornSlot(item, player)
    if wornSlot then return wornSlot end

    if item.getBodyLocation then
        local bodyValue = safeNoArgMethod(item, "getBodyLocation")
        local bodyLocation = normalizeSlot(bodyValue)
        if bodyLocation then return bodyLocation end
    end
    if item.canBeEquipped then
        local equipValue = safeNoArgMethod(item, "canBeEquipped")
        local equipLocation = normalizeSlot(equipValue)
        if equipLocation then return equipLocation end
    end

    local scriptItem = getItemScript(item)
    if scriptItem and scriptItem.getBodyLocation then
        local bodyValue = safeNoArgMethod(scriptItem, "getBodyLocation")
        return normalizeSlot(bodyValue)
    end
    return nil
end

local function isHeldInHands(item, player)
    player = player or getPlayer()
    if not item or not player then return false end

    local primaryItem = player.getPrimaryHandItem and player:getPrimaryHandItem() or nil
    local secondaryItem = player.getSecondaryHandItem and player:getSecondaryHandItem() or nil
    return item == primaryItem or item == secondaryItem
end

local function getScriptItemEquipLocation(scriptItem)
    if not scriptItem then return nil, false end

    local succeeded = false
    local runtimeItem = nil

    -- B42's official Script.Item factory uses nil to keep its default clothing palette.
    if scriptItem.InstanceItem then
        succeeded, runtimeItem = pcall(scriptItem.InstanceItem, scriptItem, nil)
    end

    -- Compatibility fallback for builds/mod environments exposing only the global helper.
    if (not succeeded or not runtimeItem) and instanceItem then
        succeeded, runtimeItem = pcall(instanceItem, scriptItem)
    end

    if not succeeded or not runtimeItem or not runtimeItem.canBeEquipped then
        return nil, false
    end

    local equipSucceeded, equipLocation = pcall(runtimeItem.canBeEquipped, runtimeItem)
    if equipSucceeded then
        return equipLocation, true
    end
    return nil, false
end

MirageWardrobeCore.getTransmogSourceSlot = function (item)
    local scriptItem = getItemScript(item) or item
    if not scriptItem then return nil end

    local fullName = getItemFullName(scriptItem)
    local cached = fullName and MirageWardrobeCore.transmogSourceSlotCache[fullName] or nil
    if cached ~= nil then
        return cached == false and nil or cached
    end

    local slot = nil
    local resolved = true
    if scriptItem.getBodyLocation then
        local bodyLocation, bodyResolved = safeNoArgMethod(scriptItem, "getBodyLocation")
        slot = normalizeSlot(bodyLocation)
        resolved = bodyResolved
    end

    if not slot then
        local equipLocation = nil
        equipLocation, resolved = getScriptItemEquipLocation(scriptItem)
        slot = normalizeSlot(equipLocation)
    end

    if fullName and resolved then
        MirageWardrobeCore.transmogSourceSlotCache[fullName] = slot or false
    end
    return slot
end

local function getBloodClothingRegionSet(item)
    local scriptItem = getItemScript(item) or item
    if not scriptItem or not scriptItem.getBloodClothingType then return {} end
    local fullName = getItemFullName(scriptItem)
    local cached = fullName and
            MirageWardrobeCore.transmogCoverageCache[fullName] or nil
    if cached ~= nil then return cached end
    local ok, clothingTypes = pcall(
            scriptItem.getBloodClothingType, scriptItem)
    if not ok or not clothingTypes or not BloodClothingType or
            not BloodClothingType.getCoveredParts then
        return {}
    end
    local coveredOk, values = pcall(
            BloodClothingType.getCoveredParts, clothingTypes)
    if not coveredOk or not values then return {} end

    local result = {}
    local size = nil
    if values.size then
        local sizeOk, value = pcall(values.size, values)
        if sizeOk then size = value end
    end
    if type(size) == "number" then
        for index = 0, size - 1 do
            local value = nil
            if values.get then
                local getOk, entry = pcall(values.get, values, index)
                if getOk then value = entry end
            end
            if value ~= nil then result[string.lower(tostring(value))] = true end
        end
    elseif type(values) == "table" then
        for _, value in pairs(values) do
            if value ~= nil then result[string.lower(tostring(value))] = true end
        end
    end
    if fullName then
        MirageWardrobeCore.transmogCoverageCache[fullName] = result
    end
    return result
end

local function coverageSetsOverlap(left, right)
    for region in pairs(left or {}) do
        if right and right[region] then return true end
    end
    return false
end

local function normalizedSlotName(slot)
    local value = string.lower(tostring(slot or ""))
    local separator = string.find(value, ":", 1, true)
    if separator then value = string.sub(value, separator + 1) end
    return string.gsub(value, "[^%w]", "")
end

local function slotNameContainsAny(name, hints)
    for _, hint in ipairs(hints) do
        if string.find(name, hint, 1, true) then return true end
    end
    return false
end

local function getExplicitReplacementFamily(slot)
    local name = normalizedSlotName(slot)
    if name == "" or slotNameContainsAny(name,
            { "underwear", "underpants", "bra", "bikini", "socks", "shoes" }) then
        return nil
    end
    if slotNameContainsAny(name, {
            "shirt", "tshirt", "sweater", "jersey", "jacket",
            "torsoextra", "upperbody", "chest", "vest", "apron", "cuirass",
    }) then
        return "upper-garment"
    end
    if slotNameContainsAny(name, {
            "pants", "trouser", "shorts", "skirt", "lowerbody", "legwear",
    }) then
        return "lower-garment"
    end
    if slotNameContainsAny(name, { "knee", "calf", "shin" }) then
        if string.find(name, "left", 1, true) then return "left-leg-guard" end
        if string.find(name, "right", 1, true) then return "right-leg-guard" end
    end
    if slotNameContainsAny(name, { "elbow", "forearm" }) then
        if string.find(name, "left", 1, true) then return "left-arm-guard" end
        if string.find(name, "right", 1, true) then return "right-arm-guard" end
    end
    return nil
end

local function getHumanBodyLocationGroup()
    if not BodyLocations or not BodyLocations.getGroup then return nil end
    local ok, group = pcall(BodyLocations.getGroup, "Human")
    if ok then return group end
    return nil
end

local function getRegisteredBodyLocation(group, slot)
    if not group or not group.indexOf or not ItemBodyLocation or
            not ItemBodyLocation.get or not ResourceLocation or
            not ResourceLocation.of then
        return nil
    end
    local resourceOk, resource = pcall(ResourceLocation.of, tostring(slot or ""))
    if not resourceOk or not resource then return nil end
    local locationOk, location = pcall(ItemBodyLocation.get, resource)
    if not locationOk or not location then return nil end
    local indexOk, index = pcall(group.indexOf, group, location)
    if not indexOk or type(index) ~= "number" or index < 0 then return nil end
    return location
end

local function slotPairCacheKey(leftSlot, rightSlot)
    local left = string.lower(tostring(leftSlot or ""))
    local right = string.lower(tostring(rightSlot or ""))
    if right < left then left, right = right, left end
    return left .. "\31" .. right
end

local function areSlotsDeclaredReplaceable(leftSlot, rightSlot)
    local key = slotPairCacheKey(leftSlot, rightSlot)
    local cached = MirageWardrobeCore.transmogSlotReplacementCache[key]
    if cached ~= nil then return cached == true end

    local replaceable = false
    local leftFamily = getExplicitReplacementFamily(leftSlot)
    local rightFamily = getExplicitReplacementFamily(rightSlot)
    if leftFamily and leftFamily == rightFamily then
        replaceable = true
    else
        local group = getHumanBodyLocationGroup()
        local leftLocation = getRegisteredBodyLocation(group, leftSlot)
        local rightLocation = getRegisteredBodyLocation(group, rightSlot)
        if leftLocation and rightLocation and group and group.isExclusive then
            local leftOk, leftExclusive = pcall(
                    group.isExclusive, group, leftLocation, rightLocation)
            local rightOk, rightExclusive = pcall(
                    group.isExclusive, group, rightLocation, leftLocation)
            replaceable = (leftOk and leftExclusive == true) or
                    (rightOk and rightExclusive == true)
        end
    end

    MirageWardrobeCore.transmogSlotReplacementCache[key] = replaceable
    return replaceable
end

MirageWardrobeCore.getTransmogCompatibilityKind = function (
        receiverItem, donorItem, receiverSlot, donorSlot)
    receiverSlot = receiverSlot and tostring(receiverSlot) or
            MirageWardrobeCore.getTransmogSourceSlot(receiverItem)
    donorSlot = donorSlot and tostring(donorSlot) or
            MirageWardrobeCore.getTransmogSourceSlot(donorItem)
    if receiverSlot and donorSlot and
            string.lower(receiverSlot) == string.lower(donorSlot) then
        return "exact"
    end
    if not receiverItem or not donorItem then return "none" end

    local receiverRegions = getBloodClothingRegionSet(receiverItem)
    local donorRegions = getBloodClothingRegionSet(donorItem)
    local receiverHasRegion = not isMapEmpty(receiverRegions)
    local donorHasRegion = not isMapEmpty(donorRegions)
    if not receiverHasRegion or not donorHasRegion or
            not coverageSetsOverlap(receiverRegions, donorRegions) then
        return "none"
    end
    if receiverSlot and donorSlot and
            areSlotsDeclaredReplaceable(receiverSlot, donorSlot) then
        return "replacement"
    end
    return "related"
end

MirageWardrobeCore.areTransmogItemsCompatible = function (
        receiverItem, donorItem, receiverSlot, donorSlot)
    local kind = MirageWardrobeCore.getTransmogCompatibilityKind(
            receiverItem, donorItem, receiverSlot, donorSlot)
    return kind == "exact" or kind == "replacement"
end

MirageWardrobeCore.canBeUsedAsTransmogSource = function (item)
    if not item or MirageWardrobeCore.isUnsupportedItem(item) then return false end

    local scriptItem = getItemScript(item) or item
    local fullName = getItemFullName(scriptItem)
    if fullName and MirageWardrobeCore.transmogSourceEligibilityCache[fullName] ~= nil then
        return MirageWardrobeCore.transmogSourceEligibilityCache[fullName]
    end

    local resolved = true
    local isClothing = false
    if scriptItem.isItemType then
        local ok, value = pcall(scriptItem.isItemType, scriptItem, ItemType.CLOTHING)
        if ok then
            isClothing = value == true
        else
            resolved = false
        end
    end

    local bodyLocation = nil
    if scriptItem.getBodyLocation then
        local value, ok = safeNoArgMethod(scriptItem, "getBodyLocation")
        if ok then bodyLocation = value else resolved = false end
    end

    local hasClothingDefinition = false
    if scriptItem.getClothingItem then
        local clothingItem, ok = safeNoArgMethod(scriptItem, "getClothingItem")
        if ok then
            hasClothingDefinition = hasLocation(clothingItem)
        else
            resolved = false
        end
    end

    -- getClothingItem() is the stable script declaration. Do not require the asset
    -- object here because mod assets can still be lazy-loaded when this list opens.
    local eligible = hasClothingDefinition and (isClothing or hasLocation(bodyLocation))
    if eligible then resolved = true end

    -- Containers and radios store their wearable location in CanBeEquipped, which
    -- Script.Item doesn't expose through a getter. Instantiate only this small set
    -- of unresolved candidates and cache the answer. This excludes hand-only cases.
    if not eligible and hasClothingDefinition then
        local equipLocation = nil
        equipLocation, resolved = getScriptItemEquipLocation(scriptItem)
        eligible = hasLocation(equipLocation)
    end

    -- Cache confirmed true/false answers, but never a transient instantiation error.
    if fullName and resolved then
        MirageWardrobeCore.transmogSourceEligibilityCache[fullName] = eligible == true
    end
    return eligible == true
end

MirageWardrobeCore.isSupportedReceiverItem = function (item, player)
    if not item or MirageWardrobeCore.isUnsupportedItem(item) then return false end

    -- Script.Item objects are list donors, while InventoryItem objects are targets.
    if not item.getScriptItem then
        return MirageWardrobeCore.canBeUsedAsTransmogSource(item)
    end

    if isHeldInHands(item, player) then return false end

    local scriptItem = getItemScript(item) or item
    local isClothing = false
    if item.isItemType then
        local ok, value = pcall(item.isItemType, item, ItemType.CLOTHING)
        if ok then isClothing = value == true end
    elseif scriptItem.isItemType then
        local ok, value = pcall(scriptItem.isItemType, scriptItem, ItemType.CLOTHING)
        if ok then isClothing = value == true end
    end

    local hasClothingDefinition = false
    if scriptItem.getClothingItem then
        local clothingItem, ok = safeNoArgMethod(scriptItem, "getClothingItem")
        if ok then hasClothingDefinition = hasLocation(clothingItem) end
    end
    local bodyLocation = item.getBodyLocation and safeNoArgMethod(item, "getBodyLocation") or nil
    local equipLocation = item.canBeEquipped and safeNoArgMethod(item, "canBeEquipped") or nil

    -- ItemVisual can be nil briefly while a mod ClothingItem asset is still loading.
    -- The mapping is still valid and will be applied on the next clothing update.
    return hasClothingDefinition and
            (isClothing or hasLocation(bodyLocation) or hasLocation(equipLocation))
end

local function getGameplayEngine()
    return type(MirageWardrobeGameplay) == "table" and
            MirageWardrobeGameplay or nil
end

local function isGameplayMultiplayerClient()
    return isClient and isClient() == true
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

MirageWardrobeCore.getGameplayRules = function ()
    local engine = getGameplayEngine()
    if not engine then return fallbackGameplayRules() end

    if isGameplayMultiplayerClient() and type(MirageWardrobeCore.networkGameplayRules) == "table" then
        return engine.sanitizeRules(MirageWardrobeCore.networkGameplayRules)
    end

    if not isGameplayMultiplayerClient() and
            type(MirageWardrobeCore.localGameplayRules) == "table" then
        return engine.sanitizeRules(MirageWardrobeCore.localGameplayRules)
    end

    if not isGameplayMultiplayerClient() and ModData and ModData.getOrCreate then
        local ok, root = pcall(ModData.getOrCreate, MirageWardrobeCore.RULES_MODDATA_KEY)
        if ok and type(root) == "table" and type(root.rules) == "table" then
            return engine.sanitizeRules(root.rules)
        end
    end
    return engine.rulesFromSandbox()
end

MirageWardrobeCore.getGameplayRulesAuthority = function ()
    local multiplayer = isGameplayMultiplayerClient()
    local revision = MirageWardrobeCore.networkGameplayRulesRevision or 0
    if not multiplayer and ModData and ModData.getOrCreate then
        local ok, root = pcall(ModData.getOrCreate, MirageWardrobeCore.RULES_MODDATA_KEY)
        if ok and type(root) == "table" and type(root.revision) == "number" then
            revision = math.max(0, math.floor(root.revision))
        end
    end
    return {
        canEdit = not multiplayer,
        source = multiplayer and "server" or "world",
        revision = revision,
    }
end

MirageWardrobeCore.setGameplayRules = function (rules)
    local engine = getGameplayEngine()
    if not engine or isGameplayMultiplayerClient() then return false end

    local sanitized = engine.sanitizeRules(rules)
    if not sanitized then return false end
    if ModData and ModData.getOrCreate and ModData.add then
        local ok, root = pcall(ModData.getOrCreate, MirageWardrobeCore.RULES_MODDATA_KEY)
        if not ok or type(root) ~= "table" then return false end
        root.rules = sanitized
        root.revision = (type(root.revision) == "number" and root.revision or 0) + 1
        ModData.add(MirageWardrobeCore.RULES_MODDATA_KEY, root)
    else
        MirageWardrobeCore.localGameplayRules = sanitized
    end
    MirageWardrobeCore.networkGameplayRules = nil
    MirageWardrobeCore.gameplayAccessSnapshot = nil
    MirageWardrobeCore.lastGameplayDenial = nil
    if MirageWardrobeCore.refreshGameplayState then
        MirageWardrobeCore.refreshGameplayState(getPlayer(), true)
    end
    return true
end

local function getLocalAccountCollection(player, create)
    local engine = getGameplayEngine()
    if not engine or not ModData or not ModData.getOrCreate then return nil, nil end
    local ok, root = pcall(ModData.getOrCreate, MirageWardrobeCore.COLLECTION_MODDATA_KEY)
    if not ok or type(root) ~= "table" then return nil, nil end

    local key = MirageWardrobeCore.getPlayerSyncKey(player) or "local-player"
    if type(root.accounts) ~= "table" then root.accounts = {} end
    local record = root.accounts[key]
    if type(record) ~= "table" and type(root[key]) == "table" then
        -- Migrate the brief pre-release layout that stored account records
        -- directly beside the collection metadata.
        record = root[key]
        root[key] = nil
    end
    if type(record) ~= "table" then
        if not create then return nil, root end
        record = engine.newCollection()
        root.accounts[key] = record
    else
        record = engine.sanitizeCollection(record)
        root.accounts[key] = record
    end
    return record, root
end

MirageWardrobeCore.getGameplayCollection = function (player, create)
    local engine = getGameplayEngine()
    if not engine then return { version = 1, items = {}, styles = {} } end
    player = player or getPlayer()
    if not player then return engine.newCollection() end

    local rules = MirageWardrobeCore.getGameplayRules()
    if isGameplayMultiplayerClient() then
        local record = engine.sanitizeCollection(MirageWardrobeCore.networkGameplayCollection)
        MirageWardrobeCore.networkGameplayCollection = record
        return record
    end

    if rules.collectionScope == "account" then
        local record = getLocalAccountCollection(player, create ~= false)
        return record or engine.newCollection()
    end

    local playerData = player.getModData and player:getModData() or nil
    if type(playerData) ~= "table" then return engine.newCollection() end
    local record = playerData[MirageWardrobeCore.CHARACTER_COLLECTION_KEY]
    if type(record) ~= "table" then
        if create == false then return engine.newCollection() end
        record = engine.newCollection()
    else
        record = engine.sanitizeCollection(record)
    end
    playerData[MirageWardrobeCore.CHARACTER_COLLECTION_KEY] = record
    return record
end

local function persistLocalGameplayCollection(player, rules)
    if isGameplayMultiplayerClient() or not rules or
            rules.collectionScope ~= "account" then return end
    if not ModData or not ModData.add then return end
    local _, root = getLocalAccountCollection(player, true)
    if root then ModData.add(MirageWardrobeCore.COLLECTION_MODDATA_KEY, root) end
end

MirageWardrobeCore.loadGameplaySnapshot = function (rules, collection, revision)
    local engine = getGameplayEngine()
    if not engine then return false end
    MirageWardrobeCore.networkGameplayRules = engine.sanitizeRules(rules)
    MirageWardrobeCore.networkGameplayRulesRevision =
            type(revision) == "number" and math.max(0, math.floor(revision)) or
            MirageWardrobeCore.networkGameplayRulesRevision or 0
    MirageWardrobeCore.networkGameplayCollection = engine.sanitizeCollection(collection)
    MirageWardrobeCore.networkGameplayCollectionRevision =
            type(revision) == "number" and math.max(0, math.floor(revision)) or 0
    MirageWardrobeCore.gameplayAccessSnapshot = nil
    -- Rebuild once on the next player update so an already-open wardrobe sees
    -- new server rules/collection data without restoring periodic polling.
    MirageWardrobeCore.gameplayAccessDirty = true
    MirageWardrobeCore.gameplayAccessDirtyDelay = 0
    MirageWardrobeCore.gameplayDiscoveryPending = false
    return true
end

MirageWardrobeCore.refreshGameplayState = function (player, force)
    local engine = getGameplayEngine()
    player = player or getPlayer()
    if not engine or not player then return nil end

    local rules = MirageWardrobeCore.getGameplayRules()
    local existing = MirageWardrobeCore.gameplayAccessSnapshot
    if existing and not MirageWardrobeCore.gameplayAccessDirty then
        if force ~= true then return existing end
        local existingRules = type(existing.rules) == "table" and
                existing.rules or nil
        if rules.accessMode == "all" and existingRules and
                existingRules.accessMode == "all" then
            -- Free access is independent of inventory, containers and position.
            -- A forced permission check must reuse this immutable snapshot.
            return existing
        end
    end

    local collectionMode = rules.accessMode == "unlocked" or
            rules.accessMode == "unlocked_or_nearby" or
            rules.accessMode == "unlocked_and_nearby"
    local collection = nil
    if collectionMode then
        collection = MirageWardrobeCore.getGameplayCollection(player, true)
    elseif engine.newCollection then
        -- Nearby, held and free access do not consult collection history. Keep
        -- their hot refresh path independent of an account's potentially large
        -- persistent collection.
        collection = engine.newCollection()
    else
        collection = { items = {}, styles = {} }
    end
    local changed = false
    if collectionMode and engine.scanDiscovery then
        local ok, result =
                pcall(engine.scanDiscovery, player, collection, rules)
        changed = ok and result == true
    end
    if changed then
        persistLocalGameplayCollection(player, rules)
        if isGameplayMultiplayerClient() and sendClientCommand then
            MirageWardrobeCore.ensureNetworkSession()
            sendClientCommand(player, MirageWardrobeCore.NETWORK_MODULE, "Discover", {
                session = MirageWardrobeCore.networkSessionId,
            })
            MirageWardrobeCore.gameplayDiscoveryPending = true
        end
    end

    local snapshot = nil
    local ok = true
    if rules.accessMode == "all" then
        -- buildAccessSnapshot() always scans held inventory. Free access never
        -- consumes that data, so construct its one stable snapshot directly.
        local sanitizedCollection = engine.sanitizeCollection and
                engine.sanitizeCollection(collection) or collection
        snapshot = {
            rules = rules,
            collection = sanitizedCollection,
            held = { items = {}, styles = {} },
            nearby = { items = {}, styles = {} },
        }
    else
        ok, snapshot = pcall(engine.buildAccessSnapshot,
                player, collection, rules)
    end

    if ok and type(snapshot) == "table" then
        local equivalent = false
        if existing and type(engine.accessSnapshotsEqual) == "function" then
            local compareOk, same = pcall(
                    engine.accessSnapshotsEqual, existing, snapshot)
            equivalent = compareOk and same == true
        end
        if equivalent then
            snapshot = existing
        else
            MirageWardrobeCore.gameplayAccessRevision =
                    (MirageWardrobeCore.gameplayAccessRevision or 0) + 1
            snapshot.revision = MirageWardrobeCore.gameplayAccessRevision
        end
        MirageWardrobeCore.gameplayAccessSnapshot = snapshot
    else
        MirageWardrobeCore.gameplayAccessRevision =
                (MirageWardrobeCore.gameplayAccessRevision or 0) + 1
        MirageWardrobeCore.gameplayAccessSnapshot = {
            rules = rules,
            collection = collection,
            held = { items = {}, styles = {} },
            nearby = { items = {}, styles = {} },
            revision = MirageWardrobeCore.gameplayAccessRevision,
        }
    end
    MirageWardrobeCore.gameplayAccessDirty = false
    MirageWardrobeCore.gameplayAccessDirtyDelay = 0
    MirageWardrobeCore.gameplayAccessLastRefreshTick =
            MirageWardrobeCore.gameplayAccessUpdateTick or 0
    local currentSquare = nil
    if player.getCurrentSquare then
        currentSquare = safeNoArgMethod(player, "getCurrentSquare")
    end
    if not currentSquare and player.getSquare then
        currentSquare = safeNoArgMethod(player, "getSquare")
    end
    MirageWardrobeCore.gameplayAccessSquare = currentSquare
    return MirageWardrobeCore.gameplayAccessSnapshot
end

MirageWardrobeCore.getAppearanceAccess = function (fullName, variant, player, force, snapshot)
    local engine = getGameplayEngine()
    if not engine then
        return { available = true, reason = "free", unlocked = true,
            held = true, nearby = true }
    end
    player = player or getPlayer()
    snapshot = snapshot or MirageWardrobeCore.refreshGameplayState(player, force == true)
    local ok, result = false, nil
    if type(snapshot) == "table" and
            type(engine.evaluatePrepared) == "function" then
        ok, result = pcall(engine.evaluatePrepared, fullName, variant, snapshot)
    else
        local rules = MirageWardrobeCore.getGameplayRules()
        ok, result = pcall(engine.evaluate, fullName, variant, snapshot, rules)
    end
    if not ok or type(result) ~= "table" then
        return { available = false, reason = "unavailable", unlocked = false,
            held = false, nearby = false }
    end
    return result
end

MirageWardrobeCore.canApplyAppearance = function (fullName, variant, player, force, snapshot)
    local access = MirageWardrobeCore.getAppearanceAccess(fullName, variant,
            player, force, snapshot)
    return access.available == true, access.reason, access
end

MirageWardrobeCore.getCollectionProgress = function (catalog, player)
    local engine = getGameplayEngine()
    local collection = MirageWardrobeCore.getGameplayCollection(player or getPlayer(), true)
    local itemCount, styleCount = 0, 0
    if engine and engine.getCollectionCounts then
        itemCount, styleCount = engine.getCollectionCounts(collection)
    end
    local total = 0
    local seen = {}
    for _, entry in ipairs(catalog or {}) do
        local fullName = entry and entry.fullName or nil
        if fullName and not seen[fullName] then
            seen[fullName] = true
            total = total + 1
        end
    end
    return {
        unlockedItems = itemCount or 0,
        unlockedStyles = styleCount or 0,
        totalItems = total,
    }
end

local function readPlayerKeyValue(player, methodName, stringify)
    local method = player and player[methodName] or nil
    if type(method) ~= "function" then return nil end
    local ok, value = pcall(method, player)
    if not ok or value == nil then return nil end
    if stringify then value = tostring(value) end
    if type(value) == "string" and value ~= "" then return value end
    return nil
end

MirageWardrobeCore.getPlayerSyncKey = function (player)
    player = player or getPlayer()
    if not player then return nil end

    local localPlayer = getPlayer()
    if isClient and isClient() and localPlayer and player == localPlayer and
            type(MirageWardrobeCore.networkAuthenticatedPlayerKey) == "string" and
            MirageWardrobeCore.networkAuthenticatedPlayerKey ~= "" then
        return MirageWardrobeCore.networkAuthenticatedPlayerKey
    end

    local keySources = {
        { method = "getUsername", stringify = false },
        { method = "getPlayerNum", stringify = true },
    }
    for _, source in ipairs(keySources) do
        local key = readPlayerKeyValue(player, source.method, source.stringify)
        if key then return key end
    end
    return nil
end
local function makeNetworkSessionId()
    MirageWardrobeCore.networkSessionCounter = (MirageWardrobeCore.networkSessionCounter or 0) + 1

    local timestamp = "0"
    if getTimestampMs then
        local ok, value = pcall(getTimestampMs)
        if ok and value ~= nil then timestamp = tostring(value) end
    end

    local randomValue = "0"
    if ZombRand then
        local ok, value = pcall(ZombRand, 2147483647)
        if ok and value ~= nil then randomValue = tostring(value) end
    end

    return tostring(MirageWardrobeCore.getPlayerSyncKey() or "player") .. ":" .. timestamp .. ":" ..
            randomValue .. ":" .. tostring(MirageWardrobeCore.networkSessionCounter)
end

MirageWardrobeCore.ensureNetworkSession = function ()
    if type(MirageWardrobeCore.networkSessionId) ~= "string" or MirageWardrobeCore.networkSessionId == "" then
        MirageWardrobeCore.networkSessionId = makeNetworkSessionId()
        MirageWardrobeCore.networkUpdateSequence = 0
        MirageWardrobeCore.outfitPresetUpdateSequence = 0
    end
    return MirageWardrobeCore.networkSessionId
end

MirageWardrobeCore.beginNetworkSession = function ()
    -- A previous world can exit between OnTick and OnPostRender. Restore the
    -- physical collections before clearing player-keyed bridge records.
    if MirageWardrobeCore.endAppearanceRenderBridges then
        MirageWardrobeCore.endAppearanceRenderBridges()
    end
    MirageWardrobeCore.networkRevision = 0
    MirageWardrobeCore.networkPlayerData = {}
    MirageWardrobeCore.networkPlayerRevisions = {}
    MirageWardrobeCore.networkPlayerStateSources = {}
    MirageWardrobeCore.networkSessionId = nil
    MirageWardrobeCore.networkUpdateSequence = 0
    MirageWardrobeCore.lastPublishedWornVisualSlotSignature = nil
    MirageWardrobeCore.outfitPresetUpdateSequence = 0
    MirageWardrobeCore.localMutationGeneration = 0
    MirageWardrobeCore.outfitPresetMutationGeneration = 0
    MirageWardrobeCore.networkSnapshotPending = false
    MirageWardrobeCore.networkSnapshotRequestGeneration = 0
    MirageWardrobeCore.networkPresetSnapshotRequestGeneration = 0
    MirageWardrobeCore.networkSnapshotRequestAttempts = 0
    MirageWardrobeCore.networkSnapshotRetryUpdates = 0
    MirageWardrobeCore.networkSnapshotRequestId = 0
    MirageWardrobeCore.networkSnapshotCompletedRequestId = nil
    MirageWardrobeCore.networkAuthenticatedPlayerKey = nil
    MirageWardrobeCore.networkGameplayRules = nil
    MirageWardrobeCore.networkGameplayRulesRevision = 0
    MirageWardrobeCore.networkGameplayCollection = nil
    MirageWardrobeCore.networkGameplayCollectionRevision = 0
    MirageWardrobeCore.gameplayAccessSnapshot = nil
    MirageWardrobeCore.gameplayAccessDirty = false
    MirageWardrobeCore.gameplayAccessDirtyDelay = 0
    MirageWardrobeCore.gameplayAccessRevision = 0
    MirageWardrobeCore.gameplayAccessSquare = nil
    MirageWardrobeCore.gameplayAccessUpdateTick = 0
    MirageWardrobeCore.gameplayAccessLastRefreshTick = nil
    MirageWardrobeCore.gameplayDiscoveryPending = false
    MirageWardrobeCore.lastGameplayDenial = nil
    MirageWardrobeCore.serverOutfitPresetLibrary = {}
    MirageWardrobeCore.cleanAppearancePending = {}
    MirageWardrobeCore.cleanAppearanceRendered = {}
    MirageWardrobeCore.appearanceWearSignatures = {}
    MirageWardrobeCore.appearanceRevisions = {}
    MirageWardrobeCore.fixedTextureTrackingCache = {}
    MirageWardrobeCore.renderCompatibilityCache = {}
    MirageWardrobeCore.compatibilityWarnings = {}
    MirageWardrobeCore.cleanAppearanceTickCounter = 0
    MirageWardrobeCore.cleanAppearancePreCharacterRenderSeen = false
    MirageWardrobeCore.isCapturingCleanAppearance = false
    MirageWardrobeCore.appearanceCapturePlayers = {}
    MirageWardrobeCore.activeAppearanceSnapshots = {}
    MirageWardrobeCore.appearanceRenderBridges = {}
    MirageWardrobeCore.appearanceSnapshotFailures = {}
    MirageWardrobeCore.cleanAppearanceCaptureDisabled = false
    MirageWardrobeCore.networkSessionInitialized = true
    return MirageWardrobeCore.ensureNetworkSession()
end
MirageWardrobeCore.markLocalMutation = function ()
    MirageWardrobeCore.localMutationGeneration = (MirageWardrobeCore.localMutationGeneration or 0) + 1
    return MirageWardrobeCore.localMutationGeneration
end

MirageWardrobeCore.findPlayerByNetworkKey = function (playerKey)
    if not playerKey then return nil end

    local localPlayer = getPlayer()
    if localPlayer and MirageWardrobeCore.getPlayerSyncKey(localPlayer) == playerKey then
        return localPlayer
    end

    if not getOnlinePlayers then return nil end
    local players = getOnlinePlayers()
    if not players then return nil end

    for index = 0, players:size() - 1 do
        local player = players:get(index)
        if player and MirageWardrobeCore.getPlayerSyncKey(player) == playerKey then
            return player
        end
    end
    return nil
end

local function readClothingExtraSubmenu(item)
    if not item then return nil end

    -- The getter is exposed by InventoryItem/Clothing.  Script.Item only
    -- exposes the backing field to Java, which Kahlua cannot read reliably.
    local submenu, submenuOk = safeNoArgMethod(
            item, "getClothingExtraSubmenu")
    if submenuOk and type(submenu) == "string" and submenu ~= "" then
        return submenu
    end

    local fieldOk, field = pcall(function ()
        return item.clothingExtraSubmenu
    end)
    if fieldOk and type(field) == "string" and field ~= "" then
        return field
    end
    return nil
end

local function getClothingExtraSubmenu(item, scriptItem)
    local submenu = readClothingExtraSubmenu(item)
    if submenu then return submenu end

    scriptItem = scriptItem or getItemScript(item) or item
    submenu = readClothingExtraSubmenu(scriptItem)
    if submenu then return submenu end

    -- Donor routes often start with Script.Item rather than a physical
    -- Clothing instance.  Build one metadata-only instance so B42's public
    -- Clothing getter remains available without mutating worn equipment.
    local fullName = getItemFullName(scriptItem)
    if type(fullName) ~= "string" or fullName == "" or not instanceItem then
        return nil
    end
    local cache = MirageWardrobeCore.hoodieSubmenuCache
    if cache[fullName] ~= nil then
        return cache[fullName] ~= false and cache[fullName] or nil
    end

    local instanceOk, metadataItem = pcall(instanceItem, fullName)
    if instanceOk and metadataItem then
        submenu = readClothingExtraSubmenu(metadataItem)
    end
    cache[fullName] = submenu or false
    return submenu
end

local function makeWornVisualSlots(player)
    if not player then return {} end
    local result = {}
    local occurrences = {}
    local limit = MirageWardrobeCore.MAX_STATE_WORN_VISUAL_ENTRIES or 128

    local function append(item, location)
        local visual = getItemVisual(item)
        if not visual then return true end
        local itemType = visual.getItemType and visual:getItemType() or nil
        local slot = location and tostring(location) or nil
        if type(itemType) ~= "string" or itemType == "" or
                type(slot) ~= "string" or slot == "" or
                string.len(itemType) > 256 or string.len(slot) > 256 or
                string.find(itemType, "%c") or string.find(slot, "%c") or
                #result >= limit then
            return false
        end
        occurrences[itemType] = (occurrences[itemType] or 0) + 1
        result[#result + 1] = {
            itemType = itemType,
            slot = slot,
            occurrence = occurrences[itemType],
        }
        return true
    end

    local bridge = MirageWardrobeCore.appearanceRenderBridges and
            MirageWardrobeCore.appearanceRenderBridges[player] or nil
    if bridge and type(bridge.originalWornItems) == "table" then
        for _, record in ipairs(bridge.originalWornItems) do
            if not append(record.item, record.location) then return {} end
        end
        return result
    end

    local wornItems = player.getWornItems and player:getWornItems() or nil
    if not wornItems or not wornItems.size or not wornItems.getItemByIndex then
        return result
    end
    for index = 0, wornItems:size() - 1 do
        local item = wornItems:getItemByIndex(index)
        local location = nil
        if item and wornItems.getLocation then
            local locationOk, value = pcall(
                    wornItems.getLocation, wornItems, item)
            if locationOk then location = value end
        end
        if not append(item, location) then return {} end
    end
    return result
end

local function getWornVisualSlotSignature(records)
    local signature = { tostring(type(records) == "table" and #records or 0) }
    for _, record in ipairs(records or {}) do
        signature[#signature + 1] = record.itemType
        signature[#signature + 1] = tostring(record.occurrence)
        signature[#signature + 1] = record.slot
    end
    return table.concat(signature, "\31")
end

local function copyAppearanceState(source, player)
    if type(source) ~= "table" then return nil end

    local transmogSource = source.transmogTable
    if transmogSource == nil and source.slotTransmogTable == nil and
            source.slotVariantTable == nil and source.hiddenItemsTable == nil and
            source.originalClothingOverrides == nil and
            source.cleanAppearance == nil and
            source.cleanAppearanceOptions == nil and
            source.hideOriginalClothing == nil then
        transmogSource = source
    end
    local slotTransmogTable = copyStringMap(source.slotTransmogTable)
    local state = {
        transmogTable = copyStringMap(transmogSource),
        slotTransmogTable = slotTransmogTable,
        slotVariantTable = copySlotVariantMap(
                source.slotVariantTable, false, slotTransmogTable),
        hiddenItemsTable = copyBooleanMap(source.hiddenItemsTable),
        originalClothingOverrides = copyOriginalClothingOverrides(
                source.originalClothingOverrides, false),
        wornVisualSlots = source.wornVisualSlots ~= nil and
                copyWornVisualSlots(source.wornVisualSlots) or
                (player and makeWornVisualSlots(player) or {}),
        cleanAppearance = source.cleanAppearance == true,
        cleanAppearanceOptions = copyCleanAppearanceOptions(
                source.cleanAppearanceOptions, false),
        hideOriginalClothing = source.hideOriginalClothing == true,
    }
    migrateLegacyHiddenSlots(state.slotTransmogTable, state.hiddenItemsTable)
    return state
end

local function makeCommittedPlayerState(player)
    if not player or not player.getModData then return nil end
    local playerData = player:getModData()
    local slotTransmogTable = copyStringMap(
            playerData.mirageWardrobeSlotTransmogTable)
    local state = {
        transmogTable = copyStringMap(playerData.mirageWardrobeTransmogTable),
        slotTransmogTable = slotTransmogTable,
        slotVariantTable = copySlotVariantMap(
                playerData.mirageWardrobeSlotVariantTable, false,
                slotTransmogTable),
        hiddenItemsTable = copyBooleanMap(
                playerData.mirageWardrobeHiddenItemsTable),
        originalClothingOverrides = copyOriginalClothingOverrides(
                playerData[MirageWardrobeCore.ORIGINAL_CLOTHING_OVERRIDES_KEY],
                false),
        wornVisualSlots = makeWornVisualSlots(player),
        cleanAppearance = playerData[
                MirageWardrobeCore.CLEAN_APPEARANCE_KEY] == true,
        cleanAppearanceOptions = copyCleanAppearanceOptions(
                playerData[MirageWardrobeCore.CLEAN_APPEARANCE_OPTIONS_KEY],
                false),
        hideOriginalClothing = playerData[
                MirageWardrobeCore.HIDE_ORIGINAL_CLOTHING_KEY] == true,
    }
    migrateLegacyHiddenSlots(state.slotTransmogTable, state.hiddenItemsTable)
    return state
end

MirageWardrobeCore.makePlayerState = function (player)
    player = player or getPlayer()
    if not player then return nil end
    local previewState = getActiveAppearancePreviewState(player)
    if previewState then
        local state = copyAppearanceState(previewState, player)
        state.wornVisualSlots = makeWornVisualSlots(player)
        return state
    end
    return makeCommittedPlayerState(player)
end

-- Wardrobe dialogs use a reversible local transaction for live previews.
-- The owner reference and generation make the in-memory snapshot a scoped
-- cancellation token; neither field is copied into Player ModData or network state.
MirageWardrobeCore.captureAppearancePreviewState = function (player)
    player = player or getPlayer()
    if not player then return nil end
    local state = MirageWardrobeCore.makePlayerState(player)
    if not state then return nil end
    MirageWardrobeCore.appearancePreviewTokenGeneration =
            (MirageWardrobeCore.appearancePreviewTokenGeneration or 0) + 1
    state._appearancePreviewOwner = player
    state._appearancePreviewGeneration =
            MirageWardrobeCore.appearancePreviewTokenGeneration
    return state
end

local function isAppearancePreviewTokenFor(state, player)
    return type(state) == "table" and player ~= nil and
            state._appearancePreviewOwner == player and
            type(state._appearancePreviewGeneration) == "number"
end

local function transactionMatchesAppearancePreviewToken(transaction, state, player)
    return transaction ~= nil and isAppearancePreviewTokenFor(state, player) and
            transaction.owner == player and
            transaction.tokenGeneration == state._appearancePreviewGeneration
end

local function beginAppearancePreviewTransaction(player, originalState)
    if not isAppearancePreviewTokenFor(originalState, player) then return nil, false end
    local transactions = MirageWardrobeCore.appearancePreviewTransactions
    local transaction = transactions[player]
    if transaction then
        if transactionMatchesAppearancePreviewToken(
                transaction, originalState, player) then
            return transaction, false
        end
        return nil, false
    end
    local baselineState = copyAppearanceState(originalState, player)
    if not baselineState then return nil, false end
    transaction = {
        owner = player,
        tokenGeneration = originalState._appearancePreviewGeneration,
        originalState = baselineState,
        previewState = copyAppearanceState(baselineState, player),
        pendingPublish = false,
        pendingMarkDirty = false,
    }
    transactions[player] = transaction
    return transaction, true
end

local function finishAppearancePreviewTransaction(player, tokenState)
    local transactions = MirageWardrobeCore.appearancePreviewTransactions
    local transaction = player and transactions[player] or nil
    if tokenState and not transactionMatchesAppearancePreviewToken(
            transaction, tokenState, player) then
        return nil
    end
    if transaction then transactions[player] = nil end
    return transaction
end

local function discardAppearancePreviewToken(state)
    if type(state) ~= "table" then return nil end
    local owner = state._appearancePreviewOwner
    if not owner then return nil end
    return finishAppearancePreviewTransaction(owner, state)
end

local function canCommitAppearancePreview(player, tokenState)
    local transaction = player and
            MirageWardrobeCore.appearancePreviewTransactions[player] or nil
    if tokenState ~= nil and not isAppearancePreviewTokenFor(
            tokenState, player) then
        discardAppearancePreviewToken(tokenState)
        return false
    end
    if transaction and not transactionMatchesAppearancePreviewToken(
            transaction, tokenState, player) then
        return false
    end
    return true
end

MirageWardrobeCore.isAppearancePreviewActive = function (player)
    player = player or getPlayer()
    return player ~= nil and
            MirageWardrobeCore.appearancePreviewTransactions[player] ~= nil
end

MirageWardrobeCore.publishAppearanceState = function (markDirty)
    local player = getPlayer()
    if not player then return false end

    local previewTransaction =
            MirageWardrobeCore.appearancePreviewTransactions[player]
    if previewTransaction then
        previewTransaction.pendingPublish = true
        previewTransaction.pendingMarkDirty = previewTransaction.pendingMarkDirty == true or
                markDirty ~= false
        return false
    end

    if markDirty ~= false then
        MirageWardrobeCore.markLocalMutation()
        MirageWardrobeCore.markAppearanceChanged(player)
    end
    local state = MirageWardrobeCore.makePlayerState(player)
    if not isClient() then return true end
    MirageWardrobeCore.ensureNetworkSession()
    MirageWardrobeCore.networkUpdateSequence =
            (MirageWardrobeCore.networkUpdateSequence or 0) + 1
    MirageWardrobeCore.lastPublishedWornVisualSlotSignature =
            getWornVisualSlotSignature(state.wornVisualSlots)
    state._clientSession = MirageWardrobeCore.networkSessionId
    state._clientSequence = MirageWardrobeCore.networkUpdateSequence
    sendClientCommand(player, MirageWardrobeCore.NETWORK_MODULE, "Update", state)
    return true
end

local function sendPendingNetworkSnapshotRequest(player)
    if not isClient() or MirageWardrobeCore.networkSnapshotPending ~= true then return false end

    player = player or getPlayer()
    if not player then return false end

    MirageWardrobeCore.ensureNetworkSession()
    MirageWardrobeCore.networkSnapshotRequestAttempts =
            (MirageWardrobeCore.networkSnapshotRequestAttempts or 0) + 1
    MirageWardrobeCore.networkSnapshotRetryUpdates = 0
    sendClientCommand(player, MirageWardrobeCore.NETWORK_MODULE, "Request", {
        session = MirageWardrobeCore.networkSessionId,
        requestId = MirageWardrobeCore.networkSnapshotRequestId,
        requestGeneration = MirageWardrobeCore.networkSnapshotRequestGeneration,
        presetGeneration = MirageWardrobeCore.networkPresetSnapshotRequestGeneration,
        outfitPresets = MirageWardrobeCore.makeOutfitPresetSnapshot and
                MirageWardrobeCore.makeOutfitPresetSnapshot(player) or {},
    })
    return true
end

MirageWardrobeCore.requestAppearanceSnapshot = function ()
    if not isClient() then return false end

    MirageWardrobeCore.ensureNetworkSession()
    MirageWardrobeCore.networkSnapshotPending = true
    MirageWardrobeCore.networkSnapshotRequestGeneration = MirageWardrobeCore.localMutationGeneration or 0
    MirageWardrobeCore.networkPresetSnapshotRequestGeneration =
            MirageWardrobeCore.outfitPresetMutationGeneration or 0
    MirageWardrobeCore.networkSnapshotRequestAttempts = 0
    MirageWardrobeCore.networkSnapshotRetryUpdates = 0
    MirageWardrobeCore.networkSnapshotRequestId = (MirageWardrobeCore.networkSnapshotRequestId or 0) + 1
    MirageWardrobeCore.networkSnapshotCompletedRequestId = nil


    -- The directed command Snapshot is the only authoritative MP restore path.
    -- Keep its mutation generations stable across retries so a delayed response
    -- cannot overwrite an edit made after the first Request.
    return sendPendingNetworkSnapshotRequest(getPlayer())
end

MirageWardrobeCore.onNetworkSnapshotPlayerUpdate = function (player)
    if not isClient() or MirageWardrobeCore.networkSnapshotPending ~= true then return end
    local localPlayer = getPlayer()
    if not localPlayer or (player and player ~= localPlayer) then return end

    if (MirageWardrobeCore.networkSnapshotRequestAttempts or 0) == 0 then
        sendPendingNetworkSnapshotRequest(localPlayer)
        return
    end
    local retryUpdates = (MirageWardrobeCore.networkSnapshotRequestAttempts or 0) <
            MirageWardrobeCore.NETWORK_SNAPSHOT_MAX_ATTEMPTS and
            MirageWardrobeCore.NETWORK_SNAPSHOT_RETRY_UPDATES or
            MirageWardrobeCore.NETWORK_SNAPSHOT_SLOW_RETRY_UPDATES
    MirageWardrobeCore.networkSnapshotRetryUpdates =
            (MirageWardrobeCore.networkSnapshotRetryUpdates or 0) + 1
    if MirageWardrobeCore.networkSnapshotRetryUpdates >=
            retryUpdates then
        sendPendingNetworkSnapshotRequest(localPlayer)
    end
end
MirageWardrobeCore.loadPlayerTransmogState = function (state, player)
    if type(state) ~= "table" then return false end

    player = player or getPlayer()
    if not player then return false end


    local transmogTable = state.transmogTable
    local slotTransmogTable = state.slotTransmogTable
    local slotVariantTable = state.slotVariantTable
    local hiddenItemsTable = state.hiddenItemsTable
    local originalClothingOverrides = state.originalClothingOverrides
    local cleanAppearance = state.cleanAppearance
    local cleanAppearanceOptions = state.cleanAppearanceOptions
    local hideOriginalClothing = state.hideOriginalClothing

    -- Compatibility with the old format, where the state itself was the transmog map.
    if transmogTable == nil and slotTransmogTable == nil and slotVariantTable == nil and
            hiddenItemsTable == nil and originalClothingOverrides == nil and
            cleanAppearance == nil and
            cleanAppearanceOptions == nil and hideOriginalClothing == nil then
        transmogTable = state
    end

    local playerData = player:getModData()
    playerData.mirageWardrobeTransmogTable = copyStringMap(transmogTable)
    playerData.mirageWardrobeSlotTransmogTable = copyStringMap(slotTransmogTable)
    playerData.mirageWardrobeSlotVariantTable = copySlotVariantMap(slotVariantTable, false,
            playerData.mirageWardrobeSlotTransmogTable)
    playerData.mirageWardrobeHiddenItemsTable = copyBooleanMap(hiddenItemsTable)
    playerData[MirageWardrobeCore.ORIGINAL_CLOTHING_OVERRIDES_KEY] =
            copyOriginalClothingOverrides(originalClothingOverrides, false)
    playerData[MirageWardrobeCore.CLEAN_APPEARANCE_KEY] = cleanAppearance == true
    playerData[MirageWardrobeCore.CLEAN_APPEARANCE_OPTIONS_KEY] =
            copyCleanAppearanceOptions(cleanAppearanceOptions, false)
    playerData[MirageWardrobeCore.HIDE_ORIGINAL_CLOTHING_KEY] =
            hideOriginalClothing == true
    migrateLegacyHiddenSlots(playerData.mirageWardrobeSlotTransmogTable, playerData.mirageWardrobeHiddenItemsTable)
    MirageWardrobeCore.markAppearanceChanged(player)
    return true
end

local function applyAppearancePreviewState(state, player, previewOriginalState)
    if type(state) ~= "table" then return false end
    player = player or getPlayer()
    if not player or not isAppearancePreviewTokenFor(
            previewOriginalState, player) then
        discardAppearancePreviewToken(previewOriginalState)
        return false
    end


    local transaction = MirageWardrobeCore.appearancePreviewTransactions[player]
    local transactionCreated = false
    if transaction and not transactionMatchesAppearancePreviewToken(
            transaction, previewOriginalState, player) then
        return false
    end
    if not transaction and type(previewOriginalState) == "table" then
        transaction, transactionCreated = beginAppearancePreviewTransaction(
                player, previewOriginalState)
    end
    if not transaction then return false end

    local previousCleanAppearance = MirageWardrobeCore.isCleanAppearanceEnabled(player)
    local previousCleanOptions = MirageWardrobeCore.getCleanAppearanceOptions(player)
    local previewState = copyAppearanceState(state, player)
    if not previewState then
        if transactionCreated then finishAppearancePreviewTransaction(player) end
        return false
    end
    transaction.previewState = previewState
    MirageWardrobeCore.markAppearanceChanged(player)

    local nextCleanAppearance = MirageWardrobeCore.isCleanAppearanceEnabled(player)
    local nextCleanOptions = MirageWardrobeCore.getCleanAppearanceOptions(player)
    local visualChanged = MirageWardrobeCore.applyWardrobeAppearance(
            player, previewState)
    if previousCleanAppearance ~= nextCleanAppearance or
            (nextCleanAppearance and not cleanAppearanceOptionsEqual(
                    previousCleanOptions, nextCleanOptions)) then
        MirageWardrobeCore.queueCleanAppearanceRefresh(player,
                visualChanged and MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_DELAY_TICKS or 0,
                nextCleanAppearance, true)
    end
    return true
end

local function applyCommittedAppearanceState(state, player, previewToken)
    if type(state) ~= "table" then return false, nil, false end
    player = player or getPlayer()
    if not player then return false, nil, false end

    local previousCleanAppearance =
            MirageWardrobeCore.isCleanAppearanceEnabled(player)
    local previousCleanOptions =
            MirageWardrobeCore.getCleanAppearanceOptions(player)
    if not MirageWardrobeCore.loadPlayerTransmogState(state, player) then
        return false, nil, false
    end
    local transaction = finishAppearancePreviewTransaction(player, previewToken)
    local nextCleanAppearance =
            MirageWardrobeCore.isCleanAppearanceEnabled(player)
    local nextCleanOptions =
            MirageWardrobeCore.getCleanAppearanceOptions(player)
    local visualChanged = MirageWardrobeCore.applyWardrobeAppearance(player)
    if previousCleanAppearance ~= nextCleanAppearance or
            (nextCleanAppearance and not cleanAppearanceOptionsEqual(
                    previousCleanOptions, nextCleanOptions)) then
        MirageWardrobeCore.queueCleanAppearanceRefresh(player,
                visualChanged and
                        MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_DELAY_TICKS or 0,
                nextCleanAppearance, true)
    end
    return true, transaction, visualChanged
end

MirageWardrobeCore.restoreAppearancePreviewState = function (state, player)
    player = player or getPlayer()
    local tokenOwner = type(state) == "table" and
            state._appearancePreviewOwner or nil
    if not tokenOwner or type(state._appearancePreviewGeneration) ~= "number" then
        return false
    end
    if tokenOwner ~= player then
        discardAppearancePreviewToken(state)
        return true
    end
    local activeTransaction =
            MirageWardrobeCore.appearancePreviewTransactions[tokenOwner]

    if not activeTransaction then
        return true
    end
    if not transactionMatchesAppearancePreviewToken(
            activeTransaction, state, tokenOwner) then
        return false
    end

    local previousCleanAppearance =
            MirageWardrobeCore.isCleanAppearanceEnabled(player)
    local previousCleanOptions =
            MirageWardrobeCore.getCleanAppearanceOptions(player)
    local transaction = finishAppearancePreviewTransaction(player, state)
    MirageWardrobeCore.markAppearanceChanged(player)
    local nextCleanAppearance =
            MirageWardrobeCore.isCleanAppearanceEnabled(player)
    local nextCleanOptions =
            MirageWardrobeCore.getCleanAppearanceOptions(player)
    local visualChanged = MirageWardrobeCore.applyWardrobeAppearance(player)
    if previousCleanAppearance ~= nextCleanAppearance or
            (nextCleanAppearance and not cleanAppearanceOptionsEqual(
                    previousCleanOptions, nextCleanOptions)) then
        MirageWardrobeCore.queueCleanAppearanceRefresh(player,
                visualChanged and
                        MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_DELAY_TICKS or 0,
                nextCleanAppearance, true)
    end
    if transaction and transaction.pendingPublish == true then
        MirageWardrobeCore.publishAppearanceState(
                transaction.pendingMarkDirty == true)
    end
    return true
end

local function readTintComponents(visual, clothingItem)
    if not visual or not visual.getTint then return nil end
    local ok, color = pcall(visual.getTint, visual, clothingItem)
    if not ok then ok, color = pcall(visual.getTint, visual) end
    if not ok or not color then return nil end

    local function component(floatMethod, plainMethod, field)
        if color[floatMethod] then
            local valueOk, value = pcall(color[floatMethod], color)
            if valueOk and isFiniteNumber(value) then return value end
        end
        if color[plainMethod] then
            local valueOk, value = pcall(color[plainMethod], color)
            if valueOk and isFiniteNumber(value) then
                return value > 1 and value / 255 or value
            end
        end
        local value = color[field]
        return isFiniteNumber(value) and value or nil
    end

    local red = component("getRedFloat", "getRed", "r")
    local green = component("getGreenFloat", "getGreen", "g")
    local blue = component("getBlueFloat", "getBlue", "b")
    if not red or not green or not blue then return nil end
    return red, green, blue
end

local function makeImmutableTint(red, green, blue)
    if not ImmutableColor or not ImmutableColor.new then return nil end
    local ok, color = pcall(ImmutableColor.new, red, green, blue, 1)
    return ok and color or nil
end

local function resolveOriginalStyle(visual, clothingItem)
    if not visual or not clothingItem then return false, nil end
    if clothingItem.isReady then
        local readyOk, ready = pcall(clothingItem.isReady, clothingItem)
        if not readyOk or ready ~= true then return false, nil end
    end
    local methods = {
        "getHue", "getTint", "getBaseTexture", "getTextureChoice",
    }
    for _, methodName in ipairs(methods) do
        local method = visual[methodName]
        if method then
            local resolved = pcall(method, visual, clothingItem)
            if not resolved then return false, nil end
        end
    end
    local decal = nil
    if visual.getDecal then
        local decalOk, value = pcall(visual.getDecal, visual, clothingItem)
        if not decalOk then return false, nil end
        decal = value
    end
    return true, decal
end

local function backupOriginalItemStyle(item)
    if not item or not item.getModData then return false end
    local itemData = item:getModData()
    if itemData[MirageWardrobeCore.ITEM_ORIGINAL_STYLE_KEY] == true then return true end
    local visual = getItemVisual(item)
    if not visual then return false end

    -- A pre-existing type-replacement marker without the new full-style
    -- marker can come from an earlier session.  Never mistake the current
    -- donor/hidden visual for the receiver's original style.
    local markedOriginalType =
            itemData[MirageWardrobeCore.ITEM_ORIGINAL_VISUAL_KEY]
    if type(markedOriginalType) == "string" then
        local currentType =
                visual.getItemType and visual:getItemType() or nil
        if currentType ~= markedOriginalType then return false end
    end

    local clothingItem = nil
    if visual.getClothingItem then
        local ok, value = pcall(visual.getClothingItem, visual)
        if ok then clothingItem = value end
    end
    local styleReady, resolvedDecal =
            resolveOriginalStyle(visual, clothingItem)
    if not styleReady then return false end

    local choice = nil
    local base = nil
    local tintR, tintG, tintB = nil, nil, nil
    if itemData[MirageWardrobeCore.ITEM_ORIGINAL_TEXTURE_CHOICE_KEY] == nil and
            visual.getTextureChoice then
        local ok, value = pcall(visual.getTextureChoice, visual)
        if ok and isFiniteNumber(value) then choice = value end
    end
    if itemData[MirageWardrobeCore.ITEM_ORIGINAL_BASE_TEXTURE_KEY] == nil and
            visual.getBaseTexture then
        local ok, value = pcall(visual.getBaseTexture, visual)
        if ok and isFiniteNumber(value) then base = value end
    end
    if itemData[MirageWardrobeCore.ITEM_ORIGINAL_TINT_R_KEY] == nil then
        tintR, tintG, tintB = readTintComponents(visual, clothingItem)
    end

    if choice ~= nil then
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_TEXTURE_CHOICE_KEY] = choice
    end
    if base ~= nil then
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_BASE_TEXTURE_KEY] = base
    end
    if tintR ~= nil then
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_TINT_R_KEY] = tintR
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_TINT_G_KEY] = tintG
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_TINT_B_KEY] = tintB
    end
    if visual.getHue then
        local hueOk, hue = pcall(visual.getHue, visual)
        if hueOk and isFiniteNumber(hue) then
            itemData[MirageWardrobeCore.ITEM_ORIGINAL_HUE_KEY] = hue
        end
    end
    if type(resolvedDecal) == "string" then
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_DECAL_KEY] =
                resolvedDecal
    end
    itemData[MirageWardrobeCore.ITEM_ORIGINAL_STYLE_KEY] = true
    return true
end

local function getVisualClothingItem(visual)
    if not visual or not visual.getClothingItem then return nil end
    local ok, clothingItem = pcall(visual.getClothingItem, visual)
    return ok and clothingItem or nil
end

local function readFixedTextureAxis(visual, clothingItem)
    if not visual or not clothingItem or not clothingItem.hasModel then
        return nil, nil
    end
    if clothingItem.isReady then
        local readyOk, ready =
                pcall(clothingItem.isReady, clothingItem)
        if not readyOk or ready ~= true then return nil, nil end
    end

    local modelOk, hasModel =
            pcall(clothingItem.hasModel, clothingItem)
    if not modelOk or type(hasModel) ~= "boolean" then
        return nil, nil
    end
    local listGetter = hasModel and clothingItem.getTextureChoices or
            clothingItem.getBaseTextures
    local rawGetter = hasModel and visual.getTextureChoice or
            visual.getBaseTexture
    local setter = hasModel and visual.setTextureChoice or
            visual.setBaseTexture
    if not listGetter or not rawGetter or not setter then
        return nil, nil
    end

    local listOk, textures = pcall(listGetter, clothingItem)
    if not listOk or not textures or not textures.size then
        return nil, nil
    end
    local sizeOk, size = pcall(textures.size, textures)
    if not sizeOk or size ~= 1 then return nil, nil end

    -- The zero-argument overload returns the raw index. Passing a
    -- ClothingItem invokes OutfitRNG and mutates an unresolved physical
    -- ItemVisual, which is exactly what this detector must avoid.
    local rawOk, rawIndex = pcall(rawGetter, visual)
    if not rawOk or not isFiniteNumber(rawIndex) then
        return nil, nil
    end
    return rawIndex, setter
end

local function normalizeFixedTextureStyle(visual, clothingItem)
    local rawIndex, setter =
            readFixedTextureAxis(visual, clothingItem)
    if rawIndex == nil then return false end
    if rawIndex ~= 0 then
        local setOk = pcall(setter, visual, 0)
        if not setOk then return false end
    end
    return true
end

resolveDetachedVisualStyle = function (visual)
    if not visual then return false end
    local clothingItem = getVisualClothingItem(visual)
    if not clothingItem then return true end
    if normalizeFixedTextureStyle(visual, clothingItem) then
        return true
    end
    local resolved = resolveOriginalStyle(visual, clothingItem)
    return resolved == true
end

local function hasUnresolvedFixedTextureWornItem(player)
    if not player then return false end
    local wornItems = player.getWornItems and
            player:getWornItems() or nil
    if not wornItems or not wornItems.size or
            not wornItems.getItemByIndex then
        return false
    end
    local count = wornItems:size()
    local revision = MirageWardrobeCore.getAppearanceRevision(player)
    local scanTicks = tonumber(
            MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_SCAN_TICKS) or 30
    if scanTicks < 1 then scanTicks = 1 end
    local checkedEpoch = math.floor(
            (MirageWardrobeCore.cleanAppearanceTickCounter or 0) / scanTicks)
    local cached = MirageWardrobeCore.fixedTextureTrackingCache[player]
    if type(cached) == "table" and cached.source == wornItems and
            cached.count == count and cached.revision == revision and
            cached.checkedEpoch == checkedEpoch then
        return cached.result == true
    end

    local result = false
    for index = 0, count - 1 do
        local item = wornItems:getItemByIndex(index)
        local visual = getItemVisual(item)
        local clothingItem = getVisualClothingItem(visual)
        local rawIndex = readFixedTextureAxis(visual, clothingItem)
        if rawIndex ~= nil and rawIndex ~= 0 then
            result = true
            break
        end
    end
    MirageWardrobeCore.fixedTextureTrackingCache[player] = {
        source = wornItems,
        count = count,
        revision = revision,
        checkedEpoch = checkedEpoch,
        result = result,
    }
    return result
end

local function canApplyTextureVariant(visual, clothingItem, variant)
    if not visual or not clothingItem or type(variant) ~= "table" or
            variant.textureMode == nil then return false end
    if not clothingItem.hasModel then return false end

    if clothingItem.isReady then
        local readyOk, ready = pcall(clothingItem.isReady, clothingItem)
        if not readyOk or ready ~= true then return false end
    end

    local modelOk, hasModel = pcall(clothingItem.hasModel, clothingItem)
    if not modelOk or type(hasModel) ~= "boolean" then return false end
    local expectedMode = hasModel and "choice" or "base"
    if variant.textureMode ~= expectedMode then return false end

    local listGetter = hasModel and clothingItem.getTextureChoices or
            clothingItem.getBaseTextures
    if not listGetter then return false end
    local listOk, textures = pcall(listGetter, clothingItem)
    if not listOk or not textures or not textures.size then return false end
    local sizeOk, size = pcall(textures.size, textures)
    if not sizeOk or not isFiniteNumber(size) or size < 0 or
            size ~= math.floor(size) then return false end
    return isFiniteNumber(variant.textureIndex) and variant.textureIndex >= 0 and
            variant.textureIndex < size
end

applyVariantToVisual = function (visual, variant, clothingItem)
    if not visual or type(variant) ~= "table" then return false end
    local changed = false
    local donorClothingItem = getVisualClothingItem(visual)
    local textureReady = canApplyTextureVariant(visual, donorClothingItem, variant)
    if textureReady and variant.textureMode == "choice" and visual.setTextureChoice then
        local current = nil
        if visual.getTextureChoice then
            local currentOk, value = pcall(visual.getTextureChoice, visual)
            if currentOk then current = value end
        end
        if current ~= variant.textureIndex then
            local setOk = pcall(visual.setTextureChoice, visual, variant.textureIndex)
            if setOk then changed = true end
        end
    elseif textureReady and variant.textureMode == "base" and visual.setBaseTexture then
        local current = nil
        if visual.getBaseTexture then
            local currentOk, value = pcall(visual.getBaseTexture, visual)
            if currentOk then current = value end
        end
        if current ~= variant.textureIndex then
            local setOk = pcall(visual.setBaseTexture, visual, variant.textureIndex)
            if setOk then changed = true end
        end
    end
    if variant.tintR ~= nil and visual.setTint then
        local red, green, blue = readTintComponents(visual,
                donorClothingItem or clothingItem)
        if red ~= variant.tintR or green ~= variant.tintG or blue ~= variant.tintB then
            local color = makeImmutableTint(variant.tintR, variant.tintG, variant.tintB)
            if color then
                local setOk = pcall(visual.setTint, visual, color)
                if setOk then changed = true end
            end
        end
    end
    return changed
end

local function restoreItemVariant(item, preserveBackup)
    if not item or not item.getModData then return false end
    local itemData = item:getModData()
    local hasFullStyle = itemData[MirageWardrobeCore.ITEM_ORIGINAL_STYLE_KEY] == true
    if not hasFullStyle and
            itemData[MirageWardrobeCore.ITEM_ORIGINAL_VARIANT_KEY] ~= true then
        return false, true
    end
    local visual = getItemVisual(item)
    if not visual then return false, false end

    local choice = itemData[MirageWardrobeCore.ITEM_ORIGINAL_TEXTURE_CHOICE_KEY]
    local base = itemData[MirageWardrobeCore.ITEM_ORIGINAL_BASE_TEXTURE_KEY]
    local red = itemData[MirageWardrobeCore.ITEM_ORIGINAL_TINT_R_KEY]
    local green = itemData[MirageWardrobeCore.ITEM_ORIGINAL_TINT_G_KEY]
    local blue = itemData[MirageWardrobeCore.ITEM_ORIGINAL_TINT_B_KEY]
    local hue = itemData[MirageWardrobeCore.ITEM_ORIGINAL_HUE_KEY]
    if isFiniteNumber(choice) and not visual.setTextureChoice then
        return false, false
    end
    if isFiniteNumber(base) and not visual.setBaseTexture then
        return false, false
    end
    if isFiniteNumber(red) and isFiniteNumber(green) and
            isFiniteNumber(blue) and not visual.setTint then
        return false, false
    end
    if isFiniteNumber(hue) and not visual.setHue then
        return false, false
    end
    if hasFullStyle and not visual.setDecal then return false, false end

    local changed = false
    if isFiniteNumber(choice) then
        visual:setTextureChoice(choice)
        changed = true
    end
    if isFiniteNumber(base) then
        visual:setBaseTexture(base)
        changed = true
    end
    if isFiniteNumber(red) and isFiniteNumber(green) and
            isFiniteNumber(blue) then
        local color = makeImmutableTint(red, green, blue)
        if not color then return false, false end
        visual:setTint(color)
        changed = true
    end
    if isFiniteNumber(hue) then
        visual:setHue(hue)
        changed = true
    end
    if hasFullStyle then
        local decal = itemData[MirageWardrobeCore.ITEM_ORIGINAL_DECAL_KEY]
        visual:setDecal(type(decal) == "string" and decal or nil)
        changed = true
    end
    if preserveBackup ~= true then
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_STYLE_KEY] = nil
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_VARIANT_KEY] = nil
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_TEXTURE_CHOICE_KEY] = nil
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_BASE_TEXTURE_KEY] = nil
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_TINT_R_KEY] = nil
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_TINT_G_KEY] = nil
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_TINT_B_KEY] = nil
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_HUE_KEY] = nil
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_DECAL_KEY] = nil
    end
    return changed, true
end

MirageWardrobeCore.setItemVisualType = function (item, visualType)
    if not item or type(visualType) ~= "string" then return false end

    local visual = getItemVisual(item)
    if not visual or not visual.setItemType then return false end

    local currentType = visual.getItemType and visual:getItemType() or nil
    if currentType == visualType then return false end

    local originalType = getItemFullName(item)
    if originalType and visualType ~= originalType and item.getModData then
        local itemData = item:getModData()
        if itemData[MirageWardrobeCore.ITEM_ORIGINAL_VISUAL_KEY] == nil then
            if not backupOriginalItemStyle(item) then return false end
            itemData[MirageWardrobeCore.ITEM_ORIGINAL_VISUAL_KEY] = originalType
            if visual.getAlternateModelName then
                local alternateModelName = visual:getAlternateModelName()
                if type(alternateModelName) == "string" and alternateModelName ~= "" then
                    itemData[MirageWardrobeCore.ITEM_ORIGINAL_ALTERNATE_MODEL_KEY] = alternateModelName
                end
            end
        end
        itemData[MirageWardrobeCore.ITEM_APPLIED_VISUAL_KEY] = visualType
    end

    visual:setItemType(visualType)
    if visual.setAlternateModelName then
        -- A hand replacement belonging to the receiver can be invalid for the donor
        -- and may crash B42's renderer. Restore it only when the transmog is reset.
        visual:setAlternateModelName(nil)
    end
    return true
end

MirageWardrobeCore.restoreItemVisual = function (item)
    if not item then return false end
    local readyVisual = getItemVisual(item)
    if not readyVisual or not readyVisual.setItemType or
            not readyVisual.getItemType then
        return false
    end

    local originalType = getItemFullName(item)
    local itemData = item.getModData and item:getModData() or nil
    if itemData and type(itemData[MirageWardrobeCore.ITEM_ORIGINAL_VISUAL_KEY]) == "string" then
        originalType = itemData[MirageWardrobeCore.ITEM_ORIGINAL_VISUAL_KEY]
    end
    if not originalType then return false end

    local originalAlternateModel = itemData and itemData[MirageWardrobeCore.ITEM_ORIGINAL_ALTERNATE_MODEL_KEY] or nil
    local changed = MirageWardrobeCore.setItemVisualType(item, originalType)
    local restoredVisual = getItemVisual(item)
    local restoredType = restoredVisual and restoredVisual.getItemType and
            restoredVisual:getItemType() or nil
    if restoredType ~= originalType then return false end
    -- Restore style after switching back to the original ClothingItem.  This
    -- prevents a temporary hidden/donor asset from normalizing the saved
    -- texture indices, tint, hue, or decal during restoration.
    local variantChanged, variantRestored = restoreItemVariant(item)
    if variantRestored ~= true then return changed end
    local visual = getItemVisual(item)
    if visual and visual.setAlternateModelName and type(originalAlternateModel) == "string" then
        visual:setAlternateModelName(originalAlternateModel)
        changed = true
    end
    if itemData then
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_VISUAL_KEY] = nil
        itemData[MirageWardrobeCore.ITEM_APPLIED_VISUAL_KEY] = nil
        itemData[MirageWardrobeCore.ITEM_ORIGINAL_ALTERNATE_MODEL_KEY] = nil
    end
    return changed or variantChanged
end

MirageWardrobeCore.refreshPlayerVisual = function (player, transmit)
    player = player or getPlayer()
    if not player then return end


    -- Appearance overrides are captured atomically later: the real ItemVisual
    -- is restored before this function returns to the game loop, so gameplay
    -- protection and future SyncClothing packets always see the physical item.
    MirageWardrobeCore.cleanAppearanceRendered[player] = nil
    MirageWardrobeCore.queueCleanAppearanceRefresh(player, 0,
            MirageWardrobeCore.isCleanAppearanceEnabled(player), true)
    -- Transmog state has its own validated network channel. Never transmit the
    -- temporary capture visuals through the game's equipment sync.
end

local function getStateTransmogTable(player, state)
    if type(state) == "table" then
        if type(state.transmogTable) == "table" then
            return state.transmogTable
        end
        return state
    end

    if isLocalPlayer(player) then
        return MirageWardrobeCore.getItemAppearanceMap(player)
    end

    local playerKey = MirageWardrobeCore.getPlayerSyncKey(player)
    local networkState = playerKey and MirageWardrobeCore.networkPlayerData[playerKey] or nil
    if type(networkState) == "table" then
        return networkState.transmogTable or networkState
    end
    return {}
end

local function getStateSlotTransmogTable(player, state)
    if type(state) == "table" and type(state.slotTransmogTable) == "table" then
        return state.slotTransmogTable
    end

    if isLocalPlayer(player) then
        return MirageWardrobeCore.getSlotTransmogTable(player)
    end

    local playerKey = MirageWardrobeCore.getPlayerSyncKey(player)
    local networkState = playerKey and MirageWardrobeCore.networkPlayerData[playerKey] or nil
    if type(networkState) == "table" and type(networkState.slotTransmogTable) == "table" then
        return networkState.slotTransmogTable
    end
    return {}
end

local function getStateSlotVariantTable(player, state, slotTransmogTable)
    if type(state) == "table" then
        return copySlotVariantMap(state.slotVariantTable, false, slotTransmogTable)
    end

    if isLocalPlayer(player) then
        return MirageWardrobeCore.getSlotVariantTable(player)
    end

    local playerKey = MirageWardrobeCore.getPlayerSyncKey(player)
    local networkState = playerKey and MirageWardrobeCore.networkPlayerData[playerKey] or nil
    if type(networkState) == "table" then
        return copySlotVariantMap(networkState.slotVariantTable, false, slotTransmogTable)
    end
    return {}
end

local function getStateHiddenItemsTable(player, state)
    if type(state) == "table" and type(state.hiddenItemsTable) == "table" then
        return state.hiddenItemsTable
    end

    if isLocalPlayer(player) then
        return MirageWardrobeCore.getHiddenSlotMap(player)
    end

    local playerKey = MirageWardrobeCore.getPlayerSyncKey(player)
    local networkState = playerKey and MirageWardrobeCore.networkPlayerData[playerKey] or nil
    if type(networkState) == "table" and type(networkState.hiddenItemsTable) == "table" then
        return networkState.hiddenItemsTable
    end
    return {}
end

local function getStateOriginalClothingOverrides(player, state)
    if type(state) == "table" then
        return copyOriginalClothingOverrides(
                state.originalClothingOverrides, false)
    end

    if isLocalPlayer(player) then
        return MirageWardrobeCore.getOriginalClothingOverrides(player)
    end

    local playerKey = MirageWardrobeCore.getPlayerSyncKey(player)
    local networkState = playerKey and MirageWardrobeCore.networkPlayerData[playerKey] or nil
    if type(networkState) == "table" then
        return copyOriginalClothingOverrides(
                networkState.originalClothingOverrides, false)
    end
    return {}
end

local function getStateWornVisualSlots(player, state)
    if type(state) == "table" then
        return copyWornVisualSlots(state.wornVisualSlots)
    end
    if isLocalPlayer(player) then return makeWornVisualSlots(player) end

    local playerKey = MirageWardrobeCore.getPlayerSyncKey(player)
    local networkState = playerKey and
            MirageWardrobeCore.networkPlayerData[playerKey] or nil
    return copyWornVisualSlots(type(networkState) == "table" and
            networkState.wornVisualSlots or nil)
end

local function getStateHideOriginalClothing(player, state)
    if type(state) == "table" then
        return state.hideOriginalClothing == true
    end

    if isLocalPlayer(player) then
        return MirageWardrobeCore.isHideOriginalClothingEnabled(player)
    end

    local playerKey = MirageWardrobeCore.getPlayerSyncKey(player)
    local networkState = playerKey and MirageWardrobeCore.networkPlayerData[playerKey] or nil
    return type(networkState) == "table" and networkState.hideOriginalClothing == true
end

local function removeVisualProxy(bodyVisuals, visual)
    if not bodyVisuals or not visual or not bodyVisuals.remove then return false end
    local removedOk, removed = pcall(bodyVisuals.remove, bodyVisuals, visual)
    local succeeded = removedOk and removed ~= false
    return succeeded
end

copyOriginalClothingOverrides = function (source, strict)
    local result = {}
    if source == nil then return result end
    if type(source) ~= "table" then return strict and nil or result end

    local count = 0
    for slot, value in pairs(source) do
        count = count + 1
        local valid = type(slot) == "string" and slot ~= "" and
                string.len(slot) <= MirageWardrobeCore.MAX_OUTFIT_PRESET_VALUE_BYTES and
                not string.find(slot, "%c") and
                (value == MirageWardrobeCore.ORIGINAL_CLOTHING_HIDDEN or
                        value == MirageWardrobeCore.ORIGINAL_CLOTHING_SHOWN)
        if count > MirageWardrobeCore.MAX_OUTFIT_PRESET_HIDDEN_ENTRIES or not valid then
            if strict then return nil end
        else
            result[slot] = value
        end
    end
    return result
end

shouldHideOriginalClothing = function (slot, hideOriginalClothing, overrides)
    local override = type(overrides) == "table" and overrides[slot] or nil
    if override == MirageWardrobeCore.ORIGINAL_CLOTHING_HIDDEN then return true end
    if override == MirageWardrobeCore.ORIGINAL_CLOTHING_SHOWN then return false end
    return hideOriginalClothing == true
end

getBodyLocationSortIndex = function (player, slot)
    if not player or type(slot) ~= "string" or not ItemBodyLocation or
            not ItemBodyLocation.get or not ResourceLocation or not ResourceLocation.of then
        return 2147483647
    end

    local wornItems = player.getWornItems and player:getWornItems() or nil
    local group = wornItems and wornItems.getBodyLocationGroup and
            wornItems:getBodyLocationGroup() or nil
    if not group or not group.indexOf then return 2147483647 end

    local resourceOk, resource = pcall(ResourceLocation.of, slot)
    if not resourceOk or not resource then return 2147483647 end
    local locationOk, location = pcall(ItemBodyLocation.get, resource)
    if not locationOk or not location then return 2147483647 end
    local indexOk, index = pcall(group.indexOf, group, location)
    if indexOk and type(index) == "number" and index >= 0 then return index end
    return 2147483647
end

getBodyLocationObjectForSlot = function (player, slot, fallback)
    if fallback and (not slot or tostring(fallback) == tostring(slot)) then
        return fallback
    end
    if type(slot) ~= "string" or slot == "" or not ResourceLocation or
            not ResourceLocation.of or not ItemBodyLocation or
            not ItemBodyLocation.get then
        return fallback
    end
    local resourceOk, resource = pcall(ResourceLocation.of, slot)
    if not resourceOk or not resource then return fallback end
    local locationOk, location = pcall(ItemBodyLocation.get, resource)
    return locationOk and location or fallback
end

getHoodieRenderSlot = function (item)
    local scriptItem = getItemScript(item) or item
    if not scriptItem or not scriptItem.getBodyLocation then return nil end

    local bodyLocation, bodyOk = safeNoArgMethod(
            scriptItem, "getBodyLocation")
    if not bodyOk or bodyLocation == nil then return nil end
    local actualSlot = string.lower(tostring(bodyLocation))
    local correctedSlot = HOODIE_RENDER_SLOT_REPLACEMENTS[actualSlot]
    if not correctedSlot then return nil end

    -- Resolve submenu metadata only for the three locations whose hood-up
    -- variants hide adjacent locations.  Ordinary clothing never allocates a
    -- metadata instance, even when a caller scans a large modded item list.
    local submenu = getClothingExtraSubmenu(item, scriptItem)
    local normalizedMode = type(submenu) == "string" and
            string.lower(submenu) or ""
    if normalizedMode ~= "uphoodie" and normalizedMode ~= "downhoodie" then
        return nil
    end
    return correctedSlot
end

getRenderCarrierForItem = function (item)
    local correctedSlot = getHoodieRenderSlot(item)
    local prefix = correctedSlot and RENDER_CARRIER_SPECS[correctedSlot] or nil
    if not prefix or not item or not item.getClothingItemAsset then
        return nil, nil
    end

    local itemType = getItemFullName(item)
    local assetOk, asset = pcall(item.getClothingItemAsset, item)
    if not assetOk or not asset then
        warnCompatibility("carrier-asset-unavailable", itemType, correctedSlot,
                "clothing asset is not ready")
        return nil, nil
    end

    local bindings = MirageWardrobeCore.renderCarrierBindings[correctedSlot]
    if type(bindings) ~= "table" then
        bindings = {}
        MirageWardrobeCore.renderCarrierBindings[correctedSlot] = bindings
    end
    local existing = bindings[asset]
    if type(existing) == "table" and existing.fullType and existing.script then
        local verifyOk, boundAsset = pcall(
                existing.script.getClothingItemAsset, existing.script)
        if verifyOk and boundAsset == asset then
            return existing.fullType, existing.script
        end
        bindings[asset] = nil
    end

    local manager = getScriptManager and getScriptManager() or nil
    if not manager or not manager.FindItem then
        warnCompatibility("carrier-manager-unavailable", itemType, correctedSlot,
                "script manager is unavailable")
        return nil, nil
    end
    local nextIndex = (MirageWardrobeCore.renderCarrierNextIndex[correctedSlot] or 0) + 1
    if nextIndex > RENDER_CARRIER_POOL_SIZE then
        warnCompatibility("carrier-pool-exhausted", "<pool>", correctedSlot,
                "keeping the native render slot")
        return nil, nil
    end

    local fullType = "MirageWardrobeRender." .. prefix ..
            string.format("%02d", nextIndex)
    local carrier = manager:FindItem(fullType)
    if not carrier or not carrier.setClothingItemAsset or
            not carrier.getClothingItemAsset then
        warnCompatibility("carrier-script-unavailable", itemType, correctedSlot,
                fullType)
        return nil, nil
    end
    -- Once a carrier setter is called, never offer that Script.Item to a
    -- different asset even if the setter or verification reports an error.
    MirageWardrobeCore.renderCarrierNextIndex[correctedSlot] = nextIndex
    local boundOk = pcall(carrier.setClothingItemAsset, carrier, asset)
    local verifyOk, boundAsset = pcall(carrier.getClothingItemAsset, carrier)
    if not boundOk or not verifyOk or boundAsset ~= asset then
        warnCompatibility("carrier-bind-failed", itemType, correctedSlot,
                fullType)
        return nil, nil
    end

    bindings[asset] = { fullType = fullType, script = carrier }
    return fullType, carrier
end

getRenderSlotForItem = function (item, fallbackSlot)
    local correctedSlot = getHoodieRenderSlot(item)
    if correctedSlot then return correctedSlot end
    local slot = item and MirageWardrobeCore.getTransmogSourceSlot(item) or nil
    return slot or fallbackSlot
end

getRenderSlotForDonor = function (receiver, donor, receiverSlot)
    local correctedSlot = getHoodieRenderSlot(donor)
    if correctedSlot then return correctedSlot end

    local donorSlot = donor and
            MirageWardrobeCore.getTransmogSourceSlot(donor) or nil
    local receiverSourceSlot = receiver and
            MirageWardrobeCore.getTransmogSourceSlot(receiver) or nil
    if donorSlot and receiverSourceSlot and
            string.lower(tostring(donorSlot)) ==
                    string.lower(tostring(receiverSourceSlot)) then
        return receiverSlot or donorSlot
    end
    return donorSlot or receiverSlot
end

local function hasRenderCompatibilityItem(player)
    if not player then return false end
    local manager = getScriptManager and getScriptManager() or nil
    if not manager or not manager.FindItem then return false end

    local remoteVisuals = MirageWardrobeCore.getRemotePlayerItemVisuals and
            MirageWardrobeCore.getRemotePlayerItemVisuals(player) or nil
    local wornItems = nil
    if not remoteVisuals then
        wornItems = player.getWornItems and player:getWornItems() or nil
    end
    local source = remoteVisuals or wornItems
    local count = source and source.size and source:size() or -1
    local revision = MirageWardrobeCore.getAppearanceRevision and
            MirageWardrobeCore.getAppearanceRevision(player) or 0
    local scanTicks = tonumber(
            MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_SCAN_TICKS) or 30
    if scanTicks < 1 then scanTicks = 1 end
    local checkedEpoch = math.floor(
            (MirageWardrobeCore.cleanAppearanceTickCounter or 0) / scanTicks)
    local cached = MirageWardrobeCore.renderCompatibilityCache[player]
    if type(cached) == "table" and cached.source == source and
            cached.count == count and cached.revision == revision and
            cached.checkedEpoch == checkedEpoch then
        return cached.result == true
    end

    local result = false
    local function inspect(scriptItem)
        if getHoodieRenderSlot(scriptItem) then result = true end
    end
    if remoteVisuals and remoteVisuals.size and remoteVisuals.get then
        for index = 0, remoteVisuals:size() - 1 do
            local visual = remoteVisuals:get(index)
            local fullName = visual and visual.getItemType and
                    visual:getItemType() or nil
            inspect(fullName and manager:FindItem(fullName) or nil)
            if result then break end
        end
    elseif wornItems and wornItems.size and wornItems.getItemByIndex then
        for index = 0, wornItems:size() - 1 do
            inspect(getItemScript(wornItems:getItemByIndex(index)))
            if result then break end
        end
    end
    MirageWardrobeCore.renderCompatibilityCache[player] = {
        source = source,
        count = count,
        revision = revision,
        checkedEpoch = checkedEpoch,
        result = result,
    }
    return result
end

local function sortRenderRecords(player, records)
    table.sort(records, function (left, right)
        local leftIndex = getBodyLocationSortIndex(player, left.renderSlot)
        local rightIndex = getBodyLocationSortIndex(player, right.renderSlot)
        if leftIndex ~= rightIndex then return leftIndex < rightIndex end
        if left.renderSlot ~= right.renderSlot then
            return tostring(left.renderSlot or "") < tostring(right.renderSlot or "")
        end
        local leftReceiver = tostring(left.receiverSlot or "")
        local rightReceiver = tostring(right.receiverSlot or "")
        if leftReceiver ~= rightReceiver then
            return leftReceiver < rightReceiver
        end
        local leftSource = tonumber(left.sourceIndex) or 0
        local rightSource = tonumber(right.sourceIndex) or 0
        return leftSource < rightSource
    end)
    return records
end

selectRenderRecords = function (player, records, group)
    table.sort(records, function (left, right)
        local leftPriority = tonumber(left.priority) or 0
        local rightPriority = tonumber(right.priority) or 0
        if leftPriority ~= rightPriority then return leftPriority > rightPriority end
        local leftSource = tonumber(left.sourceIndex) or 0
        local rightSource = tonumber(right.sourceIndex) or 0
        if leftSource ~= rightSource then return leftSource > rightSource end
        local leftReceiver = tostring(left.receiverSlot or "")
        local rightReceiver = tostring(right.receiverSlot or "")
        return leftReceiver < rightReceiver
    end)

    local locationStates = {}
    for _, record in ipairs(records) do
        local location = nil
        local locationKnown = false
        -- Records already known to be outside this exact group stay detached;
        -- never resolve them again through the global location registry.
        if record.bodyVisual ~= true and record.locationKnown ~= false then
            location = record.location or
                    getBodyLocationObjectForSlot(player, record.renderSlot, nil)
            if location and group and group.indexOf then
                local indexOk, locationIndex = pcall(
                        group.indexOf, group, location)
                locationKnown = indexOk and type(locationIndex) == "number" and
                        locationIndex >= 0
            end
        end
        locationStates[record] = {
            location = locationKnown and location or nil,
            known = locationKnown,
        }
    end

    local function locationsConflict(left, right)
        local leftState = locationStates[left]
        local rightState = locationStates[right]
        local leftLocation = leftState and leftState.location or nil
        local rightLocation = rightState and rightState.location or nil
        local leftKnown = leftState and leftState.known == true
        local rightKnown = rightState and rightState.known == true
        local sameLocation = left.renderSlot == right.renderSlot or
                (leftKnown and rightKnown and leftLocation == rightLocation)
        if sameLocation then
            if leftKnown and rightKnown and group and group.isMultiItem then
                local leftOk, leftMulti = pcall(
                        group.isMultiItem, group, leftLocation)
                local rightOk, rightMulti = pcall(
                        group.isMultiItem, group, rightLocation)
                if leftOk and leftMulti == true and
                        rightOk and rightMulti == true then
                    return false
                end
            end
            return true
        end
        -- Different unregistered custom locations have no native exclusivity
        -- relation to evaluate. Keep both records; treating every unknown
        -- location as globally exclusive makes unrelated mod slots erase one
        -- another.
        if not leftKnown or not rightKnown then return false end
        if group and group.isExclusive then
            local leftOk, leftExclusive = pcall(
                    group.isExclusive, group, leftLocation, rightLocation)
            local rightOk, rightExclusive = pcall(
                    group.isExclusive, group, rightLocation, leftLocation)
            if (leftOk and leftExclusive == true) or
                    (rightOk and rightExclusive == true) then
                return true
            end
        end
        return false
    end

    local selected = {}
    for _, candidate in ipairs(records) do
        local conflict = false
        for _, existing in ipairs(selected) do
            if locationsConflict(candidate, existing) then
                conflict = true
                candidate.selectionConflict = existing
                break
            end
        end
        if not conflict then selected[#selected + 1] = candidate end
    end
    return sortRenderRecords(player, selected)
end

local function removeAllVisualProxies(player)
    local bodyVisuals = getPlayerBodyVisuals(player)
    if not bodyVisuals or not bodyVisuals.size or not bodyVisuals.get then return false end
    local changed = false
    for index = bodyVisuals:size() - 1, 0, -1 do
        local visual = bodyVisuals:get(index)
        if getVisualProxySlot(visual) and removeVisualProxy(bodyVisuals, visual) then
            changed = true
        end
    end
    return changed
end

local function readWornItemRecords(wornItems)
    if not wornItems or not wornItems.size then
        return nil, "worn-items-api-unavailable"
    end
    local sizeOk, count = pcall(wornItems.size, wornItems)
    if not sizeOk or type(count) ~= "number" or count < 0 then
        return nil, "worn-items-count-unavailable"
    end

    local records = {}
    for index = 0, count - 1 do
        local item = nil
        local locationObj = nil
        if wornItems.getItemByIndex then
            local itemOk, value = pcall(
                    wornItems.getItemByIndex, wornItems, index)
            if itemOk then item = value end
        end
        if item and wornItems.getLocation then
            local locationOk, value = pcall(
                    wornItems.getLocation, wornItems, item)
            if locationOk then locationObj = value end
        end
        if (not item or not locationObj) and wornItems.get then
            local entryOk, entry = pcall(wornItems.get, wornItems, index)
            if entryOk and entry then
                if not item then
                    item = safeNoArgMethod(entry, "getItem")
                end
                if not locationObj then
                    locationObj = safeNoArgMethod(entry, "getLocation")
                end
            end
        end
        local slot = locationObj and tostring(locationObj) or nil
        if slot == "" then slot = nil end
        if not item or not locationObj or not slot then
            local missing = {}
            if not item then missing[#missing + 1] = "item" end
            if not locationObj then missing[#missing + 1] = "location" end
            if not slot then missing[#missing + 1] = "slot" end
            return nil, "worn-record-incomplete index=" .. tostring(index) ..
                    " missing=" .. table.concat(missing, ",")
        end
        records[#records + 1] = {
            item = item,
            location = locationObj,
            slot = slot,
        }
    end
    return records
end

-- On a multiplayer client, IsoPlayer overrides getItemVisuals(ItemVisuals) for
-- remote characters and reads its private remotePlayerItemVisuals collection
-- instead of WornItems.  The public zero-argument overload returns that live
-- collection.  Local characters and test/runtime variants without the overload
-- deliberately fall back to the physical WornItems path.
MirageWardrobeCore.getRemotePlayerItemVisuals = function (player)
    if not player or isLocalPlayer(player) or
            not (isClient and isClient()) or not player.getItemVisuals then
        return nil
    end
    local ok, visuals = pcall(player.getItemVisuals, player)
    if not ok or not visuals or not visuals.size or not visuals.get or
            not visuals.clear or not visuals.add then
        return nil
    end
    return visuals
end

local WEAR_SIGNATURE_GETTERS = {
    "getBlood",
    "getDirt",
    "getHole",
    "getBasicPatch",
    "getDenimPatch",
    "getLeatherPatch",
}

local function readWearSignatureValue(visual, getterName, partIndex)
    local getter = visual and visual[getterName] or nil
    if not getter then return nil, false end

    local fromIndex = BloodBodyPartType and BloodBodyPartType.FromIndex or nil
    if fromIndex then
        local partOk, part = pcall(fromIndex, partIndex)
        if not partOk or not part then return nil, false end
        local ok, value = pcall(getter, visual, part)
        if not ok then return nil, false end
        return value, true
    end

    -- Test doubles and older APIs may expose numeric body-part access only.
    local ok, value = pcall(getter, visual, partIndex)
    if not ok then return nil, false end
    return value, true
end

local function getPhysicalWearSignature(player)
    if not player then return nil end
    if not BloodBodyPartType or not BloodBodyPartType.MAX or
            not BloodBodyPartType.MAX.index then
        return nil
    end
    local countOk, partCount =
            pcall(BloodBodyPartType.MAX.index, BloodBodyPartType.MAX)
    if not countOk or type(partCount) ~= "number" or partCount < 0 then
        return nil
    end

    local function appendWear(signature, visual)
        for partIndex = 0, partCount - 1 do
            for _, getterName in ipairs(WEAR_SIGNATURE_GETTERS) do
                local value, valueOk = readWearSignatureValue(
                        visual, getterName, partIndex)
                if not valueOk then return false end
                signature[#signature + 1] = tostring(value)
            end
        end
        return true
    end

    local remoteVisuals = MirageWardrobeCore.getRemotePlayerItemVisuals(player)
    if remoteVisuals then
        local signature = { "remote", tostring(remoteVisuals:size()) }
        for visualIndex = 0, remoteVisuals:size() - 1 do
            local visual = remoteVisuals:get(visualIndex)
            local fullName = visual and visual.getItemType and
                    visual:getItemType() or nil
            if type(fullName) ~= "string" or fullName == "" then return nil end
            local scriptItem = getScriptManager():FindItem(fullName)
            local slot = scriptItem and
                    MirageWardrobeCore.getTransmogSourceSlot(scriptItem) or nil
            signature[#signature + 1] = fullName
            signature[#signature + 1] = tostring(slot or "")
            if not appendWear(signature, visual) then return nil end
        end
        return table.concat(signature, "\31")
    end

    if not player.getWornItems then return nil end
    local wornItems = player:getWornItems()
    if not wornItems or not wornItems.size or
            not wornItems.getItemByIndex then
        return nil
    end
    local signature = { "worn", tostring(wornItems:size()) }
    for itemIndex = 0, wornItems:size() - 1 do
        local item = wornItems:getItemByIndex(itemIndex)
        local visual = getItemVisual(item)
        local fullName = getItemFullName(item)
        if not item or not visual or type(fullName) ~= "string" then
            return nil
        end
        local location = nil
        if wornItems.getLocation then
            local locationOk, value =
                    pcall(wornItems.getLocation, wornItems, item)
            if locationOk then location = value end
        end
        signature[#signature + 1] = fullName
        signature[#signature + 1] = tostring(location or "")
        if not appendWear(signature, visual) then return nil end
    end
    return table.concat(signature, "\31")
end

-- A lightweight identity for the physical collection used by preview panels and
-- the render bridge.  Clothing can finish loading after the first game tick
-- without firing OnClothingUpdated; appearanceRevision alone therefore cannot
-- tell a cached snapshot that its source collection changed.  Keep this check
-- structural (count/order/type/slot) so it is cheap enough for an open panel
-- and does not read or mutate ItemVisual wear values.
local function getAppearanceSourceSignature(player)
    if not player then return nil end

    local remoteVisuals = MirageWardrobeCore.getRemotePlayerItemVisuals(player)
    if remoteVisuals then
        local sizeOk, count = pcall(remoteVisuals.size, remoteVisuals)
        if not sizeOk or type(count) ~= "number" or count < 0 then return nil end
        local result = { "remote", tostring(count) }
        local manager = getScriptManager and getScriptManager() or nil
        for index = 0, count - 1 do
            local visualOk, visual = pcall(
                    remoteVisuals.get, remoteVisuals, index)
            local fullName = visualOk and visual and visual.getItemType and
                    safeNoArgMethod(visual, "getItemType") or nil
            if type(fullName) ~= "string" or fullName == "" then return nil end
            result[#result + 1] = fullName
            -- Remote ItemVisuals can be reordered by SyncClothing/model rebuilds
            -- without changing the item types. Include the native body slot so
            -- a cached snapshot cannot apply an elbow/knee decision to another
            -- visual after that reorder.
            local scriptItem = manager and manager.FindItem and
                    manager:FindItem(fullName) or nil
            local sourceSlot = scriptItem and
                    MirageWardrobeCore.getTransmogSourceSlot(scriptItem) or nil
            result[#result + 1] = tostring(sourceSlot or "")
            local alternate = visual.getAlternateModelName and
                    safeNoArgMethod(visual, "getAlternateModelName") or nil
            result[#result + 1] = tostring(alternate or "")
        end
        return table.concat(result, "\31")
    end

    if not player.getWornItems then return nil end
    local wornOk, wornItems = pcall(player.getWornItems, player)
    if not wornOk or not wornItems or not wornItems.size or
            not wornItems.getItemByIndex then
        return nil
    end
    local sizeOk, count = pcall(wornItems.size, wornItems)
    if not sizeOk or type(count) ~= "number" or count < 0 then return nil end
    local result = { "worn", tostring(count) }
    for index = 0, count - 1 do
        local itemOk, item = pcall(
                wornItems.getItemByIndex, wornItems, index)
        if not itemOk or not item then return nil end
        local fullName = getItemFullName(item)
        if type(fullName) ~= "string" or fullName == "" then return nil end
        local location = nil
        if wornItems.getLocation then
            local locationOk, value = pcall(
                    wornItems.getLocation, wornItems, item)
            if locationOk then location = value end
        end
        result[#result + 1] = fullName
        result[#result + 1] = tostring(location or "")
        local visual = getItemVisual(item)
        local alternate = visual and visual.getAlternateModelName and
                safeNoArgMethod(visual, "getAlternateModelName") or nil
        result[#result + 1] = tostring(alternate or "")
    end
    return table.concat(result, "\31")
end

MirageWardrobeCore.getAppearanceSourceSignature = function (player)
    -- During the world render window the live collection is intentionally
    -- swapped to detached visuals.  UI observers asking in that window still
    -- need the identity of the restored physical source, not the donor list.
    local bridge = player and MirageWardrobeCore.appearanceRenderBridges and
            MirageWardrobeCore.appearanceRenderBridges[player] or nil
    if bridge and bridge.snapshot then
        return bridge.snapshot.sourceSignature
    end
    return getAppearanceSourceSignature(player)
end

local function readVisualReferences(visuals)
    if not visuals then return nil, "body-visuals-api-unavailable" end
    if not visuals.size or not visuals.get then
        return nil, "body-visuals-api-unavailable"
    end
    local sizeOk, count = pcall(visuals.size, visuals)
    if not sizeOk or type(count) ~= "number" or count < 0 then
        return nil, "body-visuals-count-unavailable"
    end
    local references = {}
    for index = 0, count - 1 do
        local visualOk, visual = pcall(visuals.get, visuals, index)
        if not visualOk or not visual then
            return nil, "body-visual-record-incomplete index=" ..
                    tostring(index) .. " missing=visual"
        end
        references[#references + 1] = visual
    end
    return references
end

local function replaceWornItems(wornItems, records)
    if not wornItems or not wornItems.clear or not wornItems.setItem then
        error("worn-items-swap-api-unavailable")
    end
    wornItems:clear()
    for _, record in ipairs(records or {}) do
        -- location is the original ItemBodyLocation object, never its string.
        wornItems:setItem(record.location, record.item)
    end
end

local function replaceVisualReferences(visuals, references)
    if not visuals or not visuals.clear or not visuals.add then
        error("body-visuals-swap-api-unavailable")
    end
    visuals:clear()
    for _, visual in ipairs(references or {}) do visuals:add(visual) end
end

local function resolveAppearanceState(player, state)
    local slotTransmogTable = getStateSlotTransmogTable(player, state)
    return {
        transmogTable = getStateTransmogTable(player, state),
        slotTransmogTable = slotTransmogTable,
        slotVariantTable = getStateSlotVariantTable(
                player, state, slotTransmogTable),
        hiddenItemsTable = getStateHiddenItemsTable(player, state),
        originalClothingOverrides =
                getStateOriginalClothingOverrides(player, state),
        wornVisualSlots = getStateWornVisualSlots(player, state),
        cleanAppearanceOptions = getStateCleanAppearanceOptions(player, state),
        hideOriginalClothing =
                getStateHideOriginalClothing(player, state),
    }
end

local function matchRemoteVisualSlots(sourceVisuals, records)
    records = copyWornVisualSlots(records)
    if not sourceVisuals or not sourceVisuals.size or not sourceVisuals.get then
        return nil
    end

    local manager = getScriptManager and getScriptManager() or nil
    local recordsByTypeSlot = {}
    local recordsByTypeOccurrence = {}
    local recordTypeCounts = {}
    local usedRecords = {}
    for recordIndex, record in ipairs(records) do
        local typeKey = record.itemType
        recordTypeCounts[typeKey] = (recordTypeCounts[typeKey] or 0) + 1
        local typeSlotKey = typeKey .. "\31" .. record.slot
        local bySlot = recordsByTypeSlot[typeSlotKey]
        if not bySlot then
            bySlot = {}
            recordsByTypeSlot[typeSlotKey] = bySlot
        end
        bySlot[#bySlot + 1] = recordIndex
        recordsByTypeOccurrence[typeKey .. "\31" ..
                tostring(record.occurrence)] = recordIndex
    end

    -- Remote visuals and the sender's worn records may update on adjacent ticks.
    -- Match each type independently so one transient item cannot discard all slots.
    local sourceTypeCounts = {}
    for index = 0, sourceVisuals:size() - 1 do
        local visual = sourceVisuals:get(index)
        local itemType = visual and visual.getItemType and
                visual:getItemType() or nil
        if type(itemType) ~= "string" or itemType == "" then return nil end
        sourceTypeCounts[itemType] = (sourceTypeCounts[itemType] or 0) + 1
    end

    local occurrences = {}
    local slots = {}
    for index = 0, sourceVisuals:size() - 1 do
        local visual = sourceVisuals:get(index)
        local itemType = visual and visual.getItemType and
                visual:getItemType() or nil
        if type(itemType) ~= "string" or itemType == "" then return nil end
        occurrences[itemType] = (occurrences[itemType] or 0) + 1

        local sourceSlot = nil
        local scriptItem = manager and manager.FindItem and
                manager:FindItem(itemType) or nil
        if scriptItem and MirageWardrobeCore.getTransmogSourceSlot then
            sourceSlot = MirageWardrobeCore.getTransmogSourceSlot(scriptItem)
        end

        local recordIndex = nil
        if sourceSlot then
            local bySlot = recordsByTypeSlot[itemType .. "\31" .. sourceSlot]
            if bySlot then
                for _, candidateIndex in ipairs(bySlot) do
                    if not usedRecords[candidateIndex] then
                        recordIndex = candidateIndex
                        break
                    end
                end
            end
        end
        -- Occurrence is unambiguous only while both sides have the same type count.
        if not recordIndex and sourceTypeCounts[itemType] ==
                recordTypeCounts[itemType] then
            recordIndex = recordsByTypeOccurrence[itemType .. "\31" ..
                    tostring(occurrences[itemType])]
            if recordIndex and usedRecords[recordIndex] then recordIndex = nil end
        end
        if recordIndex then
            usedRecords[recordIndex] = true
            slots[index + 1] = records[recordIndex].slot
        end
    end
    return slots
end

MirageWardrobeCore.createRemoteDetachedAppearanceSnapshot = function (player,
        sourceRemoteVisuals, desiredClean, resolvedState)
    local sourceSignature = getAppearanceSourceSignature(player)
    if type(sourceSignature) ~= "string" or sourceSignature == "" then
        return nil, "remote-source-signature-unavailable"
    end
    local ok, snapshotOrError, warning = pcall(function ()
        if not sourceRemoteVisuals or not sourceRemoteVisuals.size or
                not sourceRemoteVisuals.get then
            return nil, "remote-item-visuals-api-unavailable"
        end

        local manager = getScriptManager and getScriptManager() or nil
        if not manager or not manager.FindItem then
            return nil, "remote-script-manager-unavailable"
        end
        local cleanOptions = resolvedState.cleanAppearanceOptions
        local occupiedSlots = {}
        local retainedItems = {}
        local remoteRenderRecords = {}
        local synchronizedSlots = matchRemoteVisualSlots(
                sourceRemoteVisuals, resolvedState.wornVisualSlots)

        local function validDonor(fullName)
            return type(fullName) == "string" and fullName ~= "" and
                    manager:FindItem(fullName) ~= nil
        end

        local function createDonorVisual(sourceVisual, donorFullName, variant,
                diagnosticSlot)
            if not validDonor(donorFullName) then
                warnCompatibility(
                        "remote-missing-donor", donorFullName, diagnosticSlot,
                        "donor script is unavailable")
                error("remote donor is unavailable")
            end
            local cloneItem = instanceItem(donorFullName)
            local cloneVisual = getItemVisual(cloneItem)
            if not cloneItem or not cloneVisual or not cloneVisual.setItemType then
                warnCompatibility(
                        "remote-donor-clone", donorFullName, diagnosticSlot,
                        "donor clone is unavailable")
                error("remote donor clone is unavailable")
            end
            cloneVisual:setItemType(donorFullName)
            if cloneVisual.setAlternateModelName then
                cloneVisual:setAlternateModelName(nil)
            end
            if variant then applyVariantToVisual(cloneVisual, variant) end
            if sourceVisual then copyPreviewWear(sourceVisual, cloneVisual) end
            if desiredClean == true then
                clearCleanAppearanceWear(cloneVisual, cleanOptions)
            end
            syncDetachedItemColor(cloneItem, cloneVisual, nil, variant)
            if not resolveDetachedVisualStyle(cloneVisual) then
                warnCompatibility(
                        "remote-donor-style", donorFullName, diagnosticSlot,
                        "donor style is not ready")
                error("remote donor style is unavailable")
            end
            if cloneVisual.setInventoryItem then
                cloneVisual:setInventoryItem(cloneItem)
            end
            return cloneVisual, cloneItem
        end

        local function createRemoteRenderRecord(sourceVisual, scriptItem,
                fullName, slot, donorFullName, variant, sourceKind, sourceIndex)
            local cloneVisual = nil
            local retainedItem = nil
            if donorFullName then
                cloneVisual, retainedItem = createDonorVisual(
                        sourceVisual, donorFullName, variant, slot)
            else
                cloneVisual = clonePreviewVisual(
                        sourceVisual, desiredClean == true, cleanOptions)
                if not cloneVisual or
                        not resolveDetachedVisualStyle(cloneVisual) then
                    warnCompatibility(
                            "remote-source-clone", fullName, slot,
                            "source visual clone is unavailable")
                    error("remote source visual clone is unavailable")
                end
            end

            local renderScript = scriptItem
            local renderSlot = slot
            if donorFullName and
                    donorFullName ~= MirageWardrobeCore.HIDDEN_VISUAL_TYPE then
                renderScript = manager:FindItem(donorFullName)
                renderSlot = getRenderSlotForDonor(
                        scriptItem, renderScript, slot)
            elseif donorFullName == MirageWardrobeCore.HIDDEN_VISUAL_TYPE then
                renderScript = manager:FindItem(donorFullName)
            else
                renderSlot = getHoodieRenderSlot(scriptItem) or slot
            end
            local carrierFullType, carrierScript =
                    getRenderCarrierForItem(renderScript)
            if carrierFullType and cloneVisual.setItemType then
                cloneVisual:setItemType(carrierFullType)
                renderScript = carrierScript
            end
            return {
                visual = cloneVisual,
                scriptItem = renderScript,
                appearanceType = donorFullName or fullName,
                sourceKind = sourceKind,
                carrierType = carrierFullType,
                compatibilityRoute = carrierFullType ~= nil,
                renderSlot = renderSlot,
                receiverSlot = slot,
                sourceIndex = sourceIndex,
                priority = sourceKind == "transmog" and 30 or
                        (sourceKind == "slot-hidden" and 25 or
                        (sourceKind == "original-hidden" and 20 or 10)),
            }, retainedItem
        end

        for visualIndex = 0, sourceRemoteVisuals:size() - 1 do
            local sourceVisual = sourceRemoteVisuals:get(visualIndex)
            local fullName = sourceVisual and sourceVisual.getItemType and
                    sourceVisual:getItemType() or nil
            if type(fullName) ~= "string" or fullName == "" then
                return nil, "remote-source-record-incomplete index=" ..
                        tostring(visualIndex) .. " missing=type"
            end
            local scriptItem = manager:FindItem(fullName)
            local slot = synchronizedSlots and
                    synchronizedSlots[visualIndex + 1] or nil
            if not slot then
                slot = scriptItem and
                        MirageWardrobeCore.getTransmogSourceSlot(scriptItem) or nil
            end
            if slot then occupiedSlots[slot] = true end

            local requestedDonor = slot and
                    resolvedState.slotTransmogTable[slot] or nil
            requestedDonor = requestedDonor or
                    resolvedState.transmogTable[fullName]
            local donorFullName = requestedDonor
            local variant = slot and resolvedState.slotVariantTable[slot] or nil
            local sourceKind = "original"
            if slot and resolvedState.hiddenItemsTable[
                    getSlotHiddenKey(slot)] == true then
                donorFullName = MirageWardrobeCore.HIDDEN_VISUAL_TYPE
                variant = nil
                sourceKind = "slot-hidden"
            elseif requestedDonor ~= nil then
                if not validDonor(requestedDonor) then
                    warnCompatibility(
                            "remote-missing-donor", requestedDonor, slot,
                            "saved donor script is unavailable; using the original appearance")
                    donorFullName = nil
                    variant = nil
                    if shouldHideOriginalClothing(slot,
                            resolvedState.hideOriginalClothing,
                            resolvedState.originalClothingOverrides) then
                        donorFullName = MirageWardrobeCore.HIDDEN_VISUAL_TYPE
                        sourceKind = "original-hidden"
                    end
                else
                    sourceKind = "transmog"
                end
            elseif shouldHideOriginalClothing(slot,
                    resolvedState.hideOriginalClothing,
                    resolvedState.originalClothingOverrides) then
                donorFullName = MirageWardrobeCore.HIDDEN_VISUAL_TYPE
                variant = nil
                sourceKind = "original-hidden"
            end

            local recordOk, recordOrError, retainedItem = pcall(
                    createRemoteRenderRecord, sourceVisual, scriptItem,
                    fullName, slot, donorFullName, variant, sourceKind,
                    visualIndex)
            if not recordOk and sourceKind == "transmog" then
                warnCompatibility("remote-donor-fallback",
                        donorFullName, slot, recordOrError)
                donorFullName = nil
                variant = nil
                sourceKind = "original"
                if shouldHideOriginalClothing(slot,
                        resolvedState.hideOriginalClothing,
                        resolvedState.originalClothingOverrides) then
                    donorFullName = MirageWardrobeCore.HIDDEN_VISUAL_TYPE
                    sourceKind = "original-hidden"
                end
                recordOk, recordOrError, retainedItem = pcall(
                        createRemoteRenderRecord, sourceVisual, scriptItem,
                        fullName, slot, donorFullName, variant, sourceKind,
                        visualIndex)
            end
            if not recordOk then
                return nil, "remote-render-record-failed index=" ..
                        tostring(visualIndex) .. " item=" ..
                        compatibilityValue(fullName, 160) .. " detail=" ..
                        compatibilityValue(recordOrError, 256)
            end
            remoteRenderRecords[#remoteRenderRecords + 1] = recordOrError
            if retainedItem then
                retainedItems[#retainedItems + 1] = retainedItem
            end
        end

        -- A saved slot with no synchronized remote visual is a genuine empty
        -- slot. Add it to the same authoritative remote ItemVisuals list rather
        -- than HumanVisual.bodyVisuals, so worn and empty slots share one model
        -- input and cannot mask or overwrite each other.
        local emptySlots = {}
        for slot, donorFullName in pairs(resolvedState.slotTransmogTable) do
            if type(slot) == "string" and slot ~= "" and
                    type(donorFullName) == "string" and donorFullName ~= "" and
                    donorFullName ~= MirageWardrobeCore.HIDDEN_VISUAL_TYPE and
                    not occupiedSlots[slot] and
                    resolvedState.hiddenItemsTable[getSlotHiddenKey(slot)] ~= true then
                if not validDonor(donorFullName) then
                    warnCompatibility(
                            "remote-missing-empty-donor", donorFullName, slot,
                            "saved donor script is unavailable; empty slot was skipped")
                else
                    emptySlots[#emptySlots + 1] = slot
                end
            end
        end
        table.sort(emptySlots, function (left, right)
            local leftScript = manager:FindItem(resolvedState.slotTransmogTable[left])
            local rightScript = manager:FindItem(resolvedState.slotTransmogTable[right])
            local leftRender = getRenderSlotForItem(leftScript, left)
            local rightRender = getRenderSlotForItem(rightScript, right)
            local leftIndex = getBodyLocationSortIndex(player, leftRender)
            local rightIndex = getBodyLocationSortIndex(player, rightRender)
            if leftIndex ~= rightIndex then return leftIndex < rightIndex end
            if leftRender ~= rightRender then
                return tostring(leftRender or "") < tostring(rightRender or "")
            end
            return left < right
        end)
        if #emptySlots > MirageWardrobeCore.MAX_VISUAL_PROXIES then
            return nil, "remote-empty-slot-limit-exceeded count=" ..
                    tostring(#emptySlots)
        end
        for _, slot in ipairs(emptySlots) do
            local donorFullName = resolvedState.slotTransmogTable[slot]
            local recordOk, recordOrError, retainedItem = pcall(
                    createRemoteRenderRecord, nil, nil, donorFullName, slot,
                    donorFullName, resolvedState.slotVariantTable[slot],
                    "transmog",
                    sourceRemoteVisuals:size() + #remoteRenderRecords)
            if recordOk then
                -- Keep an actual remote worn donor ahead of an empty-slot
                -- proxy when both resolve to the same native location.
                recordOrError.priority = 29
                remoteRenderRecords[#remoteRenderRecords + 1] = recordOrError
                if retainedItem then
                    retainedItems[#retainedItems + 1] = retainedItem
                end
            else
                warnCompatibility("remote-empty-donor-skip",
                        donorFullName, slot, recordOrError)
            end
        end
        local wornItems = player.getWornItems and player:getWornItems() or nil
        local wornGroup = wornItems and wornItems.getBodyLocationGroup and
                wornItems:getBodyLocationGroup() or nil
        local remoteCandidates = remoteRenderRecords
        remoteRenderRecords = selectRenderRecords(
                player, remoteCandidates, wornGroup)
        local remoteVisuals = {}
        for _, record in ipairs(remoteRenderRecords) do
            remoteVisuals[#remoteVisuals + 1] = record.visual
        end

        local sourceBodyVisuals = getPlayerBodyVisuals(player)
        local bodyReferences, bodyError = readVisualReferences(sourceBodyVisuals)
        if not bodyReferences then return nil, bodyError end
        local bodyVisuals = {}
        for index, sourceVisual in ipairs(bodyReferences) do
            if not getVisualProxySlot(sourceVisual) then
                local sourceType = sourceVisual and sourceVisual.getItemType and
                        safeNoArgMethod(sourceVisual, "getItemType") or nil
                local cloneVisual = clonePreviewVisual(
                        sourceVisual, desiredClean == true, cleanOptions)
                if not cloneVisual or not resolveDetachedVisualStyle(cloneVisual) then
                    return nil, "remote-body-visual-clone-failed index=" ..
                            tostring(index - 1) .. " item=" ..
                            compatibilityValue(sourceType, 160) ..
                            " detail=clone-or-style-unavailable"
                end
                bodyVisuals[#bodyVisuals + 1] = cloneVisual
            end
        end
        local sourceAttachedItems = player.getAttachedItems and
                player:getAttachedItems() or nil
        local attachedItems, attachedError = readAttachedItemRecords(
                sourceAttachedItems, true, desiredClean == true, cleanOptions)
        if not attachedItems then return nil, attachedError end

        return {
            descriptor = nil,
            wornItems = {},
            remoteVisuals = remoteVisuals,
            remoteItems = retainedItems,
            bodyVisuals = bodyVisuals,
            attachedItems = attachedItems,
            state = resolvedState,
            clean = desiredClean == true,
            cleanAppearanceOptions = copyCleanAppearanceOptions(
                    cleanOptions, false),
            sourceSignature = sourceSignature,
            revision = MirageWardrobeCore.getAppearanceRevision(player),
            warning = nil,
        }
    end)
    if not ok then return nil, snapshotOrError end
    if not snapshotOrError then return nil, warning end
    return snapshotOrError
end

local function createDetachedAppearanceSnapshot(player, desiredClean, state)
    local resolvedState = resolveAppearanceState(player, state)
    local remoteVisuals = MirageWardrobeCore.getRemotePlayerItemVisuals(player)
    if remoteVisuals then
        return MirageWardrobeCore.createRemoteDetachedAppearanceSnapshot(
                player, remoteVisuals, desiredClean == true, resolvedState)
    end
    local sourceSignature = getAppearanceSourceSignature(player)
    if type(sourceSignature) ~= "string" or sourceSignature == "" then
        return nil, "local-source-signature-unavailable"
    end
    local previewDesc, warning =
            MirageWardrobeCore.createAppearancePreviewSurvivorDesc(
                    player, desiredClean == true, resolvedState)
    if not previewDesc then return nil, warning end
    if warning ~= nil then
        return nil, warning
    end

    local detachedWornItems = previewDesc.getWornItems and
            previewDesc:getWornItems() or nil
    local wornRecords, wornError =
            readWornItemRecords(detachedWornItems)
    if not wornRecords then return nil, wornError end

    -- Resolve lazy style indices only on detached visuals. A physical item can
    -- legitimately retain -1 until model population, while the asynchronous
    -- snapshot must remain self-contained after the real WornItems are restored.
    for index, record in ipairs(wornRecords) do
        local visual = getItemVisual(record.item)
        if not visual or not resolveDetachedVisualStyle(visual) then
            return nil, "detached worn-item style index=" ..
                    tostring(index - 1) .. " item=" ..
                    compatibilityValue(getItemFullName(record.item), 160) ..
                    " detail=style-unavailable"
        end
    end

    local previewHumanVisual = previewDesc.getHumanVisual and
            previewDesc:getHumanVisual() or nil
    local previewBodyVisuals = previewHumanVisual and
            previewHumanVisual.getBodyVisuals and
            previewHumanVisual:getBodyVisuals() or nil
    local bodyVisuals, bodyError =
            readVisualReferences(previewBodyVisuals)
    if not bodyVisuals then return nil, bodyError end
    for index, visual in ipairs(bodyVisuals) do
        if not resolveDetachedVisualStyle(visual) then
            local visualType = visual and visual.getItemType and
                    safeNoArgMethod(visual, "getItemType") or nil
            return nil, "detached body-visual style index=" ..
                    tostring(index - 1) .. " item=" ..
                    compatibilityValue(visualType, 160) ..
                    " detail=style-unavailable"
        end
    end

    local sourceAttachedItems = player.getAttachedItems and
            player:getAttachedItems() or nil
    local attachedItems, attachedError =
            readAttachedItemRecords(sourceAttachedItems, true,
                    desiredClean == true,
                    resolvedState.cleanAppearanceOptions)
    if not attachedItems then return nil, attachedError end

    return {
        descriptor = previewDesc,
        wornItems = wornRecords,
        bodyVisuals = bodyVisuals,
        attachedItems = attachedItems,
        state = resolvedState,
        clean = desiredClean == true,
        cleanAppearanceOptions = copyCleanAppearanceOptions(
                resolvedState.cleanAppearanceOptions, false),
        sourceSignature = sourceSignature,
        revision = MirageWardrobeCore.getAppearanceRevision(player),
        warning = warning,
    }
end

local function runWithDetachedAppearanceSnapshot(player, desiredClean, state,
        refreshDerivedClothingState, consumer)
    if not player or type(consumer) ~= "function" or
            MirageWardrobeCore.appearanceCapturePlayers[player] or
            MirageWardrobeCore.isCapturingCleanAppearance then
        return false, "capture-busy"
    end

    local snapshot, snapshotError =
            createDetachedAppearanceSnapshot(
                    player, desiredClean == true, state)
    if not snapshot then return false, snapshotError end

    local realRemoteVisuals = snapshot.remoteVisuals and
            MirageWardrobeCore.getRemotePlayerItemVisuals(player) or nil
    if snapshot.remoteVisuals and not realRemoteVisuals then
        return false, "remote ItemVisuals API is unavailable"
    end
    local originalRemoteVisuals = nil
    if realRemoteVisuals then
        local remoteError = nil
        originalRemoteVisuals, remoteError =
                readVisualReferences(realRemoteVisuals)
        if not originalRemoteVisuals then return false, remoteError end
    end

    local realWornItems = nil
    local originalWornItems = nil
    if not realRemoteVisuals then
        realWornItems = player.getWornItems and player:getWornItems() or nil
        local wornError = nil
        originalWornItems, wornError = readWornItemRecords(realWornItems)
        if not originalWornItems then return false, wornError end
    end

    local realBodyVisuals = getPlayerBodyVisuals(player)
    local originalBodyVisuals, bodyError =
            readVisualReferences(realBodyVisuals)
    if not originalBodyVisuals then return false, bodyError end
    if not realBodyVisuals and #snapshot.bodyVisuals > 0 then
        return false, "body-visuals-api-unavailable"
    end

    local realAttachedItems = player.getAttachedItems and
            player:getAttachedItems() or nil
    local originalAttachedItems, attachedError =
            readAttachedItemRecords(realAttachedItems, false, false)
    if not originalAttachedItems then return false, attachedError end

    MirageWardrobeCore.appearanceCapturePlayers[player] = true
    MirageWardrobeCore.isCapturingCleanAppearance = true
    local wornTouched = false
    local remoteTouched = false
    local bodyTouched = false
    local attachedTouched = false
    local consumed, consumeResult = pcall(function ()
        attachedTouched = true
        replaceAttachedItems(realAttachedItems, snapshot.attachedItems)
        if realRemoteVisuals then
            remoteTouched = true
            replaceVisualReferences(realRemoteVisuals, snapshot.remoteVisuals)
        else
            wornTouched = true
            replaceWornItems(realWornItems, snapshot.wornItems)
        end
        if realBodyVisuals then
            bodyTouched = true
            replaceVisualReferences(realBodyVisuals, snapshot.bodyVisuals)
        end
        return consumer(snapshot)
    end)


    local restored = true
    local restoreError = nil
    local wornRestored = not wornTouched
    if attachedTouched then
        local ok, err = pcall(replaceAttachedItems,
                realAttachedItems, originalAttachedItems)
        if not ok then
            restored = false
            restoreError = err
        end
    end
    if bodyTouched then
        local ok, err = pcall(replaceVisualReferences,
                realBodyVisuals, originalBodyVisuals)
        if not ok then
            restored = false
            if not restoreError then restoreError = err end
        end
    end
    if remoteTouched then
        local ok, err = pcall(replaceVisualReferences,
                realRemoteVisuals, originalRemoteVisuals)
        if not ok then
            restored = false
            if not restoreError then restoreError = err end
        end
    end
    if wornTouched then
        local ok, err = pcall(replaceWornItems,
                realWornItems, originalWornItems)
        if ok then
            wornRestored = true
        else
            restored = false
            if not restoreError then restoreError = err end
        end
    end
    if wornRestored and wornTouched and
            refreshDerivedClothingState == true then
        local refresh = player.OnClothingUpdated
        if not refresh then
            restored = false
            if not restoreError then
                restoreError = "clothing-derived-state-api-unavailable"
            end
        else
            local ok, err = pcall(refresh, player)
            if not ok then
                restored = false
                if not restoreError then restoreError = err end
            end
        end
    end
    MirageWardrobeCore.appearanceCapturePlayers[player] = nil
    MirageWardrobeCore.isCapturingCleanAppearance = false

    if not restored then
        MirageWardrobeCore.cleanAppearanceCaptureDisabled = true
        MirageWardrobeCore.cleanAppearancePending = {}
        MirageWardrobeCore.cleanAppearanceRendered = {}
        print("[MirageWardrobe] Detached appearance restore failed; feature disabled: " ..
                tostring(restoreError))
        return false, restoreError
    end
    if not consumed then return false, consumeResult end
    return true, consumeResult, snapshot
end

local function restoreAppearanceRenderBridge(player, bridge)
    if not player or type(bridge) ~= "table" then return false end
    local restored = true
    local firstError = nil
    local function restore(fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok then
            restored = false
            if not firstError then firstError = err end
        end
    end

    if bridge.attachedTouched then
        restore(replaceAttachedItems, bridge.realAttachedItems,
                bridge.originalAttachedItems)
    end
    if bridge.bodyTouched then
        restore(replaceVisualReferences, bridge.realBodyVisuals,
                bridge.originalBodyVisuals)
    end
    if bridge.remoteTouched then
        restore(replaceVisualReferences, bridge.realRemoteVisuals,
                bridge.originalRemoteVisuals)
    end
    if bridge.wornTouched then
        restore(replaceWornItems, bridge.realWornItems,
                bridge.originalWornItems)
    end
    MirageWardrobeCore.appearanceCapturePlayers[player] = nil
    MirageWardrobeCore.appearanceRenderBridges[player] = nil

    if not restored then
        MirageWardrobeCore.cleanAppearanceCaptureDisabled = true
        MirageWardrobeCore.cleanAppearancePending = {}
        MirageWardrobeCore.cleanAppearanceRendered = {}
        MirageWardrobeCore.appearanceRenderBridges = {}
        print("[MirageWardrobe] Render bridge restore failed; feature disabled: " ..
                tostring(firstError))
        return false
    end

    MirageWardrobeCore.activeAppearanceSnapshots[player] = bridge.snapshot
    return true
end

MirageWardrobeCore.beginAppearanceRenderBridge = function (player)
    player = player or (getPlayer and getPlayer() or nil)
    if not player or MirageWardrobeCore.cleanAppearanceCaptureDisabled == true or
            MirageWardrobeCore.appearanceRenderBridges[player] then
        return false
    end

    local pending = MirageWardrobeCore.cleanAppearancePending[player]
    local tracksAppearance = MirageWardrobeCore.shouldTrackAppearance and
            MirageWardrobeCore.shouldTrackAppearance(player) == true
    if not pending and not tracksAppearance then
        return false
    end

    local desiredClean = pending and pending.desired == true or
            MirageWardrobeCore.isCleanAppearanceEnabled(player)
    local revision = MirageWardrobeCore.getAppearanceRevision(player)
    local snapshot = MirageWardrobeCore.activeAppearanceSnapshots[player]
    local tick = tonumber(MirageWardrobeCore.cleanAppearanceTickCounter) or 0
    local stateFingerprint = table.concat({
        tostring(revision),
        tostring(desiredClean == true),
    }, "\31")
    local previousFailure =
            MirageWardrobeCore.appearanceSnapshotFailures[player]
    local retryDeferred = previousFailure and
            previousFailure.stateFingerprint == stateFingerprint and
            tick < (previousFailure.retryTick or 0)
    local sourceSignature = nil
    if not retryDeferred then
        sourceSignature = MirageWardrobeCore.getAppearanceSourceSignature and
                MirageWardrobeCore.getAppearanceSourceSignature(player) or nil
    end
    local snapshotFresh = snapshot and snapshot.revision == revision and
            snapshot.clean == desiredClean and
            type(sourceSignature) == "string" and sourceSignature ~= "" and
            snapshot.sourceSignature == sourceSignature
    local requiresSnapshot = not retryDeferred and
            not snapshotFresh
    if requiresSnapshot then
        local failureFingerprint = table.concat({
            tostring(revision),
            tostring(desiredClean == true),
            tostring(sourceSignature or "<incomplete>"),
        }, "\31")
        local snapshotError = nil
        local candidate = nil
        candidate, snapshotError = createDetachedAppearanceSnapshot(
                player, desiredClean, nil)
        if candidate then
            local verifiedSignature =
                    MirageWardrobeCore.getAppearanceSourceSignature and
                    MirageWardrobeCore.getAppearanceSourceSignature(player) or nil
            if type(verifiedSignature) ~= "string" or
                    verifiedSignature == "" or
                    candidate.sourceSignature ~= verifiedSignature or
                    candidate.revision ~= revision or
                    candidate.clean ~= desiredClean then
                candidate = nil
                snapshotError = "appearance-source-changed-during-snapshot"
            end
        end
        if candidate then
            snapshot = candidate
            MirageWardrobeCore.appearanceSnapshotFailures[player] = nil
        elseif not retryDeferred then
            MirageWardrobeCore.appearanceSnapshotFailures[player] = {
                stateFingerprint = stateFingerprint,
                fingerprint = failureFingerprint,
                retryTick = tick +
                        MirageWardrobeCore.APPEARANCE_SNAPSHOT_FAILURE_RETRY_TICKS,
                reason = tostring(snapshotError),
            }
            if pending then pending.lastError = tostring(snapshotError) end
            warnCompatibility("snapshot-failed",
                    isLocalPlayer(player) and "local" or "remote",
                    revision, snapshotError)
        end
        if not candidate then return false, snapshotError end
    elseif not retryDeferred then
        MirageWardrobeCore.appearanceSnapshotFailures[player] = nil
    else
        return false, "snapshot-retry-deferred"
    end

    local realRemoteVisuals = snapshot.remoteVisuals and
            MirageWardrobeCore.getRemotePlayerItemVisuals(player) or nil
    if snapshot.remoteVisuals and not realRemoteVisuals then
        return false, "remote ItemVisuals API is unavailable"
    end
    local originalRemoteVisuals = nil
    if realRemoteVisuals then
        local remoteError = nil
        originalRemoteVisuals, remoteError =
                readVisualReferences(realRemoteVisuals)
        if not originalRemoteVisuals then
            return false, remoteError
        end
    end
    local realWornItems = nil
    local originalWornItems = nil
    if not realRemoteVisuals then
        realWornItems = player.getWornItems and player:getWornItems() or nil
        local wornError = nil
        originalWornItems, wornError = readWornItemRecords(realWornItems)
        if not originalWornItems then
            return false, wornError
        end
    end
    local realBodyVisuals = getPlayerBodyVisuals(player)
    local originalBodyVisuals, bodyError = readVisualReferences(realBodyVisuals)
    if not originalBodyVisuals then
        return false, bodyError
    end
    local realAttachedItems = player.getAttachedItems and
            player:getAttachedItems() or nil
    local originalAttachedItems, attachedError =
            readAttachedItemRecords(realAttachedItems, false, false)
    if not originalAttachedItems then
        return false, attachedError
    end

    local bridge = {
        snapshot = snapshot,
        realWornItems = realWornItems,
        originalWornItems = originalWornItems,
        realRemoteVisuals = realRemoteVisuals,
        originalRemoteVisuals = originalRemoteVisuals,
        realBodyVisuals = realBodyVisuals,
        originalBodyVisuals = originalBodyVisuals,
        realAttachedItems = realAttachedItems,
        originalAttachedItems = originalAttachedItems,
        wornTouched = false,
        remoteTouched = false,
        bodyTouched = false,
        attachedTouched = false,
    }
    MirageWardrobeCore.appearanceRenderBridges[player] = bridge
    MirageWardrobeCore.appearanceCapturePlayers[player] = true

    local installed, installError = pcall(function ()
        bridge.attachedTouched = true
        replaceAttachedItems(realAttachedItems, snapshot.attachedItems)
        if realRemoteVisuals then
            bridge.remoteTouched = true
            replaceVisualReferences(realRemoteVisuals, snapshot.remoteVisuals)
        else
            bridge.wornTouched = true
            replaceWornItems(realWornItems, snapshot.wornItems)
        end
        if realBodyVisuals then
            bridge.bodyTouched = true
            replaceVisualReferences(realBodyVisuals, snapshot.bodyVisuals)
        end
    end)
    if not installed then
        restoreAppearanceRenderBridge(player, bridge)
        warnCompatibility("bridge-install-failed",
                snapshot.remoteVisuals and "remote" or "local",
                revision, installError)
        return false, installError
    end
    return true
end

MirageWardrobeCore.endAppearanceRenderBridges = function ()
    if isMapEmpty(MirageWardrobeCore.appearanceRenderBridges) then
        return true, 0
    end
    local bridges = {}
    for player, bridge in pairs(MirageWardrobeCore.appearanceRenderBridges) do
        bridges[#bridges + 1] = { player = player, bridge = bridge }
    end
    local restored = true
    for _, entry in ipairs(bridges) do
        if restoreAppearanceRenderBridge(entry.player, entry.bridge) ~= true then
            restored = false
        end
    end
    return restored, #bridges
end

local function beginPhysicalWornItemsRead(player)
    local bridge = player and
            MirageWardrobeCore.appearanceRenderBridges[player] or nil
    if not bridge or not bridge.wornTouched or not bridge.realWornItems or
            not bridge.originalWornItems or not bridge.snapshot or
            not bridge.snapshot.wornItems then
        return nil
    end

    local depth = tonumber(bridge.physicalWornItemsReadDepth) or 0
    if depth > 0 then
        bridge.physicalWornItemsReadDepth = depth + 1
        return bridge
    end

    local installed = pcall(replaceWornItems, bridge.realWornItems,
            bridge.originalWornItems)
    if not installed then
        restoreAppearanceRenderBridge(player, bridge)
        MirageWardrobeCore.activeAppearanceSnapshots[player] = nil
        MirageWardrobeCore.appearanceSnapshotFailures[player] = nil
        return nil
    end
    bridge.physicalWornItemsReadDepth = 1
    return bridge
end

local function endPhysicalWornItemsRead(player, bridge)
    if not bridge then return end
    local depth = tonumber(bridge.physicalWornItemsReadDepth) or 0
    if depth > 1 then
        bridge.physicalWornItemsReadDepth = depth - 1
        return
    end
    bridge.physicalWornItemsReadDepth = nil

    -- The callback may have ended the bridge itself. Never reinstall a stale
    -- snapshot over a newer bridge or over already-restored physical gear.
    if MirageWardrobeCore.appearanceRenderBridges[player] ~= bridge then return end
    local installed = pcall(replaceWornItems, bridge.realWornItems,
            bridge.snapshot.wornItems)
    if installed then return end

    restoreAppearanceRenderBridge(player, bridge)
    MirageWardrobeCore.activeAppearanceSnapshots[player] = nil
    MirageWardrobeCore.appearanceSnapshotFailures[player] = nil
end

local function callWithPhysicalWornItems(player, callback, self, ...)
    local bridge = beginPhysicalWornItemsRead(player)
    if not bridge then return callback(self, ...) end

    local ok, result = pcall(callback, self, ...)
    endPhysicalWornItemsRead(player, bridge)
    if not ok then error(result) end
    return result
end

-- Moveable weight checks run inside the render-only appearance window. Give
-- those two native checks the physical worn list without ending the bridge.
MirageWardrobeCore.installMoveableGameplayReadBoundary = function ()
    local moveableClass = ISMoveableSpriteProps
    if not moveableClass or
            moveableClass.mirageWardrobeGameplayReadBoundaryInstalled then
        return moveableClass ~= nil
    end

    local originalInfoFlags = moveableClass.getInfoPanelFlagsPerTile
    local originalPickupCheck = moveableClass.canPickUpMoveableInternal
    if type(originalInfoFlags) ~= "function" or
            type(originalPickupCheck) ~= "function" then
        return false
    end

    moveableClass.getInfoPanelFlagsPerTile = function (
            self, square, object, player, mode)
        return callWithPhysicalWornItems(player, originalInfoFlags, self,
                square, object, player, mode)
    end
    moveableClass.canPickUpMoveableInternal = function (
            self, character, square, object, isMulti)
        return callWithPhysicalWornItems(character, originalPickupCheck, self,
                character, square, object, isMulti)
    end
    moveableClass.mirageWardrobeGameplayReadBoundaryInstalled = true
    return true
end

-- ISInventoryPage rebuilds its container buttons from inventory items and
-- calls IsoPlayer:isEquipped() for each bag. UIManager.update can run while
-- the render bridge has detached WornItems installed, which makes a real worn
-- bag look unequipped and removes its button until the next physical refresh.
MirageWardrobeCore.installInventoryPagePhysicalReadBoundary = function ()
    local inventoryPageClass = ISInventoryPage
    if not inventoryPageClass then return false end
    if inventoryPageClass.refreshBackpacks ==
            inventoryPageClass.mirageWardrobePhysicalReadBoundaryWrapper then
        return true
    end

    local originalRefreshBackpacks = inventoryPageClass.refreshBackpacks
    if type(originalRefreshBackpacks) ~= "function" then return false end

    local wrapper = function (self, ...)
        local player = nil
        if self and getSpecificPlayer then
            player = getSpecificPlayer(self.player)
        end
        player = player or (getPlayer and getPlayer() or nil)
        local ok, result = pcall(callWithPhysicalWornItems,
                player, originalRefreshBackpacks, self, ...)
        if not ok then error(result) end
        return result
    end
    inventoryPageClass.refreshBackpacks = wrapper
    inventoryPageClass.mirageWardrobePhysicalReadBoundaryWrapper = wrapper
    inventoryPageClass.mirageWardrobePhysicalReadBoundaryInstalled = true
    return true
end

MirageWardrobeCore.shouldTrackAppearance = function (player, state)
    player = player or (getPlayer and getPlayer() or nil)
    if not player then return false end
    if MirageWardrobeCore.isCleanAppearanceEnabled(player) then return true end
    if getStateHideOriginalClothing(player, state) then return true end
    if not isMapEmpty(getStateTransmogTable(player, state)) then return true end
    if not isMapEmpty(getStateSlotTransmogTable(player, state)) then return true end
    if not isMapEmpty(getStateHiddenItemsTable(player, state)) then return true end
    if not isMapEmpty(getStateOriginalClothingOverrides(player, state)) then return true end
    if hasUnresolvedFixedTextureWornItem(player) then return true end
    if hasRenderCompatibilityItem(player) then return true end
    return false
end

MirageWardrobeCore.rememberCapturedAppearance = function (player, cleanEnabled, state)
    if not player then return end
    local tracksAppearance = cleanEnabled == true or
            MirageWardrobeCore.shouldTrackAppearance(player, state)
    -- Keep a short-lived completion marker even for the final all-disabled
    -- restore so its detached snapshot survives the current render submission.
    MirageWardrobeCore.cleanAppearanceRendered[player] = {
        enabled = cleanEnabled == true,
        model = getModelIdentity(player),
        tracksAppearance = tracksAppearance,
        completionFrames = tracksAppearance and 0 or 1,
    }
end

local function repairPersistentVisualOverrides(player)
    local changed = removeAllVisualProxies(player)
    local seen = {}
    local function repair(item)
        if not item or seen[item] then return end
        seen[item] = true
        local itemData = item.getModData and item:getModData() or nil
        if itemData and (itemData[MirageWardrobeCore.ITEM_ORIGINAL_VISUAL_KEY] or
                itemData[MirageWardrobeCore.ITEM_ORIGINAL_VARIANT_KEY]) then
            if MirageWardrobeCore.restoreItemVisual(item) then
                changed = true
            else
                -- Even if a lazy original ClothingItem cannot restore its full
                -- style yet, restore its script type immediately so B42 defense
                -- coverage never remains tied to an old donor between retries.
                local originalType =
                        itemData[MirageWardrobeCore.ITEM_ORIGINAL_VISUAL_KEY]
                local visual = getItemVisual(item)
                if type(originalType) == "string" and visual and
                        visual.setItemType then
                    local currentType = visual.getItemType and
                            visual:getItemType() or nil
                    if currentType ~= originalType then
                        visual:setItemType(originalType)
                        changed = true
                    end
                end
            end
        end
    end

    local wornItems = player.getWornItems and player:getWornItems() or nil
    if wornItems and wornItems.size and wornItems.getItemByIndex then
        for index = 0, wornItems:size() - 1 do
            repair(wornItems:getItemByIndex(index))
        end
    end
    local inventory = player.getInventory and player:getInventory() or nil
    local items = inventory and inventory.getItems and inventory:getItems() or nil
    if items and items.size and items.get then
        for index = 0, items:size() - 1 do repair(items:get(index)) end
    end
    return changed
end

MirageWardrobeCore.captureAppearanceTexturesImpl = function (player, desiredClean,
        requiresModelReset)
    local resetWholeModel = requiresModelReset ~= false
    if not player or MirageWardrobeCore.isCapturingCleanAppearance or
            MirageWardrobeCore.cleanAppearanceCaptureDisabled == true then
        return false, "capture-busy"
    end
    if not player.hasActiveModel or (resetWholeModel and not player.resetModel) or
            not player.postUpdateModelTextures or not player.checkUpdateModelTextures then
        return false, "texture-api-unavailable"
    end

    local activeModel, activeOk = safeNoArgMethod(player, "hasActiveModel")
    if not activeOk or activeModel ~= true then return false, "model-inactive" end

    local hasTextureCreatorGetter = player.getTextureCreator ~= nil
    if hasTextureCreatorGetter then
        local creator, creatorOk = safeNoArgMethod(player, "getTextureCreator")
        if not creatorOk then return false, "texture-creator-unavailable" end
        if creator ~= nil then return false, "texture-creator-busy" end
    end

    local captured, captureError, snapshot = runWithDetachedAppearanceSnapshot(
            player, desiredClean == true, nil, true, function ()
        -- ModelManager.Reset is synchronous, but its texture creator retains
        -- ItemVisual references. They now belong to the detached snapshot.
        if resetWholeModel then
            player:resetModel()
        end
        player:postUpdateModelTextures()
        player:checkUpdateModelTextures()
        if hasTextureCreatorGetter then
            local creator, creatorOk = safeNoArgMethod(player, "getTextureCreator")
            if not creatorOk or creator == nil then
                error("texture capture was not accepted")
            end
        end
    end)
    if not captured then
        return false, captureError
    end
    MirageWardrobeCore.activeAppearanceSnapshots[player] = snapshot
    return true
end

-- UI3DModel:setSurvivorDesc() clears AttachedModelNames in B42. setCharacter()
-- keeps attached tools, while its AnimatedModel retains shallow ItemVisual
-- references. Supply detached WornItems during that call and keep the snapshot
-- on the panel for the complete UI render lifetime.
MirageWardrobeCore.setAppearancePreviewCharacter = function (avatarPanel, player,
        cleanAppearance, state)
    player = player or (getPlayer and getPlayer() or nil)
    if not avatarPanel or not avatarPanel.setCharacter or not player then
        return false, "preview-character-api-unavailable"
    end
    local applied, result, snapshot = runWithDetachedAppearanceSnapshot(
            player, cleanAppearance == true, state, false, function ()
                avatarPanel:setCharacter(player)
            end)
    if not applied then
        warnCompatibility("preview-panel-failed",
                isLocalPlayer(player) and "local" or "remote",
                MirageWardrobeCore.getAppearanceRevision(player), result)
        return false, result
    end
    avatarPanel.mirageWardrobeAppearanceSnapshot = snapshot
    return true, snapshot and snapshot.warning or nil
end

MirageWardrobeCore.applyWardrobeAppearance = function (player, state)
    player = player or getPlayer()
    if not player or MirageWardrobeCore.appearanceUpdateInProgress then return false end


    MirageWardrobeCore.appearanceUpdateInProgress = true
    local succeeded, changedOrError = pcall(function ()
        local slotTransmogTable = getStateSlotTransmogTable(player, state)
        local hiddenItemsTable = getStateHiddenItemsTable(player, state)
        migrateLegacyHiddenSlots(slotTransmogTable, hiddenItemsTable)

        -- Repair save data produced by versions that persistently replaced the
        -- physical item's ItemVisual. From this point on, donors exist only
        -- during an atomic model/texture capture.
        local repaired = repairPersistentVisualOverrides(player)
        local cleanEnabled = MirageWardrobeCore.isCleanAppearanceEnabled(player)
        local tracksAppearance = MirageWardrobeCore.shouldTrackAppearance(player, state)
        local needsRestore = MirageWardrobeCore.cleanAppearanceRendered[player] ~= nil or
                MirageWardrobeCore.cleanAppearancePending[player] ~= nil

        -- Every native equipment/model update is allowed to settle first. A
        -- synchronous reset can be overwritten by ModelManager.ResetNextFrame,
        -- leaving the state saved but visually unapplied until clothing is worn
        -- again. One coalesced delayed capture is effectively immediate to the
        -- player while remaining safe for clothing and fluid actions.
        local queued = false
        if tracksAppearance or needsRestore or repaired then
            queued = MirageWardrobeCore.queueCleanAppearanceRefresh(player,
                    MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_DELAY_TICKS,
                    cleanEnabled, true)
        end
        return repaired or queued
    end)
    MirageWardrobeCore.appearanceUpdateInProgress = false

    if not succeeded then
        print("[MirageWardrobe] Failed to apply transmog: " .. tostring(changedOrError))
        return false
    end
    return changedOrError == true
end

MirageWardrobeCore.onEquipHandItem = function (player, item)
    if not player or not item then return end
    -- Hand/attached models are independent of clothing ItemVisuals. Refresh
    -- observers, but never submit a full character texture capture for them.
    MirageWardrobeCore.markAppearanceChanged(player)
end

MirageWardrobeCore.applyNetworkState = function (playerKey, state, revision,
        preserveLocalState, explicitPlayer, localOwnerAcknowledged)
    if type(playerKey) ~= "string" or type(state) ~= "table" then return false, false end

    local previousState = MirageWardrobeCore.networkPlayerData[playerKey]
    local numericRevision = type(revision) == "number" and math.floor(revision) or nil
    local playerRevision = numericRevision and MirageWardrobeCore.networkPlayerRevisions[playerKey] or nil
    if numericRevision and playerRevision and numericRevision < playerRevision then
        return false, false, "stale-revision"
    end
    if numericRevision and numericRevision > MirageWardrobeCore.networkRevision then
        MirageWardrobeCore.networkRevision = numericRevision
    end
    if numericRevision and (not playerRevision or numericRevision > playerRevision) then
        MirageWardrobeCore.networkPlayerRevisions[playerKey] = numericRevision
    end

    local player = explicitPlayer or MirageWardrobeCore.findPlayerByNetworkKey(playerKey)
    local previousCleanAppearance
    local previousCleanAppearanceOptions
    if player then
        previousCleanAppearance = MirageWardrobeCore.isCleanAppearanceEnabled(player)
        previousCleanAppearanceOptions =
                MirageWardrobeCore.getCleanAppearanceOptions(player)
    else
        previousCleanAppearance = type(previousState) == "table" and
                previousState.cleanAppearance == true
        previousCleanAppearanceOptions = copyCleanAppearanceOptions(
                type(previousState) == "table" and
                        previousState.cleanAppearanceOptions or nil, false)
    end

    local cleanState = {
        transmogTable = copyStringMap(state.transmogTable or state),
        slotTransmogTable = copyStringMap(state.slotTransmogTable),
        slotVariantTable = copySlotVariantMap(state.slotVariantTable, false,
                copyStringMap(state.slotTransmogTable)),
        hiddenItemsTable = copyBooleanMap(state.hiddenItemsTable),
        originalClothingOverrides = copyOriginalClothingOverrides(
                state.originalClothingOverrides, false),
        wornVisualSlots = copyWornVisualSlots(state.wornVisualSlots),
        cleanAppearance = state.cleanAppearance == true,
        cleanAppearanceOptions = copyCleanAppearanceOptions(
                state.cleanAppearanceOptions, false),
        hideOriginalClothing = state.hideOriginalClothing == true,
    }
    migrateLegacyHiddenSlots(cleanState.slotTransmogTable, cleanState.hiddenItemsTable)
    MirageWardrobeCore.networkPlayerData[playerKey] = cleanState
    local cacheSource = {
        revision = numericRevision,
        localOwnerApplied = false,
    }
    MirageWardrobeCore.networkPlayerStateSources[playerKey] = cacheSource

    if not player then
        return false, false
    end

    local previewTransaction = isLocalPlayer(player) and
            MirageWardrobeCore.appearancePreviewTransactions[player] or nil
    if previewTransaction and
            (preserveLocalState ~= true or localOwnerAcknowledged == true) then
        -- A server restore received while the wardrobe is previewing changes
        -- the persistent baseline, not the temporary visual overlay. Keep the
        -- overlay visible while committing the new baseline immediately so it
        -- is also the state serialized if the world saves before cancellation.
        if not MirageWardrobeCore.loadPlayerTransmogState(
                cleanState, player) then return false, false end
        previewTransaction.originalState =
                copyAppearanceState(cleanState, player)
        cacheSource.localOwnerApplied = true
        return false, true
    end

    if isLocalPlayer(player) and not preserveLocalState then
        if not MirageWardrobeCore.loadPlayerTransmogState(cleanState, player) then return false, false end
        cacheSource.localOwnerApplied = true
    elseif isLocalPlayer(player) and preserveLocalState then
        cacheSource.localOwnerApplied = localOwnerAcknowledged == true
        return false, true
    else
        MirageWardrobeCore.markAppearanceChanged(player)
    end
    local visualChanged = MirageWardrobeCore.applyWardrobeAppearance(player, cleanState)
    local cleanAppearance = MirageWardrobeCore.isCleanAppearanceEnabled(player)
    local cleanAppearanceOptions = MirageWardrobeCore.getCleanAppearanceOptions(player)
    local cleanOptionsChanged = not cleanAppearanceOptionsEqual(
            previousCleanAppearanceOptions, cleanAppearanceOptions)
    local pending = MirageWardrobeCore.cleanAppearancePending[player]
    local rendered = MirageWardrobeCore.cleanAppearanceRendered[player]
    if previousCleanAppearance ~= cleanAppearance or
            (cleanAppearance and cleanOptionsChanged) or
            (pending and pending.desired ~= cleanAppearance) or
            (rendered and rendered.enabled ~= cleanAppearance) then
        MirageWardrobeCore.queueCleanAppearanceRefresh(player,
                MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_DELAY_TICKS, cleanAppearance, true)
    elseif cleanAppearance then
        MirageWardrobeCore.queueCleanAppearanceRefresh(player, 0, true, false)
    end
    return visualChanged, true
end
MirageWardrobeCore.setNetworkSnapshot = function (players, revision, preserveLocalState, authenticatedLocalKey)
    if type(players) ~= "table" then return false, false end


    local numericRevision = type(revision) == "number" and math.floor(revision) or nil
    if numericRevision and numericRevision > MirageWardrobeCore.networkRevision then
        MirageWardrobeCore.networkRevision = numericRevision
    end

    -- ClientCommand/ServerCommand packets are reliable but unordered in B42.
    -- A newer per-player State may therefore arrive before an older full
    -- Snapshot. Merge the snapshot while preserving any newer delta.
    local previousData = MirageWardrobeCore.networkPlayerData or {}
    local previousRevisions = MirageWardrobeCore.networkPlayerRevisions or {}
    local previousSources = MirageWardrobeCore.networkPlayerStateSources or {}
    MirageWardrobeCore.networkPlayerData = previousData
    MirageWardrobeCore.networkPlayerRevisions = previousRevisions
    MirageWardrobeCore.networkPlayerStateSources = previousSources
    local localKey = type(authenticatedLocalKey) == "string" and authenticatedLocalKey ~= "" and
            authenticatedLocalKey or MirageWardrobeCore.getPlayerSyncKey()
    local localPlayer = getPlayer()
    local hasLocalState = false
    local localStateReady = false
    local snapshotKeys = {}

    for playerKey, state in pairs(players) do
        if type(playerKey) == "string" and type(state) == "table" then
            local isLocalState = playerKey == localKey
            if isLocalState then hasLocalState = true end
            snapshotKeys[playerKey] = true
            local previousRevision = previousRevisions[playerKey]
            local previousSource = previousSources[playerKey]
            -- A per-player State delta and a full Snapshot may carry the same
            -- global revision. If State arrived first, retaining it avoids a
            -- stale equal-revision snapshot reverting the local player.
            local keepEqualDelta = numericRevision and previousRevision == numericRevision and
                    (not isLocalState or
                            (type(previousSource) == "table" and
                                    previousSource.revision == numericRevision and
                                    previousSource.localOwnerApplied == true))
            local keepNewerDelta = numericRevision and previousRevision and
                    (previousRevision > numericRevision or keepEqualDelta)
            if keepNewerDelta then
                if isLocalState and localPlayer then localStateReady = true end
            else
                local explicitPlayer = isLocalState and localPlayer or nil
                local _, stateReady = MirageWardrobeCore.applyNetworkState(playerKey, state, numericRevision,
                        preserveLocalState == true and isLocalState, explicitPlayer)
                if isLocalState and stateReady then localStateReady = true end
            end
        end
    end

    -- A revisioned snapshot is a complete server view at that point in time.
    -- Drop cached players absent from it unless a newer delta must be preserved.
    local staleKeys = {}
    for playerKey in pairs(previousData) do
        if type(playerKey) == "string" and not snapshotKeys[playerKey] then
            local previousRevision = previousRevisions[playerKey]
            local keepNewerDelta = numericRevision and previousRevision and
                    previousRevision > numericRevision
            if not keepNewerDelta then staleKeys[#staleKeys + 1] = playerKey end
        end
    end
    for _, playerKey in ipairs(staleKeys) do
        MirageWardrobeCore.networkPlayerData[playerKey] = nil
        MirageWardrobeCore.networkPlayerRevisions[playerKey] = nil
        MirageWardrobeCore.networkPlayerStateSources[playerKey] = nil
    end
    return hasLocalState, localStateReady
end
MirageWardrobeCore.getOriginalClothingAsset = function (fullName)
    return MirageWardrobeCore.originalClothingAssets[fullName]
end

MirageWardrobeCore.getWornSlotEntries = function (player)
    player = player or getPlayer()
    local result = {}
    if not player then return result end

    local seen = {}
    local wornItems = player.getWornItems and player:getWornItems() or nil
    if wornItems then
        for index = 0, wornItems:size() - 1 do
            local item = wornItems:getItemByIndex(index)
            local slot = MirageWardrobeCore.getItemWornSlot(item, player)
            if item and slot and not seen[slot] and MirageWardrobeCore.isSupportedReceiverItem(item, player) then
                seen[slot] = true
                result[#result + 1] = { slot = slot, item = item }
            end
        end
    end

    for slot in pairs(MirageWardrobeCore.getSlotTransmogTable(player)) do
        if type(slot) == "string" and not seen[slot] then
            seen[slot] = true
            result[#result + 1] = { slot = slot, item = nil }
        end
    end

    -- Keep a hidden-only slot reachable so an old save or preset can still be
    -- shown/reset even while that body location is temporarily empty.
    for key, hidden in pairs(MirageWardrobeCore.getHiddenSlotMap(player)) do
        local slot = hidden == true and getSlotFromHiddenKey(key) or nil
        if slot and not seen[slot] then
            seen[slot] = true
            result[#result + 1] = { slot = slot, item = nil }
        end
    end

    for slot in pairs(MirageWardrobeCore.getOriginalClothingOverrides(player)) do
        if type(slot) == "string" and slot ~= "" and not seen[slot] then
            seen[slot] = true
            result[#result + 1] = { slot = slot, item = nil }
        end
    end

    table.sort(result, function (a, b) return string.lower(a.slot) < string.lower(b.slot) end)
    return result
end

local function getLegacyReceiverTypesForSlot(player, slot, transmogTable)
    local receiverTypes = {}

    local function rememberItem(item)
        if not item then return end
        local itemSlot = MirageWardrobeCore.getItemPreferredSlot(item, player)
        if itemSlot == slot then
            local fullName = getItemFullName(item)
            if fullName then receiverTypes[fullName] = true end
        end
    end

    local wornItems = player and player.getWornItems and player:getWornItems() or nil
    if wornItems then
        for index = 0, wornItems:size() - 1 do
            rememberItem(wornItems:getItemByIndex(index))
        end
    end

    local inventory = player and player.getInventory and player:getInventory() or nil
    local items = inventory and inventory:getItems() or nil
    if items then
        for index = 0, items:size() - 1 do
            rememberItem(items:get(index))
        end
    end

    -- Old MirageWardrobe saves keyed mappings by receiver item type. Resolve every
    -- still-installed receiver script so resetting an empty slot cannot revive an
    -- old mapping when a different item is equipped there later.
    for receiverFullName in pairs(type(transmogTable) == "table" and
            transmogTable or {}) do
        local scriptItem = getScriptManager():FindItem(receiverFullName)
        if scriptItem and MirageWardrobeCore.getTransmogSourceSlot(scriptItem) == slot then
            receiverTypes[receiverFullName] = true
        end
    end
    return receiverTypes
end

local function clearLegacyMappingsForSlot(player, slot)
    local transmogTable = MirageWardrobeCore.getItemAppearanceMap(player)
    local receiverTypes = getLegacyReceiverTypesForSlot(player, slot, transmogTable)
    local changed = false

    for receiverFullName in pairs(receiverTypes) do
        if transmogTable[receiverFullName] ~= nil then
            transmogTable[receiverFullName] = nil
            changed = true
        end
    end
    return changed
end

local function captureLegacyMappingsForSlot(source, slot, player)
    local result = {}
    if type(source) ~= "table" then return result end

    local receiverTypes = getLegacyReceiverTypesForSlot(player, slot, source)
    for receiverFullName in pairs(receiverTypes) do
        local donorFullName = source[receiverFullName]
        if type(donorFullName) == "string" then
            result[receiverFullName] = donorFullName
        end
    end
    return result
end

MirageWardrobeCore.captureSlotAppearanceState = function (slot, player, sourceState)
    slot = normalizeSlot(slot)
    player = player or getPlayer()
    if not slot or not player then return nil end

    sourceState = type(sourceState) == "table" and sourceState or nil
    local slotTable = sourceState and sourceState.slotTransmogTable or
            MirageWardrobeCore.getSlotTransmogTable(player)
    local variantTable = sourceState and sourceState.slotVariantTable or
            MirageWardrobeCore.getSlotVariantTable(player)
    local hiddenItemsTable = sourceState and sourceState.hiddenItemsTable or
            MirageWardrobeCore.getHiddenSlotMap(player)
    local originalClothingOverrides = sourceState and
            sourceState.originalClothingOverrides or
            MirageWardrobeCore.getOriginalClothingOverrides(player)
    local transmogTable = sourceState and sourceState.transmogTable or
            MirageWardrobeCore.getItemAppearanceMap(player)

    local donorFullName = type(slotTable) == "table" and slotTable[slot] or nil
    if type(donorFullName) ~= "string" then donorFullName = nil end
    local variant = type(variantTable) == "table" and variantTable[slot] or nil
    if variant ~= nil then
        local valid
        variant, valid = normalizeSlotVariant(variant)
        if not valid then variant = nil end
    end
    local hiddenKey = getSlotHiddenKey(slot)
    local originalOverride = type(originalClothingOverrides) == "table" and
            originalClothingOverrides[slot] or nil
    if originalOverride ~= MirageWardrobeCore.ORIGINAL_CLOTHING_HIDDEN and
            originalOverride ~= MirageWardrobeCore.ORIGINAL_CLOTHING_SHOWN then
        originalOverride = nil
    end

    return {
        slot = slot,
        donorFullName = donorFullName,
        variant = variant,
        hidden = type(hiddenItemsTable) == "table" and
                hiddenItemsTable[hiddenKey] == true,
        originalClothingOverride = originalOverride,
        legacyMappings = captureLegacyMappingsForSlot(transmogTable, slot, player),
    }
end

MirageWardrobeCore.slotAppearanceStatesEqual = function (left, right)
    if left == right then return true end
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    return left.slot == right.slot and
            left.donorFullName == right.donorFullName and
            variantsEqual(left.variant, right.variant) and
            (left.hidden == true) == (right.hidden == true) and
            left.originalClothingOverride == right.originalClothingOverride and
            mapsEqual(left.legacyMappings or {}, right.legacyMappings or {})
end

MirageWardrobeCore.restoreSlotAppearanceState = function (slot, state, player)
    slot = normalizeSlot(slot)
    player = player or getPlayer()
    if not slot or not player or not isLocalPlayer(player) or
            type(state) ~= "table" or
            (state.slot ~= nil and normalizeSlot(state.slot) ~= slot) or
            MirageWardrobeCore.appearancePreviewTransactions[player] ~= nil then
        return false
    end

    local donorFullName = state.donorFullName
    if donorFullName ~= nil and
            (type(donorFullName) ~= "string" or donorFullName == "") then
        return false
    end
    local variant = state.variant
    if variant ~= nil then
        local valid
        variant, valid = normalizeSlotVariant(variant)
        if not valid then return false end
    end
    if state.hidden ~= nil and type(state.hidden) ~= "boolean" then return false end
    local originalOverride = state.originalClothingOverride
    if originalOverride ~= nil and
            originalOverride ~= MirageWardrobeCore.ORIGINAL_CLOTHING_HIDDEN and
            originalOverride ~= MirageWardrobeCore.ORIGINAL_CLOTHING_SHOWN then
        return false
    end
    if state.legacyMappings ~= nil and type(state.legacyMappings) ~= "table" then
        return false
    end

    local normalizedState = {
        slot = slot,
        donorFullName = donorFullName,
        variant = variant,
        hidden = state.hidden == true,
        originalClothingOverride = originalOverride,
        legacyMappings = copyStringMap(state.legacyMappings),
    }
    local currentState = MirageWardrobeCore.captureSlotAppearanceState(slot, player)
    if MirageWardrobeCore.slotAppearanceStatesEqual(currentState, normalizedState) then
        return true
    end

    local slotTable = MirageWardrobeCore.getSlotTransmogTable(player)
    local variantTable = MirageWardrobeCore.getSlotVariantTable(player)
    local hiddenItemsTable = MirageWardrobeCore.getHiddenSlotMap(player)
    local originalClothingOverrides =
            MirageWardrobeCore.getOriginalClothingOverrides(player)
    local transmogTable = MirageWardrobeCore.getItemAppearanceMap(player)
    local hiddenKey = getSlotHiddenKey(slot)

    slotTable[slot] = donorFullName
    variantTable[slot] = variant
    hiddenItemsTable[hiddenKey] = normalizedState.hidden and true or nil
    originalClothingOverrides[slot] = originalOverride
    clearLegacyMappingsForSlot(player, slot)
    for receiverFullName, legacyDonor in pairs(normalizedState.legacyMappings) do
        transmogTable[receiverFullName] = legacyDonor
    end

    MirageWardrobeCore.publishAppearanceState()
    MirageWardrobeCore.applyWardrobeAppearance(player)
    return MirageWardrobeCore.slotAppearanceStatesEqual(
            MirageWardrobeCore.captureSlotAppearanceState(slot, player),
            normalizedState)
end

MirageWardrobeCore.isSlotHidden = function (slot, player)
    slot = normalizeSlot(slot)
    player = player or getPlayer()
    if not slot or not player then return false end

    return MirageWardrobeCore.getHiddenSlotMap(player)[getSlotHiddenKey(slot)] == true
end

MirageWardrobeCore.setSlotHidden = function (slot, hidden)
    slot = normalizeSlot(slot)
    local player = getPlayer()
    if not slot or not player then return false end

    local playerData = player:getModData()
    local rawSlotTable = playerData.mirageWardrobeSlotTransmogTable
    local hadLegacySentinel = type(rawSlotTable) == "table" and
            rawSlotTable[slot] == MirageWardrobeCore.HIDDEN_VISUAL_TYPE
    local slotTable = MirageWardrobeCore.getSlotTransmogTable(player)
    local hiddenItemsTable = MirageWardrobeCore.getHiddenSlotMap(player)
    migrateLegacyHiddenSlots(slotTable, hiddenItemsTable)

    local key = getSlotHiddenKey(slot)
    local wasHidden = hiddenItemsTable[key] == true
    local shouldHide = hidden == true
    if shouldHide then
        hiddenItemsTable[key] = true
    else
        hiddenItemsTable[key] = nil
    end

    local changedState = hadLegacySentinel or wasHidden ~= shouldHide
    if changedState then
        MirageWardrobeCore.publishAppearanceState()
    end
    local changedVisual = MirageWardrobeCore.applyWardrobeAppearance(player)
    return changedState or changedVisual
end

MirageWardrobeCore.setHideOriginalClothingEnabled = function (enabled, player)
    player = player or (getPlayer and getPlayer() or nil)
    if not player then return false end

    local playerData = player.getModData and player:getModData() or nil
    if type(playerData) ~= "table" then return false end
    local previewState = isLocalPlayer(player) and
            getActiveAppearancePreviewState(player) or nil
    local nextEnabled = enabled == true
    local previous
    if previewState then
        previous = previewState.hideOriginalClothing == true
        previewState.hideOriginalClothing = nextEnabled
    else
        previous = playerData[
                MirageWardrobeCore.HIDE_ORIGINAL_CLOTHING_KEY] == true
        playerData[MirageWardrobeCore.HIDE_ORIGINAL_CLOTHING_KEY] = nextEnabled
    end
    local changedState = previous ~= nextEnabled

    if changedState and isLocalPlayer(player) then
        MirageWardrobeCore.publishAppearanceState()
    end
    local changedVisual = MirageWardrobeCore.applyWardrobeAppearance(player)
    return changedState or changedVisual
end

MirageWardrobeCore.isOriginalClothingHiddenAtSlot = function (slot, player)
    slot = normalizeSlot(slot)
    player = player or (getPlayer and getPlayer() or nil)
    if not slot or not player then return false end
    return shouldHideOriginalClothing(slot,
            MirageWardrobeCore.isHideOriginalClothingEnabled(player),
            MirageWardrobeCore.getOriginalClothingOverrides(player))
end

MirageWardrobeCore.setOriginalClothingOverride = function (slot, value, player)
    slot = normalizeSlot(slot)
    player = player or (getPlayer and getPlayer() or nil)
    if not slot or not player then return false end
    if value ~= nil and value ~= MirageWardrobeCore.ORIGINAL_CLOTHING_HIDDEN and
            value ~= MirageWardrobeCore.ORIGINAL_CLOTHING_SHOWN then
        return false
    end
    if isClient and isClient() and not isLocalPlayer(player) then return false end

    local overrides = MirageWardrobeCore.getOriginalClothingOverrides(player)
    local previous = overrides[slot]
    if previous == value then return false end
    overrides[slot] = value

    if isLocalPlayer(player) then MirageWardrobeCore.publishAppearanceState() end
    MirageWardrobeCore.applyWardrobeAppearance(player)
    return true
end

local function normalizePresetName(name)
    if type(name) ~= "string" then return nil end
    local trimmed = string.match(name, "^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then return nil end
    if string.len(trimmed) > MirageWardrobeCore.MAX_OUTFIT_PRESET_NAME_BYTES then return nil end
    if string.find(trimmed, "%c") then return nil end
    return trimmed
end

local function isSafePresetValue(value)
    return type(value) == "string" and value ~= "" and
            string.len(value) <= MirageWardrobeCore.MAX_OUTFIT_PRESET_VALUE_BYTES and
            not string.find(value, "%c")
end

local function copyOutfitPreset(source)
    if type(source) ~= "table" or type(source.slotTransmogTable) ~= "table" or
            type(source.hiddenItemsTable) ~= "table" then
        return nil
    end

    local snapshot = {
        slotTransmogTable = {},
        slotVariantTable = {},
        hiddenItemsTable = {},
        originalClothingOverrides = {},
    }
    if source.cleanAppearance ~= nil then
        if type(source.cleanAppearance) ~= "boolean" then return nil end
        snapshot.cleanAppearance = source.cleanAppearance == true
    end
    snapshot.cleanAppearanceOptions = copyCleanAppearanceOptions(
            source.cleanAppearanceOptions, true)
    if not snapshot.cleanAppearanceOptions then return nil end
    if source.hideOriginalClothing ~= nil then
        if type(source.hideOriginalClothing) ~= "boolean" then return nil end
        snapshot.hideOriginalClothing = source.hideOriginalClothing == true
    end
    local slotCount = 0
    local hiddenCount = 0
    local hiddenResultCount = 0

    local function addHiddenSlot(slot)
        local hiddenKey = getSlotHiddenKey(slot)
        if snapshot.hiddenItemsTable[hiddenKey] ~= true then
            hiddenResultCount = hiddenResultCount + 1
            if hiddenResultCount > MirageWardrobeCore.MAX_OUTFIT_PRESET_HIDDEN_ENTRIES then
                return false
            end
            snapshot.hiddenItemsTable[hiddenKey] = true
        end
        return true
    end

    for slot, donorFullName in pairs(source.slotTransmogTable) do
        slotCount = slotCount + 1
        if slotCount > MirageWardrobeCore.MAX_OUTFIT_PRESET_SLOT_ENTRIES or
                not isSafePresetValue(slot) or not isSafePresetValue(donorFullName) then
            return nil
        end
        if donorFullName == MirageWardrobeCore.HIDDEN_VISUAL_TYPE then
            if not addHiddenSlot(slot) then return nil end
        else
            snapshot.slotTransmogTable[slot] = donorFullName
        end
    end
    snapshot.slotVariantTable = copySlotVariantMap(source.slotVariantTable, true,
            snapshot.slotTransmogTable)
    if not snapshot.slotVariantTable then return nil end

    snapshot.originalClothingOverrides = copyOriginalClothingOverrides(
            source.originalClothingOverrides, true)
    if not snapshot.originalClothingOverrides then return nil end

    for key, value in pairs(source.hiddenItemsTable) do
        hiddenCount = hiddenCount + 1
        local slot = getSlotFromHiddenKey(key)
        if hiddenCount > MirageWardrobeCore.MAX_OUTFIT_PRESET_HIDDEN_ENTRIES or value ~= true or
                not slot or not isSafePresetValue(slot) then
            return nil
        end
        if not addHiddenSlot(slot) then return nil end
    end
    return snapshot
end

local function countMapEntries(source)
    local count = 0
    if type(source) ~= "table" then return count end
    for _ in pairs(source) do
        count = count + 1
    end
    return count
end

local function countPresetEntries(preset)
    if type(preset) ~= "table" then return 0 end
    return countMapEntries(preset.slotTransmogTable) + countMapEntries(preset.slotVariantTable) +
            countMapEntries(preset.hiddenItemsTable) +
            countMapEntries(preset.originalClothingOverrides)
end

local function countPresetLibraryEntries(presets)
    local count = 0
    if type(presets) ~= "table" then return count end
    for _, preset in pairs(presets) do
        count = count + countPresetEntries(preset)
    end
    return count
end

local function usesSessionPresetCache(player)
    return isLocalPlayer(player)
end

local function getSessionPresetCacheKey(player)
    return MirageWardrobeCore.LOCAL_PRESET_CACHE_KEY
end

local function sortedStringKeys(source)
    local keys = {}
    if type(source) ~= "table" then return keys end
    for key in pairs(source) do
        if type(key) == "string" then keys[#keys + 1] = key end
    end
    table.sort(keys, function (left, right)
        local leftLower = string.lower(left)
        local rightLower = string.lower(right)
        if leftLower == rightLower then return left < right end
        return leftLower < rightLower
    end)
    return keys
end

local function encodeOptionalPresetBoolean(value)
    if value == true then return "1" end
    if value == false then return "0" end
    return ""
end

local function decodeOptionalPresetBoolean(value)
    if value == "" or value == nil then return nil, true end
    if value == "1" then return true, true end
    if value == "0" then return false, true end
    return nil, false
end

local function readLocalOutfitPresetFile()
    if type(getFileReader) ~= "function" then return {}, false end
    local openOk, reader = pcall(getFileReader,
            MirageWardrobeCore.OUTFIT_PRESET_FILE, true)
    if not openOk or not reader then return {}, false end

    local header = "MirageWardrobeOutfitPresets|" ..
            tostring(MirageWardrobeCore.OUTFIT_PRESET_FILE_VERSION)
    local lines = {}
    local maxLines = MirageWardrobeCore.MAX_OUTFIT_PRESET_TOTAL_ENTRIES * 10 +
            MirageWardrobeCore.MAX_OUTFIT_PRESETS * 8 + 16
    while #lines < maxLines do
        local readOk, line = pcall(reader.readLine, reader)
        if not readOk or line == nil then break end
        lines[#lines + 1] = tostring(line)
    end
    if type(reader.close) == "function" then pcall(reader.close, reader) end
    if lines[1] ~= header then return {}, false end

    local presets = {}
    local currentPreset = nil
    local currentName = nil
    local index = 2
    local function takeLine()
        local value = lines[index]
        index = index + 1
        return value
    end
    while index <= #lines do
        local recordType = takeLine()
        if recordType == "P" then
            local name = takeLine()
            local cleanAppearance, cleanOk =
                    decodeOptionalPresetBoolean(takeLine())
            local blood, bloodOk = decodeOptionalPresetBoolean(takeLine())
            local holes, holesOk = decodeOptionalPresetBoolean(takeLine())
            local patches, patchesOk = decodeOptionalPresetBoolean(takeLine())
            local hideOriginals, hideOk =
                    decodeOptionalPresetBoolean(takeLine())
            currentName = nil
            currentPreset = nil
            if name and cleanOk and bloodOk and holesOk and patchesOk and hideOk then
                currentName = name
                currentPreset = {
                    slotTransmogTable = {},
                    slotVariantTable = {},
                    hiddenItemsTable = {},
                    originalClothingOverrides = {},
                    cleanAppearanceOptions = {
                        blood = blood == true,
                        holes = holes ~= false,
                        patches = patches ~= false,
                    },
                }
                if cleanAppearance ~= nil then
                    currentPreset.cleanAppearance = cleanAppearance
                end
                if hideOriginals ~= nil then
                    currentPreset.hideOriginalClothing = hideOriginals
                end
                presets[currentName] = currentPreset
            end
        elseif recordType == "S" then
            local slot = takeLine()
            local donor = takeLine()
            local modeValue = takeLine()
            local textureValue = takeLine()
            local tintRValue = takeLine()
            local tintGValue = takeLine()
            local tintBValue = takeLine()
            if currentPreset and slot and donor then
                currentPreset.slotTransmogTable[slot] = donor
                local mode = modeValue ~= "" and modeValue or nil
                local textureIndex = textureValue ~= "" and tonumber(textureValue) or nil
                local tintR = tintRValue ~= "" and tonumber(tintRValue) or nil
                local tintG = tintGValue ~= "" and tonumber(tintGValue) or nil
                local tintB = tintBValue ~= "" and tonumber(tintBValue) or nil
                if mode or textureIndex or tintR or tintG or tintB then
                    currentPreset.slotVariantTable[slot] = {
                        textureMode = mode,
                        textureIndex = textureIndex,
                        tintR = tintR,
                        tintG = tintG,
                        tintB = tintB,
                    }
                end
            end
        elseif recordType == "H" then
            local hiddenKey = takeLine()
            if currentPreset and hiddenKey then
                currentPreset.hiddenItemsTable[hiddenKey] = true
            end
        elseif recordType == "O" then
            local slot = takeLine()
            local value = takeLine()
            if currentPreset and slot and value and
                    (value == MirageWardrobeCore.ORIGINAL_CLOTHING_HIDDEN or
                            value == MirageWardrobeCore.ORIGINAL_CLOTHING_SHOWN) then
                currentPreset.originalClothingOverrides[slot] = value
            end
        elseif recordType == "E" then
            currentName = nil
            currentPreset = nil
        else
            currentName = nil
            currentPreset = nil
        end
    end
    return presets, true
end

local function writeLocalOutfitPresetFile(presets)
    if type(getFileWriter) ~= "function" then return true end
    local openOk, writer = pcall(getFileWriter,
            MirageWardrobeCore.OUTFIT_PRESET_FILE, true, false)
    if not openOk or not writer then return false end

    local lines = {
        "MirageWardrobeOutfitPresets|" ..
                tostring(MirageWardrobeCore.OUTFIT_PRESET_FILE_VERSION),
    }
    for _, name in ipairs(sortedStringKeys(presets)) do
        local preset = copyOutfitPreset(presets[name])
        if preset then
            local options = copyCleanAppearanceOptions(
                    preset.cleanAppearanceOptions, false)
            lines[#lines + 1] = "P"
            lines[#lines + 1] = name
            lines[#lines + 1] = encodeOptionalPresetBoolean(preset.cleanAppearance)
            lines[#lines + 1] = encodeOptionalPresetBoolean(options.blood)
            lines[#lines + 1] = encodeOptionalPresetBoolean(options.holes)
            lines[#lines + 1] = encodeOptionalPresetBoolean(options.patches)
            lines[#lines + 1] = encodeOptionalPresetBoolean(preset.hideOriginalClothing)
            for _, slot in ipairs(sortedStringKeys(preset.slotTransmogTable)) do
                local variant = preset.slotVariantTable[slot] or {}
                lines[#lines + 1] = "S"
                lines[#lines + 1] = slot
                lines[#lines + 1] = preset.slotTransmogTable[slot]
                lines[#lines + 1] = variant.textureMode or ""
                lines[#lines + 1] = variant.textureIndex ~= nil and
                        tostring(variant.textureIndex) or ""
                lines[#lines + 1] = variant.tintR ~= nil and tostring(variant.tintR) or ""
                lines[#lines + 1] = variant.tintG ~= nil and tostring(variant.tintG) or ""
                lines[#lines + 1] = variant.tintB ~= nil and tostring(variant.tintB) or ""
            end
            for _, hiddenKey in ipairs(sortedStringKeys(preset.hiddenItemsTable)) do
                lines[#lines + 1] = "H"
                lines[#lines + 1] = hiddenKey
            end
            for _, slot in ipairs(sortedStringKeys(
                    preset.originalClothingOverrides)) do
                lines[#lines + 1] = "O"
                lines[#lines + 1] = slot
                lines[#lines + 1] = preset.originalClothingOverrides[slot]
            end
            lines[#lines + 1] = "E"
        end
    end

    local writeOk = true
    for _, line in ipairs(lines) do
        if not pcall(writer.write, writer, line .. "\r\n") then
            writeOk = false
            break
        end
    end
    local closeOk = type(writer.close) ~= "function" or pcall(writer.close, writer)
    return writeOk and closeOk
end

local function mergeOutfitPresetLibraries(target, source)
    target = type(target) == "table" and target or {}
    local sanitized = MirageWardrobeCore.sanitizeOutfitPresetTable and
            MirageWardrobeCore.sanitizeOutfitPresetTable(source) or nil
    if type(sanitized) ~= "table" then return target, false end
    local changed = false
    for name, preset in pairs(sanitized) do
        if target[name] == nil then
            target[name] = preset
            changed = true
        end
    end
    return target, changed
end

local function getLocalAccountPresetRecord(player, create)
    if isClient() or not isLocalPlayer(player) or not ModData or not ModData.getOrCreate then
        return nil
    end

    local rootOk, root = pcall(ModData.getOrCreate, MirageWardrobeCore.PRESET_MODDATA_KEY)
    if not rootOk or type(root) ~= "table" then return nil end

    local accountKey = MirageWardrobeCore.LOCAL_PRESET_CACHE_KEY
    local record = root[accountKey]
    if type(record) ~= "table" then
        if not create then return nil end
        record = {}
        root[accountKey] = record
    end
    if type(record.presets) ~= "table" and create then
        record.presets = {}
    end
    return record
end

MirageWardrobeCore.getLocalOutfitPresetTable = function (player)
    player = player or getPlayer()
    if not player then return {} end

    local playerData = player:getModData()
    local key = MirageWardrobeCore.OUTFIT_PRESETS_KEY
    if usesSessionPresetCache(player) then
        local cacheKey = getSessionPresetCacheKey(player)
        local presets = MirageWardrobeCore.localOutfitPresetLibraries[cacheKey]
        if type(presets) ~= "table" then
            local filePresets = readLocalOutfitPresetFile()
            presets = MirageWardrobeCore.sanitizeOutfitPresetTable and
                    MirageWardrobeCore.sanitizeOutfitPresetTable(filePresets) or {}
            local migrated = false

            if not isClient() and ModData and ModData.getOrCreate then
                local rootOk, root = pcall(ModData.getOrCreate,
                        MirageWardrobeCore.PRESET_MODDATA_KEY)
                if rootOk and type(root) == "table" then
                    for _, record in pairs(root) do
                        if type(record) == "table" and type(record.presets) == "table" then
                            local changed
                            presets, changed = mergeOutfitPresetLibraries(
                                    presets, record.presets)
                            migrated = migrated or changed
                        end
                    end
                end
            end

            local legacyPresets = playerData[key]
            if type(legacyPresets) == "table" then
                local changed
                presets, changed = mergeOutfitPresetLibraries(presets, legacyPresets)
                migrated = migrated or changed
            end
            presets = MirageWardrobeCore.sanitizeOutfitPresetTable(presets) or {}
            MirageWardrobeCore.localOutfitPresetLibraries[cacheKey] = presets
            local accountRecord = getLocalAccountPresetRecord(player, true)
            if accountRecord then accountRecord.presets = presets end
            if migrated then writeLocalOutfitPresetFile(presets) end
        end
        -- Presets belong to this installation, not to a character, world, or server.
        -- Character ModData and old Global ModData are migration sources only.
        playerData[key] = nil
        return presets
    end

    if type(playerData[key]) ~= "table" then
        playerData[key] = {}
    end
    return playerData[key]
end

MirageWardrobeCore.getOutfitPresetTable = function (player)
    player = player or getPlayer()
    if not player then return {} end
    local localPresets = MirageWardrobeCore.getLocalOutfitPresetTable(player)
    local merged = MirageWardrobeCore.sanitizeOutfitPresetTable and
            MirageWardrobeCore.sanitizeOutfitPresetTable(localPresets) or {}
    local serverPresets = MirageWardrobeCore.serverOutfitPresetLibrary
    if type(serverPresets) == "table" then
        merged = mergeOutfitPresetLibraries(merged, serverPresets)
    end
    return MirageWardrobeCore.sanitizeOutfitPresetTable(merged) or {}
end

local function storeOutfitPresetTable(player, presets)
    if usesSessionPresetCache(player) then
        local sanitized = MirageWardrobeCore.sanitizeOutfitPresetTable and
                MirageWardrobeCore.sanitizeOutfitPresetTable(presets) or nil
        if not sanitized or not writeLocalOutfitPresetFile(sanitized) then return false end
        MirageWardrobeCore.localOutfitPresetLibraries[getSessionPresetCacheKey(player)] = sanitized
        local accountRecord = getLocalAccountPresetRecord(player, true)
        if accountRecord then accountRecord.presets = sanitized end
        player:getModData()[MirageWardrobeCore.OUTFIT_PRESETS_KEY] = nil
    else
        player:getModData()[MirageWardrobeCore.OUTFIT_PRESETS_KEY] = presets
    end
    return true
end

MirageWardrobeCore.sanitizeOutfitPresetTable = function (source)
    if type(source) ~= "table" then return nil end

    local valid = {}
    local names = {}
    for name, preset in pairs(source) do
        local normalizedName = normalizePresetName(name)
        local snapshot = normalizedName == name and copyOutfitPreset(preset) or nil
        if normalizedName and snapshot then
            valid[normalizedName] = snapshot
            names[#names + 1] = normalizedName
        end
    end
    table.sort(names, function (left, right)
        local leftLower = string.lower(left)
        local rightLower = string.lower(right)
        if leftLower == rightLower then return left < right end
        return leftLower < rightLower
    end)

    local result = {}
    local limit = math.min(#names, MirageWardrobeCore.MAX_OUTFIT_PRESETS)
    local totalEntries = 0
    for index = 1, limit do
        local name = names[index]
        local preset = valid[name]
        local presetEntries = countPresetEntries(preset)
        if totalEntries + presetEntries <= MirageWardrobeCore.MAX_OUTFIT_PRESET_TOTAL_ENTRIES then
            result[name] = preset
            totalEntries = totalEntries + presetEntries
        end
    end
    return result
end

MirageWardrobeCore.makeOutfitPresetSnapshot = function (player)
    return MirageWardrobeCore.sanitizeOutfitPresetTable(
            MirageWardrobeCore.getLocalOutfitPresetTable(player)) or {}
end

MirageWardrobeCore.loadOutfitPresetSnapshot = function (source, requestGeneration, player)
    player = player or getPlayer()
    if not player or type(source) ~= "table" then return false end

    local sanitized = MirageWardrobeCore.sanitizeOutfitPresetTable(source)
    if not sanitized then return false end
    MirageWardrobeCore.serverOutfitPresetLibrary = sanitized
    return true
end

MirageWardrobeCore.markOutfitPresetMutation = function ()
    MirageWardrobeCore.outfitPresetMutationGeneration =
            (MirageWardrobeCore.outfitPresetMutationGeneration or 0) + 1
    return MirageWardrobeCore.outfitPresetMutationGeneration
end

local function sendOutfitPresetUpdate(action, name, preset)
    if not isClient() then return false end
    local player = getPlayer()
    if not player then return false end

    MirageWardrobeCore.ensureNetworkSession()
    MirageWardrobeCore.outfitPresetUpdateSequence =
            (MirageWardrobeCore.outfitPresetUpdateSequence or 0) + 1
    local payload = {
        action = action,
        name = name,
        _clientSession = MirageWardrobeCore.networkSessionId,
        _clientSequence = MirageWardrobeCore.outfitPresetUpdateSequence,
    }
    if action == "save" then
        payload.preset = copyOutfitPreset(preset)
        if not payload.preset then return false end
    elseif action == "replace" then
        payload.presets = MirageWardrobeCore.makeOutfitPresetSnapshot(player)
    end
    sendClientCommand(player, MirageWardrobeCore.NETWORK_MODULE, "PresetUpdate", payload)
    return true
end

MirageWardrobeCore.syncOutfitPresetTableToServer = function ()
    if not isClient() then return false end
    local sent = false
    local presets = MirageWardrobeCore.makeOutfitPresetSnapshot(getPlayer())
    for _, name in ipairs(sortedStringKeys(presets)) do
        local preset = presets[name]
        if sendOutfitPresetUpdate("save", name, preset) then sent = true end
    end
    return sent
end

MirageWardrobeCore.isOutfitPresetLocal = function (name, player)
    name = normalizePresetName(name)
    if not name then return false end
    local presets = MirageWardrobeCore.makeOutfitPresetSnapshot(player)
    return presets[name] ~= nil
end

MirageWardrobeCore.isOutfitPresetAvailable = function (presetOrName, player)
    player = player or getPlayer()
    local preset = presetOrName
    if type(presetOrName) == "string" then
        preset = MirageWardrobeCore.getOutfitPresetTable(player)[presetOrName]
    end
    local snapshot = copyOutfitPreset(preset)
    if not snapshot then return false end
    local manager = getScriptManager and getScriptManager() or nil
    if not manager or not manager.FindItem then return false end
    for _, donorFullName in pairs(snapshot.slotTransmogTable) do
        local findOk, scriptItem = pcall(manager.FindItem, manager, donorFullName)
        if not findOk or not scriptItem then return false end
    end
    return true
end

MirageWardrobeCore.getOutfitPresetNames = function (player, includeUnavailable)
    local names = {}
    local presets = MirageWardrobeCore.getOutfitPresetTable(player)
    for name, preset in pairs(presets) do
        if includeUnavailable == true or
                MirageWardrobeCore.isOutfitPresetAvailable(preset, player) then
            names[#names + 1] = name
        end
    end
    table.sort(names, function (left, right)
        local leftLower = string.lower(left)
        local rightLower = string.lower(right)
        if leftLower == rightLower then return left < right end
        return leftLower < rightLower
    end)
    return names
end

MirageWardrobeCore.saveOutfitPreset = function (name, player)
    name = normalizePresetName(name)
    player = player or getPlayer()
    if not name or not player then return false end

    local snapshot = copyOutfitPreset({
        slotTransmogTable = MirageWardrobeCore.getSlotTransmogTable(player),
        slotVariantTable = MirageWardrobeCore.getSlotVariantTable(player),
        hiddenItemsTable = copySlotHiddenMap(MirageWardrobeCore.getHiddenSlotMap(player)),
        originalClothingOverrides = copyOriginalClothingOverrides(
                MirageWardrobeCore.getOriginalClothingOverrides(player), false),
        cleanAppearance = MirageWardrobeCore.isCleanAppearanceEnabled(player),
        cleanAppearanceOptions = MirageWardrobeCore.getCleanAppearanceOptions(player),
        hideOriginalClothing = MirageWardrobeCore.isHideOriginalClothingEnabled(player),
    })
    if not snapshot then return false end

    local sanitizedPresets = MirageWardrobeCore.makeOutfitPresetSnapshot(player)
    if sanitizedPresets[name] == nil and
            countMapEntries(sanitizedPresets) >= MirageWardrobeCore.MAX_OUTFIT_PRESETS then
        return false
    end
    local oldPresetEntries = countPresetEntries(sanitizedPresets[name])
    local nextTotalEntries = countPresetLibraryEntries(sanitizedPresets) - oldPresetEntries +
            countPresetEntries(snapshot)
    if nextTotalEntries > MirageWardrobeCore.MAX_OUTFIT_PRESET_TOTAL_ENTRIES then return false end
    sanitizedPresets[name] = snapshot
    if not storeOutfitPresetTable(player, sanitizedPresets) then return false end
    MirageWardrobeCore.markOutfitPresetMutation()
    if isLocalPlayer(player) then
        sendOutfitPresetUpdate("save", name, snapshot)
    end
    return true
end

local function validateOutfitPresetSnapshot(name, snapshot, player,
        accessSnapshot, forceAccessRefresh)
    if not MirageWardrobeCore.isOutfitPresetAvailable(snapshot, player) then
        MirageWardrobeCore.lastGameplayDenial = {
            reason = "missing",
            preset = name,
        }
        return false
    end

    if forceAccessRefresh == true then
        accessSnapshot = MirageWardrobeCore.refreshGameplayState(player, true)
    elseif type(accessSnapshot) ~= "table" then
        -- A preview must never discover, persist, or transmit anything. The
        -- open wardrobe already owns a current access snapshot; the empty
        -- fallback simply fails closed for restrictive rule engines.
        accessSnapshot = MirageWardrobeCore.gameplayAccessSnapshot or {}
    end
    for slot, donorFullName in pairs(snapshot.slotTransmogTable) do
        local variant = snapshot.slotVariantTable[slot]
        local allowed, reason, access = MirageWardrobeCore.canApplyAppearance(
                donorFullName, variant, player, false, accessSnapshot)
        if not allowed then
            MirageWardrobeCore.lastGameplayDenial = {
                reason = reason or "unavailable",
                slot = slot,
                donor = donorFullName,
                access = access,
                preset = name,
            }
            return false
        end
    end
    MirageWardrobeCore.lastGameplayDenial = nil
    return true
end

local function makeOutfitPresetPlayerState(snapshot, player, baseState)
    baseState = type(baseState) == "table" and baseState or
            MirageWardrobeCore.makePlayerState(player)
    if type(baseState) ~= "table" then return nil end

    local nextHiddenItems = {}
    for key, value in pairs(baseState.hiddenItemsTable or {}) do
        if type(value) == "boolean" and not getSlotFromHiddenKey(key) then
            nextHiddenItems[key] = value
        end
    end
    for key, value in pairs(snapshot.hiddenItemsTable) do
        nextHiddenItems[key] = value
    end

    -- A preset is a complete slot-appearance snapshot.  An omitted override
    -- means "follow global", so applying the preset must also clear overrides
    -- that only exist in the current state.
    local nextOriginalClothingOverrides = copyOriginalClothingOverrides(
            snapshot.originalClothingOverrides, false)

    local nextCleanAppearance = baseState.cleanAppearance == true
    if type(snapshot.cleanAppearance) == "boolean" then
        nextCleanAppearance = snapshot.cleanAppearance
    end
    local nextHideOriginalClothing = baseState.hideOriginalClothing == true
    if type(snapshot.hideOriginalClothing) == "boolean" then
        nextHideOriginalClothing = snapshot.hideOriginalClothing
    end
    return {
        -- Presets describe the complete slot appearance. Old item-type
        -- mappings must not leak into slots omitted by the preset.
        transmogTable = {},
        slotTransmogTable = copyStringMap(snapshot.slotTransmogTable),
        slotVariantTable = copySlotVariantMap(snapshot.slotVariantTable, false,
                snapshot.slotTransmogTable),
        hiddenItemsTable = nextHiddenItems,
        originalClothingOverrides = nextOriginalClothingOverrides,
        cleanAppearance = nextCleanAppearance,
        cleanAppearanceOptions = copyCleanAppearanceOptions(
                snapshot.cleanAppearanceOptions, false),
        hideOriginalClothing = nextHideOriginalClothing,
    }
end

MirageWardrobeCore.previewOutfitPreset = function (name, player, accessSnapshot,
        baseState)
    name = normalizePresetName(name)
    player = player or getPlayer()
    if not name or not player then return false end

    local snapshot = copyOutfitPreset(
            MirageWardrobeCore.getOutfitPresetTable(player)[name])
    if not snapshot or not validateOutfitPresetSnapshot(
            name, snapshot, player, accessSnapshot, false) then
        return false
    end
    local originalState = type(baseState) == "table" and baseState or
            MirageWardrobeCore.captureAppearancePreviewState(player)
    local state = makeOutfitPresetPlayerState(snapshot, player, originalState)
    return state ~= nil and applyAppearancePreviewState(
            state, player, originalState)
end

MirageWardrobeCore.applyOutfitPreset = function (name, player, forceSync,
        previewToken)
    name = normalizePresetName(name)
    player = player or getPlayer()
    if not name or not player then return false end
    if not canCommitAppearancePreview(player, previewToken) then return false end

    local preset = MirageWardrobeCore.getOutfitPresetTable(player)[name]
    local snapshot = copyOutfitPreset(preset)
    if not snapshot then return false end
    if not validateOutfitPresetSnapshot(name, snapshot, player, nil, true) then
        return false
    end

    if not MirageWardrobeCore.isOutfitPresetLocal(name, player) then
        local localPresets = MirageWardrobeCore.makeOutfitPresetSnapshot(player)
        localPresets[name] = snapshot
        if not storeOutfitPresetTable(player, localPresets) then return false end
        MirageWardrobeCore.markOutfitPresetMutation()
    end

    local previewTransaction =
            MirageWardrobeCore.appearancePreviewTransactions[player]
    local currentState = previewTransaction and
            copyAppearanceState(previewTransaction.originalState, player) or
            MirageWardrobeCore.makePlayerState(player)
    local nextState = makeOutfitPresetPlayerState(snapshot, player, currentState)
    if not nextState then return false end
    local stateChanged = not mapsEqual(currentState.transmogTable,
                    nextState.transmogTable) or
            not mapsEqual(currentState.slotTransmogTable,
                    nextState.slotTransmogTable) or
            not variantMapsEqual(currentState.slotVariantTable,
                    nextState.slotVariantTable) or
            not mapsEqual(currentState.hiddenItemsTable,
                    nextState.hiddenItemsTable) or
            not mapsEqual(currentState.originalClothingOverrides,
                    nextState.originalClothingOverrides) or
            currentState.cleanAppearance ~= nextState.cleanAppearance or
            not cleanAppearanceOptionsEqual(currentState.cleanAppearanceOptions,
                    nextState.cleanAppearanceOptions) or
            currentState.hideOriginalClothing ~= nextState.hideOriginalClothing

    local applied, finishedTransaction =
            applyCommittedAppearanceState(nextState, player, previewToken)
    if not applied then return false end
    local shouldPublish = stateChanged or forceSync == true
    if shouldPublish and isLocalPlayer(player) then
        MirageWardrobeCore.publishAppearanceState()
    elseif not shouldPublish then
        if finishedTransaction and
                finishedTransaction.pendingPublish == true and
                isLocalPlayer(player) then
            MirageWardrobeCore.publishAppearanceState(
                    finishedTransaction.pendingMarkDirty == true)
        end
    end
    return true
end

MirageWardrobeCore.deleteOutfitPreset = function (name, player)
    name = normalizePresetName(name)
    player = player or getPlayer()
    if not name or not player then return false end

    local localPresets = MirageWardrobeCore.makeOutfitPresetSnapshot(player)
    local localExists = localPresets[name] ~= nil
    local serverPresets = MirageWardrobeCore.serverOutfitPresetLibrary
    local serverExists = type(serverPresets) == "table" and
            serverPresets[name] ~= nil
    if not localExists and not serverExists then return false end

    if localExists then
        localPresets[name] = nil
        if not storeOutfitPresetTable(player, localPresets) then return false end
    end
    -- The visible library is local + this server's library. Remove both sides
    -- as one user operation so a server-only preset never needs to be applied
    -- first and an optimistic UI refresh cannot expose the old server copy.
    if type(serverPresets) == "table" then serverPresets[name] = nil end
    MirageWardrobeCore.markOutfitPresetMutation()
    if isLocalPlayer(player) then
        sendOutfitPresetUpdate("delete", name)
    end
    return true
end

MirageWardrobeCore.previewSlotTransmog = function (slot, donorItem, variant, player,
        accessSnapshot, baseState)
    slot = normalizeSlot(slot)
    player = player or getPlayer()
    if not slot or not player or not donorItem then return false end

    local normalizedVariant = nil
    if variant ~= nil then
        local valid
        normalizedVariant, valid = normalizeSlotVariant(variant)
        if not valid then return false end
    end
    local donorFullName = getItemFullName(donorItem)
    if not donorFullName or not getScriptManager():FindItem(donorFullName) or
            donorFullName == MirageWardrobeCore.HIDDEN_VISUAL_TYPE or
            not MirageWardrobeCore.canBeUsedAsTransmogSource(donorItem) then
        return false
    end
    accessSnapshot = type(accessSnapshot) == "table" and accessSnapshot or
            MirageWardrobeCore.gameplayAccessSnapshot or {}
    local allowed = MirageWardrobeCore.canApplyAppearance(
            donorFullName, normalizedVariant, player, false, accessSnapshot)
    if not allowed then return false end

    local originalState = type(baseState) == "table" and baseState or
            MirageWardrobeCore.captureAppearancePreviewState(player)
    local state = type(originalState) == "table" and {
        transmogTable = copyStringMap(originalState.transmogTable),
        slotTransmogTable = copyStringMap(originalState.slotTransmogTable),
        slotVariantTable = copySlotVariantMap(originalState.slotVariantTable, false,
                originalState.slotTransmogTable),
        hiddenItemsTable = copyBooleanMap(originalState.hiddenItemsTable),
        originalClothingOverrides = copyOriginalClothingOverrides(
                originalState.originalClothingOverrides, false),
        cleanAppearance = originalState.cleanAppearance == true,
        cleanAppearanceOptions = copyCleanAppearanceOptions(
                originalState.cleanAppearanceOptions, false),
        hideOriginalClothing = originalState.hideOriginalClothing == true,
    } or nil
    if not state then return false end
    state.slotTransmogTable[slot] = donorFullName
    state.slotVariantTable[slot] = normalizedVariant
    state.hiddenItemsTable[getSlotHiddenKey(slot)] = nil
    return applyAppearancePreviewState(state, player, originalState)
end

MirageWardrobeCore.setSlotTransmog = function (slot, donorItem, variant, forceSync,
        accessSnapshot, previewToken)
    local requestedSlot = slot
    slot = normalizeSlot(slot)
    local player = getPlayer()
    if not slot or not player or not donorItem then
        return false
    end
    if not canCommitAppearancePreview(player, previewToken) then
        return false
    end

    local normalizedVariant = nil
    if variant ~= nil then
        local valid
        normalizedVariant, valid = normalizeSlotVariant(variant)
        if not valid then
            return false
        end
    end

    local donorFullName = getItemFullName(donorItem)
    if not donorFullName or not getScriptManager():FindItem(donorFullName) then
        return false
    end
    if donorFullName == MirageWardrobeCore.HIDDEN_VISUAL_TYPE then
        return MirageWardrobeCore.setSlotHidden(slot, true)
    end
    if not MirageWardrobeCore.canBeUsedAsTransmogSource(donorItem) then
        return false
    end

    local allowed, reason, access = MirageWardrobeCore.canApplyAppearance(
            donorFullName, normalizedVariant, player, true, accessSnapshot)
    if not allowed then
        MirageWardrobeCore.lastGameplayDenial = {
            reason = reason or "unavailable",
            slot = slot,
            donor = donorFullName,
            access = access,
        }
        return false
    end
    MirageWardrobeCore.lastGameplayDenial = nil

    local previewTransaction =
            MirageWardrobeCore.appearancePreviewTransactions[player]

    local slotTable = MirageWardrobeCore.getSlotTransmogTable(player)
    local variantTable = MirageWardrobeCore.getSlotVariantTable(player)
    local hiddenItemsTable = MirageWardrobeCore.getHiddenSlotMap(player)
    local hiddenKey = getSlotHiddenKey(slot)
    local changedMapping = slotTable[slot] ~= donorFullName or
            not variantsEqual(variantTable[slot], normalizedVariant) or
            hiddenItemsTable[hiddenKey] == true
    slotTable[slot] = donorFullName
    variantTable[slot] = normalizedVariant
    hiddenItemsTable[hiddenKey] = nil
    local clearedLegacy = clearLegacyMappingsForSlot(player, slot)

    local changedState = changedMapping or clearedLegacy
    local committedPreview = previewTransaction ~= nil
    local changedVisual = false
    local finishedTransaction = nil
    if committedPreview then
        local committedState = MirageWardrobeCore.makePlayerState(player)
        local committed
        committed, finishedTransaction, changedVisual =
                applyCommittedAppearanceState(committedState, player,
                        previewToken)
        if not committed then return false end
    end
    if changedState or forceSync == true or committedPreview then
        MirageWardrobeCore.publishAppearanceState()
    else
        if finishedTransaction and
                finishedTransaction.pendingPublish == true then
            MirageWardrobeCore.publishAppearanceState(
                    finishedTransaction.pendingMarkDirty == true)
        end
    end
    if not committedPreview then
        changedVisual = MirageWardrobeCore.applyWardrobeAppearance(player)
    end
    return changedState or changedVisual or forceSync == true or committedPreview
end

MirageWardrobeCore.resetSlotTransmog = function (slot)
    slot = normalizeSlot(slot)
    local player = getPlayer()
    if not slot or not player then return false end

    local slotTable = MirageWardrobeCore.getSlotTransmogTable(player)
    local variantTable = MirageWardrobeCore.getSlotVariantTable(player)
    local hiddenItemsTable = MirageWardrobeCore.getHiddenSlotMap(player)
    local originalClothingOverrides =
            MirageWardrobeCore.getOriginalClothingOverrides(player)
    local hiddenKey = getSlotHiddenKey(slot)
    local hadMapping = slotTable[slot] ~= nil
    local hadVariant = variantTable[slot] ~= nil
    local hadHidden = hiddenItemsTable[hiddenKey] == true
    local hadOriginalOverride = originalClothingOverrides[slot] ~= nil
    slotTable[slot] = nil
    variantTable[slot] = nil
    hiddenItemsTable[hiddenKey] = nil
    originalClothingOverrides[slot] = nil
    local clearedLegacy = clearLegacyMappingsForSlot(player, slot)

    local changedState = hadMapping or hadVariant or hadHidden or
            hadOriginalOverride or clearedLegacy
    if changedState then
        MirageWardrobeCore.publishAppearanceState()
    end
    local changedVisual = MirageWardrobeCore.applyWardrobeAppearance(player)
    return changedState or changedVisual
end

MirageWardrobeCore.resetWardrobeState = function ()
    local player = getPlayer()
    if not player then return false end

    local transmogTable = MirageWardrobeCore.getItemAppearanceMap(player)
    local slotTransmogTable = MirageWardrobeCore.getSlotTransmogTable(player)
    local slotVariantTable = MirageWardrobeCore.getSlotVariantTable(player)
    local hiddenItemsTable = MirageWardrobeCore.getHiddenSlotMap(player)
    local originalClothingOverrides =
            MirageWardrobeCore.getOriginalClothingOverrides(player)
    local hadCleanAppearance = MirageWardrobeCore.isCleanAppearanceEnabled(player)
    local cleanAppearanceOptions = MirageWardrobeCore.getCleanAppearanceOptions(player)
    local hadCustomCleanAppearanceOptions = not cleanAppearanceOptionsEqual(
            cleanAppearanceOptions, CLEAN_APPEARANCE_OPTION_DEFAULTS)
    local hadHideOriginalClothing = MirageWardrobeCore.isHideOriginalClothingEnabled(player)
    local hadTransmogs = not isMapEmpty(transmogTable) or not isMapEmpty(slotTransmogTable) or
            not isMapEmpty(slotVariantTable) or not isMapEmpty(hiddenItemsTable) or
            not isMapEmpty(originalClothingOverrides)
    local hadState = hadTransmogs or hadCleanAppearance or
            hadCustomCleanAppearanceOptions or hadHideOriginalClothing
    local changed = false
    local seenItems = {}

    local function restoreTrackedItem(item)
        if not item or seenItems[item] then return end
        seenItems[item] = true

        local fullName = getItemFullName(item)
        local itemData = item.getModData and item:getModData() or nil
        local wornSlot = MirageWardrobeCore.getItemWornSlot(item, player)
        if (fullName and transmogTable[fullName] ~= nil) or
                (wornSlot and slotTransmogTable[wornSlot] ~= nil) or
                (wornSlot and slotVariantTable[wornSlot] ~= nil) or
                (wornSlot and hiddenItemsTable[getSlotHiddenKey(wornSlot)] == true) or
                (itemData and (itemData[MirageWardrobeCore.ITEM_ORIGINAL_VISUAL_KEY] or
                        itemData[MirageWardrobeCore.ITEM_ORIGINAL_VARIANT_KEY])) then
            if MirageWardrobeCore.restoreItemVisual(item) then
                changed = true
            end
        end

        local backupAsset = fullName and MirageWardrobeCore.getOriginalClothingAsset(fullName) or nil
        local scriptItem = getItemScript(item)
        if backupAsset and scriptItem and scriptItem.setClothingItemAsset then
            scriptItem:setClothingItemAsset(backupAsset)
            changed = true
        end
    end

    local wornItems = player.getWornItems and player:getWornItems() or nil
    if wornItems then
        for index = 0, wornItems:size() - 1 do
            restoreTrackedItem(wornItems:getItemByIndex(index))
        end
    end

    local inventory = player:getInventory()
    local items = inventory and inventory:getItems() or nil
    if items then
        for index = 0, items:size() - 1 do
            restoreTrackedItem(items:get(index))
        end
    end

    player:getModData().mirageWardrobeTransmogTable = {}
    player:getModData().mirageWardrobeSlotTransmogTable = {}
    player:getModData().mirageWardrobeSlotVariantTable = {}
    player:getModData().mirageWardrobeHiddenItemsTable = {}
    player:getModData()[MirageWardrobeCore.ORIGINAL_CLOTHING_OVERRIDES_KEY] = {}
    player:getModData()[MirageWardrobeCore.CLEAN_APPEARANCE_KEY] = false
    player:getModData()[MirageWardrobeCore.CLEAN_APPEARANCE_OPTIONS_KEY] =
            copyCleanAppearanceOptions(nil, false)
    player:getModData()[MirageWardrobeCore.HIDE_ORIGINAL_CLOTHING_KEY] = false
    MirageWardrobeCore.originalClothingAssets = {}

    if hadState then
        MirageWardrobeCore.publishAppearanceState()
    end
    local repairedByApply = MirageWardrobeCore.applyWardrobeAppearance(player)
    if changed and not repairedByApply then
        MirageWardrobeCore.refreshPlayerVisual(player, true)
    end
    if hadCleanAppearance then
        MirageWardrobeCore.queueCleanAppearanceRefresh(player,
                (changed or repairedByApply) and MirageWardrobeCore.CLEAN_APPEARANCE_MODEL_DELAY_TICKS or 0,
                false, true)
    end
    return changed or hadState or repairedByApply
end

local function getGameplayPlayerSquare(player)
    if not player then return nil end
    local square = nil
    if player.getCurrentSquare then
        square = safeNoArgMethod(player, "getCurrentSquare")
    end
    if not square and player.getSquare then
        square = safeNoArgMethod(player, "getSquare")
    end
    return square
end

local function gameplayRulesUseNearby(rules)
    local mode = type(rules) == "table" and rules.accessMode or nil
    return mode == "nearby" or mode == "unlocked_or_nearby" or
            mode == "unlocked_and_nearby"
end

local function gameplayRulesUseDynamicAccess(rules)
    local mode = type(rules) == "table" and rules.accessMode or nil
    return type(mode) == "string" and mode ~= "" and mode ~= "all"
end

local function getActiveGameplayAccessRules()
    local snapshot = MirageWardrobeCore.gameplayAccessSnapshot
    return snapshot and snapshot.rules or
            (MirageWardrobeCore.getGameplayRules and
                    MirageWardrobeCore.getGameplayRules() or nil)
end

local function detectGameplaySquareChange(localPlayer)
    if not localPlayer or
            not gameplayRulesUseNearby(getActiveGameplayAccessRules()) then
        return false
    end
    local currentSquare = getGameplayPlayerSquare(localPlayer)
    if not currentSquare or
            currentSquare == MirageWardrobeCore.gameplayAccessSquare then
        return false
    end
    MirageWardrobeCore.gameplayAccessSquare = currentSquare
    MirageWardrobeCore.markGameplayAccessDirty(
            MirageWardrobeCore.GAMEPLAY_MOVEMENT_SETTLE_TICKS)
    return true
end

MirageWardrobeCore.markGameplayAccessDirty = function (delay)
    local rules = getActiveGameplayAccessRules()
    if not gameplayRulesUseDynamicAccess(rules) then return false end

    local requestedDelay = type(delay) == "number" and
            math.max(0, math.floor(delay)) or 0
    local currentDelay = MirageWardrobeCore.gameplayAccessDirtyDelay or 0
    MirageWardrobeCore.gameplayAccessDirty = true
    if requestedDelay > currentDelay then
        MirageWardrobeCore.gameplayAccessDirtyDelay = requestedDelay
    end
    return true
end

MirageWardrobeCore.installGameplayAccessTransferBoundary = function ()
    local transferClass = ISInventoryTransferAction
    if not transferClass or
            transferClass.mirageWardrobeAccessRefreshInstalled then
        return transferClass ~= nil
    end
    local originalPerform = transferClass.perform
    if type(originalPerform) ~= "function" then return false end

    transferClass.perform = function (self, ...)
        local result = originalPerform(self, ...)
        local localPlayer = getPlayer and getPlayer() or nil
        if self and localPlayer and self.character == localPlayer then
            MirageWardrobeCore.markGameplayAccessDirty(1)
        end
        return result
    end
    transferClass.mirageWardrobeAccessRefreshInstalled = true
    return true
end

MirageWardrobeCore.onWardrobeClothingUpdated = function (player)
    player = player or getPlayer()
    if not player then return end
    -- resetModel() raises OnClothingUpdated while our detached WornItems are
    -- installed. Treat that callback as an internal implementation detail;
    -- queuing from it creates a self-sustaining reset/capture loop.
    if MirageWardrobeCore.appearanceCapturePlayers[player] then return end

    MirageWardrobeCore.markAppearanceChanged(player)
    if player == getPlayer() then
        MirageWardrobeCore.markGameplayAccessDirty(1)
    end

    -- setWornItem() queues ModelManager.ResetNextFrame before the first Lua
    -- clothing event. Never capture synchronously in that callback: the queued
    -- work runs from OnPostFloorLayerDraw after ModelManager has consumed
    -- ResetNextFrame and before character models are submitted. A zero delay
    -- repairs the final native model in the same rendered frame; adding another
    -- settle tick exposes one frame of the physical outfit.
    repairPersistentVisualOverrides(player)
    if player == getPlayer() and isClient() then
        local wornVisualSlots = makeWornVisualSlots(player)
        local signature = getWornVisualSlotSignature(wornVisualSlots)
        if signature ~= MirageWardrobeCore.lastPublishedWornVisualSlotSignature then
            MirageWardrobeCore.publishAppearanceState(false)
        end
    end
    if MirageWardrobeCore.shouldTrackAppearance(player) then
        MirageWardrobeCore.queueCleanAppearanceRefresh(player,
                0,
                MirageWardrobeCore.isCleanAppearanceEnabled(player), true)
    end
end

MirageWardrobeCore.onGameplayPlayerUpdate = function (player)
    local localPlayer = getPlayer()
    if not localPlayer or (player and player ~= localPlayer) then return end

    MirageWardrobeCore.gameplayAccessUpdateTick =
            (MirageWardrobeCore.gameplayAccessUpdateTick or 0) + 1
    -- Build 42 multiplayer does not dispatch OnPlayerMove for the local client.
    -- This pointer comparison keeps nearby access correct without scanning.
    detectGameplaySquareChange(localPlayer)

    -- Inventory/container events coalesce into one rebuild after activity
    -- settles. Stable frames perform no scan and keep snapshot identity, so an
    -- open 8k-entry wardrobe never receives spurious full-directory refreshes.
    if not MirageWardrobeCore.gameplayAccessDirty then return end
    local delay = MirageWardrobeCore.gameplayAccessDirtyDelay or 0
    if delay > 0 then
        MirageWardrobeCore.gameplayAccessDirtyDelay = delay - 1
        return
    end
    local rules = getActiveGameplayAccessRules()
    local lastRefresh = MirageWardrobeCore.gameplayAccessLastRefreshTick
    if MirageWardrobeCore.gameplayAccessSnapshot and
            gameplayRulesUseNearby(rules) and type(lastRefresh) == "number" then
        local elapsed = MirageWardrobeCore.gameplayAccessUpdateTick - lastRefresh
        if elapsed < MirageWardrobeCore.GAMEPLAY_NEARBY_REFRESH_COOLDOWN_TICKS then
            return
        end
    end
    MirageWardrobeCore.refreshGameplayState(localPlayer, false)
end

MirageWardrobeCore.onGameplayContainerUpdate = function ()
    if not gameplayRulesUseDynamicAccess(getActiveGameplayAccessRules()) then return end
    -- Container events can arrive continuously while driving. Rebuild once
    -- after they stop. Nearby world scans also have a hard refresh ceiling;
    -- collection/held modes retain this event for direct mod inventory edits.
    MirageWardrobeCore.markGameplayAccessDirty(2)
end

MirageWardrobeCore.onGameplayPlayerMove = function (player)
    local localPlayer = getPlayer and getPlayer() or nil
    player = player or localPlayer
    if not localPlayer or player ~= localPlayer then return end

    -- Walking leaves enough time to refresh shortly after each crossed square.
    -- Faster continuous movement keeps extending this short settle window, so
    -- nearby mode never turns a vehicle trip into a full world scan per tile.
    detectGameplaySquareChange(localPlayer)
end

local function beginNetworkAppearanceRenderBridges(localPlayer, requestedPlayers)
    if not (isClient and isClient()) then return end
    local bindings = MirageWardrobeCore.networkAppliedBindings or {}
    local states = MirageWardrobeCore.networkPlayerData or {}
    for playerKey, binding in pairs(bindings) do
        local player = type(binding) == "table" and binding.player or nil
        local state = states[playerKey]
        local identityReady = player and player ~= localPlayer and
                type(state) == "table" and binding.state == state
        local tracksAppearance = identityReady and
                MirageWardrobeCore.shouldTrackAppearance(player, state) == true
        local hasPending = identityReady and
                MirageWardrobeCore.cleanAppearancePending[player] ~= nil
        local wasRequested = identityReady and requestedPlayers and
                requestedPlayers[player] == true
        if identityReady and (tracksAppearance or hasPending or wasRequested) then
            -- SyncVisuals mutates remote ItemVisual wear in place and only
            -- schedules the native model reset; it does not necessarily emit
            -- OnClothingUpdated. Compare the physical wear signature while
            -- the real WornItems are restored, and invalidate one stale
            -- detached snapshot only when blood, dirt, holes, or patches
            -- actually changed. This is intentionally a small bound-state
            -- check, not a model capture or an online-player scan.
            local wearSignature = getPhysicalWearSignature(player)
            if wearSignature then
                local knownSignature =
                        MirageWardrobeCore.appearanceWearSignatures[player]
                if knownSignature and knownSignature ~= wearSignature then
                    MirageWardrobeCore.activeAppearanceSnapshots[player] = nil
                    MirageWardrobeCore.appearanceSnapshotFailures[player] = nil
                end
                MirageWardrobeCore.appearanceWearSignatures[player] = wearSignature
            end
            -- Keep synchronized remote snapshots in the render-only window for
            -- every native model rebuild. Iterate only bound state here; online
            -- player discovery belongs to the periodic compatibility scanner.
            MirageWardrobeCore.beginAppearanceRenderBridge(player)
        end
    end
end

MirageWardrobeCore.onAppearanceBeforeModelUpdate = function ()
    -- IngameState runs world simulation, timed actions, combat, and damage
    -- before OnTick, then ModelManager.update() afterwards.  Restore any bridge
    -- left by an aborted render, process explicit appearance changes against
    -- physical equipment, and install the cached snapshot only for the native
    -- model-update/world-render window.
    MirageWardrobeCore.endAppearanceRenderBridges()
    MirageWardrobeCore.cleanAppearancePreCharacterRenderSeen = false
    local localPlayer = getPlayer and getPlayer() or nil
    local remoteRenderRequests = nil
    for pendingPlayer in pairs(MirageWardrobeCore.cleanAppearancePending or {}) do
        if pendingPlayer ~= localPlayer and
                hasCurrentNetworkBinding(pendingPlayer) then
            remoteRenderRequests = remoteRenderRequests or {}
            remoteRenderRequests[pendingPlayer] = true
        end
    end
    MirageWardrobeCore.onCleanAppearanceTick()
    if localPlayer then
        MirageWardrobeCore.beginAppearanceRenderBridge(localPlayer)
    end
    beginNetworkAppearanceRenderBridges(localPlayer, remoteRenderRequests)
end

MirageWardrobeCore.onPreCharacterRender = function ()
    if MirageWardrobeCore.cleanAppearancePreCharacterRenderSeen then return end
    MirageWardrobeCore.cleanAppearancePreCharacterRenderSeen = true
    -- Optional legacy-render hook.  Build 42.19's default FBO chunk renderer
    -- does not dispatch this event, so the normal bridge is already open from
    -- OnTick.  Keep this only as a compatibility fallback.
    local localPlayer = getPlayer and getPlayer() or nil
    if localPlayer then
        if not MirageWardrobeCore.appearanceRenderBridges[localPlayer] then
            MirageWardrobeCore.beginAppearanceRenderBridge(localPlayer)
        end
    end
end

MirageWardrobeCore.onAppearancePostWorldRender = function ()
    -- IngameState fires OnPostRender immediately after IsoWorld.render() and
    -- before UIManager.render().  Character render data and texture creators
    -- have already retained the detached references, so gameplay-facing
    -- WornItems/body/attachments can be restored here without changing the
    -- submitted world frame.
    local localPlayer = getPlayer and getPlayer() or nil
    MirageWardrobeCore.endAppearanceRenderBridges()
end

MirageWardrobeCore.onAppearancePreUIDraw = function ()
    -- Secondary cleanup boundary for render paths that skip OnPostRender.
    -- All vanilla UI elements therefore read physical equipment and defense.
    MirageWardrobeCore.endAppearanceRenderBridges()
    local localPlayer = getPlayer and getPlayer() or nil
end

MirageWardrobeCore.onAppearanceRenderTick = function ()
    -- Final compatibility cleanup after all rendering.  The normal B42 path
    -- has already restored at OnPostRender, before UI drawing.
    MirageWardrobeCore.endAppearanceRenderBridges()
    MirageWardrobeCore.cleanAppearancePreCharacterRenderSeen = false
end

MirageWardrobeCore.onAppearanceLogicTick = function ()
    -- Compatibility for builds without OnRenderTick.
    MirageWardrobeCore.endAppearanceRenderBridges()
    MirageWardrobeCore.cleanAppearancePreCharacterRenderSeen = false
end

local function prepareAppearanceForSave()
    local restored, bridgeCount =
            MirageWardrobeCore.endAppearanceRenderBridges()
    MirageWardrobeCore.cleanAppearancePreCharacterRenderSeen = false
    -- B42 serializes characters before OnSave. Preview state therefore lives
    -- only in the runtime transaction and Player ModData already contains the
    -- committed baseline; saving must not pause or rewrite the preview.
    return restored, bridgeCount
end

local function clearWardrobeRuntimeSession()
    local restored, bridgeCount =
            MirageWardrobeCore.endAppearanceRenderBridges()

    MirageWardrobeCore.networkRevision = 0
    MirageWardrobeCore.networkPlayerData = {}
    MirageWardrobeCore.networkPlayerRevisions = {}
    MirageWardrobeCore.networkPlayerStateSources = {}
    MirageWardrobeCore.networkSessionId = nil
    MirageWardrobeCore.networkUpdateSequence = 0
    MirageWardrobeCore.outfitPresetUpdateSequence = 0
    MirageWardrobeCore.localMutationGeneration = 0
    MirageWardrobeCore.outfitPresetMutationGeneration = 0
    MirageWardrobeCore.networkSnapshotPending = false
    MirageWardrobeCore.networkSnapshotRequestGeneration = 0
    MirageWardrobeCore.networkPresetSnapshotRequestGeneration = 0
    MirageWardrobeCore.networkSnapshotRequestAttempts = 0
    MirageWardrobeCore.networkSnapshotRetryUpdates = 0
    MirageWardrobeCore.networkSnapshotRequestId = 0
    MirageWardrobeCore.networkSnapshotCompletedRequestId = nil
    MirageWardrobeCore.networkAuthenticatedPlayerKey = nil
    MirageWardrobeCore.networkSessionInitialized = false
    MirageWardrobeCore.networkAppliedBindings = {}
    MirageWardrobeCore.networkAppliedBindingSessionKnown = false
    MirageWardrobeCore.networkAppliedBindingSessionId = nil
    MirageWardrobeCore.networkGameplayRules = nil
    MirageWardrobeCore.networkGameplayRulesRevision = 0
    MirageWardrobeCore.networkGameplayCollection = nil
    MirageWardrobeCore.networkGameplayCollectionRevision = 0
    MirageWardrobeCore.gameplayAccessSnapshot = nil
    MirageWardrobeCore.gameplayAccessDirty = false
    MirageWardrobeCore.gameplayAccessDirtyDelay = 0
    MirageWardrobeCore.gameplayAccessRevision = 0
    MirageWardrobeCore.gameplayAccessSquare = nil
    MirageWardrobeCore.gameplayAccessUpdateTick = 0
    MirageWardrobeCore.gameplayAccessLastRefreshTick = nil
    MirageWardrobeCore.gameplayDiscoveryPending = false
    MirageWardrobeCore.lastGameplayDenial = nil
    MirageWardrobeCore.serverOutfitPresetLibrary = {}
    MirageWardrobeCore.cleanAppearancePending = {}
    MirageWardrobeCore.cleanAppearanceRendered = {}
    MirageWardrobeCore.appearanceWearSignatures = {}
    MirageWardrobeCore.appearanceRevisions = {}
    MirageWardrobeCore.fixedTextureTrackingCache = {}
    MirageWardrobeCore.renderCompatibilityCache = {}
    MirageWardrobeCore.compatibilityWarnings = {}
    MirageWardrobeCore.cleanAppearanceTickCounter = 0
    MirageWardrobeCore.cleanAppearancePreCharacterRenderSeen = false
    MirageWardrobeCore.isCapturingCleanAppearance = false
    MirageWardrobeCore.appearanceCapturePlayers = {}
    MirageWardrobeCore.appearancePreviewTransactions = {}
    MirageWardrobeCore.activeAppearanceSnapshots = {}
    MirageWardrobeCore.appearanceRenderBridges = {}
    MirageWardrobeCore.appearanceSnapshotFailures = {}
    MirageWardrobeCore.lastPublishedWornVisualSlotSignature = nil

    return restored, bridgeCount
end

MirageWardrobeCore.onWardrobeSave = function ()
    return prepareAppearanceForSave()
end

MirageWardrobeCore.onWardrobePostSave = function ()
    return clearWardrobeRuntimeSession()
end

MirageWardrobeCore.onWardrobeDisconnect = function ()
    return clearWardrobeRuntimeSession()
end

MirageWardrobeCore.onWardrobeMainMenuEnter = function ()
    return clearWardrobeRuntimeSession()
end

MirageWardrobeCore.onWardrobeGameStart = function ()
    MirageWardrobeCore.installMoveableGameplayReadBoundary()
    MirageWardrobeCore.installInventoryPagePhysicalReadBoundary()
    MirageWardrobeCore.installGameplayAccessTransferBoundary()
    MirageWardrobeCore.beginNetworkSession()
    local player = getPlayer()
    if not isClient() then
        MirageWardrobeCore.refreshGameplayState(player, true)
    end
    MirageWardrobeCore.applyWardrobeAppearance(player)
    if isClient() then
        MirageWardrobeCore.requestAppearanceSnapshot()
    end
end

MirageWardrobeCore.installGameplayAccessTransferBoundary()
MirageWardrobeCore.installInventoryPagePhysicalReadBoundary()
Events.OnClothingUpdated.Add(MirageWardrobeCore.onWardrobeClothingUpdated)
Events.OnGameStart.Add(MirageWardrobeCore.onWardrobeGameStart)
-- B42 world appearance bridge (including the default FBO chunk renderer):
--   IsoWorld.update         gameplay/combat reads physical equipment
--   OnTick                  install detached appearance after simulation
--   ModelManager.update     native resets rebuild from the detached snapshot
--   IsoGameCharacter.render consume texture jobs and submit the world model
--   OnPostRender            restore before every UI draw/defense reader
-- OnPostFloorLayerDraw is only a legacy-render compatibility fallback because
-- the FBO path does not dispatch the Terrain.RenderTiles.Lua event.
local hasPreCharacterRenderHook =
        Events.OnPostFloorLayerDraw and Events.OnPostFloorLayerDraw.Add
if hasPreCharacterRenderHook then
    Events.OnPostFloorLayerDraw.Add(MirageWardrobeCore.onPreCharacterRender)
end
if Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(MirageWardrobeCore.onAppearanceBeforeModelUpdate)
end
if Events.OnPostRender and Events.OnPostRender.Add then
    Events.OnPostRender.Add(MirageWardrobeCore.onAppearancePostWorldRender)
end
if Events.OnPreUIDraw and Events.OnPreUIDraw.Add then
    Events.OnPreUIDraw.Add(MirageWardrobeCore.onAppearancePreUIDraw)
end
if Events.OnRenderTick and Events.OnRenderTick.Add then
    Events.OnRenderTick.Add(MirageWardrobeCore.onAppearanceRenderTick)
elseif hasPreCharacterRenderHook and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(MirageWardrobeCore.onAppearanceLogicTick)
elseif Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(MirageWardrobeCore.onCleanAppearanceTick)
end
if Events.OnPlayerUpdate and Events.OnPlayerUpdate.Add then
    Events.OnPlayerUpdate.Add(MirageWardrobeCore.onNetworkSnapshotPlayerUpdate)
    Events.OnPlayerUpdate.Add(MirageWardrobeCore.onGameplayPlayerUpdate)
end
if Events.OnContainerUpdate and Events.OnContainerUpdate.Add then
    Events.OnContainerUpdate.Add(MirageWardrobeCore.onGameplayContainerUpdate)
end
if Events.OnPlayerMove and Events.OnPlayerMove.Add then
    Events.OnPlayerMove.Add(MirageWardrobeCore.onGameplayPlayerMove)
end
if Events.OnSave and Events.OnSave.Add then
    Events.OnSave.Add(MirageWardrobeCore.onWardrobeSave)
end
if Events.OnPostSave and Events.OnPostSave.Add then
    Events.OnPostSave.Add(MirageWardrobeCore.onWardrobePostSave)
end
if Events.OnDisconnect and Events.OnDisconnect.Add then
    Events.OnDisconnect.Add(MirageWardrobeCore.onWardrobeDisconnect)
end
if Events.OnMainMenuEnter and Events.OnMainMenuEnter.Add then
    Events.OnMainMenuEnter.Add(MirageWardrobeCore.onWardrobeMainMenuEnter)
end
Events.OnEquipPrimary.Add(MirageWardrobeCore.onEquipHandItem)
Events.OnEquipSecondary.Add(MirageWardrobeCore.onEquipHandItem)
