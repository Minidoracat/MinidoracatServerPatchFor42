-- 離線測試：MSP_WardrobeBridgeFilter（Mirage Wardrobe 塑形橋接只處理附近玩家，穿戴簽章每人節流）。
--   lua scripts/test_wardrobe_bridge_filter.lua             行為與邊界
--   lua scripts/test_wardrobe_bridge_filter.lua --mutants   另對補丁植入錯誤，確認真上游差分抓得到
--   lua scripts/test_wardrobe_bridge_filter.lua --bench     另印上游原樣與補丁每 tick 的成本（標準 Lua，只看比例）
-- 假上游段（1–9，最小引擎 stub）：上游缺席零行為＋OnGameBoot 補裝／OnTick 換掉原註冊／遠處與未載入玩家被濾掉、附近保留／
--       呼叫後完整表還原／原版改寫子集寫回／整表被換掉不還原／原版拋錯先還原再重拋／
--       非 MP 客戶端與無本機玩家直接透傳／重複安裝不疊／形狀不符只在 OnGameBoot 印 NOT installed 一次／
--       上游 shared 先建表、client 檔晚載入時不誤報。
-- 真上游段（R1–R8）：載入本機 Steam 訂閱裡未修改的 Mirage Wardrobe，上游原樣 vs 補丁差分（見該段開頭）。
local FILE = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/client/Patches/MirageWardrobe42/MSP_WardrobeBridgeFilter.lua"

local pass, fail = 0, 0
local rawPrint = print
local quiet = false
local function check(name, cond)
    if cond then pass = pass + 1 else fail = fail + 1 end
    if not quiet then rawPrint((cond and "  PASS  " or "  FAIL  ") .. name) end
end

local printed = {}
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

