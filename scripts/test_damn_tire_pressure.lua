-- 離線測試：damnlib 胎壓補丁（MSP_DamnTirePressure）。載入「未修改的」上游（本機 Steam 訂閱副本）與本機遊戲的原版處理器：
--   damnlib 42.20      shared/DAMN_Shared.lua、DAMN_Helpers.lua、DAMN_Armor_Shared.lua、DAMN_Parts.lua，
--                      client/DAMN_Armor_Client.lua、DAMN_Client.lua（CTIS 補胎、OnEnterVehicle／OnPlayerUpdate）
--   85chevyCaprice 42.13、89defender 42.20、69charger 42.20 的 client/*_armor.lua（temp tire fix）
--   原版 media/lua/server/Vehicles/VehicleCommands.lua（42.22.2：setContainerContentAmount 要 UseMechanicsCheat）
-- 同一個 VM 同時當客戶端與伺服器：上游的 sendClientCommand 把 args 的副本交給伺服器端 OnClientCommand（原版處理器、補丁）。
-- 車與零件只有一份，省掉同步延遲：客戶端下一次 OnPlayerUpdate 看到的就是伺服器上的值。
-- 對照：「上游原樣」＝42.22.2 原版、沒有補丁；「管理員」＝原版處理器放行，等同 42.20 原版對所有人的行為。
--   lua scripts/test_damn_tire_pressure.lua             行為與邊界
--   lua scripts/test_damn_tire_pressure.lua --mutants   另對補丁植入錯誤，確認測試抓得到

local WS = "D:/SteamLibrary/steamapps/workshop/content/108600/"
local VANILLA = "D:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/server/Vehicles/VehicleCommands.lua"
local PATCH = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/server/Patches/damnlib/MSP_DamnTirePressure.lua"
local GAME_VERSION = 42 * 1000 + 22 -- 42.22.2：載入不高於它的最大版本目錄（ZomboidFileSystem.java:463-479）

-- 各上游的根目錄與預期載入的版本目錄
local DAMNLIB = { root = WS .. "3171167894/mods/damnlib/", version = "42.20" }
local CARS = {
    { mod = "85chevyCaprice", root = WS .. "3413704851/mods/85chevyCaprice/", version = "42.13", file = "client/85chevyCaprice_armor.lua",
        sample = "Base.85chevyCapriceSedan" },
    { mod = "89defender", root = WS .. "3570973322/mods/89defender/", version = "42.20", file = "client/89defender_armor.lua",
        sample = "Base.89defenderWolf" },
    { mod = "69charger", root = WS .. "3631989559/mods/69charger/", version = "42.20", file = "client/69charger_armor.lua",
        sample = "Base.69chargerRT" },
}
local DAMN_FILES = { "shared/DAMN_Shared.lua", "shared/DAMN_Helpers.lua", "shared/DAMN_Armor_Shared.lua", "shared/DAMN_Parts.lua",
    "client/DAMN_Armor_Client.lua", "client/DAMN_Client.lua" }
local CTIS_SCRIPT = "Base.92amgeneralM998" -- template runFlatTires＋centralTireInflation（92amgeneralM998.txt:300-301）
local TIRE_IDS = { "TireFrontLeft", "TireFrontRight", "TireRearLeft", "TireRearRight" }

local SOURCES = {}
local function readFile(path)
    if SOURCES[path] then return SOURCES[path] end
    local fh = io.open(path, "r")
    if not fh then error("找不到檔案（上游需本機已訂閱）：" .. path) end
    SOURCES[path] = fh:read("a")
    fh:close()
    return SOURCES[path]
end
local function luaPath(mod, rel) return mod.root .. mod.version .. "/media/lua/" .. rel end

local pass, fail = 0, 0
local rawPrint = print
local quiet = false
local function check(name, cond)
    if cond then pass = pass + 1 else fail = fail + 1 end
    if not quiet then rawPrint((cond and "  PASS  " or "  FAIL  ") .. name) end
end

local MUTATION
local function loadPatch()
    local source = readFile(PATCH)
    if MUTATION then
        local s, e = source:find(MUTATION.from, 1, true)
        if not s then error("突變片段不在原始碼中：" .. MUTATION.name) end
        source = source:sub(1, s - 1) .. MUTATION.to .. source:sub(e + 1)
    end
    assert(load(source, "@" .. PATCH))()
end
local function loadFile(path) assert(load(readFile(path), "@" .. path))() end

-- ===== 假引擎 =====
local handlers, byId, sent, transmits, printed, active, serverSide, time, nextId, currentPlayer
function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    printed[#printed + 1] = table.concat(parts, " ")
end
local function printedMatching(text)
    local n = 0
    for _, line in ipairs(printed) do if line:find(text, 1, true) then n = n + 1 end end
    return n
end

local function newEvents()
    handlers = {}
    Events = setmetatable({}, { __index = function(t, name)
        local list = {}
        handlers[name] = list
        local ev = {
            Add = function(fn) list[#list + 1] = fn end,
            Remove = function(fn) for i = #list, 1, -1 do if list[i] == fn then table.remove(list, i) end end end,
        }
        rawset(t, name, ev)
        return ev
    end })
end
local function fire(name, ...) for _, fn in ipairs(handlers[name] or {}) do fn(...) end end
local function count(name) return #(handlers[name] or {}) end

local function copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = copy(x) end
    return out
end

function isServer() return serverSide end
function isClient() return false end
function require() end
unpack = unpack or table.unpack
function ZombRand() return 0 end
function ZombRandBetween(a) return a end
function getActivatedMods() return { contains = function(_, id) return active[id] == true end } end
function getPlayer() return currentPlayer end
function getVehicleById(id) return type(id) == "number" and byId[math.floor(id)] or nil end -- (short) 截斷小數
function checkPermissions(player, capability) return player ~= nil and capability == "UseMechanicsCheat" and player.admin == true end
Capability = { UseMechanicsCheat = "UseMechanicsCheat" }
DebugType = { VehicleClientCommand = { debugln = function() end } }
Calendar = { getInstance = function() return { getTimeInMillis = function() return time end } end }

-- 網路：客戶端送出時記一筆，伺服器收到的是 args 的副本
local function serverReceive(player, module, command, args) fire("OnClientCommand", module, command, player, args) end
function sendClientCommand(player, module, command, args)
    sent[#sent + 1] = { module = module, command = command, args = copy(args) }
    serverReceive(player, module, command, copy(args))
end
local function sentCount(command)
    local n = 0
    for _, s in ipairs(sent) do if s.module == "vehicle" and s.command == (command or "setContainerContentAmount") then n = n + 1 end end
    return n
end

-- 零件：容器的 setContainerContentAmount 照 VehiclePart.java:387-399（不帶 force：夾在容量內、不小於 0）
local function newPart(vehicle, id, opts)
    opts = opts or {}
    local p = { id = id, vehicle = vehicle, container = opts.cap ~= nil, cap = opts.cap, amount = opts.amount or 0, condition = 100, md = {} }
    function p:getId() return self.id end
    function p:getVehicle() return self.vehicle end
    function p:getContainerContentAmount() return self.container and self.amount or 0 end
    function p:setContainerContentAmount(a)
        if self.container then self.amount = math.max(math.min(a, self.cap), 0) end
    end
    function p:getContainerCapacity() return self.container and self.cap or 0 end
    function p:getCondition() return self.condition end
    function p:setCondition(c) self.condition = c end
    function p:getInventoryItem() return nil end
    function p:getModData() return self.md end
    return p
end

-- 車：腳本裡的零件都在（裝甲程式會直接對保護件呼叫方法）；RFsystem／CTIsystem／airBrake 只在腳本有對應模板時才在
local SYSTEMS = { RFsystem = true, CTIsystem = true, airBrake = true }
local function newVehicle(script, opts)
    opts = opts or {}
    local v = { id = nextId, script = script, engine = opts.engine == true, parts = {}, generic = {} }
    nextId = nextId + 1
    for _, t in ipairs(TIRE_IDS) do
        v.parts[t] = newPart(v, t, { cap = opts.cap or 50, amount = (opts.tires or {})[t] or 35 })
    end
    v.parts.GasTank = newPart(v, "GasTank", { cap = 50, amount = 10 })
    if opts.rfs then v.parts.RFsystem = newPart(v, "RFsystem") end
    if opts.ctis then v.parts.CTIsystem = newPart(v, "CTIsystem") end
    function v:getId() return self.id end
    function v:getScript()
        local s = self.script
        return { getFullName = function() return s end, getName = function() return (s:gsub("^[^.]*%.", "")) end }
    end
    function v:getPartById(id)
        if self.parts[id] then return self.parts[id] end
        if SYSTEMS[id] then return nil end
        self.generic[id] = self.generic[id] or newPart(self, id)
        return self.generic[id]
    end
    function v:isEngineRunning() return self.engine end
    function v:isDriver(p) return p.vehicle == self and p.seat == 0 end
    function v:transmitPartModData(part) transmits[#transmits + 1] = { vehicle = self.id, part = part:getId() } end
    function v:getModData() return {} end
    byId[v.id] = v
    return v
end
local function ctisVehicle(tires, opts)
    opts = opts or {}
    return newVehicle(CTIS_SCRIPT, { rfs = opts.rfs ~= false, ctis = opts.ctis ~= false, engine = opts.engine ~= false, tires = tires, cap = opts.cap })
end
local function amount(v, tire) return v:getPartById(tire or "TireFrontLeft"):getContainerContentAmount() end

local function newPlayer(admin)
    local p = { admin = admin == true, vehicle = nil, seat = -1 }
    function p:getVehicle() return self.vehicle end
    function p:getUsername() return "tester" end
    return p
end
-- 伺服器先把人放上座位，客戶端才觸發 OnEnterVehicle
local function enter(p, v, seat)
    p.vehicle, p.seat, currentPlayer = v, seat or 0, p
    fire("OnEnterVehicle", p)
end
local function tick(p, n)
    for _ = 1, n or 1 do
        time = time + 100
        currentPlayer = p
        fire("OnPlayerUpdate", p)
    end
end

local ALL_MODS = { damnlib = true, ["85chevyCaprice"] = true, ["89defender"] = true, ["69charger"] = true, MinidoracatServerPatchFor42 = true }
local function reset(opts)
    opts = opts or {}
    for _, g in ipairs({ "DAMN", "KI5", "CAP85", "DEF89", "CHR69", "MSP_DamnTirePressure" }) do _G[g] = nil end
    newEvents()
    byId, sent, transmits, printed, time, nextId, currentPlayer = {}, {}, {}, {}, 1000000, 1, nil
    active = opts.mods or ALL_MODS
    serverSide = opts.server ~= false
    -- 伺服器：原版 server 檔先於各 MOD 的 server 檔（LuaManager.java:1151-1193）
    loadFile(VANILLA)
    if opts.patch ~= false then loadPatch() end
    -- 客戶端：damnlib shared → client，再來三台車的 client 檔
    if opts.upstream ~= false then
        for _, rel in ipairs(DAMN_FILES) do loadFile(luaPath(DAMNLIB, rel)) end
        for _, car in ipairs(CARS) do loadFile(luaPath(car, car.file)) end
    end
end

-- 一次「上游客戶端實際流程」：上車、跑 n 次 OnPlayerUpdate
local function drive(opts)
    reset({ patch = opts.patch })
    local v = opts.vehicle()
    local p = newPlayer(opts.admin)
    enter(p, v, opts.seat)
    tick(p, opts.ticks or 10)
    return v, p
end

local function setOf(list)
    local out = {}
    for _, x in ipairs(list) do out[x] = true end
    return out
end
local function sameSet(a, b)
    for k in pairs(a) do if not b[k] then return false end end
    for k in pairs(b) do if not a[k] then return false end end
    return true
end

local function versionDir(root)
    local best, bestKey
    local listing = io.popen('dir /b /ad "' .. root:gsub("/", "\\") .. '" 2>nul')
    for name in listing:lines() do
        local a, b = name:match("^(%d+)%.(%d+)$")
        local key = a and tonumber(a) * 1000 + tonumber(b)
        if key and key <= GAME_VERSION and (not bestKey or key > bestKey) then best, bestKey = name, key end
    end
    listing:close()
    return best
end

local function suite()
    -- 1. 前提：上游與原版的形狀
    for _, mod in ipairs({ DAMNLIB, CARS[1], CARS[2], CARS[3] }) do
        check("前提：42.22 載入 " .. (mod.mod or "damnlib") .. " 的 " .. mod.version .. "/", versionDir(mod.root) == mod.version)
    end
    reset({ patch = false })
    check("前提：上游補胎的目標胎壓（tireCTISPressure）等於補丁的 PRESSURE", DAMN.Armor.tireCTISPressure == 35)
    local lists = 0
    local allSame = true
    for _, path in ipairs({ luaPath(DAMNLIB, "client/DAMN_Armor_Client.lua"), luaPath(CARS[1], CARS[1].file),
        luaPath(CARS[2], CARS[2].file), luaPath(CARS[3], CARS[3].file) }) do
        for body in readFile(path):gmatch("ipairs%s*%(%s*{(.-)}%s*%)") do
            if body:find('"TireFrontLeft"', 1, true) then
                local ids = {}
                for id in body:gmatch('"([%w_]+)"') do ids[#ids + 1] = id end
                lists = lists + 1
                allSame = allSame and sameSet(setOf(ids), setOf(TIRE_IDS))
            end
        end
    end
    check("前提：上游五個輪胎迴圈（CTIS、三台車 temp tire fix、Wolf）都只看那四個輪胎", lists == 5 and allSame)
    local registered = {}
    for script in pairs(DAMN.Armor.byVehicleScript) do registered[script] = true end
    reset()
    check("前提：補丁的裝甲車種清單等於三台車 DAMN.Armor:add 登記的全部車種", sameSet(registered, MSP_DamnTirePressure.ARMOR))
    local allFix = true
    for script in pairs(registered) do
        local before = sentCount()
        local v = newVehicle(script, { tires = { TireRearRight = 0 } })
        DAMN.Armor.byVehicleScript[script](newPlayer(), v)
        allFix = allFix and sentCount() == before + 1 and sent[#sent].args.part == "TireRearRight" and sent[#sent].args.amount == 35
    end
    check("前提：每個登記車種的裝甲程式都會對低於 1 的輪胎送「補到 35」", allFix)

    -- 2. CTIS（M998：RFS＋CTIS、引擎發動、左前胎 10）
    local function ctisLow() return ctisVehicle({ TireFrontLeft = 10 }) end
    local v = drive({ patch = false, vehicle = ctisLow })
    check("CTIS 上游原樣（一般玩家）：胎壓補不上去，10 次 OnPlayerUpdate 送了 10 次", amount(v) == 10 and sentCount() == 10)
    local admin = drive({ patch = false, admin = true, vehicle = ctisLow })
    local adminSent, adminTx = sentCount(), #transmits
    check("CTIS 管理員（原版放行）：補到 35、只送一次、同步一次", amount(admin) == 35 and adminSent == 1 and adminTx == 1)
    v = drive({ vehicle = ctisLow })
    check("CTIS 補丁（一般玩家駕駛）：和管理員相同（35、送一次、同步一次）",
        amount(v) == 35 and sentCount() == adminSent and #transmits == adminTx and transmits[1].part == "TireFrontLeft")
    v = drive({ vehicle = function() return ctisVehicle({ TireFrontLeft = 5, TireFrontRight = 0, TireRearLeft = 20, TireRearRight = 34.5 }) end })
    check("CTIS 補丁：四輪都低，第一次更新全補到 35，之後不再送",
        amount(v, "TireFrontLeft") == 35 and amount(v, "TireFrontRight") == 35 and amount(v, "TireRearLeft") == 35
        and amount(v, "TireRearRight") == 35 and sentCount() == 4 and #transmits == 4)
    v = drive({ vehicle = ctisLow, seat = 1 })
    check("CTIS 補丁：只有乘客時不補（只接受駕駛），客戶端照舊每次重送", amount(v) == 10 and sentCount() == 10 and #transmits == 0)
    v = drive({ vehicle = ctisLow, admin = true })
    check("CTIS 補丁＋管理員：原版處理，補丁不重複同步", amount(v) == 35 and #transmits == 1)
    v = drive({ vehicle = function() return ctisVehicle({ TireFrontLeft = 10 }, { engine = false }) end })
    check("CTIS 補丁：引擎沒發動，上游不送，胎壓不變", amount(v) == 10 and sentCount() == 0)
    v = drive({ vehicle = function() return ctisVehicle({ TireFrontLeft = 10 }, { cap = 30 }) end, patch = false, admin = true })
    local capAdminTx = #transmits
    v = drive({ vehicle = function() return ctisVehicle({ TireFrontLeft = 10 }, { cap = 30 }) end })
    check("CTIS 補丁：容量 30 的輪胎補到 30；上游照舊每次重送，補丁只同步一次（管理員每次都同步）",
        amount(v) == 30 and sentCount() == 10 and #transmits == 1 and capAdminTx == 10)

    -- 3. temp tire fix（三台車各一個車種、引擎熄火、右後胎 0）
    for _, car in ipairs(CARS) do
        local function flat(level) return function() return newVehicle(car.sample, { tires = { TireRearRight = level } }) end end
        v = drive({ patch = false, vehicle = flat(0), ticks = 5 })
        check(car.mod .. " 上游原樣：胎壓 0 補不上去，5 次更新送 5 次", amount(v, "TireRearRight") == 0 and sentCount() == 5)
        v = drive({ vehicle = flat(0), ticks = 5 })
        check(car.mod .. " 補丁：引擎熄火也補到 35，只送一次、同步一次",
            amount(v, "TireRearRight") == 35 and sentCount() == 1 and #transmits == 1)
        v = drive({ vehicle = flat(0.5), ticks = 5 })
        check(car.mod .. " 補丁：胎壓 0.5 補到 35", amount(v, "TireRearRight") == 35)
        v = drive({ vehicle = flat(1), ticks = 5 })
        check(car.mod .. " 補丁：胎壓 1，上游不送、胎壓不變", amount(v, "TireRearRight") == 1 and sentCount() == 0)
    end

    -- 4. 偽造請求：直接送到伺服器，每一筆都不能改任何胎壓、不能同步
    reset()
    local p = newPlayer()
    local v1 = ctisVehicle({ TireFrontLeft = 10 })
    local v2 = ctisVehicle({ TireFrontLeft = 10 })
    local high = ctisVehicle({ TireFrontLeft = 40 })
    local ctisOnly = ctisVehicle({ TireFrontLeft = 10 }, { rfs = false })
    local rfsOnly = ctisVehicle({ TireFrontLeft = 10 }, { ctis = false })
    local off = ctisVehicle({ TireFrontLeft = 10 }, { engine = false })
    local armor = newVehicle("Base.85chevyCapriceSedan", { tires = { TireFrontLeft = 5 } })
    local armorOne = newVehicle("Base.85chevyCapriceSedan", { tires = { TireFrontLeft = 1 } })
    local plain = newVehicle("Base.CarNormal", { engine = true, tires = { TireFrontLeft = 0 } })
    local snapshot = function()
        local out = {}
        for id, veh in pairs(byId) do
            for _, t in ipairs(TIRE_IDS) do out[id .. t] = amount(veh, t) end
            out[id .. "GasTank"] = amount(veh, "GasTank")
        end
        return out
    end
    local function unchanged(label, seatIn, args, who)
        local before = snapshot()
        p.vehicle, p.seat = seatIn, seatIn and 0 or -1
        transmits = {}
        local ok, err = pcall(serverReceive, who == nil and p or who or nil, "vehicle", "setContainerContentAmount", args)
        local after = snapshot()
        local same = true
        for k, x in pairs(before) do same = same and after[k] == x end
        check("偽造：" .. label, ok and same and #transmits == 0)
        if not ok and not quiet then rawPrint("        " .. tostring(err)) end
    end
    local function req(veh, part, value) return { vehicle = veh and veh:getId(), part = part or "TireFrontLeft", amount = value or 35 } end
    for _, value in ipairs({ 34, 36, 1000, "35" }) do unchanged("數值 " .. tostring(value), v1, req(v1, nil, value)) end
    unchanged("沒有數值", v1, { vehicle = v1:getId(), part = "TireFrontLeft" })
    unchanged("非輪胎零件（油箱）", v1, req(v1, "GasTank"))
    unchanged("沒有零件", v1, { vehicle = v1:getId(), amount = 35 })
    unchanged("坐在 A 車、目標是 B 車", v1, req(v2))
    unchanged("車輛 id 帶小數", v1, { vehicle = v1:getId() + 0.5, part = "TireFrontLeft", amount = 35 })
    unchanged("車輛 id 是字串", v1, { vehicle = tostring(v1:getId()), part = "TireFrontLeft", amount = 35 })
    unchanged("防火牆消掉的請求（vehicle = -1、其餘清空）", v1, { vehicle = -1 })
    unchanged("人不在車上", nil, req(v1))
    unchanged("引擎沒發動", off, req(off))
    unchanged("只有 CTIS、沒有 RFS", ctisOnly, req(ctisOnly))
    unchanged("只有 RFS、沒有 CTIS", rfsOnly, req(rfsOnly))
    unchanged("CTIS 胎壓 40（不能往下調）", high, req(high))
    unchanged("裝甲車種、胎壓 5（不到 1 才補）", armor, req(armor))
    unchanged("裝甲車種、胎壓剛好 1（上游不送）", armorOne, req(armorOne))
    unchanged("一般車種、胎壓 0", plain, req(plain))
    unchanged("player 是 nil", v1, req(v1), false)
    unchanged("沒有 args（nil）", v1, nil)
    local ok = pcall(serverReceive, p, "vehicle", "setPartCondition", { vehicle = v1:getId(), part = "TireFrontLeft", condition = 1 })
    check("偽造：別的指令不受影響、不報錯", ok and amount(v1) == 10)
    -- 正向對照與指令防火牆：同一筆合法請求，防火牆（shared 註冊、排在最前面）拒絕時改成 -1
    p.vehicle, p.seat = v1, 0
    table.insert(handlers.OnClientCommand, 1, function(_, _, _, args)
        for k in pairs(copy(args)) do args[k] = nil end
        args.vehicle = -1
    end)
    serverReceive(p, "vehicle", "setContainerContentAmount", req(v1))
    check("指令防火牆拒絕的合法請求：胎壓不變", amount(v1) == 10 and #transmits == 0)
    table.remove(handlers.OnClientCommand, 1)
    serverReceive(p, "vehicle", "setContainerContentAmount", req(v1))
    check("同一筆請求沒有防火牆時：補到 35、同步一次", amount(v1) == 35 and #transmits == 1)

    -- 5. 安裝條件
    reset({ upstream = false })
    check("安裝：印一行 installed、只多註冊一個處理器", printedMatching("tire pressure fix installed") == 1
        and count("OnClientCommand") == 2 and MSP_DamnTirePressure ~= nil)
    loadPatch()
    check("重複載入：只裝一次", printedMatching("tire pressure fix installed") == 1 and count("OnClientCommand") == 2)
    reset({ upstream = false, mods = { ["\\damnlib"] = true } })
    check("Mods= 寫成 \\damnlib 也安裝", MSP_DamnTirePressure ~= nil and count("OnClientCommand") == 2)
    reset({ upstream = false, mods = { MinidoracatServerPatchFor42 = true, ["85chevyCaprice"] = true } })
    check("damnlib 缺席：不註冊、不設全域表、零輸出", MSP_DamnTirePressure == nil and count("OnClientCommand") == 1 and #printed == 0)
    reset({ upstream = false, server = false })
    check("MP 客戶端：不安裝、零輸出", MSP_DamnTirePressure == nil and count("OnClientCommand") == 1 and #printed == 0)
end

rawPrint("== damnlib 胎壓補丁")
suite()

if arg and arg[1] == "--mutants" then
    local mutants = {
        { name = "不比對車輛 id", from = "vehicle == nil or vehicle:getId() ~= args.vehicle", to = "vehicle == nil" },
        { name = "不限駕駛（乘客也放行）", from = " or not vehicle:isDriver(player)", to = "" },
        { name = "不檢查數值", from = "args.amount ~= PRESSURE or ", to = "" },
        { name = "不檢查輪胎", from = "not TIRES[args.part] or ", to = "" },
        { name = "不看引擎", from = "vehicle:isEngineRunning()", to = "true" },
        { name = "不要求 RFS", from = 'vehicle:getPartById("RFsystem") ~= nil and ', to = "" },
        { name = "不要求 CTIS", from = ' and vehicle:getPartById("CTIsystem") ~= nil', to = "" },
        { name = "CTIS 不看胎壓（會往下調）", from = "now < PRESSURE and vehicle:isEngineRunning()", to = "vehicle:isEngineRunning()" },
        { name = "裝甲車門檻放寬到 35", from = "now < 1 and ARMOR", to = "now < PRESSURE and ARMOR" },
        { name = "裝甲車門檻含 1", from = "now < 1 and ARMOR", to = "now <= 1 and ARMOR" },
        { name = "不限裝甲車種", from = "ARMOR[vehicle:getScript():getFullName()]", to = "true" },
        { name = "每次都同步", from = "if part:getContainerContentAmount() ~= now then vehicle:transmitPartModData(part) end",
            to = "vehicle:transmitPartModData(part)" },
        { name = "不同步", from = "if part:getContainerContentAmount() ~= now then vehicle:transmitPartModData(part) end", to = "" },
        { name = "不檢查 player", from = " or player == nil then return end", to = " then return end" },
        { name = "不檢查上游", from = 'if not (mods:contains("damnlib") or mods:contains("\\\\damnlib")) then return end', to = "" },
        { name = "不擋重複載入", from = "not isServer() or MSP_DamnTirePressure", to = "not isServer()" },
        { name = "客戶端也安裝", from = "not isServer() or MSP_DamnTirePressure", to = "MSP_DamnTirePressure" },
        { name = "裝甲車種漏一台", from = '"69chargerDemon",', to = "" },
    }
    rawPrint("== 突變（每個都應至少讓一項 FAIL）")
    local survived = 0
    for _, m in ipairs(mutants) do
        local keepPass, keepFail = pass, fail
        MUTATION, quiet = m, true
        pass, fail = 0, 0
        local ok, err = pcall(suite)
        local killed = (not ok) or fail > 0
        rawPrint(string.format("  %s  %s（%s）", killed and "KILLED " or "SURVIVED", m.name,
            ok and (fail .. " 項 FAIL") or ("錯誤：" .. tostring(err))))
        if not killed then survived = survived + 1 end
        pass, fail, MUTATION, quiet = keepPass, keepFail, nil, false
    end
    check("所有突變都被抓到", survived == 0)
end

rawPrint(string.format("結果：%d PASS，%d FAIL", pass, fail))
os.exit(fail == 0 and 0 or 1)
