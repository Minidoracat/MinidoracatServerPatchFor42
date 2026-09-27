-- 離線測試：LoadGridsquare 瘦身三補丁（Arcadia／damnlib／rSemiTruck）。載入「未修改的」上游檔（本機 Steam 訂閱副本），
-- 以同一批假格子各跑一次「開關關閉＝上游原樣」與「開關開啟＝補丁」，逐項比對所有副作用，並證明非目標格子不進上游。
--   lua scripts/test_loadgridsquare_slim.lua           行為等價與邊界
--   lua scripts/test_loadgridsquare_slim.lua --bench   另跑離線逐格成本比較（標準 Lua，非 Kahlua、非實機）
-- 引擎模擬依 IsoChunk.doLoadGridsquare（IsoChunk.java:3799-3834）：只處理有物件的格子，先 MapObjects.loadGridSquare
-- （MapObjects.java:184-218，跳過地上物品）再依註冊順序觸發 LoadGridsquare（Event.java:52-64）。

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
}
for _, path in pairs(UP) do
    local fh = io.open(path, "r")
    if not fh then error("找不到上游副本（需本機已訂閱）：" .. path) end
    fh:close()
end

local pass, fail = 0, 0
local rawPrint, printed = print, {}
local function check(name, cond)
    if cond then pass = pass + 1; rawPrint("  PASS  " .. name) else fail = fail + 1; rawPrint("  FAIL  " .. name) end
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

