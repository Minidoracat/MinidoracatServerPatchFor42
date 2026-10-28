-- 離線測試：Vanilla Foods Expanded 載入瘦身（MSP_VfeLoadSlim）。載入「未修改的」上游 shared/vfx_squareload.lua（本機 Steam 訂閱副本），
-- 同一批格子各跑一次「上游原樣」與「補丁」，比對每個 listener 收到的呼叫（格子、地上物品數、有沒有容器）、上游 Debug 計數的 log
-- 與 LoadGridsquare 回呼清單；另驗空格子不進上游（上游每次被呼叫都會 getObjects，補丁不會）。listener 用假的，名稱與
-- ground／containers 旗標照上游原始碼的 SquareLoad.add 讀出：補丁只決定上游合併回呼何時被呼叫，不碰 listener 本身。
--   lua scripts/test_vfe_load_slim.lua            上游前提、等價差分、時序、回退
--   lua scripts/test_vfe_load_slim.lua --mutants  另對補丁植入錯誤，確認測試抓得到
-- 引擎模擬（反編譯 42.21.0）：
-- - 專用伺服器依 Mods= 逐 MOD 載入 shared/，再逐 MOD 載入 server/（LuaManager.java:1151-1188、GameServer.java:1469-1471），
--   之後讀沙盒、OnGameBoot、OnInitGlobalModData。
-- - LoadGridsquare 只對有物件的格子觸發（IsoChunk.java:3800-3839）；Event.trigger 每圈重讀清單長度（Event.java:52-64）。
-- - getContainerCount＝主容器＋次要容器，次要容器只在有主容器時存在（IsoObject.java:5194-5198、:1247-1262）；
--   getObjectContainers 收各物件的主容器、不重複（IsoGridSquare.java:9998-10009）。

local MODROOT = "D:/SteamLibrary/steamapps/workshop/content/108600/3577903007/mods/Vanilla Foods Expanded/"
local WS = MODROOT .. "42.18/"
local SQ = WS .. "media/lua/shared/vfx_squareload.lua"
local SHARED = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/shared/Patches/"
local PATCH = {
    dispatch = SHARED .. "MSP_ChunkSquareDispatch.lua",
    vfe = SHARED .. "VanillaFoodsExpanded/MSP_VfeLoadSlim.lua",
}
local ARGS = {}
for _, a in ipairs(arg or {}) do ARGS[a] = true end

local function readFile(path)
    local fh = io.open(path, "rb")
    if not fh then error("找不到檔案（上游需本機已訂閱）：" .. path) end
    local text = fh:read("a")
    fh:close()
    return text
end

local pass, fail = 0, 0
local rawPrint = print
local function check(name, cond)
    if cond then pass = pass + 1; rawPrint("  PASS  " .. name) else fail = fail + 1; rawPrint("  FAIL  " .. name) end
end

