-- Motivation: I'm broke, gotta sell
function Weight()
	-- colored dynasties will not sell
	if not DynastyIsShadow("dynasty") then
		return 0
	end
	
	if not ReadyToRepeat("dynasty", "BasicAI_SellShop") then
		return 0
	end

	if GetMoney("dynasty") >= 0 then
		return 0
	end

	if not DynastyGetRandomBuilding("dynasty", GL_BUILDING_CLASS_WORKSHOP, -1, "sd_Workshop") then
		return 0
	end
	
	return 2
end

function Execute()
	SetRepeatTimer("dynasty", "BasicAI_SellShop", 12)
	BuildingSetForSale("sd_Workshop", true)
	SetState("sd_Workshop", STATE_SELLFLAG, true)
end

