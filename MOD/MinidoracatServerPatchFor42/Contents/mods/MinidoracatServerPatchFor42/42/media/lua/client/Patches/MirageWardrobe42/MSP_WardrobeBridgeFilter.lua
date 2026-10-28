--[[
MSP_WardrobeBridgeFilter — Mirage Wardrobe 每個 tick 對綁定的遠端玩家重算穿戴簽章

【上游】幻装衣橱：联机幻化 / Mirage Wardrobe [B42]（Workshop 3770186452，mod id MirageWardrobe42，
核對版本為 upstream.json 的 acked_time_updated）。upstream.json 有登記，Workshop 更新時 Action 會開 issue。

【缺陷】
`MirageWardrobeCore.lua:7809` 把 `onAppearanceBeforeModelUpdate`（:7623）掛在 OnTick。它最後呼叫
local `beginNetworkAppearanceRenderBridges`（:7582），遍歷 `MirageWardrobeCore.networkAppliedBindings`
的每一位遠端玩家，對通過 :7597 閘門者先呼叫 `getPhysicalWearSignature`（:4500），再 `beginAppearanceRenderBridge`。
簽章是每件 ItemVisual × 18 個身體部位 × 6 個 getter，每次讀取包兩個 pcall 再 tostring，最後 table.concat。
沒有距離判斷、沒有節流，成本＝綁定的人數 × 每人每 tick 一次。staff／admin 客戶端會收到全服玩家
（PlayerPacket 的角色位階旁路），一般客戶端在玩家聚集時一樣是十幾個人。
- 2026-09-25 E2E（admin 帳號、正式服 17 人、非 debug）：這個 callback 佔主執行緒 68.9%，FPS 36–42／CPU Time 31ms。
- 2026-10-28 正式服活動點（同畫面 13 人以上，全在範圍內）：這個 callback 佔主執行緒 75%，
  CPU Time 59ms、FPS 16–22（開 -debug 的 admin 客戶端）；Lua 取樣有 92% 落在簽章函式。
2026-08-16 已在 Workshop 討論區回報（附行號與三種修法），至今沒有回覆，之後的上游更新也沒修這段。

【修法】
移除原本的 OnTick 註冊，改掛包裝函式，做三件事：
1. 範圍：呼叫原版前把 `networkAppliedBindings` 暫時換成「在本機已載入格子上、且距本機玩家 ≤ RANGE 格」
   的子集，呼叫完換回完整表。
2. 畫面：子集再扣掉不在本機鏡頭可視範圍內的人（四邊加 VIEW_MARGIN 格緩衝；已在處理的人放寬到
   VIEW_KEEP_MARGIN 格才停，免得在邊上來回）。橋只在 OnTick 到 OnPostRender 之間開著，讓這段時間的原生模型重建
   （ModelManager.update，IngameState 在 OnTick 之後呼叫）與貼圖建立（IsoGameCharacter.render 的
   checkUpdateModelTextures）讀到幻化的衣物。畫面外的人不會被畫（FBORenderCell.renderPlayer 先看 isOnScreen），
   但遠端玩家不做 scene cull，引擎照樣重建他們的模型（動作結束、同步衣物都會排 ResetNextFrame），這時讀到的是
   實體衣物。所以走進可視範圍、第一次開成橋的那個 tick，補丁呼叫 resetModelNextFrame：同一幀稍後的
   ModelManager.update 在橋開著時重建，第一個畫出來的幀就是幻化外觀。可視範圍照 IsoGridSquare.IsOnScreen 的算法，
   用 IsoCamera 的偏移與畫面大小；鏡頭在 IsoPlayer.update 開頭更新，render 前 Core.StartFrame 又以本機玩家當下的位置
   重新置中（MultiTextureFBO2.update → PlayerCamera.center），所以另以本機玩家現在的位置置中算一次，兩個範圍任一個
   在內就處理（之後才在別的 OnTick 回呼裡傳送本機玩家時，傳送後的第一幀照不到）。
   分割畫面（每個視窗各自 render）或 API 不在時不做這一步。
   代價：每有一人走進可視範圍，多一次模型重建（原版在每次原生重建後本來就會再重拍一次）。
3. 節流：子集裡每位玩家的簽章最多每 WEAR_INTERVAL_MS 算一次。原版 `onCleanAppearanceTick()`（:7640）
   一返回，就把表再換成「這個 tick 到期的人」，原版迴圈只對他們算簽章、開橋；其餘的人在原版返回後，
   由本補丁照 :7587-7597 的閘門呼叫 `beginAppearanceRenderBridge`，所以外觀每幀照樣套上，只是不重算簽章。
   第一次看到的人把到期時間錯開到 WEAR_INTERVAL_MS 內，避免同一個 tick 一起算。
   代價：別人衣服的血跡、髒污、破洞、補丁變化，最多晚 WEAR_INTERVAL_MS 才讓舊快照失效、重畫。
- 原版在呼叫中改寫了子集或到期表（新增、移除、換 binding），寫回完整表；中途新加的 binding 當作到期。
  整張表被換掉（session 重置）時不還原舊表，也不補開橋。
- 原版拋錯時仍先還原完整表，再原樣重拋，不吞例外；這個 tick 不補開橋（和原版中途中止相同），也不重建模型。
- `onCleanAppearanceTick` 沒經 `MirageWardrobeCore` 表呼叫（上游改了形狀）時換表不會發生，原版照舊處理整個子集，
  本補丁印一行 wear throttle inactive，本次遊戲只剩範圍與畫面過濾。
- 篩選本身出錯、非 MP 客戶端、沒有本機玩家時，直接走原版，行為與未安裝相同；沒有 `getTimestampMs` 時不節流。
被篩掉的玩家在 `onCleanAppearanceTick` 的 `hasCurrentNetworkBinding` 會回 false，但下一段
會改查線上玩家清單，結果一樣是「追蹤中」，行為不變；換成到期表時 `onCleanAppearanceTick` 已經跑完。

【為什麼不改上游】
他人的 Workshop MOD，本服不重新發布；作者未回應回報。只在本服客戶端篩掉不會被畫出來的玩家、降低簽章比對頻率，
不改塑形資料、網路協定或存檔。

【軟依賴】
不 require MirageWardrobe42。載入時沒有 `MirageWardrobeCore` 就什麼都不做；為避免檔案載入順序
早於上游，另掛 `OnGameBoot` 再試一次（冪等）。上游 `shared/MirageWardrobeNetwork.lua:1` 先建好
`MirageWardrobeCore` 表，本檔早於上游 client 檔載入時函式還不在，所以形狀判定只在 `OnGameBoot`（Lua 全部載入後）
才算數：那時仍不符（函式或 OnTick API 不在）才印一行 NOT installed 後放棄，不猜。

【上游更新時要重核】
`onAppearanceBeforeModelUpdate` 是否仍掛在 OnTick、仍先以 `MirageWardrobeCore.onCleanAppearanceTick()` 呼叫，
之後才經 `networkAppliedBindings` 遍歷遠端玩家；迴圈每人是否仍只做「簽章比對＋`beginAppearanceRenderBridge`」，
閘門是否仍是 :7587-7597（本補丁照它判斷要不要替延後的人開橋）；
`beginNetworkAppearanceRenderBridges` 是否已自己加距離判斷、畫面判斷或節流（有的話本補丁退場）；
tick 路徑內是否開始寫入 `networkAppliedBindings`（目前只有 MirageWardrobeNetwork.lua 的計分板與
網路 handler 會寫）；橋是否仍只在 OnTick 到 OnPostRender 之間開著、`appearanceRenderBridges[player]` 是否仍記著
開成的橋（本補丁照它判斷走進畫面的人這個 tick 有沒有開成橋、要不要重建模型）。
]]

