-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching 
end

function SimGetFameLevel(SimAlias)

	local fame = 0

	if AliasExists(SimAlias) then
		if GetProperty(SimAlias,"Fame") then
			fame = GetProperty(SimAlias,"Fame")
		end
	end

	if fame == 0 then
		return 0
	elseif fame < 6 then
		return 1
	elseif fame < 11 then
		return 2
	elseif fame < 16 then
		return 3
	elseif fame < 21 then
		return 4
	else
		return 5
	end

end

-- ----------- 
-- MoveToExact
-- -----------
function MoveToExact(MoverAlias, DestinationAlias, Movespeed, Range)
	
	-- Get the current exact distance
	local Distance = CalcDistance(MoverAlias, DestinationAlias)
	
	-- Check if the sim is not already there
	if (Range < Distance) then
	
		-- Move to the destination until the offset position is reached and get the new distance
		f_MoveTo(MoverAlias, DestinationAlias, Movespeed, Range)
		
		-- Get the new exact distance
		Distance = CalcDistance(MoverAlias, DestinationAlias)
		
	end
	
	-- Get the direction from the mover to the destination
	local DirX = 0
	local DirY = 0
	local DirZ = 0
	DirX, DirY, DirZ = GetDirectionTo(MoverAlias, DestinationAlias)
	
	-- Calculate the last step distance
	local LastStepLength = Distance - Range
	
	-- Move the last step
	GfxMoveToPosition(MoverAlias, DirX * LastStepLength, DirY * LastStepLength, DirZ * LastStepLength, 1, false)
	
	local Error = CalcDistance(MoverAlias, DestinationAlias) - Range
	
end

-- -------------
-- StopFollowing
-- -------------
function StopFollowing(Follower, Followed)
	if HasProperty(Follower, "Follows") then
		if GetID(Followed) == GetProperty(Follower, "Follows") then
			SimStopMeasure(Follower)
		end
	end
end

-- ----------
-- AlignExact
-- ----------
function AlignExact(MoverAlias, DestinationAlias, Range, Duration)
	Duration = Duration or 1

	-- Get the current exact distance
	local Distance = CalcDistance(MoverAlias, DestinationAlias)
	
	-- Get the direction from the mover to the destination
	local DirX = 0
	local DirY = 0
	local DirZ = 0
	DirX, DirY, DirZ = GetDirectionTo(DestinationAlias, MoverAlias)
	
	-- Calculate the last step distance
	local LastStepLength = Distance - Range
	
	-- Get the terrain-height of the sims
	local tempx = 0
	local tempz = 0
	local HeightMover = 0
	local HeightDest = 0

	GetPosition(MoverAlias, "MoverPos")
	tempx, HeightMover, tempz = PositionGetVector("MoverPos")

	GetPosition(DestinationAlias, "DestinationPos")
	tempx, HeightDest, tempz = PositionGetVector("DestinationPos")

	local HeightComm = (HeightMover + HeightDest) * 0.5
	local MovMover = HeightComm - HeightMover
	local MovDest = HeightComm - HeightDest
	
	-- Prevent BJ-Bug
	GfxMoveToPositionNoWait(MoverAlias, 0, MovMover, 0, 1, false)
	GfxMoveToPosition(DestinationAlias, 0, MovDest, 0, 1, false)
	
	-- Move the last step
	GfxMoveToPosition(DestinationAlias, DirX * LastStepLength, DirY * LastStepLength, DirZ * LastStepLength, 1, false)
	
	local Error = CalcDistance(MoverAlias, DestinationAlias) - Range
	
end

-- -----------------------
-- GetTradeBonus
-- -----------------------
function GetTradeBonus(BuyerAlias, HowMuch)
	LogMessage("GetTradeBonus is called")
--	local Chance = 3 * GetSkillValue(BuyerAlias, BARGAINING)
	
--	if(IsDynastySim(BuyerAlias)) then
--		Chance = Chance + 20
--	end
	
--	if(Chance > Rand(199)) then	
--		local Bonus = 0.0025 * HowMuch * (4 * GetSkillValue(BuyerAlias, RHETORIC) + 100 - SimGetAlignment(BuyerAlias))		
--		return Bonus	
--	end
end

-- -----------------------
-- SetOfficeImpactList
-- -----------------------
function SetOfficeImpactList( Office, ... )
	for i=1,arg.n,1 do
		local blubb = arg[i]
		AddObjectDependendImpact("", GetID(Office), blubb, 1)
	end
end

-- -----------------------
-- SetNobilityImpactList
-- -----------------------
function SetNobilityImpactList(TitleHolder, ... )
	for i=1, arg.n, 1 do
		local element = arg[i]
		if element ~= "" then
			AddImpact(TitleHolder, element, 1, -1)
		end
	end
end

-- -----------------------
-- RemoveNobilityImpactList
-- -----------------------
function RemoveNobilityImpactList(TitleHolder, ... )
	
	for i = 1, arg.n, 1 do
		local element = arg[i]
		if element ~= "" then
			RemoveImpact(TitleHolder, element)
		end
	end
end

-- -----------------------
-- GeneratePrivilegeListLabels
-- -----------------------
function GeneratePrivilegeListLabels(... )
	
	local Labels  = {}
	for k=0, 20 do
		Labels[k] = ""
	end
	
	local Counter = 0
	
	for i=1, arg.n,1 do
		local element = arg[i]
		if element ~= "" then
			Labels[Counter] = "_PRIVILEGE_"..arg[i].."_MESSAGETEXT_+0"
			Labels[Counter+1] = "$N"
			Counter = Counter + 2
		end
	end
	
	-- quick'n dirty
	return Labels[0], Labels[1], Labels[2], Labels[3], Labels[4], Labels[5], Labels[6], Labels[7], Labels[8], Labels[9], Labels[10], Labels[11], Labels[12], Labels[13], Labels[14], Labels[15], Labels[16], Labels[17], Labels[18], Labels[19], Labels[20]
end

-- -----------------------
-- Compute Secret Knowledge
-- -----------------------
function ArtifactsDuration(User, duration)
	local Value = GetSkillValue(User, SECRET_KNOWLEDGE)
	if Value <= 1 then
		return 0
	else
		return ((Value/20)*duration)
	end
end

-- -----------------------
-- RecieveMoney 
-- -----------------------
function RecieveMoney(ObjectAlias, val, topic)
	chr_CreditMoney(ObjectAlias, val, topic)
	ShowOverheadSymbol(ObjectAlias, false, false, 0, "@L%1t", val)
	return val
end

