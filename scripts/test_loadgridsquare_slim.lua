-- 離線測試：LoadGridsquare 瘦身三補丁（Arcadia／damnlib／rSemiTruck）。載入「未修改的」上游檔（本機 Steam 訂閱副本），
-- 以同一批 chunk 各跑一次「開關關閉＝上游原樣」與「開關開啟＝補丁」，逐項比對所有副作用，並證明非目標格子不進上游。
--   lua scripts/test_loadgridsquare_slim.lua             行為等價、邊界、隨機差分
--   lua scripts/test_loadgridsquare_slim.lua --mutants   另對分派器／索引植入錯誤，確認隨機差分抓得到
--   lua scripts/test_loadgridsquare_slim.lua --bench     另跑離線每 chunk 成本比較（標準 Lua，非 Kahlua、非實機）
-- 引擎模擬依 IsoChunk.doLoadGridsquare（IsoChunk.java:3691-3966）：z＝minLevel..maxLevel、x、y 走訪，只處理非 nil 且
-- 有物件的格子，先 MapObjects.loadGridSquare（MapObjects.java:184-218，跳過地上物品）再依註冊順序觸發 LoadGridsquare
-- （Event.java:52-64，每個 callback 各自 protectedCall）；整個 chunk 走完後觸發一次 LoadChunk（:3965）。

local WS = "D:/SteamLibrary/steamapps/workshop/content/108600/"
local UP = {
    arcadiaShared = WS .. "3786849936/mods/ArcadiaRefillablePropaneTanks_B42/42/media/lua/shared/ArcadiaRefillablePropane_Shared.lua",
    arcadiaServer = WS .. "3786849936/mods/ArcadiaRefillablePropaneTanks_B42/42/media/lua/server/ArcadiaRefillablePropane_Server.lua",
    damn = WS .. "3171167894/mods/damnlib/42.20/media/lua/server/DAMN_Spawns.lua",
    semi = WS .. "3409472393/mods/rSemiTruck/common/media/lua/server/rSemiTruck.GuaranteedSpawns_mil.lua",
}
local PATCHES = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/server/Patches/"
local PATCH = {
    arcadia = PATCHES .. "ArcadiaRefillablePropaneTanks_B42/MSP_ArcadiaDepotSpriteLoad.lua",
    damn = PATCHES .. "damnlib/MSP_DamnSpawnIndex.lua",
    semi = PATCHES .. "rSemiTruck/MSP_SemiTruckSpawnIndex.lua",
    dispatch = PATCHES .. "MSP_ChunkSquareDispatch.lua",
}
local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then error("找不到檔案（上游需本機已訂閱）：" .. path) end
    local text = fh:read("a")
    fh:close()
    return text
end
for _, path in pairs(UP) do readFile(path) end

local pass, fail = 0, 0
local rawPrint, printed = print, {}
local function check(name, cond)
    if cond then pass = pass + 1; rawPrint("  PASS  " .. name) else fail = fail + 1; rawPrint("  FAIL  " .. name) end
end

-- 突變：{ file = PATCH.x, from = 原文片段, to = 取代 }；只影響本檔載入補丁時讀到的原始碼
local MUTATION
local function loadPatch(path)
    local source = readFile(path)
    if MUTATION and MUTATION.file == path then
        local s, e = source:find(MUTATION.from, 1, true)
        if not s then error("突變片段不在原始碼中：" .. MUTATION.name) end
        source = source:sub(1, s - 1) .. MUTATION.to .. source:sub(e + 1)
    end
    return assert(load(source, "@" .. path))()
end

