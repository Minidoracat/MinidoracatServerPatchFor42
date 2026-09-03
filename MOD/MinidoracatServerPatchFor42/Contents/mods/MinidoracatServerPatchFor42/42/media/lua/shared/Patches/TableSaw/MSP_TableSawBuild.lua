--[[
MSP_TableSawBuild — [B42][MP]Table Saw（Workshop 3540297822）缺 Building Craft 時台鋸無法建造

【上游】Table Saw 3540297822（mod id TableSaw）。upstream.json 有登記，Workshop 更新時 Action 會開 issue。

【缺陷】
TableSaw 的「建造台鋸」只註冊進 Building Craft（3459887404）的建造選單：
TableSaw_Global.lua:224 `if Building_Data then` 之內才呼叫
`BuildingCraft_AddItemData(ModTextureData1(), 11)`；mod.info 又沒寫 require=，
所以沒裝 Building Craft 時整段靜默跳過——零錯誤、零 log，玩家只能靠 7 種房型 × 3%
首見率（RandomSpawnTableSaw.lua:47-49）撿到現成台鋸。使用台鋸／修理／換鋸片不受影響。

【為什麼不裝 Building Craft】
它 top-level 硬覆寫 vanilla `DoTileBuilding`／`ISBuildingObject:tryBuild`
（ISBuildingObjectNew.lua:24/:137，B41 世代 fork），而 B42 官方 `ISBuildIsoEntity:tryBuild`
會呼叫後者 ⇒ 全服建築主路徑都改走 fork（手把守衛 `xJoypad == -1` vs vanilla `== nil`
確定回歸）。評估：MinidoracatServerAnalyze/reports/mods/2026-09-03-BuildingCraft-3459887404-評估.md

【本補丁】
用 vanilla `ISBuildingObject` 老路徑補一個建造入口（右鍵地面 →「建造台鋸」），配方逐項照抄
TableSaw_Global.lua:163-201 的 ModTextureData1()：
  技能 MetalWelding 5、雜誌配方 "Make TableSaw"、工具 BlowTorch（手持）＋ WeldingMask（臉部）
  need: CircularSawblade×1 AgedMotor×1 SheetMetal×8 Screws×8 MetalPipe×6 ElectricWire×4
  use:  WeldingRods×4 BlowTorch×4（use/need 分類照 Building Craft 的 MaterialIsUse 表，
        Building_Data.lua:33-34）
  xp:MetalWelding 1
三檔：shared（本檔，常數＋檢查）、server/Patches/TableSaw/MSP_TableSawBuildCursor.lua（建造游標）、
client/Patches/TableSaw/MSP_TableSawBuildMenu.lua（右鍵入口）。

【軟依賴】
不 require TableSaw。所有對其全域（TableSawSpriteList／TableSawMaxDurable／SawBladeMaxDurable）
的引用都在函式內執行時解析，載入順序無關；isTableSawLoaded() 為 false 時右鍵不加選項，零行為。

【上游更新時要重核】ModTextureData1() 的配方、TableSawSpriteList 的 sprite 名、
ISBuildTableSaw:create 的 modData 欄位（Durable／SawBladeDurable）。
]]

MSP_TableSawBuild = MSP_TableSawBuild or {}
local TSB = MSP_TableSawBuild

TSB.RECIPE_NAME = "Make TableSaw"
TSB.SKILL_LEVEL = 5
-- 順序即 ISBuildingObject 的 sprite / northSprite / eastSprite / southSprite
-- （與 Building Craft 呼叫 ISBuildTableSaw:new 時傳入的 sprite1..4 相同）
TSB.SPRITES = { "TableSaw_0", "TableSaw_1", "TableSaw_2", "TableSaw_3" }
TSB.NEED = {
    ["Base.CircularSawblade"] = 1,
    ["Base.AgedMotor"] = 1,
    ["Base.SheetMetal"] = 8,
    ["Base.Screws"] = 8,
    ["Base.MetalPipe"] = 6,
    ["Base.ElectricWire"] = 4,
}
TSB.USE = {
    ["Base.WeldingRods"] = 4,
    ["Base.BlowTorch"] = 4,
}
TSB.XP = 1

function TSB.isTableSawLoaded()
    return type(TableSawSpriteList) == "table" and TableSawSpriteList[TSB.SPRITES[1]] ~= nil
end

function TSB.knowsRecipe(playerObj)
    local known = playerObj:getKnownRecipes()
    return known ~= nil and known:contains(TSB.RECIPE_NAME)
end

function TSB.hasSkill(playerObj)
    return playerObj:getPerkLevel(Perks.MetalWelding) >= TSB.SKILL_LEVEL
end

-- 穿戴中的物品仍在 inventory 內，getFirstTypeRecurse 兩種情況都找得到
function TSB.hasWeldingMask(playerObj)
    return playerObj:getInventory():getFirstTypeRecurse("Base.WeldingMask") ~= nil
end

function TSB.isCheat(playerObj)
    return (ISBuildMenu and ISBuildMenu.cheat) or playerObj:isBuildCheat()
end
