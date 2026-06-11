-- Motivation: I'm broke, gotta sell
function Weight()
	if not ReadyToRepeat("dynasty", "BasicAI_SellShop") then
		return 0
	end

	local Money = GetMoney("dynasty")

	-- shadows sell as soon as they are in the red; colored dynasties only as
	-- a last resort when deep in debt (previously they never sold and just
	-- stayed bankrupt)
	if DynastyIsShadow("dynasty") then
		if Money >= 0 then
			return 0
		end
	elseif Money >= -5000 then
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

