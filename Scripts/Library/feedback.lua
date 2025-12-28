-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end


-- -----------------------
-- ShowOverheadSymbol
-- -----------------------
function OverheadPercent(ObjectAlias, Number)
	
	-- shows fading percents
	ShowOverheadSymbol(ObjectAlias, false, false, 0, "@L$C[51,102,255]%1i%%", Number)
end 

-- -------------
-- OverheadMoney
-- -------------
function OverheadMoney(ObjectAlias, Number)
	
	-- shows fading money
	ShowOverheadSymbol(ObjectAlias, false, false, 0, "@L%1t", Number)
end

-- -------------
-- OverheadFame
-- -------------
function OverheadFame(ObjectAlias, Number)
	
	-- shows fading fame
	ShowOverheadSymbol(ObjectAlias, false, false, 0, "@L_GUILDHOUSE_FAME_+0", Number)
end

-- ---------------
-- OverheadImpFame
-- ---------------
function OverheadImpFame(ObjectAlias, Number)
	
	-- shows fading fame
	ShowOverheadSymbol(ObjectAlias, false, false, 0, "@L_IMPERIAL_FAME_+0", Number)
end

-- ---------------------
-- OverheadCourtProgress
-- ---------------------
function OverheadCourtProgress(ObjectAlias, Progress)

	-- shows fading (possibly broken) heart
	if (Progress > 0) then
		ShowOverheadSymbol(ObjectAlias, false, true, 0, "@L$S[2001] +%1i", Progress)
	else
		ShowOverheadSymbol(ObjectAlias, false, true, 0, "@L$S[2012] %1i", Progress)
	end

end

function OverheadActionName(ObjectAlias, ActionName, Force, Replacement)
	
	-- the overhead is shown permanent
	-- Force: true = show overhead symbol global, false = show overhead symbol only for the dynasty
	-- Replacement: e.g. character name, building name, item name, time, counter, etc.

	if ActionName then
		if Replacement then
			ShowOverheadSymbol(ObjectAlias, true, Force, 0, ActionName, Replacement)
		else
		ShowOverheadSymbol(ObjectAlias, true, Force, 0, ActionName)
		end
	else
		RemoveOverheadSymbols(ObjectAlias)
	end
end

function OverheadComment(ObjectAlias, Comment, NoFade, Force, Replacement1, Replacement2)
	
	-- NoFade: true = the overhead is shown permanent, false = the overhead is fading out
	-- Force: true = show overhead symbol global, false = show overhead symbol only for the dynasty
	-- Replacement: e.g. character name, building name, item name, time, counter, etc.

	if Comment then
		ShowOverheadSymbol(ObjectAlias, NoFade, Force, 0, Comment, Replacement1, Replacement2)
	else
		RemoveOverheadSymbols(ObjectAlias)
	end
end

function OverheadSkill(ObjectAlias, Skill, Force, Replacement1, Replacement2, Replacement3)
	
	-- NoFade: true = the overhead is shown permanent, false = the overhead is fading out
	-- Force: true = show overhead symbol global, false = show overhead symbol only for the dynasty
	-- Replacement: e.g. character name, building name, item name, time, counter, etc.
	
	if Skill then
		ShowOverheadSymbol(ObjectAlias, false, Force, 0, Skill, Replacement1, Replacement2, Replacement3)
	else
		RemoveOverheadSymbols(ObjectAlias)
	end
end

function OverheadFadeText(ObjectAlias, FadeText, Force, Replacement)
	-- Force: true = show overhead symbol global, false = show overhead symbol only for the dynasty
	-- Replacement: e.g. character name, building name, item name, time, counter, etc.

	ShowOverheadSymbol(ObjectAlias, false, Force, 0, FadeText, Replacement)
end

-- -----------------------
-- MsgNews
-- -----------------------
function MessageWorkshop(Owner, Headline, Text, ...)

	local HeaderText = Headline
	local MessageClass = "building"

	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	GetVariableParameters(arg)
	MsgNewsNoWait(Owner, Owner, "", MessageClass, -1, HeaderText, Text)
end

