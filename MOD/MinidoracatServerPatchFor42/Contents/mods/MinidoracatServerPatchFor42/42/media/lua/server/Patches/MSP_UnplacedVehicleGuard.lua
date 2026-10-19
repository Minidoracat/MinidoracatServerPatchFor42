--[[
MSP_UnplacedVehicleGuard — 拖車卸車時引擎拒絕放置，上游仍把車的資料寫進一台不存在的車再刪掉倉儲：整台車消失

涵蓋兩個上游，所以放在 Patches 根層，不放 <上游 mod id>/ 子目錄。

【上游】
- rSemiTruck（Workshop 3409472393，mod id rSemiTruck）的多槽拖車 MSW：
  `common/media/lua/server/MSW_Common_Commands.lua`（核對 sha256 前 12 碼 479104b27483）的 `Commands.launchVehicle`
  （卸車）與 `Commands.unloadContainer`（卸貨櫃）。
- Tsar's Common Library（Workshop 3402491515，mod id tsarslib，核對版本 3.31；42.21.0 載入 `42.17/` 與 `common/`）的拖吊車：
  `42.17/media/lua/shared/TimedActions/ATAISLaunchVehicle.lua` 的 `complete`（42.21 選單實際走的卸車路徑，伺服器執行）與
  `common/media/lua/server/CommonTemplates/CommonCommands.lua` 的 `Commands.launchVehicle`（`commonlib` 指令）。

【缺陷】
引擎 `addVehicleDebug`（42.21.0 `LuaManager.java:10791-10828`）放置前問 `IsoChunk.doSpawnedVehiclesInInvalidPosition`
（`IsoChunk.java:1240-1268`）：格子不在戶外又不在停車區（`getVehicleZoneAt(x,y,z) == nil && !isOutside()`，:1254-1256），
或與本輪已檢查過的車碰撞（:1258-1262）就回 false。這時不 `addToWorld`、不 `VehiclesDB2.addVehicle`（`LuaManager.java:10817-10823`），
卻照樣回傳那台車；它的 `sqlId` 停在初值 -1（`BaseVehicle.java:274`），因為只有 `VehiclesDB2` 的 `addVehicle`／`setVehicleLoaded`
會配號（`VehiclesDB2.java:301-320`）。
上游四個呼叫點都只判斷回傳值是不是 nil，接著把倉儲還原進這台不在世界上的車、再清掉倉儲：
- MSW 卸車：`deleteMSWStoredVehicleData` 刪掉全域 ModData `MSW_VehicleStorage_v2` 裡的快照、清空拖車槽位，車就永遠沒了
  （正式服 2026-10-19 在室內卸車實際發生）。MSW 的客戶端選單 `canLaunchHere`（`client/MSW_ISVehicleMenu.lua:191-206`）
  只看格子空不空，不看室內，所以選單照樣讓你卸。
- MSW 卸貨櫃：貨櫃裡的物品搬進不存在的車，拖車上的貨櫃零件拆掉。
- tsarslib 卸車（兩處相同）：`exchangePartsTrailerToVehicle2` 把零件交給不存在的車並清掉拖吊零件 modData（scriptName、parts…），
  再 `wreckerPart:setInventoryItem(nil)`。

【修法】
包裝全域 `addVehicleDebug`：呼叫原函式，回傳的車 `getSqlId() == -1`（引擎拒絕放置）就印一行 log、改回傳 nil，
讓上游走自己既有的失敗分支，車留在拖車上，玩家換個地方再卸。正常放置時 `VehiclesDB2.addVehicle` 在回傳前就同步配號
（`VehiclesDB2.java:126-128,317-320`），sqlId 必定 ≥1，原物件原樣回傳。

【上游核對（2026-10-20）】
- 呼叫期查全域：兩個上游全 MOD 都直接寫 `addVehicleDebug(...)`，沒有 `local addVehicleDebug = addVehicleDebug` 之類的快取，
  所以在檔案載入時換掉全域即可，與 `Mods=` 及檔案載入順序無關。
- MSW 卸車的 nil 分支：只記 DebugLog、顯示「Failed to spawn」提示就 return，之前沒有任何寫入；倉儲在還原成功後才刪。
  卸貨櫃：`if not veh then return end` 在搬物品之前。
- tsarslib：`ATAISLaunchVehicle.complete`（`42.17/` 與 `42.13/` 同檔）:66-70 與 `CommonCommands.lua` `Commands.launchVehicle`
  :1003-1007，nil 時印 `ERROR: Failed to spawn vehicle! launchVehicle` 後 return，在換零件、清 modData、拆拖吊零件之前；
  `complete` 回 nil：`pcallBoolean` 給 null（`KahluaThread.java:1329-1338`），`NetTimedAction.perform` 拆箱丟例外、被 catch 後
  回 false（`NetTimedAction.java:132-139`），動作被拒，伺服器多一行 `Perform failed`。
- 包裝是全域的，所有 MOD 的呼叫都經過它（2026-10-20 掃本機訂閱）：其他伺服器端呼叫者都自己處理 nil，或忽略回傳值
  （damnlib `DAMN_Spawns.lua`、原版 `ProfessionVehicles.lua`），不受影響；rSemiTruck 保證生成點（`rSemiTruck.GuaranteedSpawns_mil.lua:92-99`）
  原本把「被拒的車」當成已生成而永久記下，現在改成下次載入再試。不處理 nil 的只有原版 debug 情境與 tsarslib `_Debug`（開發工具）。

【為什麼不改上游】他人的 Workshop MOD，本服不重新發布；落差出在引擎回傳值的語意，在這一個地方擋住，兩個 MOD 四個呼叫點一起修好。

【軟依賴】不 require 上游。`getActivatedMods()` 沒有 rSemiTruck 也沒有 tsarslib 就直接 return：不換全域、不印 log。
MP 客戶端不裝（`isClient()`）：客戶端的 `addVehicleDebug` 本來就放不進世界（`IsoChunk.java:1245-1249` 只在伺服器／單機取格子）。

【E2E】`MSP_UnplacedVehicleGuard.original` 是引擎原函式，負對照輪次用它暫時換回。

【上游更新時要重核】見 upstream.json 兩筆的 recheck；兩個上游都自己檢查放置結果（`getSqlId() ~= -1`；`getSquare()` 不算，
`BaseVehicle.getSquare` 由座標現算，`BaseVehicle.java:9769-9771`，沒進世界也有格子）時本補丁退場。
]]

local PREFIX = "[MinidoracatServerPatchFor42]"

if isClient() or MSP_UnplacedVehicleGuard then return end
local mods = getActivatedMods()
local function active(id) return mods:contains(id) or mods:contains("\\" .. id) end
if not (active("rSemiTruck") or active("tsarslib")) then return end

local original = addVehicleDebug

addVehicleDebug = function(scriptName, dir, skinIndex, square)
    local vehicle = original(scriptName, dir, skinIndex, square)
    if vehicle and vehicle:getSqlId() == -1 then
        print(PREFIX .. " addVehicleDebug: engine did not place " .. tostring(scriptName) .. " at "
            .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
            .. " (indoors outside a vehicle zone, or overlapping a vehicle); returned nil so the caller keeps its stored vehicle")
        return nil
    end
    return vehicle
end

MSP_UnplacedVehicleGuard = { original = original }
print(PREFIX .. " unplaced vehicle guard installed (addVehicleDebug returns nil when the engine refuses placement)")
