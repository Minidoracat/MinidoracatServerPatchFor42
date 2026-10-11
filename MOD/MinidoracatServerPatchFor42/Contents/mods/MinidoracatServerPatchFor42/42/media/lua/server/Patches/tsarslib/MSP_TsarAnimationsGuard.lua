--[[
MSP_TsarAnimationsGuard — Tsar's Common Library 的全域 ModData「tsaranimations」伺服器端不檢查內容

【上游】Tsar's Common Library（Workshop 3402491515，mod id tsarslib，核對版本 3.31）：
common/media/lua/server/Animations/AMC_ModData.lua、common/media/lua/client/tsarlibModDataRequest.lua。
upstream.json 有登記，Workshop 更新時 Action 會開 issue。

【缺陷】
這張表記哪些玩家要套機車動畫：鍵＝玩家 onlineID、值＝true。寫入端是依賴 tsarslib 的機車 MOD（例：Autotsar
Motorclub，Workshop 3404737883）的客戶端，改自己那一項後整張 ModData.transmit。伺服器端 AMC_ModData.lua:9-30
收到就 `ModData.add` 整張取代（GlobalModData.java:108-110），不檢查內容；引擎對這個封包只要求連線已登入
（GlobalModDataPacket.java:16-22、45-55）。tsarlibModDataRequest.lua:1-15 讓每個客戶端每 100 tick 要一次表，
伺服器每次整張回傳（GlobalModData.java:171-205），表也隨世界存檔。所以表裡一旦有「在線玩家 ID＝true」以外的
內容（非整數鍵、巢狀表、離線或不存在的 ID），就會一直留在存檔裡、反覆送給每個客戶端；上游每小時的清理
（AMC_ModData.lua:36-47）只移除值為真、又查不到玩家的項目。

【修法】
1. 開服時（OnInitGlobalModData；GlobalModData.java:51-55 讀完存檔才觸發）清空存檔裡的舊項目：onlineID 每次連線
   重新分配，開服時沒有玩家在線，舊項目都已失效，等於把上游每小時的清理提早做。
2. 在同一個回呼裡註冊 OnReceiveGlobalModData 處理器。上游在檔案載入時就註冊，OnInitGlobalModData 一定在 Lua
   全部載入之後，所以這個處理器排在上游之後，不受 Mods= 與檔案載入順序影響（同一事件依註冊順序呼叫，
   Event.java:52-56、98）。收到 tsaranimations 時上游已把表換成收到的那張，這裡就地刪掉不是「整數 onlineID＝true、
   且該玩家在線」（LuaManager.java:3940-3942）的項目，表的大小因此不超過在線人數。有刪除時印一行計數，每分鐘最多一行。
在線玩家的 ID＝true 原樣保留；離線玩家的項目提早移除（原版要等每小時的清理）。

【為什麼不改上游】
上游是多個車輛 MOD 共用的函式庫，本服不重新發布他人 MOD；只限制表的內容，不改它的同步方式。

【軟依賴】不 require 上游。`getActivatedMods()` 沒有 tsarslib 就直接 return，不註冊任何事件。只在 isServer() 生效。

【上游更新時要重核】AMC_ModData.lua 是否仍在 OnReceiveGlobalModData 以 ModData.add 整張取代、表的鍵值語意
（onlineID＝true）與請求週期；上游自己檢查內容或改成伺服器端維護時，本補丁退場。寫入端在其他 MOD：
日後裝了寫入這張表的 MOD，先確認它寫的仍是自己的 onlineID＝true，否則會被這裡刪掉。
]]

local MOD_ID = "tsarslib"
local TAG = "tsaranimations"
local PREFIX = "[MinidoracatServerPatchFor42][tsarslib]"

local mods = getActivatedMods()
if not isServer() or not (mods:contains(MOD_ID) or mods:contains("\\" .. MOD_ID)) then return end

-- 就地刪掉 keep(k, v) 不成立的項目，回傳刪除數與保留數；先收集再刪，不在 pairs 走訪中改表
local function prune(t, keep)
    local drop, kept = {}, 0
    for k, v in pairs(t) do
        if keep(k, v) then kept = kept + 1 else drop[#drop + 1] = k end
    end
    for i = 1, #drop do t[drop[i]] = nil end
    return #drop, kept
end

-- onlineID 是 short（LuaManager.java:3942 轉型）；型別與範圍先驗過，才交給 getPlayerByOnlineID
local function onlineEntry(k, v)
    return v == true and type(k) == "number" and k >= 0 and k <= 32767 and k == math.floor(k)
        and getPlayerByOnlineID(k) ~= nil
end

local function none() return false end

local lastReport, suppressed = nil, 0
local function onReceive(module)
    if module ~= TAG then return end
    local t = ModData.get(TAG)
    if not t then return end
    local dropped, kept = prune(t, onlineEntry)
    if dropped == 0 then return end
    local now = getTimestampMs()
    if lastReport and now - lastReport < 60000 then
        suppressed = suppressed + 1
        return
    end
    print(PREFIX .. " tsaranimations: dropped " .. dropped .. " invalid or offline entries, kept " .. kept
        .. " (" .. suppressed .. " similar reports suppressed)")
    lastReport, suppressed = now, 0
end

Events.OnInitGlobalModData.Add(function()
    local t = ModData.get(TAG)
    local cleared = t and prune(t, none) or 0
    Events.OnReceiveGlobalModData.Add(onReceive)
    print(PREFIX .. " tsaranimations guard installed (cleared " .. cleared .. " saved entries)")
end)
