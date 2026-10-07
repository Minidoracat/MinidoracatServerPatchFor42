-- 離線測試：MSP_KI5SkeletonTrim（client 載入時把 KI5 群組模型腳本的 mesh 改指裁剪版 FBX）。
-- 以 scripts/ki5trim/build.py 產生的資料表 MSP_KI5SkeletonTrimData.lua 建假 ScriptManager／getActivatedMods／getModFileReader；
-- 假 ModelScript:Load 照 ModelScript.java:54-109 只設 body 寫到的欄位；補丁只准寫 mesh。
-- 上游 KI5 宣告 On Lockdown，測試不讀上游內容：模型腳本的原 mesh／static 取自資料表（產生時以本機訂閱副本解析），
-- 與上游的一致性由 scripts/ki5trim/build.py --check 負責。
--   lua scripts/test_ki5_skeleton_trim.lua             行為與邊界
--   lua scripts/test_ki5_skeleton_trim.lua --mutants   另對補丁植入錯誤，確認測試抓得到

local LUA_DIR = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/client/"
local MAIN = LUA_DIR .. "Patches/MSP_KI5SkeletonTrim.lua"

local function readFile(path)
    local fh = assert(io.open(path, "rb"))
    local text = fh:read("a")
    fh:close()
    return text
end

local DATA = assert(load(readFile(LUA_DIR .. "Patches/MSP_KI5SkeletonTrimData.lua")))()
local GROUPS = DATA.groups
-- scripts/ki5trim/build.py vehicle_sig 對下面這組零件模型算出的值（跨語言對照向量）；Radio 是沒命名的 model 區塊（id 為 nil，
-- 67gt500 的 `part Radio* { model { file = 67gt500radio, } }`，2026-10-07 E2E 實際踩到 nil 串接錯誤）
local SIG_VECTOR = { parts = { { "DoorFrontLeft", { { "DoorFrontLeft", "76chevyKseriesDoorfl" } } },
                               { "WindowFrontLeft", { { "windowFL", "76chevyKseriesWindowfl" } } },
                               { "Radio", { { nil, "67gt500radio" } } } }, sig = 627280118 }

-- ===== 假引擎 =====
local scripts, activeMods, files, loads, vehicles
local function newVehicleScript(parts) -- parts: { { partId, { { modelId, file }, ... } }, ... }
    local vs = {}
    function vs:getPartCount() return #parts end
    function vs:getPart(i)
        local p = parts[i + 1]
        return { getId = function() return p[1] end, getModelCount = function() return #p[2] end,
                 getModel = function(_, j)
                     local m = p[2][j + 1]
                     return { getId = function() return m[1] end, getFile = function() return m[2] end }
                 end }
    end
    vs.parts = parts
    return vs
end
-- 測試自己的指紋實作（以 SIG_VECTOR 與 build.py 對照）
local function testSig(parts)
    local total = 0
    for _, p in ipairs(parts) do
        for _, m in ipairs(p[2]) do
            local s, h = p[1] .. "/" .. (m[1] or "") .. "=" .. (m[2] or ""), 0
            for k = 1, #s do h = (h * 31 + s:byte(k)) % 2147483647 end
            total = (total + h) % 2147483647
        end
    end
    return total
