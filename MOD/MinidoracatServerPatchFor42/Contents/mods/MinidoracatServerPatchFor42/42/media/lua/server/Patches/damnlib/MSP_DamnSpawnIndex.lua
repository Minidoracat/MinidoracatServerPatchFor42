--[[
MSP_DamnSpawnIndex — damnlib 固定車輛生成：每載入一格就組一次字串鍵查表

【上游】that DAMN Library（Workshop 3171167894，mod id damnlib，作者 KI5／bikinihorst；42.20.4 載入 `42.20/`）。
upstream.json 有登記（上游檔頭宣告 On Lockdown，repo 不留上游快照）。

【缺陷】（行號為上游 42.20/media/lua/server/DAMN_Spawns.lua）
:426-430 在 OnInitGlobalModData 內註冊 LoadGridsquare，每格呼叫 `DAMN.Spawns:checkSquare(square)`；:140 對每格做
`tostring(getX()) .. "_" .. tostring(getY())`（兩次 Java 呼叫、兩次數字轉字串、兩次串接、新字串雜湊）再查
`DAMN.Spawns.byLocation`（KI5 車輛 MOD 以 `DAMN.Spawns:add` 在載入時登記的數十個固定座標）。
引擎對每個「有物件」的格子、每次載入都觸發（`IsoChunk.java:3799-3831`），絕大多數格子查不到。

【修法】伺服器 `OnGameBoot` 時替換 `DAMN.Spawns.checkSquare`：先查數字索引 x → y（由 byLocation 的鍵解析而來，
是 byLocation 的超集），只有命中時才呼叫原本的 checkSquare，其餘直接回 true（原版查不到時的回傳值，:191）。
多數格子只剩一次 `getX()` 與一次表查詢，不組字串、不呼叫 `getY()`。
- 索引在第一次使用時建立；`DAMN.Spawns:addInternal`（byLocation 唯一的寫入點，:97-137）被呼叫或 byLocation 整張被換掉
  時重建，所以伺服器執行中才登記的生成點也不會漏。
- 命中後走原本的 checkSquare，是否已生成、沙盒、MOD／地圖黑白名單、機率、阻擋判定全部照原版。
- 不改 damnlib 的任何檔案、不含其任何程式碼；只在執行時決定「哪些格子需要交給它檢查」。

【為什麼不改上游】上游宣告 On Lockdown（不得修改、重新打包或散布其檔案）。本補丁不碰上游檔案、不含上游內容，
只在執行時包一層座標過濾；另見 upstream.json recheck 的回報作者建議。

【軟依賴】不 require 上游。`getActivatedMods()` 沒有 damnlib 就直接 return。形狀不符印一行 NOT installed，上游原樣。

【開關】沙盒 `MinidoracatServerPatchFor42.SlimDamnlibLoad`（預設開；關掉＝上游原樣，重啟生效）。
]]

local PREFIX = "[MinidoracatServerPatchFor42][damnlib]"
local MOD_ID = "damnlib"

local mods = getActivatedMods()
if not isServer() or not (mods:contains(MOD_ID) or mods:contains("\\" .. MOD_ID)) then return end

-- byLocation 的鍵是 tostring(x) .. "_" .. tostring(y)；解析成數字索引。解析不出來的鍵不可能等於任何格子的鍵。
local function buildIndex(byLocation)
    local index = {}
    for key in pairs(byLocation) do
        if type(key) == "string" then
            local sx, sy = string.match(key, "^(.-)_(.*)$")
            local x, y = tonumber(sx), tonumber(sy)
            if x and y then
                local column = index[x]
                if not column then
                    column = {}
                    index[x] = column
                end
                column[y] = true
            end
        end
    end
    return index
end

local function install()
    local options = SandboxVars and SandboxVars.MinidoracatServerPatchFor42
    if options and options.SlimDamnlibLoad == false then
        print(PREFIX .. " spawn index disabled by sandbox option; upstream unchanged")
        return
    end
    local spawns = DAMN and DAMN.Spawns
    if type(spawns) ~= "table" or type(spawns.checkSquare) ~= "function" or type(spawns.addInternal) ~= "function"
        or type(spawns.byLocation) ~= "table" then
        print(PREFIX .. " spawn index NOT installed: upstream shape changed; re-check upstream.json recheck notes")
        return
    end
    if spawns.MSP_indexedCheckSquare == spawns.checkSquare then return end

    local originalCheck, originalAdd = spawns.checkSquare, spawns.addInternal
    local index, indexedFrom

    spawns.addInternal = function(...)
        indexedFrom = nil
        return originalAdd(...)
    end

    spawns.checkSquare = function(self, square, ...)
        local byLocation = DAMN.Spawns["byLocation"]
        if type(byLocation) ~= "table" then return originalCheck(self, square, ...) end
        if byLocation ~= indexedFrom then
            index, indexedFrom = buildIndex(byLocation), byLocation
        end
        local column = index[square:getX()]
        if column and column[square:getY()] then return originalCheck(self, square, ...) end
        return true
    end
    spawns.MSP_indexedCheckSquare = spawns.checkSquare
    print(PREFIX .. " spawn index installed")
end

Events.OnGameBoot.Add(install)
