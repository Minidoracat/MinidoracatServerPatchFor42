-- 離線測試：MSP_WardrobeBridgeFilter（Mirage Wardrobe 塑形橋接只處理附近、畫面內的玩家，穿戴簽章每人節流）。
--   lua scripts/test_wardrobe_bridge_filter.lua             行為與邊界
--   lua scripts/test_wardrobe_bridge_filter.lua --mutants   另對補丁植入錯誤，確認真上游差分抓得到
--   lua scripts/test_wardrobe_bridge_filter.lua --bench     另印上游原樣與補丁每 tick 的成本（標準 Lua，只看比例）
-- 假上游段（1–9，最小引擎 stub）：上游缺席零行為＋OnGameBoot 補裝／OnTick 換掉原註冊／遠處與未載入玩家被濾掉、附近保留／
--       呼叫後完整表還原／原版改寫子集寫回／整表被換掉不還原／原版拋錯先還原再重拋／
--       非 MP 客戶端與無本機玩家直接透傳／重複安裝不疊／形狀不符只在 OnGameBoot 印 NOT installed 一次／
--       上游 shared 先建表、client 檔晚載入時不誤報。
-- 真上游段（R1–R8 節流，R9–R13 畫面過濾）：載入本機 Steam 訂閱裡未修改的 Mirage Wardrobe，上游原樣 vs 補丁差分（見該段開頭）。
-- R9–R13 另照引擎模擬模型重建（ModelManager.update 在 OnTick 之後，重建時看橋開著沒有）與 render（Core.StartFrame
-- 以本機玩家當下位置重新置中鏡頭，IsoGridSquare.IsOnScreen 決定畫不畫），比較每 tick 畫出來的外觀。
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
local UNIT = 64 -- tileScale 2 時一格在螢幕 x 方向的像素（IsoUtils.XToScreen(1, 0, 0, 0)）
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
    local W = { clock = 0, checks = {}, bridged = {}, printed = {}, resetQueue = {}, resets = {}, model = {} }
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
    if opts.camera then -- 鏡頭 API（tileScale 2：一格在螢幕 x 方向 64 像素）；沒有時補丁不做畫面過濾
        env.IsoCamera = {
            getOffX = function() return W.cam.offX end, getOffY = function() return W.cam.offY end,
            getOffscreenWidth = function() return W.cam.w end, getOffscreenHeight = function() return W.cam.h end,
            getRightClickOffX = function() return 0 end, getRightClickOffY = function() return 0 end,
        }
        env.IsoUtils = {
            XToScreen = function(x, y) return (x - y) * UNIT end,
            YToScreen = function(x, y, z) return (x + y) * UNIT / 2 - 3 * z * UNIT end,
        }
        env.getNumActivePlayers = function() return W.numPlayers or 1 end
    end
    setmetatable(env, { __index = function(t, k)
        -- 鏡頭 API 只在 opts.camera 時給（上面已 rawset），否則照遊戲沒有這些全域時處理
        if k:find("^Mirage") or k:find("^MSP_") or k == "IsoCamera" or k == "IsoUtils" or k == "getNumActivePlayers" then
            return nil
        end
        local v = mock(k)
        rawset(t, k, v)
        return v
    end })
    W.env = env
    assert(load(UP_NET_SRC, "@" .. UP_NET, "t", env))()
    assert(load(opts.coreTransform and opts.coreTransform(UP_CORE_SRC) or UP_CORE_SRC, "@" .. UP_CORE, "t", env))()
    local core = env.MirageWardrobeCore
    W.core = core
    -- 橋：開成的記在 appearanceRenderBridges（上游的開橋紀錄），原版每 tick 開頭與 OnPostRender 收掉
    core.appearanceRenderBridges = {}
    core.endAppearanceRenderBridges = function()
        for p in pairs(core.appearanceRenderBridges) do core.appearanceRenderBridges[p] = nil end
        return true, 0
    end
    core.onCleanAppearanceTick = function() if W.onClean then W.onClean(W) end end
    core.beginAppearanceRenderBridge = function(p)
        W.bridged[#W.bridged + 1] = p.name
        if W.onBridge then W.onBridge(p) end
        if W.bridgeFail and W.bridgeFail(p) then return false end
        core.appearanceRenderBridges[p] = true
        return true
    end
    core.shouldTrackAppearance = function(p) return p.tracked == true end
    core.getRemotePlayerItemVisuals = function(p) if p ~= W.localPlayer then return p.visuals end end
    core.getTransmogSourceSlot = function() return "base:test" end
    if opts.sourceModel then
        -- 照 :5371-5454 判斷快照新不新：版本號一樣、經表問的來源簽章（:5401）和快照記的一樣才沿用；否則重拍
        -- （候選的簽章原版用 local 現算，:4788），再經表問一次驗證（:5422），不符就不開橋。經表的呼叫另外計數
        local realSource = core.getAppearanceSourceSignature
        W.sourceChecks, W.snapTaken, W.verifyFails = {}, {}, 0
        W.countedSource = function(p)
            W.sourceChecks[p.name] = (W.sourceChecks[p.name] or 0) + 1
            return realSource(p)
        end
        W.liveSource = realSource
        core.getAppearanceSourceSignature = W.countedSource
        core.beginAppearanceRenderBridge = function(p)
            W.bridged[#W.bridged + 1] = p.name
            if W.onBridge then W.onBridge(p) end
            local revision = core.getAppearanceRevision(p)
            local snapshot = core.activeAppearanceSnapshots[p]
            local signature = core.getAppearanceSourceSignature(p)
            if not (snapshot and snapshot.revision == revision and type(signature) == "string" and
                    snapshot.sourceSignature == signature) then
                local candidate = { revision = revision, sourceSignature = realSource(p) }
                if core.getAppearanceSourceSignature(p) ~= candidate.sourceSignature then
                    W.verifyFails = W.verifyFails + 1
                    return false
                end
                core.activeAppearanceSnapshots[p] = candidate
                snapshot = candidate
                W.snapTaken[p.name] = (W.snapTaken[p.name] or 0) + 1
            end
            core.appearanceRenderBridges[p] = { snapshot = snapshot }
            return true
        end
    end
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
    function p:getZ() return self.z or 0 end
    function p:getPlayerNum() return 0 end
    function p:resetModelNextFrame() -- 只記補丁的呼叫；劇本裡的原生重建直接排進 resetQueue
        W.resetQueue[self] = true
        W.resets[name] = W.resets[name] or {}
        table.insert(W.resets[name], W.tickNo)
    end
    return p
end

local function bind(W, key, p, stale)
    local state = { key = key }
    W.core.networkPlayerData[key] = state
    W.full[key] = { player = p, state = stale and { stale = true } or state }
end

-- 引擎這一幀畫不畫這個人：IsoGridSquare.IsOnScreen（非樹木格）照抄，FBORenderCell.renderPlayer 先看它
local function engineOnScreen(W, p)
    local x, y, z = math.floor(p.x), math.floor(p.y), math.floor(p.z or 0)
    local sx = (x - y) * UNIT - W.cam.offX
    local sy = (x + y) * UNIT / 2 - z * 3 * UNIT - W.cam.offY
    return sx + UNIT > 0 and sy + UNIT > 0 and sx - UNIT < W.cam.w and sy - 3 * UNIT < W.cam.h
end

local function tick(W, dt)
    W.clock = W.clock + (dt or TICK_MS)
    W.tickNo = (W.tickNo or 0) + 1
    W.bridged = {}
    if W.beforeTick then W.beforeTick(W) end
    local handlers = {}
    for i, fn in ipairs(W.env.Events.OnTick.handlers) do handlers[i] = fn end
    for _, fn in ipairs(handlers) do fn() end
    table.sort(W.bridged)
    if W.cam then
        -- ModelManager.update（OnTick 之後）：排了重建的人，看這時橋開著沒有，決定模型用幻化還是實體衣物；
        -- render：Core.StartFrame 以本機玩家當下的位置重新置中鏡頭，引擎畫面上的人記下畫出來的外觀；OnPostRender 收橋
        local bridges = W.core.appearanceRenderBridges
        for p in pairs(W.resetQueue) do W.model[p] = bridges[p] and "mirage" or "real" end
        W.resetQueue, W.drawn = {}, {}
        W:look(W.localPlayer.x, W.localPlayer.y)
        for _, p in pairs(W.P) do
            if engineOnScreen(W, p) then W.drawn[p.name] = W.model[p] end
        end
        W.core.endAppearanceRenderBridges()
    end
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

-- 有鏡頭的世界：本機 L 在 (1000, 1000)，鏡頭 1920×1080、zoom 1、置中在 look(x, y)；
-- 每位玩家照引擎模擬模型：一開始是幻化（之前拍過），之後每次重建看當時橋開著沒有
local function viewWorld(patch)
    local W = newWorld({ patch = patch, camera = true })
    W.localPlayer = newPlayer(W, "L", 1000, 1000)
    W.P = {}
    function W:look(x, y)
        self.cam = { offX = (x - y) * UNIT - 960, offY = (x + y) * UNIT / 2 - 540, w = 1920, h = 1080 }
    end
    W:look(1000, 1000)
    return W
end

local function addPlayer(W, name, x, y, o)
    local p = newPlayer(W, name, x, y, o)
    p.z = o and o.z
    W.P[name] = p
    bind(W, "k" .. name, p)
    W.model[p] = p.tracked and "mirage" or "real"
    return p
end

local function drawnKey(W)
    local out = {}
    for name, look in pairs(W.drawn) do out[#out + 1] = name .. "=" .. look end
    table.sort(out)
    return table.concat(out, ",")
end

local function has(list, name)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end

-- 畫面過濾：上游原樣 vs 補丁，比每 tick 開橋名單與畫出來的外觀
local function viewSuite()
    -- R9 A 在畫面上；V、D（不追蹤）從畫面外 40 格走進來；O 在範圍內、畫面外；Z 在三樓，換算後落在畫面內。
    -- 第 5 tick 引擎重建 V、O 的模型（動作結束這類）；第 301 tick 本機傳送到 O 旁邊，鏡頭直接跳過去
    local function walkIn(patch)
        local W = viewWorld(patch)
        addPlayer(W, "A", 1002, 1000, { tracked = true })
        addPlayer(W, "V", 1040, 1000, { tracked = true })
        addPlayer(W, "D", 1040, 1001)
        addPlayer(W, "O", 1000, 1060, { tracked = true })
        addPlayer(W, "Z", 1016, 1016, { tracked = true, z = 3 })
        W.beforeTick = function(w)
            for _, p in ipairs({ w.P.V, w.P.D }) do p.x = math.max(1010, p.x - 0.1) end
            if w.tickNo == 5 then w.resetQueue[w.P.V], w.resetQueue[w.P.O] = true, true end
            if w.tickNo == 301 then
                w.localPlayer.y = 1058
                w:look(1000, 1058)
            end
        end
        return W
    end
    local base, pat = walkIn(false), walkIn(true)
    local sameDrawn, drawnBridged, oSkipped, oBase, setup = true, true, true, true, false
    local vFirstBridged, vFirstDrawn, oFirstAfterJump, vEntryChecked, oEntryChecked
    for _ = 1, 330 do
        local cv, co = pat.checks.V or 0, pat.checks.O or 0
        local b, p = tick(base), tick(pat)
        local t = pat.tickNo
        if drawnKey(base) ~= drawnKey(pat) then sameDrawn = false end
        for name in pairs(base.drawn) do
            if has(b, name) and not has(p, name) then drawnBridged = false end
        end
        if t <= 300 then
            if has(p, "O") then oSkipped = false end
            if not has(b, "O") then oBase = false end
        elseif not oFirstAfterJump and has(p, "O") then
            oFirstAfterJump = t
        end
        if not vFirstBridged and has(p, "V") then
            vFirstBridged = t
            vEntryChecked = (pat.checks.V or 0) > cv
        end
        if t == 301 then oEntryChecked = (pat.checks.O or 0) > co end
        if not vFirstDrawn and pat.drawn.V then vFirstDrawn = t end
        if t == 100 then setup = pat.model[pat.P.V] == "real" and base.model[base.P.V] == "mirage" end
    end
    local vr, orr = pat.resets.V or {}, pat.resets.O or {}
    check("R9 setup: engine rebuild while off screen used physical clothes (patched), mirage (upstream)", setup)
    check("R9 view: drawn appearance identical to upstream on every tick", sameDrawn)
    check("R9 view: every player the engine draws and upstream bridges is bridged", drawnBridged)
    check("R9 view: in range but off screen -> skipped (upstream bridges it every tick)", oSkipped and oBase)
    check("R9 view: walking in -> one rebuild, on the first bridged tick, before the first drawn tick",
        #vr == 1 and vr[1] == vFirstBridged and vFirstDrawn ~= nil and vr[1] < vFirstDrawn)
    check("R9 view: camera jump -> rebuilt on the jump tick and drawn as mirage",
        #orr == 1 and orr[1] == 301 and oFirstAfterJump == 301 and pat.drawn.O == "mirage")
    check("R9 view: untracked player (never bridged) never rebuilt", pat.resets.D == nil)
    check("R9 view: offView counted", pat.filter.stats.offView > 0)
    check("R9 view: entering players' signatures checked on the entry tick (walking in, camera jump)",
        vEntryChecked == true and oEntryChecked == true)

    -- R10 在畫面邊外來回：進緩衝（離中心 19 格）後在 19、22 格（緩衝外、保留範圍內）間來回 10 次，
    -- 再退到 30 格（保留範圍外）又回來
    local H = viewWorld(true)
    local hv = addPlayer(H, "V", 1030, 1000, { tracked = true })
    H.beforeTick = function(w)
        local t = w.tickNo
        local dx = 19
        if t <= 10 or (t > 210 and t <= 230) then dx = 30
        elseif t <= 210 and math.floor((t - 11) / 10) % 2 == 1 then dx = 22 end
        hv.x = 1000 + dx
    end
    for _ = 1, 250 do tick(H) end
    local hr = H.resets.V or {}
    check("R10 hysteresis: back and forth near the edge rebuilds once, leaving and returning rebuilds again",
        #hr == 2 and hr[1] == 11 and hr[2] == 231)

    -- R11 分割畫面：不做畫面過濾，開橋名單與上游相同
    local function split(patch)
        local S = viewWorld(patch)
        S.numPlayers = 2
        addPlayer(S, "A", 1002, 1000, { tracked = true })
        addPlayer(S, "O", 1000, 1060, { tracked = true })
        return S
    end
    local bs, ps = split(false), split(true)
    local sameSplit = true
    for _ = 1, 30 do if joined(tick(bs)) ~= joined(tick(ps)) then sameSplit = false end end
    check("R11 split screen: no view filter, same players bridged as upstream", sameSplit and ps.resets.O == nil)

    -- R12 走進來那幾個 tick 開橋失敗（快照重試中）：等第一次開成橋才重建
    local function failing(patch)
        local F = viewWorld(patch)
        local v = addPlayer(F, "V", 1040, 1000, { tracked = true })
        F.bridgeFail = function(p) return p == v and F.tickNo >= 190 and F.tickNo <= 230 end
        F.beforeTick = function(w)
            v.x = math.max(1010, v.x - 0.1)
            if w.tickNo == 5 then w.resetQueue[v] = true end
        end
        return F
    end
    local bf, pf = failing(false), failing(true)
    local sameFail = true
    for _ = 1, 300 do
        tick(bf); tick(pf)
        if drawnKey(bf) ~= drawnKey(pf) then sameFail = false end
    end
    local fr = pf.resets.V or {}
    check("R12 bridge failed on entry: rebuilt on the first tick the bridge opens, drawn appearance identical",
        sameFail and #fr == 1 and fr[1] == 231)

    -- R13 本機玩家在鏡頭更新之後才被傳送（OnPlayerUpdate、動作裡）：OnTick 時 IsoCamera 還是舊位置，render 前才重新置中
    local function lateTeleport(patch)
        local T = viewWorld(patch)
        local o = addPlayer(T, "O", 1000, 1060, { tracked = true })
        T.beforeTick = function(w)
            if w.tickNo == 5 then w.resetQueue[o] = true end
            if w.tickNo == 40 then w.localPlayer.y = 1058 end -- 不呼叫 look：IsoCamera 停在舊位置
        end
        return T
    end
    local bt, pt = lateTeleport(false), lateTeleport(true)
    local sameLate = true
    for _ = 1, 60 do
        tick(bt); tick(pt)
        if drawnKey(bt) ~= drawnKey(pt) then sameLate = false end
    end
    local lr = pt.resets.O or {}
    check("R13 teleported after the camera update: rebuilt on the teleport tick, drawn appearance identical",
        sameLate and #lr == 1 and lr[1] == 40 and pt.drawn.O == "mirage")
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
        countPrinted(pat, "signature throttle " .. interval .. "ms") == 1 and countPrinted(pat, "inactive") == 0)

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
    check("R4 shape changed: one 'signature throttle inactive' line", countPrinted(pat4, "signature throttle inactive") == 1)
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

    -- R14 來源簽章（照原版判斷快照新不新的開橋）：延後的人第一次問時回快照記的簽章；
    -- 換衣服（OnClothingUpdated 加版本號）當下重拍，清單被重排（不觸發事件）最多晚一個間隔
    local function sourceWorld(patch)
        local W = newWorld({ patch = patch, sourceModel = true })
        W.localPlayer = newPlayer(W, "L", 1000, 1000)
        W.P = { A = newPlayer(W, "A", 1003, 1000, { tracked = true }), B = newPlayer(W, "B", 1000, 1004, { tracked = true }) }
        for name, p in pairs(W.P) do bind(W, "k" .. name, p) end
        for _ = 1, 70 do tick(W) end -- 每個人至少比對過一次、都有快照
        return W
    end
    local bs, ps = sourceWorld(false), sourceWorld(true)
    local b0, p0, sameS = bs.sourceChecks.A, ps.sourceChecks.A, true
    for _ = 1, 190 do if joined(tick(bs)) ~= joined(tick(ps)) then sameS = false end end
    check("R14 source: same players bridged", sameS)
    check("R14 source: upstream asks every tick, patch 2-4 times in ~3 s (deferred bridges reuse the snapshot's)",
        bs.sourceChecks.A - b0 == 190 and within(ps.sourceChecks.A - p0, 2, 4) and ps.filter.stats.sourceSkips > 0)
    check("R14 source: hook restored after the tick (UI callers get the live signature)",
        ps.core.getAppearanceSourceSignature == ps.countedSource)
    local function sourceDelay(W, change)
        change(W)
        local start = W.clock
        for _ = 1, 100 do
            tick(W)
            W.core.endAppearanceRenderBridges() -- OnPostRender 收橋，之後問的才是實體衣物的簽章
            local snap = W.core.activeAppearanceSnapshots[W.P.A]
            if snap and snap.sourceSignature == W.liveSource(W.P.A) then return W.clock - start end
        end
    end
    local function reorder(W) local l = W.P.A.list; l[1], l[2] = l[2], l[1] end
    local function clothing(W) reorder(W); W.core.markAppearanceChanged(W.P.A) end
    local patR = sourceDelay(sourceWorld(true), reorder)
    check("R14 source: list reordered without OnClothingUpdated -> upstream next tick, patch within WEAR_INTERVAL_MS + 1 tick",
        sourceDelay(sourceWorld(false), reorder) == TICK_MS and patR ~= nil and patR <= interval + TICK_MS)
    local pc = sourceWorld(true)
    local patC = sourceDelay(pc, clothing)
    check("R14 source: clothing change (revision bump) -> re-snapshot on the next tick in both, verification passes",
        sourceDelay(sourceWorld(false), clothing) == TICK_MS and patC == TICK_MS and pc.verifyFails == 0)
    local pe = sourceWorld(true)
    pe.onBridge = function(p)
        if p == pe.P.B and pe.core.getAppearanceSourceSignature ~= pe.countedSource then error("boom-src", 0) end
    end
    local okE, errE
    for _ = 1, 10 do
        okE, errE = pcall(tick, pe)
        if not okE then break end
    end
    check("R14 source: error in a deferred bridge propagates; hook and full table restored",
        not okE and errE == "boom-src" and pe.core.getAppearanceSourceSignature == pe.countedSource and
        pe.core.networkAppliedBindings == pe.full)

    viewSuite()
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
        { name = "比對後不重設到期", from = "nextDue[player] = now + WEAR_INTERVAL_MS\n                stats.due = stats.due + 1\n            else\n",
          to = "nextDue[player] = now\n                stats.due = stats.due + 1\n            else\n" },
        { name = "系統時間往回調就卡住", from = " or due - now > WEAR_INTERVAL_MS then", to = " then" },
        { name = "中途新加的 binding 也延後", from = "if c.deferKeys[key] and c.before[key] == binding then", to = "if c.deferKeys[key] or c.before[key] == nil then" },
        { name = "不換回完整表", from = "core.networkAppliedBindings = full", to = "local _ = full" },
        { name = "吞掉上游例外", from = "if not called then error(err, 0) end", to = "" },
        { name = "形狀變了不關節流", from = "throttleOn = false\n            print(PREFIX", to = "print(PREFIX" },
        { name = "畫面外也處理", from = "if keep and unit and player ~= localPlayer then", to = "if false and unit and player ~= localPlayer then" },
        { name = "走進畫面不重建", from = "player:resetModelNextFrame()", to = "local _ = player" },
        { name = "沒開成橋也重建", from = "if state == \"pending\" and type(bridges) == \"table\" and bridges[player] then", to = "if state == \"pending\" then" },
        { name = "沒開成橋就不再等", from = "    shown = inView\n", to = "    for p in pairs(inView) do inView[p] = true end\n    shown = inView\n" },
        { name = "沒有緩衝", from = "local VIEW_MARGIN = 4", to = "local VIEW_MARGIN = 0" },
        { name = "沒有遲滯", from = "local VIEW_KEEP_MARGIN = 8", to = "local VIEW_KEEP_MARGIN = 4" },
        { name = "忽略樓層", from = "- 3 * math.floor(player:getZ())", to = "- 0" },
        { name = "分割畫面也篩", from = "getNumActivePlayers() > 1 then", to = "getNumActivePlayers() > 9 then" },
        { name = "只看 IsoCamera 的偏移", from = "inRect(sx, sy, nowX, nowY, width, height, unit, pad)", to = "false" },
        { name = "走進畫面不算到期", from = "if inView and inView[player] == \"pending\" then", to = "if false then" },
        { name = "延後的人照算來源簽章", from = "core.getAppearanceSourceSignature = sourceHook", to = "local _ = sourceHook" },
        { name = "來源簽章不只省第一問", from = "        assumeFor = nil\n        local snapshots", to = "        local snapshots" },
        { name = "不還原來源簽章函式", from = "if core.getAppearanceSourceSignature == sourceHook then core.getAppearanceSourceSignature = live end", to = "" },
        { name = "延後開橋出錯不還原", from = "local ok, err = pcall(bridgeEach, core, deferred, localPlayer, requested)",
          to = "bridgeEach(core, deferred, localPlayer, requested); local ok, err = true" },
        { name = "吞掉延後開橋的例外", from = "    if not ok then error(err, 0) end\nend", to = "end" },
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
