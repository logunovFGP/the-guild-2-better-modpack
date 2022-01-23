-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching 
end

-- -------------------
-- BlockSocialMeasures
-- -------------------
function BlockSocialMeasures(ActorAlias, TimeOut)
	
	if TimeOut == nil then
		TimeOut = 2
	end
	
	SetRepeatTimer(ActorAlias, GetMeasureRepeatName2("Flirt"), TimeOut)
	SetRepeatTimer(ActorAlias, GetMeasureRepeatName2("HugCharacter"), TimeOut)
	SetRepeatTimer(ActorAlias, GetMeasureRepeatName2("KissCharacter"), TimeOut)
	SetRepeatTimer(ActorAlias, GetMeasureRepeatName2("MakeACompliment"), TimeOut)
	
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
	
	return MoveResult
	
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

	-- Get the current exact distance
	local Distance = CalcDistance(MoverAlias, DestinationAlias)
	
	-- Get the direction from the mover to the destination
	local DirX = 0
	local DirY = 0
	local DirZ = 0
	DirX, DirY, DirZ = GetDirectionTo(DestinationAlias, MoverAlias)
	
	-- Calculate the last step distance
	local LastStepLength = Distance - Range
	
	if not Duration then
		local Duration = 1
	end
	
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
-- AttemptToBribeIsSuccess
-- -----------------------
function AttemptToBribeIsSuccess(BriberAlias, TargetAlias)

	local Favor = GetFavorToSim(TargetAlias, BriberAlias)
	local Alignment = SimGetAlignment(TargetAlias)
	local SuccessValue = Favor + Alignment * 0.5
	
	if(SuccessValue >= 50) then
		return true
	end
	
	return false

end

-- -----------------------
-- GetFavorWonFromBribe
-- -----------------------
function GetFavorWonFromBribe(TargetAlias, BribeAmount)
	local wealth = SimGetWealth(TargetAlias)
	 
	if (wealth <= 1500) then 
		wealth = 1500
	end
		
	return ( 250 * BribeAmount / wealth)
end

-- -----------------------
-- GetTradeBonus
-- -----------------------
function GetTradeBonus(BuyerAlias, HowMuch)
	local Chance = 3 * GetSkillValue(BuyerAlias, BARGAINING)
	
	if(IsDynastySim(BuyerAlias)) then
		Chance = Chance + 20
	end
	
	if(Chance > Rand(199)) then	
		local Bonus = 0.0025 * HowMuch * (4 * GetSkillValue(BuyerAlias, RHETORIC) + 100 - SimGetAlignment(BuyerAlias))		
		return Bonus	
	end
end

-- -----------------------
-- AnswerCourtingMeasure
-- -----------------------
function AnswerCourtingMeasure(Kind, Rhetoric, Gender, CourtingProgress)

	local label = "@L_SOCIAL_ANSWER_"..Kind
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end	
	
	if (Kind == "TALK") or (Kind == "COMPLIMENT") or (Kind == "DANCE") or (Kind == "MAKE_A_PRESENT") then
		
		if (CourtingProgress <= 0) then
			if (CourtingProgress < -6) then
				label = label.."_WAY_TOO_PROFOUND_"
			else
				label = label.."_PROFOUND_"
			end
		else
			if (CourtingProgress >= 15) then
				label = label.."_VERY_WELL_RECEIVED_"
			else			
				label = label.."_WELL_RECEIVED_"
			end
		end
		
	else
	
		if (CourtingProgress <= 0) then
			if (CourtingProgress <- 6) then
				label = label.."_WAY_TOO_OFFENSIVE_"
			else
				label = label.."_OFFENSIVE_"
			end
		else
			if (CourtingProgress >= 15) then
				label = label.."_VERY_WELL_RECEIVED_"
			else			
				label = label.."_WELL_RECEIVED_"
			end
		end		
	
	end
	
	label = label.."+"..Gender
	return label
end

