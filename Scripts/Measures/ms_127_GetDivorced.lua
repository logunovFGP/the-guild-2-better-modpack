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
	
	local Cost = chr_GetBribeAmount("")
	
	local result = MsgNews("", 0, "@B[A, @L_REPLACEMENTS_BUTTONS_JA]@B[C, @L_REPLACEMENTS_BUTTONS_NEIN]@P",  
					ms_127_GetDivorced_AI, "default", -1, "@L_GENERAL_MEASURES_GETDIVORCED_HEAD_+0", 
					"@L_GENERAL_MEASURES_GETDIVORCED_BODY_+0", GetID("Spouse"), Cost)
	
	if (result ~= "A") then
		return false
	end
	
	
	MsgSay("", "@L_FAMILY_5_DIVORCE_TALK_1", GetID("Spouse"))
	MsgSay("Spouse", "@L_FAMILY_5_DIVORCE_TALK_2")
	MsgSay("", "@L_FAMILY_5_DIVORCE_TALK_3")	
	
	chr_SpendMoney("", Cost, "CostSocial")
	-- Ex-spouse leaves the building
	f_ExitCurrentBuilding("Spouse")
		
	-- change alliance status
	local OldDyn = GetProperty("Spouse", "FamilyID") or 0
	if OldDyn > 0 then
		if GetAliasByID(OldDyn, "OldFamily") then
			local CurrentState = DynastyGetDiplomacyState("", "OldFamily")
			if CurrentState > DIP_NEUTRAL then
				-- set the new status and favor here
				DynastySetMinDiplomacyState("", "OldFamily", DIP_FOE, GetID(""), 12)
				DynastySetDiplomacyState("", "OldFamily", DIP_NEUTRAL)
				DynastyForceCalcDiplomacy("")
				
				if GetFavorToDynasty("", "OldFamily") > 50 then
					SetFavorToDynasty("", "OldFamily", 50)
				end
				
				if CurrentState == DIP_ALLIANCE then
					dyn_RemoveAlly("", "OldFamily")
				end
			end
		end
	end
	
	SimGetDivorced("", "Spouse")
end

function CleanUp()
end

function ms_GetDivorced_AI()
	return "A"
end


