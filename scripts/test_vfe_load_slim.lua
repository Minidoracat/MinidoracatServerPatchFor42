-- 離線測試：Vanilla Foods Expanded 載入瘦身（MSP_VfeLoadSlim）。載入「未修改的」上游 shared/vfx_birthday.lua、
-- server/vfx_agingmanager.lua 與 server/vfx_storydistribution.lua（本機 Steam 訂閱副本），同一個模擬世界各跑一次「上游原樣」與
-- 「補丁」，逐幀比對三個上游的內部狀態（aging 掃描佇列與登記表、story 待處理建築）、引擎回呼清單、所有物品變動與亂數序列、
-- 上游 log，以及最後的存檔內容。Mods= 兩種順序都跑：本 MOD 在 VFE 之前（birthday 併入合併回呼）、VFE 在前（birthday 留給引擎）。
--   lua scripts/test_vfe_load_slim.lua             等價差分、邊界、回退
--   lua scripts/test_vfe_load_slim.lua --mutants   另對補丁植入錯誤，確認差分抓得到
--   lua scripts/test_vfe_load_slim.lua --bench     另印每格／每 chunk 的上游呼叫數、Java 呼叫替身數與離線耗時
-- 引擎模擬（反編譯 42.21.0）：
-- - 專用伺服器依 Mods= 逐 MOD 載入 shared/，再逐 MOD 載入 server/（LuaManager.java:1151-1188、GameServer.java:1469-1471），
--   之後 OnGameBoot、OnInitGlobalModData。
-- - 一幀：preupdate 載入 cell（ServerMap.java:430-510；loader 先把 64 個 chunk 放進 cell，RecalcAll2 開頭 isLoaded＝true，
--   再依 x 外圈、y 內圈對每個 chunk doLoadGridsquare，:828-956）→ OnTick → postupdate 卸載 cell（:533-560）。
-- - doLoadGridsquare（IsoChunk.java:3800-3969）：z→x→y 對有物件的格子觸發 LoadGridsquare；之後 randomizeBuildingsEtc
--   （完整載入的建築跑建築故事，這裡模擬安全屋故事直接填容器、不觸發 OnFillContainer）；再 loadGridSquareIfNeeded
--   （LoadGridsquarePerformanceWorkaround.java:22-66：每格第一次載入時，物件第一個未探索容器照一般戰利品表填、觸發
--   OnFillContainer、設為已探索）；最後觸發 LoadChunk。
-- - 卸載：chunk 回池、loadID 設 -1（getLoadID 對 -1 丟例外，IsoChunk.java:5294、:5366-5371）；格子物件回池（FIFO）後
--   在別處重用；專用伺服器不觸發 ReuseGridsquare（WorldReuserThread.java:105-137）。
-- - BuildingDef.isFullyStreamedIn 查的是「所在 cell 已 isLoaded 且 chunk 在」（BuildingDef.java:423-434、ServerMap.java:669-678）。

local WS = "D:/SteamLibrary/steamapps/workshop/content/108600/3577903007/mods/Vanilla Foods Expanded/42.18/"
local UP = {
    birthday = WS .. "media/lua/shared/vfx_birthday.lua",
    aging = WS .. "media/lua/server/vfx_agingmanager.lua",
    story = WS .. "media/lua/server/vfx_storydistribution.lua",
}
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
for _, path in pairs(UP) do readFile(path) end

local pass, fail = 0, 0
local rawPrint = print
local function check(name, cond)
    if cond then pass = pass + 1; rawPrint("  PASS  " .. name) else fail = fail + 1; rawPrint("  FAIL  " .. name) end
end

-- 上游回呼的定義行從原始碼找（不寫死行號）；找不到就是上游改了形狀，照 upstream.json 的 recheck 重核
local function lineOf(path, text)
    local n = 0
    for line in readFile(path):gmatch("[^\n]*\n?") do
        n = n + 1
        if line:find(text, 1, true) then return n end
    end
    error("上游找不到：" .. text .. "（" .. path .. "）")
end
local LINE = {
    agingLoad = lineOf(UP.aging, "local function loadGridSquare(square)"),
    scanQueue = lineOf(UP.aging, "processSquareScanQueue = function()"),
    scanSquare = lineOf(UP.aging, "local function scanGridSquare(square)"),
    storyLoad = lineOf(UP.story, "local function onLoadGridsquare(square)"),
    storyChunk = lineOf(UP.story, "onLoadChunk = function(chunk)"),
    prune = lineOf(UP.story, "local function pruneBuilding(group, cell, softReset)"),
    birthdayLoad = lineOf(UP.birthday, "Events.LoadGridsquare.Add(function(square)"),
}

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

local MUTATION -- { name, edits = { { file, from, to } } }
local function loadPatch(path)
    local source = readFile(path)
    if MUTATION then
        for _, edit in ipairs(MUTATION.edits) do
            if edit.file == path then
                local s, e = source:find(edit.from, 1, true)
                if not s then error("突變片段不在原始碼中：" .. MUTATION.name) end
                source = source:sub(1, s - 1) .. edit.to .. source:sub(e + 1)
            end
        end
    end
    return assert(load(source, "@" .. path))()
end

