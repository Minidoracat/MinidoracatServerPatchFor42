--[[
MSP_VfeLoadSlim — Vanilla Foods Expanded：每載入一格就分派兩個伺服器回呼，story 每載入一個 chunk 就重掃全部待處理建築

【上游】Vanilla Foods Expanded（Workshop 3577903007，mod id VanillaFoodsExpanded，核對版本 3.4.2、2026-10-16 更新；42.21.0 載入 `42.18/`）。
upstream.json 有登記（上游宣告 On Lockdown，repo 不留上游快照，本檔不含上游程式碼）。

【缺陷】（行號為上游 42.18/media/lua/server/ 下的檔）
1. vfx_agingmanager.lua :1460 loadGridSquare（:2019 註冊 LoadGridsquare）：引擎對每個有物件的格子、每次載入都觸發
   （IsoChunk.java:3800-3839）。它每格 getWorldObjects、getObjects 並逐物件 getContainerCount，絕大多數格子沒有地上物品也沒有容器，
   算完就 return。
2. vfx_storydistribution.lua :197 onLoadGridsquare（:292 註冊）：每格 getRoom，室內格再 getBuilding、getDef 並逐物件 getContainerCount；
   格子上沒有容器時什麼都不登記。
3. 同檔 :243 onLoadChunk：有待處理建築時由 onLoadGridsquare 以 Events.LoadChunk.Add 掛上、清空時自己 Remove。每次 LoadChunk 都對
   全部待處理建築跑 :87 pruneBuilding（逐 batch 查 chunk 是否還在）再判斷能否完成。伺服器一個 cell 的 64 個 chunk 在同一幀依序載入
   （ServerMap.java:944-956 RecalcAll2），所以每載入一個 cell 就把全部待處理建築重掃 64 次；探索新地圖時待處理建築很多。
2026-10-24 正式服 Lua 取樣：以上三項分別佔主執行緒 6.25%、1.14%、3.15%。

【修法】只在伺服器生效。上游的回呼一個不少地照原順序執行，只略過「上游呼叫了也什麼都不做」的呼叫
（逐項論證與上游原樣 vs 補丁差分見 scripts/test_vfe_load_slim.lua）。
- 掛點：本檔放 shared/，專用伺服器先載入全部 MOD 的 shared/ 再載入 server/（GameServer.java:1469-1471），所以早於上游兩個 server 檔。
  以共用攔截器（Patches/MSP_ChunkSquareDispatch 的 claim）認出兩檔傳給 Events.LoadGridsquare.Add 的函式，不交給引擎，改在 aging
  註冊的位置掛一個合併回呼（兩檔中間沒有別的 LoadGridsquare 註冊，順序不變；aging 先、story 後，同上游）。
- 合併回呼每格先逐物件找容器（同 aging :1484-1494 的判斷，找到就停）：
  - aging：有容器或有地上物品才呼叫，其餘格子上游算完就 return。例外照樣呼叫：開了 VFX.AgingSkipDebug／AgingQueueDebug（上游要印 log
    與計數），以及「近期交給過 aging 的格子物件」——上游 :1466-1480 會清掉該物件殘留的掃描佇列項目。專用伺服器不觸發 ReuseGridsquare
    （只有單機／客戶端呼叫 doReuseGridsquares，伺服器卸載走 WorldReuserThread，IsoChunk.java:3352-3361、:4291、
    WorldReuserThread.java:105-137），格子物件回收後會在別處重用，殘留項目真的會出現。佇列上限 512（:244、:1504），
    processSquareScanQueue 每次被呼叫至少取出一項（:1555-1559），所以排入的項目在它被呼叫 512 次內一定被取出或整個佇列重設；
    本檔記下交給 aging 的格子，計數滿 512 次換一代、兩代後丟棄，佇列整個清空時全部丟棄。計數方法：aging 呼叫期間暫換
    Events.OnTick.Add，認出它掛上的 processSquareScanQueue、改掛一層包裝（同一時間、同一位置）；包裝呼叫期間暫換
    Events.OnTick.Remove，它移除自己時改為移除包裝。
  - story：格子有容器才呼叫。呼叫期間暫換 Events.LoadChunk.Add，認出它掛上的 onLoadChunk、改掛 chunk 回呼（同一時間、同一位置）；
    也暫換全域 isServer：上游只在新建一棟待處理建築時呼叫它（:213-216 → :30 indexBuilding），以此得知「有新建築」。
- chunk 回呼：同一個 cell 的同一次載入（同 cell、同幀、chunk 在 cell 內的序號遞增，序號照 RecalcAll2 的 x 外圈、y 內圈）中，
  第一個 chunk 照樣呼叫 onLoadChunk；之後的 chunk 只有「上次呼叫後新建了待處理建築」才呼叫，否則略過。理由：
  同一次 cell 載入中途不會卸載任何 chunk（卸載只在 postupdate，ServerMap.java:533-560；載入在 preupdate，:493）；cell 的 64 個 chunk
  在 RecalcAll2 一開頭就全部可見（isLoaded＝true，ServerMap.java:837、:677；BuildingDef.isFullyStreamedIn 查的就是它，
  BuildingDef.java:423-434）；64 個 chunk 的原點落在同一個 cellKey（上游 :23-25）。所以第一次呼叫時沒完成、沒被清掉的建築，
  同一次載入裡之後每次呼叫也都不會（batch 是否有效、是否完整載入、cell 索引都不變），那些呼叫只更新上游的快取；新建築第一次被檢查
  （firstCheck）的那次呼叫照樣發生。完成、清除、亂數抽取都發生在同一批呼叫、同樣順序。chunk 原點格子不存在或座標為負
  （上游此時不以 cell 過濾）一律照樣呼叫；軟重設也照樣呼叫：那時 chunk 由 WorldStreamer.addJobWipe 逐個載入、不走 RecalcAll2
  （WorldStreamer.java:516-527、GameServer.java:412），上面的前提不成立。
- 失敗回退：shared 載入時以 getModFileReader 讀上游兩檔算雜湊，與本檔核對時的不同就什麼都不攔、印一行 NOT installed（上游原樣）；
  到 OnInitGlobalModData 都沒攔到註冊也印 NOT installed。上游回呼出錯時印一行，不影響同一格的另一個回呼（同引擎逐 callback 隔離）。

【為什麼不改上游】上游宣告 On Lockdown（不得修改、重新打包或散布）。本補丁不碰上游檔案、不含上游內容，只決定何時呼叫上游的回呼。

【未涵蓋】shared/vfx_birthday.lua :332 的 LoadGridsquare 匿名函式在上游 shared 載入時就註冊（Mods= 上游排在本 MOD 之前），
早於本 MOD 任何檔案、拿不到函式，攔不到；它每格 getWorldObjects 一次。

【軟依賴】不 require 上游。getActivatedMods() 沒有 VanillaFoodsExpanded 就直接 return，不碰任何事件。

【開關】沙盒 MinidoracatServerPatchFor42.SlimVfeLoad（預設開；關掉＝每格照樣呼叫兩個上游回呼、story 自己掛 onLoadChunk，重啟生效）。
沙盒在 shared 載入之後才讀入（GameServer.java:1469-1481），所以註冊仍由本檔接手，開關在 OnGameBoot 才決定行為。

【上游更新時要重核】見 upstream.json 的 recheck。
]]