function MessageCharacter(Owner, Headline, Text, ...)

	local HeaderText = Headline
	local MessageClass = "intrigue"
	
	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	GetVariableParameters(arg)
	MsgNewsNoWait(Owner,Owner,"",MessageClass,-1, HeaderText, Text)
end

function MessageOtherCharacters(Owner, Headline, Text, ...)
	
	if DynastyIsShadow(Owner) then
		return
	end
	
	local HeaderText = Headline
	local MessageClass = "economie"
	local OwnerDyn = GetDynastyID(Owner)
	local Alias
	local DynCount = ScenarioGetObjects("Dynasty", 100, "Dynasties")
	
	for i=0, DynCount-1 do
		Alias = "Dynasties"..i
		if GetDynastyID(Alias) ~= OwnerDyn then
			-- copies variable parameters to c	
			-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
			GetVariableParameters(arg)
			MsgNewsNoWait(Alias, Owner, "", MessageClass, -1, HeaderText, Text)
		end
	end
end

function MessageOtherDynastiesTitle(Owner, NewTitle)
	
	if DynastyIsShadow(Owner) then
		return
	end
	
	local Alias
	local OwnerDyn = GetDynastyID(Owner)
	local DynCount = ScenarioGetObjects("Dynasty", 100, "Dynasties")
	
	local GenderLabel = 1
	if SimGetGender(Owner) == GL_GENDER_FEMALE then
		GenderLabel = 2
	end
	local TitleLabel = "_CHARACTERS_3_TITLES_NAME_+"..(NewTitle * 2) - GenderLabel
	
	for i=0, DynCount-1 do
		Alias = "Dynasties"..i
			
		if GetDynastyID(Alias) ~= OwnerDyn then
			-- check for diplomacy
			local Diplo = DynastyGetDiplomacyState(Alias, Owner)
			if Diplo == DIP_FOE then
				MsgNewsNoWait(Alias, Owner, "", "economie", -1, "@L_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_OTHER_DOCUMENT_HEADER_+2", "_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_OTHERPLAYERS_ENEMY_+0", GetID(Owner), TitleLabel)
			elseif Diplo == DIP_ALLIANCE then
				MsgNewsNoWait(Alias, Owner, "", "economie", -1, "@L_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_OTHER_DOCUMENT_HEADER_+1", "_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_OTHERPLAYERS_BLOODBAND_+0", GetID(Owner), TitleLabel)
			else -- neutral
				MsgNewsNoWait(Alias, Owner, "", "economie", -1, "@L_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_OTHER_DOCUMENT_HEADER_+0", "_CHARACTERS_3_TITLES_AQUIRE_MESSAGES_OTHERPLAYERS_NEUTRAL_+0", GetID(Owner), TitleLabel)
			end
		end
	end
end

function MessageProduction(Owner, Headline, Text,...)

	local HeaderText = Headline
	local MessageClass = "production"
	
	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	GetVariableParameters(arg)
	MsgNewsNoWait(Owner,Owner,"",MessageClass,-1, HeaderText, Text)
end

function MessageEconomie(Owner, Headline, Text, ...)

	local HeaderText = Headline
	local MessageClass = "economie"

	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	GetVariableParameters(arg)
	MsgNewsNoWait(Owner, Owner, "", MessageClass, -1, HeaderText, Text)
end

function MessageMilitary(Owner, Headline, Text, ...)

	local HeaderText = Headline
	local MessageClass = "military"
	
	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	GetVariableParameters(arg)
	MsgNewsNoWait(Owner, Owner, "", MessageClass, -1, HeaderText, Text)
end

function MessagePolitics(Owner, Headline, Text, ...)

	local HeaderText = Headline
	local MessageClass = "politics"
	
	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	GetVariableParameters(arg)
	MsgNewsNoWait(Owner, Owner, "", MessageClass, -1, HeaderText, Text)
end

function MessageSchedule(Owner, Headline, Text, ...)

	local HeaderText = Headline
	local MessageClass = "schedule"
	
	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	GetVariableParameters(arg)
	MsgNewsNoWait(Owner, Owner, "", MessageClass, -1, HeaderText, Text)
end

