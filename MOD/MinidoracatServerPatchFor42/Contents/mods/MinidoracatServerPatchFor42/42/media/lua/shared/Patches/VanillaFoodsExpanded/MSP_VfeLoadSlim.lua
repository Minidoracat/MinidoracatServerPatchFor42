--[[
MSP_VfeLoadSlim — Vanilla Foods Expanded：每載入一格，上游的合併回呼都逐物件問一次有沒有容器

【上游】Vanilla Foods Expanded（Workshop 3577903007，mod id VanillaFoodsExpanded，核對版本 2026-10-27 更新；42.21.0 載入 `42.18/`）。
upstream.json 有登記（上游宣告 On Lockdown，repo 不留上游快照，本檔不含上游程式碼）。
2026-10-27 這版上游自己把 aging、story、birthday 三個逐格回呼合成一個、略過空格子，story 的 onLoadChunk 也自己節流、冰塊除錯
預設關掉；本補丁之前做的這些都已退場，只剩下面這一件。

【缺陷】（行號為上游 42.18/media/lua/ 下的檔）shared/vfx_squareload.lua :15 onLoadGridsquare（:64 rebuild 註冊 LoadGridsquare）：
引擎對每個有物件的格子、每次載入都觸發（IsoChunk.java:3800-3839）。它每格以 `obj:method()` 呼叫 getWorldObjects():size()、
getObjects():size()，再逐物件 get、getContainerCount；絕大多數格子沒有地上物品也沒有容器，算完就在 :35-38 return。
每次 `obj:method()` 都要先經 getmetatable／__index 查方法表（KahluaThread.java:1113-1148、:1195-1240）。

【修法】只在伺服器生效。以共用攔截器（Patches/MSP_ChunkSquareDispatch 的 claim）認出 vfx_squareload.lua 傳給
Events.LoadGridsquare.Add 的 onLoadGridsquare，不交給引擎，改在同一個位置掛一層前置判斷：格子沒有地上物品、也沒有任何物件帶容器時
直接返回，否則照樣呼叫上游（上游自己再判斷一次、分派給各 listener）。
- 等價：這種格子上，上游的 worldObjects 是 nil、hasContainers 是 false（不論哪些 listener 要地上物品或容器），除了
  SquareLoad.Debug 的計數什麼都不做；Debug 開著時每格照樣呼叫上游。
- 判斷只用兩組 Java 呼叫，方法由 `__classmetatables` 預先取出直接呼叫（同一個 Java 方法、同樣的引數，只省查表；每個類別的方法表
  含繼承的公開方法，LuaJavaClassExposer.java:315-322）：
  - 地上物品：getWorldObjects():isEmpty()。
  - 容器：IsoGridSquare.getObjectContainers(nil, nil, 清單) 一次收齊 getObjects() 裡每個物件的主容器（IsoGridSquare.java:9998-10009
    → IsoObject.getContainers :1907-1922），清單非空＝有容器，用完清空。和上游「某物件 getContainerCount() > 0」等價：
    getContainerCount＝主容器＋次要容器數（IsoObject.java:5194-5198）；引擎只在已有主容器時才加次要容器（IsoObject.java:1247-1262 讀檔、
    :4747-4759 同步、:5300-5308 冷凍庫、IsoStackedWasherDryer.java:50-66），主容器只和次要容器一起清掉（:2160-2212、:5263-5266）；
    沒有 IsoObject 子類別覆寫 getContainer()；原版 Lua 與本機訂閱的全部工作坊 MOD 都沒有呼叫 addSecondaryContainer（2026-10-25 搜尋）。
- 掛點時序：上游 rebuild 在第一個 listener 加入時才 Add。aging（server/vfx_agingmanager.lua :2046）與 story
  （server/vfx_storydistribution.lua :353）在 server 檔載入時加入；birthday（shared/vfx_birthday.lua :102）最早在它自己的
  OnInitGlobalModData 回呼（:134-139）。本檔在 shared 載入時就 claim（專用伺服器先載入全部 MOD 的 shared/ 再載入 server/，
  GameServer.java:1469-1471），所以 Mods= 裡 VFE 排在本 MOD 前後都攔得到。
- 上游的 listener 清空時會 Remove 自己、之後再 Add：Remove 對引擎沒有作用（引擎拿的是本檔的包裝）；攔截器還原前的再 Add 由本檔吞掉，
  還原後的 Add 卻會讓上游被註冊兩次。aging、story 加入後不會移除（只有 birthday 呼叫 SquareLoad.remove，:104）：shared 載入時
  讀這兩檔，讀不到或出現 SquareLoad.remove 就不安裝；OnInitGlobalModData 時兩者至少一個在聽才保留包裝，都不在就換回上游原樣。
- 失敗回退：shared 載入時以 getModFileReader 讀 vfx_squareload.lua 算雜湊，與本檔核對時的不同、或預先取方法失敗，就什麼都不攔、
  印一行 NOT installed（上游原樣）。到 OnInitGlobalModData 都沒攔到也印 NOT installed。
- 換回上游原樣＝不再吞上游的 Add、移除包裝，birthday 還在聽時把上游的 onLoadGridsquare 交給引擎（排到 LoadGridsquare 清單最後）；
  沒有 listener 時上游以為自己沒註冊，之後加入時會自己 Add。

【為什麼不改上游】上游宣告 On Lockdown（不得修改、重新打包或散布）。本補丁不碰上游檔案、不含上游內容，只決定何時呼叫上游的回呼。

【軟依賴】不 require 上游。getActivatedMods() 沒有 VanillaFoodsExpanded 就直接 return，不碰任何事件。

【開關】沙盒 MinidoracatServerPatchFor42.SlimVfeLoad（預設開；關掉＝包裝留在原位、每格照樣轉交上游，重啟生效）。
沙盒在 shared／server 載入之後才讀入（GameServer.java:1469-1481），所以註冊仍由本檔接手，到 OnInitGlobalModData 才決定。

【上游更新時要重核】見 upstream.json 的 recheck。
]]

