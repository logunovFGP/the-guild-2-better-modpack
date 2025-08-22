local CATEGORY_DATA = {
    [1] = {
        objects = {"Handheld_Device/ANIM_Floursack.nif", "Handheld_Device/ANIM_Woodlog.nif", "Handheld_Device/ANIM_Metalbar.nif"},
        speeches = {"_HPFZ_HANDEL_SPRUCH_+0", "_HPFZ_HANDEL_SPRUCH_+1", "_HPFZ_HANDEL_SPRUCH_+2", "_HPFZ_HANDEL_SPRUCH_+3", "_HPFZ_HANDEL_SPRUCH_+4", "_HPFZ_HANDEL_SPRUCH_+5"},
        activity = "carry",
        sleepTime = 6,
        useAnimation = false
    },
    [2] = {
        objects = {"Handheld_Device/ANIM_Barrel.nif", "Handheld_Device/ANIM_Breadbasket.nif", "Handheld_Device/ANIM_fish_L.nif"},
        speeches = {"_HPFZ_HANDEL_SPRUCH_+6", "_HPFZ_HANDEL_SPRUCH_+7", "_HPFZ_HANDEL_SPRUCH_+8", "_HPFZ_HANDEL_SPRUCH_+9", "_HPFZ_HANDEL_SPRUCH_+10", "_HPFZ_HANDEL_SPRUCH_+11"},
        activity = "carry",
        sleepTime = 6,
        useAnimation = false,
        specialFlags = {[3] = true}
    },
    [3] = {
        objects = {"Handheld_Device/Anim_Hammer.nif", "Handheld_Device/ANIM_Smallsack.nif", "Handheld_Device/ANIM_Cloth.nif"},
        speeches = {"_HPFZ_HANDEL_SPRUCH_+12", "_HPFZ_HANDEL_SPRUCH_+13", "_HPFZ_HANDEL_SPRUCH_+22", "_HPFZ_HANDEL_SPRUCH_+23", "_HPFZ_HANDEL_SPRUCH_+20", "_HPFZ_HANDEL_SPRUCH_+21"},
        activity = "",
        sleepTime = 6,
        useAnimation = true,
        specialBehavior = {
            [1] = {useAnimation = true, activity = ""},
            [2] = {useAnimation = true, activity = ""},
            [3] = {useAnimation = false, activity = "carry"}
        }
    },
    [4] = {
        objects = {"Handheld_Device/ANIM_bookpile.nif"},
        speeches = {"_HPFZ_HANDEL_SPRUCH_+18", "_HPFZ_HANDEL_SPRUCH_+19"},
        activity = "carry",
        sleepTime = 6,
        useAnimation = false,
        singleVariation = true
    },
    [5] = {
        objects = {"Handheld_Device/ANIM_Bottlebox.nif", "Handheld_Device/ANIM_Aesculap_Staff.nif", "Handheld_Device/ANIM_perfumebottle.nif"},
        speeches = {"_HPFZ_HANDEL_SPRUCH_+24", "_HPFZ_HANDEL_SPRUCH_+25", "_HPFZ_HANDEL_SPRUCH_+26", "_HPFZ_HANDEL_SPRUCH_+27", "_HPFZ_HANDEL_SPRUCH_+28", "_HPFZ_HANDEL_SPRUCH_+29"},
        activity = "carry",
        sleepTime = 6,
        useAnimation = false,
        specialBehavior = {
            [1] = {useAnimation = false, activity = "carry"},
            [2] = {useAnimation = true, activity = ""},
            [3] = {useAnimation = true, activity = ""}
        }
    },
    [6] = {
        objects = {"Handheld_Device/ANIM_gun.nif", "weapons/langsword_01.nif"},
        speeches = {"_HPFZ_HANDEL_SPRUCH_+14", "_HPFZ_HANDEL_SPRUCH_+15", "_HPFZ_HANDEL_SPRUCH_+16", "_HPFZ_HANDEL_SPRUCH_+17"},
        activity = "",
        sleepTime = 0,
        useAnimation = true,
        limitedVariations = true
    }
}

function Run()
    if not f_MoveTo("","Destination") then
        MsgQuick("","Trade destination not reachable")
        StopMeasure()
    end	

    local inventoryData = ms_hpfz_handel_CheckInventory()
    local personalStock = inventoryData[1]
    local cartStock = inventoryData[2] 

    if personalStock == 0 and cartStock == 0 then
	   MsgQuick("","_HPFZ_HANDEL_FEHLER_+0")
	   StopMeasure()
    end

    MeasureSetStopMode(STOP_NOMOVE)
    CommitAction("handeln", "", "")

    GetPosition("","TradePos")
    GfxAttachObject("tradetable", "city/Stuff/tradetable.nif")
    GfxSetPositionTo("tradetable", "TradePos")

    while personalStock > 0 or cartStock > 0 do
        local availableCategories = ms_hpfz_handel_GetAvailableCategories()
        
        for category = 1, 6 do
            if availableCategories[category] == true then
                ms_hpfz_handel_AdvertiseCategory(category)
                Sleep(2)
            end
        end
        inventoryData = ms_hpfz_handel_CheckInventory()
        personalStock = inventoryData[1]
        cartStock = inventoryData[2]
        Sleep(3)
    end
    GfxDetachAllObjects()
    StopAction("handeln","")
    StopMeasure()
end