local PREFIX = "[MinidoracatServerPatchFor42][VanillaFoodsExpanded]"
local MOD_ID = "VanillaFoodsExpanded"
-- 核對過的上游檔：行數與雜湊（逐行、每字元 h = (h * 31 + byte) % 2147483647，行尾再加 10）
local AGING = { suffix = "/lua/server/vfx_agingmanager.lua", path = "media/lua/server/vfx_agingmanager.lua",
    lines = 2019, hash = 860265047 }
local STORY = { suffix = "/lua/server/vfx_storydistribution.lua", path = "media/lua/server/vfx_storydistribution.lua",
    lines = 293, hash = 741156383 }
local SCAN_CALLS = 512 -- 上游掃描佇列上限：排入的項目在 processSquareScanQueue 被呼叫這麼多次內一定被取出

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

local shared = require "Patches/MSP_ChunkSquareDispatch"
if type(shared) ~= "table" or type(shared.claim) ~= "function" or not shared.available() then
    print(PREFIX .. " load slim NOT installed: LoadGridsquare interception unavailable; upstream unchanged")
    return
end
if not (upstreamMatches(AGING) and upstreamMatches(STORY)) then
    print(PREFIX .. " load slim NOT installed: vfx_agingmanager.lua / vfx_storydistribution.lua differ from the reviewed"
        .. " version; upstream unchanged; re-check upstream.json recheck notes")
    return
end

-- 實機觀察用計數（E2E 讀）
local stats = { squares = 0, aging = 0, story = 0, chunks = 0, chunkCalls = 0 }
MSP_VfeLoadSlim = { stats = stats }

local enabled = true
local aging, story, scanQueue, storyChunk -- 上游函式
local recent, previous, scanCalls = {}, {}, 0 -- 近期交給 aging 的格子（兩代）、processSquareScanQueue 本代被呼叫次數
local newBuilding = false
local lastCellX, lastCellY, lastPos, lastFrame
local savedTickAdd, savedTickRemove, savedChunkAdd, savedChunkRemove, savedIsServer -- 暫換期間原本的函式
local scanDriver, chunkDriver

local function failed(what, err)
    print(PREFIX .. " upstream " .. what .. " failed: " .. tostring(err))
end

local function tickAdd(fn)
    if fn == scanQueue or (scanQueue == nil and type(fn) == "function" and shared.fromFile(fn, AGING.suffix)) then
        scanQueue = fn
        return savedTickAdd(scanDriver)
    end
    return savedTickAdd(fn)
end

local function tickRemove(fn)
    if fn == scanQueue then
        recent, previous, scanCalls = {}, {}, 0 -- 佇列整個清空了
        return savedTickRemove(scanDriver)
    end
    return savedTickRemove(fn)
end