-- -----------------------
-- AnswerMissingVariation
-- -----------------------
function AnswerMissingVariation(Gender, Rhetoric)

	local label = "@L_SOCIAL_ANSWER_NO_VARIATION"
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_MALE"
	else
		label = label.."_FEMALE"
	end
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	return label
	
end

-- -----------------------
-- AnswerBathSuccess
-- -----------------------
function AnswerBathing(Gender, Rhetoric, Success)

	local label = "@L_SOCIAL_ANSWER_TAKE_A_BATH"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end

	if (Success == true) then
		label = label.."_WELL_RECEIVED"
	else
		label = label.."_OFFENSIVE"
	end

	if (Gender == GL_GENDER_MALE) then
		label = label.."_+1"
	else
		label = label.."_+0"
	end
		
	return label
	
end

-- ------------------------------
-- SocialMeasureFailedBeforeStart
-- ------------------------------
function SocialMeasureFailedBeforeStart(Gender, Rhetoric, Kind)

	local label = "@L_SOCIAL_ANSWER_FAILED_BEFORE_START"
	
	if (Kind == "Slap") then
		label = label.."_SLAP"
	else
		label = label.."_OUTRAGED"
	end
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_MALE"
	else
		label = label.."_FEMALE"
	end
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	return label
	
end

-- ----------------------
-- SocialMeasureSucceeded
-- ----------------------
function SocialMeasureSucceeded(Gender, Rhetoric, Kind)

	Assert(Kind, "Param 'Kind' not specified")
	if not Kind then
		return
	end
	local label = "@L_SOCIAL_ANSWER_SUCCEEDED_"..Kind
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_MALE"
	else
		label = label.."_FEMALE"
	end
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	return label
	
end

-- -----------------------
-- AskCohabit
-- -----------------------
function AskCohabit(Rhetoric, Gender)

	local label = "@L_FAMILY_2_COHABITATION_QUESTION"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender==GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end

-- -----------------------
-- AnswerCohabit
-- -----------------------
function AnswerCohabit(Rhetoric, Gender, Success)

	local label = "@L_FAMILY_2_COHABITATION"
	
	if (Success == 1) then
		label = label.."_ANSWER_POSITIVE"
	elseif (Success == 2) then
		label = label.."_ANSWER_NEGATIVE"
	else
		label = label.."_ANSWER_OUTRAGED"
	end
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	return label
end

-- ---------------
-- MakeACompliment
-- ---------------
function MakeACompliment(Gender, Rhetoric)

	local label = "@L_COMPLIMENT"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender==GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
		
end

-- -----------------------
-- FlirtSaying1
-- -----------------------
function FlirtSaying1(Rhetoric, Gender)

	local label = "@L_FLIRT_SAYING1"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender==GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end

-- -----------------------
-- FlirtAnswer
-- -----------------------
function FlirtAnswer(Rhetoric, Gender)

	local label = "@L_FLIRT_ANSWER"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender==GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end

-- -----------------------
-- FlirtSaying2
-- -----------------------
function FlirtSaying2(Rhetoric, Gender)

	local label = "@L_FLIRT_SAYING2"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender==GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
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
		return ((Value/40)*duration)
	end
end

-- -----------------------
-- RecieveMoney 
-- -----------------------
function RecieveMoney(ObjectAlias, val, topic)
	CreditMoney(ObjectAlias, val, topic)
	ShowOverheadSymbol(ObjectAlias, false, false, 0, "@L%1t", val)
	return val
end