-- ===== 假引擎狀態 =====
local S -- 每次執行的狀態
local function log(line) S.effects[#S.effects + 1] = line end
local function jc(name)
    if S.counting then
        local phase = S.phase or "other"
        S.java[phase] = (S.java[phase] or 0) + 1
    end
end

function print(...)
    local line = table.concat({ ... }, " ")
    if line:find("MinidoracatServerPatchFor42", 1, true) then S.patchPrints[#S.patchPrints + 1] = line
    elseif line:find("[VFX", 1, true) then S.upstreamPrints[#S.upstreamPrints + 1] = line end
end

local function newEvent(name)
    local event = { list = {}, name = name }
    event.Add = function(fn) if type(fn) == "function" then event.list[#event.list + 1] = fn end end
    event.Remove = function(fn)
        for i, f in ipairs(event.list) do if f == fn then table.remove(event.list, i); return end end
    end
    event.engineAdd = event.Add
    return event
end
-- Event.trigger（Event.java:52-64）：每圈重讀清單長度；callback 自己被移除時不跳過下一個
local function trigger(event, ...)
    local n = 1
    while n <= #event.list do
        local fn = event.list[n]
        if S.counting then S.dispatch[event.name] = (S.dispatch[event.name] or 0) + 1 end
        local ok, err = pcall(fn, ...)
        if not ok then log("callback error in " .. event.name .. ": " .. tostring(err):gsub("^.-:%d+: ", "")) end
        local still = false
        for _, f in ipairs(event.list) do if f == fn then still = true; break end end
        if still then n = n + 1 end
    end
end

-- Java 物件替身：方法呼叫才計數（引擎自己直接讀欄位）
local List = {}; List.__index = List
function List:size() jc(); return #self.t end
function List:get(i) jc(); return self.t[i + 1] end
function List:isEmpty() jc(); return #self.t == 0 end
function List:contains(v) jc(); for _, x in ipairs(self.t) do if x == v then return true end end return false end
function List:clear() jc(); for i = #self.t, 1, -1 do self.t[i] = nil end end
local function newList(t) return setmetatable({ t = t }, List) end

local Item = {}; Item.__index = Item
local function newItem(type, id, age, modData)
    if not id then S.nextItemId = S.nextItemId + 1; id = S.nextItemId end
    return setmetatable({ id = id, type = type, age = age or 0, modData = modData, class = "InventoryItem" }, Item)
end
function Item:getID() jc(); return self.id end
function Item:getFullType() jc(); return self.type end
function Item:hasModData() jc(); return self.modData ~= nil end
function Item:getModData() jc(); self.modData = self.modData or {}; return self.modData end
function Item:IsInventoryContainer() jc(); return false end
function Item:getFluidContainer() jc(); return nil end
function Item:updateAge() jc() end
function Item:getAge() jc(); return self.age end
function Item:setAge(age) jc(); self.age = age end
function Item:getWorldItem() jc(); return self.worldItem end
function Item:setWorldItem(w) jc(); self.worldItem = w end
function Item:getContainer() jc(); return self.container end
-- birthday 用到的物品方法（數值變動記進副作用）
function Item:getCurrentUses() jc(); return self.uses or 0 end
function Item:setCurrentUses(n) jc(); self.uses = n; log(string.format("uses #%d=%s", self.id, tostring(n))) end
function Item:getTicks() jc(); return self.ticks or 0 end
function Item:setTicks(n) jc(); self.ticks = n; log(string.format("ticks #%d=%s", self.id, tostring(n))) end
function Item:getCondition() jc(); return 10 end
function Item:setCondition() jc() end
function Item:isFavorite() jc(); return false end
function Item:setFavorite() jc() end
function Item:copyModData() jc() end
function Item:getTicksPerEquipUse() jc(); return 30 end
function Item:isUseWhileEquiped() jc(); return false end
function Item:isUseWhileUnequiped() jc(); return true end
function Item:setUseWhileEquiped(v) jc(); log(string.format("burnEq #%d=%s", self.id, tostring(v))) end
function Item:setUseWhileUnequiped(v) jc(); log(string.format("burnUneq #%d=%s", self.id, tostring(v))) end
function Item:getLightDistance() jc(); return 2 end
function Item:getLightStrength() jc(); return 0.5 end

local Container = {}; Container.__index = Container
function Container:isExplored() jc(); return self.explored end
function Container:getItems() jc(); return newList(self.items) end
function Container:getParent() jc(); return self.parent end
function Container:getType() jc(); return "crate" end
function Container:AddItem(x)
    jc()
    local item = type(x) == "string" and newItem(x) or x
    item.container = self
    self.items[#self.items + 1] = item
    log(string.format("add c%d %s#%d", self.id, item.type, item.id))
    return item
end
function Container:Remove(item)
    jc()
    for i, v in ipairs(self.items) do
        if v == item then
            table.remove(self.items, i)
            item.container = nil
            log(string.format("remove c%d #%d", self.id, item.id))
            return
        end
    end
end

local Obj = {}; Obj.__index = Obj
function Obj:getContainerCount() jc(); return #self.containers end
function Obj:getContainerByIndex(i) jc(); return self.containers[i + 1] end
function Obj:getSquare() jc(); return self.square end
function Obj:getItem() jc(); return self.item end
function Obj:swapItem(item)
    jc()
    log(string.format("swap s%d #%d->%s#%d", self.square.id, self.item.id, item.type, item.id))
    self.item.worldItem = nil
    self.item, item.worldItem = item, self
end

local Square = {}; Square.__index = Square
function Square:getX() jc(); return self.x end
function Square:getY() jc(); return self.y end
function Square:getZ() jc(); return self.z end
function Square:getObjects() jc(); return newList(self.objects) end
function Square:getWorldObjects() jc(); return newList(self.worldObjects) end
function Square:getChunk() jc(); return self.chunk end
function Square:getRoom() jc(); return self.room end
-- IsoGridSquare.getObjectContainers（IsoGridSquare.java:9998-10009）：每個物件的主容器（IsoObject.getContainers :1907-1922）
function Square:getObjectContainers(_, _, list)
    jc()
    for _, obj in ipairs(self.objects) do
        local c = obj.containers[1]
        if c then
            local seen = false
            for _, x in ipairs(list.t) do if x == c then seen = true end end
            if not seen then list.t[#list.t + 1] = c end
        end
    end
    return list
end
function Square:transmitRemoveItemFromSquare(obj) jc(); log(string.format("transmitRemove s%d #%d", self.id, obj.item.id)) end
function Square:removeWorldObject(obj)
    jc()
    for _, t in ipairs({ self.worldObjects, self.objects }) do
        for i, o in ipairs(t) do if o == obj then table.remove(t, i); break end end
    end
    log(string.format("removeWorld s%d #%d", self.id, obj.item.id))
end

local MAP = {} -- 每次執行重建：cellKey → { loaded, chunks[px*8+py] }
local function serverChunk(wx, wy)
    local cell = MAP[(wx // 8) .. ":" .. (wy // 8)]
    return cell and cell.loaded and cell.chunks[(wx % 8) * 8 + wy % 8] or nil
end
local function serverSquare(x, y, z)
    local chunk = serverChunk(x // 8, y // 8)
    local level = chunk and chunk.squares[z]
    return level and level[(x % 8) * 8 + y % 8] or nil
end

local Chunk = {}; Chunk.__index = Chunk
function Chunk:getGridSquare(x, y, z)
    jc()
    if x < 0 or x > 7 or y < 0 or y > 7 then return nil end
    local level = self.squares[z]
    return level and level[x * 8 + y] or nil
end
function Chunk:getLoadID()
    jc()
    if self.loadId == -1 then error("IsoChunk.loadID is invalid") end
    return self.loadId
end
function Chunk:getMinLevel() jc(); return self.minLevel end
function Chunk:getMaxLevel() jc(); return self.maxLevel end

local CELL = {}
function CELL:getChunkForGridSquare(x, y, z) jc(); return serverChunk(x // 8, y // 8) end
function CELL:getGridSquare(x, y, z) jc(); return serverSquare(x, y, z) end
local WORLD = {}
function WORLD:getFrameNo() jc(); return S.frame end

local Def = {}; Def.__index = Def
function Def:getX() jc(); return self.x end
function Def:getY() jc(); return self.y end
function Def:getX2() jc(); return self.x2 end
function Def:getY2() jc(); return self.y2 end
function Def:isUserDefined() jc(); return self.userDefined end
function Def:getID() jc(); return self.id end
function Def:getRooms() jc(); return newList(self.roomDefs) end
function Def:isFullyStreamedIn()
    jc()
    for wx = self.x // 8, self.x2 // 8 do
        for wy = self.y // 8, self.y2 // 8 do
            if not serverChunk(wx, wy) then return false end
        end
    end
    return true
end
local RoomDef = {}; RoomDef.__index = RoomDef
function RoomDef:getProceduralSpawnedContainer() jc(); return next(self.counts) and self.map or nil end
local Counts = {}; Counts.__index = Counts
function Counts:get(name) jc(); return self.owner.counts[name] end
local IsoRoom = {}; IsoRoom.__index = IsoRoom
function IsoRoom:getBuilding() jc(); return self.building end
local IsoBuilding = {}; IsoBuilding.__index = IsoBuilding
function IsoBuilding:getDef() jc(); return self.def end

-- ===== 全域 API 替身 =====
function isServer() return true end
function getText(key) return key end
function isClient() return false end
function isServerSoftReset() jc(); return S.softReset end
function getActivatedMods() return { contains = function(_, id) return S.mods[id] == true end } end
function getFilenameOfClosure(fn) return (debug.getinfo(fn, "S").source:gsub("^@", ""):gsub("\\", "/")) end
function getCell() jc(); return CELL end
function getWorld() jc(); return WORLD end
function getGameTime() return { getWorldAgeHours = function() return 100 end, getMinutesPerDay = function() return 60 end } end
GameTime = { getServerTime = function() jc(); S.clock = S.clock + 100000; return S.clock end } -- 每次 0.1 ms
Fluid = { Get = function() jc(); return nil end }
function instanceof(o, class) jc(); return type(o) == "table" and o.class == class end
function instanceItem(type) jc(); return newItem(type) end
function sendReplaceItemInContainer(container, old, new)
    jc()
    log(string.format("send c%d #%d->#%d", container.id, old.id, new.id))
end
function ZombRand(n)
    S.rng = (S.rng * 1103515245 + 12345) % 2147483648
    local v = S.rng % n
    log("rand " .. n .. "=" .. v)
    return v
end
function getModFileReader(modId, path)
    if modId ~= "VanillaFoodsExpanded" then return nil end
    local lines = javaLines(S.fileOverride and S.fileOverride[path] or readFile(WS .. path))
    local i = 0
    return {
        readLine = function() i = i + 1; return lines[i] end,
        close = function() end,
    }
end
-- Kahlua 的類別方法表（KahluaUtil.getClassMetatables）與類別物件；PZArrayList 建構子
IsoGridSquare, ArrayList, ItemContainer = { class = "C:IsoGridSquare" }, { class = "C:ArrayList" }, { class = "C:ItemContainer" }
PZArrayList = { class = "C:PZArrayList", new = function() jc(); return newList({}) end }
__classmetatables = { ["C:IsoGridSquare"] = { __index = Square }, ["C:ArrayList"] = { __index = List },
    ["C:PZArrayList"] = { __index = List } }
-- birthday 用到的全域
ModData = {
    get = function(key) return S.modData[key] end,
    getOrCreate = function(key) S.modData[key] = S.modData[key] or {}; return S.modData[key] end,
    remove = function(key) S.modData[key] = nil end,
}
function sendServerCommand(module, command, args)
    log(string.format("server %s %s #%s", module, command, tostring(args and args.id)))
end
function sendItemStats(item) log(string.format("stats #%d", item.id)) end

-- ===== 世界規格（每個種子一份；建築／房間物件跨兩次執行共用，pairs(建築) 的順序才可比）=====
-- VFX.YeastStarterFermenting 是上游 ReplaceItemTable 的起點（5 天 → VFX.YeastStarter → …），VFX.YeastStarter 也在故事替換表裡
local FILL = { "Base.CannedSoup", "Base.Bread", "VFX.YeastStarterFermenting", "Base.Nails", "VFX.YeastStarter" }
local STORY_FILL = { "Base.CannedSoup", "VFX.YeastStarter", "Base.Bread", "VFX.YeastStarterFermenting" }

local function newDef(id, x, y, x2, y2, opts)
    local def = setmetatable({ id = id, x = x, y = y, x2 = x2, y2 = y2, userDefined = opts.userDefined == true,
        safehouse = opts.safehouse == true, upper = opts.upper == true, roomDefs = {} }, Def)
    local roomDef = setmetatable({ counts = {} }, RoomDef)
    roomDef.map = setmetatable({ owner = roomDef }, Counts)
    def.roomDefs[1] = roomDef
    def.room = setmetatable({ building = setmetatable({ def = def }, IsoBuilding) }, IsoRoom)
    return def
end

-- tiles[key] = { x, y, z, floor, crates = { { cid... } }, ground = { itemData }, room }；containers[cid] = { explored, items }
local function addTile(spec, x, y, z, def, R)
    local tile = { x = x, y = y, z = z, crates = {}, ground = {}, room = def and def.room or nil }
    local indoor = def ~= nil
    tile.floor = indoor or R() < 0.85
    local crateChance = indoor and 0.22 or 0.05
    if R() < crateChance then
        local crate = {}
        for _ = 1, (indoor and R(1, 2) or 1) do
            spec.nextCid = spec.nextCid + 1
            local data = { explored = R() < 0.3, items = {} }
            local n = data.explored and R(0, 3) or (R() < 0.4 and 1 or 0)
            for _ = 1, n do
                spec.nextItem = spec.nextItem + 1
                -- 未探索容器裡、熟成 5～6 天的發酵酵母：aging 立即掃描會把它換成 VFX.YeastStarter（也在故事替換表裡），
                -- 換在 story 記下原有物品之前或之後，故事替換的結果不同（測合併回呼的呼叫順序）
                local seeded = not data.explored and R() < 0.5
                data.items[#data.items + 1] = { id = spec.nextItem, type = seeded and "VFX.YeastStarterFermenting" or FILL[R(1, #FILL)],
                    age = seeded and R(5, 6) or R(0, 20) }
            end
            spec.containers[spec.nextCid] = data
            crate[#crate + 1] = spec.nextCid
        end
        tile.crates[1] = crate
    end
    if R() < 0.04 then
        spec.nextItem = spec.nextItem + 1
        tile.ground[1] = { id = spec.nextItem, type = "Base.Plank", age = 0 }
    end
    -- 地上點著的生日蠟燭（約 1.4% 的格子；位置由座標決定，不動 R() 的序列）：重開機紀錄在原位（birthday 接續燃燒，燒完的移除）、
    -- 在別處（換成沒點的蠟燭）或沒有紀錄（換掉）
    local h = (x * 7919 + y * 104729 + z * 31) % 211
    if h < 3 then
        spec.nextItem = spec.nextItem + 1
        local id = spec.nextItem
        tile.ground[#tile.ground + 1] = { id = id, type = "VFX.BirthdayCandleLit", age = 0, uses = (x + y) % 4, ticks = 5 }
        if h == 0 then spec.restart[tostring(id)] = { x = x, y = y, z = z, equipped = false, unequipped = true }
        elseif h == 1 then spec.restart[tostring(id)] = { x = x + 1, y = y, z = z, equipped = false, unequipped = true } end
    end
    spec.tiles[x .. ":" .. y .. ":" .. z] = tile
    if def then def.tiles[#def.tiles + 1] = tile end
end

local CX0, CY0, NCX, NCY = 120, 130, 3, 2
local function cellKeyOf(cx, cy) return cx .. ":" .. cy end

local function baseSpec()
    return { tiles = {}, containers = {}, defs = {}, invalid = {}, frames = {}, cells = {}, nextCid = 0, nextItem = 0, restart = {} }
end

local function buildTiles(spec, R)
    local x0, y0 = CX0 * 64, CY0 * 64
    local defAt = {}
    for _, def in ipairs(spec.defs) do
        def.tiles = {}
        for x = def.x, def.x2 do for y = def.y, def.y2 do defAt[x .. ":" .. y] = defAt[x .. ":" .. y] or def end end
    end
    for x = x0, x0 + NCX * 64 - 1 do
        for y = y0, y0 + NCY * 64 - 1 do
            local def = defAt[x .. ":" .. y]
            addTile(spec, x, y, 0, def, R)
            if def and def.upper then addTile(spec, x, y, 1, def, R) end
        end
    end
end

local function randomSpec(seed)
    math.randomseed(seed)
    local R = math.random
    local spec = baseSpec()
    for cx = CX0, CX0 + NCX - 1 do for cy = CY0, CY0 + NCY - 1 do spec.cells[#spec.cells + 1] = cellKeyOf(cx, cy) end end
    for i = 1, 34 do
        local w, h = R(2, 16), R(2, 16)
        local x = CX0 * 64 + R(0, NCX * 64 - w - 1)
        local y = CY0 * 64 + R(0, NCY * 64 - h - 1)
        spec.defs[i] = newDef(i, x, y, x + w - 1, y + h - 1,
            { safehouse = R() < 0.5, userDefined = R() < 0.1, upper = R() < 0.3 })
    end
    buildTiles(spec, R)
    -- 地圖邊緣：某些 chunk 永遠不存在（isValidChunk，ServerChunkLoader.java:200）
    spec.invalid[(CX0 * 8) .. ":" .. (CY0 * 8)] = true
    spec.invalid[(CX0 * 8 + 7) .. ":" .. (CY0 * 8 + 7)] = true
    local loaded, order = {}, {}
    for f = 1, 34 do
        local frame = { loads = {}, unloads = {}, soft = R() < 0.08 }
        local loads = R() < 0.2 and 2 or (R() < 0.7 and 1 or 0)
        for _ = 1, loads do
            local free = {}
            for _, key in ipairs(spec.cells) do if not loaded[key] then free[#free + 1] = key end end
            if #free > 0 then
                local key = free[R(1, #free)]
                loaded[key] = true
                local fails = {}
                for pos = 0, 63 do if R() < 0.02 then fails[pos] = true end end -- LoadChunk 失敗（ServerChunkLoader.java:209-211）
                frame.loads[#frame.loads + 1] = { key = key, fails = fails }
            end
        end
        if R() < 0.4 then
            local busy = {}
            for _, key in ipairs(spec.cells) do if loaded[key] then busy[#busy + 1] = key end end
            if #busy > 0 then
                local key = busy[R(1, #busy)]
                loaded[key] = nil
                frame.unloads[#frame.unloads + 1] = key
            end
        end
        spec.frames[f] = frame
    end
    for f = 35, 34 + 60 do spec.frames[f] = { loads = {}, unloads = {} } end -- 把掃描佇列跑完
    return spec
end

-- ===== 一次執行 =====
local function resetRun(spec, opts)
    S = {
        effects = {}, patchPrints = {}, upstreamPrints = {}, java = {}, dispatch = {}, calls = {},
        frame = 0, clock = 0, rng = 4242, nextItemId = 1000000, nextLoadId = 7, nextSquareId = 0, nextChunkId = 0,
        squarePool = { head = 1, tail = 0 }, chunkPool = { head = 1, tail = 0 }, softReset = false,
        mods = {}, modules = {}, counting = opts.counting, fileOverride = opts.fileOverride,
        save = { containers = {}, overlay = {}, ground = {} }, coverage = { staleReuse = 0, immediate = 0 },
        modData = {},
    }
    for _, id in ipairs(opts.mods or { "VanillaFoodsExpanded" }) do S.mods[id] = true; S.mods["\\" .. id] = true end
    for cid, data in pairs(spec.containers) do
        local items = {}
        for i, it in ipairs(data.items) do items[i] = { id = it.id, type = it.type, age = it.age } end
        S.save.containers[cid] = { explored = data.explored, items = items }
    end
    for key, tile in pairs(spec.tiles) do
        local ground = {}
        for i, it in ipairs(tile.ground) do ground[i] = { id = it.id, type = it.type, age = it.age, uses = it.uses, ticks = it.ticks } end
        S.save.ground[key] = ground
    end
    local restart = {}
    for key, r in pairs(spec.restart or {}) do restart[key] = { x = r.x, y = r.y, z = r.z, equipped = r.equipped, unequipped = r.unequipped } end
    if next(restart) then S.modData.VFX_Birthday = { restart = restart } end
    for _, def in ipairs(spec.defs) do
        def.randomized = false
        def.roomDefs[1].counts = {}
    end
    for k in pairs(MAP) do MAP[k] = nil end
    Events = setmetatable({}, { __index = function(t, k) local e = newEvent(k); rawset(t, k, e); return e end })
    VFX = {
        -- ReplaceItemTable／StatItemTable／TemperatureItemTable 由上游 aging 檔載入時自己定義
        DistributionReplacements = {
            ["Base.CannedSoup"] = { items = { ["VFX.SoupA"] = 3, ["VFX.SoupB"] = 1 } },
            ["VFX.YeastStarter"] = { items = { ["VFX.YeastA"] = 1, ["VFX.YeastB"] = 2 } },
            ["Base.Bread"] = { items = { ["VFX.Sourdough"] = 1 }, minQty = 1 },
        },
    }
    SandboxVars = { MinidoracatServerPatchFor42 = opts.sandbox or {} }
    MSP_ChunkSquareDispatch, MSP_VfeLoadSlim = nil, nil
    ISDropWorldItemAction = { complete = function() return true end }
    ISTransferAction = { transferItem = function(_, _, item) return item end }
end

-- opts.order：「patchFirst」＝Mods= 本 MOD 在 VFE 之前（預設），「vfeFirst」＝VFE 在前（2026-10-24 正式服的順序）
local function boot(mode, opts)
    function require(name)
        if name == "vfx_distribution" then return true end
        if name == "TimedActions/ISDropWorldItemAction" or name == "TimedActions/ISTransferAction" then return true end
        if name == "Patches/MSP_ChunkSquareDispatch" then
            if S.modules[name] == nil then S.modules[name] = loadPatch(PATCH.dispatch) end
            return S.modules[name]
        end
        error("unexpected require " .. name)
    end
    -- shared/：依 Mods= 逐 MOD；本 MOD 的檔照檔名排序（patches/msp_chunksquaredispatch.lua 先於 patches/vanillafoodsexpanded/…）
    local function vfeShared() if S.mods.VanillaFoodsExpanded then dofile(UP.birthday) end end
    local function patchShared()
        if mode == "patched" then
            require("Patches/MSP_ChunkSquareDispatch")
            loadPatch(PATCH.vfe)
        end
    end
    if opts.order == "vfeFirst" then vfeShared(); patchShared() else patchShared(); vfeShared() end
    if opts.beforeServer then opts.beforeServer() end
    -- server/：上游兩檔（vfx_agingmanager.lua 先於 vfx_storydistribution.lua）
    if S.mods.VanillaFoodsExpanded then
        dofile(UP.aging)
        dofile(UP.story)
    end
    if opts.afterServer then opts.afterServer() end
    trigger(Events.OnGameBoot)
    trigger(Events.OnInitGlobalModData, false)
end

local function upvalue(fn, name)
    local i = 1
    while true do
        local n, v = debug.getupvalue(fn, i)
        if not n then return nil end
        if n == name then return v end
        i = i + 1
    end
end
local function sourceOf(fn) return debug.getinfo(fn, "S").source:gsub("^@", "") end

-- 從 LoadGridsquare 清單找回上游函式（補丁執行時在合併回呼的 upvalue 裡）
local function upstreamFns()
    local fns = {}
    for _, fn in ipairs(Events.LoadGridsquare.list) do
        local src = sourceOf(fn)
        if src == UP.aging then fns.agingLoad = fn
        elseif src == UP.story then fns.storyLoad = fn
        elseif src == UP.birthday then fns.birthdayLoad = fn
        elseif src == PATCH.vfe then
            fns.agingLoad = fns.agingLoad or upvalue(fn, "aging")
            fns.storyLoad = fns.storyLoad or upvalue(fn, "story")
            fns.birthdayLoad = fns.birthdayLoad or upvalue(fn, "birthday")
            fns.patch = fn
        end
    end
    if fns.agingLoad then
        fns.scan = upvalue(fns.agingLoad, "scan")
        fns.scanQueue = upvalue(upvalue(fns.agingLoad, "updateEventHandlers"), "processSquareScanQueue")
        fns.scanSquare = upvalue(fns.agingLoad, "scanGridSquare")
        fns.replacements = upvalue(VFX.RebuildAgingReplacementIndex, "replacements")
    end
    if fns.storyLoad then
        fns.storyChunk = upvalue(fns.storyLoad, "onLoadChunk")
        fns.prune = upvalue(fns.storyChunk, "pruneBuilding")
    end
    if fns.patch then
        fns.chunkDriver = upvalue(upvalue(upvalue(fns.patch, "callStory"), "chunkAdd"), "chunkDriver")
        fns.scanDriver = upvalue(upvalue(upvalue(fns.patch, "callAging"), "tickAdd"), "scanDriver")
    end
    return fns
end

-- 物件池（FIFO，IsoGridSquare.isoGridSquareCache 是 poll／add 的佇列，IsoGridSquare.java:334、:4272-4300）
local function poolPush(pool, obj)
    pool.tail = pool.tail + 1
    pool[pool.tail] = obj
end
local function poolPop(pool)
    if pool.head > pool.tail then return nil end
    local obj = pool[pool.head]
    pool[pool.head] = nil
    pool.head = pool.head + 1
    return obj
end
local function popSquare()
    local sq = poolPop(S.squarePool)
    if sq then return sq end
    S.nextSquareId = S.nextSquareId + 1
    return setmetatable({ id = S.nextSquareId }, Square)
end
local function popChunk()
    local c = poolPop(S.chunkPool)
    if c then return c end
    S.nextChunkId = S.nextChunkId + 1
    return setmetatable({ id = S.nextChunkId }, Chunk)
end

local function buildSquare(spec, sq, chunk, x, y, z)
    local key = x .. ":" .. y .. ":" .. z
    local tile = spec.tiles[key]
    sq.x, sq.y, sq.z, sq.chunk, sq.key = x, y, z, chunk, key
    sq.room = tile and tile.room or nil
    sq.objects, sq.worldObjects = {}, {}
    if not tile then return end
    if tile.floor then sq.objects[#sq.objects + 1] = setmetatable({ containers = {}, square = sq }, Obj) end
    for _, crate in ipairs(tile.crates) do
        local obj = setmetatable({ containers = {}, square = sq }, Obj)
        for i, cid in ipairs(crate) do
            local data = S.save.containers[cid]
            local c = setmetatable({ id = cid, explored = data.explored, items = {}, parent = obj, class = "ItemContainer" },
                Container)
            for k, it in ipairs(data.items) do
                local item = newItem(it.type, it.id, it.age, it.modData and { VFX_AgingReplaceTracked = it.modData })
                item.container = c
                c.items[k] = item
            end
            obj.containers[i] = c
        end
        sq.objects[#sq.objects + 1] = obj
    end
    for _, it in ipairs(S.save.ground[key]) do
        local item = newItem(it.type, it.id, it.age)
        item.uses, item.ticks = it.uses, it.ticks
        local obj = setmetatable({ containers = {}, square = sq, item = item }, Obj)
        item.worldItem = obj
        sq.objects[#sq.objects + 1] = obj
        sq.worldObjects[#sq.worldObjects + 1] = obj
    end
end

local function saveSquare(sq)
    for _, obj in ipairs(sq.objects) do
        for _, c in ipairs(obj.containers) do
            local items = {}
            for i, item in ipairs(c.items) do
                local marker = item.modData and item.modData.VFX_AgingReplaceTracked
                items[i] = { id = item.id, type = item.type, age = item.age, modData = marker }
            end
            S.save.containers[c.id] = { explored = c.explored, items = items }
        end
    end
    local ground = {}
    for i, obj in ipairs(sq.worldObjects) do
        local item = obj.item
        ground[i] = { id = item.id, type = item.type, age = item.age, uses = item.uses, ticks = item.ticks }
    end
    S.save.ground[sq.key] = ground
end

local function engineAdd(c, type)
    local item = newItem(type, nil, type == "VFX.YeastStarterFermenting" and ZombRand(12) or 0)
    item.container = c
    c.items[#c.items + 1] = item
    log(string.format("fill c%d %s#%d", c.id, item.type, item.id))
end

local function forEachSquare(chunk, fn)
    for z = chunk.minLevel, chunk.maxLevel do
        for lx = 0, 7 do
            for ly = 0, 7 do
                local sq = chunk.squares[z][lx * 8 + ly]
                if sq then fn(sq) end
            end
        end
    end
end

-- randomizeBuildingsEtc：附近（±1 格）完整載入、還沒跑過故事的建築；安全屋故事直接填容器（不觸發 OnFillContainer）
local function randomize(spec, chunk)
    local ax, ay = chunk.wx * 8 - 1, chunk.wy * 8 - 1
    for _, def in ipairs(spec.defs) do
        if not def.randomized and def.x <= ax + 9 and def.x2 >= ax and def.y <= ay + 9 and def.y2 >= ay
            and Def.isFullyStreamedIn(def) then
            def.randomized = true
            if def.safehouse then
                for _, tile in ipairs(def.tiles) do
                    local sq = serverSquare(tile.x, tile.y, tile.z)
                    for _, obj in ipairs(sq and sq.objects or {}) do
                        for _, c in ipairs(obj.containers) do
                            if not c.explored then
                                c.explored = true
                                for _ = 1, 1 + ZombRand(2) do engineAdd(c, STORY_FILL[ZombRand(#STORY_FILL) + 1]) end
                            end
                        end
                    end
                end
                local counts = def.roomDefs[1].counts
                counts.SafehouseFood = (counts.SafehouseFood or 0) + 1
            end
        end
    end
end

-- loadGridSquareIfNeeded：每格第一次載入時，物件第一個未探索容器照一般戰利品表填
local function fillChunk(chunk)
    forEachSquare(chunk, function(sq)
        if #sq.objects == 0 or S.save.overlay[sq.key] then return end
        for _, obj in ipairs(sq.objects) do
            local c = obj.containers[1]
            if not obj.item and c and not c.explored then
                for _ = 1, ZombRand(3) do engineAdd(c, FILL[ZombRand(#FILL) + 1]) end
                trigger(Events.OnFillContainer, "room", "crate", c)
                c.explored = true
                if sq.room and ZombRand(6) == 0 then
                    local counts = sq.room.building.def.roomDefs[1].counts
                    counts.SafehouseFridge = (counts.SafehouseFridge or 0) + 1
                end
            end
        end
        S.save.overlay[sq.key] = true
    end)
end

local function loadCell(spec, load, fns)
    local cx, cy = load.key:match("^(%-?%d+):(%-?%d+)$")
    cx, cy = tonumber(cx), tonumber(cy)
    local cell = { loaded = false, chunks = {} }
    MAP[load.key] = cell
    for px = 0, 7 do
        for py = 0, 7 do
            local pos = px * 8 + py
            local wx, wy = cx * 8 + px, cy * 8 + py
            if not spec.invalid[wx .. ":" .. wy] and not (load.fails and load.fails[pos])
                and not (load.only and not load.only(pos)) then
                local chunk = popChunk()
                chunk.wx, chunk.wy, chunk.loadId = wx, wy, S.nextLoadId
                S.nextLoadId = (S.nextLoadId + 1) % 32767
                chunk.minLevel, chunk.maxLevel, chunk.squares = 0, 0, { [0] = {} }
                for lx = 0, 7 do
                    for ly = 0, 7 do
                        local x, y = wx * 8 + lx, wy * 8 + ly
                        local sq = popSquare()
                        buildSquare(spec, sq, chunk, x, y, 0) -- z=0 的格子一定存在（ServerChunkLoader.java:323-331）
                        chunk.squares[0][lx * 8 + ly] = sq
                        if spec.tiles[x .. ":" .. y .. ":1"] then
                            chunk.maxLevel = 1
                            chunk.squares[1] = chunk.squares[1] or {}
                            local up = popSquare()
                            buildSquare(spec, up, chunk, x, y, 1)
                            chunk.squares[1][lx * 8 + ly] = up
                        end
                    end
                end
                cell.chunks[pos] = chunk
            end
        end
    end
    -- RecalcAll2
    cell.loaded = true
    for px = 0, 7 do
        for py = 0, 7 do
            local chunk = cell.chunks[px * 8 + py]
            if chunk then
                S.phase = "lgs"
                forEachSquare(chunk, function(sq)
                    if #sq.objects > 0 then
                        if S.counting then S.lgsEvents = (S.lgsEvents or 0) + 1 end
                        local scan = fns.scan
                        local pending = scan and scan.pending[sq]
                        if pending and #sq.worldObjects == 0 then
                            local any = false
                            for _, obj in ipairs(sq.objects) do if #obj.containers > 0 then any = true end end
                            if not any then S.coverage.staleReuse = S.coverage.staleReuse + 1 end
                        end
                        trigger(Events.LoadGridsquare, sq)
                    end
                end)
                S.phase = "engine"
                randomize(spec, chunk)
                fillChunk(chunk)
                S.phase = "chunk"
                if S.counting then S.chunkEvents = (S.chunkEvents or 0) + 1 end
                trigger(Events.LoadChunk, chunk)
                S.phase = nil
            end
        end
    end
end

local function unloadCell(key)
    local cell = MAP[key]
    if not cell then return end
    cell.loaded = false
    for pos = 0, 63 do
        local chunk = cell.chunks[pos]
        if chunk then
            forEachSquare(chunk, function(sq)
                saveSquare(sq)
                sq.objects, sq.worldObjects, sq.chunk, sq.room = nil, nil, nil, nil
                poolPush(S.squarePool, sq)
            end)
            chunk.loadId, chunk.squares = -1, nil
            poolPush(S.chunkPool, chunk)
        end
    end
    MAP[key] = nil
end

-- ===== 狀態快照 =====
local function storyState(fns)
    if not fns.storyLoad then return "" end
    local pb = upvalue(fns.storyLoad, "pendingBuildings")
    local pc = upvalue(fns.storyLoad, "pendingContainers")
    local count = upvalue(fns.storyLoad, "pendingCount")
    local chunkLoads = upvalue(upvalue(fns.storyLoad, "squareLoad"), "chunkLoads")
    local byCell = upvalue(upvalue(fns.storyLoad, "indexBuilding"), "buildingsByCell")
    local defs = {}
    for def in pairs(pb) do defs[#defs + 1] = def end
    table.sort(defs, function(a, b) return a.id < b.id end)
    local out = { "pending=" .. count }
    for _, def in ipairs(defs) do
        local g = pb[def]
        local parts = { string.format("d%d fc=%s ug=%d cells=%s", def.id, tostring(g.firstCheck), g.ungrouped,
            g.cells and table.concat(g.cells, ",") or "-") }
        for _, st in ipairs(g) do
            local b = st.batch
            parts[#parts + 1] = string.format("c%d@s%d/%s/%s", st.container.id, st.square.id,
                b and ("k" .. b.chunk.id .. ":" .. b.id .. ":" .. b.count .. ":" .. tostring(g.chunks[b])) or "-",
                tostring(st.normalFill))
        end
        out[#out + 1] = table.concat(parts, " ")
    end
    local n = 0
    for _ in pairs(pc) do n = n + 1 end
    out[#out + 1] = "containers=" .. n
    local loads = {}
    for chunk, batch in pairs(chunkLoads) do loads[#loads + 1] = "k" .. chunk.id .. ":" .. batch.id .. ":" .. batch.count end
    table.sort(loads)
    out[#out + 1] = "loads=" .. table.concat(loads, ",")
    local cells = {}
    for key, bucket in pairs(byCell) do cells[#cells + 1] = key .. "=" .. bucket.count end
    table.sort(cells)
    out[#out + 1] = "cells=" .. table.concat(cells, ",")
    return table.concat(out, "\n")
end

local function agingState(fns, withSkipped)
    if not fns.scan then return "" end
    local scan = fns.scan
    local out = { string.format("head=%d tail=%d pending=%d active=%s", scan.head, scan.tail, scan.pendingCount,
        tostring(scan.eventActive)) }
    if scan.session then
        out[#out + 1] = string.format("session scanned=%d skipped=%d immediate=%d", scan.session.scanned,
            scan.session.skipped, scan.session.immediate)
        if scan.session.immediate > 0 then S.coverage.immediate = S.coverage.immediate + 1 end
    end
    if withSkipped then out[#out + 1] = "skippedEmpty=" .. scan.skippedEmptyCount end
    for i = scan.head, scan.tail do
        local e = scan.queue[i]
        out[#out + 1] = e and string.format("%s %d,%d,%d k%s:%s", e.square and ("s" .. e.square.id) or "x", e.x, e.y,
            e.z, e.chunk and e.chunk.id or "-", tostring(e.loadID)) or "nil"
    end
    local pending = {}
    for sq, e in pairs(scan.pending) do pending[#pending + 1] = "s" .. sq.id .. "=" .. e.x .. "," .. e.y end
    table.sort(pending)
    out[#out + 1] = "pendingKeys=" .. table.concat(pending, ",")
    local r = fns.replacements
    local keys = {}
    for k in pairs(r.hourly) do keys[#keys + 1] = tostring(k) end
    table.sort(keys)
    out[#out + 1] = string.format("replace hourly=%d daily=%d keys=%s", r.hourlyCount, r.dailyCount, table.concat(keys, ","))
    return table.concat(out, "\n")
end

local function callbackState(fns)
    local out = {}
    for _, name in ipairs({ "OnTick", "LoadChunk", "EveryHours", "EveryDays", "EveryTenMinutes", "ReuseGridsquare" }) do
        local names = {}
        for _, fn in ipairs(Events[name].list) do
            if fn == fns.storyChunk or (fns.chunkDriver and fn == fns.chunkDriver) then names[#names + 1] = "story.onLoadChunk"
            elseif fn == fns.scanQueue or (fns.scanDriver and fn == fns.scanDriver) then names[#names + 1] = "aging.scanQueue"
            else names[#names + 1] = sourceOf(fn):match("[^/]+$") .. ":" .. debug.getinfo(fn, "S").linedefined end
        end
        out[#out + 1] = name .. "=" .. table.concat(names, ",")
    end
    return table.concat(out, "\n")
end

local function saveState()
    local ids = {}
    for cid in pairs(S.save.containers) do ids[#ids + 1] = cid end
    table.sort(ids)
    local out = {}
    for _, cid in ipairs(ids) do
        local data = S.save.containers[cid]
        local items = {}
        for i, it in ipairs(data.items) do items[i] = it.type .. "#" .. it.id .. ":" .. it.age .. ":" .. tostring(it.modData) end
        out[#out + 1] = cid .. (data.explored and "E " or "U ") .. table.concat(items, ",")
    end
    local keys = {}
    for key, ground in pairs(S.save.ground) do if #ground > 0 then keys[#keys + 1] = key end end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local items = {}
        for i, it in ipairs(S.save.ground[key]) do
            items[i] = it.type .. "#" .. it.id .. ":" .. tostring(it.uses) .. ":" .. tostring(it.ticks)
        end
        out[#out + 1] = "g" .. key .. " " .. table.concat(items, ",")
    end
    local saved = S.modData.VFX_Birthday and S.modData.VFX_Birthday.restart or {}
    local restart = {}
    for key, r in pairs(saved) do restart[#restart + 1] = key .. "@" .. r.x .. "," .. r.y end
    table.sort(restart)
    out[#out + 1] = "restart=" .. table.concat(restart, ",")
    return table.concat(out, "\n")
end

local function run(spec, mode, opts)
    opts = opts or {}
    resetRun(spec, opts)
    boot(mode, opts)
    local fns = upstreamFns()
    if opts.hook then
        local names = {}
        for _, key in ipairs({ "agingLoad", "storyLoad", "storyChunk", "prune", "scanQueue", "scanSquare", "birthdayLoad" }) do
            if fns[key] then names[fns[key]] = key end
        end
        S.trace = {}
        debug.sethook(function()
            local name = names[debug.getinfo(2, "f").func]
            if name then
                S.calls[name] = (S.calls[name] or 0) + 1
                if opts.trace and (name == "agingLoad" or name == "storyLoad" or name == "birthdayLoad") then
                    local _, sq = debug.getlocal(2, 1)
                    S.trace[#S.trace + 1] = name .. "@" .. tostring(type(sq) == "table" and sq.id)
                end
            end
        end, "c")
    end
    local snaps = {}
    local t0 = os.clock()
    for f, frame in ipairs(spec.frames) do
        S.frame = f
        S.softReset = frame.soft == true
        if opts.debugAt then opts.debugAt(f) end
        for _, load in ipairs(frame.loads) do loadCell(spec, load, fns) end
        S.phase = "tick"
        trigger(Events.OnTick)
        S.phase = nil
        for _, key in ipairs(frame.unloads) do unloadCell(key) end
        snaps[f] = storyState(fns) .. "\n" .. agingState(fns, opts.withSkipped) .. "\n" .. callbackState(fns)
    end
    local elapsed = os.clock() - t0
    debug.sethook()
    local keys = {}
    for key in pairs(MAP) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do unloadCell(key) end
    return { snaps = snaps, effects = S.effects, prints = S.upstreamPrints, patchPrints = S.patchPrints,
        save = saveState(), fns = fns, S = S, elapsed = elapsed,
        stats = MSP_VfeLoadSlim and MSP_VfeLoadSlim.stats }
end

local function firstDiff(a, b)
    for f = 1, math.max(#a.snaps, #b.snaps) do
        if a.snaps[f] ~= b.snaps[f] then
            local la, lb = {}, {}
            for line in (a.snaps[f] or ""):gmatch("[^\n]+") do la[#la + 1] = line end
            for line in (b.snaps[f] or ""):gmatch("[^\n]+") do lb[#lb + 1] = line end
            for i = 1, math.max(#la, #lb) do
                if la[i] ~= lb[i] then
                    return string.format("幀 %d 狀態不同：%s ≠ %s", f, tostring(la[i]):sub(1, 120), tostring(lb[i]):sub(1, 120))
                end
            end
        end
    end
    for i = 1, math.max(#a.effects, #b.effects) do
        if a.effects[i] ~= b.effects[i] then
            return string.format("副作用第 %d 項不同：%s ≠ %s", i, tostring(a.effects[i]), tostring(b.effects[i]))
        end
    end
    for i = 1, math.max(#a.prints, #b.prints) do
        if a.prints[i] ~= b.prints[i] then return "上游 log 第 " .. i .. " 行不同" end
    end
    if a.save ~= b.save then return "存檔內容不同" end
    return nil
end

local function differential(spec, opts)
    opts = opts or {}
    local base = run(spec, "upstream", opts)
    local other = run(spec, opts.otherMode or "patched", opts)
    return firstDiff(base, other), base, other
end

-- ===== 0. 上游版本 =====
rawPrint("情境零：上游檔與補丁核對的版本相同")
local patchSource = readFile(PATCH.vfe)
local function patchConst(name)
    local block = patchSource:match("local " .. name .. " = (%b{})")
    return tonumber(block:match("lines = (%d+)")), tonumber(block:match("hash = (%d+)"))
end
local agingLines, agingHash = fileHash(readFile(UP.aging))
local storyLines, storyHash = fileHash(readFile(UP.story))
local birthdayLines, birthdayHash = fileHash(readFile(UP.birthday))
local pal, pah = patchConst("AGING")
local psl, psh = patchConst("STORY")
local pbl, pbh = patchConst("BIRTHDAY")
local upstreamCurrent = agingLines == pal and agingHash == pah and storyLines == psl and storyHash == psh
    and birthdayLines == pbl and birthdayHash == pbh
check(string.format("本機上游＝補丁核對版本（aging %d 行 %d、story %d 行 %d、birthday %d 行 %d；不同就是上游更新了，補丁會 NOT installed"
    .. "或把 birthday 留給引擎，照 recheck 重核後更新常數）", agingLines, agingHash, storyLines, storyHash, birthdayLines,
    birthdayHash), upstreamCurrent)

-- 合併回呼呼叫上游的順序：補丁的呼叫序列必須是上游原樣呼叫序列的子序列（上游每格依註冊順序呼叫每一個）
local function orderKept(base, other)
    local j = 1
    for _, e in ipairs(other) do
        while j <= #base and base[j] ~= e do j = j + 1 end
        if j > #base then return false, e end
        j = j + 1
    end
    return true
end

-- ===== 1. 隨機世界差分 =====
local SEEDS = ARGS["--quick"] and 3 or 12
local function runDifferential(seeds, opts)
    local first
    local agg = { staleReuse = 0, immediate = 0, replaced = 0, candles = 0, chunks = 0, chunkCalls = 0, squares = 0, birthday = 0,
        aging = 0, story = 0 }
    for seed = 1, seeds do
        local spec = randomSpec(seed)
        local problem, base, other = differential(spec, opts)
        if problem and not first then first = "seed " .. seed .. "：" .. problem end
        agg.staleReuse = agg.staleReuse + other.S.coverage.staleReuse
        agg.immediate = agg.immediate + base.S.coverage.immediate
        for _, e in ipairs(base.effects) do
            if e:find("^send") then agg.replaced = agg.replaced + 1 end
            if e:find("^swap") or e:find("^removeWorld") then agg.candles = agg.candles + 1 end
        end
        if other.stats then
            for k in pairs(agg) do if other.stats[k] then agg[k] = agg[k] + other.stats[k] end end
        end
    end
    return first, agg
end

if upstreamCurrent then
    rawPrint("情境一：隨機世界差分（上游原樣 vs 補丁；cell 同幀連續載入、卸載後格子／chunk 物件重用、載入失敗的 chunk、軟重設、"
        .. "地上點著的生日蠟燭）")
    local first, agg = runDifferential(SEEDS)
    check(string.format("情境有效：故事替換 %d 次、掃描佇列滿而立即掃描的幀 %d 個、殘留佇列項目的格子物件被重用到空格 %d 次、"
        .. "birthday 換掉或移除地上蠟燭 %d 次", agg.replaced, agg.immediate, agg.staleReuse, agg.candles),
        agg.replaced > 0 and agg.immediate > 0 and agg.staleReuse > 0 and agg.candles > 0)
    check(string.format("Mods= 本 MOD 在 VFE 之前：%d 個世界逐幀等價（三上游內部狀態、引擎回呼清單、物品變動與亂數序列、上游 log、存檔）%s",
        SEEDS, first and ("；首個失敗 " .. first) or ""), first == nil)
    check(string.format("補丁確實少呼叫：格子 %d、交給 birthday %d、aging %d、story %d；story onLoadChunk 引擎觸發 %d、實際呼叫 %d",
        agg.squares, agg.birthday, agg.aging, agg.story, agg.chunks, agg.chunkCalls),
        agg.birthday > 0 and agg.birthday < agg.squares and agg.aging < agg.squares and agg.story < agg.squares
        and agg.chunkCalls < agg.chunks)
    local vfeFirst, aggV = runDifferential(math.max(2, SEEDS // 4), { order = "vfeFirst" })
    check(string.format("Mods= VFE 在前（birthday 留給引擎）：%d 個世界逐幀等價、birthday 沒經合併回呼（%d）%s", math.max(2, SEEDS // 4),
        aggV.birthday, vfeFirst and ("；首個失敗 " .. vfeFirst) or ""), vfeFirst == nil and aggV.birthday == 0)

    local traceSpec = randomSpec(7)
    local tb = run(traceSpec, "upstream", { hook = true, trace = true })
    local tp = run(traceSpec, "patched", { hook = true, trace = true })
    local kept, at = orderKept(tb.S.trace, tp.S.trace)
    check(string.format("呼叫順序：補丁的 %d 次上游呼叫照上游的 birthday → aging → story 順序（上游 %d 次）%s", #tp.S.trace, #tb.S.trace,
        kept and "" or ("；第一個亂序 " .. tostring(at))), kept and #tp.S.trace > 0)

    rawPrint("情境二：debug 旗標（AgingQueueDebug 全程開、AgingSkipDebug 中途開關）上游 log 與計數相同")
    local spec = randomSpec(101)
    local problem, base = differential(spec, { withSkipped = true, debugAt = function(f)
        VFX.AgingQueueDebug = true
        VFX.AgingSkipDebug = f >= 5 and f < 15
    end })
    check("debug 旗標：逐幀等價（含 skippedEmptyCount）、上游 log 相同" .. (problem and ("；" .. problem) or ""),
        problem == nil and #base.prints > 100)

    rawPrint("情境三：開關、回退、軟依賴")
    problem, base = differential(randomSpec(102), { sandbox = { SlimVfeLoad = false } })
    local off = run(randomSpec(102), "patched", { sandbox = { SlimVfeLoad = false }, hook = true, counting = true })
    check("沙盒關閉：逐幀等價、印一行 disabled、每格三個上游回呼都照呼叫" .. (problem and ("；" .. problem) or ""),
        problem == nil and #off.patchPrints == 1 and off.patchPrints[1]:find("disabled by sandbox option", 1, true) ~= nil
        and off.S.calls.agingLoad == off.S.lgsEvents and off.S.calls.storyLoad == off.S.lgsEvents
        and off.S.calls.birthdayLoad == off.S.lgsEvents)

    local changed = readFile(UP.aging):gsub("local max_queued_squares = 512", "local max_queued_squares = 1024")
    local override = { ["media/lua/server/vfx_agingmanager.lua"] = changed }
    problem = differential(randomSpec(103), { fileOverride = override })
    local mism = run(randomSpec(103), "patched", { fileOverride = override })
    check("上游檔與核對版本不同（同一行改數字）：印一行 NOT installed、不攔任何註冊、逐幀等價" .. (problem and ("；" .. problem) or ""),
        problem == nil and #mism.patchPrints == 1 and mism.patchPrints[1]:find("NOT installed", 1, true) ~= nil
        and #Events.LoadGridsquare.list == 3 and MSP_ChunkSquareDispatch.restore == nil)

    local candleText = readFile(UP.birthday):gsub("Birthday.litType = \"VFX.BirthdayCandleLit\"",
        "Birthday.litType = \"VFX.BirthdayCandleLit\" ")
    local candleOverride = { ["media/lua/shared/vfx_birthday.lua"] = candleText }
    problem = differential(randomSpec(106), { fileOverride = candleOverride })
    local bmism = run(randomSpec(106), "patched", { fileOverride = candleOverride })
    check("只有 vfx_birthday.lua 與核對版本不同：birthday 留給引擎、aging／story 照樣合併、逐幀等價" .. (problem and ("；" .. problem) or ""),
        problem == nil and #bmism.patchPrints == 1 and bmism.patchPrints[1]:find("vfx_birthday.lua differs", 1, true) ~= nil
        and #Events.LoadGridsquare.list == 2 and sourceOf(Events.LoadGridsquare.list[1]) == UP.birthday)

    local absent = run(randomSpec(104), "patched", { mods = {} })
    check("上游沒裝：零註冊、零 log、攔截器沒裝", #absent.patchPrints == 0 and #Events.LoadGridsquare.list == 0
        and #Events.OnGameBoot.list == 0 and (MSP_ChunkSquareDispatch.restore == nil))

    local on = run(randomSpec(105), "patched")
    check("正常安裝（本 MOD 在 VFE 之前）：印一行 installed、Add 已換回引擎原函式、LoadGridsquare 只剩合併回呼",
        #on.patchPrints == 1 and on.patchPrints[1]:find("load slim installed", 1, true) ~= nil
        and on.patchPrints[1]:find("birthday merged", 1, true) ~= nil
        and Events.LoadGridsquare.Add == Events.LoadGridsquare.engineAdd and #Events.LoadGridsquare.list == 1
        and sourceOf(Events.LoadGridsquare.list[1]) == PATCH.vfe)
    local late = run(randomSpec(105), "patched", { order = "vfeFirst" })
    check("VFE 在前：印一行 installed 並註明 birthday 留給引擎、LoadGridsquare 是 birthday＋合併回呼",
        #late.patchPrints == 1 and late.patchPrints[1]:find("load slim installed", 1, true) ~= nil
        and late.patchPrints[1]:find("listed before this mod", 1, true) ~= nil and #Events.LoadGridsquare.list == 2
        and sourceOf(Events.LoadGridsquare.list[1]) == UP.birthday and sourceOf(Events.LoadGridsquare.list[2]) == PATCH.vfe)

    -- 同一攔截器上，shared 載入時的 claim（VFE）與 OnGameBoot 內的 claim（damnlib／rSemiTruck 的做法）並存：
    -- 後者的上游在 OnInitGlobalModData 內才註冊，還原要排在它之後
    local lateFile = "fake/late_upstream.lua"
    local lateSeen, lateFn = 0, nil
    run({ tiles = {}, containers = {}, defs = {}, invalid = {}, frames = {}, cells = {} }, "patched", {
        afterServer = function()
            local f = assert(load("return function() Events.OnInitGlobalModData.Add(function()"
                .. " Events.LoadGridsquare.Add(function(square) end) end) end", "@" .. lateFile))()
            f()
            Events.OnGameBoot.Add(function()
                MSP_ChunkSquareDispatch.claim(lateFile, function(fn) lateSeen = lateSeen + 1; lateFn = fn; return true end,
                    function() end)
            end)
        end,
    })
    check("shared 載入時已 claim，OnGameBoot 內再 claim：OnInitGlobalModData 內才註冊的上游照樣被攔、Add 最後換回引擎原函式",
        lateSeen == 1 and lateFn ~= nil and Events.LoadGridsquare.Add == Events.LoadGridsquare.engineAdd
        and #Events.LoadGridsquare.list == 1)

    -- 4. 固定情境：chunk 載入失敗讓「上一個 chunk 的序號」比這一個小，卻屬於不同的 cell 載入
    rawPrint("情境四：固定情境（chunk 載入失敗造成的序號接續）")
    local function fixedSpec(defs, frames)
        local spec = baseSpec()
        spec.defs = defs
        buildTiles(spec, function(a) return a or 0.5 end) -- 只有地板：R() 恆 0.5、R(a, b) 恆 a
        for _, def in ipairs(defs) do
            for i, tile in ipairs(def.tiles) do
                if i % 3 == 1 then
                    spec.nextCid = spec.nextCid + 1
                    spec.containers[spec.nextCid] = { explored = false, items = {} }
                    tile.crates[1] = { spec.nextCid }
                end
            end
        end
        for _ = 1, 20 do frames[#frames + 1] = { loads = {}, unloads = {} } end
        spec.frames = frames
        return spec
    end
    local function upto(n) return function(pos) return pos <= n end end
    local function from(n) return function(pos) return pos >= n end end
    local A, B, C = cellKeyOf(CX0, CY0), cellKeyOf(CX0 + 1, CY0), cellKeyOf(CX0, CY0 + 1)
    -- 建築跨 A 的 chunk (7,2) 與 B 的 chunk (0,2)。幀 1 載入 A：它等 B。幀 2 先載入 C 的 chunk 0（序號 0），
    -- 再載入 B 的序號 ≥1：B 一開頭就全部可見，建築在 B 的第一個 chunk（序號 1）完成，雖然序號比上一個 chunk 大
    local x0, y0 = CX0 * 64 + 60, CY0 * 64 + 20
    local cellCase = fixedSpec({ newDef(1, x0, y0, x0 + 6, y0 + 3, { safehouse = true }) }, {
        { loads = { { key = A } }, unloads = {} },
        { loads = { { key = C, only = upto(0) }, { key = B, only = from(1) } }, unloads = {} },
    })
    problem = differential(cellCase)
    check("同幀換 cell 且序號接續：建築在第二個 cell 的第一個 chunk 完成，等價" .. (problem and ("；" .. problem) or ""),
        problem == nil)
    -- 建築跨 A 的 chunk (5,0)、(5,1)（序號 40、41）。幀 1 只載入序號 ≤40 後卸載；幀 2 只載入序號 ≥41：
    -- 第一個 chunk 要清掉上一輪留下的狀態
    local reload = fixedSpec({ newDef(1, CX0 * 64 + 42, CY0 * 64 + 5, CX0 * 64 + 45, CY0 * 64 + 10, { safehouse = true }) }, {
        { loads = { { key = A, only = upto(40) } }, unloads = { A } },
        { loads = { { key = A, only = from(41) } }, unloads = {} },
    })
    problem = differential(reload)
    check("同一 cell 卸載後下一幀重載、序號接續上一輪：等價" .. (problem and ("；" .. problem) or ""), problem == nil)
    MSP_FIXED = { cellCase = cellCase, reload = reload }
else
    rawPrint("上游已更新：只驗回退（補丁 NOT installed、上游原樣）")
    local problem = differential(randomSpec(1))
    local r = run(randomSpec(1), "patched")
    check("上游已更新：印一行 NOT installed、不攔任何註冊、逐幀等價" .. (problem and ("；" .. problem) or ""),
        problem == nil and #r.patchPrints == 1 and r.patchPrints[1]:find("NOT installed", 1, true) ~= nil)
end

-- ===== 5. 突變 =====
if ARGS["--mutants"] and upstreamCurrent then
    rawPrint("\n突變測試（每個突變都必須讓差分失敗）")
    local V = PATCH.vfe
    local MUTANTS = {
        { name = "chunk 回呼不看「新建了待處理建築」", edits = { { file = V,
            from = "if same and not newBuilding then return end", to = "if same then return end" } } },
        { name = "chunk 回呼不比對 cell", edits = { { file = V,
            from = "local same = cellX == lastCellX and cellY == lastCellY and frame", to = "local same = frame" } } },
        { name = "chunk 回呼不比對幀", edits = { { file = V,
            from = "and frame == lastFrame and pos > lastPos", to = "and pos > lastPos" } } },
        { name = "aging 不看近期交給過的格子（殘留佇列項目不清）", edits = { { file = V,
            from = "elseif recent[square] or previous[square] or (", to = "elseif (" } } },
        { name = "aging 換代太快（4 次）", edits = { { file = V,
            from = "local SCAN_CALLS = 512", to = "local SCAN_CALLS = 4" } } },
        { name = "aging 不看地上物品", edits = { { file = V,
            from = "if containers or ground then", to = "if containers then" } } },
        { name = "aging 不看 debug 旗標", edits = { { file = V,
            from = " or (VFX and (VFX.AgingSkipDebug or VFX.AgingQueueDebug))", to = "" } } },
        { name = "story 先於 aging", edits = { { file = V,
            from = "    if aging then\n        if not containers",
            to = "    if story and containers then callStory(square) end\n    if aging then\n        if not containers" },
            { file = V, from = "    end\n    if story and containers then callStory(square) end\nend",
            to = "    end\nend" } } },
        { name = "birthday 在 aging 之後", edits = { { file = V,
            from = "        if ground then callBirthday(square) end\n", to = "" },
            { file = V, from = "    if story and containers then callStory(square) end\nend",
            to = "    if ground then callBirthday(square) end\n    if story and containers then callStory(square) end\nend" } } },
        { name = "birthday 不看地上物品就略過（只在有容器時呼叫）", edits = { { file = V,
            from = "        if ground then callBirthday(square) end\n", to = "" },
            { file = V, from = "    if containers then listClear(found) end\n",
            to = "    if containers then listClear(found) end\n    if containers and birthday then callBirthday(square) end\n" } } },
        { name = "容器判斷改成只看第一個物件", edits = { { file = V,
            from = "local containers = not listIsEmpty(found)",
            to = "local containers = square:getObjects():get(0):getContainerCount() > 0" } } },
        { name = "攔截器還原不延到 OnGameBoot", edits = { { file = PATCH.dispatch,
            from = "    Events.OnGameBoot.Add(function()\n        Events.OnInitGlobalModData.Add(function()\n            M.restore()\n            for i = 1, #claims do claims[i].onDone(claims[i].matched) end\n        end)\n    end)",
            to = "    Events.OnInitGlobalModData.Add(function()\n        M.restore()\n        for i = 1, #claims do claims[i].onDone(claims[i].matched) end\n    end)" } } },
    }
    for _, mutant in ipairs(MUTANTS) do
        MUTATION = mutant
        local ok, killed, why = pcall(function()
            for _, key in ipairs({ "cellCase", "reload" }) do
                local problem = differential(MSP_FIXED[key])
                if problem then return true, key .. "：" .. problem end
            end
            local tb = run(randomSpec(7), "upstream", { hook = true, trace = true })
            local tp = run(randomSpec(7), "patched", { hook = true, trace = true })
            local kept, at = orderKept(tb.S.trace, tp.S.trace)
            if not kept then return true, "呼叫順序：" .. tostring(at) end
            local problem = differential(randomSpec(101), { withSkipped = true, debugAt = function(f)
                VFX.AgingQueueDebug = true
                VFX.AgingSkipDebug = f >= 5 and f < 15
            end })
            if problem then return true, "debug：" .. problem end
            local lateSeen = 0
            run({ tiles = {}, containers = {}, defs = {}, invalid = {}, frames = {}, cells = {} }, "patched", {
                afterServer = function()
                    local f = assert(load("return function() Events.OnInitGlobalModData.Add(function()"
                        .. " Events.LoadGridsquare.Add(function(square) end) end) end", "@fake/late_upstream.lua"))()
                    f()
                    Events.OnGameBoot.Add(function()
                        MSP_ChunkSquareDispatch.claim("fake/late_upstream.lua", function() lateSeen = lateSeen + 1; return true end,
                            function() end)
                    end)
                end,
            })
            if lateSeen ~= 1 then return true, "OnGameBoot 內的 claim 沒攔到" end
            local first = runDifferential(SEEDS)
            if first then return true, first end
            first = runDifferential(2, { order = "vfeFirst" })
            return first ~= nil, first and ("VFE 在前：" .. first)
        end)
        MUTATION = nil
        check("突變被抓到：" .. mutant.name .. (why and ("（" .. tostring(why):sub(1, 150) .. "）") or ""), ok and killed)
    end
end

-- ===== 6. 成本 =====
if ARGS["--bench"] and upstreamCurrent then
    rawPrint("\n成本（同一批世界：上游原樣 vs 補丁；Java 呼叫替身＝Lua 端呼叫的 Java 方法數，不含引擎自己的工作）")
    local tot = { upstream = { java = {}, dispatch = {}, calls = {}, lgs = 0, chunks = 0, cells = 0 },
        patched = { java = {}, dispatch = {}, calls = {}, lgs = 0, chunks = 0, cells = 0 } }
    local BENCH_SEEDS = 6
    for seed = 1, BENCH_SEEDS do
        local spec = randomSpec(seed)
        for _, mode in ipairs({ "upstream", "patched" }) do
            local r = run(spec, mode, { counting = true, hook = true })
            local t = tot[mode]
            for k, v in pairs(r.S.java) do t.java[k] = (t.java[k] or 0) + v end
            for k, v in pairs(r.S.dispatch) do t.dispatch[k] = (t.dispatch[k] or 0) + v end
            for k, v in pairs(r.S.calls) do t.calls[k] = (t.calls[k] or 0) + v end
            t.lgs = t.lgs + (r.S.lgsEvents or 0)
            t.chunks = t.chunks + (r.S.chunkEvents or 0)
            for _, frame in ipairs(spec.frames) do t.cells = t.cells + #frame.loads end
        end
    end
    local function line(label, u, p, per)
        rawPrint(string.format("  %-40s 上游 %10.2f → 補丁 %10.2f%s", label, u / per, p / per,
            u > 0 and string.format("（%.0f%%）", (p - u) / u * 100) or ""))
    end
    local U, P = tot.upstream, tot.patched
    rawPrint(string.format("  世界 %d 個、cell 載入 %d 次、chunk %d 個、有物件的格子（LoadGridsquare 觸發）%d 個",
        BENCH_SEEDS, U.cells, U.chunks, U.lgs))
    rawPrint("  每格（LoadGridsquare）：")
    line("引擎分派 VFE 回呼", U.dispatch.LoadGridsquare or 0, P.dispatch.LoadGridsquare or 0, U.lgs)
    line("birthday LoadGridsquare 執行", U.calls.birthdayLoad or 0, P.calls.birthdayLoad or 0, U.lgs)
    line("aging loadGridSquare 執行", U.calls.agingLoad or 0, P.calls.agingLoad or 0, U.lgs)
    line("story onLoadGridsquare 執行", U.calls.storyLoad or 0, P.calls.storyLoad or 0, U.lgs)
    line("Java 呼叫替身", U.java.lgs or 0, P.java.lgs or 0, U.lgs)
    rawPrint("  每 chunk（LoadChunk）：")
    line("story onLoadChunk 執行", U.calls.storyChunk or 0, P.calls.storyChunk or 0, U.chunks)
    line("pruneBuilding 執行（待處理建築數×呼叫數）", U.calls.prune or 0, P.calls.prune or 0, U.chunks)
    line("Java 呼叫替身", U.java.chunk or 0, P.java.chunk or 0, U.chunks)
    rawPrint("  每 cell 載入（含 OnTick 掃描）：")
    line("Java 呼叫替身（LoadGridsquare＋LoadChunk）", (U.java.lgs or 0) + (U.java.chunk or 0),
        (P.java.lgs or 0) + (P.java.chunk or 0), U.cells)
    line("processSquareScanQueue 執行", U.calls.scanQueue or 0, P.calls.scanQueue or 0, U.cells)
    line("scanGridSquare 執行（實際掃描，應相同）", U.calls.scanSquare or 0, P.calls.scanSquare or 0, U.cells)

    rawPrint("\n  離線耗時（標準 Lua 5.4，非 Kahlua；扣掉無 VFE 的假引擎底噪；每個世界 3 輪取最小值）")
    local times = { none = 0, upstream = 0, patched = 0 }
    for seed = 1, BENCH_SEEDS do
        local spec = randomSpec(seed)
        for mode, opts in pairs({ none = { mods = {} }, upstream = {}, patched = {} }) do
            local best = math.huge
            for _ = 1, 3 do
                collectgarbage("collect")
                best = math.min(best, run(spec, mode == "none" and "upstream" or mode, opts).elapsed)
            end
            times[mode] = times[mode] + best
        end
    end
    local u, p = times.upstream - times.none, times.patched - times.none
    rawPrint(string.format("  VFE 回呼耗時：上游 %.1f ms/cell → 補丁 %.1f ms/cell（%.0f%%）；假引擎底噪 %.1f ms/cell",
        u * 1000 / U.cells, p * 1000 / U.cells, (p - u) / u * 100, times.none * 1000 / U.cells))
end

rawPrint(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
