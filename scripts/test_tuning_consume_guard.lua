-- 離線測試：MSP_TuningConsumeGuard 的伺服器端材料預檢。最小引擎 stub，不需遊戲。
--   lua scripts/test_tuning_consume_guard.lua
-- 情境：充足透傳／件數不足拒絕／可消耗物用量不足拒絕／找不到拒絕／無 use 透傳／
--       重複安裝不疊 wrapper／名稱正規化與上游一致／上游缺席零行為＋OnGameBoot 補裝。
local LUA = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/"

local pass, fail = 0, 0
local function check(name, cond)
    if cond then pass = pass + 1; print("  PASS  " .. name) else fail = fail + 1; print("  FAIL  " .. name) end
end

-- ===== 假的 PZ 全域 =====
local bootHandlers = {}
Events = { OnGameBoot = { Add = function(fn) bootHandlers[#bootHandlers + 1] = fn end } }
function isServer() return true end
local printed = {}
local rawPrint = print
function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    local line = table.concat(parts, " ")
    if line:find("MinidoracatServerPatchFor42", 1, true) then printed[#printed + 1] = line else rawPrint(line) end
end

-- java 風格清單（size()/get(i)，0-based）
local function javaList(items)
    return { size = function() return #items end, get = function(_, i) return items[i + 1] end }
end

-- 假物品：type 為短型名；fullType 帶模組
local function item(fullType, opts)
    opts = opts or {}
    local shortType = fullType:match("([^.]+)$")
    return {
        fullType = fullType, shortType = shortType,
        IsDrainable = function() return opts.drainable == true end,
        getCurrentUses = function() return opts.uses or 0 end,
        getCondition = function() return opts.condition or 100 end,
    }
end

-- 假背包：比對規則照 ItemContainer.compareType（無 `.` 比短型名，有 `.` 比全型名或短型名）
local function inventory(items)
    local function matches(name, it)
        if not name:find(".", 1, true) then return it.shortType == name end
        return it.fullType == name or it.shortType == name
    end
    return {
        getBestConditionRecurse = function(_, name)
            for _, it in ipairs(items) do if matches(name, it) then return it end end
            return nil
        end,
        getAllTypeRecurse = function(_, name)
            local out = {}
            for _, it in ipairs(items) do if matches(name, it) then out[#out + 1] = it end end
            return javaList(out)
        end,
    }
end

local function character(items, name)
    local inv = inventory(items)
    return { getInventory = function() return inv end, getUsername = function() return name or "tester" end }
end

-- ===== 情境零：上游缺席 → 零行為，但掛 OnGameBoot 等待 =====
print("情境零：上游缺席")
dofile(LUA .. "server/Patches/tsarslib/MSP_TuningConsumeGuard.lua")
check("缺席時沒有印安裝訊息", #printed == 0)
check("缺席時掛了 OnGameBoot 補裝", #bootHandlers == 1)

-- ===== 假的上游 =====
local originalCalls = 0
ATA = { consumeItems = function() end }
ISInstallTuningVehiclePart = { complete = function(self) originalCalls = originalCalls + 1; return "original" end }
ISUninstallTuningVehiclePart = { complete = function(self) originalCalls = originalCalls + 1; return "original" end }

for _, fn in ipairs(bootHandlers) do fn() end
check("OnGameBoot 後安裝成功", #printed == 1 and printed[1]:find("material guard installed", 1, true) ~= nil)
check("install 與 uninstall 都被包裝", ISInstallTuningVehiclePart.MSP_tuningConsumeGuardOriginal ~= nil
    and ISUninstallTuningVehiclePart.MSP_tuningConsumeGuardOriginal ~= nil)
local wrapped = ISInstallTuningVehiclePart.complete
MSP_TuningConsumeGuard.install()
check("重複安裝不疊 wrapper", ISInstallTuningVehiclePart.complete == wrapped)

local function action(cls, items, use, model)
    return setmetatable({ character = character(items), use = use, modelName = model or "Bullbar" }, { __index = cls })
end
local function lastLog() return printed[#printed] or "" end

-- ===== 情境一：材料充足 → 完全透傳 =====
print("情境一：充足")
originalCalls = 0
local a = action(ISInstallTuningVehiclePart,
    { item("Base.SteelBarHalf"), item("Base.SteelBarHalf"), item("Base.BlowTorch", { drainable = true, uses = 10 }) },
    { SteelBarHalf = 2, BlowTorch = 4 })
check("充足時回原版結果", a:complete() == "original")
check("充足時原版被呼叫一次", originalCalls == 1)
check("充足時不印 rejected", not lastLog():find("rejected", 1, true))

-- ===== 情境二：件數不足 → 拒絕、不呼叫原版 =====
print("情境二：件數不足")
originalCalls = 0
local b = action(ISInstallTuningVehiclePart, { item("Base.SteelBarHalf") }, { SteelBarHalf = 2 })
check("不足時回 false", b:complete() == false)
check("不足時原版沒被呼叫", originalCalls == 0)
check("不足時 log 含 need/have", lastLog():find("SteelBarHalf need 2 have 1", 1, true) ~= nil)

-- ===== 情境三：可消耗物用量 =====
print("情境三：可消耗物用量")
originalCalls = 0
local c = action(ISInstallTuningVehiclePart,
    { item("Base.BlowTorch", { drainable = true, uses = 2 }), item("Base.BlowTorch", { drainable = true, uses = 1 }) },
    { BlowTorch = 4 })
check("用量總和 3 < 4 → 拒絕", c:complete() == false and originalCalls == 0)
check("log 標示 (uses)", lastLog():find("have 3 (uses)", 1, true) ~= nil)
local c2 = action(ISInstallTuningVehiclePart,
    { item("Base.BlowTorch", { drainable = true, uses = 2 }), item("Base.BlowTorch", { drainable = true, uses = 2 }) },
    { BlowTorch = 4 })
check("用量總和 4 ≥ 4 → 透傳", c2:complete() == "original" and originalCalls == 1)

-- ===== 情境四：完全找不到（上游原本會在 :32 拋錯）=====
print("情境四：找不到")
originalCalls = 0
local d = action(ISUninstallTuningVehiclePart, {}, { SheetMetal = 1 })
check("找不到 → 拒絕", d:complete() == false and originalCalls == 0)
check("uninstall 標籤", lastLog():find("uninstall rejected", 1, true) ~= nil and lastLog():find("have 0", 1, true) ~= nil)

-- ===== 情境五：沒有 use（免材料的安裝）→ 透傳 =====
print("情境五：無 use")
originalCalls = 0
local e = action(ISInstallTuningVehiclePart, {}, nil)
check("use=nil 透傳", e:complete() == "original" and originalCalls == 1)

-- ===== 情境六：名稱正規化與上游一致 =====
print("情境六：名稱正規化")
local norm = MSP_TuningConsumeGuard.normalizeName
check("Base__SteelBarHalf → Base.SteelBarHalf", norm("Base__SteelBarHalf") == "Base.SteelBarHalf")
check("SteelBarHalf 不補前綴（照上游 find('.') 語意）", norm("SteelBarHalf") == "SteelBarHalf")
local f = action(ISInstallTuningVehiclePart, { item("Tsar.SteelBarHalf"), item("Base.SteelBarHalf") }, { SteelBarHalf = 2 })
originalCalls = 0
check("短型名跨模組計數（compareType 語意）", f:complete() == "original" and originalCalls == 1)

-- ===== 情境七：多項 use，第二項不足也擋 =====
print("情境七：多項")
originalCalls = 0
local g = action(ISInstallTuningVehiclePart, { item("Base.SteelBarHalf"), item("Base.SteelBarHalf") },
    { SteelBarHalf = 2, Screws = 4 })
check("第二項不足 → 拒絕", g:complete() == false and originalCalls == 0)

print()
print(string.format("%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
