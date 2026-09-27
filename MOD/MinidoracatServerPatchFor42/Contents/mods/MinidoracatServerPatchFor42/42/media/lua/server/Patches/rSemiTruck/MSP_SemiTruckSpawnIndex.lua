--[[
MSP_SemiTruckSpawnIndex — rSemiTruck 保證生成點：每載入一格就線性比對整張座標表

【上游】rSemiTruck（Workshop 3409472393，mod id rSemiTruck；檔案在 `common/`）。upstream.json 有登記。

【缺陷】（行號為上游 common/media/lua/server/rSemiTruck.GuaranteedSpawns_mil.lua）
:69-106 在 OnInitGlobalModData 內以匿名函式註冊 LoadGridsquare；每格 `getX()`、`getY()` 後以 `ipairs` 走完整張
local `guaranteedSpawns`（:17-44 共 11 筆，:51-62 依地圖 MOD 追加，本服裝 Raven Creek 再加 2 筆）逐筆比對座標。
引擎對每個「有物件」的格子、每次載入都觸發（`IsoChunk.java:3799-3831`），絕大多數格子一筆都不中。
沙盒 GuaranteedMilitarySpawns 要座標命中後才檢查（:77-84），關掉它也省不到逐格成本。

【修法】上游的函式與座標表都是 local，外部拿不到，所以：
1. 攔註冊：伺服器 `OnGameBoot` 時暫換 `Events.LoadGridsquare.Add`（`Events.X` 是一般 Lua 表，`Event.java:78-83`），
   以 `getFilenameOfClosure`（`LuaManager.java:7317-7323`）認出該檔傳進來的函式，換成包裝版再交給引擎，
   其他函式原樣轉交；註冊位置與原本相同。上游在 OnInitGlobalModData 內註冊，而它在 `OnGameBoot` 之後才觸發
   （`GameServer.java:767,1481` 的 doMinimumInit → `:781` `IsoWorld.init` → `IsoWorld.java:1995` →
   `GlobalModData.java:54`）；本檔在 `OnGameBoot` 內追加的 OnInitGlobalModData 回呼排在上游（檔案載入時註冊）之後，
   在那裡把 `Add` 換回引擎原本的。
2. 取座標表：包裝時呼叫一次上游函式，傳入只有 getX／getY（回 -1）的探針格子，同時暫換全域 `ipairs` 記下它收到的表
   並回傳空迭代器——上游在 :71-74 取座標後把 `guaranteedSpawns` 交給 `ipairs`，迴圈一次都不跑，沒有任何副作用；
   隨即換回 `ipairs`。拿到的是上游那張 live 表本身，地圖 MOD 追加的點也在內，不需要在本檔複製座標。
3. 包裝版：以座標表建數字索引 x → y；只有命中時才呼叫上游函式（上游再自己比對、檢查沙盒與 ModData、生成），
   其餘格子只剩一次 `getX()` 與一次表查詢。上游只比 x、y 不看 z，索引同樣不看 z。
探針失敗、表的形狀不符或到 OnInitGlobalModData 結束都沒攔到上游函式時印一行 NOT installed，上游函式原樣註冊。

【為什麼不改上游】他人的 Workshop MOD，本服不重新發布；只過濾「哪些格子需要交給它比對」，生成邏輯全由上游執行。

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

local wrapped = 0

local function wrap(upstream)
    local index, count = probeIndex(upstream)
    if not index then
        print(PREFIX .. " spawn index NOT installed: upstream shape changed; re-check upstream.json recheck notes")
        return upstream
    end
    wrapped = wrapped + 1
    print(PREFIX .. " spawn index installed (" .. count .. " guaranteed spawn locations)")
    return function(square)
        local column = index[square:getX()]
        if column and column[square:getY()] then return upstream(square) end
    end
end

local function fromUpstream(fn)
    local ok, file = pcall(getFilenameOfClosure, fn)
    return ok and type(file) == "string" and string.find(string.lower(file), UPSTREAM_FILE, 1, true) ~= nil
end

Events.OnGameBoot.Add(function()
    local options = SandboxVars and SandboxVars.MinidoracatServerPatchFor42
    if options and options.SlimSemiTruckLoad == false then
        print(PREFIX .. " spawn index disabled by sandbox option; upstream unchanged")
        return
    end
    local event = Events.LoadGridsquare
    local engineAdd = event.Add
    local function add(fn)
        if type(fn) == "function" and fromUpstream(fn) then fn = wrap(fn) end
        return engineAdd(fn)
    end
    event.Add = add
    Events.OnInitGlobalModData.Add(function()
        if event.Add == add then event.Add = engineAdd end
        if wrapped == 0 then
            print(PREFIX .. " spawn index NOT installed: upstream LoadGridsquare registration not seen")
        end
    end)
end)
