-- -----------------------
-- Init
-- -----------------------
function Init()
	--needed for caching
end

-- helper functions
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

function NoTime(Boolean, ObjectAlias, Sickness, endtime)
  if not Sickness == "Caries" and not Sickness == "BurnWound" then
    if Boolean == true then
      SetProperty(ObjectAlias, Sickness.."Time", endtime)
    else
      RemoveProperty(ObjectAlias, Sickness.."Time")
    end
  end
end
-- end of helper functions

skills = 
{
	["0"] = "constitution",
	["1"] = "dexterity",
	["2"] = "charisma",
	["3"] = "fighting",
	["4"] = "craftsmanship",
	["5"] = "shadow_arts",
	["6"] = "rhetoric",
	["7"] = "empathy",
	["8"] = "bargaining",
	["9"] = "secret_knowledge"
}

diseases = {}

local newDisease = function(name, medicine, favor, cost, duration, impacts1, impacts2, callback)
    local self = {
        name = name,
        medicine = medicine,
        favor = favor,
        cost = cost,
        duration = duration,
        impacts1 = impacts1,
      	impacts2 = impacts2,
        callback = callback
    }

    -- for the following functions I decided to go for <self.function> instead of <local function> because it seemed to break calls

    self.infectSim = function(ObjectAlias)
        LogMessage("CodeRework, Medical. " .. GetName(ObjectAlias) .. " is suffering from: " .. (self.name))
        diseases_giveSickness(self,ObjectAlias)
    end

    self.cureSim = function(ObjectAlias)
        diseases_removeSickness(self,ObjectAlias)
    end

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

		self.getCallback = function()
			return self.callback or nil
		end

    LogMessage("CodeRework, Medical. Class " .. self.name .. " has successfully been created!")
    return self

end
--edd
Sprain 			 = newDisease("Sprain","Bandage",GL_FAVOR_MOD_SMALL,200,16,-2,"134",MoveSetActivity)
Cold 		  	 = newDisease("Cold","Bandage",GL_FAVOR_MOD_SMALL,250,24,-1,"0123456789",nil)
Influenza 	 = newDisease("Influenza","Medicine",GL_FAVOR_MOD_SMALL,400,16,-3,"0123456789",nil)
Pox          = newDisease("Pox","Medicine",GL_FAVOR_MOD_NORMAL,700,-1,-6,"012",nil)
BurnWound    = newDisease("BurnWound","PainKiller",GL_FAVOR_MOD_NORMAL,750,8,1,"0000",nil)
Pneumonia    = newDisease("Pneumonia","Medicine",GL_FAVOR_MOD_GREATER,800,24,-5,"0123456789",nil)
Blackdeath   = newDisease("Blackdeath","PainKiller",GL_FAVOR_MOD_LARGE,1000,24,-7,"0123456789",nil)
Fracture     = newDisease("Fracture","PainKiller",GL_FAVOR_MOD_NORMAL,600,24,-4,"134",nil)
Caries       = newDisease("Caries","PainKiller",GL_FAVOR_MOD_NORMAL,800,48,-3,"26",nil)
allDiseases = {Sprain,Cold,Influenza,Pox,BurnWound,Pneumonia,Blackdeath,Fracture,Caries}

-- this list will be removed
diseases.list = {"Sprain","Cold","Influenza","Pox","BurnWound","Pneumonia","Blackdeath","Fracture","Caries",
["1"]="Sprain",["2"]="Cold",["3"]="Influenza",["4"]="Pox",["5"]="BurnWound",["6"]="Pneumonia",["7"]="Blackdeath",["8"]="Fracture",["9"]="Caries"}


-- Suggestion ToM: only expose a single table as global variable

Disease = 
{
-- inserting functions directly within Disease causes the game to crash on boot.
}

Disease.infectSim = 
	function(ObjectAlias,Class)
		local Result = Disease[Class]
    LogMessage("CodeRework, Medical. " .. GetName(ObjectAlias) .. " is suffering from: " .. Result:getName())
    diseases_giveSickness(Result,ObjectAlias)
  end

Disease.cureSim = 
  function(ObjectAlias,Class)
  	local Result = Disease[Class]
    diseases_removeSickness(Result,ObjectAlias)
  end

