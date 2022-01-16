-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_127_GetDivorced"
----
----	with this measure the player can divorce from the spouse
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
	
	-- Get the spouse
	if not SimGetSpouse("", "Spouse") then
		return
	end

	-- Perhaps the spouse is just following me
	if HasProperty("Spouse", "Follows") then
		if GetID("") == GetProperty("Spouse", "Follows") then
			SimStopMeasure("Spouse")
		end
	end	
	
	-- Go to the spouse
	if not ai_StartInteraction("", "Spouse", 800, 128) then
		return false
	end

	----------
	-- Divorce
	----------
	
	local Wealth = SimGetWealth("")
	local LooseMoney = math.ceil(Wealth*0.05)
	
	local result = MsgNews("", 0, "@B[A, @L_REPLACEMENTS_BUTTONS_JA]@B[C, @L_REPLACEMENTS_BUTTONS_NEIN]@P",  
					ms_127_getdivorced_AIDecide, "default", -1, "@L_GENERAL_MEASURES_GETDIVORCED_HEAD_+0", 
					"@L_GENERAL_MEASURES_GETDIVORCED_BODY_+0", GetID("Spouse"), LooseMoney)
	
	if (result ~= "A") then
		return false
	end
	
	
	MsgSay("", "@L_FAMILY_5_DIVORCE_TALK_1", GetID("Spouse"))
	MsgSay("Spouse", "@L_FAMILY_5_DIVORCE_TALK_2")
	MsgSay("", "@L_FAMILY_5_DIVORCE_TALK_3")	
	
	
	
	-- Massive favor loss from the ex-spouse
	local FavorLossPercent = GL_PERCENT_FAVOR_LOSS_AFTER_DIVORCE
	local CurrentFavor = GetFavorToSim("Spouse", "")
	local Factor = (100 - FavorLossPercent) * 0.01
	SetFavorToSim("Spouse", "", Factor * CurrentFavor)
	
	-- Ex spouse gets compensation
	chr_SpendMoney("", LooseMoney, "CostBribes")
	-- Ex-spouse leaves the building
	f_ExitCurrentBuilding("Spouse")

	SimGetDivorced("", "Spouse")
	
end

function CleanUp()
end

function AIDecide()
	return "A"
end