-- -----------------------
-- ModifyFavor
-- Value uses GameConstants (global constant FAVOR_MOD_ +++)
-- Value uses diplomacy or title for additional modification
-- -----------------------
function ModifyFavor(source, dest, val)
	
	local SourceTitle = 0
	local DestinationTitle = 0
	
	if IsDynastySim(source) and IsDynastySim(dest) and GetDynastyID(source) > 0 and GetDynastyID(dest) > 0 then
		local Diplo = DynastyGetDiplomacyState(source, dest)
		
		if Diplo == DIP_ALLIANCE and val < 0 then
		-- harder to lose if you are friends
			val = math.floor(val / 2)
		elseif Diplo == DIP_FOE and val > 0 then
		-- harder to gain if you are enemies
			val = math.floor(val / 2)
		else
			-- check title-difference
			SourceTitle = 0 + GetNobilityTitle(source)
			DestinationTitle = 0 + GetNobilityTitle(dest)
			
			if val > 0 then
			-- harder to gain favor
				if (SourceTitle + 2) < DestinationTitle then
					val = math.floor(val / 2)
					if (SourceTitle + 4) < DestinationTitle then
						val = math.floor(val / 2)
					end
				end
			else
			-- easier to lose favor
				if (SourceTitle + 2) < DestinationTitle then
					val = math.floor(val*1.5)
					if (SourceTitle + 4) < DestinationTitle then
						val = math.floor(val*1.5)
					end
				end
			end
		end
			
		-- grudge and fondness
		if GetDynasty(source, "MyDyn") then
			local TargetID = GetDynastyID(dest)
			if HasProperty("MyDyn", "Grudge"..TargetID) then
				-- grudges reduce positive favor and raise losts
				val = math.ceil(val - (GetProperty("MyDyn", "Grudge"..TargetID))*1.5)
			elseif HasProperty("MyDyn", "Fondness"..TargetID) then
				-- fondness makes your bond stronger
				val = math.floor(val + (GetProperty("MyDyn", "Fondness"..TargetID))*1.5)
			end
		end
	end
	
	-- lose only 50 percent favor if you have rattle the chains impact
	if GetImpactValue(dest, "RattleTheChains") == 1 and val < 0 then
		val = math.floor(val / 2)
	end
	
	-- Infamous ability
	local MyInfamousLevel = GetImpactValue(source, "InfamousI")
	local YourInfamousLevel = GetImpactValue(dest, "InfamousI")

	if MyInfamousLevel == 1 and SimGetClass(dest) == 4 then
		if val < 0 then
			val = math.floor(val / 2)
			if val > -1 then
				val = -1
			end
		else
			val = val * 2
		end
	elseif YourInfamousLevel == 1 and SimGetClass(source) == 4 then
		if val < 0 then
			val = math.floor(val / 2)
			if val > -1 then
				val = -1
			end
		else
			val = val * 2
		end
	end
	
	
	-- Nice Guy ability
	local MyNiceGuyLevel = GetImpactValue(source, "NiceGuyI")*2
	local YourNiceGuyLevel = GetImpactValue(dest, "NiceGuyI")*2

	if MyNiceGuyLevel > 0 then
		if val > 0 then
			val = val + MyNiceGuyLevel
		elseif val < 0 then
			val = val + MyNiceGuyLevel
			if val > -1 then
				val = -1
			end
		end
	elseif YourNiceGuyLevel > 0 then
		if val > 0 then
			val = val + YourNiceGuyLevel
		elseif val < 0 then
			val = val + YourNiceGuyLevel
			if val > -1 then
				val = -1
			end
		end
	end

	-- Motivator ability
	local MyMotivatorLevel = GetImpactValue(dest, "MotivatorI")
	local YourMotivatorLevel = GetImpactValue(source, "MotivatorI")

	if val < 0 then
		if MyMotivatorLevel > 0 then
			 -- am I your employee?
			if SimGetWorkingPlace(source, "WorkPlace") then
				if BuildingGetOwner("WorkPlace", "MyBoss") and GetID("MyBoss") == GetID(dest) then
					val = val - math.floor(val * (MyMotivatorLevel * 0.5))
					if val > -1 then
						val = -1
					end
				end
			end
		elseif YourMotivatorLevel > 0 then
			 -- Are you my employee?
			if SimGetWorkingPlace(dest, "WorkPlace") then
				if BuildingGetOwner("WorkPlace", "MyBoss") and GetID("MyBoss") == GetID(source) then
					val = val - math.floor(val * (YourMotivatorLevel * 0.5))
					if val > -1 then
						val = -1
					end
				end
			end
		end
	end
	
	-- Grudges + Fondness for Dynasties
	if IsDynastySim(source) and IsDynastySim(dest) then
		if GetDynastyID(source) ~= GetDynastyID(dest) then
			-- add new grudges
			if val <= -20 then
				dyn_AddGrudge(source, dest)
			elseif val >= 20 then
			-- add new fondness
				dyn_AddFondness(source, dest)
			end
		end
	end
	
	ModifyFavorToSim(source, dest, val)

	if DynastyIsPlayer(source) or DynastyIsPlayer(dest) then
		if (val >0) then
			feedback_OverheadSkill(source, "@L$S[2007] +%1n", true, val)
		else
			feedback_OverheadSkill(source, "@L$S[2006] %1n", true, val)
		end
	end
end

-- -----------------------
-- SkillCheck
-- Roll higher than difficulty + enemy talent value
-- -----------------------
function SkillCheck(SimAlias, Skill, Difficulty, DestAlias, DestSkill)
	Difficulty = Difficulty or 0
	local TalentValue = GetSkillValue(SimAlias, Skill) + Rand(3)
	local TalentEnemy = 0
	
	if DestAlias ~= nil and AliasExists(DestAlias) then
		TalentEnemy = GetSkillValue(DestAlias, DestSkill) or 0
	end
	
	local SuccessValue = TalentEnemy + Difficulty
	if SuccessValue <= 0 then
		return true -- don't try to randomize over negative values
	end
	
	if Rand(TalentValue) > Rand(SuccessValue) then
		return true
	else
		return false
	end
end

-- -----------------------
-- GetMaxHaulValue 
-- berechnet den maximalen wert der beute, die ein dieb abhngig von der gebudestufe klauen kann
-- -----------------------

function GetMaxHaulValue(DestAlias, DynastyID, ThiefLevel)

	local BaseValue = BuildingGetPriceProto(BuildingGetProto(DestAlias))
	
	if BaseValue < 1000 then
		return 0
	end
	
	BaseValue = BaseValue * 0.025
	if GetDynastyID(DestAlias) then
		BaseValue = BaseValue * 2
	end
	
	if HasProperty(DestAlias, "ScoutedBy"..DynastyID) then
		BaseValue = BaseValue * 3
	end

	local LootFactor	= ((101 - GetImpactValue(DestAlias, "ProtectionOfBurglary"))*100 + 10*ThiefLevel )
	local LootValue = (BaseValue * LootFactor / 100)
	
	if LootValue > 1500 then
		LootValue = 1500
	end
	
	return LootValue
end

-- -----------------------
-- GetBuildingLootLevel 
-- -----------------------
function GetBuildingLootLevel(DestAlias, DynastyID)
 
	local maxvalue = chr_GetMaxHaulValue(DestAlias, DynastyID, 6)
	local LootClass = 0
	
	if maxvalue <= 100 then
		LootClass = 0
	elseif maxvalue <= 350 then
		LootClass = 1
	elseif maxvalue <= 700 then
		LootClass = 2
	elseif maxvalue <= 1000 then
		LootClass = 3
	else
		LootClass = 4
	end
	
	return LootClass
end

-- -----------------------
-- GetBuildingProtFromBurglaryLevel 
-- -----------------------
function GetBuildingProtFromBurglaryLevel(Destination)	
	--the protection of burglary from the target building
	local ProtectionValue = GetImpactValue(Destination, "ProtectionOfBurglary")
	ProtectionValue = (ProtectionValue - 100)*100
	local ProtectionClass = 0

	if ProtectionValue <= 0 then
		ProtectionClass = 0
	elseif ProtectionValue <= 25 then
		ProtectionClass = 1
	elseif ProtectionValue <= 50 then
		ProtectionClass = 2
	elseif ProtectionValue <= 75 then
		ProtectionClass = 3
	else
		ProtectionClass = 4
	end
	return ProtectionClass	
end

-- -----------------------
-- SimModifyFaith
-- -----------------------
function SimModifyFaith(Sim, FaithAmount, Religion)

	local Faith = SimGetFaith(Sim) + FaithAmount
	SimSetFaith(Sim, Faith)
	if Religion == 0 then
		ShowOverheadSymbol(Sim, false, true, 0, "@L$S[2015] %1n", FaithAmount)
	else
		ShowOverheadSymbol(Sim, false, true, 0, "@L$S[2014] %1n", FaithAmount)
	end
