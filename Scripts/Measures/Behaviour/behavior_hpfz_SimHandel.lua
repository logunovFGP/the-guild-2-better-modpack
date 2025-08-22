local CUSTOMER_REACTION_DATA = {
    [1] = {
        objects = {"Handheld_Device/ANIM_Floursack.nif", "Handheld_Device/ANIM_Woodlog.nif", "Handheld_Device/ANIM_Metalbar.nif"},
        speeches = {"_HPFZ_HANDEL_ANTWORT_+0", "_HPFZ_HANDEL_ANTWORT_+1", "_HPFZ_HANDEL_ANTWORT_+2"},
        activity = "carry",
        sleepTime = 3,
        useAnimation = false
    },
    [2] = {
        objects = {"Handheld_Device/ANIM_Barrel.nif", "Handheld_Device/ANIM_Breadbasket.nif", "Handheld_Device/ANIM_fish_L.nif"},
        speeches = {"_HPFZ_HANDEL_ANTWORT_+3", "_HPFZ_HANDEL_ANTWORT_+4", "_HPFZ_HANDEL_ANTWORT_+5"},
        activity = "carry",
        sleepTime = 3,
        useAnimation = false,
        specialFlags = {[3] = true}
    },
    [3] = {
        objects = {"Handheld_Device/Anim_Hammer.nif", "Handheld_Device/ANIM_Smallsack.nif", "Handheld_Device/ANIM_Cloth.nif"},
        speeches = {"_HPFZ_HANDEL_ANTWORT_+6", "_HPFZ_HANDEL_ANTWORT_+11", "_HPFZ_HANDEL_ANTWORT_+10"},
        activity = "",
        sleepTime = 3,
        useAnimation = true,
        specialBehavior = {
            [1] = {useAnimation = true, activity = ""},
            [2] = {useAnimation = true, activity = ""},
            [3] = {useAnimation = false, activity = "carry"}
        }
    },
    [4] = {
        objects = {"Handheld_Device/ANIM_bookpile.nif"},
        speeches = {"_HPFZ_HANDEL_ANTWORT_+9"},
        activity = "carry",
        sleepTime = 3,
        useAnimation = false,
        singleVariation = true
    },
    [5] = {
        objects = {"Handheld_Device/ANIM_Bottlebox.nif", "Handheld_Device/ANIM_Aesculap_Staff.nif", "Handheld_Device/ANIM_perfumebottle.nif"},
        speeches = {"_HPFZ_HANDEL_ANTWORT_+12", "_HPFZ_HANDEL_ANTWORT_+13", "_HPFZ_HANDEL_ANTWORT_+14"},
        activity = "carry",
        sleepTime = 3,
        useAnimation = false,
        specialBehavior = {
            [1] = {useAnimation = false, activity = "carry"},
            [2] = {useAnimation = true, activity = ""},
            [3] = {useAnimation = true, activity = ""}
        }
    },
    [6] = {
        objects = {"Handheld_Device/ANIM_gun.nif", "weapons/langsword_01.nif"},
        speeches = {"_HPFZ_HANDEL_ANTWORT_+7", "_HPFZ_HANDEL_ANTWORT_+8"},
        activity = "",
        sleepTime = 0,
        useAnimation = true,
        limitedVariations = true
    }
}

function Run()
    if Rand(5) > 1 then
        GetFleePosition("Owner", "Actor", Rand(50)+100, "Away")
        f_MoveTo("Owner", "Away", GL_MOVESPEED_WALK)
        AlignTo("Owner", "Actor")
        Sleep(1)
        
        local timeLeft
        if Rand(10) < 5 then
            if SimGetGender("Owner") == GL_GENDER_MALE then
                PlaySound3DVariation("", "CharacterFX/male_cheer", 1)
            else
                PlaySound3DVariation("", "CharacterFX/female_cheer", 1)
            end
            timeLeft = PlayAnimation("Owner", "cheer_01")
        else
            timeLeft = PlayAnimation("Owner", "cheer_02")
        end
        
        local itemCategory = behavior_hpfz_simhandel_CustomerChoice()
        if itemCategory > 0 then
            behavior_hpfz_simhandel_CustomerReaction(itemCategory)
        end
    end
