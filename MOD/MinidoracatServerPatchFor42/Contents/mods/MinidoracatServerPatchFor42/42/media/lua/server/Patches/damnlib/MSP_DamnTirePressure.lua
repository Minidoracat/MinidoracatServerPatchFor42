--[[
MSP_DamnTirePressure — damnlib 的 CTIS 自動補胎與三台 KI5 車的 temp tire fix，在 42.22.2 對一般玩家失效

【上游】that DAMN Library（Workshop 3171167894，mod id damnlib，作者 KI5／bikinihorst；42.22.2 載入 `42.20/`），
以及透過它補胎的 '85 Chevrolet Caprice／Impala（3413704851，載入 `42.13/`）、'89 Land Rover Defender（3570973322，載入 `42.20/`）、
'69 Dodge Charger（3631989559，載入 `42.20/`）。upstream.json 四筆都有登記（上游宣告 On Lockdown，repo 不留上游快照）。

【缺陷】damnlib 客戶端用 `DAMN.Parts:setContainerAmount`（shared/DAMN_Parts.lua:463-469）送原版指令
`vehicle.setContainerContentAmount`，把輪胎補到 35（`DAMN.Armor["tireCTISPressure"]`，client/DAMN_Armor_Client.lua:13）：
- CTIS：車上有 RFsystem 與 CTIsystem 零件、引擎發動中，四個輪胎低於 35 就補（DAMN_Armor_Client.lua:29-49），
  由 client/DAMN_Client.lua:42-47 掛在 OnPlayerUpdate；OnEnterVehicle 不分座位（:75-118），乘客的客戶端也送。
- temp tire fix：上面三台車的裝甲程式（`DAMN.Armor:add` 登記的車種）在車上每次 OnPlayerUpdate 都看，輪胎低於 1 就補到 35，
  不看引擎（85chevyCaprice_armor.lua:217-227、89defender_armor.lua:177-187、69charger_armor.lua:159-169）。
42.22.2 原版處理器要 `UseMechanicsCheat`（server/Vehicles/VehicleCommands.lua:44-57；42.20.2 的 :80-93 沒有這個檢查；
42.21 的 Lua 本機沒有，42.21 函式索引只有行號，是 42.21 還是 42.22 加的無法確認），
一般玩家的請求被安靜丟掉：胎壓補不上去，條件一直成立，客戶端每次 OnPlayerUpdate 都再送一次。

【修法】伺服器 OnClientCommand 只看 vehicle.setContainerContentAmount，下面全部成立才照 42.20 原版做
`setContainerContentAmount` 與 `transmitPartModData`（引擎把數值夾在輪胎容量內，VehiclePart.java:387-399）：
- 送指令的人是 args.vehicle 這台車的駕駛（車輛 id 要完全相等，小數不算）。上游客戶端不分座位都會送，乘客的請求不理：
  和 Vehicle Manager 指令防火牆一致（它只讓駕駛自動補胎，其他座位要有修車權限）；
- 零件是上游迴圈的四個輪胎之一，數值剛好 35；
- 車上有 RFsystem 與 CTIsystem、引擎發動中、伺服器上的胎壓低於 35；或車種是三台車登記的裝甲車種、胎壓低於 1。
胎壓沒變（已經到容量上限）就不送同步。其他數值、別台車、非輪胎、條件不符的請求一律不理，原版照舊拒絕。
有 UseMechanicsCheat 的人原版先處理（原版 server 檔排在 MOD 之前），胎壓已經是 35，這裡不會再做一次。
Vehicle Manager 的指令防火牆在 shared 註冊、排在所有 server 處理器之前，拒絕時把 args.vehicle 改成 -1，這裡跟著不理。
不涵蓋：車上只有乘客時不補（客戶端照舊重送）；damnlib 換掉舊版輪胎物品後補胎（DAMN_Parts.lua:296-310 → DAMN_BackCompat.lua），
那條不限車種、送的人不必在車上。

【為什麼不改上游】上游宣告 On Lockdown（不得修改、重新打包或散布其檔案）；改變的是 42.20.2 之後原版的權限，
上游客戶端沒有別的管道補胎。本補丁不碰上游檔案、不含上游內容，只在伺服器接受上游本來就會送的這兩種請求。

【軟依賴】不 require 上游。getActivatedMods() 沒有 damnlib 就直接 return：不註冊事件、不印 log。三台車沒裝時，它們的車種不會出現。

【E2E】`MSP_DamnTirePressure.onCommand` 是註冊的處理器，負對照輪次用 `Events.OnClientCommand.Remove` 暫時拿掉。

【上游更新時要重核】見 upstream.json 四筆的 recheck；上游改用自己的伺服器指令補胎、或原版拿掉權限檢查時，本補丁退場。
]]