local PREFIX = "[MinidoracatServerPatchFor42][VanillaFoodsExpanded]"
local MOD_ID = "VanillaFoodsExpanded"
-- 核對過的上游檔：行數與雜湊（逐行、每字元 h = (h * 31 + byte) % 2147483647，行尾再加 10）
local SQUARELOAD = { suffix = "/lua/shared/vfx_squareload.lua", path = "media/lua/shared/vfx_squareload.lua",
    lines = 113, hash = 2031799377 }
-- 加入 SquareLoad 後不會移除自己的上游檔（補丁靠它們一直在聽，保證上游不會在攔截器還原後再 Add）
local KEEPERS = { "media/lua/server/vfx_agingmanager.lua", "media/lua/server/vfx_storydistribution.lua" }

local mods = getActivatedMods()
if not isServer() or not (mods:contains(MOD_ID) or mods:contains("\\" .. MOD_ID)) then return end

local function upstreamMatches(file)
    local ok, matches = pcall(function()
        local reader = getModFileReader(MOD_ID, file.path, false)
        if not reader then return false end
        local h, n = 0, 0
        local line = reader:readLine()
        while line do
            for i = 1, #line do h = (h * 31 + string.byte(line, i)) % 2147483647 end
            h = (h * 31 + 10) % 2147483647
            n = n + 1
            line = reader:readLine()
        end
        reader:close()
        return n == file.lines and h == file.hash
    end)
    return ok and matches
end

-- 讀不到檔（不存在、開檔失敗時 getModFileReader 回 nil）也當成「可能有」：確認不了前提就不安裝
local function upstreamMayMention(path, text)
    local ok, mentioned = pcall(function()
        local reader = getModFileReader(MOD_ID, path, false)
        if not reader then return true end
        local line, found = reader:readLine(), false
        while line and not found do
            found = string.find(line, text, 1, true) ~= nil
            line = reader:readLine()
        end
        reader:close()
        return found
    end)
    return not ok or mentioned
end

