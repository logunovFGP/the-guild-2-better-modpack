function Run()
end

function OnLevelUp()
	alchimist_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	alchimist_SetupAI("")
	bld_HandleSetup("")
	-- create ambient animals
	if Rand(2) == 0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
end

function PingHour()
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
	alchimist_SetNeed("NeedSell", ItemId, Counter)
	alchimist_SetNeed("NeedStd", ItemId, Stock)
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

	alchimist_SetGood(GL_ITEM_LAVENDER, nil, 20)	-- Lavender [120]
	alchimist_SetGood(GL_ITEM_BLACKBERRY, nil, 20)	-- Blackberry [121]
	alchimist_SetGood(GL_ITEM_HERBTEA, nil, nil)	-- Herb tea [123]
	alchimist_SetGood(GL_ITEM_DYE, nil, nil)	-- Plant Colourant [967]

	if Level >= 2 then
		alchimist_SetGood(GL_ITEM_MOONFLOWER, nil, 20)	-- Moon flower [122]
		alchimist_SetGood(GL_ITEM_PERFUME, nil, nil)	-- Perfume [126]
		alchimist_SetGood(GL_ITEM_DARTAGNANSFRAGRANCE, nil, nil)	-- Dartagnan's scent [127]
		alchimist_SetGood(GL_ITEM_FROGEYE, nil, 8)	-- Toad eye [131]
		alchimist_SetGood(GL_ITEM_FLOWEROFDISCORD, nil, nil)	-- Flower of discord [132]
		alchimist_SetGood(GL_ITEM_TOADEXCREMENTS, nil, nil)	-- Toad excrement [133]
		alchimist_SetGood(GL_ITEM_BOOBYTRAP, nil, nil)	-- Booby trap [139]
		alchimist_SetGood(GL_ITEM_WEAPONPOISON, nil, nil)	-- Weapon Poison [562]
		alchimist_SetGood(GL_ITEM_ANTIDOTE, nil, nil)	-- Antidote [563]
	end

	if Level >= 3 then
		alchimist_SetGood(GL_ITEM_STONELILY, nil, 10)	-- Rock lily [128]
		alchimist_SetGood(GL_ITEM_DRFAUSTUSELIXIR, nil, nil)	-- Faust's elixir [129]
		alchimist_SetGood(GL_ITEM_FRAGRANCEOFHOLINESS, nil, nil)	-- Sacred scent [130]
		alchimist_SetGood(GL_ITEM_SPIDERLEG, nil, 10)	-- Spider leg [134]
		alchimist_SetGood(GL_ITEM_TOADSLIME, nil, nil)	-- Toad slime [135]
		alchimist_SetGood(GL_ITEM_PARALYSISPOISON, nil, nil)	-- Paralysis Poison [564]
		alchimist_SetGood(GL_ITEM_BLACKWIDOWPOISON, nil, nil)	-- Black Widow Poison [565]
	end
end
