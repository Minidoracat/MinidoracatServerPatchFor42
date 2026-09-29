-- 離線測試：rSemiTruck「載入後修復」節流補丁（MSP_SemiTruckRestoreThrottle）。載入「未修改的」上游
-- MSW_Common_Commands.lua（本機 Steam 訂閱副本），同一個模擬世界各跑一次「上游原樣」與「補丁」，比對車罩同步、
-- 舊容量鍵清理、送出的封包與全掃次數，並涵蓋開關、上游形狀改變與載入順序。
--   lua scripts/test_semitruck_restore_throttle.lua             行為與邊界
--   lua scripts/test_semitruck_restore_throttle.lua --mutants   另對補丁植入錯誤，確認測試抓得到
-- 引擎模擬：專用伺服器先載入全部 MOD 的 shared/ 再載入 server/（GameServer.java:1469-1471），Lua 全部載入且沙盒讀入後
-- 觸發 OnGameBoot（:1481-1496）；Events.X 是一般 Lua 表（Event.java:78-83），每個 callback 各自 protectedCall（:52-64）。

local UP = "D:/SteamLibrary/steamapps/workshop/content/108600/3409472393/mods/rSemiTruck/common/media/lua/server/MSW_Common_Commands.lua"
local PATCH = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/shared/Patches/rSemiTruck/MSP_SemiTruckRestoreThrottle.lua"
local MIGRATE_LINE, RESTORE_LINE = 2396, 2408 -- 上游兩個 EveryOneMinute 回呼的定義行（debug.getinfo 的 linedefined）

local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then error("找不到檔案（上游需本機已訂閱）：" .. path) end
    local text = fh:read("a")
    fh:close()
    return text
end
local UP_SOURCE = readFile(UP)

local pass, fail = 0, 0
local rawPrint, printed = print, {}
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
    return assert(load(source, "@" .. PATCH))()
end
local function loadUpstream(transform)
    local source = transform and transform(UP_SOURCE) or UP_SOURCE
    return assert(load(source, "@" .. UP))()
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

