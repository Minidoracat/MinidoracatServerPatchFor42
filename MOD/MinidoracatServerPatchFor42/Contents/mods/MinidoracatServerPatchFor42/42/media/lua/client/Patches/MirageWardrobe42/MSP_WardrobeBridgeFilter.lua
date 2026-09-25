--[[
MSP_WardrobeBridgeFilter — Mirage Wardrobe 每個 tick 對「全部」綁定的遠端玩家重算穿戴簽章

【上游】幻装衣橱：联机幻化 / Mirage Wardrobe [B42]（Workshop 3770186452，mod id MirageWardrobe42，
核對版本為 upstream.json 的 acked_time_updated）。upstream.json 有登記，Workshop 更新時 Action 會開 issue。

【缺陷】
`MirageWardrobeCore.lua:7809` 把 `onAppearanceBeforeModelUpdate`（:7623）掛在 OnTick。它最後呼叫
local `beginNetworkAppearanceRenderBridges`（:7582），遍歷 `MirageWardrobeCore.networkAppliedBindings`
的每一位遠端玩家，對通過 :7597 閘門者呼叫 `getPhysicalWearSignature`（:4500）：每件 ItemVisual ×
18 個身體部位 × 6 個 getter，每次讀取包兩個 pcall 再 tostring，最後 table.concat。沒有距離判斷、
沒有節流。一般玩家客戶端的遠端玩家會衰減成附近的人，但 staff／admin 客戶端會收到全服玩家
（PlayerPacket 的角色位階旁路），成本隨在線人數線性成長。
2026-09-25 E2E（admin 帳號、正式服 17 人、非 debug）：這個 callback 佔主執行緒 68.9%，
遊戲內 FPS 36–42／CPU Time 31ms；RTX 4090 使用率 18%。
2026-08-16 已在 Workshop 討論區回報（附行號與三種修法），至今沒有回覆，之後的上游更新也沒修這段。

【修法】
移除原本的 OnTick 註冊，改掛包裝函式。每次呼叫原版前，把 `networkAppliedBindings` 暫時換成
「在本機已載入格子上、且距本機玩家 ≤ RANGE 格」的子集，呼叫完立刻換回完整表。子集外的玩家
不會被畫出來，也就不需要塑形橋接與簽章比對；走進範圍的下一個 tick 就會被納入，
簽章與上次不同時照原版邏輯讓快照失效，外觀一樣正確。
- 原版在呼叫中若改寫了子集（新增、移除、換 binding），寫回完整表；若整張表被換掉
  （session 重置），不還原舊表。
- 原版拋錯時仍先還原完整表，再原樣重拋，不吞例外。
- 篩選本身出錯、非 MP 客戶端、沒有本機玩家時，直接走原版，行為與未安裝相同。
被篩掉的玩家在 `onCleanAppearanceTick` 的 `hasCurrentNetworkBinding` 會回 false，但下一段
會改查線上玩家清單，結果一樣是「追蹤中」，行為不變。

【為什麼不改上游】
他人的 Workshop MOD，本服不重新發布；作者未回應回報。只在本服客戶端篩掉畫面外的玩家，
不改塑形資料、網路協定或存檔。

【軟依賴】
不 require MirageWardrobe42。載入時沒有 `MirageWardrobeCore` 就什麼都不做；為避免檔案載入順序
早於上游，另掛 `OnGameBoot` 再試一次（冪等）。上游在但形狀不符（函式或 OnTick API 不在）時，
印一行 NOT installed 後放棄，不猜。

【上游更新時要重核】
`onAppearanceBeforeModelUpdate` 是否仍掛在 OnTick 且仍經 `networkAppliedBindings` 遍歷遠端玩家；
`beginNetworkAppearanceRenderBridges` 是否已自己加距離判斷或節流（有的話本補丁退場）；
tick 路徑內是否開始寫入 `networkAppliedBindings`（目前只有 MirageWardrobeNetwork.lua 的計分板與
網路 handler 會寫）。
]]

local PREFIX = "[MinidoracatServerPatchFor42][MirageWardrobe42]"
local RANGE = 100 -- 格；大於客戶端 chunk 串流半徑（寬 19 chunk ≈ 76 格），畫面內的人都在範圍內
local RANGE2 = RANGE * RANGE

-- 回傳子集；本機玩家不存在時回 nil（不篩選）
local function nearbySubset(full, localPlayer)
    if not localPlayer then return nil end
    local lx, ly = localPlayer:getX(), localPlayer:getY()
    local subset = {}
    for key, binding in pairs(full) do
        local player = type(binding) == "table" and binding.player or nil
        local keep = true -- 無效 binding 交給原版自己的閘門判斷
        if player then
            keep = false
            if player:getCurrentSquare() then
                local dx, dy = player:getX() - lx, player:getY() - ly
                keep = dx * dx + dy * dy <= RANGE2
            end
        end
        if keep then subset[key] = binding end
    end
    return subset
end

local function copy(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end

local function makeWrapper(core, original)
    return function()
        local full = core.networkAppliedBindings
        if not (isClient and isClient()) or type(full) ~= "table" then
            return original()
        end
        local ok, subset = pcall(nearbySubset, full, getPlayer and getPlayer() or nil)
        if not ok or not subset then
            return original()
        end
        local before = copy(subset)
        core.networkAppliedBindings = subset
        local called, err = pcall(original)
        if core.networkAppliedBindings == subset then
            core.networkAppliedBindings = full
            for key, value in pairs(before) do
                if subset[key] ~= value then full[key] = subset[key] end
            end
            for key, value in pairs(subset) do
                if before[key] == nil then full[key] = value end
            end
        end
        if not called then error(err, 0) end
    end
end

local installed, warned = false, false
local function install()
    if installed then return end
    local core = MirageWardrobeCore
    if type(core) ~= "table" then return end -- 上游缺席：零行為
    local original = core.onAppearanceBeforeModelUpdate
    local onTick = Events and Events.OnTick
    if type(original) ~= "function" or type(onTick) ~= "table" or
            type(onTick.Add) ~= "function" or type(onTick.Remove) ~= "function" then
        if not warned then
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
    print(PREFIX .. " bridge filter installed (range=" .. RANGE .. ")")
end

install()
if not installed and Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(install)
end

-- 離線測試用（scripts/test_wardrobe_bridge_filter.lua）；遊戲內不會有人引用
MSP_WardrobeBridgeFilter = { install = install, nearbySubset = nearbySubset, RANGE = RANGE }