-- -----------------------
-- ModifyFavor
-- Value uses GameConstants (GL_FAVOR_MOD_)
-- Value uses diplomacy or title for additional modification
-- -----------------------
function ModifyFavor(source, dest, val)
	
	if IsDynastySim(source) and IsDynastySim(dest) then
		local Diplo = DynastyGetDiplomacyState(source, dest)
		
		if Diplo == DIP_ALLIANCE and val < 0 then
		-- harder to lose if you are friends
			val = math.floor(val / 2)
		elseif Diplo == DIP_FOE and val > 0 then
		-- harder to gain if you are enemies
			val = math.floor(val / 2)
		else
			-- check title-difference
			local SourceTitle = GetNobilityTitle(source, true)
			local DestinationTitle = GetNobilityTitle(dest, true)
			
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
	if GetImpactValue(dest,"RattleTheChains") == 1 and val < 0 then
		val = math.floor(val / 2)
	end
	
	if IsDynastySim(source) and IsDynastySim(dest) then
		-- add new grudges
		if val <= -20 then
			dyn_AddGrudge(source, dest)
		elseif val >= 20 then
		-- add new fondness
			dyn_AddFondness(source, dest)
		end
	end
	
	ModifyFavorToSim(source, dest, val)

	if DynastyIsPlayer(source) or DynastyIsPlayer(dest) then
		if (val >0) then
			feedback_OverheadSkill("","@L$S[2007] +%1n", true, val)
		else
			feedback_OverheadSkill("","@L$S[2006] %1n", true, val)
		end
	end
end


-- -----------------------
-- SkillCheck
-- Roll higher than difficulty + enemy talent value
-- -----------------------
function SkillCheck(SimAlias, Skill, Difficulty, DestAlias, DestSkill)
	local TalentValue = GetSkillValue(SimAlias, Skill) + Rand(3)
	local TalentEnemy = 0
	
	if DestAlias ~= nil then
		TalentEnemy = GetSkillValue(DestAlias, DestSkill)
	end
	
	local SuccessValue = TalentEnemy + Difficulty
	
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

	local BaseValue		= BuildingGetPriceProto(BuildingGetProto(DestAlias))
	
	if BaseValue < 1000 then
		return 0
	end
	
	BaseValue = BaseValue * 0.025
	if GetDynastyID(DestAlias) then
		BaseValue = BaseValue * 2
	end
	
	if HasProperty(DestAlias,"ScoutedBy"..DynastyID) then
		BaseValue = BaseValue * 3
	end

	local LootFactor	= ((101 - GetImpactValue(DestAlias,"ProtectionOfBurglary"))*100 + 10*ThiefLevel )
	local LootValue		=	(BaseValue * LootFactor / 100)
	
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
function GetBuildingProtFromBurglaryLevel(destination)	
	--the protection of burglary from the target building
	local ProtectionValue = GetImpactValue(destination,"ProtectionOfBurglary")
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
-- SpeakPoem
-- -----------------------
function SpeakPoem(GenderDes,OwnMarried,InLove,DesFName,OwnFName)

	local label = "@L_GIVEAPOEM"
	
	if (DesFName == OwnFName) or (OwnMarried == false) or (InLove == true) then
		label = label.."_POETRY"
	else
		label = label.."_HOMAGE"
	end
	
	if GenderDes == GL_GENDER_FEMALE then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end	
	
	return label
end

-- -----------------------
-- SimModifyFaith
-- -----------------------
function SimModifyFaith(Sim,FaithAmount,Religion)

	local faith = SimGetFaith(Sim) + FaithAmount
	SimSetFaith(Sim,faith)
	if Religion == 0 then
		ShowOverheadSymbol(Sim,false,true,0,"@L$S[2015] %1n",FaithAmount)
	else
		ShowOverheadSymbol(Sim,false,true,0,"@L$S[2014] %1n",FaithAmount)
	end
end

-- -----------------------
-- GetBootyCount
-- for the robbers
-- -----------------------
function GetBootyCount(Destination, InventoryType)
	local	Slots = InventoryGetSlotCount(Destination, InventoryType)
	local	Number
	local	ItemId
	local	ItemCount
	local	Total = 0
	
	for Number = 0, Slots-1 do
		ItemId, ItemCount = InventoryGetSlotInfo(Destination, Number, InventoryType)
		if ItemId and ItemCount then
			Total = Total + ItemGetBasePrice(ItemId) * ItemCount
		end
	end
	
	return Total

end