local PREFIX = "[MinidoracatServerPatchFor42][MirageWardrobe42]"
local RANGE = 100 -- 格；大於客戶端 chunk 串流半徑（寬 19 chunk ≈ 76 格），畫面內的人都在範圍內
local RANGE2 = RANGE * RANGE
local VIEW_MARGIN = 4 -- 格：鏡頭可視範圍外這麼近的人照常處理，走進畫面前就已開橋、重建過模型
local VIEW_KEEP_MARGIN = 8 -- 格：處理中的人離開可視範圍這麼遠才停，免得在邊上來回重建模型
local WEAR_INTERVAL_MS = 1000 -- 同一位玩家兩次簽章比對的最短間隔
local SPREAD_SLOTS = 16 -- 第一次看到的人，到期時間依序錯開 WEAR_INTERVAL_MS / SPREAD_SLOTS
local STALE_MS = 60000 -- 到期後這麼久都沒再出現在範圍內，就丟掉他的到期時間
local PRUNE_EVERY_MS = 10000

-- E2E 讀：到期（允許算簽章）的人次、替延後的人開橋的次數、範圍內但在畫面外略過的人次、走進畫面重建模型的次數
local stats = { due = 0, deferredBridges = 0, offView = 0, entryResets = 0 }
local nextDue = {} -- [IsoPlayer] = 下次可以算簽章的時間（getTimestampMs）
-- [IsoPlayer] = 上個 tick 在可視範圍內的遠端玩家：true 已開過橋，"pending" 還沒（第一次開成橋時重建模型）
local shown = {}
local spreadSlot = 0
local nextPrune = 0
local throttleOn = false
local ctx = nil -- 包裝函式呼叫原版期間的狀態
local cleanTarget = nil -- 最近一次被暫換的 onCleanAppearanceTick（不清掉：萬一有人留著 cleanHook，照樣呼叫得到原版）