-- ===== 假引擎 =====
function print(...)
    local line = table.concat({ ... }, " ")
    if line:find("MinidoracatServerPatchFor42", 1, true) then printed[#printed + 1] = line end
end
local function printedMatching(text)
    local n = 0
    for _, line in ipairs(printed) do if line:find(text, 1, true) then n = n + 1 end end
    return n
end

local effects, rngState, rngBetweenState, modDataStore, activeMods, spriteCallbacks, counters
local function log(line) effects[#effects + 1] = line end
local function count(name) counters[name] = (counters[name] or 0) + 1 end

local function newEvent(name)
    local event = { list = {} }
    event.Add = function(fn) if type(fn) == "function" then event.list[#event.list + 1] = fn end end
    event.Remove = function(fn)
        for i, f in ipairs(event.list) do if f == fn then table.remove(event.list, i); return end end
    end
    event.name = name
    event.engineAdd = event.Add
    return event
end
local function trigger(event, ...)
    local n = 1
    while n <= #event.list do
        local fn = event.list[n]
        count("dispatch:" .. event.name)
        local ok, err = pcall(fn, ...)
        if not ok then log("callback error in " .. event.name .. ": " .. tostring(err):gsub("^.-:%d+: ", "")) end
        local still = false
        for _, f in ipairs(event.list) do if f == fn then still = true; break end end
        if still then n = n + 1 end
    end
end

local function javaList(items)
    return {
        size = function() return #items end,
        get = function(_, i) return items[i + 1] end,
        isEmpty = function() return #items == 0 end,
        contains = function(_, v) for _, x in ipairs(items) do if x == v then return true end end return false end,
    }
end

local function resetEnv(modList)
    effects, printed, modDataStore, spriteCallbacks = {}, {}, {}, {}
    counters = { vehicleContainer = 0, getObjects = 0 }
    rngState, rngBetweenState = 12345, 777
    activeMods = {}
    for _, id in ipairs(modList) do activeMods[id] = true; activeMods["\\" .. id] = true end
    Events = setmetatable({}, { __index = function(t, k) local e = newEvent(k); rawset(t, k, e); return e end })
    DAMN = {
        log = function() end, printList = function() end,
        itemIsInArray = function(_, arr, value) for _, v in ipairs(arr) do if v == value then return true end end return false end,
    }
    ArcadiaRefillablePropane, ArcadiaRefillablePropaneServer = nil, nil
    MSP_ChunkSquareDispatch = nil
    SandboxVars = { DAMN = { AllowB = true }, rSemiTruck = {} }
end

function isServer() return true end
function isClient() return false end
function getActivatedMods() return { contains = function(_, id) return activeMods[id] == true end } end
function getFilenameOfClosure(fn)
    local source = debug.getinfo(fn, "S").source
    return (source:gsub("^@", ""):gsub("\\", "/"))
end
local realGetFilenameOfClosure = getFilenameOfClosure
function ZombRand(n) rngState = (rngState * 1103515245 + 12345) % 2147483648; return rngState % n end
function ZombRandBetween(a, b) rngBetweenState = (rngBetweenState * 69069 + 1) % 4294967296; return a + rngBetweenState % (b - a) end
function getScriptManager() return { getVehicle = function() return {} end } end
function getServerOptions() return { getOptionByName = function() return { getValue = function() return "Muldraugh, KY" end } end } end
function string.split(s, sep)
    local out = {}
    for part in string.gmatch(s, "([^" .. sep .. "]+)") do out[#out + 1] = part end
    return out
end
Calendar = { getInstance = function() return { getTimeInMillis = function() return 1000 end } end }
ModData = {
    getOrCreate = function(key) modDataStore[key] = modDataStore[key] or {}; return modDataStore[key] end,
    transmit = function(key) log("transmit " .. key) end,
}
IsoDirections = {
    S = "S", N = "N", E = "E", W = "W",
    fromString = function(s) return "dir:" .. s end, getRandom = function() return "dir:random" end,
}
function addVehicleDebug(script, dir, skin, square)
    log(string.format("vehicle %s %s %s at %d,%d,%d sq#%d", script, tostring(dir), tostring(skin), square.x, square.y,
        square.z, square.id))
    return {}
end
MapObjects = {
    OnLoadWithSprite = function(names, fn)
        for _, name in ipairs(names) do
            spriteCallbacks[name] = spriteCallbacks[name] or {}
            table.insert(spriteCallbacks[name], fn)
        end
    end,
}
local function newObject(sprite, opts)
    opts = opts or {}
    local object = { sprite = sprite, worldItem = opts.worldItem, modData = {}, transmits = 0 }
    function object:getSprite()
        if not self.sprite then return nil end
        -- 專用伺服器上地上物品的 sprite 是空殼，沒有名稱（IsoWorldInventoryObject.java:93,379,416）
        local name = not self.worldItem and self.sprite or nil
        return { getName = function() return name end }
    end
    function object:getModData() return self.modData end
    function object:transmitModData() self.transmits = self.transmits + 1 end
    function object:getObjectIndex() return 0 end
    return object
end

local nextSquareId = 0
local function newSquare(x, y, z, objects, opts)
    opts = opts or {}
    nextSquareId = nextSquareId + 1
    local square = { id = nextSquareId, x = x, y = y, z = z, objects = objects, intersecting = opts.intersecting,
        xCalls = 0, yCalls = 0 }
    function square:getX() self.xCalls = self.xCalls + 1; count("getX"); return self.x end
    function square:getY() self.yCalls = self.yCalls + 1; count("getY"); return self.y end
    function square:getZ() return self.z end
    function square:getObjects() counters.getObjects = counters.getObjects + 1; return javaList(self.objects) end
    function square:isVehicleIntersecting() count("isVehicleIntersecting"); return self.intersecting == true end
    function square:getVehicleContainer() counters.vehicleContainer = counters.vehicleContainer + 1; return opts.vehicle end
    for _, object in ipairs(objects) do object.getSquare = function() return square end end
    return square
end

-- IsoChunk：只暴露引擎給 Lua 的方法（IsoChunk.java:3103-3109 getMinLevel／getMaxLevel、:3154-3161 getGridSquare）；
-- wx／wy 是 instance field，Kahlua 不暴露，Lua 端讀不到
local function newChunk(wx, wy, minLevel, maxLevel)
    local grid = {}
    local chunk = {}
    function chunk:getGridSquare(x, y, z)
        count("getGridSquare")
        if x < 0 or x > 7 or y < 0 or y > 7 or z < minLevel or z > maxLevel then return nil end
        return grid[z .. ":" .. x .. ":" .. y]
    end
    function chunk:getMinLevel() count("getMinLevel"); return minLevel end
    function chunk:getMaxLevel() count("getMaxLevel"); return maxLevel end
    local function put(square)
        local lx, ly = square.x - wx * 8, square.y - wy * 8
        assert(lx >= 0 and lx < 8 and ly >= 0 and ly < 8 and square.z >= minLevel and square.z <= maxLevel)
        grid[square.z .. ":" .. lx .. ":" .. ly] = square
    end
    return chunk, grid, put, minLevel, maxLevel
end

-- IsoChunk.doLoadGridsquare 的一格
local function loadSquare(square)
    if #square.objects == 0 then return end
    local snapshot = {}
    for i, object in ipairs(square.objects) do snapshot[i] = object end
    for _, object in ipairs(snapshot) do
        if not object.worldItem and object.sprite then
            for _, fn in ipairs(spriteCallbacks[object.sprite] or {}) do fn(object) end
        end
    end
    trigger(Events.LoadGridsquare, square)
end

-- IsoChunk.doLoadGridsquare 整個 chunk：格子迴圈（:3796-3835）後觸發 LoadChunk（:3965）
local function loadChunk(c)
    for z = c.minLevel, c.maxLevel do
        for x = 0, 7 do
            for y = 0, 7 do
                local square = c.grid[z .. ":" .. x .. ":" .. y]
                if square then loadSquare(square) end
            end
        end
    end
    if type(Events.LoadChunk) == "table" then trigger(Events.LoadChunk, c.chunk) end
end

local function makeChunk(wx, wy, minLevel, maxLevel, squares)
    local chunk, grid, put = newChunk(wx, wy, minLevel, maxLevel)
    for _, square in ipairs(squares or {}) do put(square) end
    return { chunk = chunk, grid = grid, minLevel = minLevel, maxLevel = maxLevel }
end

-- 單一格子自成一個 chunk 載入（固定情境用）
local function chunkOf(square)
    return makeChunk(square.x // 8, square.y // 8, math.min(0, square.z), math.max(0, square.z), { square })
end

-- 依伺服器載入順序：shared → server（Mods= 順序 damnlib #3、rSemiTruck #68、Arcadia #112、本 MOD #118）
local function boot(modList, toggles, opts)
    opts = opts or {}
    resetEnv(modList)
    getFilenameOfClosure = realGetFilenameOfClosure
    local present = {}
    for _, id in ipairs(modList) do present[id] = true end
    function require(name)
        if name == "ArcadiaRefillablePropane_Shared" then return ArcadiaRefillablePropane end
        if name == "Patches/MSP_ChunkSquareDispatch" then
            if opts.noDispatchModule then return nil end
            return loadPatch(PATCH.dispatch)
        end
        error("unexpected require " .. name)
    end
    if present.ArcadiaRefillablePropaneTanks_B42 then dofile(UP.arcadiaShared) end
    local upstreamOrder = opts.semiUpstreamFirst and { "rSemiTruck", "damnlib" } or { "damnlib", "rSemiTruck" }
    for _, id in ipairs(upstreamOrder) do
        if present[id] then dofile(id == "damnlib" and UP.damn or UP.semi) end
    end
    if present.ArcadiaRefillablePropaneTanks_B42 then dofile(UP.arcadiaServer) end
    if opts.beforePatches then opts.beforePatches() end
    if not opts.noPatches then
        loadPatch(PATCH.arcadia)
        if opts.semiPatchFirst then loadPatch(PATCH.semi); loadPatch(PATCH.damn) else loadPatch(PATCH.damn); loadPatch(PATCH.semi) end
    end
    SandboxVars.MinidoracatServerPatchFor42 = toggles
    if opts.beforeBoot then opts.beforeBoot() end
    trigger(Events.OnGameBoot)
    trigger(Events.OnInitGlobalModData, false)
end

local ALL = { "damnlib", "rSemiTruck", "ArcadiaRefillablePropaneTanks_B42", "RavenCreekB42" }
local ON = { SlimArcadiaLoad = true, SlimDamnlibLoad = true, SlimSemiTruckLoad = true }
local OFF = { SlimArcadiaLoad = false, SlimDamnlibLoad = false, SlimSemiTruckLoad = false }

local function addDamnSpawns()
    if not (DAMN and DAMN.Spawns and DAMN.Spawns.add) then return end
    DAMN.Spawns:add("Base.A", 8000, 9000, { chance = 100 })
    DAMN.Spawns:add("Base.B", 8001, 9000, { chance = 50, sandboxVar = "AllowB" })
    DAMN.Spawns:add("Base.C", 8000, 9005, { chance = 100, modWhitelist = { "NotInstalled" } })
    DAMN.Spawns:add("Base.D", 8200, 9100, { chance = 100 }) -- 放在阻擋格測「稍後重試」
end

-- 同一批格子：全部目標、z=1 同座標、鄰格、同 x 異 y、重載、阻擋，外加大量非目標格子
local anchorSprite, bodySprite = "industry_02_64", "industry_02_65"
local function buildWorld(nonTargets)
    local squares = {}
    local function add(sq) squares[#squares + 1] = sq end
    local function plain() return { newObject("floors_exterior_street_01_0"), newObject("fixtures_counters_01_1") } end
    local targets = {
        { 8000, 9000 }, { 8001, 9000 }, { 8000, 9005 }, { 8002, 9000 }, { 8000, 9001 }, { 9999, 9000 },
        { 10670, 10411 }, { 12449, 4261 }, { 852, 12947 }, { 6499, 15337 }, { 6514, 15338 }, { 10671, 10411 },
        { 7777, 7777 }, -- 之後才登記的 damnlib 生成點
    }
    for _, t in ipairs(targets) do add(newSquare(t[1], t[2], 0, plain())) end
    add(newSquare(10670, 10411, 1, plain())) -- 上游不看 z
    add(newSquare(8200, 9100, 0, plain(), { intersecting = true }))
    add(newSquare(8200, 9100, 0, plain())) -- 同點重載，這次不阻擋
    add(newSquare(10670, 10411, 0, plain())) -- 已生成過的點重載
    add(newSquare(12449, 4261, 0, {})) -- 目標座標但沒有物件：引擎不觸發
    add(newSquare(500, 500, 0, { newObject(anchorSprite), newObject(bodySprite), newObject("industry_03_105") }))
    add(newSquare(501, 500, 0, { newObject(anchorSprite, { worldItem = true }) }))
    add(newSquare(502, 500, 0, { newObject("location_shop_gas2go_01_65"), newObject(nil) }))
    add(newSquare(503, 500, 0, { newObject("floors_01_1") }, { vehicle = { getScriptName = function() return "Base.Van" end } }))
    add(newSquare(500, 500, 0, { newObject(anchorSprite) })) -- 補充站格重載（新物件）
    for i = 1, nonTargets do
        local x, y = 20000 + (i * 7919) % 3000, 20000 + (i * 104729) % 3000
        local objects = {}
        for k = 1, 1 + i % 4 do objects[k] = newObject("walls_exterior_house_01_" .. ((i + k) % 64)) end
        add(newSquare(x, y, 0, objects))
    end
    return squares
end

local function storeOf()
    local store = {}
    for key, tbl in pairs(modDataStore) do
        for k, v in pairs(tbl) do store[#store + 1] = key .. "." .. k .. "=" .. tostring(v) end
    end
    table.sort(store)
    return store
end

local function run(toggles, modList, world, afterBoot)
    boot(modList or ALL, toggles, { beforePatches = addDamnSpawns })
    if afterBoot then afterBoot() end
    for i, square in ipairs(world) do
        if i == 13 and DAMN.Spawns and DAMN.Spawns.add then DAMN.Spawns:add("Base.Late", 7777, 7777, { chance = 100 }) end
        loadChunk(chunkOf(square))
    end
    local depots = {}
    for _, square in ipairs(world) do
        for _, object in ipairs(square.objects) do
            local md = object.modData
            if md.ArcadiaRefillablePropane ~= nil then
                depots[#depots + 1] = string.format("%d,%d %s amount=%s ver=%s rev=%s tx=%d", square.x, square.y,
                    object.sprite, tostring(md.ArcadiaRefillablePropaneAmount), tostring(md.ArcadiaRefillablePropaneVersion),
                    tostring(md.ArcadiaRefillablePropaneRevision), object.transmits)
            end
        end
    end
    return { effects = effects, depots = depots, store = storeOf() }
end

local function same(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end
local function sorted(list)
    local copy = {}
    for i, v in ipairs(list) do copy[i] = v end
    table.sort(copy)
    return copy
end
-- 同一次模擬中 square.id 由建構順序決定，effects 內的 sq# 在不同次模擬間可比；比較 effects 前把它當成格子身分保留
local function freshWorld(n) nextSquareId = 0; return buildWorld(n) end

-- ===== 上游回呼追蹤：以 debug hook 記下「上游 LoadGridsquare 匿名函式」每次被呼叫時收到的格子 =====
local function upstreamLine(path)
    local n = 0
    for line in readFile(path):gmatch("[^\n]*\n?") do
        n = n + 1
        if line:find("Events.LoadGridsquare.Add(function(square)", 1, true) then return n end
    end
    error("上游 LoadGridsquare 註冊行不見了：" .. path)
end
local UPSTREAM_TAG = {
    ["@" .. UP.damn .. ":" .. upstreamLine(UP.damn)] = "damn",
    ["@" .. UP.semi .. ":" .. upstreamLine(UP.semi)] = "semi",
}
local UPSTREAM_LINES = { [upstreamLine(UP.damn)] = true, [upstreamLine(UP.semi)] = true }
local semiTables = setmetatable({}, { __mode = "k" })
local function semiTable(fn)
    if semiTables[fn] == nil then
        local i = 1
        while true do
            local name, value = debug.getupvalue(fn, i)
            if not name then break end
            if name == "guaranteedSpawns" then semiTables[fn] = value; break end
            i = i + 1
        end
    end
    return semiTables[fn]
end
local function isHit(tag, fn, square)
    if tag == "damn" then
        return DAMN.Spawns.byLocation[tostring(square.x) .. "_" .. tostring(square.y)] ~= nil
    end
    for _, spawn in ipairs(semiTable(fn)) do
        if spawn[2] == square.x and spawn[3] == square.y then return true end
    end
    return false
end
local trace
local function traceHook()
    local info = debug.getinfo(2, "S")
    if not (info and UPSTREAM_LINES[info.linedefined]) then return end
    local tag = UPSTREAM_TAG[info.source .. ":" .. info.linedefined]
    if not tag then return end
    local _, square = debug.getlocal(2, 1)
    if type(square) ~= "table" or not square.id then return end -- rSemiTruck 探針格子
    trace[#trace + 1] = { tag = tag, id = square.id, hit = isHit(tag, debug.getinfo(2, "f").func, square) }
end
-- tag 的呼叫序列（square id）；hitsOnly 只留座標在上游表內的
local function calls(t, tag, hitsOnly)
    local out = {}
    for _, e in ipairs(t) do
        if e.tag == tag and (e.hit or not hitsOnly) then out[#out + 1] = e.id end
    end
    return out
end

-- ===== 隨機世界：多層、nil 格、無物件格、跨 chunk 邊界的點、同 (x,y) 多層、重載、執行中登記的點 =====
local SEMI_POINTS
do
    boot({ "rSemiTruck", "RavenCreekB42" }, OFF)
    SEMI_POINTS = {}
    for _, spawn in ipairs(semiTable(Events.LoadGridsquare.list[1])) do SEMI_POINTS[#SEMI_POINTS + 1] = { spawn[2], spawn[3] } end
end

local function worldSpec(seed)
    math.randomseed(seed)
    local R = math.random
    local spec = { damn = {}, loads = {}, adds = {} }
    local wx0, wy0 = 1000 + R(0, 50), 1100 + R(0, 50)
    local function edge() return ({ 0, 7, R(0, 7) })[R(1, 3)] end
    local function clusterPoint()
        return (wx0 + R(0, 2)) * 8 + edge(), (wy0 + R(0, 2)) * 8 + edge()
    end
    for i = 1, R(3, 10) do
        local x, y = clusterPoint()
        spec.damn[i] = { x = x, y = y, chance = ({ 100, 100, 50 })[R(1, 3)] }
    end
    local bx, by = (wx0 + 1) * 8, (wy0 + 1) * 8 + R(0, 7) -- 同一列跨 chunk 邊界的兩個點
    spec.damn[#spec.damn + 1] = { x = bx - 1, y = by, chance = 100 }
    spec.damn[#spec.damn + 1] = { x = bx, y = by, chance = 100 }
    local chunks = {}
    for dx = 0, 2 do for dy = 0, 2 do chunks[#chunks + 1] = { wx0 + dx, wy0 + dy } end end
    for _ = 1, 3 do
        local p = SEMI_POINTS[R(1, #SEMI_POINTS)]
        chunks[#chunks + 1] = { p[1] // 8, p[2] // 8 }
    end
    for _ = 1, 3 do chunks[#chunks + 1] = { 3000 + R(0, 100), 3000 + R(0, 100) } end
    for i = 1, R(15, 30) do
        local c = chunks[R(1, #chunks)]
        local minLevel = R(1, 3) == 1 and -1 or 0
        local maxLevel = R(0, 3)
        local cells = {}
        local hole = R(1, 8) -- 1：(0,0,0) 為 nil；2：整層 z=0 為 nil；3：每層 x=0 整列為 nil；4：每層 y=0 整行為 nil
        for z = minLevel, maxLevel do
            for x = 0, 7 do
                for y = 0, 7 do
                    local r = R()
                    local present = z == 0 and r > 0.1 or z ~= 0 and r > 0.5
                    if z == 0 and (hole == 2 or hole == 1 and x == 0 and y == 0) then present = false end
                    if hole == 3 and x == 0 or hole == 4 and y == 0 then present = false end
                    if present then
                        cells[#cells + 1] = { z = z, x = x, y = y, objects = R(1, 5) == 1 and 0 or R(1, 3),
                            intersecting = R(1, 8) == 1 }
                    end
                end
            end
        end
        spec.loads[i] = { wx = c[1], wy = c[2], minLevel = minLevel, maxLevel = maxLevel, cells = cells }
        if R(1, 5) == 1 then
            local x, y = clusterPoint()
            spec.adds[i] = { x = x, y = y }
        end
    end
    return spec
end

local function buildLoad(load)
    local squares = {}
    for _, cell in ipairs(load.cells) do
        local objects = {}
        for k = 1, cell.objects do objects[k] = newObject("floors_random_" .. k) end
        squares[#squares + 1] = newSquare(load.wx * 8 + cell.x, load.wy * 8 + cell.y, cell.z, objects,
            { intersecting = cell.intersecting })
    end
    return makeChunk(load.wx, load.wy, load.minLevel, load.maxLevel, squares)
end

local function runSpec(spec, modList, toggles, opts)
    opts = opts or {}
    nextSquareId = 0
    boot(modList, toggles, {
        noPatches = opts.noPatches,
        noDispatchModule = opts.noDispatchModule,
        beforePatches = function()
            if DAMN.Spawns and DAMN.Spawns.add then
                for i, p in ipairs(spec.damn) do DAMN.Spawns:add("Base.P" .. i, p.x, p.y, { chance = p.chance }) end
            end
            if opts.beforePatches then opts.beforePatches() end
        end,
        beforeBoot = opts.beforeBoot,
    })
    trace = {}
    debug.sethook(traceHook, "c")
    for i, load in ipairs(spec.loads) do
        local add = spec.adds[i]
        if add and DAMN.Spawns and DAMN.Spawns.add then DAMN.Spawns:add("Base.Runtime" .. i, add.x, add.y, { chance = 100 }) end
        loadChunk(buildLoad(load))
    end
    debug.sethook()
    return { trace = trace, effects = effects, store = storeOf(), printed = printed,
        loadGridsquare = #Events.LoadGridsquare.list,
        loadChunk = type(Events.LoadChunk) == "table" and #Events.LoadChunk.list or 0 }
end

-- 同一世界的差分：上游收到的「目標格子」序列（同一格子物件、同順序）、副作用、ModData 全同
local SEMI_MODS = { "rSemiTruck", "RavenCreekB42" }
local function diff(base, other, exactAll)
    local problems = {}
    for _, tag in ipairs({ "damn", "semi" }) do
        local want = calls(base.trace, tag, not exactAll)
        local got = calls(other.trace, tag, not exactAll)
        if not same(want, got) then problems[#problems + 1] = tag .. " 上游呼叫序列不同（" .. #want .. " vs " .. #got .. "）" end
        if not exactAll then
            for _, e in ipairs(other.trace) do
                if e.tag == tag and not e.hit then problems[#problems + 1] = tag .. " 非目標格子進了上游"; break end
            end
        end
    end
    return problems
end
local function differential(seed)
    local spec = worldSpec(seed)
    local problems = {}
    local function add(list, prefix) for _, p in ipairs(list) do problems[#problems + 1] = prefix .. p end end
    for _, mods in ipairs({ { "damnlib" }, SEMI_MODS, ALL }) do
        local base = runSpec(spec, mods, OFF)
        local other = runSpec(spec, mods, ON)
        add(diff(base, other, false), "[" .. mods[1] .. (#mods > 2 and "+" or "") .. "] ")
        local single = #mods <= 2
        -- 單一上游時副作用順序也要相同；兩個上游同時在時，同 chunk 內兩者的相對順序本來就會改變（見補丁檔頭）
        local be, oe = base.effects, other.effects
        if not single then be, oe = sorted(be), sorted(oe) end
        if not same(be, oe) then problems[#problems + 1] = "[" .. mods[1] .. "] 生成車輛／傳送序列不同" end
        if not same(base.store, other.store) then problems[#problems + 1] = "[" .. mods[1] .. "] 全域 ModData 不同" end
    end
    return problems, spec
end

-- 1. 行為等價：同一批格子，上游原樣 vs 三補丁全開
rawPrint("情境一：行為等價（上游原樣 vs 補丁）")
local base = run(OFF, ALL, freshWorld(300))
local patched = run(ON, ALL, freshWorld(300))
check("有生成車輛（情境有效）", #base.effects >= 5)
check("生成車輛與 ModData 傳送序列相同", same(base.effects, patched.effects))
check("全域 ModData 內容相同", same(base.store, patched.store))
check("補充站 modData 與傳送次數相同", #base.depots >= 4 and same(base.depots, patched.depots))
check("三補丁各印一行 installed", printedMatching("installed (") == 3 and printedMatching("spawn index installed") == 2
    and printedMatching("chunk dispatch installed") == 1)
check("damnlib／rSemiTruck 不再有逐格 LoadGridsquare、改由兩個 LoadChunk 回呼處理",
    #Events.LoadGridsquare.list == 0 and #Events.LoadChunk.list == 2)
for _, line in ipairs(base.effects) do rawPrint("        base: " .. line) end
for _, line in ipairs(base.depots) do rawPrint("        depot: " .. line) end

-- 2. 非目標格子不進上游
rawPrint("情境二：非目標格子不進上游")
local SPECIAL = 23 -- buildWorld 前 23 格是目標／邊界格，之後全是非目標格子
local function coordCalls(world)
    local x, y = 0, 0
    for i, sq in ipairs(world) do if i > SPECIAL then x = x + sq.xCalls; y = y + sq.yCalls end end
    return x, y
end
local world = freshWorld(500)
run(OFF, { "damnlib" }, world)
local _, yBase = coordCalls(world)
world = freshWorld(500)
run(ON, { "damnlib" }, world)
local xPatched, yPatched = coordCalls(world)
-- 每格自成一個 chunk，getX 是分派器每個 chunk 取一次 chunk 座標
check("damnlib：非目標 chunk 只取一次 getX、不呼叫 getY、零 LoadGridsquare 分派（上游每格都分派＋組鍵）",
    yBase == 500 and yPatched == 0 and xPatched == 500 and (counters["dispatch:LoadGridsquare"] or 0) == 0)

world = freshWorld(500)
run(OFF, SEMI_MODS, world)
_, yBase = coordCalls(world)
world = freshWorld(500)
run(ON, SEMI_MODS, world)
xPatched, yPatched = coordCalls(world)
check("rSemiTruck：非目標 chunk 不進上游、零 LoadGridsquare 分派", yBase == 500 and yPatched == 0 and xPatched == 500
    and (counters["dispatch:LoadGridsquare"] or 0) == 0)
check("rSemiTruck：探針拿到 11＋2（Raven Creek）筆", printedMatching("(13 guaranteed spawn locations") == 1)

run(OFF, { "ArcadiaRefillablePropaneTanks_B42" }, freshWorld(500))
local objectsBase, vehicleBase = counters.getObjects, counters.vehicleContainer
run(ON, { "ArcadiaRefillablePropaneTanks_B42" }, freshWorld(500))
check("Arcadia：不再逐格 getObjects／找車", objectsBase >= 500 and vehicleBase >= 500
    and counters.getObjects == 0 and counters.vehicleContainer == 0)
check("Arcadia：上游 LoadGridsquare 已移除、無其他 LoadGridsquare", #Events.LoadGridsquare.list == 0)

-- 3. 開關與軟依賴
rawPrint("情境三：開關、軟依賴、形狀不符、攔截失敗")
boot({}, ON)
check("三個上游都沒裝：零註冊、零 log", #Events.OnGameBoot.list == 0 and #Events.LoadGridsquare.list == 0
    and #Events.LoadChunk.list == 0 and #printed == 0)
boot(ALL, OFF, { beforePatches = addDamnSpawns })
check("開關全關：三行 disabled、上游逐格註冊原樣、無 LoadChunk", printedMatching("disabled by sandbox option") == 3
    and #Events.LoadGridsquare.list == 3 and #Events.LoadChunk.list == 0)
boot({ "ArcadiaRefillablePropaneTanks_B42", "B42FRUsedCarsAnimAlpha" }, ON)
check("Filibuster 啟用：Arcadia 補丁不裝、上游原樣", printedMatching("Filibuster") == 1 and #Events.LoadGridsquare.list == 1)
boot({ "rSemiTruck" }, ON)
check("rSemiTruck：Add 在 OnInitGlobalModData 後換回、上游改走 LoadChunk", #Events.LoadGridsquare.list == 0
    and #Events.LoadChunk.list == 1)
local plainFn = function() end
Events.LoadGridsquare.Add(plainFn)
check("之後其他 MOD 的註冊照常", Events.LoadGridsquare.list[1] == plainFn)
boot({ "damnlib" }, ON)
Events.LoadGridsquare.Add(plainFn)
check("damnlib：Add 換回、上游改走 LoadChunk、之後的註冊照常", Events.LoadGridsquare.list[1] == plainFn
    and #Events.LoadGridsquare.list == 1 and #Events.LoadChunk.list == 1)
boot({ "rSemiTruck", "damnlib" }, ON, { beforePatches = function()
    Events.OnInitGlobalModData.list = {} -- 模擬上游改了註冊方式
end })
check("沒攔到上游：兩個各印一行 NOT installed", printedMatching("registration not seen") == 2
    and printedMatching("NOT installed") == 2)
boot({ "damnlib" }, ON, { beforePatches = function() DAMN.Spawns.checkSquare = nil end })
check("damnlib 形狀不符：印一行 NOT installed、上游逐格註冊原樣", printedMatching("damnlib] spawn index NOT installed") == 1
    and printedMatching("NOT installed") == 1 and #Events.LoadGridsquare.list == 1 and #Events.LoadChunk.list == 0)

-- 3b. 各種失敗回退，在隨機世界裡與上游原樣逐項比對（上游每次呼叫都比，含非目標格子）
local function breakSemiTable()
    for _, fn in ipairs(Events.OnInitGlobalModData.list) do
        local i = 1
        while true do
            local name, value = debug.getupvalue(fn, i)
            if not name then break end
            if name == "guaranteedSpawns" then value[#value + 1] = { "Base.Odd", "not-a-number", 1, 0, "S" } end
            i = i + 1
        end
    end
end
local FALLBACKS = {
    { name = "攔截失敗（getFilenameOfClosure 拋錯）", toggles = ON, beforeBoot = function()
        getFilenameOfClosure = function() error("boom") end
    end, expect = { ["registration not seen"] = 2 } },
    { name = "LoadChunk 不可用", toggles = ON, beforeBoot = function() rawset(Events, "LoadChunk", false) end,
        expect = { ["LoadChunk dispatch unavailable"] = 2 } },
    { name = "分派模組 require 失敗", toggles = ON, noDispatchModule = true,
        expect = { ["LoadChunk dispatch unavailable"] = 2 } },
    { name = "rSemiTruck 座標表形狀不符", toggles = ON, beforePatches = breakSemiTable, mods = SEMI_MODS,
        expect = { ["upstream shape changed"] = 1 } },
    { name = "沙盒開關關閉", toggles = OFF, expect = { ["disabled by sandbox option"] = 2 } },
}
for _, case in ipairs(FALLBACKS) do
    local ok, detail = true, ""
    for seed = 1, 5 do
        local spec = worldSpec(seed)
        local mods = case.mods or { "damnlib", "rSemiTruck", "RavenCreekB42" }
        local upstream = runSpec(spec, mods, nil, { noPatches = true, beforePatches = case.beforePatches })
        local fallback = runSpec(spec, mods, case.toggles, case)
        local problems = diff(upstream, fallback, true)
        if not same(upstream.effects, fallback.effects) then problems[#problems + 1] = "副作用不同" end
        if not same(upstream.store, fallback.store) then problems[#problems + 1] = "ModData 不同" end
        if fallback.loadChunk > 0 or fallback.loadGridsquare ~= upstream.loadGridsquare then problems[#problems + 1] = "註冊不同" end
        local notInstalled = 0
        for _, line in ipairs(fallback.printed) do if line:find("NOT installed", 1, true) then notInstalled = notInstalled + 1 end end
        for text, n in pairs(case.expect) do
            local seen = 0
            for _, line in ipairs(fallback.printed) do if line:find(text, 1, true) then seen = seen + 1 end end
            if seen ~= n or (case.toggles == ON and notInstalled ~= n) then problems[#problems + 1] = "log 行數不符：" .. text end
        end
        if #problems > 0 then ok, detail = false, " seed " .. seed .. "：" .. table.concat(problems, "；"); break end
    end
    check("回退＝上游原樣（上游呼叫、副作用、ModData、註冊、NOT installed 各一行）：" .. case.name .. detail, ok)
end

-- 3c. 任何組合下，OnInitGlobalModData 之後 Events.LoadGridsquare.Add 都必須正是引擎原本的函式，
-- 各上游的註冊由對的補丁接手（chunk＝改走 LoadChunk、square＝原樣逐格），之後別的 MOD 的註冊直達引擎
local DS = { "damnlib", "rSemiTruck", "RavenCreekB42" }
local BOTH = { damn = "chunk", semi = "chunk" }
local NEITHER = { damn = "square", semi = "square" }
local ADD_CASES = {
    { "只有 damnlib", { "damnlib" }, ON, {}, { damn = "chunk" } },
    { "只有 rSemiTruck", SEMI_MODS, ON, {}, { semi = "chunk" } },
    { "兩者（damnlib 補丁先載）", DS, ON, {}, BOTH },
    { "兩者（rSemiTruck 補丁先載）", DS, ON, { semiPatchFirst = true }, BOTH },
    { "兩者（rSemiTruck 上游先註冊）", DS, ON, { semiUpstreamFirst = true }, BOTH },
    { "兩者（rSemiTruck 上游先註冊、補丁先載）", DS, ON, { semiUpstreamFirst = true, semiPatchFirst = true }, BOTH },
    { "開關全關", DS, OFF, {}, NEITHER },
    { "只關 damnlib", DS, { SlimDamnlibLoad = false, SlimSemiTruckLoad = true }, {}, { damn = "square", semi = "chunk" } },
    { "只關 rSemiTruck", DS, { SlimDamnlibLoad = true, SlimSemiTruckLoad = false }, {}, { damn = "chunk", semi = "square" } },
    { "只關 rSemiTruck（rSemiTruck 補丁先載）", DS, { SlimDamnlibLoad = true, SlimSemiTruckLoad = false },
        { semiPatchFirst = true }, { damn = "chunk", semi = "square" } },
    { "攔截失敗", DS, ON, { beforeBoot = function() getFilenameOfClosure = function() error("boom") end end }, NEITHER },
    { "LoadChunk 不可用", DS, ON, { beforeBoot = function() rawset(Events, "LoadChunk", false) end }, NEITHER },
    { "分派模組 require 失敗", DS, ON, { noDispatchModule = true }, NEITHER },
    { "rSemiTruck 座標表形狀不符", DS, ON, { beforePatches = breakSemiTable }, { damn = "chunk", semi = "square" } },
    { "上游沒有註冊（改了註冊方式）", DS, ON, { beforePatches = function() Events.OnInitGlobalModData.list = {} end }, {} },
}
local function upstreamTagOf(fn)
    local source = debug.getinfo(fn, "S").source
    if source == "@" .. UP.damn then return "damn" end
    if source == "@" .. UP.semi then return "semi" end
end
local function addIdentityProblems()
    local problems = {}
    for _, case in ipairs(ADD_CASES) do
        local name, mods, toggles, opts, expect = table.unpack(case)
        boot(mods, toggles, opts)
        local event = Events.LoadGridsquare
        local perSquare, wantChunk = {}, 0
        for _, fn in ipairs(event.list) do
            local tag = upstreamTagOf(fn)
            if tag then perSquare[tag] = true end
        end
        for _, how in pairs(expect) do if how == "chunk" then wantChunk = wantChunk + 1 end end
        local chunkHandlers = type(Events.LoadChunk) == "table" and #Events.LoadChunk.list or 0
        local ok = event.Add == event.engineAdd and chunkHandlers == wantChunk
        for _, tag in ipairs({ "damn", "semi" }) do
            if (expect[tag] == "square") ~= (perSquare[tag] == true) then ok = false end
        end
        local later = function() end
        event.Add(later)
        if not ok or event.list[#event.list] ~= later then problems[#problems + 1] = name end
    end
    return problems
end
local addProblems = addIdentityProblems()
check(string.format("%d 種組合（單一上游、兩者不同載入順序、開關、各回退）：Add 最後是引擎原函式、註冊歸屬正確、之後的註冊直達引擎%s",
    #ADD_CASES, #addProblems > 0 and ("；失敗：" .. table.concat(addProblems, "、")) or ""), #addProblems == 0)

-- 4. damnlib：之後登記的點、byLocation 換表、checkSquare 回傳值、上游出錯不影響同 chunk 其他格
rawPrint("情境四：damnlib 索引維護與錯誤隔離")
boot({ "damnlib" }, ON, { beforePatches = addDamnSpawns })
local probe = newSquare(1, 1, 0, {})
check("非目標回傳 true（同原版）", DAMN.Spawns:checkSquare(probe) == true)
DAMN.Spawns:add("Base.Late", 4242, 4343, { chance = 100 })
loadChunk(chunkOf(newSquare(4242, 4343, 0, { newObject("x") })))
check("伺服器執行中才登記的點照樣生成", effects[#effects - 1] and effects[#effects - 1]:find("Base.Late", 1, true) ~= nil
    and effects[#effects - 1]:find("at 4242,4343", 1, true) ~= nil)
DAMN.Spawns.byLocation = {}
DAMN.Spawns:add("Base.New", 11, 12, { chance = 100 })
local before = #effects
loadChunk(chunkOf(newSquare(4242, 4343, 0, { newObject("x") })))
loadChunk(chunkOf(newSquare(11, 12, 0, { newObject("x") })))
check("byLocation 整張換掉：舊點不再命中、新點命中", #effects == before + 2 and effects[#effects - 1]:find("Base.New", 1, true) ~= nil)

local function errorWorld()
    nextSquareId = 0
    return makeChunk(600, 600, 0, 0, {
        newSquare(4801, 4802, 0, { newObject("x") }),
        newSquare(4803, 4804, 0, { newObject("x") }),
    })
end
local function errorRun(toggles)
    boot({ "damnlib" }, toggles, { beforePatches = function()
        DAMN.Spawns:add("Base.Err", 4801, 4802, { chance = 100, sandboxVar = "Missing" })
        DAMN.Spawns:add("Base.Ok", 4803, 4804, { chance = 100 })
    end })
    SandboxVars.DAMN = nil -- 上游 checkIfAllowed 對帶 sandboxVar 的點會 index nil 而出錯
    loadChunk(errorWorld())
    local vehicles = {}
    for _, line in ipairs(effects) do if line:find("^vehicle") then vehicles[#vehicles + 1] = line end end
    return vehicles
end
local errBase, errPatched = errorRun(OFF), errorRun(ON)
check("同 chunk 前一格上游出錯，後一格照樣生成（同原版逐格隔離）", #errBase == 1 and same(errBase, errPatched)
    and printedMatching("upstream LoadGridsquare handler failed") == 1)

-- 5. 隨機差分：同一世界，上游原樣 vs 補丁；每個上游收到的目標格子（同物件、同順序）、副作用、ModData 全同
rawPrint("情境五：隨機世界差分（多層、nil 格、無物件格、跨 chunk 邊界、重載、執行中登記的點）")
local SEEDS = 20
local function runDifferential()
    local failures, first = 0, nil
    local chunks = 0
    for seed = 1, SEEDS do
        local problems, spec = differential(seed)
        chunks = chunks + #spec.loads
        if #problems > 0 then
            failures = failures + 1
            first = first or ("seed " .. seed .. "：" .. table.concat(problems, "；"))
        end
    end
    return failures, first, chunks
end
local failures, first, chunkCount = runDifferential()
do
    -- 情境有效性：目標格子確實出現在多層、z=-1、(0,0,0) 為 nil 的 chunk 與執行中登記的點上
    local spec = worldSpec(7)
    local r = runSpec(spec, { "damnlib" }, OFF)
    local hitIds = calls(r.trace, "damn", true)
    check("隨機世界有效（seed 7 damnlib 目標格子呼叫 " .. #hitIds .. " 次）", #hitIds >= 3)
end
check(string.format("隨機差分 %d 個世界、%d 次 chunk 載入：damnlib、rSemiTruck、三者同時皆等價%s", SEEDS, chunkCount,
    first and ("；首個失敗 " .. first) or ""), failures == 0)

-- 6. 每 chunk 的 Java 呼叫替身計數（全滿 64 格、單層、無目標：正式服絕大多數 chunk 的樣子）
rawPrint("情境六：每 chunk Java 呼叫替身計數（64 格全有物件、無目標點）")
local function fullChunk(wx, wy)
    local squares = {}
    for x = 0, 7 do for y = 0, 7 do squares[#squares + 1] = newSquare(wx * 8 + x, wy * 8 + y, 0, { newObject("floor") }) end end
    return makeChunk(wx, wy, 0, 0, squares)
end
local function callsPerChunk(toggles, noPatches)
    boot({ "damnlib", "rSemiTruck", "RavenCreekB42" }, toggles, { beforePatches = addDamnSpawns, noPatches = noPatches })
    counters = { vehicleContainer = 0, getObjects = 0 }
    for i = 1, 10 do loadChunk(fullChunk(4000 + i, 4000)) end
    local c = {}
    for k, v in pairs(counters) do c[k] = v / 10 end
    c.java = (c.getX or 0) + (c.getY or 0) + (c.getObjects or 0) + (c.getGridSquare or 0) + (c.getMinLevel or 0) + (c.getMaxLevel or 0)
    return c
end
local up, now = callsPerChunk(nil, true), callsPerChunk(ON)
rawPrint(string.format("        上游原樣：LoadGridsquare 分派 %d、LoadChunk 分派 %d、Java 方法呼叫 %d",
    up["dispatch:LoadGridsquare"] or 0, up["dispatch:LoadChunk"] or 0, up.java))
rawPrint(string.format("        補丁　　：LoadGridsquare 分派 %d、LoadChunk 分派 %d、Java 方法呼叫 %d",
    now["dispatch:LoadGridsquare"] or 0, now["dispatch:LoadChunk"] or 0, now.java))
check("補丁：非目標 chunk 零 LoadGridsquare 分派、每個補丁每 chunk 至多 2 次 Java 呼叫",
    (now["dispatch:LoadGridsquare"] or 0) == 0 and now["dispatch:LoadChunk"] == 2 and now.java <= 4)

-- 7. 突變：分派器與索引的錯誤必須被隨機差分抓到
if arg and arg[1] == "--mutants" then
    rawPrint("\n突變測試（每個突變都必須讓隨機差分失敗）")
    local MUTANTS = {
        { name = "z 由高到低", file = PATCH.dispatch,
            from = "for z = chunk:getMinLevel(), chunk:getMaxLevel() do\n            for i = 1, #points, 2 do",
            to = "for z = chunk:getMaxLevel(), chunk:getMinLevel(), -1 do\n            for i = 1, #points, 2 do" },
        { name = "z 從 0 起（漏地下層）", file = PATCH.dispatch,
            from = "for z = chunk:getMinLevel(), chunk:getMaxLevel() do\n            for i = 1, #points, 2 do",
            to = "for z = 0, chunk:getMaxLevel() do\n            for i = 1, #points, 2 do" },
        { name = "同層點位倒序（x／y 順序錯）", file = PATCH.dispatch,
            from = "for i = 1, #points, 2 do", to = "for i = #points - 1, 1, -2 do" },
        { name = "先 y 後 x", file = PATCH.dispatch,
            from = "for x = 0, 7 do\n            local column = columns[x]\n            if column then\n                for y = 0, 7 do\n                    if column[baseY + y] then",
            to = "for y = 0, 7 do\n            for x = 0, 7 do\n                local column = columns[x]\n                if column then\n                    if column[baseY + y] then" },
        { name = "漏掉「有物件」條件", file = PATCH.dispatch,
            from = "if square and not square:getObjects():isEmpty() then", to = "if square then" },
        { name = "chunk x 座標不扣 anchor 的 chunk 內偏移", file = PATCH.dispatch,
            from = "local baseX = anchor:getX() - ax", to = "local baseX = anchor:getX()" },
        { name = "chunk y 座標不扣 anchor 的 chunk 內偏移", file = PATCH.dispatch,
            from = "local baseY = anchor:getY() - ay", to = "local baseY = anchor:getY()" },
        { name = "執行中登記的點不重建索引", file = PATCH.damn,
            from = "indexedFrom = nil\n        return originalAdd(...)", to = "return originalAdd(...)" },
        { name = "每個補丁各自暫換／還原 Add（舊版串鏈）", file = PATCH.dispatch,
            from = "    if M.restore then return end\n", to = "" },
    }
    for _, mutant in ipairs(MUTANTS) do
        MUTATION = mutant
        local ok, killed, why = pcall(function()
            local addBroken = addIdentityProblems()
            if #addBroken > 0 then return true, "Add 組合失敗：" .. table.concat(addBroken, "、") end
            local f, firstProblem = runDifferential()
            return f > 0, firstProblem
        end)
        MUTATION = nil
        check("突變被抓到：" .. mutant.name .. (why and ("（" .. tostring(why):sub(1, 160) .. "）") or ""), ok and killed)
    end
end

-- 8. 離線每 chunk 成本
if arg and arg[1] == "--bench" then
    rawPrint("\n離線每 chunk 成本（標準 Lua 5.x、假 chunk 64 格全有物件、無目標點；已扣除假引擎本身的迴圈成本）")
    rawPrint("只比 Lua 端工作量：不含 Kahlua 反射呼叫與引擎逐 callback 分派的成本，不能換算成正式服收益")
    local N, REPEAT, ROUNDS = 500, 20, 5
    local batch = {}
    for i = 1, N do batch[i] = fullChunk(5000 + i % 50, 5000 + i // 50) end
    local function timed(modList, toggles, noPatches)
        local best = math.huge
        for _ = 1, ROUNDS do
            boot(modList, toggles, { beforePatches = addDamnSpawns, noPatches = noPatches })
            collectgarbage("collect")
            local t0 = os.clock()
            for _ = 1, REPEAT do
                for _, c in ipairs(batch) do loadChunk(c) end
            end
            best = math.min(best, os.clock() - t0)
        end
        return best / (N * REPEAT) * 1e9
    end
    local floor = timed({}, ON)
    rawPrint(string.format("  假引擎底噪 %.0f ns/chunk（已扣除；%d 輪取最小值）", floor, ROUNDS))
    local function bench(label, modList)
        local upstream, slim = timed(modList, nil, true) - floor, timed(modList, ON) - floor
        rawPrint(string.format("  %-10s 上游 %8.0f ns/chunk → 補丁 %8.0f ns/chunk", label, upstream, slim))
    end
    bench("Arcadia", { "ArcadiaRefillablePropaneTanks_B42" })
    bench("damnlib", { "damnlib" })
    bench("rSemiTruck", SEMI_MODS)
    bench("三者合計", ALL)
end

rawPrint(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
