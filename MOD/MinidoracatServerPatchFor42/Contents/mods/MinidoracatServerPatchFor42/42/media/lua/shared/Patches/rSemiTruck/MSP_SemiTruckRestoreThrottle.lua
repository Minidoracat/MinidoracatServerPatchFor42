--[[
MSP_SemiTruckRestoreThrottle — rSemiTruck「載入後修復」回呼：沒載入過汽車運輸拖車就每遊戲分鐘全掃一次所有車輛

【上游】W900 Semi-Truck [B42]（Workshop 3409472393，mod id rSemiTruck，核對版本 1.88；檔案在 `common/`）。upstream.json 有登記。

【缺陷】（行號為上游 common/media/lua/server/MSW_Common_Commands.lua）
`MSW_RestoreContainerCapacitiesOnLoad`（:2522-2573，:2574 掛 EveryOneMinute）註解寫「載入後清一次」，但要
`mswCapacityRestored` 與 `mswCoverPartsRestored` 都為真才提前結束（:2523）；後者只在某台已載入的車有 `ATAMultiSlotWrecker`
與 `MSWCarCover1`（:2535-2536），且 `syncCartrailerCoverParts` 回 true（五個 MSWCarCover 零件都在，:1348-1389）時才設。
整個 session 沒載入過汽車運輸拖車時，它每遊戲分鐘走訪全部已載入車輛（`getCell():getVehicles()`，:165-227）的每個零件
（`getPartCount`／`getPartByIndex`／`getModData`，:2542-2560）。本服一天 1 小時，每遊戲分鐘＝2.5 秒；2026-09-29 正式服
取樣這個回呼佔主執行緒 0.70%（約每次 17 ms）；前一個已載入過汽車拖車的 session 則是零樣本。

【修法】只在伺服器生效。
- 掛點：攔截上游的事件註冊。本檔放 shared/，專用伺服器先載入全部 MOD 的 shared/ 再載入 server/（`GameServer.java:1469-1471`），
  所以一定早於 MSW_Common_Commands.lua。暫換 `Events.EveryOneMinute.Add`（`Events.X` 是一般 Lua 表，`Event.java:78-83`），
  以 `getFilenameOfClosure`（`LuaManager.java:7341-7347`）認出該檔傳進來的函式。該檔依序註冊兩個 EveryOneMinute 回呼
  （:2510 舊存檔搬移、:2574 本回呼），把第二個換成節流版再交給引擎，其他一律原樣轉交。`OnGameBoot`（Lua 全部載入且沙盒已讀入後，
  `GameServer.java:1481-1496`）換回 `Add`，確認該檔恰好註冊兩個才啟用。
- 節流：上游回呼第一次照常執行，之後每 30 個遊戲分鐘（本服 75 秒）才執行一次。執行的仍是上游函式，照原本的條件在找到汽車拖車後
  自行停下；差別只在「之後才載入的汽車拖車」要等下一次（最多 30 個遊戲分鐘）才補上車罩同步與舊容量鍵清理。汽車拖車的裝卸指令
  本身會同步車罩（:2326、:2428），不受影響。舊存檔搬移那個回呼不動。

【為什麼不改上游】他人的 Workshop MOD，本服不重新發布；已在上游 Workshop 討論區回報並附一行修法，作者修好後本補丁即可退場。

【軟依賴】不 require 上游。`getActivatedMods()` 沒有 rSemiTruck 就直接 return，不碰任何事件。`OnGameBoot` 時該檔的
EveryOneMinute 註冊數不是 2（上游改檔名、改註冊方式或增減回呼）就印一行 NOT installed，節流版原樣轉交。

【開關】沙盒 `MinidoracatServerPatchFor42.SlimSemiTruckRestore`（預設開；關掉＝上游原樣，重啟生效）。

【上游更新時要重核】見 upstream.json 的 recheck。
]]

local PREFIX = "[MinidoracatServerPatchFor42][rSemiTruck]"
local MOD_ID = "rSemiTruck"
local UPSTREAM_FILE = "/lua/server/msw_common_commands.lua"
local EVERY_MINUTES = 30

local mods = getActivatedMods()
if not isServer() or not (mods:contains(MOD_ID) or mods:contains("\\" .. MOD_ID)) then return end
if MSP_SemiTruckRestoreThrottle then return end -- 已裝過，不疊
MSP_SemiTruckRestoreThrottle = true

local event = Events.EveryOneMinute
local engineAdd = event.Add
local registered = 0 -- 上游檔註冊的 EveryOneMinute 回呼數
local restoreLine
local active = false

local function throttle(upstream)
    local skip = 0
    return function(...)
        if active then
            if skip > 0 then
                skip = skip - 1
                return
            end
            skip = EVERY_MINUTES - 1
        end
        return upstream(...)
    end
end

local function add(fn)
    if type(fn) == "function" then
        local ok, file = pcall(getFilenameOfClosure, fn)
        if ok and type(file) == "string" and string.find(string.lower(file), UPSTREAM_FILE, 1, true) then
            registered = registered + 1
            if registered == 2 then
                local okLine, line = pcall(getFirstLineOfClosure, fn)
                restoreLine = okLine and line or nil
                fn = throttle(fn)
            end
        end
    end
    return engineAdd(fn)
end
event.Add = add

Events.OnGameBoot.Add(function()
    if event.Add == add then event.Add = engineAdd end
    local options = SandboxVars and SandboxVars.MinidoracatServerPatchFor42
    if options and options.SlimSemiTruckRestore == false then
        print(PREFIX .. " restore throttle disabled by sandbox option; upstream unchanged")
        return
    end
    if registered ~= 2 then
        print(PREFIX .. " restore throttle NOT installed: expected 2 EveryOneMinute registrations from"
            .. " MSW_Common_Commands.lua, saw " .. registered .. "; re-check upstream.json recheck notes")
        return
    end
    active = true
    print(string.format("%s restore throttle installed (post-load vehicle scan every %d game minutes, line %s)",
        PREFIX, EVERY_MINUTES, tostring(restoreLine)))
end)
