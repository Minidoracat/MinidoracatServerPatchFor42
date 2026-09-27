--[[
MSP_SemiTruckSpawnIndex — rSemiTruck 保證生成點：每載入一格就分派一次上游回呼、線性比對整張座標表

【上游】rSemiTruck（Workshop 3409472393，mod id rSemiTruck；檔案在 `common/`）。upstream.json 有登記。

【缺陷】（行號為上游 common/media/lua/server/rSemiTruck.GuaranteedSpawns_mil.lua）
:69-106 在 OnInitGlobalModData 內以匿名函式註冊 LoadGridsquare；每格 `getX()`、`getY()` 後以 `ipairs` 走完整張
local `guaranteedSpawns`（:17-44 共 11 筆，:51-62 依地圖 MOD 追加，本服裝 Raven Creek 再加 2 筆）逐筆比對座標。
引擎對每個「有物件」的格子、每次載入都觸發（`IsoChunk.java:3796-3835`），絕大多數格子一筆都不中。
沙盒 GuaranteedMilitarySpawns 要座標命中後才檢查（:77-84），關掉它也省不到逐格成本；引擎逐 callback 分派本身
也有固定成本（`Event.java:52-64`），包裝省不掉，只有不註冊才省得掉。

【修法】上游的函式與座標表都是 local，外部拿不到，所以：
1. 攔註冊：以共用攔截器（`Patches/MSP_ChunkSquareDispatch` 的 `claim`）在伺服器 `OnGameBoot` 暫換 `Events.LoadGridsquare.Add`
   （`Events.X` 是一般 Lua 表，`Event.java:78-83`），以 `getFilenameOfClosure`（`LuaManager.java:7317-7323`）認出該檔傳進來的
   函式，**不註冊**它，改註冊一個 LoadChunk 回呼，其他函式原樣轉交。上游在 OnInitGlobalModData 內註冊，而它在 `OnGameBoot`
   之後才觸發（`GameServer.java:767,1481` 的 doMinimumInit → `:781` `IsoWorld.init` → `IsoWorld.java:1995` →
   `GlobalModData.java:54`）；攔截器在 `OnGameBoot` 內追加的 OnInitGlobalModData 回呼排在上游（檔案載入時註冊）之後，
   在那裡把 `Add` 換回引擎原本的函式（damnlib 補丁共用同一個攔截器，不會串成包裝鏈）。
2. 取座標表：攔到時呼叫一次上游函式，傳入只有 getX／getY（回 -1）的探針格子，同時暫換全域 `ipairs` 記下它收到的表
   並回傳空迴圈——上游在 :71-74 取座標後把 `guaranteedSpawns` 交給 `ipairs`，迴圈一次都不跑，沒有任何副作用；
   隨即換回 `ipairs`。拿到的是上游那張 live 表本身，地圖 MOD 追加的點也在內，不需要在本檔複製座標。
3. LoadChunk 回呼：每個 chunk 載入尾端一次（`IsoChunk.java:3965`），以座標表建的數字索引 x → y 找出 chunk 內命中的點，
   依引擎的 z → x → y 順序、只對引擎當時會觸發 LoadGridsquare 的格子（非 nil、有物件）呼叫上游函式本身
   （上游再自己比對、檢查沙盒與 ModData、生成）。上游只比 x、y 不看 z，索引同樣不看 z，每層都照送。
與逐格的差異只有時間點：同一次 chunk 載入內，上游呼叫從格子迴圈中移到載入尾端。isVehicleIntersecting 可能多看到
同 chunk 迴圈之後才出現的車（建築故事、damnlib 與其他 MOD 在後面格子生的車）；上游被阻擋時不寫 ModData（:89-101），
下次載入重試，不會永久漏生成。IsoDirections.getRandom（方向為 nil 時）與 addVehicleDebug 內的亂數抽取位置隨之改變。
探針失敗、表的形狀不符或 LoadChunk 不可用時印一行 NOT installed，上游函式原樣逐格註冊；到 OnInitGlobalModData
結束都沒攔到上游函式也印一行 NOT installed。

【為什麼不改上游】他人的 Workshop MOD，本服不重新發布；只決定「哪些格子、何時交給它比對」，生成邏輯全由上游執行。

【軟依賴】不 require 上游。`getActivatedMods()` 沒有 rSemiTruck 就直接 return，不碰任何事件。

【開關】沙盒 `MinidoracatServerPatchFor42.SlimSemiTruckLoad`（預設開；關掉＝不攔註冊、上游原樣，重啟生效）。

【上游更新時要重核】見 upstream.json 的 recheck。
]]

local PREFIX = "[MinidoracatServerPatchFor42][rSemiTruck]"
local MOD_ID = "rSemiTruck"
local UPSTREAM_FILE = "/lua/server/rsemitruck.guaranteedspawns_mil.lua"

local mods = getActivatedMods()
if not isServer() or not (mods:contains(MOD_ID) or mods:contains("\\" .. MOD_ID)) then return end

local probeSquare = {
    getX = function() return -1 end,
    getY = function() return -1 end,
}

-- 回傳 x → { [y] = true } 與筆數；形狀不符回 nil
local function probeIndex(upstream)
    local realIpairs, seen = ipairs, nil
    ipairs = function(t)
        seen = t
        return function() return nil end, t, 0
    end
    local ok = pcall(upstream, probeSquare)
    ipairs = realIpairs
    if not ok or type(seen) ~= "table" then return nil end
    local index, count = {}, 0
    for _, spawn in realIpairs(seen) do
        if type(spawn) ~= "table" or type(spawn[1]) ~= "string" or type(spawn[2]) ~= "number"
            or type(spawn[3]) ~= "number" then
            return nil
        end
        local column = index[spawn[2]]
        if not column then
            column = {}
            index[spawn[2]] = column
        end
        column[spawn[3]] = true
        count = count + 1
    end
    return index, count
end

Events.OnGameBoot.Add(function()
    local options = SandboxVars and SandboxVars.MinidoracatServerPatchFor42
    if options and options.SlimSemiTruckLoad == false then
        print(PREFIX .. " spawn index disabled by sandbox option; upstream unchanged")
        return
    end
    local shared = require "Patches/MSP_ChunkSquareDispatch"
    if type(shared) ~= "table" or type(shared.available) ~= "function" or not shared.available() then
        print(PREFIX .. " spawn index NOT installed: LoadChunk dispatch unavailable; upstream unchanged")
        return
    end
    shared.claim(UPSTREAM_FILE, function(fn)
        local index, count = probeIndex(fn)
        if not index then
            print(PREFIX .. " spawn index NOT installed: upstream shape changed; re-check upstream.json recheck notes")
            return false
        end
        Events.LoadChunk.Add(shared.dispatch(function() return index end, fn, PREFIX))
        print(PREFIX .. " spawn index installed (" .. count .. " guaranteed spawn locations, LoadChunk dispatch)")
        return true
    end, function(matched)
        if matched == 0 then
            print(PREFIX .. " spawn index NOT installed: upstream LoadGridsquare registration not seen")
        end
    end)
end)