end

-- -----------------------
-- GetBootyCount
-- for the robbers
-- -----------------------
function GetBootyCount(Destination, InventoryType)
	
	local Slots = InventoryGetSlotCount(Destination, InventoryType)
	local ItemID, ItemCount
	local Total = 0
	
	for Number = 0, Slots-1 do
		ItemID, ItemCount = InventoryGetSlotInfo(Destination, Number, InventoryType)
		if ItemID and ItemCount and ItemID ~= 999 then
			-- check for engineer ability
			if GetImpactValue(Destination, "CartBoost") > 0 then
				ItemCount = ItemCount - 5
			end
			
			if ItemCount > 0 then
				Total = Total + ItemGetBasePrice(ItemID) * ItemCount
			end
		end
	end
	
	return Total
end

function Plunder(SimAlias, Destination)
	local Print = function (Channel, Message)
		LogMessage("@"..Channel)
		LogMessage("@"..Channel.." "..Message)
	end

	Print("WAYLAY", "#E Plunder("..GetName(SimAlias)..", "..GetName(Destination)..")")

	local Check = false

	GetLocalPlayerDynasty("Local")
	GetDynasty(SimAlias, "Target")

	if GetID("Target") == GetID("Local") then
		Check = true
	end

	if Check then
		if AliasExists(Destination) then
			local Count = InventoryGetSlotCount(Destination, INVENTORY_STD)
			LogMessage("@WAYLAY " .. GetName(Destination) .. "'s inventory count is " .. Count)
			local _ID, _COUNT
			for i = 0, Count - 1 do
				_ID, _COUNT = InventoryGetSlotInfo(Destination, i)
				if _COUNT == nil or _ID == nil then
					LogMessage("@WAYLAY Slot #" .. i + 1 .. " is empty.")
				else
					LogMessage("@WAYLAY Slot #" .. i + 1 .. " contains x" .._COUNT .. " " .. ItemGetName(_ID) .. "(s)")
				end
			end
		end
	end

	local Item = {Slot=InventoryGetSlotCount(Destination, INVENTORY_STD), ID=nil, Count=nil, Value=0}
	
	for Number = 0, Item.Slot - 1 do
		Item.ID, Item.Count = InventoryGetSlotInfo(Destination, Number, INVENTORY_STD)
		if Item.ID and Item.Count and Item.ID ~= 999 then
			if Item.Count > 0 then
				local _SPACE = GetRemainingInventorySpace(SimAlias, Item.ID, INVENTORY_STD)

				if _SPACE > 10 then
					_SPACE = 10
				end

				if _SPACE > Item.Count then
					LogMessage("@WAYLAY [i] Available space of ".._SPACE.." but only x"..Item.Count.." exist in the cart (before extra modifiers).")
					_SPACE = Item.Count
				end

				if GetImpactValue(Destination, "CartBoost") > 0 then
					_SPACE = _SPACE - 5
					if _SPACE < 0 then
						_SPACE = 0
					end
				end

				if _SPACE == 0 then
					LogMessage("@WAYLAY [i] Actually, the cart seems to be empty... moving on to the next victim.")
					return 0
				end

				if _SPACE > 0 then
					AddItems(SimAlias, Item.ID, _SPACE, INVENTORY_STD)
					Print("WAYLAY", "#W <" .. GetName(SimAlias) .. "> 'I have collected x".._SPACE.." "..ItemGetName(Item.ID).."(s) from "..GetName(Destination).."'.")
					RemoveItems(Destination, Item.ID, _SPACE, INVENTORY_STD)
					LogMessage("@WAYLAY #W <" .. GetName(Destination) .. "> 'I have lost x".._SPACE.." "..ItemGetName(Item.ID).."(s)...'")
					Item.Value = Item.Value + ItemGetBasePrice(Item.ID) * _SPACE
					break
				end
			end
		end
	end

	MoveSetActivity(SimAlias, "carry")
	Sleep(2)
	CarryObject(SimAlias, "Handheld_Device/ANIM_Bag.nif", false)
	Sleep(0.5)
	
	return Item.Value
end 

function OutputHireError(SimAlias, BuildingAlias, Error)

	if Error == "" then
		return
	end
	
	if (Error == "WrongGender") then
		local Profession = BuildingGetProfession(BuildingAlias)
		if SimGetGender(SimAlias) == GL_GENDER_MALE then -- can't hire Male for female only jobs
			local Label = ProfessionGetLabel(Profession, GL_GENDER_FEMALE)
			MsgQuick(BuildingAlias, "@L_GENERAL_MEASURES_FAILURES_+27", Label)
		else -- can't hire Female for male only jobs
			local Label = ProfessionGetLabel(Profession, GL_GENDER_MALE)
			MsgQuick(BuildingAlias, "@L_GENERAL_MEASURES_FAILURES_+12", Label)
		end
	elseif (Error == "NoSpace") then
		local	MaxWorker = BuildingGetMaxWorkerCount(BuildingAlias)
		MsgQuick(BuildingAlias, "@L_GENERAL_MEASURES_FAILURES_+13", MaxWorker, GetID(BuildingAlias))
	elseif (Error == "NoMoney") then
		local Handsel = SimGetHandsel(SimAlias, BuildingAlias)
		MsgQuick(BuildingAlias, "@L_GENERAL_MEASURES_FAILURES_+14", Handsel, GetID(SimAlias))
	elseif (Error == "NoWorker") then
		MsgQuick(BuildingAlias, "@L_GENERAL_MEASURES_FAILURES_+15",GetID(BuildingAlias))
	else
		-- "WrongParams", etc.
		MsgQuick(BuildingAlias, "@L_GENERAL_MEASURES_FAILURES_+16", GetID(SimAlias))
	end
end

-- -----------------------
-- CreateChild
-- -----------------------
function CreateChild(Residence, Parent1, Parent2, Age, ChildAlias, Gender)

	if Gender == GL_GENDER_MALE then
		SimCreate(7, Residence, Residence, ChildAlias)
	elseif Gender == GL_GENDER_FEMALE then
		SimCreate(8, Residence, Residence, ChildAlias)
	else
		SimCreate(-1, Residence, Residence, ChildAlias)
	end

	-- Sets the child to the new family
	SimSetFamily(ChildAlias, Parent1, Parent2)

	-- Initialize more stuff in the code
	DoNewBornStuff(ChildAlias)
	SimSetAge(ChildAlias, Age)
	
	if Age < GL_AGE_FOR_GROWNUP then
		SimSetBehavior(ChildAlias, "Childness")
		SetState(ChildAlias, STATE_CHILD, true)
	end
end

-- -----------------------
-- SocialReactCourtLover
-- -----------------------
function SocialReactCourtLover()
end

-- -----------------------
-- SocialReactNoCourtLover
-- -----------------------
function SocialReactNoCourtLover()
end

-- -----------------------
-- MultiAnim
-- Plays two animations on two sim and adjustes the distance between them.
-- A factor for the overall time until the function should return can be given. It must be between 0.0 and 1.0.
-- If the last parameter is given, the ReturnAfter value means the seconds after which the function should return. The minimum time here is 1.0 second
-- In any case the function returns the time until the animations are over.
-- -----------------------
function MultiAnim(Actor1, Anim1, Actor2, Anim2, Distance, ReturnAfter, Seconds)
	
	local time1 = PlayAnimationNoWait(Actor1, Anim1)
	local time2 = PlayAnimationNoWait(Actor2, Anim2)
	chr_AlignExact(Actor1, Actor2, Distance)
	
	if time1 == nil then
		time1 = 0
	end
	
	if time2 == nil then
		time2 = 0
	end
	
	local time3 = math.max(time1, time2)
	
	if Seconds then
		
		-- Sleep the given seconds
		if ReturnAfter> 0.0 and ReturnAfter<time3 then
			if ReturnAfter < 1.0 then
				ReturnAfter = 1.0
			end
		end
		
		Sleep(ReturnAfter)
		return time3 - ReturnAfter
		
	elseif ReturnAfter then
		
		-- Sleep the given factor
		if ReturnAfter<1.0 and ReturnAfter>0.0 then
			Sleep(time3 * ReturnAfter)
			return time3 * (1 - ReturnAfter)
		end
	end
	
	Sleep(time3)
	return 0