Disease.Sprain       = newDisease("Sprain","Bandage",GL_FAVOR_MOD_SMALL,200,16,-2,"134",MoveSetActivity)
Disease.Cold 		  	 = newDisease("Cold","Bandage",GL_FAVOR_MOD_SMALL,250,24,-1,"0123456789",nil)
Disease.Influenza 	 = newDisease("Influenza","Medicine",GL_FAVOR_MOD_SMALL,400,16,-3,"0123456789",nil)
Disease.Pox          = newDisease("Pox","Medicine",GL_FAVOR_MOD_NORMAL,700,-1,-6,"012",nil)
Disease.BurnWound    = newDisease("BurnWound","PainKiller",GL_FAVOR_MOD_NORMAL,750,8,1,"0000",nil)
Disease.Pneumonia    = newDisease("Pneumonia","Medicine",GL_FAVOR_MOD_GREATER,800,24,-5,"0123456789",nil)
Disease.Blackdeath   = newDisease("Blackdeath","PainKiller",GL_FAVOR_MOD_LARGE,1000,24,-7,"0123456789",nil)
Disease.Fracture     = newDisease("Fracture","PainKiller",GL_FAVOR_MOD_NORMAL,600,24,-4,"134",nil)
Disease.Caries       = newDisease("Caries","PainKiller",GL_FAVOR_MOD_NORMAL,800,48,-3,"26",nil)
DiseaseNames = {"Sprain","Cold","Influenza","Pox","BurnWound","Pneumonia","Blackdeath","Fracture","Caries"}

--attempt to index local `Result' (a nil value)

--- This will return an iterator over all diseases.
-- Example: 

function GetDiseaseIterator()
	return diseases_DiseaseIterator, Disease, 0
end

function DiseaseIterator(t, i)
	i = i + 1
	local v = DiseaseNames[i]
	if v then
		return i, t[v]
	end
end

function removeSickness(Illness,ObjectAlias)

	if GetImpactValue(ObjectAlias, Illness:getName()) and GetImpactValue(ObjectAlias, Illness:getName()) == 1 then

		local length, modifier

	  if Illness:getName() ~= "BurnWound" then 
	  	length = string.len(Illness.impacts2)
	    modifier = Illness.impacts1
	  end 

	  if Illness:getName() == "Pneumonia" then 
	  	Sleep(1)
	  end

  	LogMessage("CodeRework, Medical. " .. GetName(ObjectAlias) .. " has been cured from: " .. Illness:getName()--[[()]])

  	diseases_ImpactManager(false, ObjectAlias, Illness:getName(), 0)
    diseases_NoTime(ObjectAlias, Illness:getName(), 0, false)

  	if Illness:getName() ~= "BurnWound" then

  	  local new_duration = Illness.getDuration()
  	  if not Illness:getName() == "Pox" then
  	    if math.mod(GetGametime(),24) < GetProperty(ObjectAlias, Illness:getName().."Time") then
  	  	  new_duration = math.floor(GetProperty(ObjectAlias,Illness:getName().."Time")-math.mod(GetGametime(),24))
  	    end
  	  end

  	  for i = 1,length do
	  	  local skill = skills[string.sub(Illness.impacts2,i,i)]
		    AddImpact(ObjectAlias, skill, -modifier, new_duration)
  	  end

    end

    if Illness.getCallback() ~= nil then
      Illness.callback(ObjectAlias)
    end

  	if GetSettlement(ObjectAlias,"City") then
  	  chr_DecrementInfectionCount(Illness:getName().."Infected", "City")
  	end
	end
end

function removeAllSickness(ObjectAlias)
	for k, v in diseases_GetDiseaseIterator() do		
		if GetImpactValue(ObjectAlias, v.getName()) == 1 then
			Disease.cureSim(ObjectAlias,v.getName())
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
	local length, modifier = 0,0
	local skill, tempdur
	local endtime

  if Illness:getName() == "Pneumonia" then 
		Sleep(1)
  end

  if Illness:getName() ~= "BurnWound" then 
		length = string.len(Illness.impacts2)
		modifier = Illness.impacts1
  end 

  if not Illness:getName() == "BurnWound" and not diseases_checkSickness(ObjectAlias) then
		return 
  end

	tempdur = Illness.getDuration()

  endtime = math.mod(GetGametime(),24)+tempdur
  
	if GetImpactValue(ObjectAlias, Illness:getName()) and GetImpactValue(ObjectAlias, Illness:getName()) ~= 1 then

		if length then
      for i = 1,length do
        if Illness:getName() == 'BurnWound' then 
        	break 
        end
	        skill = skills[string.sub(Illness.impacts2,i,i)]
	       	AddImpact(ObjectAlias, skill, modifier, Illness.getDuration())
  	  end
  	end

		diseases_ImpactManager(true, ObjectAlias, Illness:getName(), Illness.getDuration())
		diseases_NoTime(ObjectAlias, Illness:getName(), endtime, true)

		if Illness:getName() == "Pox" or Illness:getName() == "Blackdeath" then
			AddImpact(ObjectAlias,"LifeExpanding", -1, -1) 
		end

		if Illness:getName() == "Pneumonia" then
			AddImpact(ObjectAlias, "LifeExpanding", -2, -1) 
		end
  end
end