end

function CustomerChoice()
    local itemList = {}
    local itemSources = {}

    if AliasExists("Owner") and AliasExists("Actor") then
        local index = 0

        local slotCount = InventoryGetSlotCount("Actor", INVENTORY_STD)
        for count = 0, slotCount - 1 do
            local itemID, itemCount = InventoryGetSlotInfo("Actor", count, INVENTORY_STD)
            if itemID ~= nil and itemCount > 0 then
                index = index + 1
                itemList[index] = itemID
                itemSources[index] = {type = "personal"}
            end
        end

        local function IsOwnedByActor(cart)
            if not GetHomeBuilding(cart, "Building") then
                return false
            end
            if not BuildingGetOwner("Building", "BuildingOwner") then
                return false
            end
            return GetID("BuildingOwner") == GetID("Actor")
        end

        local function AnalyzeCart(cart, cartIndex)
            if IsOwnedByActor(cart) then
                local cartSlotCount = InventoryGetSlotCount(cart, INVENTORY_STD)
                for count = 0, cartSlotCount - 1 do
                    local itemID, itemCount = InventoryGetSlotInfo(cart, count, INVENTORY_STD)
                    if itemID ~= nil and itemCount > 0 then
                        index = index + 1
                        itemList[index] = itemID
                        itemSources[index] = {
                            type = "cart", 
                            cartIndex = cartIndex,
                            cartAlias = cartIndex > 0 and ("Cart" .. cartIndex) or "Cart"
                        }
                    end
                end
            end
        end

        local cartCount = Find("Actor", "__F((Object.GetObjectsByRadius(Cart)==800))", "Cart", -1)
        if cartCount > 0 then
            for cartIndex = 0, cartCount - 1 do
                local cartAlias = "Cart"
                if cartIndex > 0 then
                    cartAlias = "Cart" .. cartIndex
                end
                AnalyzeCart(cartAlias, cartIndex)
            end
        end

        if index > 0 then
            local purchase = Rand(index) + 1
            local selectedItem = itemList[purchase]
            local itemSource = itemSources[purchase]
            
            if ItemGetCategory(selectedItem) ~= -1 then
                local price = behavior_hpfz_simhandel_CalculateMarketPrice(selectedItem)
                if price > 0 then
                    chr_CreditMoney("Actor", price, "Offering")
                    IncrementXPQuiet("Actor", 5)
                    if IsDynastySim("Owner") then
                        chr_SpendMoney("Owner", price, "Offering")
                    end
                    ShowOverheadSymbol("Actor", false, true, 0, "%1t", price)

                    if itemSource.type == "cart" then
                        RemoveItems(itemSource.cartAlias, selectedItem, 1)
                    else
                        RemoveItems("Actor", selectedItem, 1)
                    end
                end
                return ItemGetCategory(selectedItem)
            end
        end
    end
    return -1
end