local function newEvent()
    local event = { list = {} }
    event.Add = function(fn) if type(fn) == "function" then event.list[#event.list + 1] = fn end end
    event.Remove = function(fn)
        for i, f in ipairs(event.list) do if f == fn then table.remove(event.list, i); return end end
    end
    return event
end
local function trigger(event, ...)
    local n = 1
    while n <= #event.list do
        local fn = event.list[n]
        fn(...)
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

local effects, rngState, rngBetweenState, modDataStore, activeMods, spriteCallbacks, counters
local function log(line) effects[#effects + 1] = line end

local function resetEnv(modList)
    effects, printed, modDataStore, spriteCallbacks = {}, {}, {}, {}
    counters = { vehicleContainer = 0, getObjects = 0 }
    rngState, rngBetweenState = 12345, 777
    activeMods = {}
    for _, id in ipairs(modList) do activeMods[id] = true; activeMods["\\" .. id] = true end
    Events = setmetatable({}, { __index = function(t, k) local e = newEvent(); rawset(t, k, e); return e end })
    DAMN = {
        log = function() end, printList = function() end,
        itemIsInArray = function(_, arr, value) for _, v in ipairs(arr) do if v == value then return true end end return false end,
    }
    ArcadiaRefillablePropane, ArcadiaRefillablePropaneServer = nil, nil
    SandboxVars = { DAMN = { AllowB = true }, rSemiTruck = {} }
end

function isServer() return true end
function isClient() return false end
function getActivatedMods() return { contains = function(_, id) return activeMods[id] == true end } end
function getFilenameOfClosure(fn)
    local source = debug.getinfo(fn, "S").source
    return (source:gsub("^@", ""):gsub("\\", "/"))
end
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
    log(string.format("vehicle %s %s %s at %d,%d,%d", script, tostring(dir), tostring(skin), square.x, square.y, square.z))
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

local function newSquare(x, y, z, objects, opts)
    opts = opts or {}
    local square = { x = x, y = y, z = z, objects = objects, intersecting = opts.intersecting, xCalls = 0, yCalls = 0 }
    function square:getX() self.xCalls = self.xCalls + 1; return self.x end
    function square:getY() self.yCalls = self.yCalls + 1; return self.y end
    function square:getZ() return self.z end
    function square:getObjects() counters.getObjects = counters.getObjects + 1; return javaList(self.objects) end
    function square:isVehicleIntersecting() return self.intersecting == true end
    function square:getVehicleContainer() counters.vehicleContainer = counters.vehicleContainer + 1; return opts.vehicle end
    for _, object in ipairs(objects) do object.getSquare = function() return square end end
    return square
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

-- 依伺服器載入順序：shared → server（Mods= 順序 damnlib #3、rSemiTruck #68、Arcadia #112、本 MOD #118）
local function boot(modList, toggles, opts)
    opts = opts or {}
    resetEnv(modList)
    local present = {}
    for _, id in ipairs(modList) do present[id] = true end
    function require(name)
        if name == "ArcadiaRefillablePropane_Shared" then return ArcadiaRefillablePropane end
        error("unexpected require " .. name)
    end
    if present.ArcadiaRefillablePropaneTanks_B42 then dofile(UP.arcadiaShared) end
    if present.damnlib then dofile(UP.damn) end
    if present.rSemiTruck then dofile(UP.semi) end
    if present.ArcadiaRefillablePropaneTanks_B42 then dofile(UP.arcadiaServer) end
    if opts.beforePatches then opts.beforePatches() end
    dofile(PATCH.arcadia); dofile(PATCH.damn); dofile(PATCH.semi)
    SandboxVars.MinidoracatServerPatchFor42 = toggles
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

local function run(toggles, modList, world, afterBoot)
    boot(modList or ALL, toggles, { beforePatches = addDamnSpawns })
    if afterBoot then afterBoot() end
    for i, square in ipairs(world) do
        if i == 13 and DAMN.Spawns and DAMN.Spawns.add then DAMN.Spawns:add("Base.Late", 7777, 7777, { chance = 100 }) end
        loadSquare(square)
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
    local store = {}
    for key, tbl in pairs(modDataStore) do
        for k, v in pairs(tbl) do store[#store + 1] = key .. "." .. k .. "=" .. tostring(v) end
    end
    table.sort(store)
    return { effects = effects, depots = depots, store = store }
end

local function same(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end
local function freshWorld(n) return buildWorld(n) end

-- 1. 行為等價：同一批格子，上游原樣 vs 三補丁全開
rawPrint("情境一：行為等價（上游原樣 vs 補丁）")
local base = run(OFF, ALL, freshWorld(300))
local patched = run(ON, ALL, freshWorld(300))
check("有生成車輛（情境有效）", #base.effects >= 5)
check("生成車輛與 ModData 傳送序列相同", same(base.effects, patched.effects))
check("全域 ModData 內容相同", same(base.store, patched.store))
check("補充站 modData 與傳送次數相同", #base.depots >= 4 and same(base.depots, patched.depots))
check("三補丁各印一行 installed", printedMatching("installed (") == 2 and printedMatching("spawn index installed") == 2)
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
check("damnlib：非目標格子不組鍵、不呼叫 getY（上游每格都呼叫）", yBase == 500 and yPatched == 0 and xPatched == 500)

world = freshWorld(500)
run(OFF, { "rSemiTruck", "RavenCreekB42" }, world)
_, yBase = coordCalls(world)
world = freshWorld(500)
run(ON, { "rSemiTruck", "RavenCreekB42" }, world)
xPatched, yPatched = coordCalls(world)
check("rSemiTruck：非目標格子不進上游（上游每格都取座標再跑表）", yBase == 500 and yPatched == 0 and xPatched == 500)
check("rSemiTruck：探針拿到 11＋2（Raven Creek）筆", printedMatching("(13 guaranteed spawn locations)") == 1)

run(OFF, { "ArcadiaRefillablePropaneTanks_B42" }, freshWorld(500))
local objectsBase, vehicleBase = counters.getObjects, counters.vehicleContainer
run(ON, { "ArcadiaRefillablePropaneTanks_B42" }, freshWorld(500))
check("Arcadia：不再逐格 getObjects／找車", objectsBase >= 500 and vehicleBase >= 500
    and counters.getObjects == 0 and counters.vehicleContainer == 0)
check("Arcadia：上游 LoadGridsquare 已移除、無其他 LoadGridsquare", #Events.LoadGridsquare.list == 0)

-- 3. 開關與軟依賴
rawPrint("情境三：開關、軟依賴、形狀不符")
boot({}, ON)
check("三個上游都沒裝：零註冊、零 log", #Events.OnGameBoot.list == 0 and #Events.LoadGridsquare.list == 0 and #printed == 0)
boot(ALL, OFF, { beforePatches = addDamnSpawns })
check("開關全關：三行 disabled、上游註冊原樣", printedMatching("disabled by sandbox option") == 3
    and #Events.LoadGridsquare.list == 3)
boot({ "ArcadiaRefillablePropaneTanks_B42", "B42FRUsedCarsAnimAlpha" }, ON)
check("Filibuster 啟用：Arcadia 補丁不裝、上游原樣", printedMatching("Filibuster") == 1 and #Events.LoadGridsquare.list == 1)
boot({ "rSemiTruck" }, ON)
check("Add 在 OnInitGlobalModData 後換回", #Events.LoadGridsquare.list == 1)
local plainFn = function() end
Events.LoadGridsquare.Add(plainFn)
check("之後其他 MOD 的註冊照常", Events.LoadGridsquare.list[2] == plainFn)
boot({ "rSemiTruck" }, ON, { beforePatches = function()
    Events.OnInitGlobalModData.list = {} -- 模擬上游改了註冊方式
end })
check("沒攔到上游：印 NOT installed", printedMatching("registration not seen") == 1)
boot({ "damnlib" }, ON, { beforePatches = function() DAMN.Spawns.checkSquare = nil end })
check("damnlib 形狀不符：印 NOT installed", printedMatching("damnlib] spawn index NOT installed") == 1)

-- 4. damnlib：之後登記的點、byLocation 換表、checkSquare 回傳值
rawPrint("情境四：damnlib 索引維護")
boot({ "damnlib" }, ON, { beforePatches = addDamnSpawns })
local probe = newSquare(1, 1, 0, {})
check("非目標回傳 true（同原版）", DAMN.Spawns:checkSquare(probe) == true)
DAMN.Spawns:add("Base.Late", 4242, 4343, { chance = 100 })
trigger(Events.LoadGridsquare, newSquare(4242, 4343, 0, { newObject("x") }))
check("伺服器執行中才登記的點照樣生成", effects[#effects - 1] and effects[#effects - 1]:find("Base.Late", 1, true) ~= nil
    and effects[#effects - 1]:find("at 4242,4343", 1, true) ~= nil)
DAMN.Spawns.byLocation = {}
DAMN.Spawns:add("Base.New", 11, 12, { chance = 100 })
local before = #effects
trigger(Events.LoadGridsquare, newSquare(4242, 4343, 0, { newObject("x") }))
trigger(Events.LoadGridsquare, newSquare(11, 12, 0, { newObject("x") }))
check("byLocation 整張換掉：舊點不再命中、新點命中", #effects == before + 2 and effects[#effects - 1]:find("Base.New", 1, true) ~= nil)

-- 5. 離線逐格成本
if arg and arg[1] == "--bench" then
    rawPrint("\n離線逐格成本（標準 Lua 5.x、假格子、同一批 200000 格；已扣除假引擎本身的迴圈成本）")
    rawPrint("只比 Lua 端工作量：不含 Kahlua 反射呼叫與引擎逐 callback 分派的成本，不能換算成正式服收益")
    local N, ROUNDS = 200000, 5
    local batch = buildWorld(N)
    local function timed(modList, toggles)
        local best = math.huge
        for _ = 1, ROUNDS do
            boot(modList, toggles, { beforePatches = addDamnSpawns })
            collectgarbage("collect")
            local t0 = os.clock()
            for _, square in ipairs(batch) do loadSquare(square) end
            best = math.min(best, os.clock() - t0)
        end
        return best / N * 1e9
    end
    local floor = timed({}, ON)
    rawPrint(string.format("  假引擎底噪 %.0f ns/格（已扣除；%d 輪取最小值）", floor, ROUNDS))
    local function bench(label, modList)
        local up, patched = timed(modList, OFF) - floor, timed(modList, ON) - floor
        rawPrint(string.format("  %-10s 上游 %6.0f ns/格 → 補丁 %6.0f ns/格", label, up, patched))
    end
    bench("Arcadia", { "ArcadiaRefillablePropaneTanks_B42" })
    bench("damnlib", { "damnlib" })
    bench("rSemiTruck", { "rSemiTruck", "RavenCreekB42" })
    bench("三者合計", ALL)
end

rawPrint(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