function OutputHireError(SimAlias, BuildingAlias, Error)

	if Error == "" then
		return
	end
	
	if (Error == "WrongGender") then
		local Profession = BuildingGetProfession(BuildingAlias)
		if SimGetGender(SimAlias) == GL_GENDER_MALE then -- can't hire Male for female only jobs
			local Label = ProfessionGetLabel(Profession, GL_GENDER_FEMALE)
			MsgQuick(BuildingAlias,"@L_GENERAL_MEASURES_FAILURES_+27", Label)
		else -- can't hire Female for male only jobs
			local Label = ProfessionGetLabel(Profession, GL_GENDER_MALE)
			MsgQuick(BuildingAlias,"@L_GENERAL_MEASURES_FAILURES_+12", Label)
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

function CreateFamily(SimAlias)

	if not AliasExists(SimAlias) then
		return
	end
	
	local	Age = SimGetAge(SimAlias)
	if Age < 16 then
		return
	end

	local	Var = 90
	if Age < 26 then
		Var = 100 - (26 - Age) * 10
		if Var > 90 then
			Var = 90
		end
	end
	
	local SpouseAlias = SimAlias.."_s"
	
	local	Married = false
	if Rand(100) < Var then
		if BossCreate(HomeAlias, 1-SimGetGender(SimAlias), 0, 2, SpouseAlias) then
			SimSetAge(SpouseAlias, Rand(9) + Age - 4)
			if SimMarry(SimAlias, SpouseAlias) then
				Married = true
			end
		end
	end
	
	if not Married then
		return
	end
	
	Age = math.min( SimGetAge(SimAlias), SimGetAge(SpouseAlias) )
	
	local Childs 		= Rand(3)+1
	local	Birthday 	= Rand(16)+16
	local ChildAge
	local ChildAlias
	local	CreateChild
	local ChildWasCreated = false
	
	
	while Childs>0 and Birthday < Age do
		ChildAge = Age - Birthday
		
		CreateChild = true
		if Age > 18 then
			if Rand(100) < 50 and ChildWasCreated then
				CreateChild = false
			end
		end
		
		if CreateChild then
			ChildAlias = SimAlias.."_c"..Childs
			chr_CreateChild(HomeAlias, SimAlias, SpouseAlias, ChildAge, ChildAlias)
			chr_CreateFamily(ChildAlias)
			ChildWasCreated = true
		end
		Childs = Childs - 1
		Birthday = Rand(1)+Birthday + 1
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
	if DynastyIsAI(SimAlias) then
		local Diff = ScenarioGetDifficulty()
		local Multiplier = 10/(8-Diff)
		local CorrectAmount = MoneyToSpend*Multiplier
		if SpendMoney(SimAlias, CorrectAmount, Reason, Force) then
			return true
		else
			return false
		end
	else
		if SpendMoney(SimAlias, MoneyToSpend, Reason, Force) then
			return true
		else
			return false
		end
	end
end

-- -----------------------
-- GainXP
-- -----------------------
function GainXP(SimAlias, XPAmount)
	local Options = FindNode("\\Settings\\Options")
	local YPR = Options:GetValueInt("YearsPerRound")
	local Multiplicator = 1
	
	Multiplicator = 0.5*YPR
	
	local SchoeneRundeZahl = 5*math.floor(XPAmount*Multiplicator/5)
	
	if DynastyIsPlayer(SimAlias) then
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

	local	Ok = false
	
	local	Count = DynastyGetBuildingCount2("")
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

	local	Ok = false
	
	local	Count = DynastyGetBuildingCount2("")
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
	
	GetPosition(SimAlias,"ParticleSpawnPos")
	PlaySound3D(SimAlias,"Effects/mystic_gift+0.wav", 1.0)
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
		GetPosition("FightUnit"..i,"ParticleSpawnPos")
		PlaySound3D(SimAlias,"Effects/mystic_gift+0.wav", 1.0)
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
	local MovespeedModify = 0
	
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
			
			if BuildingHasUpgrade(Workbuilding, "SexyClothes") then
				CharismaMod = CharismaMod + 3
			end
			
		else -- lower instead of removal, cause RemoveImpact removes the whole stack
			if BuildingHasUpgrade(WorkBuilding, "MakeUpMirror") then
				CharismaMod = CharismaMod - 1
			end
			
			if BuildingHasUpgrade(WorkBuilding, "BathBowl") then
				CharismaMod = CharismaMod - 2
			end
			
			if BuildingHasUpgrade(Workbuilding, "SexyClothes") then
				CharismaMod = CharismaMod - 3
			end
		end
		
		AddImpact(SimAlias, "charisma", CharismaMod, -1)

	elseif BuildingType == GL_BUILDING_TYPE_CASTLE then
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