end
local function newModelScript(full, mesh, static)
    local short = full:match("^[^.]+%.(.+)$")
    local ms = { mesh = mesh, static = static }
    function ms:getName() return short end
    function ms:getMeshName() return self.mesh end
    function ms:isStatic() return self.static end
    function ms:Load(name, body)
        assert(name == short, "Load name")
        local inner = assert(body:match("^model%s+" .. short:gsub("%p", "%%%0") .. "%s*{(.*)}%s*$"), "body header: " .. body)
        for k, v in inner:gmatch("([^,=]+)=([^,]*),") do -- 只取逗號結尾的值（ScriptParser.java:33-38）
            k = k:match("^%s*(.-)%s*$"); v = v:match("^%s*(.-)%s*$")
            assert(k == "mesh", "only mesh may be written, got " .. k)
            self.mesh = v
        end
        loads[#loads + 1] = full
    end
    return ms
end

local function buildWorld()
    scripts, activeMods, files, loads, vehicles = {}, {}, {}, {}, {}
    for name in pairs(DATA.vehicles) do
        -- 假車輛腳本：一個具名模型加一個沒命名的模型（id 為 nil）；期望值改成它的指紋（真值的跨語言一致性由 SIG_VECTOR 檢查）
        vehicles[name] = newVehicleScript({ { "P", { { "M", name } } }, { "Radio", { { nil, name .. "radio" } } } })
        DATA.vehicles[name] = testSig(vehicles[name].parts)
    end
    for _, g in ipairs(GROUPS) do
        activeMods[g.mod] = true
        -- binary FBX 前面的位元組被 UTF-8 有損解碼也不影響：時間戳是 ASCII
        files[g.mod .. "/" .. g.src] = { "Kaydara FBX Binary  \0\26\0 junk", "P: \"Original|DateTime_GMT\", \"DateTime\", \"\", \"\", \"" .. g.stamp .. "\"", "rest" }
        for _, m in ipairs(g.models) do
            scripts[m[1]] = newModelScript(m[1], m[2], m[4])
        end
    end
end

function getScriptManager()
    return { getModelScript = function(_, name) return scripts[name] end,
             getVehicle = function(_, name) return vehicles[name] end }
end
function getActivatedMods()
    return { contains = function(_, id) return activeMods[id] == true end }
end
function getModFileReader(modId, rel, create)
    assert(create == false)
    local lines = files[modId .. "/" .. rel]
    if not lines then return nil end
    local i = 0
    return { readLine = function() i = i + 1; return lines[i] end, close = function() end }
end
function require(name)
    assert(name == "Patches/MSP_KI5SkeletonTrimData", "unexpected require " .. name)
    return DATA
end
function getTimestampMs() return math.floor(os.clock() * 1000) end

local printed = {}
local rawPrint = print
function print(...)
    local line = table.concat({ ... }, " ")
    if line:find("[KI5SkeletonTrim]", 1, true) then printed[#printed + 1] = line else rawPrint(line) end
end

local SOURCE = readFile(MAIN)
local function runMain(source)
    printed, loads = {}, {}
    assert(load(source, "@MSP_KI5SkeletonTrim.lua"))()
    return MSP_KI5SkeletonTrim
end

-- ===== 測試 =====
local pass, fail = 0, 0
local quiet = false
local function check(name, cond)
    if cond then pass = pass + 1 else fail = fail + 1 end
    if not quiet then rawPrint((cond and "  PASS  " or "  FAIL  ") .. name) end
end

local totalModels = 0
for _, g in ipairs(GROUPS) do totalModels = totalModels + #g.models end

local function groupLoaded(g)
    local n = 0
    for _, m in ipairs(g.models) do
        if scripts[m[1]].mesh == m[3] then n = n + 1 end
    end
    return n
end

local function linesWith(s)
    local n = 0
    for _, l in ipairs(printed) do if l:find(s, 1, true) then n = n + 1 end end
    return n
end

-- 找兩個不同上游 MOD 的群組、以及一個成員 ≥2 的群組
local G1, G2
for _, g in ipairs(GROUPS) do
    if #g.models >= 2 and not G1 then G1 = g end
end
for _, g in ipairs(GROUPS) do
    if g.mod ~= G1.mod and not G2 then G2 = g end
end
local function usesVehicle(g, name)
    for _, x in ipairs(g.vehicles) do if x == name then return true end end
    return false
end

local function run(source)
    -- 1. 全部一致：每個群組全套用、只寫 mesh、只印一行總結
    buildWorld()
    runMain(source)
    local all = true
    for _, g in ipairs(GROUPS) do all = all and groupLoaded(g) == #g.models end
    check("consistent: every model points to trimmed mesh", all and #loads == totalModels)
    check("consistent: one summary line, no skip lines", #printed == 1 and linesWith("skip group") == 0)

    -- 2. 上游 MOD 沒啟用：該 MOD 的群組不動、不印 skip
    buildWorld()
    activeMods[G2.mod] = nil
    runMain(source)
    local untouched, others = true, true
    for _, g in ipairs(GROUPS) do
        if g.mod == G2.mod then untouched = untouched and groupLoaded(g) == 0
        else others = others and groupLoaded(g) == #g.models end
    end
    check("inactive mod: its groups untouched", untouched)
    check("inactive mod: other groups applied", others)
    check("inactive mod: silent", linesWith("skip group") == 0)

    -- 3. 上游改了某成員的 mesh：整組跳過（其他成員也不動）、印一行
    buildWorld()
    scripts[G1.models[2][1]].mesh = G1.models[2][2] .. "X"
    runMain(source)
    check("upstream mesh changed: whole group skipped", groupLoaded(G1) == 0 and scripts[G1.models[1][1]].mesh == G1.models[1][2])
    check("upstream mesh changed: one skip line", linesWith("skip group") == 1 and linesWith("mesh changed") == 1)
    check("upstream mesh changed: other groups applied", groupLoaded(G2) == #G2.models)

    -- 4. 大小寫不同也算不同（mesh asset 以原字串為鍵）
    buildWorld()
    scripts[G1.models[1][1]].mesh = string.upper(G1.models[1][2])
    runMain(source)
    check("mesh case changed: group skipped", groupLoaded(G1) == 0)

    -- 5. static 改變
    buildWorld()
    scripts[G1.models[1][1]].static = true
    runMain(source)
    check("static changed: group skipped", groupLoaded(G1) == 0 and linesWith("static changed") == 1)

    -- 6. 群組部分缺席（某成員模型腳本不存在）
    buildWorld()
    scripts[G1.models[#G1.models][1]] = nil
    runMain(source)
    local partial = 0
    for i = 1, #G1.models - 1 do if scripts[G1.models[i][1]].mesh == G1.models[i][3] then partial = partial + 1 end end
    check("member missing: no partial apply", partial == 0 and linesWith("model script missing") == 1)

    -- 7. 上游 FBX 重新匯出（時間戳不同）：同一來源檔的所有群組都跳過、其他來源照套
    buildWorld()
    files[G1.mod .. "/" .. G1.src][2] = files[G1.mod .. "/" .. G1.src][2]:gsub("%d%d%d\"$", "999\"")
    runMain(source)
    local sameSrc, otherSrc = true, true
    for _, g in ipairs(GROUPS) do
        if g.mod == G1.mod and g.src == G1.src then sameSrc = sameSrc and groupLoaded(g) == 0
        elseif g.mod ~= G1.mod or g.src ~= G1.src then otherSrc = otherSrc and groupLoaded(g) == #g.models end
    end
    check("FBX re-exported: groups of that source skipped", sameSrc)
    check("FBX re-exported: other sources applied", otherSrc)

    -- 8. 上游 FBX 不見了（getModFileReader 回 nil）
    buildWorld()
    files[G1.mod .. "/" .. G1.src] = nil
    runMain(source)
    check("FBX missing: group skipped", groupLoaded(G1) == 0)

    -- 9. 時間戳不在前 STAMP_MAX_LINES 行：視為不同
    buildWorld()
    local lines = {}
    for i = 1, 401 do lines[i] = "x" end
    lines[402] = files[G1.mod .. "/" .. G1.src][2]
    files[G1.mod .. "/" .. G1.src] = lines
    runMain(source)
    check("stamp beyond line cap: group skipped", groupLoaded(G1) == 0)

    -- 10. 上游改了車輛腳本（多一個零件模型）：引用它的群組全部跳過、不引用的照套
    buildWorld()
    local V = G1.vehicles[1]
    table.insert(vehicles[V].parts, { "NewArmor", { { "a", "SomeModel" } } })
    runMain(source)
    local hit, miss = true, true
    for _, g in ipairs(GROUPS) do
        if usesVehicle(g, V) then hit = hit and groupLoaded(g) == 0
        else miss = miss and groupLoaded(g) == #g.models end
    end
    check("vehicle script changed: groups using it skipped", hit and linesWith("vehicle script changed") >= 1)
    check("vehicle script changed: other groups applied", miss)

    -- 11. 引用成員的車輛腳本不見了
    buildWorld()
    vehicles[G1.vehicles[1]] = nil
    runMain(source)
    check("vehicle script missing: group skipped", groupLoaded(G1) == 0)

    -- 11b. 某群組的模型腳本在檢查時拋例外：只跳過那一組（印 error），其他群組照常套用
    buildWorld()
    scripts[G1.models[1][1]].getMeshName = function() error("boom") end
    runMain(source)
    local others = true
    for _, g in ipairs(GROUPS) do
        if g ~= G1 then others = others and groupLoaded(g) == #g.models end
    end
    check("check error: group skipped with error line", groupLoaded(G1) == 0 and linesWith("error:") >= 1)
    check("check error: other groups still applied", others)

    -- 11c. 套用到一半 Load 拋例外：已改的成員改回原 mesh，整組不套用
    buildWorld()
    local victim = scripts[G1.models[2][1]]
    function victim:Load() error("load failed") end
    runMain(source)
    local reverted = true
    for _, m in ipairs(G1.models) do reverted = reverted and scripts[m[1]].mesh == m[2] end
    check("load error mid-group: members reverted to original mesh", reverted and linesWith("error:") >= 1)

    -- 12. 跨語言指紋：MSP_KI5SkeletonTrim.lua 的 vehicleSig 與 build.py 的 vehicle_sig 對同一輸入相同
    check("vehicleSig matches build.py vector", MSP_KI5SkeletonTrim.vehicleSig(newVehicleScript(SIG_VECTOR.parts)) == SIG_VECTOR.sig
        and testSig(SIG_VECTOR.parts) == SIG_VECTOR.sig)

    -- 13. 所有 KI5 MOD 都沒啟用：什麼都不 Load
    buildWorld()
    activeMods = {}
    runMain(source)
    check("no KI5 mod active: no Load, no log", #loads == 0 and #printed == 0)
end

run(SOURCE)

if arg[1] == "--mutants" then
    local MUTANTS = {
        { "drop static check", "if ms:isStatic%(%) ~= m%[4%] then return \"static changed: \" %.%. m%[1%] end", "" },
        { "case-insensitive mesh compare", "if ms:getMeshName%(%) ~= m%[2%] then", "if string.lower(ms:getMeshName()) ~= string.lower(m[2]) then" },
        { "skip stamp check", "if cache%.stamps%[key%] ~= g%.stamp then", "if false then" },
        { "ignore inactive mod", "if not active:contains%(g%.mod%) then", "if false then" },
        { "apply member-by-member (partial groups)", "local reason = checkGroup%(sm, g, cache%)", "local reason = nil" },
        { "skip vehicle signature check", "if cache%.sigs%[name%] ~= DATA%.vehicles%[name%] then", "if false then" },
        { "order-dependent signature", "total = %(total %+ h%) %% SIG_MOD", "total = (total * 7 + h) %% SIG_MOD" },
        { "concat nil model id", "%(model:getId%(%) or \"\"%)", "model:getId()" },
        { "no revert after mid-group error", "for _, m in ipairs%(applied%) do", "for _, m in ipairs({}) do" },
        { "mesh value without trailing comma", "%.%. mesh %.%. \", }\"", ".. mesh .. \" }\"" },
        { "extra postProcess field", "%.%. mesh %.%. \", }\"", ".. mesh .. \", postProcess = +OPTIMIZE_GRAPH, }\"" },
        { "always log summary", "if groups %+ skipped > 0 then", "if true then" },
    }
    local caught = 0
    for _, mu in ipairs(MUTANTS) do
        local src, n = SOURCE:gsub(mu[2], mu[3])
        assert(n == 1, "mutant pattern not found: " .. mu[1])
        local before, beforePass = fail, pass
        quiet = true
        local ok = pcall(run, src)
        quiet = false
        local hit = (not ok) or fail > before
        fail, pass = before, beforePass
        rawPrint((hit and "  CAUGHT  " or "  MISSED  ") .. mu[1])
        if hit then caught = caught + 1 end
    end
    if caught < #MUTANTS then fail = fail + (#MUTANTS - caught) end
end

rawPrint(("\n%d passed, %d failed"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