local effects, counters, activeMods, modDataStore, minute, inRestore
local function log(line) effects[#effects + 1] = { minute = minute, line = line } end

local function newEvent(name)
    local event = { list = {}, name = name }
    event.Add = function(fn) if type(fn) == "function" then event.list[#event.list + 1] = fn end end
    event.Remove = function(fn)
        for i, f in ipairs(event.list) do if f == fn then table.remove(event.list, i); return end end
    end
    event.engineAdd = event.Add
    return event
end
local function where(fn)
    local info = debug.getinfo(fn, "S")
    return info.source:gsub("^@", ""), info.linedefined
end
local function trigger(event, ...)
    for _, fn in ipairs(event.list) do
        local file, line = where(fn)
        local key = (file == UP and ("upstream:" .. line)) or (file == PATCH and "patch") or "other"
        counters["dispatch:" .. event.name .. ":" .. key] = (counters["dispatch:" .. event.name .. ":" .. key] or 0) + 1
        local ok, err = pcall(fn, ...)
        if not ok then log("callback error " .. tostring(err)) end
    end
end

local function javaList(items)
    return { size = function() return #items end, get = function(_, i) return items[i + 1] end }
end

local world = {}
local function newContainer(owner, cap)
    return {
        cap = cap,
        getCapacity = function(self) return self.cap end,
        setCapacity = function(self, n) self.cap = n; log("setCapacity " .. owner .. " " .. n) end,
    }
end
local function newPart(vehicle, id, opts)
    opts = opts or {}
    local part = { id = id, md = opts.md, container = opts.container, item = opts.item }
    function part:getModData()
        if inRestore then counters.restoreGetModData = (counters.restoreGetModData or 0) + 1 end
        if not self.md then self.md = {} end
        return self.md
    end
    function part:getItemContainer() return self.container end
    function part:getInventoryItem() return self.item end
    function part:setInventoryItem(item)
        self.item = item
        log("setInventoryItem " .. vehicle.name .. " " .. id .. " " .. tostring(item and item.type))
    end
    function part:getTable() return nil end
    return part
end
local function newVehicle(name, specs)
    local v = { name = name, parts = {}, byId = {} }
    for _, spec in ipairs(specs) do
        local part = newPart(v, spec[1], spec[2])
        v.parts[#v.parts + 1] = part
        v.byId[spec[1]] = part
    end
    function v:getPartById(id) return self.byId[id] end
    function v:getPartCount()
        if inRestore then counters.restoreScans = (counters.restoreScans or 0) + 1 end
        return #self.parts
    end
    function v:getPartByIndex(i) return self.parts[i + 1] end
    function v:updatePartStats() end
    function v:transmitPartItem(part) log("transmitPartItem " .. self.name .. " " .. part.id) end
    function v:transmitPartModData(part) log("transmitPartModData " .. self.name .. " " .. part.id) end
    return v
end
local function plainCar(i)
    local specs = {}
    for p = 1, 8 do specs[#specs + 1] = { "Part" .. p } end
    return newVehicle("car" .. i, specs)
end
local function legacyCar()
    return newVehicle("legacy", {
        { "TruckBed", { md = { msw_customContainerCapacity = 50 }, container = newContainer("legacy", 30) } },
        { "GloveBox", { md = { msw_customContainerCapacity = 5 }, container = newContainer("legacy-glove", 10) } },
        { "Engine" },
    })
end
local function carTrailer(name, pairs)
    local slots = {}
    for i, pair in ipairs(pairs) do slots[i] = { storageId = name, slot = i, scriptName = "Base.Car", coverPair = pair } end
    local specs = { { "ATAMultiSlotWrecker", { md = { msw = { slots = slots } } } } }
    for i = 1, 5 do specs[#specs + 1] = { "MSWCarCover" .. i } end
    return newVehicle(name, specs)
end

local function resetEnv(modList, server)
    effects, printed, counters, modDataStore = {}, {}, {}, {}
    minute, inRestore = 0, false
    activeMods = {}
    for _, id in ipairs(modList) do activeMods[id] = true; activeMods["\\" .. id] = true end
    Events = setmetatable({}, { __index = function(t, k) local e = newEvent(k); rawset(t, k, e); return e end })
    MSP_SemiTruckRestoreThrottle = nil
    SandboxVars = { MSW = {} }
    world.vehicles = {}
    isServer = function() return server ~= false end
end

function isClient() return false end
function getActivatedMods() return { contains = function(_, id) return activeMods[id] == true end } end
function getFilenameOfClosure(fn) return (where(fn):gsub("\\", "/")) end
function getFirstLineOfClosure(fn) local _, line = where(fn); return line end
function getCell() return { getVehicles = function() return javaList(world.vehicles) end } end
function instanceItem(fullType) return { type = fullType } end
ModData = { getOrCreate = function(key) modDataStore[key] = modDataStore[key] or {}; return modDataStore[key] end }

-- 啟動：patchMode ＝ "none"（不載補丁）／"shared"（正常：shared 早於 server）／"after"（補丁晚於上游）／"twice"
local function boot(opts)
    opts = opts or {}
    resetEnv(opts.mods or { "rSemiTruck", "MinidoracatServerPatchFor42" }, opts.server)
    if opts.other then
        assert(load("Events.EveryOneMinute.Add(function() end)", "@other/mod.lua"))()
    end
    local mode = opts.patch or "shared"
    if mode == "shared" or mode == "twice" then loadPatch() end
    if mode == "twice" then loadPatch() end
    loadUpstream(opts.transform)
    if mode == "after" then loadPatch() end
    SandboxVars.MinidoracatServerPatchFor42 = opts.toggles
    trigger(Events.OnGameBoot)
end

-- 模擬世界：timeline[m] 在第 m 遊戲分鐘開始前把車加入已載入清單
local function run(minutes, timeline)
    for m = 1, minutes do
        minute = m
        for _, v in ipairs((timeline and timeline[m]) or {}) do world.vehicles[#world.vehicles + 1] = v end
        local before = counters.restoreScans or 0
        inRestore = true
        trigger(Events.EveryOneMinute)
        inRestore = false
        if (counters.restoreScans or 0) > before then
            counters.scanMinutes = counters.scanMinutes or {}
            counters.scanMinutes[#counters.scanMinutes + 1] = m
        end
    end
end

local function baseTimeline(withTrailers)
    local t = { [1] = { legacyCar() } }
    for i = 1, 20 do t[1][#t[1] + 1] = plainCar(i) end
    if withTrailers then
        t[40] = { carTrailer("trailerA", { 2, 4 }) }
        t[70] = { carTrailer("trailerB", { 1 }) }
    end
    return t
end

local function effectLines(filter)
    local out = {}
    for _, e in ipairs(effects) do
        if not filter or e.line:find(filter, 1, true) then out[#out + 1] = e.line end
    end
    table.sort(out)
    return table.concat(out, "\n")
end
local function minutesOf(filter)
    local set, out = {}, {}
    for _, e in ipairs(effects) do
        if e.line:find(filter, 1, true) and not set[e.minute] then set[e.minute] = true; out[#out + 1] = e.minute end
    end
    return table.concat(out, ",")
end
local function scanMinutes() return table.concat(counters.scanMinutes or {}, ",") end
local function engineCallbacks(event)
    local out = {}
    for _, fn in ipairs(event.list) do
        local file, line = where(fn)
        out[#out + 1] = (file == UP and ("upstream:" .. line)) or (file == PATCH and "patch") or file
    end
    return table.concat(out, ",")
end

local function suite()
    -- 1. 上游原樣（不載補丁）＝基準
    boot({ patch = "none" })
    run(90, baseTimeline(true))
    local baseAll, baseScans = effectLines(), scanMinutes()
    local baseMigrate = counters["dispatch:EveryOneMinute:upstream:" .. MIGRATE_LINE]
    check("基準：上游在找到汽車拖車前每分鐘全掃（1..40）", baseScans == table.concat((function()
        local t = {} for m = 1, 40 do t[#t + 1] = m end return t end)(), ","))
    check("基準：trailerA 在第 40 分鐘同步車罩", minutesOf("setInventoryItem trailerA") == "40")
    check("基準：trailerB（上游停下後才載入）不會被這個回呼同步", minutesOf("trailerB") == "")
    check("基準：舊容量鍵在第 1 分鐘清理", minutesOf("setCapacity legacy") == "1")

    -- 2. 補丁（正常載入順序）
    boot({ other = true })
    check("安裝：印出 installed 且標出上游第 " .. RESTORE_LINE .. " 行", printedMatching("restore throttle installed") == 1
        and printedMatching("line " .. RESTORE_LINE .. ")") == 1)
    check("安裝：OnGameBoot 後 Add 換回引擎原本的函式", Events.EveryOneMinute.Add == Events.EveryOneMinute.engineAdd)
    check("安裝：只包上游第二個回呼，第一個與其他 MOD 原樣", engineCallbacks(Events.EveryOneMinute)
        == "other/mod.lua,upstream:" .. MIGRATE_LINE .. ",patch")
    run(90, baseTimeline(true))
    check("節流：只在第 1、31、61 分鐘執行上游回呼", scanMinutes() == "1,31,61")
    check("節流：trailerA 延到下一次（第 61 分鐘）才同步", minutesOf("setInventoryItem trailerA") == "61")
    check("節流：舊容量鍵仍在第 1 分鐘清理", minutesOf("setCapacity legacy") == "1")
    check("節流：90 分鐘後所有副作用與上游原樣相同（只差時間點）", effectLines() == baseAll)
    check("節流：舊存檔搬移回呼每分鐘照跑（90 次）", baseMigrate == 90
        and counters["dispatch:EveryOneMinute:upstream:" .. MIGRATE_LINE] == 90)
    check("節流：找到汽車拖車後上游自行停下（21＋21＋22 台次，trailerB 不再被掃）", (counters.restoreScans or 0) == 21 + 21 + 22)

    -- 3. 整個 session 都沒有汽車拖車：上游 90 次全掃 vs 補丁 3 次
    boot({ patch = "none" })
    run(90, baseTimeline(false))
    local noTrailerBase = counters.restoreScans
    boot({})
    run(90, baseTimeline(false))
    check("沒有汽車拖車：上游每分鐘全掃（90 次 × 21 台）", noTrailerBase == 90 * 21)
    check("沒有汽車拖車：補丁只全掃 3 次（第 1、31、61 分鐘）", counters.restoreScans == 3 * 21 and scanMinutes() == "1,31,61")

    -- 4. 開關關閉＝上游原樣
    boot({ toggles = { SlimSemiTruckRestore = false } })
    run(90, baseTimeline(true))
    check("開關關閉：印 disabled、Add 已換回", printedMatching("disabled by sandbox option") == 1
        and Events.EveryOneMinute.Add == Events.EveryOneMinute.engineAdd)
    check("開關關閉：全掃時間點與副作用和上游原樣相同", scanMinutes() == baseScans and effectLines() == baseAll)

    -- 5. 上游形狀改變：多一個 EveryOneMinute 註冊 → NOT installed、原樣
    local extra = function(src) return src .. "\nEvents.EveryOneMinute.Add(function() end)\n" end
    boot({ patch = "none", transform = extra })
    run(90, baseTimeline(true))
    local extraBase, extraScans = effectLines(), scanMinutes()
    boot({ transform = extra })
    run(90, baseTimeline(true))
    check("上游多一個回呼：印 NOT installed（saw 3）", printedMatching("NOT installed") == 1 and printedMatching("saw 3") == 1)
    check("上游多一個回呼：行為與上游原樣相同", scanMinutes() == extraScans and effectLines() == extraBase)
    check("上游多一個回呼：Add 已換回", Events.EveryOneMinute.Add == Events.EveryOneMinute.engineAdd)

    -- 6. 上游拿掉本回呼的註冊 → saw 1、NOT installed
    boot({ transform = function(src)
        return (src:gsub("Events%.EveryOneMinute%.Add%(MSW_RestoreContainerCapacitiesOnLoad%)", "-- removed"))
    end })
    check("上游只剩一個回呼：印 NOT installed（saw 1）", printedMatching("NOT installed") == 1 and printedMatching("saw 1") == 1)

    -- 7. 補丁晚於上游載入（攔不到）→ saw 0、NOT installed、上游原樣
    boot({ patch = "after" })
    run(90, baseTimeline(true))
    check("補丁晚於上游：印 NOT installed（saw 0）", printedMatching("saw 0") == 1)
    check("補丁晚於上游：行為與上游原樣相同", scanMinutes() == baseScans and effectLines() == baseAll)

    -- 8. 上游缺席、非伺服器：完全不碰事件、不印任何字
    boot({ mods = { "MinidoracatServerPatchFor42" } })
    check("上游缺席：Add 未被替換、零輸出", Events.EveryOneMinute.Add == Events.EveryOneMinute.engineAdd and #printed == 0
        and engineCallbacks(Events.EveryOneMinute) == "upstream:" .. MIGRATE_LINE .. ",upstream:" .. RESTORE_LINE)
    boot({ server = false })
    check("非伺服器：不攔截、零輸出", #printed == 0
        and engineCallbacks(Events.EveryOneMinute) == "upstream:" .. MIGRATE_LINE .. ",upstream:" .. RESTORE_LINE)

    -- 9. 補丁檔被載入兩次：只攔一次、只包一層
    boot({ patch = "twice" })
    check("重複載入：只裝一次、只包一層、Add 已換回", printedMatching("restore throttle installed") == 1
        and printedMatching("NOT installed") == 0
        and engineCallbacks(Events.EveryOneMinute) == "upstream:" .. MIGRATE_LINE .. ",patch"
        and Events.EveryOneMinute.Add == Events.EveryOneMinute.engineAdd)
    run(90, baseTimeline(false))
    check("重複載入：節流週期不變（1、31、61）", scanMinutes() == "1,31,61")
end

rawPrint("== rSemiTruck 載入後修復節流")
suite()

if arg and arg[1] == "--mutants" then
    local mutants = {
        { name = "改包第一個回呼（舊存檔搬移）", from = "if registered == 2 then", to = "if registered == 1 then" },
        { name = "週期差一（每 31 分鐘）", from = "skip = EVERY_MINUTES - 1", to = "skip = EVERY_MINUTES" },
        { name = "第一次就跳過", from = "local skip = 0", to = "local skip = EVERY_MINUTES - 1" },
        { name = "OnGameBoot 不換回 Add", from = "if event.Add == add then event.Add = engineAdd end", to = "" },
        { name = "不檢查上游註冊數", from = "if registered ~= 2 then", to = "if false then" },
        { name = "忽略沙盒開關", from = "options.SlimSemiTruckRestore == false", to = "false" },
        { name = "不擋重複載入", from = "if MSP_SemiTruckRestoreThrottle then return end", to = "" },
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
