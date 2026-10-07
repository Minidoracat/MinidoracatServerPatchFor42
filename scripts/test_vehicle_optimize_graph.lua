-- 離線測試：MSP_VehicleOptimizeGraph（W900 蒙皮車輛模型加 postProcess = +OPTIMIZE_GRAPH）。
-- 以「未修改的」上游模型腳本（本機 Steam 訂閱副本：W900，以及不在白名單的 KI5 M998、Oshkosh 拖車尾門）建假 ScriptManager，
-- 假 ModelScript:Load 照 ModelScript.java:54-109 只設 body 寫到的欄位（不 reset），比對補丁前後每個模型腳本的欄位。
--   lua scripts/test_vehicle_optimize_graph.lua             行為與邊界
--   lua scripts/test_vehicle_optimize_graph.lua --mutants   另對補丁植入錯誤，確認測試抓得到
-- 引擎模擬：client Lua 在 ScriptManager.Load 之後才載入（Core.java:3931、3949），所以補丁載入時模型腳本都已就緒；
-- ScriptManager.getModelScript 接受 "Module.Name"（ScriptBucketCollection.java:72-90）。

local WS = os.getenv("PZ_WORKSHOP_DIR") or "D:/SteamLibrary/steamapps/workshop/content/108600"
local UPSTREAM_FILES = {
    WS .. "/3409472393/mods/rSemiTruck/common/media/scripts/vehicles/vehicles_rSemiTruck_models.txt",
    WS .. "/2642541073/mods/92amgeneralM998/42.13/media/scripts/vehicles/template_M998_doors.txt",
    WS .. "/2566953935/mods/86oshkoshP19A/42.13/media/scripts/vehicles/template_M10XX_trunkdoors.txt",
}
local PATCH = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/client/Patches/rSemiTruck/MSP_VehicleOptimizeGraph.lua"
local EXPECT_BODY_VALUES = { postProcess = "+OPTIMIZE_GRAPH" }

local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then error("找不到檔案（上游需本機已訂閱）：" .. path) end
    local text = fh:read("a")
    fh:close()
    return text
end