function MessageMission(Owner, Headline, Text, ...)

	local HeaderText = Headline
	local MessageClass = "mission"	
	
	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	GetVariableParameters(arg)
	MsgNewsNoWait(Owner, 0, "", MessageClass, -1, HeaderText, Text)
end

function MessageDefault(Owner, Headline, Text, ...)

	local HeaderText = Headline
	local MessageClass = "default"

	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	GetVariableParameters(arg)
	MsgNewsNoWait(Owner, Owner, "", MessageClass, -1, HeaderText, Text)
end

-- -----------------------
-- MsgBox - ganz wichtige Messages
-- -----------------------

function MessageBox(Owner, Headline, Text, ...)

	local HeaderText = Headline
	
	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	GetVariableParameters(arg)
	MsgBoxNoWait(Owner, Owner, HeaderText, Text)
end

-- -----------------------
-- PregnancySuccess
-- -----------------------
function PregnancySuccess(Gender, Success)

	local label = "@L_FAMILY_2_COHABITATION_PREGNANCY"
	
	if (Success == 0) then
		label = label.."_UNSUCCESSFUL"
	else
		label = label.."_SUCCESSFUL"
	end
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end

-- -------------------------
-- Msg for gaining an office
-- -------------------------
function MessageOffice(Owner, GetPrivilegeList, Headline, Text, ...)

	local HeaderText = Headline
	local MessageClass = "politics"
	
	local Privilegs = { GetPrivilegeList() }
	local PrivilegName
	local Label
	local Count = 1
	local Param = {}
	
	local FirstFreeParameter = arg.n + 2
	local PriviText = ""
	
	GetVariableParameters(arg)

	if not(Privilegs[Count]) then
		Text = Text.."_+1"
	else
		Text = Text.."_+0"	
		while (Privilegs[Count]) do
	
			PrivilegName = Privilegs[Count]
			
			-- PrivilegName -> "AimForInquisitionalProceeding" or "HaveImmunity"
			
			Param[Count] = "_MEASURE_"..PrivilegName.."_NAME_+0"
			PriviText = PriviText .. "$N  - %"..FirstFreeParameter.."l"
			FirstFreeParameter = FirstFreeParameter + 1
			
			Count = Count + 1
		end
	end

	SetArg(arg.n+1, PriviText)
	Count = 1
	
	while (Param[Count]) do
		SetArg(arg.n+1+Count, Param[Count])
		Count = Count + 1
	end
	
	-- copies variable parameters to c	
	-- attention - GetVariableParameters works only with special function such as (MsgNews/MsgNewsNoWait/MsgBox/MsgBoxNoWait)
	MsgNewsNoWait(Owner, Owner, "", MessageClass, -1, HeaderText, Text)
end

-- -------------------------
-- Msg for grudges (ModifyFavor)
-- -------------------------

function FavorReduceFondness(Owner, Target)
	
	if GetDynasty(Owner, "MyDyn") and GetDynasty(Target, "TargetDyn") then
		local TargetID = GetDynastyID(Target)
		local MyDynID = GetDynastyID(Owner)
		local FondnessCounter = 0 + GetProperty("MyDyn", "Fondness"..TargetID)
		
		MsgNewsNoWait(Owner, Target, "", "intrigue", -1, 
					"@L_DIPLOMATIC_FEEDBACK_FONDNESS_REDUCE_HEAD_+0",
					"@L_DIPLOMATIC_FEEDBACK_FONDNESS_REDUCE_BODY_+0", 
					GetID(Owner), GetID(Target), FondnessCounter)
	end
end

function FavorRemoveFondness(Owner, Target)
	
	MsgNewsNoWait(Owner, Target, "", "intrigue", -1, 
					"@L_DIPLOMATIC_FEEDBACK_FONDNESS_REMOVE_HEAD_+0",
					"@L_DIPLOMATIC_FEEDBACK_FONDNESS_REMOVE_BODY_+0", 
					GetID(Owner), GetID(Target))
end

