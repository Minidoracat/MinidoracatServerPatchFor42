--[[
MSP_KI5SkeletonTrim — KI5 車輛的門窗模型每幀重算整台車的骨架

【上游】KI5 系列車輛 MOD（45 個，各自的 Workshop），逐筆登記在 upstream.json（`patches` 含本檔者）；
核對版本為各筆的 acked_time_updated。資料表 MSP_KI5SkeletonTrimData.lua 每個群組也記了上游 mod id 與 Workshop id。

【缺陷】
客戶端每幀對每台已載入的車，把每個蒙皮零件模型的 AnimationPlayer 重算一次（BaseVehicle.postupdate
42.21.0 :3774-3780 → updateAnimationPlayer :3898-3904，沒有距離、可見或靜止閘門），成本約等於骨頭數。
KI5 每個門、引擎蓋、後車廂、車窗、裝甲模型都指向整台車的 FBX，骨架是整台車（例如 76chevyKseries 41 根，
ImportedSkeleton.java:56-112）；車窗、裝甲子零件又共用門的 player（ModelInfo.getAnimationPlayer :11844-11867），
讓同一個 player 每幀多算幾次。

【修法】
`scripts/ki5trim/build.py` 依「共用同一個 player 的模型群組」把原 FBX 拆成小檔：只留群組的 mesh、
蒙皮骨頭與名稱引用的骨頭（boneWeight／attachment）、它們的祖先與 VehicleSkeleton，以及指向保留骨頭的動畫曲線。
直接編輯 FBX 節點樹、保留原始位元組，不重算數值；唯一改的數值是 VehicleSkeleton 的變換屬性歸零（讓 assimp 不在它上方
補兩個 `$AssimpFbx$` pivot 骨頭；它沒有動畫、不是 aiBone、不是 mesh 節點的祖先，PZ 動畫裡本來就是單位矩陣）。
小檔放在本 MOD 的 `42/media/models_X/MSP_KI5Trim/`。
`scripts/ki5trim/verify.py` 用遊戲本體的 jassimp＋PZ 匯入類別逐位元比對原檔與新檔（容差 0）。
本檔在 client Lua 載入時，用 `ModelScript:Load(name, "model X { mesh = MSP_KI5Trim/<檔>|<mesh>, }")` 改指新檔。
- Load 不 reset，只設 body 寫到的欄位（ModelScript.java:54-109）。
- 子零件用 parent 的 player 繪製時，骨頭依名稱重新對應（AnimationPlayer.getSkinTransforms :1555-1580、
  SkinTransformData.checkBoneMap :1799-1817）。所以同一群組一律指向同一個新檔，整組套用或整組不動。
- 不加 `postProcess = +OPTIMIZE_GRAPH`：它把 KI5 mesh 節點的 pivot 鏈摺成一個節點，PZ 算出的 mesh 世界矩陣
  （ProcessedAiScene.java:78-95）平移差 0.666，零件會錯位。

時機：client Lua 在 ScriptManager.Load 之後、任何車輛建立模型之前執行（Core.ResetLua :3931、:3949；
連線時由 ConnectToServerState.java:125 觸發）。車輛模型在 BaseVehicle.createPhysics :871 → ModelManager.addVehicle
才會載入。dedicated server 對 client Lua 只做 checksum、不執行（LuaManager.java:1206-1208），伺服器不受影響。

安全閘：以群組為單位，任一條不符就整組跳過，畫面維持原版。
- 上游 MOD 沒啟用：靜默跳過。
- 模型腳本不存在，或原 mesh 字串、static 狀態和產生時不同：上游改了模型腳本。
- 引用成員的車輛腳本不存在，或零件／模型／檔案集合的指紋不同：上游改了車輛腳本，群組劃分可能失效。
  part 的 parent 在 Lua 讀不到，只能靠這個集合間接偵測。
- 上游來源 FBX 檔頭的 `Original|DateTime_GMT` 和產生時不同：上游重新匯出了模型。
- 檢查或套用時出錯：把已改的成員改回原 mesh，只影響這一組。
每個跳過的群組印一行。至少有一組套用或跳過時，最後印一行總結（套用數、跳過數、耗時）。

【為什麼不改上游】
KI5 宣告 On Lockdown，不得修改或重包。裁剪後的 FBX 是 KI5 內容的衍生物，依使用者裁定只給本服使用：
只在本機產生、隨本 MOD 上傳 Workshop，不進公開 repo（.gitignore）。本檔與資料表只有名稱、雜湊與指紋。

【軟依賴】
不 require 任何上游。資料表裡的上游 MOD 一個都沒啟用時，什麼都不做：不 Load、不註冊事件、不印 log。

【上游更新時要重核】
依序跑 `python scripts/ki5trim/build.py --check`、`python scripts/ki5trim/verify.py`、
`lua scripts/test_ki5_skeleton_trim.lua --mutants`。有差異就跑 `python scripts/ki5trim/build.py` 重產，再重驗、重跑測試。
]]

