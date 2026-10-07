-- 離線測試：Simple Status 刻度合併繪製（MSP_SimpleStatusRulerBatch）。載入「未修改的」上游 42.20/ 客戶端
-- （本機 Steam 訂閱副本）與原版 ISBaseObject／ISUIElement／ISPanel，同一組情境各跑一次「上游原樣」與「補丁」，
-- 以 Java 的繪製語意逐像素比對畫面，並計數每幀 Lua→Java 呼叫。
--   lua scripts/test_simplestatus_ruler_batch.lua             行為與邊界
--   lua scripts/test_simplestatus_ruler_batch.lua --mutants   另對補丁植入錯誤，確認測試抓得到
--   lua scripts/test_simplestatus_ruler_batch.lua --bench     另比標準 Lua 下 prerender 的耗時（只供參考，不是 Kahlua）
-- 畫面模型：UIElement.DrawTextureScaledCol 把 x／y／w／h 各自截成整數（UIElement.java:469-483），DrawText 不截
-- （:190-197）；UI 混色 SRC_ALPHA／ONE_MINUS_SRC_ALPHA，FBO 時 alpha 通道 ONE／ONE_MINUS_SRC_ALPHA
-- （UIManager.java:279-281）。兩種混色下 alpha 1.0 的純色都完全覆蓋底下的內容，所以每個像素記「最後一次不透明純色
-- 之後的繪製序列」，序列相同＝任何底圖與任何算術下結果相同；文字呼叫記參數與當下整個畫面的雜湊。

local WS = "D:/SteamLibrary/steamapps/workshop/content/108600/"
local UP = WS .. "2867431511/mods/SimpleStatus/42.20/media/lua/client/"
local VANILLA = "D:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/"
local PATCH = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/client/Patches/simpleStatus/MSP_SimpleStatusRulerBatch.lua"
local FRAMES = 12 -- 第 10 幀 prepareBarInfo 重算一次，之後兩幀用新數值

local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then error("找不到檔案（上游需本機已訂閱）：" .. path) end
    local text = fh:read("a")
    fh:close()
    return text
end
-- 上游形狀：補丁換掉的三個方法都還在 ISSSBar.lua；找不到就是上游改了形狀，照 upstream.json 的 recheck 重核
local UP_SOURCE = readFile(UP .. "ISSSBar.lua")
for _, sig in ipairs({ "function SSBar:prerender()", "function SSBar:drawRuler(x, y, p)", "self:drawRectStatic(" }) do
    if not UP_SOURCE:find(sig, 1, true) then error("上游 ISSSBar.lua 找不到：" .. sig) end
end

local pass, fail = 0, 0
local quiet = false
local rawPrint, printed = print, {}
local function check(name, cond)
    if cond then pass = pass + 1 else fail = fail + 1 end
    if not quiet then rawPrint((cond and "  PASS  " or "  FAIL  ") .. name) end