local PREFIX = "[MinidoracatServerPatchFor42][damnlib]"

if not isServer() or MSP_DamnTirePressure then return end
local mods = getActivatedMods()
if not (mods:contains("damnlib") or mods:contains("\\damnlib")) then return end

local PRESSURE = 35
local TIRES = { TireFrontLeft = true, TireFrontRight = true, TireRearLeft = true, TireRearRight = true }
local ARMOR = {}
for _, name in ipairs({
    -- 85chevyCaprice 42.13/media/lua/client/85chevyCaprice_armor.lua:231-248
    "85chevyCapriceSedan", "85chevyCapriceCoupe", "85chevyCapriceWagon", "85chevyCapriceWagon2",
    "85chevyImpalaSedanAirport", "85chevyImpalaSedanBCS", "85chevyImpalaSedanCLPD", "85chevyImpalaSedanFD",
    "85chevyImpalaSedanKSP", "85chevyImpalaSedanLCPD", "85chevyImpalaSedanMCS", "85chevyImpalaSedanMPD",
    "85chevyImpalaSedanPD", "85chevyImpalaSedanPDu", "85chevyImpalaSedanPrison", "85chevyImpalaSedanRanger",
    "85chevyImpalaSedanTaxi", "85chevyImpalaSedanWPPD",
    -- 89defender 42.20/media/lua/client/89defender_armor.lua:191-196
    "89defender90", "89defender90utility", "89defender110", "89defender110utility", "89defender130", "89defenderWolf",
    -- 69charger 42.20/media/lua/client/69charger_armor.lua:173-177
    "69chargerRT", "69charger500", "69chargerDaytona", "69charger440", "69chargerDemon",
}) do
    ARMOR["Base." .. name] = true
end

local function onCommand(module, command, player, args)
    if module ~= "vehicle" or command ~= "setContainerContentAmount" or type(args) ~= "table" then return end
    if args.amount ~= PRESSURE or not TIRES[args.part] or player == nil then return end
    local vehicle = player:getVehicle()
    if vehicle == nil or vehicle:getId() ~= args.vehicle or not vehicle:isDriver(player) then return end
    local part = vehicle:getPartById(args.part)
    if part == nil then return end
    local now = part:getContainerContentAmount()
    local ctis = now < PRESSURE and vehicle:isEngineRunning()
        and vehicle:getPartById("RFsystem") ~= nil and vehicle:getPartById("CTIsystem") ~= nil
    if not (ctis or (now < 1 and ARMOR[vehicle:getScript():getFullName()])) then return end
    part:setContainerContentAmount(PRESSURE)
    if part:getContainerContentAmount() ~= now then vehicle:transmitPartModData(part) end
end

MSP_DamnTirePressure = { onCommand = onCommand, PRESSURE = PRESSURE, TIRES = TIRES, ARMOR = ARMOR }
Events.OnClientCommand.Add(onCommand)
print(PREFIX .. " tire pressure fix installed (CTIS and temp tire fix requests from the driver)")