local PREFIX = "[MinidoracatServerPatchFor42][KI5SkeletonTrim]"
local STAMP_PATTERN = "%d%d/%d%d/%d%d%d%d %d%d:%d%d:%d%d%.%d%d%d" -- 與 scripts/ki5trim/build.py 的 STAMP 相同
local STAMP_MAX_LINES = 400 -- 時間戳在檔頭前幾 KB；binary FBX 換行很少，400 行足夠且有上限
local SIG_MOD = 2147483647 -- 與 build.py 的 vehicle_sig 相同；h*31+255 < 2^53，double 運算精確

local DATA = require "Patches/MSP_KI5SkeletonTrimData"

-- 讀上游 FBX 檔頭的時間戳；getModFileReader 先找版本目錄再找 common（LuaManager.java:5970-6025）
local function readStamp(modId, rel)
    local ok, reader = pcall(getModFileReader, modId, rel, false)
    if not ok or not reader then return nil end
    local found
    for _ = 1, STAMP_MAX_LINES do
        local line = reader:readLine()
        if not line then break end
        found = string.match(line, STAMP_PATTERN)
        if found then break end
    end
    reader:close()
    return found
end

-- 零件模型的順序無關指紋：Σ hash("partId/modelId=file") mod SIG_MOD（不排序，避開 Kahlua table.sort）
local function vehicleSig(vs)
    local total = 0
    for i = 0, vs:getPartCount() - 1 do
        local part = vs:getPart(i)
        for j = 0, part:getModelCount() - 1 do
            local model = part:getModel(j)
            -- 沒命名的 model 區塊（例如 67gt500 的 `part Radio* { model { file = 67gt500radio, } }`）id 是 nil（VehicleScript.java:693-697）
            local s = (part:getId() or "") .. "/" .. (model:getId() or "") .. "=" .. (model:getFile() or "")
            local h = 0
            for k = 1, #s do h = (h * 31 + string.byte(s, k)) % SIG_MOD end
            total = (total + h) % SIG_MOD
        end
    end
    return total
end

-- 回傳 nil（可套用）或跳過原因
local function checkGroup(sm, g, cache)
    local key = g.mod .. "/" .. g.src
    if cache.stamps[key] == nil then cache.stamps[key] = readStamp(g.mod, g.src) or false end
    if cache.stamps[key] ~= g.stamp then return "upstream FBX re-exported (" .. tostring(cache.stamps[key]) .. ")" end
    for _, name in ipairs(g.vehicles) do
        if cache.sigs[name] == nil then
            local vs = sm:getVehicle(name)
            cache.sigs[name] = vs and vehicleSig(vs) or false
        end
        if cache.sigs[name] ~= DATA.vehicles[name] then return "vehicle script changed: " .. name end
    end
    for _, m in ipairs(g.models) do
        local ms = sm:getModelScript(m[1])
        if not ms then return "model script missing: " .. m[1] end
        if ms:getMeshName() ~= m[2] then return "mesh changed: " .. m[1] .. " = " .. tostring(ms:getMeshName()) end
        if ms:isStatic() ~= m[4] then return "static changed: " .. m[1] end
    end
    return nil
end

local function setMesh(ms, mesh)
    -- 結尾逗號必要：ScriptParser 只在逗號處切值（ScriptParser.java:33-38）
    ms:Load(ms:getName(), "model " .. ms:getName() .. " { mesh = " .. mesh .. ", }")
end

local function apply()
    local t0 = getTimestampMs()
    local sm = getScriptManager()
    local active = getActivatedMods()
    local cache = { stamps = {}, sigs = {} }
    local groups, models, inactive, skipped = 0, 0, 0, 0
    for _, g in ipairs(DATA.groups) do
        if not active:contains(g.mod) then
            inactive = inactive + 1
        else
            -- 任何意外錯誤只影響這一組：已改的成員改回原 mesh，整組算跳過
            local applied = {}
            local ok, why = pcall(function()
                local reason = checkGroup(sm, g, cache)
                if reason then return reason end
                for _, m in ipairs(g.models) do
                    local ms = sm:getModelScript(m[1])
                    applied[#applied + 1] = m
                    setMesh(ms, m[3])
                end
                return nil
            end)
            if not ok then
                for _, m in ipairs(applied) do
                    local ms = sm:getModelScript(m[1])
                    pcall(setMesh, ms, m[2])
                end
                why = "error: " .. tostring(why)
            end
            if why then
                skipped = skipped + 1
                print(PREFIX .. " skip group " .. g.models[1][1] .. " (" .. g.mod .. "): " .. why)
            else
                groups = groups + 1
                models = models + #g.models
            end
        end
    end
    if groups + skipped > 0 then
        print(PREFIX .. " " .. models .. " model scripts in " .. groups .. " groups use trimmed skeletons; "
            .. skipped .. " groups skipped (upstream changed), "
            .. inactive .. " groups not active; " .. (getTimestampMs() - t0) .. " ms")
    end
    return groups, models, skipped, inactive
end

apply()

-- 離線測試用（scripts/test_ki5_skeleton_trim.lua）；遊戲內不會有人引用
MSP_KI5SkeletonTrim = { apply = apply, DATA = DATA, vehicleSig = vehicleSig }