end

function SpendMoney(SimAlias, MoneyToSpend, Reason, Force)
	
	if not AliasExists(SimAlias) then
		return false
	end
	
	if MoneyToSpend == nil then
		return false
	end
	
	-- if Force is true, dynasties will pay regardless if they can afford it or not and go into negatives
	if Force == nil then
		Force = false
	end
	
	if Reason == nil or Reason == false then
		Reason = "misc"
	end
	
	-- check if Worker
	if GetDynastyID(SimAlias) < 1 then
		return true
	end
	
	-- check if AI
	--if not DynastyIsAI(SimAlias) then
		return SpendMoney(SimAlias, MoneyToSpend, Reason, Force)
	--end
	
	-- counter hardcoded AI cheat OBSOLETE WITH NEW SETTINGS 
--	local Diff = ScenarioGetDifficulty()
--	local Multiplier = 10/(8-Diff)

--	local CorrectedAmount = math.floor(MoneyToSpend * Multiplier)
--	Reason = "misc" -- AI does not spend money for some other reasons (i.e. social interactions)
--	return SpendMoney(SimAlias, CorrectedAmount, Reason, Force)
	
	-- debugging
--	local MoneyBefore = GetMoney(SimAlias)
--	local Result = SpendMoney(SimAlias, CorrectedAmount, Reason, Force)
--	if Result and (MoneyBefore - MoneyToSpend) ~= GetMoney(SimAlias) then
--		local Msg = "Amount was not spent by AI: "..MoneyToSpend.." for "..Reason .. ". Spent value: " .. math.abs((GetMoney(SimAlias) - MoneyBefore))
--		MsgBoxNoWait("All", SimAlias, "SpendMoney failed assertion", Msg)
--		LogMessage("AIToM::SpendMoney:: "..Msg)
--	end
	
	-- workaround for AI not spending the money
--	if not GetDynasty(SimAlias, "CrdAlias") then
--		return SpendMoney(SimAlias, CorrectedAmount, Reason, Force)
--	end
--	
--	local MoneyBefore = GetMoney(SimAlias)
--	if MoneyBefore < MoneyToSpend and not Force then
--		return false
--	end
--	-- save to property for later transfer
--	local Current = GetProperty("CrdAlias", "AI_DynMoney") or 0
--	SetProperty("CrdAlias", "AI_DynMoney", Current - MoneyToSpend)
--	return Result
end

function CreditMoney(Alias, Amount, Purpose)
	-- don't care about non-dynasty characters
	if not GetDynasty(Alias, "CrdAlias") then
		return CreditMoney(Alias, Amount, Purpose)
	end
	
	if DynastyIsPlayer("CrdAlias") then
		return CreditMoney(Alias, Amount, Purpose)
	end
	
	if IsGUIDriven() then
		-- call hardcoded CreditMoney since it works for these cases
		return CreditMoney(Alias, Amount, Purpose)
	end

	-- workaround: save to property for later transfer
	local Current = GetProperty("CrdAlias", "AI_DynMoney") or 0
	SetProperty("CrdAlias", "AI_DynMoney", Current + Amount)
	return true
end

function GiveMoney(Target)
	DynastyGetMember(Target, 0, "FirstMember")
	if not AliasExists("FirstMember") then
		return
	end
	local MoneyOnLastCheck = GetProperty(Target, "AI_DynMoney_LastCheck")
	local CurrentMoney = GetMoney("FirstMember")
	local CheatingMoney = 0

	if DynastyIsShadow(Target) and MoneyOnLastCheck and (MoneyOnLastCheck + 1000) < CurrentMoney then
		CheatingMoney = CurrentMoney - MoneyOnLastCheck
		aitwp_Log("Removing cheating money from AI: " .. CheatingMoney, Target, true)
		SpendMoney(Target, math.abs(CheatingMoney), "misc")
	end
	
	local Current = GetProperty(Target, "AI_DynMoney") or 0
	Current = math.floor(Current)
	SetProperty(Target, "AI_DynMoney", 0)
	if Current > 0 then
		CreditMoney(Target, Current, "Income")
		LogMessage("::AITWP::GiveMoney "..GetName(Target).." received "..Current)
	elseif Current < 0 then -- should currently not happen since SpendMoney is handled directly
		LogMessage("::AITWP::GiveMoney "..GetName(Target).." spent "..Current)
		local Diff = ScenarioGetDifficulty()
		local Multiplier = 10/(8-Diff)
		Current = math.floor(Current * Multiplier)
		SpendMoney(Target, math.abs(Current), "misc")
	end
	CurrentMoney = GetMoney("FirstMember")
	SetProperty(Target, "AI_DynMoney_LastCheck", CurrentMoney)
end

-- -----------------------
-- GainXP
-- -----------------------
function GainXP(SimAlias, XPAmount, Quiet)
	
	local Options = FindNode("\\Settings\\Options")
	local YPR = Options:GetValueInt("YearsPerRound")
	local Multiplicator = 1
	
	if XPAmount == 0 or XPAmount == nil then
		XPAmount = 25
	end
	
	Multiplicator = 0.5*YPR
	
	local SchoeneRundeZahl = 5*math.floor(XPAmount*Multiplicator/5)
	
	if Quiet == nil then
		Quiet = false
	end
	
	if DynastyIsPlayer(SimAlias) and not Quiet then
		IncrementXP(SimAlias, SchoeneRundeZahl)
		PlaySound3D(SimAlias, "gainxp/gain_xp.ogg", 1)
	else
		IncrementXPQuiet(SimAlias, SchoeneRundeZahl)
	end
end

function CheckSell()

	if BuildingGetType("") ~= GL_BUILDING_TYPE_RESIDENCE then
		return true
	end

	local Ok = false
	
	local Count = DynastyGetBuildingCount2("")
	for l=0, Count-1 do
		if DynastyGetBuilding2("", l, "Check") then
			if BuildingGetType("Check") == GL_BUILDING_TYPE_RESIDENCE then
				if GetID("Check") ~= GetID("") then
					if not BuildingGetForSale("Check") then
						Ok = true
					end
				end
			end
		end
	end
	
	if not Ok then
		MsgQuick("", "@L_GENERAL_MEASURES_075_SELLBUILDING_FAILURES_+0")
		return false
	end
	
	Count = DynastyGetMemberCount("")
	for l=0, Count-1 do
		if DynastyGetMember("", l, "Member") then
			if GetHomeBuildingId("Member") == GetID("") then
			
				if SimGetOfficeID("Member") ~= -1 then
					MsgQuick("", "@L_GENERAL_MEASURES_075_SELLBUILDING_FAILURES_+1")
					return false
				end
				
				if SimIsAppliedForOffice("Member") then
					MsgQuick("", "@L_GENERAL_MEASURES_075_SELLBUILDING_FAILURES_+2")
					return false
				end
			end
		end
	end

	return true
end