end
function print(...)
    local line = table.concat({ ... }, " ")
    if line:find("MinidoracatServerPatchFor42", 1, true) then printed[#printed + 1] = line end
end

-- ===== 假引擎 =====
local calls -- 每類 Lua→Java 呼叫次數
local function java(kind) calls[kind] = (calls[kind] or 0) + 1 end
local function jint(v) -- Java (int) 往 0 截斷
    if v >= 0 then return math.floor(v) end
    return math.ceil(v)
end

local scene -- 目前情境：scroll、滑鼠、量字寬係數
local fb -- 畫面：fb.stack[像素] = 序列雜湊（整數）；fb.hash 為整個畫面的增量雜湊
local intern, internN = {}, 0
local function idOf(s)
    local id = intern[s]
    if not id then internN = internN + 1; id = internN; intern[s] = id end
    return id
end
local function mix(k, v) return ((k * 0x9E3779B1) ~ (v * 0x85EBCA77)) * 0xC2B2AE3D end
local function newFb() return { stack = {}, hash = 0, texts = {} } end

-- 不透明純色把序列重設成只剩自己；其餘接在序列後面（64 位元整數環繞雜湊）
local function plot(k, op, opaque)
    local stack = fb.stack
    local old = stack[k]
    local new = op
    if old then
        if not opaque then new = old * 1000003 + op end
        fb.hash = fb.hash - mix(k, old)
    end
    fb.hash = fb.hash + mix(k, new)
    stack[k] = new
end

local function newJavaObject(lua)
    local o = { lua = lua, x = 0, y = 0, w = 0, h = 0, visible = true }
    local m = {}
    function m:setX(v) java("other"); self.x = v end
    function m:setY(v) java("other"); self.y = v end
    function m:setWidth(v) java("other"); self.w = v end
    function m:setHeight(v) java("other"); self.h = v end
    function m:setVisible(v) java("other"); self.visible = v end
    function m:isVisible() java("other"); return self.visible end
    function m:getXScroll() java("scroll"); return scene.scrollX end
    function m:getYScroll() java("scroll"); return scene.scrollY end
    -- UIElement.DrawTextureScaledCol（UIElement.java:469-483）
    function m:DrawTextureScaledColor(tex, x, y, w, h, r, g, b, a)
        java("rect")
        if not self.visible then return end
        local dx, dy = x + self.x, y + self.y
        local top = jint(dy + scene.scrollY)
        if top + h < 0 or top > 4096 then return end
        local x0, y0, iw, ih = jint(dx + scene.scrollX), top, jint(w), jint(h)
        local op
        if tex then
            op = string.format("T%s@%d,%d,%d,%d/%.17g,%.17g,%.17g,%.17g", tex.name, x0, y0, iw, ih, r, g, b, a)
        else
            op = string.format("S%.17g,%.17g,%.17g,%.17g", r, g, b, a)
        end
        op = idOf(op)
        local opaque = tex == nil and a >= 1
        for py = y0, y0 + ih - 1 do
            local row = (py + 8192) * 65536 + 8192
            for px = x0, x0 + iw - 1 do plot(row + px, op, opaque) end
        end
    end
    -- UIElement.DrawText(UIFont, ...)（UIElement.java:190-197）
    function m:DrawText(font, text, x, y, r, g, b, a)
        java("text")
        if text == nil then return end
        local ay = y + self.y + scene.scrollY
        local top = jint(ay)
        if top + 100 < 0 or top > 4096 then return end
        fb.texts[#fb.texts + 1] = string.format("%s|%s|%.17g|%.17g|%.17g,%.17g,%.17g,%.17g|%d",
            tostring(font), text, x + self.x + scene.scrollX, ay, r, g, b, a, fb.hash)
    end
    return setmetatable(o, { __index = function(_, k)
        if m[k] then return m[k] end
        return function() java("other") end -- setAnchorLeft 等用不到回傳值的 setter
    end })
end

local function valueOf(key, scale)
    local h = 0
    for i = 1, #key do h = (h * 31 + key:byte(i)) % 1000003 end
    return ((h + scene.frame * 37) % 1000) / 1000 * (scale or 1)
end

local function makePlayer(md)
    local function obj(t)
        return setmetatable(t, { __index = function(_, k) return function() java("other"); return valueOf(k) end end })
    end
    local thermo = obj({
        getCoreTemperature = function() java("other"); return 36 + valueOf("core", 4) end,
    })
    local bodyDamage = obj({
        getHealth = function() java("other"); return valueOf("health", 100) end,
        getThermoregulator = function() java("other"); return thermo end,
    })
    local nutrition = obj({
        getWeight = function() java("other"); return 50 + valueOf("weight", 60) end,
        getCalories = function() java("other"); return valueOf("cal", 5000) - 2000 end,
        isIncWeight = function() java("other"); return scene.frame % 3 == 0 end,
        isIncWeightLot = function() java("other"); return scene.frame % 7 == 0 end,
        isDecWeight = function() java("other"); return scene.frame % 5 == 0 end,
    })
    local statsObj = { get = function(_, key) java("other"); return valueOf(key) end }
    local visual = obj({})
    return {
        getPlayerNum = function() return 0 end,
        getUsername = function() return "tester" end,
        getModData = function() return md end,
        transmitModData = function() end,
        getStats = function() java("other"); return statsObj end,
        getBodyDamage = function() java("other"); return bodyDamage end,
        getNutrition = function() java("other"); return nutrition end,
        getHumanVisual = function() java("other"); return visual end,
        getInventoryWeight = function() java("other"); return valueOf("inv", 40) end,
        getMaxWeight = function() java("other"); return 20 end,
    }
end

-- 每次重建整個 Lua 世界（原版 UI 類別、上游、補丁），補丁改的是類別表，兩邊不能共用
local MUTATION
local function loadWorld(withPatch, activeMods)
    local loaded, created = {}, {}
    local handlers = {}
    Events = setmetatable({}, { __index = function(t, name)
        local ev = { Add = function(fn) handlers[name] = handlers[name] or {}; table.insert(handlers[name], fn) end }
        rawset(t, name, ev)
        return ev
    end })
    UIFont = { Small = "Small", Medium = "Medium", Large = "Large" }
    UIElement = { new = function(lua) local o = newJavaObject(lua); created[#created + 1] = o; return o end }
    UIManager = { AddUI = function() end, RemoveUI = function() end }
    Keyboard = { KEY_BACKSLASH = 43, KEY_L = 38 }
    PZAPI = { ModOptions = { create = function()
        return { addKeyBind = function(_, _, _, key) return { getValue = function() return key end } end }
    end } }
    CharacterStat = setmetatable({}, { __index = function(_, k) return k end })
    BloodBodyPartType = { MAX = { index = function() return 3 end }, FromIndex = function(i) return i end }
    PZMath = { clampFloat = function(v, lo, hi) java("other"); return math.max(lo, math.min(hi, v)) end }
    function getText(key) return key end
    function getTextManager() java("measure"); return {
        MeasureStringX = function(_, _, s) java("measure"); return #s * scene.charW end,
        getFontHeight = function() java("other"); return scene.fontH end,
    } end
    function getTexture(name) java("other"); return { name = name, isJavaTexture = true } end
    function getMouseX() java("other"); return scene.mouseX end
    function getMouseY() java("other"); return scene.mouseY end
    function toInt(v) java("other"); return jint(v) end
    function getCore() return {
        getOptionDisplayAsCelsius = function() java("other"); return true end,
        getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end,
    } end
    function isTable(o) return type(o) == "table" and not o.isJavaTexture end
    function getISUIStackTrace() return nil end
    function getActivatedMods() return { contains = function(_, id) return activeMods[id] == true end } end
    -- 原版 round（shared/luautils.lua:709-712）
    function round(num, idp) local mult = 10 ^ (idp or 0) return math.floor(num * mult + 0.5) / mult end
    ISBaseObject, ISUIElement, ISPanel, ISUITextureGetter, SimpleStatus = nil, nil, nil, nil, nil

    local STUB = { luautils = true, ["ISUI/Style/ISStyle"] = true, ["ISUI/Layout/ISBounds"] = true }
    function require(name)
        name = name:gsub("%.lua$", "")
        if loaded[name] ~= nil then return loaded[name] end
        if STUB[name] then loaded[name] = true return true end
        for _, path in ipairs({ UP .. name .. ".lua", VANILLA .. "client/" .. name .. ".lua", VANILLA .. "shared/" .. name .. ".lua" }) do
            local fh = io.open(path, "r")
            if fh then
                fh:close()
                local ret = assert(loadfile(path))()
                loaded[name] = ret == nil and true or ret
                return loaded[name]
            end
        end
        error("require 找不到：" .. name)
    end
    UIHorizontalAlignment = nil
    require("ISUI/ISPanel")
    -- 上游客戶端依字母序載入（ss.main 會 require 其餘檔）
    require("ss.main")
    if withPatch then
        local source = readFile(PATCH)
        if MUTATION then
            local s, e = source:find(MUTATION.from, 1, true)
            if not s then error("突變片段不在原始碼中：" .. MUTATION.name) end
            source = source:sub(1, s - 1) .. MUTATION.to .. source:sub(e + 1)
        end
        assert(load(source, "@" .. PATCH))()
    end
    for _, fn in ipairs(handlers.OnGameBoot or {}) do fn() end
    return { handlers = handlers, created = created, SSBar = loaded["ISSSBar"] }
end

-- 建一個面板：走上游 ss.main 的 OnCreatePlayer，回傳 SSBar 實體
local function spawnBar(world, md)
    for _, fn in ipairs(world.handlers.OnCreatePlayer) do fn(0, makePlayer({ SimpleStatusConfig = md })) end
    return world.created[#world.created].lua
end

local function runScenario(sc, withPatch)
    scene = { scrollX = sc.scrollX or 0.0, scrollY = sc.scrollY or 0.0, mouseX = sc.mouseX or -1, mouseY = sc.mouseY or -1,
        charW = sc.charW or 7, fontH = sc.fontH or 15, frame = 0 }
    calls = {}
    local world = loadWorld(withPatch, { simpleStatus = true })
    local bar = spawnBar(world, sc.md)
    calls = {}
    local frames = {}
    for f = 1, FRAMES do
        scene.frame = f
        fb = newFb()
        bar:prerender()
        frames[f] = fb
    end
    return frames, calls, world
end

local function sameFrames(a, b)
    for f = 1, FRAMES do
        local fa, fbb = a[f], b[f]
        if fa.hash ~= fbb.hash or #fa.texts ~= #fbb.texts then return false, "frame " .. f .. " hash/text count" end
        for i = 1, #fa.texts do
            if fa.texts[i] ~= fbb.texts[i] then return false, "frame " .. f .. " text " .. i end
        end
        for k, v in pairs(fa.stack) do if fbb.stack[k] ~= v then return false, "frame " .. f .. " pixel " .. k end end
        for k in pairs(fbb.stack) do if fa.stack[k] == nil then return false, "frame " .. f .. " extra pixel " .. k end end
    end
    return true
end

local function allShown(extra)
    local md = { SS_pos_x = 20, SS_pos_y = 630 }
    for _, n in ipairs({ "health", "endurance", "hunger", "thirst", "fatigue", "rest", "happy", "unhappy", "boredom", "pain",
        "panic", "stress", "sickness", "anger", "sanity", "proteins", "calories", "carbohydrates", "lipids", "dirtiness",
        "cleanliness", "weight", "weight_capacity", "bodytemp", "bodyheatgen", "wetness", "intoxication", "poison",
        "food_sickness", "zombie_infection", "zombie_fever", "nicotine_withdrawal", "fitness", "morale", "discomfort",
        "idleness" }) do
        md["SS_shown_" .. n] = true
    end
    for k, v in pairs(extra or {}) do md[k] = v end
    return md
end

local SCENARIOS = {
    { name = "預設設定（水平、刻度開、18 條）", md = {} },
    { name = "全部條目＋三組反轉", md = allShown({ SS_tog_rest = true, SS_tog_unhappy = true, SS_tog_cleanliness = true }) },
    { name = "垂直、滑鼠停在第 3 條（tooltip）", md = allShown({ SS_isVertical = true, SS_pos_x = 40, SS_pos_y = 100 }),
        mouseX = 40 + 2 * (15 + 3) + 8, mouseY = 160 },
    { name = "刻度關閉", md = allShown({ SS_isRulerOn = false }) },
    { name = "面板在原點、字寬 6、字高 11", md = { SS_pos_x = 0, SS_pos_y = 0 }, charW = 6, fontH = 11 },
    { name = "小數座標面板（水平）", md = allShown({ SS_pos_x = 133.5, SS_pos_y = 41.25 }), charW = 9 },
    { name = "小數座標面板（垂直）", md = allShown({ SS_isVertical = true, SS_pos_x = 7.75, SS_pos_y = 300.5 }), charW = 8 },
    { name = "非零 scroll（假設情境）", md = allShown(), scrollX = 3.0, scrollY = -2.0 },
}

local function scenarioDiff(sc)
    local origFrames, origCalls = runScenario(sc, false)
    local patchFrames, patchCalls, world = runScenario(sc, true)
    local same, why = sameFrames(origFrames, patchFrames)
    return same, why, origCalls, patchCalls, origFrames, patchFrames, world
end

local function total(c) local n = 0 for _, v in pairs(c) do n = n + v end return n end
local function fmtCalls(c)
    return string.format("總 %.0f（rect %.0f、scroll %.0f、text %.0f、量字寬 %.0f、其他 %.0f）", total(c) / FRAMES, (c.rect or 0) / FRAMES,
        (c.scroll or 0) / FRAMES, (c.text or 0) / FRAMES, (c.measure or 0) / FRAMES, (c.other or 0) / FRAMES)
end

-- ===== 情境 =====
local args = {}
for _, a in ipairs(arg or {}) do args[a] = true end

local function suite()
    for i, sc in ipairs(SCENARIOS) do
        local same, why, oc, pc, of, pf, world = scenarioDiff(sc)
        check(sc.name .. "：畫面逐像素相同" .. (same and "" or "（" .. why .. "）"), same)
        check(sc.name .. "：補丁已安裝", world.SSBar.MSP_rulerBatch == true)
        local texts = 0
        for f = 1, FRAMES do texts = texts + #of[f].texts end
        check(sc.name .. "：有畫到東西（文字 " .. texts .. "）", of[1].hash ~= 0 and (texts > 0 or sc.md.SS_isVertical))
        if i == 1 or i == 3 or i == 4 then
            if not quiet then
                rawPrint("        每幀 Java 呼叫  原樣 " .. fmtCalls(oc))
                rawPrint("                        補丁 " .. fmtCalls(pc))
            end
        end
        if i == 1 then -- 預設 18 條；上游預設條目變多要重估
            check("預設設定：原樣每幀 > 1,500 次 Java 呼叫", total(oc) / FRAMES > 1500)
            check("預設設定：補丁每幀 < 450 次 Java 呼叫", total(pc) / FRAMES < 450)
        end
        if sc.md.SS_isRulerOn ~= false then
            check(sc.name .. "：Java 呼叫至少少一半", total(pc) * 2 < total(oc))
        end
    end
end

suite()

-- 上游缺席：不註冊事件、不 require 上游、不印
do
    printed = {}
    local world = loadWorld(true, {})
    check("上游缺席：補丁沒有註冊 OnGameBoot", world.handlers.OnGameBoot == nil)
    check("上游缺席：靜默", #printed == 0)
end
-- 只認反斜線前綴的 mod id 也要裝
do
    printed = {}
    local world = loadWorld(true, { ["\\simpleStatus"] = true })
    check("mod id 帶反斜線：已安裝", world.SSBar.MSP_rulerBatch == true and #printed == 1)
end
-- 重複觸發 OnGameBoot 不疊包裝
do
    printed = {}
    scene = { scrollX = 0.0, scrollY = 0.0, charW = 7, fontH = 15, frame = 0 }
    calls = {}
    local world = loadWorld(true, { simpleStatus = true })
    local prerender = world.SSBar.prerender
    for _, fn in ipairs(world.handlers.OnGameBoot) do fn() end
    check("重複 OnGameBoot：prerender 沒被再包一層", world.SSBar.prerender == prerender and #printed == 1)
end
-- prerender 之外呼叫 drawRectStatic 走原版（含 scroll getter）
do
    scene = { scrollX = 0.0, scrollY = 0.0, charW = 7, fontH = 15, frame = 0 }
    calls = {}
    local world = loadWorld(true, { simpleStatus = true })
    local bar = spawnBar(world, {})
    fb = newFb()
    bar:prerender()
    calls = {}
    bar:drawRectStatic(0, 0, 1, 1, 1, 1, 1, 1)
    check("prerender 之外：drawRectStatic 走原版（2 次 scroll getter）", calls.scroll == 2 and calls.rect == 1)
end
-- 上游形狀不符：印一行 NOT installed，上游原樣
do
    printed = {}
    scene = { scrollX = 0.0, scrollY = 0.0, charW = 7, fontH = 15, frame = 0 }
    calls = {}
    local world = loadWorld(false, { simpleStatus = true })
    world.SSBar.drawRuler = nil
    local before = world.SSBar.prerender
    assert(load(readFile(PATCH), "@" .. PATCH))()
    for _, fn in ipairs(world.handlers.OnGameBoot) do fn() end
    check("上游形狀不符：NOT installed 一行、prerender 原樣",
        #printed == 1 and printed[1]:find("NOT installed", 1, true) ~= nil and world.SSBar.prerender == before)
end

if args["--mutants"] then
    local MUTANTS = {
        { name = "白色先畫、墊底後畫", from = "        self:drawRectStatic(x - 1, y - 1, w + 2, h + 2, c.a, c.r, c.g, c.b)\n        self:drawRectStatic(x, y, w, h, 1.0, 1.0, 1.0, 1.0)",
            to = "        self:drawRectStatic(x, y, w, h, 1.0, 1.0, 1.0, 1.0)\n        self:drawRectStatic(x - 1, y - 1, w + 2, h + 2, c.a, c.r, c.g, c.b)" },
        { name = "墊底少 1 像素", from = "w + 2, h + 2", to = "w + 1, h + 2" },
        { name = "垂直刻度寬高沒對調", from = "y, w, h = y + (1 - p) * self.barLength, 4, 2", to = "y = y + (1 - p) * self.barLength" },
        { name = "忘了扣 scroll", from = "x - sx, y - self.MSP_scrollY", to = "x, y" },
        { name = "白色 alpha 不是 1", from = "1.0, 1.0, 1.0, 1.0)", to = "0.99, 1.0, 1.0, 1.0)" },
    }
    FRAMES = 1 -- 突變只要抓得到；第一幀就畫齊全部刻度
    for _, mt in ipairs(MUTANTS) do
        MUTATION = mt
        quiet = true
        local passBefore, failBefore = pass, fail
        suite()
        local caught = fail > failBefore
        pass, fail, quiet = passBefore, failBefore, false
        check("突變被抓到：" .. mt.name, caught)
    end
    MUTATION = nil
end

if args["--bench"] then
    local function bench(withPatch)
        scene = { scrollX = 0.0, scrollY = 0.0, charW = 7, fontH = 15, frame = 0 }
        calls = {}
        local world = loadWorld(withPatch, { simpleStatus = true })
        local bar = spawnBar(world, {})
        for _, o in ipairs(world.created) do -- 不畫像素，只留呼叫成本
            o.DrawTextureScaledColor = function() calls.rect = (calls.rect or 0) + 1 end
            o.DrawText = function() calls.text = (calls.text or 0) + 1 end
        end
        local N = 20000
        local t0 = os.clock()
        for f = 1, N do scene.frame = f; bar:prerender() end
        return (os.clock() - t0) / N * 1e6
    end
    local a, b = bench(false), bench(true)
    rawPrint(string.format("  BENCH  標準 Lua 每次 prerender：原樣 %.1f µs、補丁 %.1f µs（%.0f%%）", a, b, b / a * 100))
end

rawPrint(string.format("\n%d 通過、%d 失敗", pass, fail))
if fail > 0 then os.exit(1) end