-- ===== PZ ScriptParser 語意（ScriptParser.java:11-44 只在逗號切值、:52-87 去掉 /* */）=====
local function stripComments(s)
    while true do
        local e
        local i = 1
        while true do
            local f = s:find("*/", i, true)
            if not f then break end
            e, i = f, f + 1
        end
        if not e then return s end
        local st, j = nil, 1
        while true do
            local f = s:find("/*", j, true)
            if not f or f >= e then break end
            st, j = f, f + 1
        end
        if not st then return s end
        s = s:sub(1, st - 1) .. s:sub(e + 2)
    end
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function readBlock(s, start, block)
    local i = start
    while i <= #s do
        local c = s:sub(i, i)
        if c == "{" then
            local header = trim(s:sub(start, i - 1))
            local words = {}
            for w in header:gmatch("%S+") do words[#words + 1] = w end
            local child = { type = words[1] or "", id = words[2], values = {}, children = {} }
            block.children[#block.children + 1] = child
            i = readBlock(s, i + 1, child)
            start = i
        elseif c == "}" then
            return i + 1
        else
            if c == "," then
                local raw = s:sub(start, i - 1)
                local eq = raw:find("=", 1, true)
                block.values[#block.values + 1] = eq and { trim(raw:sub(1, eq - 1)), trim(raw:sub(eq + 1)) } or { trim(raw), "" }
                start = i + 1
            end
            i = i + 1
        end
    end
    return i
end

local function parse(text)
    local root = { values = {}, children = {} }
    readBlock(stripComments(text), 1, root)
    return root
end

-- ===== 假 ModelScript／ScriptManager =====
local MODEL_KEYS = { mesh = "mesh", scale = "scale", shader = "shader", static = "static", texture = "texture",
                     invertx = "invertX", postprocess = "postProcess", animationsmesh = "animationsMesh" }

local function newModelScript(name, values)
    local ms = { name = name, fields = { static = "true" }, boneWeights = 0, loads = {} }
    local function apply(vals)
        for _, kv in ipairs(vals) do
            local key = MODEL_KEYS[kv[1]:lower()]
            if key then ms.fields[key] = kv[2]
            elseif kv[1]:lower() == "boneweight" then ms.boneWeights = ms.boneWeights + 1 end
        end
    end
    apply(values)
    function ms:getName() return self.name end
    function ms:getMeshName() return self.fields.mesh end
    function ms:isStatic() return self.fields.static:lower() == "true" end
    function ms:Load(n, body) -- ModelScript.java:54-109：只設 body 寫到的欄位
        self.loads[#self.loads + 1] = { n, body }
        if self.throwOnLoad then error("boom") end
        apply(parse(body).children[1].values)
    end
    return ms
end

local scripts, lookups
local function buildWorld(extra)
    scripts, lookups = {}, {}
    for _, path in ipairs(UPSTREAM_FILES) do
        for _, mod in ipairs(parse(readFile(path)).children) do
            if mod.type == "module" then
                for _, b in ipairs(mod.children) do
                    if b.type == "model" and b.id then -- Model 有 ResetExisting：後定義者取代
                        scripts[mod.id .. "." .. b.id] = newModelScript(b.id, b.values)
                    end
                end
            end
        end
    end
    for full, ms in pairs(extra or {}) do scripts[full] = ms end
end
function getScriptManager()
    return { getModelScript = function(_, name) lookups[#lookups + 1] = name; return scripts[name] end }
end

local registered
Events = setmetatable({}, { __index = function(_, name)
    return { Add = function() registered[#registered + 1] = name end, Remove = function() end }
end })

local printed = {}
local rawPrint = print
function print(...)
    local line = table.concat({ ... }, " ")
    if line:find("MinidoracatServerPatchFor42", 1, true) then printed[#printed + 1] = line else rawPrint(line) end
end

local MUTATION
local function loadPatch()
    local source = readFile(PATCH)
    if MUTATION then
        local s, e = source:find(MUTATION.from, 1, true)
        if not s then error("突變片段不在原始碼中：" .. MUTATION.name) end
        source = source:sub(1, s - 1) .. MUTATION.to .. source:sub(e + 1)
    end
    printed, registered = {}, {}
    MSP_VehicleOptimizeGraph = nil
    assert(load(source, "@" .. PATCH))()
    return MSP_VehicleOptimizeGraph
end

local function snapshot()
    local out = {}
    for full, ms in pairs(scripts) do
        local f = {}
        for k, v in pairs(ms.fields) do f[k] = v end
        f.boneWeights = ms.boneWeights
        out[full] = f
    end
    return out
end

local pass, fail = 0, 0
local quiet = false
local function check(name, cond)
    if cond then pass = pass + 1 else fail = fail + 1 end
    if not quiet then rawPrint((cond and "  PASS  " or "  FAIL  ") .. name) end
end

local function run()
    -- 1. 上游缺席：沒有任何白名單模型腳本 → 不 Load、不印、不註冊事件
    scripts, lookups = {}, {}
    local api = loadPatch()
    check("absent: silent", #printed == 0)
    check("absent: no events registered", #registered == 0)
    local listCount = 0
    for _ in pairs(api.LIST) do listCount = listCount + 1 end
    check("absent: only whitelisted names looked up", #lookups == listCount)

    -- 2. 上游原樣 vs 補丁：真實上游模型腳本＋白名單內但上游已改（mesh／static）＋白名單外＋Load 拋錯
    local changedMesh, nowStatic, outsider, thrower
    local listed = {}
    for full in pairs(api.LIST) do listed[#listed + 1] = full end
    table.sort(listed)
    for _, full in ipairs(listed) do
        if full:find("^Rotators%.ContainerDoorR_") then
            if not changedMesh then
                changedMesh = full
            elseif not nowStatic then
                nowStatic = full
            elseif not thrower then
                thrower = full
            end
        end
    end
    local extra = {
        [changedMesh] = newModelScript(changedMesh:match("%.(.+)$"), { { "mesh", "vehicles/Other|door" }, { "static", "FALSE" } }),
        [nowStatic] = newModelScript(nowStatic:match("%.(.+)$"), { { "mesh", api.LIST[nowStatic] }, { "static", "TRUE" } }),
        [thrower] = newModelScript(thrower:match("%.(.+)$"), { { "mesh", api.LIST[thrower] }, { "static", "FALSE" } }),
        ["Base.MSP_NotListedDoor"] = newModelScript("MSP_NotListedDoor", { { "mesh", "vehicles/X|door" }, { "static", "FALSE" } }),
    }
    extra[thrower].throwOnLoad = true
    outsider = "Base.MSP_NotListedDoor"
    buildWorld(extra)
    local before = snapshot()
    api = loadPatch()
    local after = snapshot()

    local listedPresent, loadedOk, badBody, otherChanged = 0, 0, 0, 0
    for full, ms in pairs(scripts) do
        local listed = api.LIST[full]
        local eligible = listed and not before[full].static:lower():find("true", 1, true)
            and before[full].mesh and before[full].mesh:lower() == listed:lower()
        if listed then listedPresent = listedPresent + 1 end
        if eligible then
            if #ms.loads == 1 then loadedOk = loadedOk + 1 end
            local load = ms.loads[1]
            local body = load and parse(load[2]).children[1]
            local okBody = load and load[1] == ms.name and body and body.type == "model" and body.id == ms.name
                and #body.values == 1 and EXPECT_BODY_VALUES[body.values[1][1]] == body.values[1][2] and #body.children == 0
            if not okBody then badBody = badBody + 1 end
        elseif #ms.loads > 0 then
            otherChanged = otherChanged + 1
        end
        -- 差分：只有 postProcess 可以變，而且只在白名單且未被上游改掉、Load 沒拋錯時
        for k, v in pairs(after[full]) do
            local expectChange = eligible and full ~= thrower and k == "postProcess"
            if expectChange then
                if v ~= "+OPTIMIZE_GRAPH" then otherChanged = otherChanged + 1 end
            elseif before[full][k] ~= v then
                otherChanged = otherChanged + 1
            end
        end
        if eligible and full ~= thrower and after[full].postProcess ~= "+OPTIMIZE_GRAPH" then otherChanged = otherChanged + 1 end
    end
    local rsemiReal, listCount2, nonRotators = 0, 0, 0
    for full in pairs(api.LIST) do
        listCount2 = listCount2 + 1
        if not full:find("^Rotators%.") then nonRotators = nonRotators + 1 end
        if full ~= changedMesh and full ~= nowStatic and full ~= thrower and scripts[full] and #scripts[full].loads == 1 then
            rsemiReal = rsemiReal + 1
        end
    end
    check("whitelist: exactly the 17 W900 (Rotators.*) model scripts", listCount2 == 17 and nonRotators == 0)
    check("upstream: every untouched W900 whitelisted model loaded once (14)", rsemiReal == 14)
    local ki5Skinned, ki5Touched = 0, 0
    for full, ms in pairs(scripts) do
        if full:find("^Base%.92amgeneralM998") and not ms:isStatic() then
            ki5Skinned = ki5Skinned + 1
            if #ms.loads > 0 or api.LIST[full] then ki5Touched = ki5Touched + 1 end
        end
    end
    check("KI5 M998 skinned models (" .. ki5Skinned .. ") not in list and untouched", ki5Skinned > 0 and ki5Touched == 0)
    check("KI5 Oshkosh tarp not in list and untouched",
        scripts["Base.trailerM1082tailgateTarp"] ~= nil and api.LIST["Base.trailerM1082tailgateTarp"] == nil
        and #scripts["Base.trailerM1082tailgateTarp"].loads == 0)
    check("upstream: every eligible whitelisted script loaded exactly once", loadedOk == listedPresent - 2)
    check("upstream: body only sets postProcess", badBody == 0)
    check("upstream: only postProcess changes, only on whitelisted scripts", otherChanged == 0)
    check("changed upstream: mesh changed -> not loaded", #scripts[changedMesh].loads == 0)
    check("changed upstream: now static -> not loaded", #scripts[nowStatic].loads == 0)
    check("outsider skinned model untouched", #scripts[outsider].loads == 0)
    check("Load throwing does not escape", #scripts[thrower].loads == 1)
    check("one log line with counts", #printed == 1 and printed[1]:find("set on " .. (loadedOk - 1), 1, true) ~= nil
        and printed[1]:find("3 skipped", 1, true) ~= nil)
    check("present: no events registered", #registered == 0)

    -- 3. 重複觸發不重複套用
    local total = 0
    for _, ms in pairs(scripts) do total = total + #ms.loads end
    local done, changed = api.apply()
    local total2 = 0
    for _, ms in pairs(scripts) do total2 = total2 + #ms.loads end
    check("re-apply: no new Load", total2 == total and done == 0 and changed == 0)
end

run()

if arg[1] == "--mutants" then
    local MUTANTS = {
        { name = "不比 mesh", from = "or string.lower(cur) ~= string.lower(mesh)", to = "" },
        { name = "不看 static", from = "if ms:isStatic() or not cur", to = "if not cur" },
        { name = "沒有已套用守衛", from = "if ms and not applied[ms] then", to = "if ms then" },
        { name = "body 多帶欄位", from = '" { postProcess = +OPTIMIZE_GRAPH, }"', to = '" { postProcess = +OPTIMIZE_GRAPH, static = TRUE, }"' },
        { name = "缺席也印 log", from = "if done + changed > 0 then", to = "if true then" },
        { name = "pcall 拿掉", from = "elseif pcall(function() ms:Load(ms:getName(), \"model \" .. ms:getName() .. BODY) end) then",
          to = "elseif ms:Load(ms:getName(), \"model \" .. ms:getName() .. BODY) or true then" },
    }
    rawPrint("\n突變測試：")
    local caught = 0
    for _, m in ipairs(MUTANTS) do
        MUTATION = m
        local p0, f0 = pass, fail
        quiet = true
        local ok = pcall(run)
        quiet = false
        local killed = (not ok) or fail > f0
        pass, fail = p0, f0
        rawPrint((killed and "  KILLED   " or "  SURVIVED ") .. m.name)
        if killed then caught = caught + 1 end
    end
    MUTATION = nil
    if caught < #MUTANTS then fail = fail + (#MUTANTS - caught) end
end

rawPrint(("\n%d passed, %d failed"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
