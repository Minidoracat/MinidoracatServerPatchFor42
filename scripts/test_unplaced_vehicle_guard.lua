-- 離線測試：拖車卸車引擎拒絕放置的防護（MSP_UnplacedVehicleGuard）。載入「未修改的」上游（本機 Steam 訂閱副本）：
--   rSemiTruck  common/media/lua/server/MSW_Common_Commands.lua（MSW 多槽拖車卸車，msw launchVehicle 指令）
--   tsarslib    common/media/lua/server/CommonTemplates/CommonCommands.lua（commonlib launchVehicle 指令）
--               42.17/media/lua/shared/TimedActions/ATAISLaunchVehicle.lua（拖吊車卸車動作的 complete）
-- 假引擎的 addVehicleDebug 照 LuaManager.java:10791-10828：室內格（不在停車區）照樣回傳車，但沒進世界、sqlId 停在 -1；
-- 戶外格放進世界並配 sqlId（VehiclesDB2.java:317-320）。同一個情境各跑「上游原樣」與「補丁」比對倉儲與世界。
--   lua scripts/test_unplaced_vehicle_guard.lua             行為與邊界
--   lua scripts/test_unplaced_vehicle_guard.lua --mutants   另對補丁植入錯誤，確認測試抓得到
-- MSW 快照不帶 parts：restoreSlotDataToVehicle 直接返回（還原成功），測的是 launchVehicle 自己的「生車 → 還原 → 刪倉儲」流程。

local WS = "D:/SteamLibrary/steamapps/workshop/content/108600/"
local MSW = WS .. "3409472393/mods/rSemiTruck/common/media/lua/server/MSW_Common_Commands.lua"
local TSAR_CMD = WS .. "3402491515/mods/tsarslib/common/media/lua/server/CommonTemplates/CommonCommands.lua"
local TSAR_ACT = WS .. "3402491515/mods/tsarslib/42.17/media/lua/shared/TimedActions/ATAISLaunchVehicle.lua"
local PATCH = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/server/Patches/MSP_UnplacedVehicleGuard.lua"

local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then error("找不到檔案（上游需本機已訂閱）：" .. path) end
    local text = fh:read("a")
    fh:close()
    return text
end
local SOURCES = { [MSW] = readFile(MSW), [TSAR_CMD] = readFile(TSAR_CMD), [TSAR_ACT] = readFile(TSAR_ACT) }

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
local function loadUpstream(path) assert(load(SOURCES[path], "@" .. path))() end