function CheckGuildMaster(SimAlias,GuildHouse)

	if GetSettlement(SimAlias, "city") then
		if (gameplayformulas_CheckPublicBuilding("city", GL_BUILDING_TYPE_GUILDHOUSE)[1]>0) then
			if not CityGetRandomBuilding("city", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "guildhouse") then
				return false
			end
		else
			return false
		end
	else
		return false
	end
	
	local Class

	if SimGetClass(SimAlias) == 1 then
		Class = "PatronMaster"
	elseif SimGetClass(SimAlias) == 2 then
		Class = "ArtisanMaster"
	elseif SimGetClass(SimAlias) == 3 then
		Class = "ScholarMaster"
	elseif SimGetClass(SimAlias) == 4 then
		Class = "ChiselerMaster"
	else
		return false
	end

	if GetID(SimAlias) == GetProperty(GuildHouse, Class) then
		return true
	else
		return false
	end
end

function GetAlderman()
	local alderman = GetData("#Alderman")
	if alderman~=nil then
		if (alderman>0) and GetAliasByID(alderman,"Alderman") and GetState("Alderman", STATE_DEAD)==false then
			return alderman
		else
			return 0
		end
	else
		return 0
	end
end

function GetKing()
	local Count = ScenarioGetObjects("cl_Settlement", 99, "Cities")

	for i=0,Count-1 do
		if CityGetOffice("Cities"..i, 7, 0, "OFFICE") then
			if OfficeGetHolder("OFFICE", "OfficeHolder") then
				return GetID("OfficeHolder")
			end
		end
	end

	return 0
end

function GetImperialOfficer()
	local ImperialOfficer = GetData("#ImperialOfficer")
	if ImperialOfficer~=nil then
		if (ImperialOfficer>0) and GetAliasByID(ImperialOfficer,"ImperialOfficer") and GetState("ImperialOfficer", STATE_DEAD)==false then
			return ImperialOfficer
		else
			return 0
		end
	else
		return 0
	end
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

	return 0

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

	return 0

end

function decrementInfectionCount(InfectionName, CityAlias)
	if HasProperty(CityAlias,InfectionName) then
		local Infected = GetProperty(CityAlias,InfectionName) - 1
		if Infected < 1 then
			Infected = 0
		end
		SetProperty(CityAlias,InfectionName,Infected)
	else
		SetProperty(CityAlias,InfectionName,0)
	end
end

function incrementInfectionCount(InfectionName, CityAlias)
	if HasProperty(CityAlias,InfectionName) then
		local Infected = GetProperty(CityAlias,InfectionName) + 1
		SetProperty(CityAlias,InfectionName,Infected)
	else
		SetProperty(CityAlias,InfectionName,1)
	end
end

-- --------------------------------------------------------
-- Check bonuses workers get from their current employer
-- --------------------------------------------------------