function CheckInventory()
    local personalSlots = InventoryGetSlotCount("",INVENTORY_STD)
    local personalItems = 0
    local cartItems = 0
    
    for slot = 0, personalSlots-1 do
        local itemID, itemCount = InventoryGetSlotInfo("", slot, INVENTORY_STD)
        if itemCount ~= nil and itemCount > 0 then
            if itemID ~= nil and ItemGetCategory(itemID) > 0 then
                personalItems = personalItems + 1
            end
        end 
    end
    
    local cartCount = Find("", "__F((Object.GetObjectsByRadius(Cart)==800)AND(Object.CanBeControlled())AND(Object.BelongsToMe()))", "PlayerCart", -1)
    
    if cartCount > 0 then
        
        for cartIndex = 0, cartCount-1 do
            local cartAlias = "PlayerCart"
            if cartIndex > 0 then
                cartAlias = "PlayerCart" .. cartIndex
            end

            local cartSlots = InventoryGetSlotCount(cartAlias, INVENTORY_STD)
            
            for slot = 0, cartSlots-1 do
                local itemID, itemCount = InventoryGetSlotInfo(cartAlias, slot, INVENTORY_STD)
                if itemCount ~= nil and itemCount > 0 then
                    if itemID ~= nil and ItemGetCategory(itemID) > 0 then
                        cartItems = cartItems + 1
                    end
                end 
            end
        end
    end
    
    return {personalItems, cartItems}
end

function GetAvailableCategories()
    local categories = {false, false, false, false, false, false}

    local personalSlots = InventoryGetSlotCount("", INVENTORY_STD)

    for slot = 0, personalSlots-1 do
        local itemID, itemCount = InventoryGetSlotInfo("", slot, INVENTORY_STD)
        if itemCount ~= nil and itemCount > 0 and itemID ~= nil then
            local category = ItemGetCategory(itemID)
            if category > 0 and category <= 6 then
                categories[category] = true
            end
        end
    end

    local cartCount = Find("", "__F((Object.GetObjectsByRadius(Cart)==800)AND(Object.CanBeControlled())AND(Object.BelongsToMe()))", "PlayerCart", -1)

    if cartCount > 0 then
        for cartIndex = 0, cartCount-1 do
            local cartAlias = "PlayerCart"
            if cartIndex > 0 then
                cartAlias = "PlayerCart" .. cartIndex
            end

            local cartSlots = InventoryGetSlotCount(cartAlias, INVENTORY_STD)

            for slot = 0, cartSlots-1 do
                local itemID, itemCount = InventoryGetSlotInfo(cartAlias, slot, INVENTORY_STD)
                if itemCount ~= nil and itemCount > 0 and itemID ~= nil then
                    local category = ItemGetCategory(itemID)
                    if category > 0 and category <= 6 then
                        categories[category] = true
                    end
                end
            end
        end
    end
    return categories
end

function AdvertiseCategory(category) 
    local categoryData = CATEGORY_DATA[category]
    if not categoryData then
        return
    end
    
    local maxVariations = 3
    if categoryData.singleVariation then
        maxVariations = 1
    elseif categoryData.limitedVariations then
        maxVariations = 2
    end
    
    local tradeVariation = Rand(maxVariations)
    local speechVariation = Rand(2)
    local actionTime = 0

    if SimGetGender("") == GL_GENDER_MALE then
        PlaySound3DVariation("","CharacterFX/male_jolly", 1)
    else
        PlaySound3DVariation("","CharacterFX/female_jolly", 1)
    end
    PlayAnimation("","preach")
    Sleep(1)
    
    local currentBehavior = {
        useAnimation = categoryData.useAnimation,
        activity = categoryData.activity,
        sleepTime = categoryData.sleepTime
    }
    
    if categoryData.specialBehavior and categoryData.specialBehavior[tradeVariation + 1] then
        local special = categoryData.specialBehavior[tradeVariation + 1]
        currentBehavior.useAnimation = special.useAnimation
        currentBehavior.activity = special.activity
        if special.sleepTime then
            currentBehavior.sleepTime = special.sleepTime
        end
    end
    
    if currentBehavior.useAnimation then
        actionTime = PlayAnimationNoWait("","use_object_standing")
        Sleep(1)
    end
    
    if currentBehavior.activity ~= "" then
        MoveSetActivity("", currentBehavior.activity)
    end
    
    local objectIndex = tradeVariation + 1
    if categoryData.singleVariation then
        objectIndex = 1
    end
    local objectPath = categoryData.objects[objectIndex]

    local speechIndex = tradeVariation * 2 + speechVariation + 1
    if categoryData.singleVariation then
        speechIndex = speechVariation + 1
    end
    local speechText = categoryData.speeches[speechIndex]
    
    local carryFlag = false
    if categoryData.specialFlags and categoryData.specialFlags[tradeVariation + 1] then
        carryFlag = true
    end
    
    CarryObject("", objectPath, carryFlag)
    MsgSay("", speechText)
    
    local sleepTime = currentBehavior.sleepTime
    if actionTime > 0 then
        sleepTime = math.max(1, actionTime - 1)
    end
    
    if sleepTime > 0 then
        Sleep(sleepTime)
    end

    ms_hpfz_handel_CleanUpAdvertisement()
end

function CleanUpAdvertisement()
    CarryObject("", "", false)
    CarryObject("", "", true)
    MoveSetActivity("")
end

function CleanUp()
    StopAnimation("")
    StopAction("handeln", "")
    GfxDetachAllObjects()
    ms_hpfz_handel_CleanUpAdvertisement()
end