scanDriver = function(...)
    scanCalls = scanCalls + 1
    if scanCalls >= SCAN_CALLS then recent, previous, scanCalls = {}, recent, 0 end
    local event = Events.OnTick
    local remove = event.Remove
    savedTickRemove, event.Remove = remove, tickRemove
    local ok, err = pcall(scanQueue, ...)
    event.Remove = remove
    if not ok then failed("processSquareScanQueue", err) end
end

local function chunkAdd(fn)
    if fn == storyChunk or (storyChunk == nil and type(fn) == "function" and shared.fromFile(fn, STORY.suffix)) then
        storyChunk = fn
        return savedChunkAdd(chunkDriver)
    end
    return savedChunkAdd(fn)
end

local function chunkRemove(fn)
    if fn == storyChunk then return savedChunkRemove(chunkDriver) end
    return savedChunkRemove(fn)
end

local function countingIsServer(...)
    newBuilding = true
    return savedIsServer(...)
end

chunkDriver = function(chunk)
    stats.chunks = stats.chunks + 1
    local origin = not isServerSoftReset() and chunk and chunk:getGridSquare(0, 0, 0)
    local x, y = origin and origin:getX(), origin and origin:getY()
    if origin and x >= 0 and y >= 0 then
        local cellX, cellY = math.floor(x / 64), math.floor(y / 64)
        local pos = math.floor(x / 8) % 8 * 8 + math.floor(y / 8) % 8
        local frame = getWorld():getFrameNo()
        local same = cellX == lastCellX and cellY == lastCellY and frame == lastFrame and pos > lastPos
        lastCellX, lastCellY, lastPos, lastFrame = cellX, cellY, pos, frame
        if same and not newBuilding then return end
    else
        lastCellX = nil
    end
    newBuilding = false
    stats.chunkCalls = stats.chunkCalls + 1
    local event = Events.LoadChunk
    local remove = event.Remove
    savedChunkRemove, event.Remove = remove, chunkRemove
    local ok, err = pcall(storyChunk, chunk)
    event.Remove = remove
    if not ok then failed("story LoadChunk handler", err) end
end

local function callAging(square)
    stats.aging = stats.aging + 1
    local event = Events.OnTick
    local add = event.Add
    savedTickAdd, event.Add = add, tickAdd
    local ok, err = pcall(aging, square)
    event.Add = add
    if not ok then failed("aging LoadGridsquare handler", err) end
end

local function callStory(square)
    stats.story = stats.story + 1
    local event = Events.LoadChunk
    local add = event.Add
    savedChunkAdd, savedIsServer = add, isServer
    event.Add, isServer = chunkAdd, countingIsServer
    local ok, err = pcall(story, square)
    event.Add, isServer = add, savedIsServer
    if not ok then failed("story LoadGridsquare handler", err) end
end

local function onSquare(square)
    stats.squares = stats.squares + 1
    if not enabled then
        if aging then
            local ok, err = pcall(aging, square)
            if not ok then failed("aging LoadGridsquare handler", err) end
        end
        if story then
            local ok, err = pcall(story, square)
            if not ok then failed("story LoadGridsquare handler", err) end
        end
        return
    end
    local containers = false
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if object and object:getContainerCount() > 0 then
            containers = true
            break
        end
    end
    if aging then
        local worldObjects = not containers and square:getWorldObjects()
        if containers or (worldObjects and worldObjects:size() > 0) then
            recent[square] = true
            callAging(square)
        elseif recent[square] or previous[square] or (VFX and (VFX.AgingSkipDebug or VFX.AgingQueueDebug)) then
            callAging(square)
        end
    end
    if story and containers then callStory(square) end
end
-- E2E 量測用：合併回呼與兩個上游回呼（vfe-mp 情境在空格子上比較兩者的成本）
MSP_VfeLoadSlim.handlers = function() return onSquare, aging, story end

local function take(fn)
    if not (aging or story) then Events.LoadGridsquare.Add(onSquare) end -- 經攔截器轉交引擎，落在 aging 原本的位置
    return fn
end

shared.claim(AGING.suffix, function(fn)
    if aging then return false end
    aging = take(fn)
    return true
end, function() end)

shared.claim(STORY.suffix, function(fn)
    if story then return false end
    story = take(fn)
    return true
end, function()
    if not (aging and story) then
        -- 沒攔到的那個由引擎原樣逐格呼叫；攔到的照樣經合併回呼
        print(string.format("%s load slim NOT installed for the handler not seen (aging=%s, story=%s);"
            .. " re-check upstream.json recheck notes", PREFIX, tostring(aging ~= nil), tostring(story ~= nil)))
    elseif enabled then
        print(PREFIX .. " load slim installed (aging/story LoadGridsquare merged and gated; story LoadChunk skipped"
            .. " within a cell load when nothing can change)")
    end
end)

Events.OnGameBoot.Add(function()
    local options = SandboxVars and SandboxVars.MinidoracatServerPatchFor42
    if options and options.SlimVfeLoad == false then
        enabled = false
        print(PREFIX .. " load slim disabled by sandbox option; both upstream LoadGridsquare handlers run on every tile")
    end
end)
