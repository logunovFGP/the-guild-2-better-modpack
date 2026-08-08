function Run()
end

function OnLevelUp()
	church_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	church_SetupAI("")
	bld_HandleSetup("")
	-- create ambient animals
	if Rand(2) == 0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
end

function PingHour()
	local currentGameTime = math.mod(GetGametime(), 24)
	if (currentGameTime == 12) then
		PlaySound3D("", "locations/bell_stroke_church_loop+0.wav", 2.0)
		Sleep(2)
		PlaySound3D("", "locations/bell_stroke_church_loop+0.wav", 2.0)
	elseif (currentGameTime == 18) then
		PlaySound3D("", "locations/bell_stroke_church_loop+0.wav", 2.0)
		Sleep(2)
		PlaySound3D("", "locations/bell_stroke_church_loop+0.wav", 2.0)
	end
	
	bld_HandlePingHour("", true)
end

function SetNeed(InvAlias, ItemId, Value)
	if (GetProperty(InvAlias, "NeedLock_"..ItemId) or 0) ~= 0 then
		return
	end
	if Value then
		SetProperty(InvAlias, "Need_"..ItemId, Value)
	else
		RemoveProperty(InvAlias, "Need_"..ItemId)
	end
end

function SetGood(ItemId, Counter, Stock)
	church_SetNeed("NeedSell", ItemId, Counter)
	church_SetNeed("NeedStd", ItemId, Stock)
end

function SetupAI(Alias)
	local Level = BuildingGetLevel(Alias)
	if Level < 1 then
		return
	end
	if not GetInventory(Alias, INVENTORY_STD, "NeedStd") then
		return
	end
	if not GetInventory(Alias, INVENTORY_SELL, "NeedSell") then
		return
	end

	church_SetGood(GL_ITEM_PARCHMENT, -1, 12)	-- Parchment [160]
	church_SetGood(GL_ITEM_HOLYWATER, -1, 30)	-- Holy water [161]
	church_SetGood(GL_ITEM_HOUSEL, 10, 40)	-- Host [162]
	church_SetGood(GL_ITEM_POEM, nil, nil)	-- Poem [163]

	if Level >= 2 then
		church_SetGood(GL_ITEM_CHAPLET, nil, nil)	-- Rosary [164]
		church_SetGood(GL_ITEM_ABOUTTALENTS1, nil, nil)	-- About Talents I [165]
		church_SetGood(GL_ITEM_THESISPAPER, nil, nil)	-- Thesis paper [168]
	end

	if Level >= 3 then
		church_SetGood(GL_ITEM_LETTEROFINDULGENCE, nil, nil)	-- Letter of indulgence [166]
		church_SetGood(GL_ITEM_LETTERFROMROME, nil, nil)	-- Letter from Rome [167]
		church_SetGood(GL_ITEM_ABOUTTALENTS2, nil, nil)	-- About Talents II [169]
		church_SetGood(GL_ITEM_HASSTIRADE, nil, nil)	-- Torrent of Hatred [900]
		church_SetGood(GL_ITEM_HANDWERKSURKUNDE, nil, nil)	-- Certificate of Tradesmanship [901]
	end
end