-- 8. 形狀不符：檔案載入時不印，OnGameBoot 仍不符才印 NOT installed 一次、不動 OnTick
resetEnv(); localPlayer = player(0, 0)
MirageWardrobeCore = { networkAppliedBindings = {} }
loadPatch(); MSP_WardrobeBridgeFilter.install()
check("shape changed: silent before OnGameBoot", #printed == 0)
bootHandlers[1](); bootHandlers[1]()
local notInstalled = 0
for _, line in ipairs(printed) do if line:find("NOT installed", 1, true) then notInstalled = notInstalled + 1 end end
check("shape changed: NOT installed once at OnGameBoot", notInstalled == 1 and #tickHandlers == 0)

-- 9. 上游 shared 先建表、本檔早於上游 client 檔載入：不誤報，OnGameBoot 裝上（42.21.0 E2E 實見的順序）
resetEnv(); localPlayer = player(0, 0)
MirageWardrobeCore = { networkAppliedBindings = {} }
loadPatch()
local late = fakeUpstream(); late.networkAppliedBindings = MirageWardrobeCore.networkAppliedBindings
MirageWardrobeCore.onAppearanceBeforeModelUpdate = late.onAppearanceBeforeModelUpdate
Events.OnTick.Add(MirageWardrobeCore.onAppearanceBeforeModelUpdate)
bootHandlers[1]()
check("late client file: no NOT installed", #printed == 1 and printed[1]:find("bridge filter installed", 1, true) ~= nil)
check("late client file: wrapper replaces original", #tickHandlers == 1 and tickHandlers[1] == MirageWardrobeCore.MSP_bridgeFilterWrapper)

-- ===== 真上游差分 =====
-- 依遊戲順序載入本機 Steam 訂閱裡未修改的 shared/MirageWardrobeNetwork.lua → client/MirageWardrobeCore.lua，
-- 每個 tick 跑原版 onAppearanceBeforeModelUpdate 與它的 local（requestedPlayers、beginNetworkAppearanceRenderBridges、
-- getPhysicalWearSignature、readWearSignatureValue、hasCurrentNetworkBinding）。只換掉要真引擎物件、又不在這次改動範圍的
-- 公開函式：endAppearanceRenderBridges／onCleanAppearanceTick／beginAppearanceRenderBridge（記錄）、shouldTrackAppearance
-- （看假玩家的 tracked）、getRemotePlayerItemVisuals（回假 ItemVisuals，每次 get(0)＝一次簽章比對）、getTransmogSourceSlot。
-- 比較：每個 tick 開橋的名單（補丁＝原樣扣掉範圍外）、簽章比對次數、髒污變化讓舊快照失效的延遲、各種中途改表與拋錯。
local WS = os.getenv("PZ_WORKSHOP_DIR") or "D:/SteamLibrary/steamapps/workshop/content/108600"
local UP_DIR = WS .. "/3770186452/mods/MirageWardrobe/42.0/media/lua/"
local UP_NET, UP_CORE = UP_DIR .. "shared/MirageWardrobeNetwork.lua", UP_DIR .. "client/MirageWardrobeCore.lua"
local function readFile(path)
    local fh = io.open(path, "rb")
    if not fh then error("讀不到 " .. path .. "（需要本機訂閱 Workshop 3770186452）") end
    local text = fh:read("a")
    fh:close()
    return text
end
local UP_NET_SRC, UP_CORE_SRC, PATCH_SRC = readFile(UP_NET), readFile(UP_CORE), readFile(FILE)
local MUTATION
local TICK_MS = 16
local PARTS = 18
local GETTERS = { "getBlood", "getDirt", "getHole", "getBasicPatch", "getDenimPatch", "getLeatherPatch" }
local LIBS = { "pairs", "ipairs", "type", "tostring", "tonumber", "pcall", "error", "select", "next", "table",
    "string", "math", "setmetatable", "getmetatable", "rawget", "rawset", "rawequal", "assert" }

-- 載入期碰到的其他全域（ISInventoryTransferAction、ISInventoryPage）給一個什麼都接受的假物件
local function mock(name)
    return setmetatable({}, {
        __index = function(t, k) local v = mock(name .. "." .. tostring(k)); rawset(t, k, v); return v end,
        __call = function() return mock(name .. "()") end,
    })
end

local function newWorld(opts)
    local W = { clock = 0, checks = {}, bridged = {}, printed = {} }
    local env = {}
    for _, k in ipairs(LIBS) do env[k] = _G[k] end
    env.unpack = table.unpack
    env.Events = setmetatable({}, { __index = function(t, name)
        local ev = { handlers = {} }
        ev.Add = function(fn) ev.handlers[#ev.handlers + 1] = fn end
        ev.Remove = function(fn)
            for i = #ev.handlers, 1, -1 do if ev.handlers[i] == fn then table.remove(ev.handlers, i) end end
        end
        rawset(t, name, ev)
        return ev
    end })
    env.require = function() end
    env.isClient = function() return true end
    env.isServer = function() return false end
    env.print = function(...) W.printed[#W.printed + 1] = table.concat({ ... }, " ") end
    env.getTimestampMs = function() return W.clock end
    env.getPlayer = function() return W.localPlayer end
    local parts = {}
    for i = 0, PARTS - 1 do parts[i] = { index = i } end
    env.BloodBodyPartType = { MAX = { index = function() return PARTS end }, FromIndex = function(i) return parts[i] end }
    local scripts = { FindItem = function(_, name) return { name = name } end }
    env.getScriptManager = function() return scripts end
    env.CLEAN_DIRECT = function() end -- 只有模擬「上游不經表呼叫 onCleanAppearanceTick」的情境會用
    setmetatable(env, { __index = function(t, k)
        if k:find("^Mirage") or k:find("^MSP_") then return nil end
        local v = mock(k)
        rawset(t, k, v)
        return v
    end })
    W.env = env
    assert(load(UP_NET_SRC, "@" .. UP_NET, "t", env))()
    assert(load(opts.coreTransform and opts.coreTransform(UP_CORE_SRC) or UP_CORE_SRC, "@" .. UP_CORE, "t", env))()
    local core = env.MirageWardrobeCore
    W.core = core
    core.endAppearanceRenderBridges = function() return true, 0 end
    core.onCleanAppearanceTick = function() if W.onClean then W.onClean(W) end end
    core.beginAppearanceRenderBridge = function(p)
        W.bridged[#W.bridged + 1] = p.name
        if W.onBridge then W.onBridge(p) end
        return true
    end
    core.shouldTrackAppearance = function(p) return p.tracked == true end
    core.getRemotePlayerItemVisuals = function(p) if p ~= W.localPlayer then return p.visuals end end
    core.getTransmogSourceSlot = function() return "base:test" end
    core.networkAppliedBindings = core.networkAppliedBindings or {}
    W.full = core.networkAppliedBindings
    if opts.patch then
        local src = PATCH_SRC
        if MUTATION then
            local s, e = src:find(MUTATION.from, 1, true)
            if not s then error("突變片段不在補丁原始碼中：" .. MUTATION.name) end
            src = src:sub(1, s - 1) .. MUTATION.to .. src:sub(e + 1)
        end
        assert(load(src, "@" .. FILE, "t", env))()
        W.filter = env.MSP_WardrobeBridgeFilter
    end
    return W
end

-- 假遠端玩家：visuals 件 ItemVisual，每件 18 部位 × 6 種磨損讀值
local function newPlayer(W, name, x, y, o)
    o = o or {}
    local list = {}
    for i = 1, o.visuals or 3 do
        local v = { kind = "Base.Test" .. i, wear = {} }
        for _, g in ipairs(GETTERS) do
            v.wear[g] = {}
            v[g] = function(self, part) return self.wear[g][part.index] or 0 end
        end
        v.getItemType = function(self) return self.kind end
        list[i] = v
    end
    local p = { name = name, x = x, y = y, tracked = o.tracked == true, list = list }
    p.visuals = {
        size = function() return #list end,
        get = function(_, i)
            if i == 0 then W.checks[name] = (W.checks[name] or 0) + 1 end
            return list[i + 1]
        end,
    }
    function p:getX() return self.x end
    function p:getY() return self.y end
    function p:getCurrentSquare() return self end
    return p
end

local function bind(W, key, p, stale)
    local state = { key = key }
    W.core.networkPlayerData[key] = state
    W.full[key] = { player = p, state = stale and { stale = true } or state }
end

local function tick(W, dt)
    W.clock = W.clock + (dt or TICK_MS)
    W.bridged = {}
    if W.beforeTick then W.beforeTick(W) end
    local handlers = {}
    for i, fn in ipairs(W.env.Events.OnTick.handlers) do handlers[i] = fn end
    for _, fn in ipairs(handlers) do fn() end
    table.sort(W.bridged)
    return W.bridged
end

local function joined(list, skip)
    local out = {}
    for _, name in ipairs(list) do if name ~= skip then out[#out + 1] = name end end
    return table.concat(out, ",")
end

local function countPrinted(W, text)
    local n = 0
    for _, line in ipairs(W.printed) do if line:find(text, 1, true) then n = n + 1 end end
    return n
end

-- L 本機；A、B、C 附近且追蹤；D 附近不追蹤也沒 pending；E 追蹤但在範圍外；F 追蹤但 binding.state 不是
-- networkPlayerData 那份（身分未就緒）；G 只有 pending；H 是 requested（tick 開始時 pending，onCleanAppearanceTick 處理掉）
local function standardWorld(patch, coreTransform)
    local W = newWorld({ patch = patch, coreTransform = coreTransform })
    W.localPlayer = newPlayer(W, "L", 1000, 1000)
    local P = {
        A = newPlayer(W, "A", 1010, 1000, { tracked = true }),
        B = newPlayer(W, "B", 1020, 1010, { tracked = true }),
        C = newPlayer(W, "C", 990, 990, { tracked = true }),
        D = newPlayer(W, "D", 1005, 1005),
        E = newPlayer(W, "E", 1500, 1000, { tracked = true }),
        F = newPlayer(W, "F", 1001, 1001, { tracked = true }),
        G = newPlayer(W, "G", 1002, 1003),
        H = newPlayer(W, "H", 1003, 1002),
    }
    for name, p in pairs(P) do bind(W, "k" .. name, p, name == "F") end
    W.core.cleanAppearancePending[P.G] = { desired = true }
    W.beforeTick = function(w) w.core.cleanAppearancePending[P.H] = { desired = true } end
    W.onClean = function(w) w.core.cleanAppearancePending[P.H] = nil end
    W.P = P
    return W
end

-- 上游不經 MirageWardrobeCore 表呼叫 onCleanAppearanceTick（模擬上游改形狀）；找不到呼叫點＝上游真的改了，要重核
local function cleanNotThroughTable(src)
    local fs = src:find("MirageWardrobeCore.onAppearanceBeforeModelUpdate = function", 1, true)
    local s, e = src:find("MirageWardrobeCore.onCleanAppearanceTick()", fs or #src, true)
    if not fs or not s then error("上游 onAppearanceBeforeModelUpdate 不再經表呼叫 onCleanAppearanceTick：照 upstream.json recheck 重核") end
    return src:sub(1, s - 1) .. "CLEAN_DIRECT()" .. src:sub(e + 1)
end

local function realSuite()
    local function within(x, lo, hi) return x ~= nil and x >= lo and x <= hi end

    -- R1 差分：約 3 秒、60 FPS
    local base, pat = standardWorld(false), standardWorld(true)
    local same, restored, n = true, true, 190
    for _ = 1, n do
        local b, p = tick(base), tick(pat)
        if joined(b, "E") ~= joined(p) then same = false end
        if pat.core.networkAppliedBindings ~= pat.full then restored = false end
    end
    local interval = pat.filter.WEAR_INTERVAL_MS
    check("R1 real upstream: same players bridged every tick (patched = upstream minus out-of-range)", same)
    check("R1 real upstream: full binding table restored after every tick", restored)
    check("R1 upstream: tracked/pending/requested players signature-checked every tick",
        base.checks.A == n and base.checks.G == n and base.checks.H == n and base.checks.E == n)
    check("R1 throttle: each near tracked/pending/requested player checked 2-4 times in ~3 s",
        within(pat.checks.A, 2, 4) and within(pat.checks.B, 2, 4) and within(pat.checks.C, 2, 4)
        and within(pat.checks.G, 2, 4) and within(pat.checks.H, 2, 4))
    check("R1 both: untracked and identity-not-ready players never checked",
        not base.checks.D and not base.checks.F and not pat.checks.D and not pat.checks.F)
    check("R1 throttle: out-of-range player never checked", pat.checks.E == nil)
    check("R1 throttle: installed with throttle on, no inactive warning",
        countPrinted(pat, "wear throttle " .. interval .. "ms") == 1 and countPrinted(pat, "inactive") == 0)

    -- R2 髒污變化：舊快照失效的延遲
    local function propagation(W)
        for _ = 1, 70 do tick(W) end -- 1.12 秒：每個人至少比對過一次
        W.core.activeAppearanceSnapshots[W.P.A] = "snapshot"
        W.P.A.list[1].wear.getBlood[3] = 0.5
        local start = W.clock
        for _ = 1, 100 do
            tick(W)
            if W.core.activeAppearanceSnapshots[W.P.A] == nil then return W.clock - start end
        end
    end
    local baseDelay, patDelay = propagation(standardWorld(false)), propagation(standardWorld(true))
    check("R2 upstream: wear change invalidates the snapshot on the next tick", baseDelay == TICK_MS)
    check("R2 throttle: wear change invalidates the snapshot within WEAR_INTERVAL_MS + 1 tick",
        patDelay ~= nil and patDelay <= interval + TICK_MS)

    -- R3 同時第一次看到 16 人：錯開
    local S = newWorld({ patch = true })
    S.localPlayer = newPlayer(S, "L", 1000, 1000)
    for i = 1, 16 do bind(S, "s" .. i, newPlayer(S, "S" .. i, 1000 + i, 1000, { tracked = true })) end
    local maxPerTick, prevTotal = 0, 0
    for _ = 1, 125 do
        tick(S)
        local total = 0
        for _, v in pairs(S.checks) do total = total + v end
        maxPerTick = math.max(maxPerTick, total - prevTotal)
        prevTotal = total
    end
    local eachOk = true
    for i = 1, 16 do if not within(S.checks["S" .. i], 1, 3) then eachOk = false end end
    check("R3 throttle: 16 players seen at once are spread (<= 2 checks per tick)", maxPerTick <= 2)
    check("R3 throttle: each of them checked 1-3 times in 2 s", eachOk)

    -- R4 上游不經表呼叫 onCleanAppearanceTick：只剩範圍過濾、印一次 inactive
    local base4, pat4 = standardWorld(false, cleanNotThroughTable), standardWorld(true, cleanNotThroughTable)
    local same4 = true
    for _ = 1, 70 do
        if joined(tick(base4), "E") ~= joined(tick(pat4)) then same4 = false end
    end
    check("R4 shape changed: one 'wear throttle inactive' line", countPrinted(pat4, "wear throttle inactive") == 1)
    check("R4 shape changed: same players bridged (range filter only)", same4)
    check("R4 shape changed: checked every tick (throttle off)", pat4.checks.A == 70)

    -- R5 原版拋錯（本機玩家的開橋在原版裡、迴圈之前）：原樣重拋、完整表還原
    local base5, pat5 = standardWorld(false), standardWorld(true)
    for _ = 1, 30 do tick(base5); tick(pat5) end
    local boom = function(p) if p.name == "L" then error("boom", 0) end end
    base5.onBridge, pat5.onBridge = boom, boom
    local okB, errB = pcall(tick, base5)
    local okP, errP = pcall(tick, pat5)
    check("R5 error: upstream error propagates unchanged in both", not okB and errB == "boom" and not okP and errP == "boom")
    check("R5 error: full table restored", pat5.core.networkAppliedBindings == pat5.full)

    -- R6 系統時間往回調 10 分鐘：照常比對
    local W6 = standardWorld(true)
    for _ = 1, 70 do tick(W6) end
    local before6 = W6.checks.A or 0
    W6.clock = W6.clock - 600000
    for _ = 1, 70 do tick(W6) end
    check("R6 clock moved back: checks continue", (W6.checks.A or 0) > before6)

    -- R7 onCleanAppearanceTick 期間新增、移除 binding（另一份到期表之前的改動）
    local base7, pat7 = standardWorld(false), standardWorld(true)
    for _ = 1, 40 do tick(base7); tick(pat7) end
    for _, W in ipairs({ base7, pat7 }) do
        local N = newPlayer(W, "N", 1004, 1004, { tracked = true })
        W.core.networkPlayerData.kN = { key = "kN" }
        W.onClean = function(w)
            w.core.cleanAppearancePending[w.P.H] = nil
            w.core.networkAppliedBindings.kN = { player = N, state = w.core.networkPlayerData.kN }
            w.core.networkAppliedBindings.kC = nil
        end
    end
    check("R7 mid-call add/remove: same players bridged", joined(tick(base7), "E") == joined(tick(pat7)))
    check("R7 mid-call add/remove: merged back into the full table",
        pat7.core.networkAppliedBindings == pat7.full and pat7.full.kN ~= nil and pat7.full.kC == nil)
    check("R7 mid-call add: new binding checked in the same tick", pat7.checks.N == 1)

    -- R8 onCleanAppearanceTick 期間整張表被換掉（session 重置）：兩邊都只開本機的橋，補丁留新表
    local base8, pat8 = standardWorld(false), standardWorld(true)
    for _ = 1, 40 do tick(base8); tick(pat8) end
    local fresh = {}
    base8.onClean = function(w) w.core.networkAppliedBindings = {} end
    pat8.onClean = function(w) w.core.networkAppliedBindings = fresh end
    check("R8 session reset mid-call: only the local player bridged in both",
        joined(tick(base8)) == "L" and joined(tick(pat8)) == "L")
    check("R8 session reset mid-call: new table kept", pat8.core.networkAppliedBindings == fresh)
end

rawPrint("== 真上游差分（Mirage Wardrobe 本機訂閱）")
realSuite()

if arg and arg[1] == "--mutants" then
    local mutants = {
        { name = "延後的人不開橋", from = "bridgeDeferred(core, c.deferred, localPlayer, c.requested)", to = "local _ = c.deferred" },
        { name = "從不延後（等於沒節流）", from = "if planned and count > 0 then", to = "if planned and count < 0 then" },
        { name = "延後開橋不看身分", from = "type(state) == \"table\" and binding.state == state then", to = "type(state) == \"table\" then" },
        { name = "延後開橋漏掉 requested", from = "or requested[player] then", to = "then" },
        { name = "第一次看到的人不錯開", from = "nextDue[player] = now + spreadSlot * WEAR_INTERVAL_MS / SPREAD_SLOTS", to = "nextDue[player] = now" },
        { name = "到期晚一個間隔", from = "elseif now >= due or", to = "elseif now >= due + WEAR_INTERVAL_MS or" },
        { name = "比對後不重設到期", from = "nextDue[player] = now + WEAR_INTERVAL_MS\n", to = "nextDue[player] = now\n" },
        { name = "系統時間往回調就卡住", from = " or due - now > WEAR_INTERVAL_MS then", to = " then" },
        { name = "中途新加的 binding 也延後", from = "if c.deferKeys[key] and c.before[key] == binding then", to = "if c.deferKeys[key] or c.before[key] == nil then" },
        { name = "不換回完整表", from = "core.networkAppliedBindings = full", to = "local _ = full" },
        { name = "吞掉上游例外", from = "if not called then error(err, 0) end", to = "" },
        { name = "形狀變了不關節流", from = "throttleOn = false\n            print(PREFIX", to = "print(PREFIX" },
    }
    rawPrint("== 突變（每個都應至少讓一項 FAIL）")
    local survived = 0
    for _, m in ipairs(mutants) do
        local keepPass, keepFail = pass, fail
        MUTATION, quiet = m, true
        pass, fail = 0, 0
        local ok, err = pcall(realSuite)
        local killed = (not ok) or fail > 0
        rawPrint(string.format("  %s  %s（%s）", killed and "KILLED " or "SURVIVED", m.name,
            ok and (fail .. " 項 FAIL") or ("錯誤：" .. tostring(err))))
        if not killed then survived = survived + 1 end
        pass, fail, MUTATION, quiet = keepPass, keepFail, nil, false
    end
    check("所有突變都被抓到", survived == 0)
end

if arg and arg[1] == "--bench" then
    -- 20 位附近追蹤中的玩家、每人 20 件 ItemVisual；標準 Lua 比遊戲的 Kahlua 快很多，只看兩者比例
    for _, patch in ipairs({ false, true }) do
        local W = newWorld({ patch = patch })
        W.localPlayer = newPlayer(W, "L", 1000, 1000)
        for i = 1, 20 do bind(W, "b" .. i, newPlayer(W, "B" .. i, 1000 + i, 1000, { tracked = true, visuals = 20 })) end
        for _ = 1, 120 do tick(W) end
        local t0 = os.clock()
        for _ = 1, 300 do tick(W) end
        rawPrint(string.format("  bench %-8s %.3f ms/tick", patch and "patched" or "upstream", (os.clock() - t0) * 1000 / 300))
    end
end

rawPrint(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
