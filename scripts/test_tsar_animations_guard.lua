-- 離線測試：MSP_TsarAnimationsGuard（tsarslib 全域 ModData「tsaranimations」伺服器端清理）。載入本機 Steam 訂閱裡
-- 「未修改的」上游 AMC_ModData.lua，同一個模擬世界各跑一次「上游原樣」與「上游＋補丁」，比對伺服器存下的表。
--   lua scripts/test_tsar_animations_guard.lua             行為與邊界
--   lua scripts/test_tsar_animations_guard.lua --mutants   另對補丁植入錯誤，確認測試抓得到
-- 引擎模擬：GlobalModData.init 先讀存檔再觸發 OnInitGlobalModData（GlobalModData.java:51-55）；收到封包時以新建的表
-- 觸發 OnReceiveGlobalModData，封包的「有表」旗標是 false 時改傳 false（GlobalModDataPacket.java:45-55）；ModData.add＝整張取代
-- （GlobalModData.java:108-110）；Events.X 依註冊順序呼叫、各自 protectedCall（Event.java:52-56、98）；
-- getPlayerByOnlineID 的參數是 Java int，伺服器端再轉 short（LuaManager.java:3940-3942）。

local WS = os.getenv("PZ_WORKSHOP_DIR") or "D:/SteamLibrary/steamapps/workshop/content/108600"
local UP = WS .. "/3402491515/mods/tsarslib/common/media/lua/server/Animations/AMC_ModData.lua"
local PATCH = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/server/Patches/tsarslib/MSP_TsarAnimationsGuard.lua"
local TAG = "tsaranimations"

local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then error("找不到檔案（上游需本機已訂閱）：" .. path) end
    local text = fh:read("a")
    fh:close()
    return text
end
local UP_SOURCE = readFile(UP)

local pass, fail = 0, 0
local rawPrint = print
local quiet = false
local function check(name, cond)
    if cond then pass = pass + 1 else fail = fail + 1 end
    if not quiet then rawPrint((cond and "  PASS  " or "  FAIL  ") .. name) end
end
local function section(name) if not quiet then rawPrint(name) end end

local MUTATION
local function loadPatch()
    local source = readFile(PATCH)
    for _, edit in ipairs(MUTATION and MUTATION.edits or {}) do
        local s, e = source:find(edit[1], 1, true)
        if not s then error("突變片段不在原始碼中：" .. MUTATION.name) end
        source = source:sub(1, s - 1) .. edit[2] .. source:sub(e + 1)
    end
    return assert(load(source, "@" .. PATCH))()
end
local function loadUpstream()
    return assert(load(UP_SOURCE, "@" .. UP))()
end

-- ===== 假引擎 =====
local W -- 目前的模擬世界

