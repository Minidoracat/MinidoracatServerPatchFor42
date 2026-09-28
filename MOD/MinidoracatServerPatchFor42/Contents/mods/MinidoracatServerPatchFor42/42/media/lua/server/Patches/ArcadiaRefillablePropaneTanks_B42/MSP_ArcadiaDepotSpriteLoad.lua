--[[
MSP_ArcadiaDepotSpriteLoad — Arcadia Refillable Propane Tanks 每載入一格就逐物件查圖塊名

【上游】Arcadia Refillable Propane Tanks（Workshop 3786849936，mod id ArcadiaRefillablePropaneTanks_B42；
42.21.0 載入 `42/`）。upstream.json 有登記，Workshop 更新時 Action 會開 issue。

【缺陷】（行號為上游 42/media/lua/ 下的檔案）
server/ArcadiaRefillablePropane_Server.lua:328-343 把 `Server.onLoadGridSquare` 掛在 LoadGridsquare。引擎對每個
「有物件」的格子、每次載入都觸發一次（`IsoChunk.java:3803-3835`，新生成與讀檔都走這裡）。每格：`getObjects()`，
逐物件 `getSprite():getName()` 查 `PERSISTENT_ANCHOR_SPRITES`（shared 檔 :105-121、:190-192，共 19 個固定圖塊）；
每格另呼叫 `square:getVehicleContainer()`（Java 端掃周圍最多 4 個 chunk 的所有車做相交判定，
`IsoGridSquare.java:9872-9893`）找 Filibuster 丙烷車。玩家探索新區時幾乎全是非目標格子。

【修法】伺服器 `OnGameBoot`（全部 Lua 已載入、沙盒值已讀入，`GameServer.java:1469-1496`）時：
- 改用引擎的圖塊分派 `MapObjects.OnLoadWithSprite(錨點圖塊名, fn, 5)`。`IsoChunk.doLoadGridsquare` 在觸發
  LoadGridsquare 的同一個條件下、就在它前一行呼叫 `MapObjects.loadGridSquare(square)`（`IsoChunk.java:3829-3835`），
  由 Java 以 HashMap 查每個物件的圖塊名，只對已登記圖塊呼叫 Lua（`MapObjects.java:184-218`）。fn 仍先跑上游的
  `Depot.isPersistentAnchorObject(object)` 再呼叫上游 `Server.ensureDepot(object)`，判定與動作都是上游本身。
  Java 會跳過地上物品（`IsoWorldInventoryObject`）；專用伺服器上地上物品的圖塊只建空殼、不載材質、沒有名稱
  （`IsoWorldInventoryObject.java:95,381,418`），上游本來就不會把它們當補充站，結果相同。
- 移除上游的 LoadGridsquare 註冊（`Events.LoadGridsquare.Remove`，以函式身分移除，`Event.java:106-125`）。
- 上游那段找車只替 Filibuster 丙烷車做一次性初始化；`Depot.getFilibusterPropanePart` 第一步就要求 Filibuster MOD
  已啟用（shared 檔 :469-473、:540-541），沒啟用時每格那次找車都是白做。所以只在 Filibuster 未啟用時安裝；
  啟用時整個補丁不裝，上游原樣運作。
唯一的時點差異：`addTileObject` 這類「放上新圖塊物件」的 API 也會呼叫 `MapObjects.loadGridSquare`
（`IsoGridSquare.java:10658-10663`），新放上的補充站會在放上當下就初始化（上游要等下次載入或第一次使用，
`ensureDepot` 在每個使用動作開頭都會先呼叫）。初始存量的抽法與上游相同，只是早一點抽。

【為什麼不改上游】他人的 Workshop MOD，本服不重新發布；只改「哪些格子需要檢查」，建立補充站的條件與內容仍由上游決定。

【軟依賴】不 require 上游。`getActivatedMods()` 沒有該 MOD 就直接 return，不註冊任何事件。上游形狀不符時印一行
NOT installed，上游原樣運作。

【開關】沙盒 `MinidoracatServerPatchFor42.SlimArcadiaLoad`（預設開；關掉＝上游原樣，重啟生效）。

【上游更新時要重核】見 upstream.json 的 recheck。
]]

local PREFIX = "[MinidoracatServerPatchFor42][ArcadiaRefillablePropaneTanks_B42]"
local MOD_ID = "ArcadiaRefillablePropaneTanks_B42"
local PRIORITY = 5

local mods = getActivatedMods()
if not isServer() or not (mods:contains(MOD_ID) or mods:contains("\\" .. MOD_ID)) then return end

local function install()
    local options = SandboxVars and SandboxVars.MinidoracatServerPatchFor42
    if options and options.SlimArcadiaLoad == false then
        print(PREFIX .. " sprite load disabled by sandbox option; upstream unchanged")
        return
    end
    local Server, Depot = ArcadiaRefillablePropaneServer, ArcadiaRefillablePropane
    if type(Server) ~= "table" or type(Server.onLoadGridSquare) ~= "function" or type(Server.ensureDepot) ~= "function"
        or type(Depot) ~= "table" or type(Depot.PERSISTENT_ANCHOR_SPRITES) ~= "table"
        or type(Depot.isPersistentAnchorObject) ~= "function" or type(Depot.isFilibusterModActive) ~= "function" then
        print(PREFIX .. " sprite load NOT installed: upstream shape changed; re-check upstream.json recheck notes")
        return
    end
    if Depot.isFilibusterModActive() then
        print(PREFIX .. " sprite load NOT installed: Filibuster propane truck mod is active (needs the per-tile vehicle check)")
        return
    end
    local names = {}
    for name, flag in pairs(Depot.PERSISTENT_ANCHOR_SPRITES) do
        if flag == true and type(name) == "string" and name ~= "" then names[#names + 1] = name end
    end
    if #names == 0 then
        print(PREFIX .. " sprite load NOT installed: no anchor sprites")
        return
    end
    MapObjects.OnLoadWithSprite(names, function(object)
        if Depot.isPersistentAnchorObject(object) then Server.ensureDepot(object) end
    end, PRIORITY)
    Events.LoadGridsquare.Remove(Server.onLoadGridSquare)
    print(PREFIX .. " sprite load installed (" .. #names .. " anchor sprites; per-tile LoadGridsquare removed)")
end

Events.OnGameBoot.Add(install)