-- BufferedReader.readLine 的切行（\n、\r\n、\r；最後一行沒有換行也算一行）：getModFileReader 回傳的就是它
local function javaLines(text)
    local lines, pos = {}, 1
    while pos <= #text do
        local s, e = text:find("\r\n?", pos)
        local n = text:find("\n", pos, true)
        if n and (not s or n < s) then s, e = n, n end
        if not s then lines[#lines + 1] = text:sub(pos); break end
        lines[#lines + 1] = text:sub(pos, s - 1)
        pos = e + 1
    end
    return lines
end

-- 補丁的上游雜湊（與補丁同一算法）
local function fileHash(text)
    local h, n = 0, 0
    for _, line in ipairs(javaLines(text)) do
        for i = 1, #line do h = (h * 31 + line:byte(i)) % 2147483647 end
        h = (h * 31 + 10) % 2147483647
        n = n + 1
    end
    return n, h
end

-- ===== 1. 上游前提 =====
rawPrint("上游前提（upstream.json recheck）")
local lines, hash = fileHash(readFile(SQ))
local patchLines, patchHash = readFile(PATCH.vfe):match("lines = (%d+), hash = (%d+)")
local upstreamCurrent = tonumber(patchLines) == lines and tonumber(patchHash) == hash
check(string.format("補丁核對的 vfx_squareload.lua 和本機副本相同（本機 lines = %d, hash = %d）", lines, hash), upstreamCurrent)

local FLAGS, removers = {}, {}
local listing = io.popen('dir /b /s "' .. MODROOT:gsub("/", "\\") .. '*.lua" 2>nul')
for path in listing:lines() do
    local text = readFile(path)
    for name, ground, containers in text:gmatch('SquareLoad%.add%(%s*"([%w_]+)"%s*,%s*[%w_.]+%s*,%s*(%a+)%s*,%s*(%a+)%s*%)') do
        FLAGS[name] = { ground = ground == "true", containers = containers == "true" }
    end
    for name in text:gmatch('SquareLoad%.remove%(%s*"([%w_]+)"') do removers[#removers + 1] = name end
end
listing:close()
local listeners = {}
for name in pairs(FLAGS) do listeners[#listeners + 1] = name end
table.sort(listeners)
check("VFE 掛 SquareLoad 的只有 aging、birthday、story（實際：" .. table.concat(listeners, "、") .. "）",
    table.concat(listeners, ",") == "aging,birthday,story")
check("只有 birthday 會從 SquareLoad 移除自己（實際：" .. table.concat(removers, "、") .. "）",
    table.concat(removers, ",") == "birthday")
if not (FLAGS.aging and FLAGS.story and FLAGS.birthday) then
    rawPrint(string.format("\n%d passed, %d failed", pass, fail + 1))
    os.exit(1)
end

-- ===== 2. 假引擎 =====
local S -- 每次執行的狀態
local MUTATION -- { name, edits = { { from, to } } }（只改補丁檔）

local function jc(name)
    if S.phase == "empty" and not (VFX and VFX.SquareLoad and VFX.SquareLoad.Debug) then
        S.emptyJava[name] = (S.emptyJava[name] or 0) + 1
        S.emptyJava.total = (S.emptyJava.total or 0) + 1
    end
end

function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    local line = table.concat(parts, " ")
    if line:find("MinidoracatServerPatchFor42", 1, true) then S.patchPrints[#S.patchPrints + 1] = line
    else S.log[#S.log + 1] = "print " .. line end
end

local function newEvent(name)
    local event = { list = {}, name = name }
    function event.Add(fn) if type(fn) == "function" then event.list[#event.list + 1] = fn end end
    function event.Remove(fn)
        for i, f in ipairs(event.list) do if f == fn then table.remove(event.list, i); return end end
    end
    event.engineAdd = event.Add
    return event
end
local function trigger(event, ...)
    local n = 1
    while n <= #event.list do
        local fn = event.list[n]
        local ok, err = pcall(fn, ...)
        if not ok then S.log[#S.log + 1] = "error " .. event.name .. " " .. tostring(err) end
        local still = false
        for _, f in ipairs(event.list) do if f == fn then still = true; break end end
        if still then n = n + 1 end
    end
end

local List = {}; List.__index = List
function List:size() jc("size"); return #self.t end
function List:get(i) jc("get"); return self.t[i + 1] end
function List:isEmpty() jc("isEmpty"); return #self.t == 0 end
function List:clear() jc("clear"); for i = #self.t, 1, -1 do self.t[i] = nil end end
local function newList(t) return setmetatable({ t = t or {} }, List) end

local Obj = {}; Obj.__index = Obj
function Obj:getContainerCount() jc("getContainerCount"); return (self.primary and 1 or 0) + self.secondary end

local Square = {}; Square.__index = Square
function Square:getWorldObjects() jc("getWorldObjects"); return self.world end
function Square:getObjects() jc("getObjects"); return self.objects end
function Square:getObjectContainers(_, _, list)
    jc("getObjectContainers")
    for _, o in ipairs(self.objects.t) do
        local seen = o.primary == nil
        for _, c in ipairs(list.t) do if c == o.primary then seen = true end end
        if not seen then list.t[#list.t + 1] = o.primary end
    end
end

IsoGridSquare, ArrayList, ItemContainer = { class = "C:IsoGridSquare" }, { class = "C:ArrayList" }, { class = "C:ItemContainer" }
PZArrayList = { class = "C:PZArrayList", new = function() return newList() end }
local CLASS_METATABLES = { ["C:IsoGridSquare"] = { __index = Square }, ["C:ArrayList"] = { __index = List },
    ["C:PZArrayList"] = { __index = List } }

function isServer() return S.server end
function isClient() return not S.server end
function getActivatedMods() return { contains = function(_, id) return S.mods[id] == true end } end
function getFilenameOfClosure(fn) return (debug.getinfo(fn, "S").source:gsub("^@", ""):gsub("\\", "/")) end
function getModFileReader(modId, path)
    if modId ~= "VanillaFoodsExpanded" or (S.missing or {})[path] then return nil end -- 檔不存在／開檔失敗時引擎回 nil
    local all, i = javaLines((S.fileOverride or {})[path] or readFile(WS .. path)), 0
    return { readLine = function() i = i + 1; return all[i] end, close = function() end }
end

local function loadPatch(path)
    local source = readFile(path)
    if MUTATION and path == PATCH.vfe then
        for _, edit in ipairs(MUTATION.edits) do
            local s, e = source:find(edit.from, 1, true)
            if not s then error("突變片段不在原始碼中：" .. MUTATION.name) end
            source = source:sub(1, s - 1) .. edit.to .. source:sub(e + 1)
        end
    end
    return assert(load(source, "@" .. path))()
end

function require(name)
    if S.loaded[name] ~= nil then return S.loaded[name] end
    local result
    if name == "Patches/MSP_ChunkSquareDispatch" then result = loadPatch(PATCH.dispatch)
    elseif name == "vfx_squareload" then result = assert(load(readFile(SQ), "@" .. SQ))()
    else error("未預期的 require：" .. name) end
    S.loaded[name] = result
    return result
end

-- listener 與其他 MOD 的 LoadGridsquare 回呼：記下收到什麼
local function listener(name)
    return function(square, worldObjects, hasContainers)
        S.log[#S.log + 1] = string.format("%s %s ground=%s containers=%s", name, square.id,
            worldObjects and tostring(#worldObjects.t) or "nil", tostring(hasContainers))
    end
end
-- mutate：回呼順便清掉格子上的地上物品（驗回呼之間的先後：排在 VFE 之後的回呼改了格子，VFE 就得先看到原樣）
local function other(name, mutate)
    local fn = function(square)
        S.log[#S.log + 1] = name .. " " .. square.id
        if mutate then square.world.t = {} end
    end
    S.labels[fn] = name
    return fn
end

-- ===== 3. 世界 =====
local function newRng(seed)
    local s = seed
    return function() s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648 end
end
local function makeSquare(rng, id)
    local world, objects, any = {}, {}, false
    if rng() < 0.12 then for i = 1, rng() < 0.5 and 1 or 2 do world[i] = { id = id .. "w" .. i } end end
    for i = 1, 1 + math.floor(rng() * 3) do
        local o = setmetatable({ secondary = 0 }, Obj)
        if rng() < 0.08 then
            o.primary = { id = id .. "c" .. i }
            any = true
            if rng() < 0.3 then o.secondary = 1 + math.floor(rng() * 2) end
        end
        objects[i] = o
    end
    return setmetatable({ id = id, world = newList(world), objects = newList(objects), empty = #world == 0 and not any }, Square)
end
-- opts：order（patchFirst＝Mods= 本 MOD 在 VFE 之前／vfeFirst）、birthdayAtBoot、birthdayCycle、debugToggle、
-- noAging、noStory、earlyAdd（VFE shared 載入時就有 listener）、tmpCycle（server 載入時 listener 清空又加入）、
-- sandboxOff、mods、server、fileOverride、noJava
local function randomSpec(seed, opts)
    local spec, rng = {}, newRng(seed)
    for k, v in pairs(opts or {}) do spec[k] = v end
    spec.frames = {}
    for f = 1, 30 do
        local frame = { squares = {} }
        for i = 1, 40 do frame.squares[i] = makeSquare(rng, f .. ":" .. i) end
        if spec.debugToggle and f == 10 then frame.debug = true elseif spec.debugToggle and f == 20 then frame.debug = false end
        if spec.birthdayCycle and f % 7 == 0 then frame.birthday = (f // 7) % 2 == 1 and "add" or "remove" end
        frame.tenMinutes = f % 5 == 0
        spec.frames[f] = frame
    end
    return spec
end

local function addListener(name)
    local flags = FLAGS[name] or { ground = true, containers = true }
    VFX.SquareLoad.add(name, S.fns[name], flags.ground, flags.containers)
end

local function boot(mode, spec)
    Events = {}
    for _, name in ipairs({ "LoadGridsquare", "LoadChunk", "OnGameBoot", "OnInitGlobalModData", "EveryTenMinutes" }) do
        Events[name] = newEvent(name)
    end
    VFX, MSP_ChunkSquareDispatch, MSP_VfeLoadSlim = nil, nil, nil
    SandboxVars = nil -- 引擎在 shared／server 載入之後才讀沙盒（GameServer.java:1469-1488）
    __classmetatables = spec.noJava and {} or CLASS_METATABLES
    local vfe = S.mods.VanillaFoodsExpanded
    local function ours() if mode == "patched" then loadPatch(PATCH.vfe) end end
    local function vfeShared()
        if not vfe then return end
        require "vfx_squareload"
        if spec.earlyAdd then addListener("early") end
        Events.OnInitGlobalModData.Add(function() if spec.birthdayAtBoot then addListener("birthday") end end)
    end
    -- shared/
    Events.LoadGridsquare.Add(other("before"))
    if spec.order == "vfeFirst" then vfeShared(); ours() else ours(); vfeShared() end
    S.addUntouchedAfterShared = Events.LoadGridsquare.Add == Events.LoadGridsquare.engineAdd
    -- server/
    if spec.wrapAdd then -- 別的 MOD 在本補丁之後又包了一層 Add：共用攔截器就不還原（MSP_ChunkSquareDispatch 的 restore）
        local inner = Events.LoadGridsquare.Add
        Events.LoadGridsquare.Add = function(fn) return inner(fn) end
    end
    if vfe then
        if spec.tmpCycle then addListener("tmp"); VFX.SquareLoad.remove("tmp") end
        if not spec.noAging then addListener("aging") end
    end
    Events.LoadGridsquare.Add(other("between", spec.mutateBetween))
    if vfe and not spec.noStory then addListener("story") end
    Events.LoadGridsquare.Add(other("after"))
    SandboxVars = { MinidoracatServerPatchFor42 = { SlimVfeLoad = not spec.sandboxOff } }
    trigger(Events.OnGameBoot)
    trigger(Events.OnInitGlobalModData)
end

local function snapshot(list)
    local wrapper = MSP_VfeLoadSlim and MSP_VfeLoadSlim.handlers and (MSP_VfeLoadSlim.handlers())
    local labels, raw = {}, { wrapper = 0, upstream = 0 }
    for _, fn in ipairs(list) do
        if fn == wrapper then raw.wrapper = raw.wrapper + 1; labels[#labels + 1] = "vfe"
        elseif getFilenameOfClosure(fn):lower():find("/lua/shared/vfx_squareload.lua", 1, true) then
            raw.upstream = raw.upstream + 1; labels[#labels + 1] = "vfe"
        else labels[#labels + 1] = S.labels[fn] or "?" end
    end
    return table.concat(labels, ","), raw
end

local function run(spec, mode)
    S = { log = {}, patchPrints = {}, emptyJava = {}, loaded = {}, labels = {}, emptySquares = 0,
        server = spec.server ~= false, mods = spec.mods or { VanillaFoodsExpanded = true }, fileOverride = spec.fileOverride,
        missing = spec.missing }
    S.fns = {}
    for _, name in ipairs({ "aging", "story", "birthday", "early", "tmp" }) do S.fns[name] = listener(name) end
    boot(mode, spec)
    S.bootOrder, S.bootRaw = snapshot(Events.LoadGridsquare.list)
    S.maxRaw = { wrapper = S.bootRaw.wrapper, upstream = S.bootRaw.upstream }
    for _, frame in ipairs(spec.frames) do
        if VFX and VFX.SquareLoad then
            if frame.debug ~= nil then VFX.SquareLoad.Debug = frame.debug end
            if frame.birthday == "add" then addListener("birthday") elseif frame.birthday == "remove" then VFX.SquareLoad.remove("birthday") end
        end
        local _, raw = snapshot(Events.LoadGridsquare.list)
        S.maxRaw.wrapper = math.max(S.maxRaw.wrapper, raw.wrapper)
        S.maxRaw.upstream = math.max(S.maxRaw.upstream, raw.upstream)
        for _, square in ipairs(frame.squares) do
            S.phase = square.empty and "empty" or "full"
            if square.empty and not (VFX and VFX.SquareLoad and VFX.SquareLoad.Debug) then S.emptySquares = S.emptySquares + 1 end
            trigger(Events.LoadGridsquare, square)
            S.phase = nil
        end
        if frame.tenMinutes then trigger(Events.EveryTenMinutes) end
    end
    S.finalOrder, S.finalRaw = snapshot(Events.LoadGridsquare.list)
    S.installed = MSP_VfeLoadSlim ~= nil and MSP_VfeLoadSlim.installed == true
    return S
end

-- 差分：perLabel＝各回呼自己的呼叫序列分開比（換回上游原樣時，上游排到 LoadGridsquare 清單最後，彼此的先後會變）
local function byLabel(log)
    local groups = {}
    for _, line in ipairs(log) do
        local label = line:match("^(%S+)")
        groups[label] = groups[label] or {}
        groups[label][#groups[label] + 1] = line
    end
    return groups
end
-- spec 可以是函式（每次執行重建世界：有回呼會改格子時，兩次執行不能共用同一批格子）
local function differential(spec, perLabel)
    local function fresh() return type(spec) == "function" and spec() or spec end
    local u, p = run(fresh(), "upstream"), run(fresh(), "patched")
    if perLabel then
        local gu, gp = byLabel(u.log), byLabel(p.log)
        for label, list in pairs(gu) do
            local other = gp[label] or {}
            for i = 1, math.max(#list, #other) do
                if list[i] ~= other[i] then
                    return string.format("%s 第 %d 筆：上游 %s／補丁 %s", label, i, tostring(list[i]), tostring(other[i])), u, p
                end
            end
        end
        for label in pairs(gp) do if not gu[label] then return "補丁多出 " .. label, u, p end end
    else
        for i = 1, math.max(#u.log, #p.log) do
            if u.log[i] ~= p.log[i] then
                return string.format("第 %d 筆：上游 %s／補丁 %s", i, tostring(u.log[i]), tostring(p.log[i])), u, p
            end
        end
        if u.finalOrder ~= p.finalOrder then return "回呼清單：上游 " .. u.finalOrder .. "／補丁 " .. p.finalOrder, u, p end
    end
    return nil, u, p
end

local function printed(r, text)
    return #r.patchPrints == 1 and r.patchPrints[1]:find(text, 1, true) ~= nil
end

-- ===== 4. 情境 =====
local function scenarios(expect)
    local spent = { upstream = 0, patched = 0, squares = 0 }
    for _, order in ipairs({ "patchFirst", "vfeFirst" }) do
        for _, atBoot in ipairs({ false, true }) do
            for seed = 1, 3 do
                local spec = randomSpec(seed * 10 + (atBoot and 1 or 0), { order = order, birthdayAtBoot = atBoot,
                    birthdayCycle = true, debugToggle = true })
                local problem, u, p = differential(spec)
                local tag = string.format("%s、birthday %s、seed %d", order, atBoot and "開機就掛" or "執行中才掛", seed)
                expect("等價（" .. tag .. "）：listener 呼叫、Debug 計數 log、回呼位置都相同" .. (problem and ("；" .. problem) or ""),
                    problem == nil)
                expect("安裝（" .. tag .. "）：印一行 installed、installed 為真、引擎上只有包裝", printed(p, "load slim installed")
                    and p.installed and p.maxRaw.wrapper == 1 and p.maxRaw.upstream == 0 and p.finalRaw.wrapper == 1)
                expect("空格子不進上游（" .. tag .. "）：補丁 getObjects 0 次（上游 " .. tostring(u.emptyJava.getObjects) .. " 次）",
                    (p.emptyJava.getObjects or 0) == 0 and (p.emptyJava.getContainerCount or 0) == 0 and (u.emptyJava.getObjects or 0) > 0)
                spent.upstream = spent.upstream + (u.emptyJava.total or 0)
                spent.patched = spent.patched + (p.emptyJava.total or 0)
                spent.squares = spent.squares + u.emptySquares
            end
        end
    end
    if expect == check then
        rawPrint(string.format("  （空格子平均 Java 呼叫：上游 %.2f、補丁 %.2f）", spent.upstream / spent.squares, spent.patched / spent.squares))
    end

    local problem, _, p = differential(randomSpec(41, { tmpCycle = true, birthdayCycle = true }))
    expect("server 載入中 listener 清空又加入：上游再 Add 由補丁吞掉、不重複註冊" .. (problem and ("；" .. problem) or ""),
        problem == nil and p.maxRaw.wrapper == 1 and p.maxRaw.upstream == 0)

    problem, _, p = differential(randomSpec(42, { earlyAdd = true, order = "patchFirst" }))
    expect("VFE shared 載入時就有 listener、本 MOD 在前：照樣攔到" .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "load slim installed"))
    problem, _, p = differential(randomSpec(43, { earlyAdd = true, order = "vfeFirst" }))
    expect("VFE shared 載入時就有 listener、VFE 在前：攔不到就印 NOT installed、上游原樣" .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "registration not seen") and p.finalRaw.upstream == 1 and p.finalRaw.wrapper == 0)

    problem, _, p = differential(function()
        return randomSpec(44, { sandboxOff = true, birthdayCycle = true, debugToggle = true, mutateBetween = true })
    end)
    expect("沙盒關閉：包裝留在原位、每格照樣轉交上游（排在後面的回呼改了格子也等價）" .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "disabled by sandbox option") and not p.installed and p.finalRaw.wrapper == 1
        and p.finalRaw.upstream == 0 and (p.emptyJava.getObjects or 0) > 0)
    problem, _, p = differential(function() return randomSpec(50, { mutateBetween = true, birthdayCycle = true }) end)
    expect("排在後面的回呼會改格子：照樣等價" .. (problem and ("；" .. problem) or ""), problem == nil and p.installed)

    problem, _, p = differential(randomSpec(45, { noAging = true, noStory = true, birthdayAtBoot = true, birthdayCycle = true }), true)
    expect("aging、story 都沒在聽（只有 birthday 會增減）：換回上游原樣，之後增減也不重複註冊" .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "neither aging nor story") and not p.installed and p.maxRaw.upstream <= 1
        and p.finalRaw.wrapper == 0)
    problem, _, p = differential(randomSpec(51, { noAging = true, noStory = true, tmpCycle = true, birthdayCycle = true }), true)
    expect("換回上游時 listener 已清空：不交給引擎，birthday 之後加入時上游自己註冊一次" .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "neither aging nor story") and p.maxRaw.upstream <= 1 and p.finalRaw.wrapper == 0)
    problem, _, p = differential(randomSpec(52, { noAging = true, noStory = true, birthdayAtBoot = true, birthdayCycle = true,
        wrapAdd = true }), true)
    expect("別的 MOD 之後又包了 Add（攔截器沒還原）：換回時上游的 Add 照樣交給引擎" .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "neither aging nor story") and p.maxRaw.upstream <= 1 and p.finalRaw.wrapper == 0)
    problem, _, p = differential(randomSpec(53, { wrapAdd = true, birthdayCycle = true }))
    expect("別的 MOD 之後又包了 Add：正常安裝且等價" .. (problem and ("；" .. problem) or ""), problem == nil and p.installed)
    problem, _, p = differential(randomSpec(46, { noAging = true, birthdayCycle = true }))
    expect("只有 story 在聽：照樣安裝且等價" .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "load slim installed"))

    local changed = readFile(SQ) .. "-- changed\n"
    problem, _, p = differential(randomSpec(47, { fileOverride = { ["media/lua/shared/vfx_squareload.lua"] = changed } }))
    expect("上游 vfx_squareload.lua 改過：印 NOT installed、不換 LoadGridsquare.Add、上游原樣" .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "differs from the reviewed version") and p.addUntouchedAfterShared and p.finalRaw.wrapper == 0)
    local removing = readFile(WS .. "media/lua/server/vfx_agingmanager.lua") .. '\nSquareLoad.remove("aging")\n'
    problem, _, p = differential(randomSpec(54, { fileOverride = { ["media/lua/server/vfx_agingmanager.lua"] = removing } }))
    expect("aging 會移除自己：印 NOT installed、不換 LoadGridsquare.Add、上游原樣" .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "never removes itself from SquareLoad") and p.addUntouchedAfterShared)
    problem, _, p = differential(randomSpec(55, { missing = { ["media/lua/server/vfx_storydistribution.lua"] = true } }))
    expect("story 檔讀不到（確認不了不會移除自己）：印 NOT installed、不換 LoadGridsquare.Add、上游原樣"
        .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "never removes itself from SquareLoad") and p.addUntouchedAfterShared)
    problem, _, p = differential(randomSpec(48, { noJava = true }))
    expect("預先取 Java 方法失敗：印 NOT installed、上游原樣" .. (problem and ("；" .. problem) or ""),
        problem == nil and printed(p, "Java method lookup failed") and p.addUntouchedAfterShared)

    for _, case in ipairs({ { "沒有啟用 VFE", { mods = {} } }, { "客戶端", { server = false } } }) do
        p = run(randomSpec(49, case[2]), "patched")
        expect(case[1] .. "：零行為（不印 log、不換 LoadGridsquare.Add、不設全域）",
            #p.patchPrints == 0 and p.addUntouchedAfterShared and MSP_VfeLoadSlim == nil)
    end
end

rawPrint("\n等價差分、時序、回退")
if upstreamCurrent then scenarios(check) else rawPrint("  （補丁核對的不是本機這版，差分略過；重核後更新補丁常數）") end

-- ===== 5. 突變 =====
if ARGS["--mutants"] and upstreamCurrent then
    rawPrint("\n突變測試（每個突變都必須讓上面至少一項失敗）")
    local MUTANTS = {
        { name = "沒有地上物品就略過（漏掉只有容器的格子）",
            edits = { { from = "if listIsEmpty(found) then return end", to = "do return end" } } },
        { name = "只看容器（漏掉只有地上物品的格子）",
            edits = { { from = "arrayIsEmpty(getWorldObjects(square)) and not squareLoad.Debug then",
                to = "not squareLoad.Debug then" } } },
        { name = "Debug 開著也略過", edits = { { from = " and not squareLoad.Debug", to = "" } } },
        { name = "收完容器不清空清單", edits = { { from = "listClear(found)", to = "local _ = found" } } },
        { name = "上游再 Add 時又交給引擎", edits = { { from = "if upstream then return swallow and fn == upstream end",
            to = "if upstream then return false end" } } },
        { name = "換回上游後仍吞掉上游的 Add", edits = { { from = "swallow = false", to = "local _ = false" } } },
        { name = "不檢查 aging／story 有沒有在聽", edits = { {
            from = 'if not (squareLoad.isListening("aging") or squareLoad.isListening("story")) then', to = "if false then" } } },
        { name = "換回上游時不看還有沒有 listener 就交給引擎", edits = { {
            from = 'if squareLoad.isListening("birthday") then Events.LoadGridsquare.Add(upstream) end',
            to = "Events.LoadGridsquare.Add(upstream)" } } },
        { name = "換回上游時沒移除包裝", edits = { { from = "Events.LoadGridsquare.Remove(onSquare)", to = "local _ = onSquare" } } },
        { name = "沙盒關閉仍做前置判斷", edits = { { from = "slim = false\n", to = "local _ = false\n" } } },
        { name = "沙盒關閉時換回上游（移到清單最後）", edits = { { from = "slim = false\n",
            to = "swallow = false; Events.LoadGridsquare.Remove(onSquare); Events.LoadGridsquare.Add(upstream)\n" } } },
        { name = "沙盒在載入時就讀", edits = {
            { from = "local upstream -- vfx_squareload.lua 的 onLoadGridsquare",
                to = "local EARLY = SandboxVars and SandboxVars.MinidoracatServerPatchFor42\nlocal upstream" },
            { from = "local options = SandboxVars and SandboxVars.MinidoracatServerPatchFor42", to = "local options = EARLY" } } },
        { name = "不核對上游雜湊", edits = { { from = "if not upstreamMatches(SQUARELOAD) then", to = "if false then" } } },
        { name = "不檢查 aging／story 會不會移除自己", edits = { {
            from = 'if upstreamMayMention(path, "SquareLoad.remove") then', to = "if false then" } } },
        { name = "讀不到 aging／story 檔就當成不會移除自己", edits = { {
            from = "if not reader then return true end", to = "if not reader then return false end" } } },
    }
    for _, mutant in ipairs(MUTANTS) do
        MUTATION = mutant
        local failed, first = 0, nil
        local ok, err = pcall(scenarios, function(name, cond)
            if not cond then failed = failed + 1; first = first or name end
        end)
        MUTATION = nil
        local missing = not ok and tostring(err):find("突變片段不在原始碼中", 1, true) ~= nil
        local why = ok and first or ("執行錯誤：" .. tostring(err))
        local cut = why and utf8.offset(why, 61)
        check("突變被抓到：" .. mutant.name .. (why and ("（" .. (cut and why:sub(1, cut - 1) or why) .. "）") or ""),
            not missing and (not ok or failed > 0))
    end
end

rawPrint(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