function CheckDestroy()

	if BuildingGetType("") ~= GL_BUILDING_TYPE_RESIDENCE then
		return true
	end

	local Ok = false
	
	local Count = DynastyGetBuildingCount2("")
	for l=0, Count-1 do
		if DynastyGetBuilding2("", l, "Check") then
			if BuildingGetType("Check")==GL_BUILDING_TYPE_RESIDENCE then
				if GetID("Check")~=GetID("") then
					if not BuildingGetForSale("Check") then
						Ok = true
					end
				end
			end
		end
	end
	
	if not Ok then
		MsgQuick("", "@L_INTERFACE_TEARDOWN_FAILURES_+0")
		return false
	end
	
	Count = DynastyGetMemberCount("")
	for l=0, Count-1 do
		if DynastyGetMember("", l, "Member") then
			if GetHomeBuildingId("Member") == GetID("") then
			
				if SimGetOfficeID("Member") ~= -1 then
					MsgQuick("", "@L_INTERFACE_TEARDOWN_FAILURES_+1")
					return false
				end
				
				if SimIsAppliedForOffice("Member") then
					MsgQuick("", "@L_INTERFACE_TEARDOWN_FAILURES_+2")
					return false
				end
			end
		end
	end

	return true
end

function StartRage(SimAlias)

	local MeasureID = MeasureGetID("Rage")
	local duration = mdata_GetDuration(MeasureID)
	local TimeOut = mdata_GetTimeOut(MeasureID)
	local BaseXP = GetDatabaseValue("Measures", MeasureID, "basexp")
	local boost = 4
	
	SetRepeatTimer(SimAlias, GetMeasureRepeatName2("Rage"), TimeOut)
	
	GetPosition(SimAlias, "ParticleSpawnPos")
	PlaySound3D(SimAlias, "Effects/mystic_gift+0.wav", 1.0)
	StartSingleShotParticle("particles/rage.nif", "ParticleSpawnPos", 1, 2.0)
	AddImpact(SimAlias, "fighting", boost, duration)
	AddImpact(SimAlias, "IsOnRage", boost, duration)
	
	-- Find all units in the near range of the "Feldherr"
	local FightUnits = Find(SimAlias, "__F( (Object.GetObjectsByRadius(Sim) == 2000) AND (Object.CanBeControlled()))", "FightUnit", -1)
	chr_GainXP(SimAlias, BaseXP)
	if FightUnits == 0 then
		--No unit found
		return true
	end
	
	for i=0, FightUnits-1 do
		GetPosition("FightUnit"..i, "ParticleSpawnPos")
		PlaySound3D(SimAlias, "Effects/mystic_gift+0.wav", 1.0)
		StartSingleShotParticle("particles/rage.nif", "ParticleSpawnPos", 1, 2.0)
		AddImpact("FightUnit"..i, "fighting", boost, duration)
		AddImpact("FightUnit"..i, "IsOnRage", boost, duration)
	end
	
	return true
end

function CalculateBuildingBonus(SimAlias, WorkBuilding, HireFire)

	if not AliasExists(SimAlias) then
		return
	end
	
	if not AliasExists(WorkBuilding) then
		return
	end

	local ConstitutionMod = 0
	local DexterityMod = 0
	local FightingMod = 0
	local Shadow_ArtsMod = 0
	local CharismaMod = 0
	local EmpathyMod = 0
	local RhetoricMod = 0
	local Secret_KnowledgeMod = 0
	local MovespeedMod = 0
	
	local BuildingType = BuildingGetType(WorkBuilding)
	
	-- abilities
	BuildingGetOwner(WorkBuilding, "BOwner")
	chr_CalculateAbilityBonus(SimAlias, "BOwner", HireFire)
	
	if BuildingType == GL_BUILDING_TYPE_RESIDENCE then
		if HireFire == "hire" then
			if BuildingHasUpgrade(WorkBuilding, "CrossedAxes") then
				FightingMod = FightingMod + 2
			end
			
			if BuildingHasUpgrade(WorkBuilding, "HarkingHorn") then
				EmpathyMod = EmpathyMod + 1
			end
			
		else -- lower instead of removal, cause RemoveImpact removes the whole stack
			if BuildingHasUpgrade(WorkBuilding, "CrossedAxes") then
				FightingMod = FightingMod - 2
			end
			
			if BuildingHasUpgrade(WorkBuilding, "HarkingHorn") then
				EmpathyMod = EmpathyMod - 1
			end
		end
		
		AddImpact(SimAlias, "fighting", FightingMod, -1)
		AddImpact(SimAlias, "empathy", EmpathyMod, -1)
	
	elseif BuildingType == GL_BUILDING_TYPE_ROBBER then
		if HireFire == "hire" then
			if BuildingHasUpgrade(WorkBuilding, "CircleOfEquals") then
				ConstitutionMod = ConstitutionMod + 2
			end
			
			if BuildingHasUpgrade(WorkBuilding, "ChiefTent") then
				FightingMod = FightingMod + 2
			end
			
			if BuildingHasUpgrade(WorkBuilding, "RobberTent") then
				MovespeedMod = MovespeedMod + 1.2
			end
			
		else -- lower instead of removal, cause RemoveImpact removes the whole stack
			if BuildingHasUpgrade(WorkBuilding, "CircleOfEquals") then
				ConstitutionMod = ConstitutionMod - 2
			end
			
			if BuildingHasUpgrade(WorkBuilding, "ChiefTent") then
				FightingMod = FightingMod - 2
			end
			
			if BuildingHasUpgrade(WorkBuilding, "RobberTent") then
				MovespeedMod = MovespeedMod - 1.2
			end
		end
		
		AddImpact(SimAlias, "constitution", ConstitutionMod, -1)
		AddImpact(SimAlias, "fighting", FightingMod, -1)
		AddImpact(SimAlias, "MoveSpeed", MovespeedMod, -1)

	elseif BuildingType == GL_BUILDING_TYPE_THIEF then
		if HireFire == "hire" then
			if BuildingHasUpgrade(WorkBuilding, "TrickBox") then
				Shadow_ArtsMod = Shadow_ArtsMod + 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "ShadowCloak") then
				Shadow_ArtsMod = Shadow_ArtsMod + 2
			end
			
		else -- lower instead of removal, cause RemoveImpact removes the whole stack
			if BuildingHasUpgrade(WorkBuilding, "TrickBox") then
				Shadow_ArtsMod = Shadow_ArtsMod - 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "ShadowCloak") then
				Shadow_ArtsMod = Shadow_ArtsMod - 2
			end
		end
		
		AddImpact(SimAlias, "shadow_arts", Shadow_ArtsMod, -1)

	elseif BuildingType == GL_BUILDING_TYPE_DIVEHOUSE then
		if HireFire == "hire" then
			if BuildingHasUpgrade(WorkBuilding, "MakeUpMirror") then
				CharismaMod = CharismaMod + 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "BathBowl") then
				CharismaMod = CharismaMod + 2
			end
			
			if BuildingHasUpgrade(WorkBuilding, "SexyClothes") then
				CharismaMod = CharismaMod + 3
			end
			
		else -- lower instead of removal, cause RemoveImpact removes the whole stack
			if BuildingHasUpgrade(WorkBuilding, "MakeUpMirror") then
				CharismaMod = CharismaMod - 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "BathBowl") then
				CharismaMod = CharismaMod - 2
			end
			
			if BuildingHasUpgrade(WorkBuilding, "SexyClothes") then
				CharismaMod = CharismaMod - 3
			end
		end
		
		AddImpact(SimAlias, "charisma", CharismaMod, -1)

	elseif BuildingType == GL_BUILDING_TYPE_MERCENARY then
		if HireFire == "hire" then
			if BuildingHasUpgrade(WorkBuilding, "AlarmHorn") then
				FightingMod = FightingMod + 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "WarBanner") then
				FightingMod = FightingMod + 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "CircleOfEquals") then
				ConstitutionMod = ConstitutionMod + 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "WaterBottle") then
				MovespeedMod = MovespeedMod + 1.2
			end
			
			if BuildingHasUpgrade(WorkBuilding, "PlanOfSite") then
				EmpathyMod = EmpathyMod + 1
			end
			
		else -- lower instead of removal, cause RemoveImpact removes the whole stack
			if BuildingHasUpgrade(WorkBuilding, "AlarmHorn") then
				FightingMod = FightingMod - 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "WarBanner") then
				FightingMod = FightingMod - 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "CircleOfEquals") then
				ConstitutionMod = ConstitutionMod - 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "WaterBottle") then
				MovespeedMod = MovespeedMod - 1.2
			end
			
			if BuildingHasUpgrade(WorkBuilding, "PlanOfSite") then
				EmpathyMod = EmpathyMod - 1
			end
		end
		
		AddImpact(SimAlias, "constitution", ConstitutionMod, -1)
		AddImpact(SimAlias, "fighting", FightingMod, -1)
		AddImpact(SimAlias, "MoveSpeed", MovespeedMod, -1)
		AddImpact(SimAlias, "empathy", EmpathyMod, -1)	
	end
