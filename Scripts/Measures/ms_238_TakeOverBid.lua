-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_TakeOverBid.lua"
----
----	with this measure, the player can force shadow AIs to sell their buildings
----
-------------------------------------------------------------------------------
function Run()
	
	-- Make some checks
	
	if HasProperty("", "PlunderInProgress") then
		return
	end
	
	if BuildingGetClass("") == GL_BUILDING_CLASS_WORKSHOP then
		if not CanBuildWorkshop("dynasty") then
			MsgQuick("dynasty", "@L_GENERAL_MEASURES_FAILURES_+24", GetMaxWorkshopCount("dynasty"))
			return
		end
	end
		
	if BuildingGetType("") == GL_BUILDING_TYPE_ESTATE then
		local BossID = dyn_GetValidMember("dynasty")
		GetAliasByID(BossID, "boss")
		if GetNobilityTitle("boss") < 8 then -- min title to own an estate
			MsgQuick("dynasty", "@L_GENERAL_BUILDING_CASTLE_FAILURE_+0")
			return
		else
			local	Count = DynastyGetBuildingCount2("dynasty")
			for l=0, Count-1 do
				if DynastyGetBuilding2("dynasty", l, "Check") then
					if BuildingGetType("Check") == GL_BUILDING_TYPE_ESTATE then -- only can own one estate
						MsgQuick("dynasty", "@L_GENERAL_BUILDING_CASTLE_FAILURE_+1")
						return
					end
				end
			end
		end
	end
	
	-- Find a new possible owner 
	
	if not AliasExists("Destination") then 
	
		local Class	= BuildingGetCharacterClass("")
		local Count = DynastyGetMemberCount("dynasty")
		local	Number = 0

		for Number=0, Count-1 do
			if DynastyGetMember("dynasty", Number, "Member") then
				if Class == GL_CLASS_NONE or Class == SimGetClass("Member") then
					if BuildingCanBeOwnedBy("", "Member") then
						CopyAlias("Member", "Destination")
						break;
					end
				end
			end
		end
	end
	
	-- no possible owner found, error
	
	if not AliasExists("Destination") then
		MsgBoxNoWait("dynasty", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_GENERAL_MEASURES_071_BUYBUILDING_FAILURES_+0", GetID(""))
		return
	end

	-- get former owner
	if not BuildingGetOwner("", "FormerOwner") then
		return
	end
	
	-- no takeover-bid for players
	if DynastyIsPlayer("FormerOwner") then
		MsgBoxNoWait("Destination", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURE_TAKEOVERBID_ERROR_PLAYER_+0")
		return
	end
	
	-- no takeover-bid for coloured Dynasty
	if not DynastyIsShadow("FormerOwner") then
		MsgBoxNoWait("Destination", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURE_TAKEOVERBID_ERROR_AI_+0")
		return
	end
	
	-- ask the question
	local Value = BuildingGetValue("")
	local Result = MsgNews("Destination", "", "@P"..
					"@B[1,@L_REPLACEMENTS_BUTTONS_JA_+0]"..
					"@B[C,@L_REPLACEMENTS_BUTTONS_NEIN_+0]",
					ms_takeoverbid_AIDecision,  --AIFunc
					"building", --MessageClass
					-1, --TimeOut
					"@L_MEASURE_TAKEOVERBID_QUESTION_HEAD_+0",
					"@L_MEASURE_TAKEOVERBID_QUESTION_BODY_+0",
					GetID(""), GetID("FormerOwner"), Value)
					
	if Result == "C" then
		return
	else
		local Money = GetMoney("FormerOwner")
		local Intimidation = 0
		if HasProperty("FormerOwner", "intimidated") then
			if GetProperty("FormerOwner","intimidated") == GetID("dynasty") then
				Intimidation = 1
			end
		end
		
		-- Reaction  from owner depending on favor
		if GetFavorToDynasty("dynasty", "FormerOwner") > 30 then
			-- nice reaction
			if SimGetOfficeLevel("FormerOwner") > 0 then
				-- I'm into politics, i don't sell
				MsgBoxNoWait("Destination","FormerOwner","@L_MEASURE_TAKEOVERBID_QUESTION_HEAD_+0",
							"@L_MEASURE_TAKEOVERBID_DECLINE_NICE_POLITICS_+0", GetID("FormerOwner"), 
							GetID(""))
				StopMeasure()
			elseif Money >= 100000 and Intimidation == 0 then
				-- i am rich, i don't need your money.
				MsgBoxNoWait("Destination","FormerOwner","@L_MEASURE_TAKEOVERBID_QUESTION_HEAD_+0",
							"@L_MEASURE_TAKEOVERBID_DECLINE_NICE_MONEY_+0", GetID("FormerOwner"), 
							GetID(""))
				StopMeasure()
			elseif Money >= 100000 and Intimidation == 1 then
				-- i am rich, but you broke my legs so i will sell for high money
				Value = Value*4
				local Result2 = MsgNews("Destination", "FormerOwner", "@P"..
									"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
									"@B[C,@L_MEASURE_TAKEOVERBID_BUTTON_NO_+0]",
									ms_takeoverbid_AIDecision,  --AIFunc
									"building", --MessageClass
									-1, --TimeOut
									"@L_MEASURE_TAKEOVERBID_QUESTION_HEAD_+0",
									"@L_MEASURE_TAKEOVERBID_INTERESTED_SCARED_+0",
									GetID("FormerOwner"), GetID(""), Value)
				if Result2 == "C" then
					StopMeasure()
				else
					ms_238_takeoverbid_BuyIt("Destination", "FormerOwner", Value)
				end
				
			elseif Intimidation == 1 then
				Value = Value*2
				-- you broke my legs and i need the money
				local Result5 = MsgNews("Destination", "FormerOwner", "@P"..
									"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
									"@B[C,@L_MEASURE_TAKEOVERBID_BUTTON_NO_+0]",
									ms_takeoverbid_AIDecision,  --AIFunc
									"building", --MessageClass
									-1, --TimeOut
									"@L_MEASURE_TAKEOVERBID_QUESTION_HEAD_+0",
									"@L_MEASURE_TAKEOVERBID_INTERESTED_SCARED_+0",
									GetID("FormerOwner"), GetID(""), Value)
									
				if Result5 == "C" then
					StopMeasure()
				else
					ms_238_takeoverbid_BuyIt("Destination", "FormerOwner", Value)
				end
			else
				-- i will sell for a fair price
				Value = Value*3
				local Result3 = MsgNews("Destination", "FormerOwner", "@P"..
									"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
									"@B[C,@L_MEASURE_TAKEOVERBID_BUTTON_NO_+0]",
									ms_takeoverbid_AIDecision,  --AIFunc
									"building", --MessageClass
									-1, --TimeOut
									"@L_MEASURE_TAKEOVERBID_QUESTION_HEAD_+0",
									"@L_MEASURE_TAKEOVERBID_INTERESTED_NICE_+0",
									GetID("FormerOwner"), GetID(""), Value)
									
				if Result3 == "C" then
					StopMeasure()
				else
					ms_238_takeoverbid_BuyIt("Destination", "FormerOwner", Value)
				end
			end
		else
			-- angry reaction
			if Intimidation ==1 then
				-- you broke my legs but i don't like you, so i will sell for a high price
				Value = Value*4
				local Result4 = MsgNews("Destination", "FormerOwner", "@P"..
									"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
									"@B[C,@L_MEASURE_TAKEOVERBID_BUTTON_NO_+0]",
									ms_takeoverbid_AIDecision,  --AIFunc
									"building", --MessageClass
									-1, --TimeOut
									"@L_MEASURE_TAKEOVERBID_QUESTION_HEAD_+0",
									"@L_MEASURE_TAKEOVERBID_INTERESTED_SCARED_+0",
									GetID("FormerOwner"), GetID(""), Value)
					
				if Result4 == "C" then
					StopMeasure()
				else
					ms_238_takeoverbid_BuyIt("Destination", "FormerOwner", Value)
				end
			elseif SimGetOfficeLevel("FormerOwner")>0 then
				-- I'm into politics, i don't sell
				MsgBoxNoWait("Destination", "FormerOwner", "@L_MEASURE_TAKEOVERBID_QUESTION_HEAD_+0",
							"@L_MEASURE_TAKEOVERBID_DECLINE_ANGRY_POLITICS_+0", GetID("FormerOwner"), 
							GetID(""))
				StopMeasure()
			else
				-- i hate you, i will never sell to you!
				MsgBoxNoWait("Destination", "FormerOwner", "@L_MEASURE_TAKEOVERBID_QUESTION_HEAD_+0",
							"@L_MEASURE_TAKEOVERBID_DECLINE_ANGRY_MAIN_+0", GetID("FormerOwner"), 
							GetID(""))
				StopMeasure()
			end
		end
	end
end

function BuyIt(NewOwner, FormerOwner, Money)
	if GetMoney(NewOwner) < Money then -- not enough money?
		MsgBoxNoWait(NewOwner, "", "@L_GENERAL_ERROR_HEAD_+0", "@L_GENERAL_MEASURES_071_BUYBUILDING_FAILURES_+1", Money, GetID("")) 
		StopMeasure()
	else
		if not BuildingBuy("Owner", NewOwner, BM_CAPTURE) then
			MsgBoxNoWait(NewOwner, "", "@L_GENERAL_ERROR_HEAD_+0", "@L_GENERAL_MEASURES_071_BUYBUILDING_FAILURES_+2", GetID(NewOwner), GetID(""))
			return
		else 
			PlaySound("fanfare/FanfarPositiveShort_s_01.ogg", 0.4, 1, "c4")
			chr_SpendMoney(NewOwner, Money, "BuildingBought")
			CreditMoney(FormerOwner, Money, "BuildingSold")
						
			if HasProperty(FormerOwner, "intimidated") then
				RemoveProperty(FormerOwner, "intimidated")
			end
			
			bld_ClearBuildingStash("", "FormerOwner") -- get credit money back
			-- XXX force former workers to stop working
			--bld_BuildingWorkersStopWorking("Destination") 
		end
	end
end

function AIDecision()
	return "O"
end
