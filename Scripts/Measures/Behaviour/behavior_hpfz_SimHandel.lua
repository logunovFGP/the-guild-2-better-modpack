function Run()

	if Rand(5) > 1 then
	    GetFleePosition("Owner", "Actor", Rand(50)+100, "Away")
	    f_MoveTo("Owner", "Away", GL_MOVESPEED_WALK)
	    AlignTo("Owner", "Actor")
	    Sleep(1)
		local TimeLeft
		if Rand(10) < 5 then
			if SimGetGender("Owner") == GL_GENDER_MALE then
				PlaySound3DVariation("", "CharacterFX/male_cheer", 1)
			else
				PlaySound3DVariation("", "CharacterFX/female_cheer", 1)
			end
			TimeLeft = PlayAnimation("Owner", "cheer_01")
		else
			TimeLeft = PlayAnimation("Owner", "cheer_02")
		end
		local ItemCat = behavior_hpfz_simhandel_KundeAuswahl()
		if ItemCat > 0 then
			behavior_hpfz_simhandel_KundeReaktion(ItemCat)
		end
	end
end

function KundeAuswahl()
    LogMessage("@Free_Trade #E KundeAuswahl() -> Actor | "..GetName("Actor")..", Owner | "..GetName("Owner"))

	local List = {}

    if AliasExists("Owner") and AliasExists("Actor") then
        local Index, SlotCount = 0, InventoryGetSlotCount("Actor", INVENTORY_STD)
        for Count = 0, SlotCount - 1 do
            local ItemID, ItemCount = InventoryGetSlotInfo("Actor", Count, INVENTORY_STD)
	        if ItemID ~= nil and ItemCount > 0 then
                Index = Index + 1
                List[Index] = ItemID
            end
        end


        if Index > 0 then
            LogMessage("@Free_Trade #E Index: "..Index)
            local Purchase = Rand(Index) + 1
            if ItemGetCategory(List[Purchase]) ~= -1 then
                local Calculus = ((GetSkillValue("Actor", 9) * (SimGetRank("Owner") + 5)) + ItemGetBasePrice(List[Purchase]))
                chr_CreditMoney("Actor", Calculus, "IncomeStreetSales")
                IncrementXPQuiet("Actor", 5)
                if IsDynastySim("Owner") then
                    chr_SpendMoney("Owner", Calculus, "CostStreetSales")
                end
                ShowOverheadSymbol("Actor", false, true, 0, "%1t", Calculus)
                RemoveItems("Actor", List[Purchase], 1)
            end
            LogMessage("@NAO #E behavior_hpfz_simhandel.lua, Purchase: "..Purchase..".")
            return ItemGetCategory(List[Purchase])
        else
            LogMessage("@Free_Trade #E Index is nil.")
            return -1
        end
    end

	--[[else
        local itemX, mengeX, slotX, feil, gPreis, summe, bonus, charm
        local r = 0
        slotX = InventoryGetSlotCount("Actor",INVENTORY_STD)
        for s = 0, slotX-1 do
            itemX, mengeX = InventoryGetSlotInfo("Actor",s,INVENTORY_STD)
            if itemX and mengeX > 0 then
                r = r + 1
                List[r] = itemX
            end
        end
        Purchase = ( Rand(r) + 1 )
        if ItemGetCategory(List[Purchase]) ~= nil then
            if ItemGetCategory(List[Purchase])~=0 and ItemGetCategory(List[Purchase])~=6 then
                feil = GetSkillValue("Actor",9)
                charm = GetSkillValue("Actor",3)
                gPreis = ItemGetBasePrice(List[Purchase])
                bonus = ( SimGetRank("Owner") * charm )
                summe = ((feil * bonus) + gPreis)
                chr_CreditMoney("Actor",summe,"Offering")
                IncrementXPQuiet("Actor",5)
                ShowOverheadSymbol("Actor",false,true,0,"%1t",summe)
                RemoveItems("Actor", List[Purchase], 1)
            end
        end--]]
end

function KundeReaktion(z)
    local simReagiert = Rand(3)
    local HandVerkauf = Rand(3)
	if simReagiert == 0 or simReagiert == 2 then
        if z == 1 then
            MoveSetActivity("Owner","carry")
            if HandVerkauf == 0 then
                CarryObject("Owner", "Handheld_Device/ANIM_Floursack.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+0")
            elseif HandVerkauf == 1 then
                CarryObject("Owner", "Handheld_Device/ANIM_Woodlog.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+1")
            else
                CarryObject("Owner", "Handheld_Device/ANIM_Metalbar.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+2")
            end
            Sleep(3)
	    elseif z == 2 then
            MoveSetActivity("Owner","carry")
            if HandVerkauf == 0 then
                CarryObject("Owner", "Handheld_Device/ANIM_Barrel.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+3")
            elseif HandVerkauf == 1 then
                CarryObject("Owner", "Handheld_Device/ANIM_Breadbasket.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+4")
            else
                CarryObject("Owner", "Handheld_Device/ANIM_fish_L.nif", true)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+5")
            end
            Sleep(3)
	    elseif z == 3 then
            local Aktion = PlayAnimationNoWait("Owner","use_object_standing")
            Sleep(1)
            if HandVerkauf == 0 then
                CarryObject("Owner", "Handheld_Device/Anim_Hammer.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+6")
            elseif HandVerkauf == 1 then
                CarryObject("Owner", "Handheld_Device/ANIM_gun.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+7")
            else
                CarryObject("Owner", "weapons/langsword_01.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+8")
            end
            Sleep(Aktion-1)
	    elseif z == 4 then
            if HandVerkauf == 0 then
                MoveSetActivity("Owner","carry")
                CarryObject("Owner", "Handheld_Device/ANIM_bookpile.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+9")
                Sleep(3)
            elseif HandVerkauf == 1 then
                MoveSetActivity("Owner","carry")
                CarryObject("Owner", "Handheld_Device/ANIM_Cloth.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+10")
                Sleep(3)
            else
                local Aktion = PlayAnimationNoWait("Owner","use_object_standing")
                Sleep(1)
                CarryObject("Owner", "Handheld_Device/ANIM_Smallsack.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+11")
                Sleep(Aktion-1)
            end
	    elseif z == 5 then
            if HandVerkauf == 0 then
                MoveSetActivity("Owner","carry")
                CarryObject("Owner", "Handheld_Device/ANIM_Bottlebox.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+12")
                Sleep(3)
            elseif HandVerkauf == 1 then
                local Aktion = PlayAnimationNoWait("Owner","use_object_standing")
                Sleep(1)
                CarryObject("Owner", "Handheld_Device/ANIM_Aesculap_Staff.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+13")
                Sleep(Aktion-1)
            else
                local Aktion = PlayAnimationNoWait("Owner","use_object_standing")
                Sleep(1)
                CarryObject("Owner", "Handheld_Device/ANIM_perfumebottle.nif", false)
                MsgSay("Owner","_HPFZ_HANDEL_ANTWORT_+14")
                Sleep(Aktion-1)
            end
		end
	end
    MoveSetActivity("")
	CarryObject("", "", false)
	CarryObject("", "", true)
end

function CleanUp()
    CarryObject("Owner", "", false)
    MoveSetActivity("Owner")
   	CarryObject("", "", false)
	CarryObject("", "", true)
    MoveSetActivity("")
end
