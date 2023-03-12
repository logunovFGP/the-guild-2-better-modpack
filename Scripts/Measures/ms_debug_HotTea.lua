function Run()
	GetHomeBuilding("","myhome")
	BuildingGetCity("myhome","city")

	local Target = ""
	if AliasExists("Destination") then
		Target = "Destination"
	end
	
	local MySim = ms_debug_hottea_GetName("")
	local TargetSim = ms_debug_hottea_GetName("Destination")
	local MsgBody = MySim .. "$N$N" .. TargetSim
	local Panel = "@P" .. "@B[1," .. MySim .. ",]" .. "@B[2," .. TargetSim .. ",]" 
	
	-- start dialog to select target or destination
	local TargetChoice = MsgBox("", Target, 
					Panel,
					"Confirm Selection",
					MsgBody)
	
	if TargetChoice and TargetChoice ~= "C" then
		-- irrelevant for now
	end
	
	local result = InitData("@P"..
	"@B[1,@L%1l,@L%1l,Hud/Buttons/btn_playtarot.tga]"..
	"@B[2,@L%2l,@L%2l,Hud/Items/Item_AldermanChain.tga]"..
	"@B[3,@L%3l,@L%3l,Hud/Items/item_diamanten.tga]"..
	"@B[4,@L%4l,@L%4l,Hud/Items/Item_Stonerotary.tga]"..
	"@B[5,@L%5l,@L%5l,Hud/Items/Item_goldhigh.tga]"..
	"@B[6,@L%6l,@L%6l,Hud/Items/Item_Empfehlung.tga]"..
	"@B[7,@L%7l,@L%7l,Hud/Items/Item_MiracleCure.tga]"..
	"@B[8,@L%8l,@L%8l,Hud/Items/Item_HexerdokumentII.tga]"..
	"@B[9,@L%9l,@L%9l,]",
	-1,
	"@L_MEASURE_HotTea_TITLE_+0","",
	"Immortality","Title","Office","XP","Money","Fame","Age","AI", "Special")

	if result==1 then
		if SimIsMortal(Target) then
			SimSetMortal(Target, false)
			MsgQuick("", "Ahh, the power! I feel immortal!",GetID(Target))
		else
			SimSetMortal(Target, true)
			MsgQuick("", "Lieber ein sterbliches Leben mit dir, als die Ewigkeit ohne dich!",GetID(Target))
		end
 
	elseif result==2 then
		if GetNobilityTitle(Target)<7 then
			SetNobilityTitle(Target, 7, true)
		end
	
	elseif result==3 then
		GetHomeBuilding(Target,"myhome")
		BuildingGetCity("myhome","city")
		local citylvl = CityGetLevel("city")
		local highestlvl = CityGetHighestOfficeLevel("city")
		CityGetOffice("city", highestlvl, 0, "office")
		SimSetOffice(Target, "office")
	elseif result==4 then
		chr_GainXP(Target,4000)
		MsgQuick("", "Ach, sag das doch gleich!",GetID(Target))
		LogMessage("1 < 2 but "..result.."2 > 1")
		LogMessage("3 %< 4 but "..result.."5 %> 3")
		LogMessage("1 < 2 but ".."2 > 1")
		LogMessage("3 %< 4 but ".."5 %> 3")
	elseif result==5 then
		CreditMoney(Target, 120000, "HotTea")
		MsgQuick("", "Geld, Geld, Geld!")
	elseif result==6 then
		chr_SimAddFame(Target,25)
		chr_SimAddImperialFame(Target,25)
	elseif result==7 then
		local Text = helpfuncs_MsgString("", "Change age", "Please choose the new age for %1SN.", {GetID(Target)})
		local NewAge = Text + 0
		SimSetAge(Target, NewAge)
	elseif result == 8 then
		local freeze = MsgBox("","Owner",
				"@P@B[1,@L%1l,]@B[0,@L%2l,]",
				"AIs-Zeit","AI einfrieren?", "Ja", "Nein")
		if freeze == 1 then
			ScenarioPauseAI(true)
		elseif freeze == 0 then
			ScenarioPauseAI(false)
		end
	elseif result == 9 then
		GetPosition(Target, "Pos")
--		GfxAttachObject("crowdedlocator", "city/Stuff/tradetable.nif")
		--GfxAttachObject("crowdedlocator", "city/statues/fabianthegolden.nif")
	  --GfxSetPositionTo("crowdedlocator", "Pos")	