end

function CheckGuildMaster(SimAlias, GuildHouse)

	if GetSettlement(SimAlias, "city") then
		if not trade_GetGuildHouse("city", "guildhouse") then
			return false
		end
	else
		return false
	end
	
	local Class = SimGetClass(SimAlias)
	local Master
	
	if Class > 0 and Class < 5 then
	
		local ClassData = {
					[GL_CLASS_PATRON] = "PatronMaster",
					[GL_CLASS_ARTISAN] = "ArtisanMaster",
					[GL_CLASS_SCHOLAR] = "ScholarMaster",
					[GL_CLASS_CHISELER] = "ChiselerMaster"
					}
					
		Master = ClassData[Class]
	else
		return false
	end

	if GetID(SimAlias) == GetProperty(GuildHouse, Master) then
		return true
	else
		return false
	end
end

function GetAlderman()

	local Alderman = GetData("#Alderman")
	
	if Alderman ~= nil then
		if (Alderman > 0) and GetAliasByID(Alderman, "Alderman") and not GetState("Alderman", STATE_DEAD) then
			return Alderman
		else
			return 0
		end
	else
		return 0
	end
end

function GetKing()

	local Count = ScenarioGetObjects("cl_Settlement", 99, "Cities")
	local ID = 0
	
	for i=0, Count-1 do
		if CityGetOffice("Cities"..i, 7, 0, "OFFICE") then -- king office
			if OfficeGetHolder("OFFICE", "OfficeHolder") then
				ID = GetID("OfficeHolder")
				break
			end
		end
	end

	return ID
end

function GetWarRiskLevel(val)

	if val < 10 then
		return 0
	elseif val < 20 then
		return 1
	elseif val < 40 then
		return 2
	elseif val < 60 then
		return 3
	else
		return 4
	end

end

function GetEnemyMoodLevel(val)

	if val < 5 then
		return 0
	elseif val < 10 then
		return 1
	elseif val < 26 then
		return 2
	elseif val < 50 then
		return 3
	else
		return 4
	end
end

function DecrementInfectionCount(InfectionName, CityAlias)
	
	if HasProperty(CityAlias, InfectionName) then
		local Infected = GetProperty(CityAlias, InfectionName) - 1
		if Infected < 1 then
			Infected = 0
		end
		SetProperty(CityAlias, InfectionName, Infected)
	else
		SetProperty(CityAlias, InfectionName, 0)
	end
end

function IncrementInfectionCount(InfectionName, CityAlias)

	if HasProperty(CityAlias,InfectionName) then
		local Infected = GetProperty(CityAlias, InfectionName) + 1
		SetProperty(CityAlias, InfectionName, Infected)
	else
		SetProperty(CityAlias, InfectionName, 1)
	end
end

-- --------------------------------------------------------
-- Check bonuses workers get from their current employer
-- --------------------------------------------------------
function CheckWorkerBonuses(BldAlias)
	
	local NumWorkers = BuildingGetWorkerCount(BldAlias)
	if not BuildingGetOwner(BldAlias, "BOwner") then
		return
	end
	
	for i=0 , NumWorkers -1 do
		if BuildingGetWorker(BldAlias, i, "Worker") then
			chr_CalculateAbilityBonus("Worker", "BOwner", "hire")
		end
	end
end

-- --------------------------------------------------------
-- Calculate bonuses workers get from their current employer
-- --------------------------------------------------------
function CalculateAbilityBonus(SimAlias, SimOwner, hirefire)

	if not AliasExists(SimAlias) then
		return
	end
	
	local booster, BossImpact
	local Profession = SimGetProfession(SimAlias)	

	-- Mentor
	booster = GetImpactValue(SimAlias, "MentorBoost")
	BossImpact = GetImpactValue(SimOwner, "MentorI")
	
	if BossImpact > 0 and BossImpact > booster and hirefire ~= "fire" then 
		AddImpact(SimAlias, "XPBonus", 300, -1)
		AddImpact(SimAlias, "MentorBoost", 1, -1)
	end
	
	-- Alchemist
	booster = GetImpactValue(SimAlias, "AlchemistBoost") 
	BossImpact = GetImpactValue(SimOwner, "AlchemistI")  
		
	if BossImpact > 0 and BossImpact > booster and hirefire ~= "fire" then 
		AddImpact(SimAlias, "LifeExpanding", 10, -1)
		AddImpact(SimAlias, "AlchemistBoost", 1, -1)	
	end
	
	-- Marauder
	booster = GetImpactValue(SimAlias, "MarauderBoost") 
	BossImpact = GetImpactValue(SimOwner, "MarauderI")  
		
	if BossImpact > 0 and BossImpact > booster and hirefire ~= "fire" then 
		AddImpact(SimAlias, "MarauderBoost", 1, -1)
		AddImpact(SimAlias, "DestructionBonus", 0.20, -1)
	elseif (BossImpact == 0 and booster > 0) or hirefire == "fire" then
		RemoveImpact(SimAlias, "MarauderBoost")
		RemoveImpact(SimAlias, "DestructionBonus")
	end
	
	-- General
	booster = GetImpactValue(SimAlias, "GeneralBoost") 
	BossImpact = GetImpactValue(SimOwner, "GeneralI") 
	
	if BossImpact > 0 and BossImpact > booster and hirefire ~= "fire" then 
		AddImpact(SimAlias, "fighting", 2, -1)
		AddImpact(SimAlias, "GeneralBoost", 1, -1)		
	elseif (BossImpact == 0 and booster > 0) or hirefire == "fire" then
		AddImpact(SimAlias, "fighting", -2 * booster, -1)
		RemoveImpact(SimAlias, "GeneralBoost")
	end
end

-- --------------------------------------------------------
-- Check bonuses carts get from their current employer
-- --------------------------------------------------------
function CheckCartBonuses(BldAlias)
	
	local NumCarts = BuildingGetCartCount(BldAlias)
	if not BuildingGetOwner(BldAlias, "BOwner") then
		return
	end
	
	for i=0 , NumCarts -1 do
		if BuildingGetCart(BldAlias, i, "Cart") then
			chr_CalculateCartBonus("Cart", "BOwner")
		end
	end
end

