--[[
煙霧測試骨架：用假的 PZ 全域載入**真正的** MOD Lua，跑行為情境並斷言結果。

    lua scripts/smoke_harness.lua        （repo 根目錄執行；標準 Lua 5.x 即可）

為什麼需要（兩類 luac -p 抓不到的錯誤，皆為正式服實際事故）：
- 改函式簽章漏改呼叫點：語法完全合法，要等該路徑真的執行才炸
  （實例：hotspotKey 兩參數改三參數，刪除成功後的 log 聚合路徑必崩）
- 邏輯回歸：安全把關（範圍／阻隔／保護規則）被改壞時，「執行到並斷言」是唯一防線

限制（必須誠實面對）：這是標準 Lua，不是遊戲的 Kahlua。
- 標準 Lua 有 next/xpcall，Kahlua 沒有——本 harness **測不出**誤用，
  那由 scripts/verify_mod.py 的靜態掃描負責（發版前兩者都要跑）
- Kahlua 專屬行為（table.sort 遞迴深度、Java instance field 不暴露、rawget 呼叫形式、
  每個 table 都是 LinkedHashMap 的記憶體成本）只能靠反編譯查證與實機測試

寫情境的原則：
- 情境要「執行到會炸的路徑」——刪除後的收尾、跨 tick 的第二輪、聚合輸出，都是重災區
- 安全邊界要有**反面**斷言（範圍外／被阻隔／受保護的對象必須存活），不是只測 happy path
- 新防線寫完先「植入違規證明它會抓」再信任它——測不出來的測試等於沒有測試
]]

-- 家族佈局固定，直接填死最省事；scaffold 時由模板替換佔位符
local MEDIA = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua"

-- ===== 假的 PZ 全域（依 MOD 實際用到的 API 增補）=====
-- 起始時間要夠大：週期類邏輯常寫成 now - lastAt >= interval 而 lastAt 初值 0，
-- 從 0 起跳會讓第一輪永遠不觸發（遊戲的 getTimestampMs 本來就是大數）
local nowMs = 5000000
local logLines = {}

function getTimestampMs() return nowMs end
function isClient() return false end
function isServer() return true end
function writeLog(_, text) logLines[#logLines + 1] = text end
function getText(key) return key end

local tickHandlers, clientCommandHandlers = {}, {}
Events = setmetatable({}, {
    __index = function(_, name)
        return {
            Add = function(fn)
                if name == "OnTick" then tickHandlers[#tickHandlers + 1] = fn
                elseif name == "OnClientCommand" then clientCommandHandlers[#clientCommandHandlers + 1] = fn end
            end,
        }
    end,
})

-- java 風格清單（size()/get(i)，0-based）——PZ 回傳的容器幾乎都是這個形狀
local function javaList(items)
    return {
        size = function() return #items end,
        get = function(_, i) return items[i + 1] end,
        _raw = items,
    }
end

-- ===== 載入受測程式碼 =====
local loaded = {}
function require(name)
    if loaded[name] then return true end
    loaded[name] = true
    for _, dir in ipairs({ "shared", "server", "client" }) do
        local chunk = loadfile(MEDIA .. "/" .. dir .. "/" .. name .. ".lua")
        if chunk then chunk() return true end
    end
    error("require 找不到: " .. name)
end

-- ===== 測試工具 =====
local failures = 0
local function check(ok, label)
    if ok then print("  PASS  " .. label)
    else failures = failures + 1; print("  FAIL  " .. label) end
end

local function runTicks(count)
    for _ = 1, count do
        for _, fn in ipairs(tickHandlers) do fn() end
    end
end

-- ===== 情境 =====
-- 拖車卸車防護（server/Patches/MSP_UnplacedVehicleGuard.lua）：包裝全域 addVehicleDebug。上游真檔差分在
-- scripts/test_unplaced_vehicle_guard.lua；這裡用假引擎跑真補丁，守住安裝條件與回傳值。
local GUARD = MEDIA .. "/server/Patches/MSP_UnplacedVehicleGuard.lua"
local function engineAdd(script, dir, skin, sq)
    return { getSqlId = function() return sq.placed and 7 or -1 end, script = script }
end
local function sq(placed)
    return { placed = placed, getX = function() return 10 end, getY = function() return 20 end, getZ = function() return 0 end }
end
local function loadGuard(mods)
    local set = {}
    for _, id in ipairs(mods) do set[id] = true end
    function getActivatedMods() return { contains = function(_, id) return set[id] == true end } end
    addVehicleDebug, MSP_UnplacedVehicleGuard = engineAdd, nil
    local lines, realPrint = {}, print
    print = function(...) lines[#lines + 1] = table.concat({ ... }, " ") end
    local ok, err = pcall(dofile, GUARD)
    print = realPrint
    if not ok then error(err) end
    return lines
end

print("情境一：rSemiTruck 在場，引擎拒絕放置的車改回 nil")
local lines = loadGuard({ "\\rSemiTruck", "MinidoracatServerPatchFor42" })
check(addVehicleDebug ~= engineAdd and MSP_UnplacedVehicleGuard.original == engineAdd, "已包裝全域、原函式可取回")
check(#lines == 1 and lines[1]:find("guard installed", 1, true) ~= nil, "安裝時印一行")
local placed = addVehicleDebug("Base.CarNormal", "N", 0, sq(true))
check(placed ~= nil and placed:getSqlId() == 7, "正常放置：原物件照回")
local logged = {}
local realPrint = print
print = function(...) logged[#logged + 1] = table.concat({ ... }, " ") end
local refused = addVehicleDebug("Base.CarNormal", "N", 0, sq(false))
print = realPrint
check(refused == nil, "引擎拒絕（sqlId -1）：回 nil")
check(#logged == 1 and logged[1]:find("Base.CarNormal at 10,20,0", 1, true) ~= nil, "拒絕時印一行車型與座標")

print("情境二：上游都缺席＝零行為")
lines = loadGuard({ "MinidoracatServerPatchFor42", "damnlib" })
check(addVehicleDebug == engineAdd and MSP_UnplacedVehicleGuard == nil, "不換全域、不設全域表")
check(#lines == 0, "不印任何 log")

print()
if failures > 0 then
    print(failures .. " 項失敗")
    os.exit(1)
end
print("全部通過")