-- 每格判斷用的 Java 方法（預先取出，直接以物件為第一個引數呼叫）與收容器用的清單
local function fetchJava()
    local metatables = __classmetatables
    local square = metatables[IsoGridSquare.class].__index
    local array = metatables[ArrayList.class].__index
    local pz = metatables[PZArrayList.class].__index
    local java = {
        getWorldObjects = square.getWorldObjects, getObjectContainers = square.getObjectContainers,
        arrayIsEmpty = array.isEmpty, listIsEmpty = pz.isEmpty, listClear = pz.clear,
        found = PZArrayList.new(ItemContainer.class, 4),
    }
    for _, key in ipairs({ "getWorldObjects", "getObjectContainers", "arrayIsEmpty", "listIsEmpty", "listClear", "found" }) do
        if java[key] == nil then return nil end
    end
    return java
end

local shared = require "Patches/MSP_ChunkSquareDispatch"
if type(shared) ~= "table" or type(shared.claim) ~= "function" or not shared.available() then
    print(PREFIX .. " load slim NOT installed: LoadGridsquare interception unavailable; upstream unchanged")
    return
end
if not upstreamMatches(SQUARELOAD) then
    print(PREFIX .. " load slim NOT installed: vfx_squareload.lua differs from the reviewed version; upstream unchanged;"
        .. " re-check upstream.json recheck notes")
    return
end
for _, path in ipairs(KEEPERS) do
    if upstreamMayMention(path, "SquareLoad.remove") then
        print(PREFIX .. " load slim NOT installed: cannot confirm " .. path .. " never removes itself from SquareLoad"
            .. " (unreadable, or SquareLoad.remove found); upstream unchanged; re-check upstream.json recheck notes")
        return
    end
end
local fetched, java = pcall(fetchJava)
if not fetched or not java then
    print(PREFIX .. " load slim NOT installed: Java method lookup failed (" .. tostring(java) .. "); upstream unchanged")
    return
end
local getWorldObjects, getObjectContainers = java.getWorldObjects, java.getObjectContainers
local arrayIsEmpty, listIsEmpty, listClear, found = java.arrayIsEmpty, java.listIsEmpty, java.listClear, java.found

local upstream -- vfx_squareload.lua 的 onLoadGridsquare
local squareLoad -- VFX.SquareLoad（讀 Debug、isListening）
local slim = true -- 沙盒關閉時 false：包裝留在原位、每格照樣轉交上游
local swallow = true -- 換回上游原樣後 false：上游再 Add 時照樣交給引擎

local function onSquare(square)
    if slim and arrayIsEmpty(getWorldObjects(square)) and not squareLoad.Debug then
        getObjectContainers(square, nil, nil, found)
        if listIsEmpty(found) then return end
        listClear(found)
    end
    return upstream(square)
end
-- E2E 用：包裝與上游回呼（vfe-mp 情境在空格子上比較成本）、是否真的在略過空格子
MSP_VfeLoadSlim = { handlers = function() return onSquare, upstream end, installed = false }

shared.claim(SQUARELOAD.suffix, function(fn)
    if upstream then return swallow and fn == upstream end -- 上游 Remove 後再 Add：引擎上仍是包裝，不再註冊一次
    squareLoad = VFX and VFX.SquareLoad
    if type(squareLoad) ~= "table" then return false end
    upstream = fn
    Events.LoadGridsquare.Add(onSquare) -- 經攔截器轉交引擎，落在上游原本的位置
    return true
end, function()
    if not upstream then
        print(PREFIX .. " load slim NOT installed: vfx_squareload.lua LoadGridsquare registration not seen; upstream unchanged")
        return
    end
    if not (squareLoad.isListening("aging") or squareLoad.isListening("story")) then
        -- 只剩 birthday 會增減：換回上游原樣，免得它清空再加入時上游被註冊兩次
        swallow = false
        Events.LoadGridsquare.Remove(onSquare)
        if squareLoad.isListening("birthday") then Events.LoadGridsquare.Add(upstream) end
        print(PREFIX .. " load slim NOT installed: neither aging nor story listens to SquareLoad; upstream unchanged")
        return
    end
    local options = SandboxVars and SandboxVars.MinidoracatServerPatchFor42
    if options and options.SlimVfeLoad == false then
        slim = false
        print(PREFIX .. " load slim disabled by sandbox option; every tile still goes to the SquareLoad dispatcher")
        return
    end
    MSP_VfeLoadSlim.installed = true
    print(PREFIX .. " load slim installed (empty tiles skip the SquareLoad dispatcher)")
end)