-- --------------------------------------------------------
-- Calculate bonuses carts get from their current employer
-- --------------------------------------------------------
function CalculateCartBonus(CartAlias, SimOwner)

	if not AliasExists(CartAlias) then
		return
	end
	
	local booster = GetImpactValue(CartAlias, "CartBoost")
	local BossImpact = GetImpactValue(SimOwner, "CartBonusI")
	
	-- stays forever
	if BossImpact > 0 and BossImpact > booster then 
		AddImpact(CartAlias, "MoveSpeed", 1.2, -1)
		AddImpact(CartAlias, "CartBoost", 1, -1)
	end
end

-- ------------------------------------------------
-- Calculate whether I need to visit the doc or not
-- ------------------------------------------------
function NeedsTreatment(SimAlias)
	local MyHP = GetHP(SimAlias)
	local Damage = false
	local Sickness = { "Cold", "Sprain", "Influenza", "BurnWound", "Caries", "Pox", "Pneumonia", "Blackdeath" }
	
	if MyHP < GetMaxHP(SimAlias)/1.3 then
		return true
	end
	
	if (GetImpactValue(SimAlias, "Sickness") > 0) then
		for i=1, 8 do
			if GetImpactValue(SimAlias, Sickness[i]) > 0 then
				if ImpactGetMaxTimeleft(SimAlias, Sickness[i]) >= 2 or Sickness[i] == "Pneumonia" or Sickness[i] == "Blackdeath" then
					Damage = true
					break
				end
			end
		end
	end
	
	if Damage then
		return true
	end
	
	return false
end

function CityFindCrowdedPlace(SettlementAlias, SimAlias, ResultLocation)
	
	local MaxDistance = 10000
	local MaxCrowdedLocators = 30
	local Profession = SimGetProfession(SimAlias)
	local LocatorName, LocatorRanking
	
	-- will contain a computed ranking value for each locator for decision
	-- LocatorRanking = (10 - Distance/1000) + (5 - OwnWorkersNearby)
	local LocatorRankingList = {} 
	local LocatorList = {}
	local LocatorRankingCount = 0
	for i = 1, MaxCrowdedLocators do
		RemoveAlias("CrowdedPos")
		if GetOutdoorLocator("Crowded"..i, 1, "CrowdedPos") and AliasExists("CrowdedPos") then
			-- check the distance first
			local DistanceFound = GetDistance(SimAlias, "CrowdedPos")
			if MaxDistance > DistanceFound then
				LocatorRanking = math.max(1, 10 - math.floor(DistanceFound/1000))
				-- check number of own workers nearby
				local Count = Find("CrowdedPos", "__F((Object.GetObjectsByRadius(Sim) == 1500) AND (Object.GetProfession() == " .. Profession ..") AND (Object.BelongsToMe()))", "Result", 5)
				LocatorRanking = math.max(1, LocatorRanking + (5 - Count))
				LocatorRankingCount = LocatorRankingCount + 1
				LocatorList[LocatorRankingCount] = "Crowded"..i
				LocatorRankingList[LocatorRankingCount] = LocatorRanking
			end
		end
	end
	local ChosenIndex = helpfuncs_RandWeighted(LocatorRankingList)
	if ChosenIndex and GetOutdoorLocator(LocatorList[ChosenIndex], 1, ResultLocation) and AliasExists(ResultLocation) then
		return LocatorList[ChosenIndex]
	end

	-- still no Destination? Select Market then
	if not AliasExists(ResultLocation) then
		local Market = Rand(5)+1
		if CityGetRandomBuilding(SettlementAlias, 5, 14, Market, -1, FILTER_IGNORE, ResultLocation) then
			LogMessage(GetName(SimAlias) .. " did not find a good Crowded locator and will go to the market. Profession: "..Profession.." City: " .. GetName(SettlementAlias))
			return "Market"
		end
	end
	return nil
end

function GetBribeAmount(SimAlias) 
	
	local OfficeLevel = dyn_GetHighestOfficeLevel(SimAlias)
	
	if OfficeLevel < 1 then 
		OfficeLevel = 1
	end
	
	local Title = GetNobilityTitle(SimAlias)
	local Amount = (Title * 1000) * OfficeLevel
	
	return Amount
end

function CheckWeaponChange(SimAlias, WeaponNew)
	
	local WeaponOld = ""
	local CheckNew = { "Dagger", "Shortsword", "Mace", "Longsword", "Axe", "Excalibur", "EpicAxe" }
	local CheckNewCount = 7
	local ChangeWeapon = false
	
	for i=1, CheckNewCount do
		if WeaponNew == CheckNew[i] then
			local FreeSlot = GetRemainingInventorySpace(SimAlias, WeaponNew, INVENTORY_EQUIPMENT)
			
			if FreeSlot > 0 then
				ChangeWeapon = true
				break
			else
				if WeaponNew == "Dagger" then
					break
				elseif WeaponNew == "Shortsword" then
					if GetItemCount(SimAlias, "Dagger", INVENTORY_EQUIPMENT)  > 0 then
						ChangeWeapon = true
						break
					end
				elseif WeaponNew == "Mace" then
					local CheckOld = { "Dagger", "Shortsword" }
					local CheckOldCount = 2
					local FoundOld = false
		
					for j=1, CheckOldCount do
						if GetItemCount(SimAlias, CheckOld[j], INVENTORY_EQUIPMENT) > 0 then
							FoundOld = true
							break
						end
					end
					
					if FoundOld then
						ChangeWeapon = true
						break
					end
				elseif WeaponNew == "Longsword" then
					local CheckOld = { "Dagger", "Shortsword", "Mace" }
					local CheckOldCount = 3
					local FoundOld = false
		
					for j=1, CheckOldCount do
						if GetItemCount(SimAlias, CheckOld[j], INVENTORY_EQUIPMENT) > 0 then
							FoundOld = true
							break
						end
					end
					
					if FoundOld then
						ChangeWeapon = true
						break
					end
				elseif WeaponNew == "Axe" then
					local CheckOld = { "Dagger", "Shortsword", "Mace", "Longsword" }
					local CheckOldCount = 4
					local FoundOld = false
		
					for j=1, CheckOldCount do
						if GetItemCount(SimAlias, CheckOld[j], INVENTORY_EQUIPMENT) > 0 then
							FoundOld = true
							break
						end
					end
					
					if FoundOld then
						ChangeWeapon = true
						break
					end
				elseif WeaponNew == "Excalibur" then
					local CheckOld = { "Dagger", "Shortsword", "Mace", "Longsword", "Axe" }
					local CheckOldCount = 5
					local FoundOld = false
		
					for j=1, CheckOldCount do
						if GetItemCount(SimAlias, CheckOld[j], INVENTORY_EQUIPMENT) > 0 then
							FoundOld = true
							break
						end
					end
					
					if FoundOld then
						ChangeWeapon = true
						break
					end
				elseif WeaponNew == "EpicAxe" then
					local CheckOld = { "Dagger", "Shortsword", "Mace", "Longsword", "Axe", "Excalibur" }
					local CheckOldCount = 6
					local FoundOld = false
		
					for j=1, CheckOldCount do
						if GetItemCount(SimAlias, CheckOld[j], INVENTORY_EQUIPMENT) > 0 then
							FoundOld = true
							break
						end
					end
					
					if FoundOld then
						ChangeWeapon = true
						break
					end
				end
			end
		end
	end
	
	return ChangeWeapon
end

