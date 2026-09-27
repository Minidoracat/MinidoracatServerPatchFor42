--[[
MSP_DamnSpawnIndex — damnlib 固定車輛生成：每載入一格就分派一次上游回呼、組一次字串鍵查表

【上游】that DAMN Library（Workshop 3171167894，mod id damnlib，作者 KI5／bikinihorst；42.20.4 載入 `42.20/`）。
upstream.json 有登記（上游檔頭宣告 On Lockdown，repo 不留上游快照）。

【缺陷】（行號為上游 42.20/media/lua/server/DAMN_Spawns.lua）
:426-430 在 OnInitGlobalModData 內以匿名函式註冊 LoadGridsquare，每格呼叫 `DAMN.Spawns:checkSquare(square)`；:140 對每格做
`tostring(getX()) .. "_" .. tostring(getY())`（兩次 Java 呼叫、兩次數字轉字串、兩次串接、新字串雜湊）再查
`DAMN.Spawns.byLocation`（KI5 車輛 MOD 以 `DAMN.Spawns:add` 在載入時登記的數十個固定座標）。
引擎對每個「有物件」的格子、每次載入都觸發（`IsoChunk.java:3796-3835`），絕大多數格子查不到；
光是引擎逐 callback 分派本身就有固定成本（`Event.java:52-64`），索引省不掉。

【修法】
1. 伺服器 `OnGameBoot` 時替換 `DAMN.Spawns.checkSquare`：先查數字索引 x → y（由 byLocation 的鍵解析而來，
   是 byLocation 的超集），只有命中時才呼叫原本的 checkSquare，其餘直接回 true（原版查不到時的回傳值，:191）。
   索引在第一次使用時建立；`DAMN.Spawns:addInternal`（byLocation 唯一的寫入點，:97-137）被呼叫或 byLocation 整張被換掉
   時重建，所以伺服器執行中才登記的生成點也不會漏。
2. 以共用攔截器（`Patches/MSP_ChunkSquareDispatch` 的 `claim`，OnGameBoot 暫換 `Events.LoadGridsquare.Add`、
   OnInitGlobalModData 換回引擎原本的函式）依 `getFilenameOfClosure`（`LuaManager.java:7317-7323`）認出 DAMN_Spawns.lua
   在 OnInitGlobalModData 內註冊的匿名函式，**不註冊**它，改註冊一個 LoadChunk 回呼：每個 chunk 載入尾端一次，
   只對索引命中、且引擎當時會觸發 LoadGridsquare 的格子（非 nil、有物件），依引擎的 z → x → y 順序呼叫那個匿名函式本身。
   其他 MOD 的註冊原樣轉交。沒攔到就印 NOT installed，上游照常逐格註冊（仍有 1. 的索引）。
- 命中後走原本的 checkSquare，是否已生成、沙盒、MOD／地圖黑白名單、機率、阻擋判定全部照原版。
- 與逐格的差異只有時間點：同一次 chunk 載入內，上游呼叫從格子迴圈中移到 LoadChunk（載入尾端）。
  ZombRandBetween 的抽取在全域亂數序列中的位置因此改變（機率不變）。isVehicleIntersecting 會多看到「同 chunk
  格子迴圈之後才出現」的車：迴圈後 `randomizeBuildingsEtc`（IsoChunk.java:3905 → :4175）的建築故事可能生車
  （RBPoliceSiege.java:123 等 spawnCarOnNearestNav），以及別的 MOD 在同 chunk 後面格子生的車；上游在 spawnerDebug 關閉時「被阻擋」也會 remember
  （:165-184），此時該點永久不生成。需要「故事車恰好壓在固定點上、且建築在這一個 chunk 載入時才完整串流」，
  反方向（rSemiTruck 的車）因本回呼排在 rSemiTruck 之前而變少。
- 不改 damnlib 的任何檔案、不含其任何程式碼；只在執行時決定「哪些格子、何時交給它檢查」。

【為什麼不改上游】上游宣告 On Lockdown（不得修改、重新打包或散布其檔案）。本補丁不碰上游檔案、不含上游內容，
只在執行時包一層座標過濾與分派；另見 upstream.json recheck 的回報作者建議。

【軟依賴】不 require 上游。`getActivatedMods()` 沒有 damnlib 就直接 return。形狀不符印一行 NOT installed，上游原樣。

【開關】沙盒 `MinidoracatServerPatchFor42.SlimDamnlibLoad`（預設開；關掉＝上游原樣，重啟生效）。
]]

local PREFIX = "[MinidoracatServerPatchFor42][damnlib]"
local MOD_ID = "damnlib"
local UPSTREAM_FILE = "/lua/server/damn_spawns.lua"

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

    -- 目前的索引；byLocation 不是表時回 nil（此時上游 checkSquare 本身也無法運作）
    local function currentIndex()
        local byLocation = DAMN.Spawns["byLocation"]
        if type(byLocation) ~= "table" then return nil end
        if byLocation ~= indexedFrom then
            index, indexedFrom = buildIndex(byLocation), byLocation
        end
        return index
    end

    spawns.addInternal = function(...)
        indexedFrom = nil
        return originalAdd(...)
    end

    spawns.checkSquare = function(self, square, ...)
        local current = currentIndex()
        if not current then return originalCheck(self, square, ...) end
        local column = current[square:getX()]
        if column and column[square:getY()] then return originalCheck(self, square, ...) end
        return true
    end
    spawns.MSP_indexedCheckSquare = spawns.checkSquare
    print(PREFIX .. " spawn index installed")

    local shared = require "Patches/MSP_ChunkSquareDispatch"
    if type(shared) ~= "table" or type(shared.available) ~= "function" or not shared.available() then
        print(PREFIX .. " chunk dispatch NOT installed: LoadChunk dispatch unavailable; upstream per-square handler unchanged")
        return
    end
    shared.claim(UPSTREAM_FILE, function(fn)
        Events.LoadChunk.Add(shared.dispatch(currentIndex, fn, PREFIX))
        return true
    end, function(matched)
        if matched == 0 then
            print(PREFIX .. " chunk dispatch NOT installed: upstream LoadGridsquare registration not seen")
        else
            print(PREFIX .. " chunk dispatch installed (per-square handler replaced by LoadChunk)")
        end
    end)
end

Events.OnGameBoot.Add(install)