function CheckWorkerBonuses(BldAlias)
	
	local NumWorkers = BuildingGetWorkerCount(BldAlias)
	if not BuildingGetOwner(BldAlias,"BOwner") then
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
	
	local booster
	
	-- master of manure
	booster = GetImpactValue(SimAlias,"ManureI")  
	if (not (booster == 1) and SimHasAbility(SimOwner,5)) and not (hirefire == "fire") then 
		AddImpact(SimAlias,"GatherBonus",20  * (1 - booster),-1)
		AddImpact(SimAlias,"ManureI",1       * (1 - booster),-1)		
	elseif not (booster == 0) and (not SimHasAbility(SimOwner,5) or hirefire == "fire") then
		AddImpact(SimAlias,"GatherBonus",-20 * booster,-1)
		RemoveImpact(SimAlias,"ManureI")
	end
	
	-- mentor
	booster = GetImpactValue(SimAlias,"MentorI")  
	if (not (booster == 1) and SimHasAbility(SimOwner,8)) and not (hirefire == "fire") then 
		AddImpact(SimAlias,"ExpGaining",15  * (1 - booster),-1)
		AddImpact(SimAlias,"MentorI",1      * (1 - booster),-1)
	elseif not (booster == 0) and (not SimHasAbility(SimOwner,8) or hirefire == "fire") then
		AddImpact(SimAlias,"ExpGaining",-15 * booster,-1)
		RemoveImpact(SimAlias,"MentorI")
	end
	
	-- oratory master   
	booster = GetImpactValue(SimAlias,"MarketerI")
	if (not (booster == 1) and SimHasAbility(SimOwner,17)) and not (hirefire == "fire") then 
		AddImpact(SimAlias,"rhetoric",2    * (1 - booster),-1)
		AddImpact(SimAlias,"empathy",2     * (1 - booster),-1)
		AddImpact(SimAlias,"bargaining",2  * (1 - booster),-1)
		AddImpact(SimAlias,"MarketerI",1   * (1 - booster),-1)
	elseif not (booster == 0) and (not SimHasAbility(SimOwner,17) or hirefire == "fire") then
		AddImpact(SimAlias,"rhetoric",-2   * booster,-1)
		AddImpact(SimAlias,"empathy",-2    * booster,-1)
		AddImpact(SimAlias,"bargaining",-2 * booster,-1)
		RemoveImpact(SimAlias,"MarketerI")
	end
	
	-- lightning burglary
	booster = GetImpactValue(SimAlias,"BurglaryI")
	if (not (booster == 1) and SimHasAbility(SimOwner,21)) and not (hirefire == "fire") then
		AddImpact(SimAlias,"BurglarySpeedup",25  * (1 - booster),-1)
		AddImpact(SimAlias,"MoveSpeed",1.2       * (1 - booster),-1)
		AddImpact(SimAlias,"BurglaryI",1         * (1 - booster),-1)
		AddImpact(SimAlias,"shadow_arts",2       * (1 - booster),-1)
	elseif not (booster == 0) and (not SimHasAbility(SimOwner,21) or hirefire == "fire") then
		AddImpact(SimAlias,"BurglarySpeedup",-25 * booster,-1)
		AddImpact(SimAlias,"MoveSpeed",-1.2      * booster,-1)
		AddImpact(SimAlias,"shadow_arts",-2      * booster,-1)
		RemoveImpact(SimAlias,"BurglaryI")
	end
	
	-- druidic secrets
	booster = GetImpactValue(SimAlias,"DruidicI")
	if (not (booster == 1) and SimHasAbility(SimOwner,34)) and not (hirefire == "fire") then     
		AddImpact(SimAlias,"GatherBonus",20      * (1 - booster),-1)
		AddImpact(SimAlias,"constitution",2      * (1 - booster),-1)
		AddImpact(SimAlias,"secret_knowledge",2  * (1 - booster),-1)
		AddImpact(SimAlias,"DruidicI",1          * (1 - booster),-1)
	elseif not (booster == 0) and (not SimHasAbility(SimOwner,34) or hirefire == "fire") then
		AddImpact(SimAlias,"GatherBonus",-20     * booster,-1)
		AddImpact(SimAlias,"constitution",-2     * booster,-1)
		AddImpact(SimAlias,"secret_knowledge",-2 * booster,-1)
		RemoveImpact(SimAlias,"DruidicI")
	end
	
	-- hard workers
	booster = GetImpactValue(SimAlias,"HardWorkersI")
	if (not (booster == 1) and SimHasAbility(SimOwner,36)) and not (hirefire == "fire") then
		AddImpact(SimAlias,"BonusSlot",1      * (1 - booster),-1)
		AddImpact(SimAlias,"constitution",2   * (1 - booster),-1)
		AddImpact(SimAlias,"craftsmanship",2  * (1 - booster),-1)
		AddImpact(SimAlias,"HardWorkersI",1   * (1 - booster),-1)
	elseif not (booster == 0) and (not SimHasAbility(SimOwner,36) or hirefire == "fire") then
		AddImpact(SimAlias,"BonusSlot",-1     * booster,-1)
		AddImpact(SimAlias,"constitution",-2  * booster,-1)
		AddImpact(SimAlias,"craftsmanship",-2 * booster,-1)
		RemoveImpact(SimAlias,"HardWorkersI")
	end
	
	-- charming rogues
	booster = GetImpactValue(SimAlias,"CharmingI")
	if (not (booster == 1) and SimHasAbility(SimOwner,37)) and not (hirefire == "fire") then
		AddImpact(SimAlias,"FightCrit",15  * (1 - booster),-1)
		AddImpact(SimAlias,"charisma",2    * (1 - booster),-1)
		AddImpact(SimAlias,"fighting",2    * (1 - booster),-1)
		AddImpact(SimAlias,"CharmingI",1   * (1 - booster),-1)
	elseif not (booster == 0) and (not SimHasAbility(SimOwner,37) or hirefire == "fire") then
		AddImpact(SimAlias,"FightCrit",-15 * booster,-1)
		AddImpact(SimAlias,"charisma",-2   * booster,-1)
		AddImpact(SimAlias,"fighting",-2   * booster,-1)
		RemoveImpact(SimAlias,"CharmingI")
	end
	
	-- defenders
	booster = GetImpactValue(SimAlias,"DefendersI")
	if (not (booster == 1) and SimHasAbility(SimOwner,38)) and not (hirefire == "fire") then
		AddImpact(SimAlias,"FightArmor",7  * (1 - booster),-1)
		AddImpact(SimAlias,"dexterity",2   * (1 - booster),-1)
		AddImpact(SimAlias,"empathy",2     * (1 - booster),-1)
		AddImpact(SimAlias,"DefendersI",1  * (1 - booster),-1)
	elseif not (booster == 0) and (not SimHasAbility(SimOwner,38) or hirefire == "fire") then
		AddImpact(SimAlias,"FightArmor",-7 * booster,-1)
		AddImpact(SimAlias,"dexterity",-2  * booster,-1)
		AddImpact(SimAlias,"empathy",-2    * booster,-1)
		RemoveImpact(SimAlias,"DefendersI")
	end
	
	-- master extractor
	booster = GetImpactValue(SimAlias,"ProducerI")
	if (not (booster == 1) and SimHasAbility(SimOwner,41)) and not (hirefire == "fire") then  
		AddImpact(SimAlias,"GatherBonus",35  * (1 - booster),-1)
		AddImpact(SimAlias,"ProducerI",1     * (1 - booster),-1)
	elseif not (booster == 0) and (not SimHasAbility(SimOwner,41) or hirefire == "fire") then
		AddImpact(SimAlias,"GatherBonus",-35 * booster,-1)
		RemoveImpact(SimAlias,"ProducerI")
	end

end

function NeedsTreatment(SimAlias)
	local MyHP = GetHP(SimAlias)
	local Damage = false
	local Sickness = { "Fever", "Cold", "Sprain", "Influenza", "BurnWound", "Caries", "Pox", "Pneumonia", "Blackdeath" }
	
	if MyHP < GetMaxHP(SimAlias)/2 then
		return true
	end
	
	if (GetImpactValue(SimAlias, "Sickness") > 0) then
		for i=1, 9 do
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