function CalculateMarketPrice(itemID)
    if not GetNearestSettlement("Owner", "NearestCity") then
        behavior_hpfz_simhandel_CalculateFallbackPrice(itemID)
    end

    if not CityGetLocalMarket("NearestCity", "LocalMarket") then
        behavior_hpfz_simhandel_CalculateFallbackPrice(itemID)
    end

    local buyPrice = ItemGetPriceBuy(itemID, "LocalMarket")
    local sellPrice = ItemGetPriceSell(itemID, "LocalMarket")
    
    if buyPrice == -1 or sellPrice == -1 then
        behavior_hpfz_simhandel_CalculateFallbackPrice(itemID)
    end

    local currentPrice = sellPrice
    local priceRange = buyPrice - sellPrice

    local actorSkill = GetSkillValue("Actor", 9)
    local ownerRank = SimGetRank("Owner")
    local favor = GetFavorToSim("Owner", "Actor")

    local skillFactor = actorSkill / 14.0
    local rankFactor = (ownerRank - 1) / 4.0
    local favorFactor = favor / 100.0
    
    local skillWeight = 0.4
    local rankWeight = 0.4
    local favorWeight = 0.15
    local randomWeight = 0.05
    
    local randomFactor = Rand(100) / 100.0
    
    local combinedFactor = (skillFactor * skillWeight) + 
                          (rankFactor * rankWeight) + 
                          (favorFactor * favorWeight) + 
                          (randomFactor * randomWeight)

    local priceIncrease = priceRange * combinedFactor
    local finalPrice = math.floor(currentPrice + priceIncrease)

    if actorSkill == 14 and ownerRank == 5 and favor == 100 then
        local perfectBonus = math.floor(buyPrice * 0.05)
        finalPrice = math.min(finalPrice + perfectBonus, buyPrice + perfectBonus)
    else
        finalPrice = math.min(finalPrice, buyPrice)
    end

    return finalPrice
end

function CalculateFallbackPrice(itemID)
    local basePrice = ItemGetBasePrice(itemID)
    local actorSkill = GetSkillValue("Actor", 9)
    local ownerRank = SimGetRank("Owner")

    local multiplier
    if basePrice <= 50 then
        multiplier = 1.2 + (actorSkill * 0.02) + ((ownerRank - 1) * 0.08)
    elseif basePrice <= 200 then
        multiplier = 1.15 + (actorSkill * 0.015) + ((ownerRank - 1) * 0.06)
    elseif basePrice <= 1000 then
        multiplier = 1.1 + (actorSkill * 0.01) + ((ownerRank - 1) * 0.04)
    else
        multiplier = 1.05 + (actorSkill * 0.005) + ((ownerRank - 1) * 0.02)
    end
    
    return math.floor(basePrice * multiplier)
end

function CustomerReaction(category)  
    if Rand(3) ~= 1 then
        local categoryData = CUSTOMER_REACTION_DATA[category]
        if not categoryData then
            return
        end

        local maxVariations = 3
        if categoryData.singleVariation then
            maxVariations = 1
        elseif categoryData.limitedVariations then
            maxVariations = 2
        end

        local variation = Rand(maxVariations)
        local actionTime = 0

        local useAnimation = categoryData.useAnimation
        local activity = categoryData.activity
        local sleepTime = categoryData.sleepTime
        
        if categoryData.specialBehavior and categoryData.specialBehavior[variation + 1] then
            local special = categoryData.specialBehavior[variation + 1]
            useAnimation = special.useAnimation
            activity = special.activity
            if special.sleepTime then
                sleepTime = special.sleepTime
            end
        end

        if useAnimation then
            actionTime = PlayAnimationNoWait("Owner", "use_object_standing")
            Sleep(1)
        end

        if activity ~= "" then
            MoveSetActivity("Owner", activity)
        end

        local objectIndex = variation + 1
        if categoryData.singleVariation then
            objectIndex = 1
        end
        local objectPath = categoryData.objects[objectIndex]
        
        local speechIndex = variation + 1
        if categoryData.singleVariation then
            speechIndex = 1
        end
        local speechText = categoryData.speeches[speechIndex]

        local carryFlag = false
        if categoryData.specialFlags and categoryData.specialFlags[variation + 1] then
            carryFlag = true
        end

        CarryObject("Owner", objectPath, carryFlag)
        MsgSay("Owner", speechText)

        if actionTime > 0 then
            Sleep(actionTime - 1)
        else
            Sleep(sleepTime)
        end
    end
    MoveSetActivity("")
	CarryObject("", "", false)
	CarryObject("", "", true)
end

function CleanUp()
    MoveSetActivity("Owner", "")
    CarryObject("Owner", "", false)
    CarryObject("", "", false)
    CarryObject("", "", true)
    MoveSetActivity("")
end