function FavorGainGrudge(Owner, Target)
	
	if GetDynasty(Owner, "MyDyn") and GetDynasty(Target, "TargetDyn") then
		local TargetID = GetDynastyID(Target)
		local MyDynID = GetDynastyID(Owner)
		
		MsgNewsNoWait(Owner, Target, "", "intrigue", -1, 
					"@L_DIPLOMATIC_FEEDBACK_GRUDGE_GAIN_HEAD_+0",
					"@L_DIPLOMATIC_FEEDBACK_GRUDGE_GAIN_BODY_+0", 
					GetID(Owner), GetID(Target))
	end
end

function FavorAddGrudge(Owner, Target)
	
	if GetDynasty(Owner, "MyDyn") and GetDynasty(Target, "TargetDyn") then
		local TargetID = GetDynastyID(Target)
		local MyDynID = GetDynastyID(Owner)
		local GrudgeCounter = 0 + GetProperty("MyDyn", "Grudge"..TargetID)
		
		MsgNewsNoWait(Owner, Target, "", "intrigue", -1, 
					"@L_DIPLOMATIC_FEEDBACK_GRUDGE_ADD_HEAD_+0",
					"@L_DIPLOMATIC_FEEDBACK_GRUDGE_ADD_BODY_+0", 
					GetID(Owner), GetID(Target), GrudgeCounter)
	end
end

-- -------------------------
-- Msg for fondness (ModifyFavor)
-- -------------------------

function FavorReduceGrudge(Owner, Target)
	
	if GetDynasty(Owner, "MyDyn") and GetDynasty(Target, "TargetDyn") then
		local TargetID = GetDynastyID(Target)
		local MyDynID = GetDynastyID(Owner)
		local GrudgeCounter = 0 + GetProperty("MyDyn", "Grudge"..TargetID)
		
		MsgNewsNoWait(Owner, Target, "", "intrigue", -1, 
					"@L_DIPLOMATIC_FEEDBACK_GRUDGE_REDUCE_HEAD_+0",
					"@L_DIPLOMATIC_FEEDBACK_GRUDGE_REDUCE_BODY_+0", 
					GetID(Owner), GetID(Target), GrudgeCounter)
	end
end

function FavorRemoveGrudge(Owner, Target)
	
	MsgNewsNoWait(Owner, Target, "", "intrigue", -1, 
					"@L_DIPLOMATIC_FEEDBACK_GRUDGE_REMOVE_HEAD_+0",
					"@L_DIPLOMATIC_FEEDBACK_GRUDGE_REMOVE_BODY_+0", 
					GetID(Owner), GetID(Target))
end

function FavorGainFondness(Owner, Target)
	
	if GetDynasty(Owner, "MyDyn") and GetDynasty(Target, "TargetDyn") then
		local TargetID = GetDynastyID(Target)
		local MyDynID = GetDynastyID(Owner)
		
		MsgNewsNoWait(Owner, Target, "", "intrigue", -1, 
					"@L_DIPLOMATIC_FEEDBACK_FONDNESS_GAIN_HEAD_+0",
					"@L_DIPLOMATIC_FEEDBACK_FONDNESS_GAIN_BODY_+0", 
					GetID(Owner), GetID(Target))
	end
end

function FavorAddFondness(Owner, Target)
	
	if GetDynasty(Owner, "MyDyn") and GetDynasty(Target, "TargetDyn") then
		local TargetID = GetDynastyID(Target)
		local MyDynID = GetDynastyID(Owner)
		local FondnessCounter = 0 + GetProperty("MyDyn", "Fondness"..TargetID)
		
		MsgNewsNoWait(Owner, Target, "", "intrigue", -1, 
					"@L_DIPLOMATIC_FEEDBACK_FONDNESS_ADD_HEAD_+0",
					"@L_DIPLOMATIC_FEEDBACK_FONDNESS_ADD_BODY_+0", 
					GetID(Owner), GetID(Target), FondnessCounter)
	end
end

