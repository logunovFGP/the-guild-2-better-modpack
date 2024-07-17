-- -----------------------
-- Init
-- -----------------------
function Init()
	--needed for caching
end

function ImpactManager(Boolean, ObjectAlias, Sickness, Duration)
	
	if Boolean then 
		AddImpact(ObjectAlias, Sickness, 1, Duration)
		AddImpact(ObjectAlias, "Sickness", 1, Duration)
	else
		RemoveImpact(ObjectAlias, Sickness)
		RemoveImpact(ObjectAlias, "Sickness")
	end
	SetState(ObjectAlias, STATE_SICK, Boolean)
end

function NoTime(Boolean, ObjectAlias, Sickness, Endtime)
	
	if not Sickness == "Caries" and not Sickness == "BurnWound" then
		if Boolean then
			SetProperty(ObjectAlias, Sickness.."Time", Endtime)
		else
			RemoveProperty(ObjectAlias, Sickness.."Time")
		end
	end
end

local newDisease = function(name, medicine, favor, cost, duration, impacts1, impacts2)
	
	local self = {
			name = name,
			medicine = medicine,
			favor = favor,
			cost = cost,
			duration = duration,
			impacts1 = impacts1,
			impacts2 = impacts2
			}

    -- for the following functions I decided to go for <self.function> instead of <local function> because it seemed to break calls
    -- To use those functions in your scripts, replace 'self' with Disease.Cold (or any other, see below)

	self.getName = function()
		return self.name
	end

	self.getMedicine = function()
	  	return self.medicine
	end

	self.getFavor = function()
		return self.favor
	end

	self.getCost = function()
		return self.cost
	end

	self.getDuration = function()
		return self.duration
	end

	self.getImpacts = function()
		return { self.impacts1, self.impacts2 }
	end

	self.cureSim = function(targetSickness, targetObject)
		diseases_removeSickness(targetSickness, targetObject)
	end

	self.infectSim = function(targetSickness, targetObject)
		diseases_giveSickness(targetSickness, targetObject)
	end

	LogMessage("CodeRework, Medical. Class " .. self.name .. " has successfully been created!")
	return self
end

-- global variable to start the functions
Disease = { } -- inserting functions directly within Disease causes the game to crash on boot.

Disease.Sprain		= newDisease("Sprain",		"Bandage",		GL_FAVOR_MOD_SMALL,		200,	16,	-2,	{ "dexterity", "fighting", "craftsmanship" })
Disease.Cold		= newDisease("Cold",		"Bandage",		GL_FAVOR_MOD_SMALL,		250,	24,	-1,	{ "constitution", "dexterity", "charisma", "fighting", "craftsmanship", "shadow_arts", "rhetoric", "empathy", "bargaining", "secret_knowledge" })
Disease.Influenza	= newDisease("Influenza",	"Medicine",		GL_FAVOR_MOD_SMALL,		400,	16,	-3,	{ "constitution", "dexterity", "charisma", "fighting", "craftsmanship", "shadow_arts", "rhetoric", "empathy", "bargaining", "secret_knowledge" })
Disease.Pox			= newDisease("Pox",			"Medicine",		GL_FAVOR_MOD_NORMAL,	700,	-1,	-6,	{ "constitution", "dexterity", "charisma" })
Disease.BurnWound	= newDisease("BurnWound",	"PainKiller",	GL_FAVOR_MOD_NORMAL,	750,	8,	1,	nil)
Disease.Pneumonia	= newDisease("Pneumonia",	"Medicine",		GL_FAVOR_MOD_GREATER,	800,	24,	-5,	{ "constitution", "dexterity", "charisma", "fighting", "craftsmanship", "shadow_arts", "rhetoric", "empathy", "bargaining", "secret_knowledge" })
Disease.Blackdeath	= newDisease("Blackdeath",	"Medicine",	GL_FAVOR_MOD_LARGE,		1000,	24,	-7,	{ "constitution", "dexterity", "charisma", "fighting", "craftsmanship", "shadow_arts", "rhetoric", "empathy", "bargaining", "secret_knowledge" })
Disease.Fracture	= newDisease("Fracture",	"PainKiller",	GL_FAVOR_MOD_NORMAL,	600,	24,	-4,	{ "dexterity", "fighting", "craftsmanship" })
Disease.Caries		= newDisease("Caries",		"PainKiller",	GL_FAVOR_MOD_NORMAL,	800,	48,	-3, { "charisma", "rhetoric" })
Disease.Names		= { "Sprain", "Cold","Influenza", "Pox", "BurnWound", "Pneumonia", "Blackdeath", "Fracture", "Caries" }

function GetDiseaseIterator()
	return diseases_DiseaseIterator, Disease, 0
end

function DiseaseIterator(t, i)
	i = i + 1
	local v = Disease.Names[i]
	if v then
		return i, t[v]
	end
end