local function trigger(name, ...)
    local list = Events[name].list
    local i = 1
    while i <= #list do -- 同 Java：每輪重讀 size()
        local ok, err = pcall(list[i], ...)
        if not ok then W.errors[#W.errors + 1] = tostring(err) end
        i = i + 1
    end
end

function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    local line = table.concat(parts, " ")
    if line:find("MinidoracatServerPatchFor42", 1, true) then W.printed[#W.printed + 1] = line end
end
function isClient() return false end
function isServer() return true end
function getActivatedMods() return { contains = function(_, id) return W.mods[id] == true end } end
function getTimestampMs() return W.now end
function getPlayerByOnlineID(id)
    if type(id) ~= "number" then error("getPlayerByOnlineID: no int conversion for " .. tostring(id)) end
    if id ~= math.floor(id) or id < -32768 or id > 32767 then W.badLookups = W.badLookups + 1 end
    if W.booting then W.bootLookups = W.bootLookups + 1 end
    return W.online[id] and { onlineID = id } or nil
end
ModData = {
    exists = function(tag) return W.store[tag] ~= nil end,
    create = function(tag)
        if W.store[tag] then return nil end
        W.store[tag] = {}
        return W.store[tag]
    end,
    get = function(tag) return W.store[tag] end,
    getOrCreate = function(tag) return W.store[tag] or ModData.create(tag) end,
    add = function(tag, t) W.store[tag] = t end,
}

local function copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = copy(x) end
    return out
end

local function ser(v)
    if type(v) ~= "table" then return type(v) .. ":" .. tostring(v) end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return ser(a) < ser(b) end)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = "[" .. ser(k) .. "]=" .. ser(v[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
end

-- opts：patch＝載入補丁；upstream＝false 時上游缺席；order＝"patch" 時補丁先載入；saved＝存檔讀回的表；
-- online＝在線 onlineID 集合；modKey＝getActivatedMods 裡上游的寫法
local function boot(opts)
    W = { store = {}, online = copy(opts.online or {}), now = 5000000, printed = {}, errors = {},
        badLookups = 0, bootLookups = 0, booting = false,
        mods = { [opts.modKey or "tsarslib"] = opts.upstream ~= false } }
    Events = setmetatable({}, { __index = function(t, name)
        local ev = { list = {} }
        ev.Add = function(fn) ev.list[#ev.list + 1] = fn end
        rawset(t, name, ev)
        return ev
    end })
    local loaders = {}
    if opts.upstream ~= false then loaders[#loaders + 1] = loadUpstream end
    if opts.patch then table.insert(loaders, opts.order == "patch" and 1 or #loaders + 1, loadPatch) end
    for _, f in ipairs(loaders) do f() end
    if opts.saved then W.store[TAG] = copy(opts.saved) end -- GlobalModData.load 在觸發事件之前
    W.booting = true
    trigger("OnInitGlobalModData", false)
    W.booting = false
end

local function receive(tag, packet) trigger("OnReceiveGlobalModData", tag, copy(packet)) end
local function stored() return ser(W.store[TAG]) end

local ONLINE = { [3] = true, [7] = true, [8] = true }
-- 只有 [3] 合規：離線、值不是 true、字串鍵、小數鍵、負數、超出 short、巢狀表
local JUNK = { [3] = true, [9] = true, [7] = false, ["7"] = true, [4.5] = true, [-1] = true, [40000] = true,
    [8] = { nested = true }, x = { 1, 2 } }

local function suite()
    section("情境一：上游缺席")
    boot({ upstream = false, patch = true })
    local regs = 0
    for _, ev in pairs(Events) do regs = regs + #ev.list end
    check("不註冊任何事件", regs == 0)
    check("不印任何訊息", #W.printed == 0)
    receive(TAG, JUNK)
    check("收到封包也不存表", W.store[TAG] == nil)

    section("情境二：開服清掉存檔裡的舊項目")
    local saved = { [3] = true, [9] = true, junk = { 1, 2 } }
    boot({ patch = true, saved = saved, online = ONLINE })
    check("舊項目全清", W.store[TAG] ~= nil and next(W.store[TAG]) == nil)
    check("印 installed 與清掉的數量", #W.printed == 1
        and W.printed[1]:find("tsaranimations guard installed (cleared 3 saved entries)", 1, true) ~= nil)
    check("開服時不查在線玩家", W.bootLookups == 0 and #W.errors == 0)
    boot({ patch = false, saved = saved, online = ONLINE })
    check("對照：上游原樣保留舊項目", stored() == ser(saved))
    boot({ patch = true, modKey = "\\tsarslib" })
    check("getActivatedMods 寫成 \\tsarslib 也會裝", #W.printed == 1)

    section("情境三：在線玩家的 ID＝true，與上游原樣相同")
    for _, order in ipairs({ "upstream", "patch" }) do
        for _, packet in ipairs({ { [3] = true }, { [3] = true, [7] = true }, {} }) do
            boot({ patch = false, online = ONLINE })
            receive(TAG, packet)
            local upstream = stored()
            boot({ patch = true, order = order, online = ONLINE })
            receive(TAG, packet)
            check(order .. " 先載入 " .. ser(packet), stored() == upstream and #W.printed == 1 and #W.errors == 0)
        end
    end

    section("情境四：不合規內容只留在線玩家的 ID＝true")
    for _, order in ipairs({ "upstream", "patch" }) do
        boot({ patch = true, order = order, online = ONLINE })
        receive(TAG, JUNK)
        check(order .. " 先載入：只剩 [3]", stored() == ser({ [3] = true }))
        check(order .. " 先載入：不合規的鍵不送進 getPlayerByOnlineID", W.badLookups == 0 and #W.errors == 0)
        check(order .. " 先載入：印一行刪除計數", #W.printed == 2
            and W.printed[2]:find("dropped 8 invalid or offline entries, kept 1", 1, true) ~= nil)
    end
    boot({ patch = false, online = ONLINE })
    receive(TAG, JUNK)
    check("對照：上游原樣整張存下", stored() == ser(JUNK))

    section("情境五：旗標為 false 的封包與其他標籤")
    boot({ patch = true, online = ONLINE })
    receive(TAG, { [3] = true })
    receive(TAG, false)
    check("false 封包：表維持原樣", stored() == ser({ [3] = true }) and #W.errors == 0)
    W.store.other = { junk = true }
    receive("other", { junk = true })
    check("其他標籤：兩張表都不動", stored() == ser({ [3] = true }) and ser(W.store.other) == ser({ junk = true })
        and #W.printed == 1)

    section("情境六：刪除紀錄每分鐘最多一行")
    boot({ patch = true, online = ONLINE })
    for _ = 1, 3 do
        W.now = W.now + 1000
        receive(TAG, JUNK)
    end
    check("一分鐘內三次只印一行", #W.printed == 2)
    W.now = W.now + 60000
    receive(TAG, JUNK)
    check("一分鐘後再印一行並帶省略次數", #W.printed == 3
        and W.printed[3]:find("(2 similar reports suppressed)", 1, true) ~= nil)
    receive(TAG, { [3] = true })
    check("沒有刪除時不印", #W.printed == 3)

    section("情境七：上游每小時清理照常")
    boot({ patch = true, online = { [3] = true, [7] = true } })
    receive(TAG, { [3] = true, [7] = true })
    W.online[7] = nil
    trigger("EveryHours")
    check("下線玩家由上游移除、沒有錯誤", stored() == ser({ [3] = true }) and #W.errors == 0)
end

rawPrint("== tsarslib tsaranimations 清理")
suite()

if arg and arg[1] == "--mutants" then
    local mutants = {
        { name = "載入時就註冊處理器（不等 OnInitGlobalModData）", edits = {
            { "    Events.OnReceiveGlobalModData.Add(onReceive)\n", "" },
            { "Events.OnInitGlobalModData.Add(function()",
                "Events.OnReceiveGlobalModData.Add(onReceive)\nEvents.OnInitGlobalModData.Add(function()" } } },
        { name = "不查在線", edits = { { "\n        and getPlayerByOnlineID(k) ~= nil", "" } } },
        { name = "不驗整數", edits = { { " and k == math.floor(k)", "" } } },
        { name = "不驗範圍", edits = { { " and k >= 0 and k <= 32767", "" } } },
        { name = "不驗值", edits = { { "v == true and ", "" } } },
        { name = "不驗鍵型別", edits = { { " and type(k) == \"number\"", "" } } },
        { name = "開服不清", edits = { { "t and prune(t, none) or 0", "0" } } },
        { name = "開服改查在線", edits = { { "prune(t, none)", "prune(t, onlineEntry)" } } },
        { name = "紀錄不節流", edits = { { "if lastReport and now - lastReport < 60000 then", "if false then" } } },
        { name = "不檢查上游在不在", edits = { { " or not (mods:contains(MOD_ID) or mods:contains(\"\\\\\" .. MOD_ID))", "" } } },
        { name = "只認不帶反斜線的 mod id", edits = { { " or mods:contains(\"\\\\\" .. MOD_ID)", "" } } },
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