-- -------------
-- CityBalanceRound
-- -------------
function CityBalanceRound(CityAlias)
	
	if CityGetRandomBuilding(CityAlias, GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, -1, -1, FILTER_IGNORE, "Townhall") then
		BuildingGetNPC("Townhall", 1, "Usher")
	end
	
	-- get the needed data
	-- taxes
	local TotalIncome = GetProperty(CityAlias, "TotalIncome") or 0
	local TaxValue = GetProperty(CityAlias, "TaxValue") or 0
	local TaxRaw = GetProperty(CityAlias, "TaxRaw") or 0
	local TaxFood = GetProperty(CityAlias, "TaxFood") or 0
	local TaxHandi = GetProperty(CityAlias, "TaxHandi") or 0
	local TaxSchol = GetProperty(CityAlias, "TaxSchol") or 0
	local TaxHerbs = GetProperty(CityAlias, "TaxHerbs") or 0
	local TaxIron = GetProperty(CityAlias, "TaxIron") or 0
	-- other income
	local NobilityMoneyLY = GetProperty(CityAlias, "NobilityMoneyLY") or 0
	local FeesLY = GetProperty(CityAlias, "CityFeesLY") or 0
	local TrialsLY = GetProperty(CityAlias, "TrialIncomeLY") or 0
	-- costs
	local TotalCost = GetProperty(CityAlias, "TotalCost") or 0
	
	local Balance = TotalIncome - TotalCost
	local BalanceLabel = ""
	if Balance > 0 then
		BalanceLabel = "@L_CITY_PINGHOUR_CITY_TREASURY_BALANCE_PROFIT_+0"
	else
		BalanceLabel = "@L_CITY_PINGHOUR_CITY_TREASURY_BALANCE_LOSS_+0"
	end
	
	local OfficeMoney = GetProperty(CityAlias, "OfficeMoney") or 0
	local BuildingRepairs = GetProperty(CityAlias, "BuildingRepairs") or 0
	local Warcosts = GetProperty(CityAlias, "WarcostsLY") or 0
	local CostServants = GetProperty(CityAlias, "ServantCost") or 0
	local CostCityGuard = GetProperty(CityAlias, "CityGC") or 0
	local CostEliteGuard = GetProperty(CityAlias, "EliteGC") or 0
	
	-- church income
	local ChurchTithe = GetProperty(CityAlias, "TitheValue") or 0
	local ChurchTreasury = GetProperty(CityAlias, "ChurchTreasury") or 0
	local ChurchIncome = GetProperty(CityAlias, "ChurchIncome") or 0
	local UnemployedCost = GetProperty(CityAlias, "UnemployedCost") or 0
	
	-- send a message to all office holders of the city
	local year = GetYear() - 1
	local Choice = 0
	local MaxLevel = CityGetHighestOfficeLevel(CityAlias)
	local Level = 0
	local Count = CityGetOfficeCountAtLevel(CityAlias, Level)
	
	for l=0, MaxLevel do
		Choice = 0
		for i=0, Count-1 do
			Choice = Count-1 - i
			if SettlementGetOffice(CityAlias, Level, 0, "OfficeToCheck") then
				if OfficeGetHolder("OfficeToCheck", "OfficeHolder") and GetDynasty("OfficeHolder", "OfficeDyn") then
					if ReadyToRepeat("OfficeDyn", "CityBalance"..GetID(CityAlias)) then
						MsgNewsNoWait("OfficeHolder", "Usher", "", "politics", -1,
									"@L_CITY_PINGHOUR_CITY_TREASURY_BALANCE_HEAD_+0",
									"@L_CITY_PINGHOUR_CITY_TREASURY_BALANCE_BODY_+0", GetID("Usher"), GetID(CityAlias), year, TaxValue, 
									TaxRaw, TaxFood, TaxHandi, TaxSchol, TaxHerbs, TaxIron, NobilityMoneyLY, FeesLY, TrialsLY, TotalIncome, 
									OfficeMoney, CostServants, CostCityGuard, CostEliteGuard, BuildingRepairs, Warcosts, TotalCost, 
									BalanceLabel, GetMoney(CityAlias), ChurchTithe, ChurchIncome, UnemployedCost, ChurchTreasury, Balance)
						SetRepeatTimer("OfficeDyn", "CityBalance"..GetID(CityAlias), 1)
					end
				end
			end
		end
		Level = Level + 1
		Count = CityGetOfficeCountAtLevel(CityAlias, Level)
	end
end