-- this replaces the original SimGetRank!!
function GetRank(SimAlias)
	if IsDynastySim(SimAlias) then
		-- rank depends on nobility title
		local Title = GetNobilityTitle(SimAlias)
		
		if Title < 4 then -- below lesser citizen
			return GL_RANK_POOR -- 2
		elseif Title < 7 then -- below patrician
			return GL_RANK_MIDDLE -- 3
		elseif Title < 10 then -- below  baron
			return GL_RANK_RICH -- 4
		else -- baron to arch duke
			return GL_RANK_WEALTHY -- 5
		end
	else
		if SimGetProfession(SimAlias) < 1 then -- unemployed
			return GL_RANK_DESTITUTE -- 1
		else
			-- rank depends on level
			local Level = SimGetLevel(SimAlias)
			if Level < 3 then
				return GL_RANK_POOR -- 2
			elseif Level < 5 then
				return GL_RANK_MIDDLE -- 3
			else
				return GL_RANK_RICH -- 4
			end
		end
	end
end

-- this calculates the sum of money a Sim can/want to spend on needs
function GetBudget(SimAlias, Type)
	
	local Rank = chr_GetRank(SimAlias) or 0
	local BasicMax = 0
	local LuxuryMax = 0
	local BasicCurrent = 0
	local LuxuryCurrent = 0
	
	local RankData = {
				[GL_RANK_DESTITUTE] = { BasicMax = 12, LuxuryMax = 6 }, -- 1: 696 / 348
				[GL_RANK_POOR] = { BasicMax = 24, LuxuryMax = 12 },  -- 2: 1392 / 696
				[GL_RANK_MIDDLE] = { BasicMax = 48, LuxuryMax = 32 }, -- 3: 2784 /1856
				[GL_RANK_RICH] = { BasicMax = 72, LuxuryMax = 72 },  -- 4: 4176 / 4176
				[GL_RANK_WEALTHY] = { BasicMax = 120, LuxuryMax = 240 } -- 5: 6960 / 13920
				}
	
	BasicCurrent = RankData[Rank].BasicMax - GetImpactValue(SimAlias, "BasicPurse")
	LuxuryCurrent = RankData[Rank].LuxuryMax - GetImpactValue(SimAlias, "LuxuryPurse")
	
	-- greed reduces the purses a character has (20-90% reduction)
	if IsDynastySim(SimAlias) then
		if GetDynasty(SimAlias, "MyDyn") then
			BasicCurrent = math.floor(BasicCurrent * ai_CheckPersonalityWeight("MyDyn", "greed") / 100)
			LuxuryCurrent = math.floor(LuxuryCurrent * ai_CheckPersonalityWeight("MyDyn", "greed") / 100)
		end
	end
		
	if BasicCurrent < 0 then
		BasicCurrent = 0
	end
	
	if LuxuryCurrent < 0 then
		LuxuryCurrent = 0
	end
	
	if Type == 1 then
		return BasicCurrent * 58
	else
		return LuxuryCurrent * 58
	end
end

-- spend money from your budget, based on "workhours", where 1 hour is worth 58 gold.
function UseBudget(SimAlias, Type, Amount, Balance)
	
	if Amount == nil or Amount < 1 or Type == nil or not AliasExists(SimAlias) then
		return
	end
	
	if not Balance or Balance == nil then
		Balance = "misc"
	end
	
	if IsDynastySim(SimAlias) then
		chr_SpendMoney(SimAlias, Amount, Balance, true)
		-- ToDo: statistics
	end
	
	local Change = math.floor(Amount / 58)
	
	if Type == 1 then -- BasePurse
		AddImpact(SimAlias, "BasicPurse", Change, 12)
	elseif Type == 2 then -- LuxuryPurse
		AddImpact(SimAlias, "LuxuryPurse", Change, 12)
	end
end

-- assigns a home if needed
function CheckHome(SimAlias)
	if GetHomeBuilding(SimAlias, "HasHome") then
		return
	else
		if IsDynastySim(SimAlias) then
			-- check for residence
			if DynastyGetRandomBuilding(SimAlias, GL_BUILDING_CLASS_LIVINGROOM, GL_BUILDING_TYPE_RESIDENCE, "DynHome") then
				LogMessage(GetName(SimAlias).." has no home. Assign dynasty residence")
				SetHomeBuilding(SimAlias, "DynHome")
			end
		end
		
		if not GetHomeBuilding(SimAlias, "HasHome") then
			GetNearestSettlement(SimAlias, "NewSettlement")
			CityGetNearestBuilding("NewSettlement", "", GL_BUILDING_CLASS_LIVINGROOM, GL_BUILDING_TYPE_WORKER_HOUSING, -1, -1, FILTER_IGNORE, "NewHome")
		
			if AliasExists("NewHome") then
				LogMessage(GetName(SimAlias).." has no home. Assign worker housing")
				SetHomeBuilding("", "NewHome")
			end
		end
	end
end

-- returns the current skill level of a sim with a maximum of 15
function GetSkillValue(SimAlias, Skill)
	local Value = GetSkillValue(SimAlias, Skill) or 1
	if Value > 15 then
		Value = 15
	end
	
	return Value
end

-- this searches an owned building nearby depending on it's attractiveness and regular customer preferences
function FindInterestingWorkshop(SimAlias, BuildingType, HasUpgrade, MinRange, MaxRange, OutputAlias)
	if not GetNearestSettlement(SimAlias, "City") then
		return false
	end
	
	local BuildingCount = CityGetBuildings("City", GL_BUILDING_CLASS_WORKSHOP, BuildingType, -1, -1, FILTER_HAS_DYNASTY, "Building") or 0
	local CheckBld
	local BestScore = 0
	local RegularID = 0
	
	if HasProperty(SimAlias, "Regular_"..BuildingType) then
		RegularID = GetProperty(SimAlias, "Regular_"..BuildingType)
	end
	
	if BuildingCount > 1 then
		for i=0, BuildingCount-1 do
			local Score
			CheckBld = "Building"..i
			if AliasExists(CheckBld) then
				local FavorBonus = 0
				if BuildingGetOwner(CheckBld, "CheckBoss") then
					FavorBonus = GetFavorToSim(SimAlias, "CheckBoss")
				end
				
				Score = GetImpactValue(CheckBld, "Attractivity") + FavorBonus
				
				if GetID(CheckBld) == RegularID then
					Score = Score * 3
				elseif GetDynastyID(CheckBld) == GetDynastyID(SimAlias) then
					Score = Score * 5
				end
			end
			
			if HasUpgrade == 0 or BuildingHasUpgrade(CheckBld, HasUpgrade) then
			
				local Distance = GetDistance(SimAlias, CheckBld)
				if Distance <= MinRange then
					BestScore = Score
					CopyAlias(CheckBld, OutputAlias)
					break
				elseif Distance > MaxRange then
					Score = 0
				end
				
				if Score > BestScore then
					CopyAlias(CheckBld, OutputAlias)
					BestScore = Score
				end
			end
		end
	end
	
	if BestScore > 0 then
		return true
	else
		return false
	end
end
	
function DynastyGetImperialFameLevel(SimAlias)

	local fame = 0

	if IsDynastySim(SimAlias) and GetDynasty(SimAlias, "family") then
		if GetProperty("family","ImperialFame") then
			fame = GetProperty("family","ImperialFame")
		end
	end

	if fame == 0 then
		return 0
	elseif fame < 21 then
		return 1
	elseif fame < 51 then
		return 2
	elseif fame < 101 then
		return 3
	elseif fame < 201 then
		return 4
	else
		return 5
	end

end

function DynastyGetWorkhopCount(SimAlias)
	local buildingcount = 0
	local Count = DynastyGetBuildingCount2(SimAlias)
	local Class
	for l=0,Count-1 do
		if DynastyGetBuilding2(SimAlias, l, "Check") then
			Class = BuildingGetClass("Check")
			if Class == GL_BUILDING_CLASS_WORKSHOP then
				buildingcount = buildingcount + 1
			end
		end
	end
	return buildingcount
end