--		GfxStartParticle("crowdedlocator", "particles/Campfire2.nif", "Pos", 10.0)
		for i=0, 50 do
			RemoveAlias("Pos")
			if GetOutdoorLocator("Crowded"..i, 1, "Pos") and AliasExists("Pos") then
				local x, y, z = PositionGetVector("Pos")
				LogMessage("Smoke at Crowded"..i..": "..x..", "..y..", "..z)
				StartSingleShotParticle("particles/Explosion.nif", "Pos", 4,50)
--				GfxAttachObject("crowdedlocator"..i, "city/Stuff/tradetable.nif")
--		  	GfxSetPositionTo("crowdedlocator"..i, "Pos")	
			end
		end
--		local Count = GetOutdoorLocator("Crowded", 50, "Pos")
--		for i=0,Count-1 do
--			LogMessage("Smoke at Crowded"..i)
--			GfxAttachObject("crowdedlocator"..i, "city/freierhandler.nif")
--		  GfxSetPositionTo("crowdedlocator"..i, "Pos"..i)	
--			GfxStartParticle("crowdedlocator"..i, "particles/smoke_medium.nif", "Pos"..i, 10)
--		end
	end
end

function GetName(SimAlias, WithFlag)
	if not AliasExists(SimAlias) then
		return ""
	end

	if WithFlag and GetDynasty(SimAlias, "DynAliasForFlag") then
		local MyFlag = DynastyGetFlagNumber("DynAliasForFlag") + 29
		return "$S[20" .. MyFlag .. "] " .. GetName(SimAlias)
	else 
		return GetName(SimAlias)
	end
end

function PrintRequiredItems(BldId)
	local ItemsString = GetDatabaseValue("BuildingToItems", BldId, "produceditems")
	local ProducedItems = {}
	local ProducedItemsCount = 0
	for Id in string.gfind(ItemsString, "%d+") do
		ProducedItemsCount = ProducedItemsCount + 1
		ProducedItems[ProducedItemsCount] = ItemGetID(Id)
	end
	
	local RequiredItems = {}
	local RequiredItemsBaseUsages = {}
	local RequiredItemsCount = 0
	
	local ItemId, Manufacturer
	local Amount, Buildtime
	for i=1, ProducedItemsCount do
		ItemId = ProducedItems[i]
		Buildtime = GetDatabaseValue("Items", ItemId, "buildtime")
		for j=1, 3 do 
			local Prod = GetDatabaseValue("Items", ItemId, "prod"..j) 
			Manufacturer = GetDatabaseValue("Items", Prod , "manufacturer")
			-- if Prod is empty or produced by same building, ignore it 
			if Prod and Prod > 0 and BldId ~= Manufacturer then
				Amount = GetDatabaseValue("Items", ItemId, "nr"..j)
				-- only add prod if it isn't in the list yet, otherwise increase usage
				local IndexOfProd =	hottea_IndexOf(RequiredItems, RequiredItemsCount, Prod)
				if not IndexOfProd then 
					RequiredItemsCount = RequiredItemsCount + 1
					IndexOfProd = RequiredItemsCount
					RequiredItems[IndexOfProd] = Prod
					RequiredItemsBaseUsages[IndexOfProd] = 0
					--LogMessage(ItemGetLabel(Prod, false))
				end
				-- base usage is defined as the maximum of units of this items that can be used up by one worker in 8 hours 
				RequiredItemsBaseUsages[IndexOfProd] = math.max(math.ceil(8/Buildtime) * Amount, RequiredItemsBaseUsages[IndexOfProd])				
			end
		end
	end
	-- 100  "Farm1"  4                 "1   2   4   5"                                         | 
	local DbEntry = BldId .. "   "
	DbEntry = DbEntry .. "\"" .. GetDatabaseValue("BuildingToItems", BldId, "name") .. "\"   "
	DbEntry = DbEntry .. "\"" .. GetDatabaseValue("BuildingToItems", BldId, "produceditems") .. "\"   "
	DbEntry = DbEntry .. "\"" .. helpfuncs_IdListToString(RequiredItems, RequiredItemsCount) .. "\"   \"" .. helpfuncs_IdListToString(RequiredItemsBaseUsages, RequiredItemsCount) .. "\"   |"
	LogMessage(DbEntry)
end

function IndexOf(List, ListSize, Item)
	for x=1, ListSize do
		if List[x] and List[x] == Item then
			return x
		end
	end
	return nil
end

function CleanUp()
	SetState("", STATE_LOCKED, false)
end