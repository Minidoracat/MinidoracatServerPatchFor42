--[[
MSP_ChunkSquareDispatch — 以「每個 chunk 一次」的 LoadChunk 取代「每格一次」的 LoadGridsquare，只把索引命中的格子交給上游

不是補丁本身，是 damnlib／rSemiTruck 兩個補丁共用的攔截器與分派器（`require "Patches/MSP_ChunkSquareDispatch"`，回傳表；
狀態放在全域 `MSP_ChunkSquareDispatch`，require 沒有命中快取而重跑本檔時，攔截器仍只有一個）。

【攔截註冊】`claim(檔名尾段, onMatch, onDone)`：第一次呼叫時暫換 `Events.LoadGridsquare.Add`（全伺服器只換一次），
以 `getFilenameOfClosure`（LuaManager.java:7341-7347）認出各上游檔傳進來的函式交給對應的 onMatch；onMatch 回 true＝已接手、
不交給引擎，回 false＝原樣註冊。其他函式原樣轉交。同時追加一個 OnInitGlobalModData 回呼：把 `Add` 換回引擎原本的函式，
再對每個 claim 呼叫一次 onDone(命中次數)。各補丁若各自暫換、各自還原會串成鏈：後裝的記下的「原本的 Add」其實是先裝的
包裝，還原後 `Add` 永遠停在別人的包裝上，所以集中在這裡。時序：OnInitGlobalModData 在 OnGameBoot 之後觸發
（GameServer.java:773,787,1496、IsoWorld.java:2009、GlobalModData.java:54），OnGameBoot 內追加的回呼排在上游之後。

【分派】`dispatch(getIndex, upstream, prefix)` 回傳 LoadChunk 回呼；getIndex() 回傳 x → { [y] = true }（世界座標）或 nil
（nil＝本次不處理）。引擎依據 `IsoChunk.doLoadGridsquare`（IsoChunk.java:3695-3970）：
- :3800-3839 依 z＝minLevel..maxLevel、x＝0..7、y＝0..7 走訪，`square ~= null 且 getObjects() 非空` 時觸發 LoadGridsquare；
- :3969 同一次載入的最後觸發一次 LoadChunk(this)。兩個事件只在這裡觸發（LuaEventManager.java:700-701 註冊）。
所以在 LoadChunk 裡照同樣的 z→x→y 順序、同樣的條件重走「索引命中的格子」，上游收到的格子集合與順序和逐格時相同，
只是時間點移到同一次 chunk 載入的尾端（差異見 upstream.json 各上游的 recheck 與 CHANGELOG 技術要點）。
IsoChunk 沒有 Lua 可讀的 wx/wy（Kahlua 不暴露 instance field），chunk 世界座標由任一格子的 getX/getY 減去其 chunk 內座標得到；
(0,0,0) 那格可能是 nil，所以找不到時依序掃其他格。上游在每格各自被引擎 protectedCall 包住（Event.java:52-64），
這裡用 pcall 維持「一格出錯不影響其他格」。
]]

local M = MSP_ChunkSquareDispatch or {}
MSP_ChunkSquareDispatch = M
M.claims = M.claims or {}

local function fromFile(fn, suffix)
    local ok, file = pcall(getFilenameOfClosure, fn)
    return ok and type(file) == "string" and string.find(string.lower(file), suffix, 1, true) ~= nil
end

-- LoadGridsquare／LoadChunk 兩個事件表都在（`Events.X` 是一般 Lua 表，Event.java:78-83）才可用
function M.available()
    for _, name in ipairs({ "LoadGridsquare", "LoadChunk" }) do
        local event = Events[name]
        if type(event) ~= "table" or type(event.Add) ~= "function" then return false end
    end
    return true
end

function M.claim(suffix, onMatch, onDone)
    local claims = M.claims
    claims[#claims + 1] = { suffix = suffix, onMatch = onMatch, onDone = onDone, matched = 0 }
    if M.restore then return end
    local event = Events.LoadGridsquare
    local engineAdd = event.Add
    local function add(fn)
        if type(fn) == "function" then
            for i = 1, #claims do
                local claim = claims[i]
                if fromFile(fn, claim.suffix) then
                    claim.matched = claim.matched + 1
                    if claim.onMatch(fn) then return end
                    break
                end
            end
        end
        return engineAdd(fn)
    end
    event.Add = add
    M.restore = function()
        if event.Add == add then event.Add = engineAdd end
    end
    Events.OnInitGlobalModData.Add(function()
        M.restore()
        for i = 1, #claims do claims[i].onDone(claims[i].matched) end
    end)
end

local function anySquare(chunk)
    local square = chunk:getGridSquare(0, 0, 0)
    if square then return square, 0, 0 end
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for x = 0, 7 do
            for y = 0, 7 do
                square = chunk:getGridSquare(x, y, z)
                if square then return square, x, y end
            end
        end
    end
end

function M.dispatch(getIndex, upstream, prefix)
    return function(chunk)
        local index = getIndex()
        if not index then return end
        local anchor, ax, ay = anySquare(chunk)
        if not anchor then return end
        local baseX = anchor:getX() - ax
        local columns
        for x = 0, 7 do
            local column = index[baseX + x]
            if column then
                columns = columns or {}
                columns[x] = column
            end
        end
        if not columns then return end
        local baseY = anchor:getY() - ay
        local points
        for x = 0, 7 do
            local column = columns[x]
            if column then
                for y = 0, 7 do
                    if column[baseY + y] then
                        points = points or {}
                        points[#points + 1] = x
                        points[#points + 1] = y
                    end
                end
            end
        end
        if not points then return end
        for z = chunk:getMinLevel(), chunk:getMaxLevel() do
            for i = 1, #points, 2 do
                local square = chunk:getGridSquare(points[i], points[i + 1], z)
                if square and not square:getObjects():isEmpty() then
                    local ok, err = pcall(upstream, square)
                    if not ok then print(prefix .. " upstream LoadGridsquare handler failed: " .. tostring(err)) end
                end
            end
        end
    end
end

return M
