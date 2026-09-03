--[[
MSP_TableSawBuildMenu — 右鍵地面的「建造台鋸」入口。上游與缺陷見 shared 檔頭。

不知道配方（沒讀過 TableSawMagazine）就不顯示，與 vanilla 建造選單對未知配方的
行為一致。知道配方但技能／面罩不足時顯示灰色並在 tooltip 列出缺項；材料不足
交給游標變紅（ISBuildingObject:isValid → haveMaterial）。
]]

local TSB = MSP_TableSawBuild

local function startBuild(playerNum)
    getCell():setDrag(ISMSPBuildTableSaw:new(playerNum), playerNum)
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if not TSB.isTableSawLoaded() then return end
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj or playerObj:getVehicle() then return end
    local cheat = TSB.isCheat(playerObj)
    if not cheat and not TSB.knowsRecipe(playerObj) then return end

    local square
    for _, obj in ipairs(worldObjects) do
        square = obj:getSquare()
        if square then break end
    end
    if not square then return end
    if test then return true end

    local option = context:addOption(getText("ContextMenu_MSP_BuildTableSaw"), playerNum, startBuild)
    option.iconTexture = getTexture("media/textures/TableSaw.png")

    if cheat then return end
    local missing = {}
    if not TSB.hasSkill(playerObj) then
        missing[#missing + 1] = getText("Tooltip_MSP_NeedSkill", getText("IGUI_perks_MetalWelding"), TSB.SKILL_LEVEL)
    end
    if not TSB.hasWeldingMask(playerObj) then
        missing[#missing + 1] = getText("Tooltip_MSP_NeedMask", getItemNameFromFullType("Base.WeldingMask"))
    end
    if #missing > 0 then
        option.notAvailable = true
        local tip = ISWorldObjectContextMenu.addToolTip()
        tip.description = "<RGB:1,0,0> " .. table.concat(missing, " <LINE> ")
        option.toolTip = tip
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