-- ===== 假引擎 =====
local printed, effects, activeMods, modDataStore, world, client
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
local function log(line) effects[#effects + 1] = line end

local function javaList(items)
    return { size = function() return #items end, get = function(_, i) return items[i + 1] end }
end

local function newSquare(x, y, z, indoor)
    return {
        indoor = indoor,
        getX = function() return x end, getY = function() return y end, getZ = function() return z end,
        isFree = function() return true end,
        isVehicleIntersecting = function() return false end,
        isSomethingTo = function() return false end,
        getObjects = function() return javaList({}) end,
    }
end
local INDOOR = { x = 100, y = 100 }   -- 室內、不在停車區：引擎拒絕放置
local OUTDOOR = { x = 200, y = 200 }  -- 戶外：正常放置
local function squareAt(x, y, z)
    return newSquare(x, y, z or 0, x == INDOOR.x and y == INDOOR.y)
end

local function newPart(owner, id, opts)
    opts = opts or {}
    local part = { id = id, md = opts.md or {}, item = opts.item, condition = opts.condition or 100 }
    function part:getId() return self.id end
    function part:getModData() return self.md end
    function part:getInventoryItem() return self.item end
    function part:setInventoryItem(item)
        self.item = item
        log("setInventoryItem " .. owner .. " " .. self.id .. " " .. tostring(item and item.type))
    end
    function part:getCondition() return self.condition end
    function part:setCondition(c) self.condition = c end
    function part:getItemContainer() return nil end
    function part:setItemContainer() end
    function part:getLuaFunction() return nil end
    function part:getTable() return nil end
    return part
end

-- 卸下來的車：上游只會呼叫這些
local function newSpawned(scriptName, sq)
    local v = { script = scriptName, parts = {}, keyId = -1, md = {} }
    function v:getSqlId() return self.sqlId end
    function v:getX() return sq:getX() end
    function v:getY() return sq:getY() end
    function v:getKeyId() return self.keyId end
    function v:setKeyId(k) self.keyId = k end
    function v:getModData() return self.md end
    function v:getPartById(id)
        if not self.parts[id] then self.parts[id] = newPart("spawned", id) end
        return self.parts[id]
    end
    function v:permanentlyRemove() log("permanentlyRemove spawned") end
    return setmetatable(v, { __index = function() return function() end end })
end

local nextSqlId
local function engineAddVehicleDebug(scriptName, dir, skinIndex, sq)
    local v = newSpawned(scriptName, sq)
    if sq.indoor then
        v.sqlId = -1
    else
        nextSqlId = nextSqlId + 1
        v.sqlId = nextSqlId
        world.placed[#world.placed + 1] = v
    end
    return v
end

local function newTrailer(id, name, specs)
    local t = { id = id, name = name, byId = {}, list = {} }
    for _, spec in ipairs(specs) do
        local part = newPart(name, spec[1], spec[2])
        t.byId[spec[1]] = part
        t.list[#t.list + 1] = part
    end
    function t:getId() return self.id end
    function t:getPartById(pid) return self.byId[pid] end
    function t:getPartByIndex(i) return self.list[i + 1] end
    function t:getScript()
        local list = self.list
        return { getPartCount = function() return #list end, getFullName = function() return "Base.E2ETrailer" end }
    end
    function t:getSquare() return squareAt(50, 50, 0) end
    function t:getX() return 50 end
    function t:getY() return 50 end
    function t:getZ() return 0 end
    function t:getSkinIndex() return 0 end
    function t:getAngleX() return 0 end
    function t:getAngleY() return 90 end
    function t:getAngleZ() return 0 end
    function t:getRust() return 0.25 end
    function t:getKeyId() return 4242 end
    function t:isRemovedFromWorld() return false end
    function t:updatePartStats() end
    function t:transmitPartModData(part) log("transmitPartModData " .. self.name .. " " .. part.id) end
    function t:transmitPartItem(part) log("transmitPartItem " .. self.name .. " " .. part.id) end
    world.byId[id] = t
    return t
end

local function mswTrailer()
    local specs = { { "ATAMultiSlotWrecker", { md = { msw = { slots = {
        [1] = { storageId = "S1", slot = 1, scriptName = "Base.CarNormal", coverPair = 1 },
    } } } } } }
    for i = 1, 5 do specs[#specs + 1] = { "MSWCarCover" .. i, { item = i == 1 and { type = "Base.LightBulb" } or nil } } end
    modDataStore.MSW_VehicleStorage_v2 = { version = 2, trailers = { S1 = { version = 2, slots = {
        [1] = { scriptName = "Base.CarNormal", scriptFullName = "Base.CarNormal", skin = 1, marker = "snapshot" },
    } } } }
    return newTrailer(1, "msw", specs)
end

local function tsarTrailer()
    return newTrailer(2, "tsar", {
        { "ATA2VehicleWrecker", { item = { type = "Base.ATA2Wrecker" }, md = {
            scriptName = "Base.CarNormal", skin = 2, h = 0.1, s = 0.2, v = 0.3, rust = 0.5, keyId = 77,
            parts = { Engine = { InventoryItem = "Base.NormalCarEngine", Condition = 80, modData = { tuned = true } } },
        } } },
        { "wrecker_Battery", { item = { type = "Base.CarBattery1" }, condition = 60 } },
    })
end

local function resetEnv(modList)
    printed, effects, modDataStore = {}, {}, {}
    world = { byId = {}, placed = {} }
    nextSqlId = 1000
    client = false
    activeMods = {}
    for _, id in ipairs(modList) do activeMods[id] = true; activeMods["\\" .. id] = true end
    local events = {}
    Events = setmetatable({}, { __index = function(t, k)
        local list = {}
        local e = { list = list, Add = function(fn) list[#list + 1] = fn end,
            Remove = function(fn) for i, f in ipairs(list) do if f == fn then table.remove(list, i) return end end end }
        rawset(t, k, e)
        return e
    end })
    SandboxVars = { MSW = {} }
    MSP_UnplacedVehicleGuard = nil
    ATAISLaunchVehicle = nil
    addVehicleDebug = engineAddVehicleDebug
end

function isClient() return client end
function isServer() return not client end
function getActivatedMods() return { contains = function(_, id) return activeMods[id] == true end } end
function getVehicleById(id) return world.byId[id] end
function getSquare(x, y, z) return squareAt(x, y, z) end
function getCell()
    return { getGridSquare = function(_, x, y, z) return squareAt(x, y, z) end, getVehicles = function() return javaList({}) end }
end
function getText(key) return key end
function instanceItem(fullType) return { type = fullType } end
function instanceof() return false end
function ZombRand(n) return 0 end
function require() end
IsoDirections = { N = "N" }
DebugLog = { log = function(line) print("DebugLog " .. tostring(line)) end }
VehicleUtils = { callLua = function() end }
ModData = { getOrCreate = function(key) modDataStore[key] = modDataStore[key] or {}; return modDataStore[key] end }
ISBaseTimedAction = { derive = function(self, name) return setmetatable({ Type = name }, { __index = self }) end }

local player = { notes = {} }
function player:setHaloNote(text) self.notes[#self.notes + 1] = text; log("halo " .. tostring(text)) end
function player:getUsername() return "test" end

-- ===== 情境 =====
local function trigger(module, command, args)
    for _, fn in ipairs(Events.OnClientCommand.list) do fn(module, command, player, args) end
end

-- patch：nil＝不載補丁、"before"／"after"＝補丁比上游早／晚載入
local function boot(patch, upstreamPath, mods)
    resetEnv(mods or { "rSemiTruck", "tsarslib", "MinidoracatServerPatchFor42" })
    player.notes = {}
    if patch == "before" then loadPatch() end
    loadUpstream(upstreamPath)
    if patch == "after" then loadPatch() end
end

local function mswRun(patch, target)
    boot(patch, MSW)
    local trailer = mswTrailer()
    trigger("msw", "launchVehicle", { trailer = trailer:getId(), x = target.x, y = target.y, slot = 1 })
    local root = modDataStore.MSW_VehicleStorage_v2
    local store = root.trailers.S1
    return {
        slot = trailer:getPartById("ATAMultiSlotWrecker").md.msw.slots[1] ~= nil,
        snapshot = store ~= nil and store.slots[1] ~= nil and store.slots[1].marker == "snapshot",
        placed = #world.placed,
        effects = table.concat(effects, "\n"),
        upstreamPrints = printedMatching("[MSW]"),
    }
end

local function tsarRun(patch, target, path)
    boot(patch, path)
    local trailer = tsarTrailer()
    local ret
    if path == TSAR_CMD then
        trigger("commonlib", "launchVehicle", { trailer = trailer:getId(), x = target.x, y = target.y })
    else
        ret = ATAISLaunchVehicle.complete({ character = player, trailer = trailer, square = squareAt(target.x, target.y, 0) })
    end
    local wrecker = trailer:getPartById("ATA2VehicleWrecker")
    return {
        modData = wrecker.md.scriptName == "Base.CarNormal" and wrecker.md.parts ~= nil and wrecker.md.parts.Engine ~= nil,
        item = wrecker.item ~= nil,
        battery = trailer:getPartById("wrecker_Battery").item ~= nil,
        placed = #world.placed,
        ret = ret,
        effects = table.concat(effects, "\n"),
        spawnError = printedMatching("ERROR: Failed to spawn vehicle! launchVehicle"),
    }
end
local function refusedLines() return printedMatching("engine did not place Base.CarNormal at 100,100,0") end
local function same(a, b)
    for k, v in pairs(a) do if b[k] ~= v then return false end end
    for k, v in pairs(b) do if a[k] ~= v then return false end end
    return true
end

local function suite()
    -- 1. MSW 室內卸車
    local raw = mswRun(nil, INDOOR)
    check("MSW 上游原樣（室內）：槽位與倉儲快照被刪、世界上沒有車＝整台車消失",
        not raw.slot and not raw.snapshot and raw.placed == 0)
    for _, order in ipairs({ "after", "before" }) do
        local r = mswRun(order, INDOOR)
        check("MSW 補丁（" .. order .. "，室內）：槽位與倉儲快照都在、沒有生車",
            r.slot and r.snapshot and r.placed == 0)
        check("MSW 補丁（" .. order .. "，室內）：上游走自己的失敗分支（Failed to spawn 提示、[MSW] log）、補丁印一行座標",
            r.effects:find("halo Failed to spawn unloaded vehicle", 1, true) ~= nil and r.upstreamPrints == 1
            and refusedLines() == 1)
    end
    -- 2. MSW 戶外卸車：兩邊相同
    raw = mswRun(nil, OUTDOOR)
    local patched = mswRun("after", OUTDOOR)
    check("MSW 戶外：上游原樣正常卸下（槽位清空、一台車進世界）", not raw.slot and not raw.snapshot and raw.placed == 1)
    check("MSW 戶外：補丁與上游原樣的結果與副作用完全相同、補丁不印拒絕", same(raw, patched) and printedMatching("engine did not place") == 0)

    -- 3. tsarslib 兩條卸車路徑
    for _, path in ipairs({ TSAR_CMD, TSAR_ACT }) do
        local label = path == TSAR_CMD and "tsarslib 指令" or "tsarslib 動作"
        raw = tsarRun(nil, INDOOR, path)
        check(label .. " 上游原樣（室內）：拖吊零件 modData 與零件被清掉、世界上沒有車",
            not raw.modData and not raw.item and raw.placed == 0)
        patched = tsarRun("after", INDOOR, path)
        check(label .. " 補丁（室內）：modData、拖吊零件、wrecker_Battery 都在，沒有生車",
            patched.modData and patched.item and patched.battery and patched.placed == 0)
        check(label .. " 補丁（室內）：上游印 Failed to spawn、補丁印一行座標",
            patched.spawnError == 1 and refusedLines() == 1)
        if path == TSAR_ACT then
            check(label .. " complete：上游原樣回 true、補丁回 nil（動作被拒）", raw.ret == true and patched.ret == nil)
        end
        raw = tsarRun(nil, OUTDOOR, path)
        patched = tsarRun("after", OUTDOOR, path)
        check(label .. " 戶外：上游原樣正常卸下（modData 清空、一台車進世界）", not raw.modData and raw.placed == 1)
        check(label .. " 戶外：補丁與上游原樣完全相同", same(raw, patched) and printedMatching("engine did not place") == 0)
    end

    -- 4. 安裝條件
    boot("after", MSW)
    check("安裝：印一行 installed、原函式可取回", printedMatching("unplaced vehicle guard installed") == 1
        and MSP_UnplacedVehicleGuard ~= nil and MSP_UnplacedVehicleGuard.original == engineAddVehicleDebug
        and addVehicleDebug ~= engineAddVehicleDebug)
    loadPatch()
    check("重複載入：只裝一次、不疊包裝", printedMatching("unplaced vehicle guard installed") == 1
        and MSP_UnplacedVehicleGuard.original == engineAddVehicleDebug)
    for _, only in ipairs({ "rSemiTruck", "tsarslib" }) do
        boot("after", MSW, { only, "MinidoracatServerPatchFor42" })
        check("只有 " .. only .. "：照樣安裝", addVehicleDebug ~= engineAddVehicleDebug and printedMatching("installed") == 1)
    end
    boot("after", MSW, { "MinidoracatServerPatchFor42" })
    check("上游都缺席：不換全域、不設全域表、零輸出", addVehicleDebug == engineAddVehicleDebug
        and MSP_UnplacedVehicleGuard == nil and #printed == 0)
    resetEnv({ "rSemiTruck", "tsarslib" })
    client = true
    loadPatch()
    check("MP 客戶端：不安裝、零輸出", addVehicleDebug == engineAddVehicleDebug and #printed == 0)
end

rawPrint("== 拖車卸車引擎拒絕放置防護")
suite()

if arg and arg[1] == "--mutants" then
    local mutants = {
        { name = "拿掉 sqlId 判斷", from = "vehicle and vehicle:getSqlId() == -1", to = "false" },
        { name = "拒絕時回傳原物件", from = "return nil", to = "return vehicle" },
        { name = "判斷反向（~= -1）", from = "vehicle:getSqlId() == -1", to = "vehicle:getSqlId() ~= -1" },
        { name = "不檢查上游", from = 'if not (active("rSemiTruck") or active("tsarslib")) then return end', to = "" },
        { name = "只認 rSemiTruck", from = 'active("rSemiTruck") or active("tsarslib")', to = 'active("rSemiTruck")' },
        { name = "不擋重複載入", from = "isClient() or MSP_UnplacedVehicleGuard", to = "isClient()" },
        { name = "客戶端也安裝", from = "isClient() or MSP_UnplacedVehicleGuard", to = "MSP_UnplacedVehicleGuard" },
        { name = "不留原函式", from = "{ original = original }", to = "{}" },
        { name = "拒絕時不印 log", from = "print(PREFIX .. \" addVehicleDebug", to = "(function() end)(PREFIX .. \" addVehicleDebug" },
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