-- 本機鏡頭的可視範圍（螢幕像素）：一格在螢幕 x 方向的像素（32 × tileScale）、畫面寬高、IsoCamera 的偏移、
-- 以本機玩家現在的位置置中的偏移。分割畫面（每個視窗各自 render）或 API 不在時回 nil：不做畫面過濾
local function cameraView(localPlayer)
    if not (IsoCamera and IsoUtils and getNumActivePlayers and localPlayer.resetModelNextFrame) or
            getNumActivePlayers() > 1 then
        return nil
    end
    local index = localPlayer:getPlayerNum()
    local width, height = IsoCamera.getOffscreenWidth(index), IsoCamera.getOffscreenHeight(index)
    local x, y, z = localPlayer:getX(), localPlayer:getY(), localPlayer:getZ()
    return IsoUtils.XToScreen(1, 0, 0, 0), width, height, IsoCamera.getOffX(index), IsoCamera.getOffY(index),
            IsoUtils.XToScreen(x, y, z, 0) - width / 2 + IsoCamera.getRightClickOffX(),
            IsoUtils.YToScreen(x, y, z, 0) - height / 2 + IsoCamera.getRightClickOffY()
end

-- IsoGridSquare.IsOnScreen（非樹木格）：左右各留半格、上方一格、下方一層樓高，四邊再加 pad
local function inRect(sx, sy, offX, offY, width, height, unit, pad)
    sx, sy = sx - offX, sy - offY
    return sx > -unit - pad and sx < width + unit + pad and sy > -unit - pad / 2 and sy < height + 3 * unit + pad / 2
end

-- 回傳子集與這個 tick 在可視範圍內的遠端玩家（沒有畫面過濾時是 nil）；本機玩家不存在時回 nil（不篩選）
local function nearbySubset(full, localPlayer)
    if not localPlayer then return nil end
    local lx, ly = localPlayer:getX(), localPlayer:getY()
    local unit, width, height, offX, offY, nowX, nowY = cameraView(localPlayer)
    local inView = unit and {} or nil
    local subset = {}
    for key, binding in pairs(full) do
        local player = type(binding) == "table" and binding.player or nil
        local keep = true -- 無效 binding 交給原版自己的閘門判斷
        if player then
            keep = false
            if player:getCurrentSquare() then
                local x, y = player:getX(), player:getY()
                local dx, dy = x - lx, y - ly
                keep = dx * dx + dy * dy <= RANGE2
                if keep and unit and player ~= localPlayer then
                    -- 格子座標，和 IsoGridSquare.IsOnScreen 一樣
                    x, y = math.floor(x), math.floor(y)
                    local pad = (shown[player] and VIEW_KEEP_MARGIN or VIEW_MARGIN) * unit
                    local sx = (x - y) * unit
                    local sy = ((x + y) / 2 - 3 * math.floor(player:getZ())) * unit
                    keep = inRect(sx, sy, offX, offY, width, height, unit, pad) or
                            inRect(sx, sy, nowX, nowY, width, height, unit, pad)
                    if keep then
                        inView[player] = shown[player] or "pending"
                    else
                        stats.offView = stats.offView + 1
                    end
                end
            end
        end
        if keep then subset[key] = binding end
    end
    return subset, inView
