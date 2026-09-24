--[[
MSP_TuningConsumeGuard — Tsar's Common Library 車輛改裝安裝／拆卸在伺服器端不驗材料數量

【上游】Tsar's Common Library（Workshop 3402491515，mod id tsarslib，核對版本 3.31；42.20.4 載入
`42.17/` 版本目錄）。upstream.json 有登記，Workshop 更新時 Action 會開 issue。

【缺陷】
改裝安裝／拆卸的材料消耗只在伺服器端執行（`LuaTimedActionNew.complete()` 於 client 不呼叫 Lua
`complete`，`LuaTimedActionNew.java:163-167`；伺服器由 `NetTimedAction.perform()` 以
`protectedCallBoolean(complete)` 執行，`NetTimedAction.java:132-139`）。而
`ISInstallTuningVehiclePart:complete`（42.17/…/shared/TimedActions/ISInstallTuningVehiclePart.lua:72-79）
與 `ISUninstallTuningVehiclePart:complete`（同目錄 :56-62）都是
`ATA.consumeItems(self.use, self.character)` 之後**無條件**呼叫 `ATA2Commands.installTuning`／
`uninstallTuning`，而 `ATA.consumeItems`（common/media/lua/shared/ATAActionsTools.lua:15-71）
遇到材料數量不足時只 `print` 一行 `ERROR ATA.consumeItems item X must be consumed (xN) but only M
are available.`（:47／:53），照扣手上有的、正常返回；物品完全找不到時則在 :32 對 nil 取方法拋錯，
前面已扣的材料不回滾。正式服 2026-08-30～09-05 共 58 次「短少照裝」（差額 1～4 件）。
根因（client 端 `ISVehicleTuning2:onInstallPart` 先 `transferItems()` 把周邊容器材料搬進背包再排動作，
伺服器端動作執行時背包卻仍短少）尚未定案；本補丁只堵伺服器端的驗證洞。

【修法】
伺服器端包裝兩個 `complete`：進入時用**與 `ATA.consumeItems` 完全相同的查法**（同樣的名稱正規化、
`getBestConditionRecurse`／`getAllTypeRecurse`／`IsDrainable`／`getCurrentUses`）預檢 `self.use`
每一項的件數或用量，任一項不足即 `return false`——不扣任何材料、不安裝／拆卸；vanilla 對
`complete` 回 false 的處理是拒絕該動作（client 端動作結束、什麼都沒發生，玩家重整材料後可再試）。
全部充足才交給原版 `complete`。伺服器 log 留一行 `[MinidoracatServerPatchFor42][tsarslib] rejected …`
供追根因。找不到的材料（原本 :32 會拋錯那種）同樣視為不足而拒絕。

【為什麼不改上游】
上游是 Workshop 熱門函式庫（tsarslib，多個車輛 MOD 的前置），本服不重新發布他人 MOD；
修法屬本服客製的信任邊界補強，不改變上游任何正常路徑（材料充足時逐位元走原版）。

【軟依賴】
不 require tsarslib。載入時若 `ISInstallTuningVehiclePart`／`ISUninstallTuningVehiclePart`／
`ATA.consumeItems` 不存在就什麼都不做；為避免 `Mods=` 順序把本 MOD 排在 tsarslib 之前，
另掛 `OnGameBoot` 再試一次安裝（冪等，不疊 wrapper）。只在 `isServer()` 生效。

【上游更新時要重核】ATAActionsTools.lua 的 consumeItems 名稱正規化（`__`→`.`、`find('\.')`）、
drainable 分支的用量語意（`getCurrentUses` 總和 vs `num`）、兩個 complete 是否仍是「先 consumeItems
再無條件安裝」；若上游自己補了預檢，本補丁可退場。
]]

local PREFIX = "[MinidoracatServerPatchFor42][tsarslib]"

-- 名稱正規化照抄 ATAActionsTools.lua:20-23。上游寫的是 `find('\.')`：Kahlua（同 Lua 5.1）把未定義的
-- 跳脫 `\.` 當成 `.`，pattern `.` 對任何非空字串都命中，所以「補 Base. 前綴」那一行實際上永遠不會執行
--（正式服 log 印的就是 `SteelBarHalf` 而非 `Base.SteelBarHalf`）。這裡寫成語意相同的 `find(".")`，
-- 刻意不「修正」它，查法才與消耗端完全一致（`ItemContainer.compareType` 對無 `.` 的型別比對短型名，
-- `ItemContainer.java:1193-1196`）。
local function normalizeName(itemName)
    itemName = itemName:gsub("__", ".")
    if not itemName:find(".") then
        itemName = "Base." .. itemName
    end
    return itemName
end

-- 回傳第一個不足的項目 { name, need, have, drainable }；全部充足回 nil。
-- 查法與 ATA.consumeItems 相同：找不到實例＝不足；drainable 以 getCurrentUses 總和計，其餘以件數計。
local function findShortfall(use, inventory)
    if type(use) ~= "table" or not inventory then return nil end
    for rawName, num in pairs(use) do
        if type(rawName) == "string" and type(num) == "number" then
            local name = normalizeName(rawName)
            local sample = inventory:getBestConditionRecurse(name)
            if not sample then
                return { name = name, need = num, have = 0, drainable = false }
            end
            local array = inventory:getAllTypeRecurse(name)
            if sample:IsDrainable() then
                local uses = 0
                for i = 0, array:size() - 1 do
                    uses = uses + array:get(i):getCurrentUses()
                end
                if uses < num then
                    return { name = name, need = num, have = uses, drainable = true }
                end
            elseif array:size() < num then
                return { name = name, need = num, have = array:size(), drainable = false }
            end
        end
    end
    return nil
end

local function wrapComplete(cls, label)
    if type(cls) ~= "table" or type(cls.complete) ~= "function" then return false end
    if cls.MSP_tuningConsumeGuardOriginal then return true end -- 已裝過，不疊
    local original = cls.complete
    cls.MSP_tuningConsumeGuardOriginal = original
    cls.complete = function(self)
        local inventory = self.character and self.character:getInventory()
        local short = findShortfall(self.use, inventory)
        if short then
            print(string.format("%s %s rejected: %s need %s have %s%s player=%s model=%s",
                PREFIX, label, short.name, tostring(short.need), tostring(short.have),
                short.drainable and " (uses)" or "", tostring(self.character:getUsername()), tostring(self.modelName)))
            return false
        end
        return original(self)
    end
    return true
end

local installed = false
local function install()
    if installed or not isServer() then return end
    if type(ATA) ~= "table" or type(ATA.consumeItems) ~= "function" then return end
    local a = wrapComplete(ISInstallTuningVehiclePart, "install")
    local b = wrapComplete(ISUninstallTuningVehiclePart, "uninstall")
    if a or b then
        installed = true
        print(PREFIX .. " material guard installed (install=" .. tostring(a) .. ", uninstall=" .. tostring(b) .. ")")
    end
end

install()
if not installed then
    Events.OnGameBoot.Add(install)
end

-- 離線測試用（scripts/test_tuning_consume_guard.lua）；遊戲內不會有人引用
MSP_TuningConsumeGuard = { findShortfall = findShortfall, normalizeName = normalizeName, install = install }
