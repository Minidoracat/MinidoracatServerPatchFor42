-- 離線測試：MSP_WardrobeBridgeFilter（Mirage Wardrobe 塑形橋接只處理附近玩家）。最小引擎 stub，不需遊戲。
--   lua scripts/test_wardrobe_bridge_filter.lua
-- 情境：上游缺席零行為＋OnGameBoot 補裝／OnTick 換掉原註冊／遠處與未載入玩家被濾掉、附近保留／
--       呼叫後完整表還原／原版改寫子集寫回／整表被換掉不還原／原版拋錯先還原再重拋／
--       非 MP 客戶端與無本機玩家直接透傳／重複安裝不疊／形狀不符印 NOT installed 一次。
local FILE = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/client/Patches/MirageWardrobe42/MSP_WardrobeBridgeFilter.lua"

local pass, fail = 0, 0
local function check(name, cond)
    if cond then pass = pass + 1; print("  PASS  " .. name) else fail = fail + 1; print("  FAIL  " .. name) end
end

local printed = {}
local rawPrint = print
function print(...)
    local line = table.concat({ ... }, " ")
    if line:find("MinidoracatServerPatchFor42", 1, true) then printed[#printed + 1] = line else rawPrint(line) end
end

local tickHandlers, bootHandlers
local clientMode, localPlayer
local function resetEnv()
    tickHandlers, bootHandlers, printed = {}, {}, {}
    Events = {
        OnTick = {
            Add = function(fn) tickHandlers[#tickHandlers + 1] = fn end,
            Remove = function(fn)
                for i = #tickHandlers, 1, -1 do if tickHandlers[i] == fn then table.remove(tickHandlers, i) end end
            end,
        },
        OnGameBoot = { Add = function(fn) bootHandlers[#bootHandlers + 1] = fn end },
    }
    clientMode = true
    MirageWardrobeCore = nil
    MSP_WardrobeBridgeFilter = nil
end
function isClient() return clientMode end
function getPlayer() return localPlayer end

local function player(x, y, loaded)
    return {
        getX = function() return x end, getY = function() return y end,
        getCurrentSquare = function() if loaded ~= false then return {} end end,
    }
end

-- 假上游：原版 callback 記下本次看到哪些 binding key；可注入副作用
local function fakeUpstream(sideEffect)
    local core = { networkAppliedBindings = {} }
    core.onAppearanceBeforeModelUpdate = function()
        core.seen = {}
        for k in pairs(core.networkAppliedBindings) do core.seen[k] = true end
        if sideEffect then sideEffect(core) end
    end
    return core
end

local function loadPatch() dofile(FILE) end
local function count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

-- 1. 上游缺席：零行為、不印 log；之後上游出現，OnGameBoot 補裝
resetEnv(); localPlayer = player(0, 0)
loadPatch()
check("absent: no OnTick change", #tickHandlers == 0)
check("absent: silent", #printed == 0)
check("absent: OnGameBoot retry registered", #bootHandlers == 1)
local core = fakeUpstream()
local original = core.onAppearanceBeforeModelUpdate
MirageWardrobeCore = core
Events.OnTick.Add(original)
bootHandlers[1]()
check("boot retry: original removed, one wrapper registered", #tickHandlers == 1 and tickHandlers[1] ~= original)
check("boot retry: installed log", #printed == 1 and printed[1]:find("installed", 1, true) ~= nil)

-- 2. 載入時上游已在：篩選行為
resetEnv(); localPlayer = player(1000, 1000)
core = fakeUpstream(); original = core.onAppearanceBeforeModelUpdate
MirageWardrobeCore = core; Events.OnTick.Add(original)
local near = player(1030, 1040)
local full = {
    near = { player = near }, far = { player = player(1500, 1000) },
    unloaded = { player = player(1001, 1001, false) },
    broken = "not-a-table", edge = { player = player(1000 + 100, 1000) },
}
core.networkAppliedBindings = full
loadPatch()
check("load-time install: exactly one OnTick handler", #tickHandlers == 1 and tickHandlers[1] ~= original)
tickHandlers[1]()
check("near kept", core.seen.near == true)
check("far filtered", core.seen.far == nil)
check("unloaded-square filtered", core.seen.unloaded == nil)
check("invalid binding left for upstream gate", core.seen.broken == true)
check("edge at exactly RANGE kept", core.seen.edge == true)
check("full table restored by identity", core.networkAppliedBindings == full and count(full) == 5)

-- 3. 原版改寫子集：移除、換值、新增都寫回完整表
local replacement = { player = near }
resetEnv(); localPlayer = player(0, 0)
core = fakeUpstream(function(c)
    c.networkAppliedBindings.near = nil
    c.networkAppliedBindings.edge = replacement
    c.networkAppliedBindings.added = { player = player(1, 1) }
end)
MirageWardrobeCore = core; Events.OnTick.Add(core.onAppearanceBeforeModelUpdate)
full = { near = { player = player(5, 5) }, edge = { player = player(6, 6) }, far = { player = player(900, 0) } }
core.networkAppliedBindings = full
loadPatch(); tickHandlers[1]()
check("merge-back: removal applied", full.near == nil)
check("merge-back: replacement applied", full.edge == replacement)
check("merge-back: addition applied", full.added ~= nil)
check("merge-back: filtered-out entry untouched", full.far ~= nil)

-- 4. 原版整張表換掉（session 重置）：不還原舊表
resetEnv(); localPlayer = player(0, 0)
local fresh = {}
core = fakeUpstream(function(c) c.networkAppliedBindings = fresh end)
MirageWardrobeCore = core; Events.OnTick.Add(core.onAppearanceBeforeModelUpdate)
core.networkAppliedBindings = { a = { player = player(1, 1) } }
loadPatch(); tickHandlers[1]()
check("table replaced upstream: kept new table", core.networkAppliedBindings == fresh)

-- 5. 原版拋錯：先還原完整表，再原樣重拋
resetEnv(); localPlayer = player(0, 0)
core = fakeUpstream(function() error("boom", 0) end)
MirageWardrobeCore = core; Events.OnTick.Add(core.onAppearanceBeforeModelUpdate)
full = { a = { player = player(1, 1) }, b = { player = player(999, 999) } }
core.networkAppliedBindings = full
loadPatch()
local ok, err = pcall(tickHandlers[1])
check("error rethrown unchanged", not ok and err == "boom")
check("error: full table restored", core.networkAppliedBindings == full and full.b ~= nil)

-- 6. 非 MP 客戶端／無本機玩家：透傳完整表
resetEnv(); localPlayer = player(0, 0)
core = fakeUpstream(); MirageWardrobeCore = core; Events.OnTick.Add(core.onAppearanceBeforeModelUpdate)
core.networkAppliedBindings = { far = { player = player(999, 999) } }
loadPatch()
clientMode = false; tickHandlers[1]()
check("not MP client: unfiltered", core.seen.far == true)
clientMode = true; localPlayer = nil; tickHandlers[1]()
check("no local player: unfiltered", core.seen.far == true)
localPlayer = player(0, 0)

-- 7. 重複安裝不疊（同一個 handler，不是包兩層）
local registered = tickHandlers[1]
MSP_WardrobeBridgeFilter.install()
loadPatch()
check("idempotent: same single handler", #tickHandlers == 1 and tickHandlers[1] == registered)

-- 8. 形狀不符：NOT installed 只印一次、不動 OnTick
resetEnv(); localPlayer = player(0, 0)
MirageWardrobeCore = { networkAppliedBindings = {} }
loadPatch(); MSP_WardrobeBridgeFilter.install()
local notInstalled = 0
for _, line in ipairs(printed) do if line:find("NOT installed", 1, true) then notInstalled = notInstalled + 1 end end
check("shape changed: NOT installed once", notInstalled == 1 and #tickHandlers == 0)

print(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