function GetSkillIterator(Disease)
	return diseases_SkillIterator, Disease, 0
end

function SkillIterator(t, i)
	i = i + 1
	local v = Disease[t].getImpacts()[2]
	if v[i] then
		return i, v[i]
	end
end

function removeSickness(Illness, ObjectAlias)

	if GetImpactValue(ObjectAlias, Illness:getName()) and GetImpactValue(ObjectAlias, Illness:getName()) == 1 then

		--LogMessage("CodeRework, Medical. " .. GetName(ObjectAlias) .. " has been cured from: " .. Illness:getName())

		diseases_ImpactManager(false, ObjectAlias, Illness:getName(), 0)
		diseases_NoTime(ObjectAlias, Illness:getName(), 0, false)

		if Illness:getName() ~= "BurnWound" then

			local new_duration = Illness.getDuration()
			if not Illness:getName() == "Pox" then
				if math.mod(GetGametime(),24) < GetProperty(ObjectAlias, Illness:getName().."Time") then
					new_duration = math.floor(GetProperty(ObjectAlias,Illness:getName().."Time")-math.mod(GetGametime(),24))
				end
			end

			local impacts = Illness.getImpacts()

			for k, v in diseases_GetSkillIterator(Illness.getName()) do
				AddImpact(ObjectAlias, v, -impacts[1], new_duration)
			end

		end

		if GetSettlement(ObjectAlias,"City") then
			chr_DecrementInfectionCount(Illness:getName().."Infected", "City")
		end
	end
end

function removeAllSickness(ObjectAlias)
	for k, v in diseases_GetDiseaseIterator() do		
		if GetImpactValue(ObjectAlias, v.getName()) == 1 then
			Disease[v.getName()]:cureSim(ObjectAlias)
		end		
	end
end

function checkSickness(ObjectAlias)

	if not GetSettlement(ObjectAlias, "City") then
		return false
	end
	
	if GetState(ObjectAlias, STATE_DEAD) then
		return false
	end
	
	local CurrentInfected = 0
	local InfectableSims = CityGetCitizenCount("City") / 4

	if InfectableSims <= 0 then
		return false
	end

	if GetImpactValue(ObjectAlias, "Sickness") > 0 then
		return false
	end

	if GetImpactValue(ObjectAlias, "Resist") > 0 then
		return false
	end
	
	-- ability
	local Alchemist = GetImpactValue(ObjectAlias, "IllnessResist")
	if (Rand(100) + 1) <= Alchemist then
		return false
	end
	
	if GetImpactValue("City", "Sickness") > 1 then
		return false
	end
	
	if not HasProperty("City", "InfectedSims") then
		SetProperty("City", "InfectedSims", 1)
	else
		CurrentInfected = GetProperty("City", "InfectedSims") + 1
		
		if (CurrentInfected <= InfectableSims) then
			SetProperty("City", "InfectedSims", CurrentInfected)
		else
			return false
		end
	end

	AddImpact("City", "Sickness", 1, 0.25)
	return true
end

function giveSickness(Illness, ObjectAlias)
	
	if Illness:getName() == nil then 
		LogMessage("Illness is nil!") 
		return		
	end

	--LogMessage("CodeRework, Medical. " .. GetName(ObjectAlias) .. " has been infected with: " .. Illness:getName())

	local skill, tempdur
	local endtime

	if Illness:getName() == "Pneumonia" then 
		--Sleep(1)
	end

	-- check whether the object actually gets infected or not
	if not Illness:getName() == "BurnWound" and not diseases_checkSickness(ObjectAlias) then
		LogMessage(GetName(ObjectAlias).." ID: "..GetID(ObjectAlias).." resisted against sickness")
		return 
	end

	tempdur = Illness.getDuration()
	endtime = math.mod(GetGametime(),24) + tempdur
  
	if GetImpactValue(ObjectAlias, Illness:getName()) and GetImpactValue(ObjectAlias, Illness:getName()) ~= 1 then

		if Illness:getName() ~= "BurnWound" then
			local impacts, listSkills

			impacts = Illness.getImpacts()
			listSkills = impacts[2]

			for k, v in diseases_GetSkillIterator(Illness.getName()) do
				AddImpact(ObjectAlias, v, impacts[1], Illness.getDuration())
			end
		end

		diseases_ImpactManager(true, ObjectAlias, Illness:getName(), Illness.getDuration())
		diseases_NoTime(ObjectAlias, Illness:getName(), endtime, true)
		
		-- severe diseases reduce life expectancy permanently by 1 or 2 years
		if Illness:getName() == "BurnWound" or Illness:getName() == "Fracture" then
			AddImpact(ObjectAlias, "LifeExpanding", -1, -1) 
		end

		if Illness:getName() == "Pox" or Illness:getName() == "Pneumonia" or Illness:getName() == "BlackDeath" then
			AddImpact(ObjectAlias, "LifeExpanding", -2, -1) 
		end
	end
end