end

local function copy(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end

-- 原版改寫過的 key 寫回完整表
local function mergeBack(full, before, current)
    for key, value in pairs(before) do
        if current[key] ~= value then full[key] = current[key] end
    end
    for key, value in pairs(current) do
        if before[key] == nil then full[key] = value end
    end
end

-- 這個 tick 不算簽章的 key；回傳 key 集合與個數
local function planDeferrals(subset, localPlayer, now)
    local deferKeys, count = {}, 0
    for key, binding in pairs(subset) do
        local player = type(binding) == "table" and binding.player or nil
        if player and player ~= localPlayer then
            local due = nextDue[player]
            if due == nil then
                spreadSlot = spreadSlot % SPREAD_SLOTS + 1
                nextDue[player] = now + spreadSlot * WEAR_INTERVAL_MS / SPREAD_SLOTS
                deferKeys[key] = true
                count = count + 1
            elseif now >= due or due - now > WEAR_INTERVAL_MS then -- 後者：系統時間往回調
                nextDue[player] = now + WEAR_INTERVAL_MS
                stats.due = stats.due + 1
            else
                deferKeys[key] = true
                count = count + 1
            end
        end
    end
    if now >= nextPrune then
        for player, due in pairs(nextDue) do
            if now - due > STALE_MS then nextDue[player] = nil end
        end
        nextPrune = now + PRUNE_EVERY_MS
    end
    return deferKeys, count
end

-- onCleanAppearanceTick 返回後：表換成到期的人，延後的人另存
local function swapToDue()
    local c = ctx
    if not c or c.swapped or c.core.networkAppliedBindings ~= c.subset then return end
    local due, deferred = {}, {}
    for key, binding in pairs(c.subset) do
        if c.deferKeys[key] and c.before[key] == binding then
            deferred[key] = binding
        else
            due[key] = binding
        end
    end
    c.due, c.dueBefore, c.deferred, c.swapped = due, copy(due), deferred, true
    c.core.networkAppliedBindings = due
end

local function afterClean(...)
    swapToDue()
    return ...
end

local function cleanHook(...)
    return afterClean(cleanTarget(...))
end

-- 照原版迴圈的閘門（MirageWardrobeCore.lua:7587-7597）替延後的人開橋，只是不算簽章
local function bridgeDeferred(core, deferred, localPlayer, requested)
    local states = core.networkPlayerData or {}
    local pending = core.cleanAppearancePending or {}
    for key, binding in pairs(deferred) do
        local player = binding.player
        local state = states[key]
        if player ~= localPlayer and type(state) == "table" and binding.state == state then
            local tracks = core.shouldTrackAppearance(player, state) == true
            if tracks or pending[player] ~= nil or requested[player] then
                core.beginAppearanceRenderBridge(player)
                stats.deferredBridges = stats.deferredBridges + 1
            end
        end
    end
end

-- 剛進可視範圍的人在第一次開成橋的 tick 重建模型：IngameState 在 OnTick 之後才呼叫 ModelManager.update，
-- 這時橋還開著。不在畫面時引擎可能已用實體衣物重建過他的模型，原版要等下一輪檢查才重拍。
local function resetEntering(core, inView)
    local bridges = core.appearanceRenderBridges
    for player, state in pairs(inView) do
        if state == "pending" and type(bridges) == "table" and bridges[player] then
            player:resetModelNextFrame()
            inView[player] = true
            stats.entryResets = stats.entryResets + 1
        end
    end
    shown = inView
end

local function makeWrapper(core, original)
    return function()
        local full = core.networkAppliedBindings
        if not (isClient and isClient()) or type(full) ~= "table" then
            return original()
        end
        local localPlayer = getPlayer and getPlayer() or nil
        local ok, subset, inView = pcall(nearbySubset, full, localPlayer)
        if not ok or not subset then
            return original()
        end
        local c = { core = core, subset = subset, before = copy(subset), swapped = false }
        local hooked = false
        local clean = core.onCleanAppearanceTick
        if throttleOn and type(clean) == "function" then
            local planned, deferKeys, count = pcall(planDeferrals, subset, localPlayer, getTimestampMs())
            if planned and count > 0 then
                c.deferKeys = deferKeys
                -- 原版迴圈的 requestedPlayers（:7633-7639）在 onCleanAppearanceTick 之前取
                c.requested = {}
                for player in pairs(core.cleanAppearancePending or {}) do
                    if player ~= localPlayer then c.requested[player] = true end
                end
                cleanTarget = clean
                core.onCleanAppearanceTick = cleanHook
                hooked = true
            end
        end
        ctx = c
        core.networkAppliedBindings = subset
        local called, err = pcall(original)
        ctx = nil
        if hooked and core.onCleanAppearanceTick == cleanHook then
            core.onCleanAppearanceTick = clean
        end
        local current = core.networkAppliedBindings
        local restored = current == subset or (c.swapped and current == c.due)
        if restored then
            core.networkAppliedBindings = full
            mergeBack(full, c.before, subset)
            if c.swapped then mergeBack(full, c.dueBefore, c.due) end
        end
        if not called then error(err, 0) end
        if not restored then return end
        if c.swapped then
            bridgeDeferred(core, c.deferred, localPlayer, c.requested)
        elseif hooked then
            throttleOn = false
            print(PREFIX .. " wear throttle inactive: onCleanAppearanceTick was not called through MirageWardrobeCore; re-check upstream.json recheck notes")
        end
        if inView then resetEntering(core, inView) else shown = {} end
    end
end

local installed, warned = false, false
-- final＝OnGameBoot 那次（全部 Lua 已載入）；檔案載入時形狀不符只可能是上游 client 檔還沒跑，不印
local function install(final)
    if installed then return end
    local core = MirageWardrobeCore
    if type(core) ~= "table" then return end -- 上游缺席：零行為
    local original = core.onAppearanceBeforeModelUpdate
    local onTick = Events and Events.OnTick
    if type(original) ~= "function" or type(onTick) ~= "table" or
            type(onTick.Add) ~= "function" or type(onTick.Remove) ~= "function" then
        if final and not warned then
            warned = true
            print(PREFIX .. " NOT installed: MirageWardrobeCore shape changed; re-check upstream.json recheck notes")
        end
        return
    end
    if core.MSP_bridgeFilterWrapper == original then
        installed = true
        return
    end
    local wrapper = makeWrapper(core, original)
    onTick.Remove(original)
    onTick.Add(wrapper)
    core.MSP_bridgeFilterWrapper = wrapper
    core.onAppearanceBeforeModelUpdate = wrapper
    installed = true
    throttleOn = type(getTimestampMs) == "function"
    print(PREFIX .. " bridge filter installed (range=" .. RANGE .. ", view margin " ..
            ((IsoCamera and IsoUtils) and (VIEW_MARGIN .. "/" .. VIEW_KEEP_MARGIN) or "off: no IsoCamera") ..
            ", wear throttle " .. (throttleOn and (WEAR_INTERVAL_MS .. "ms") or "off: no getTimestampMs") .. ")")
end

install()
if not installed and Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(function() install(true) end)
end

-- 離線測試（scripts/test_wardrobe_bridge_filter.lua）與 E2E 讀；遊戲內不會有人引用
MSP_WardrobeBridgeFilter = {
    install = install, nearbySubset = nearbySubset, RANGE = RANGE, VIEW_MARGIN = VIEW_MARGIN,
    VIEW_KEEP_MARGIN = VIEW_KEEP_MARGIN, WEAR_INTERVAL_MS = WEAR_INTERVAL_MS, stats = stats,
}
