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
allDiseases = {}

disease = {}

local newDisease = function(name, medicine, favor, cost, duration, impacts, callback)
    local self = {
        name = name,
        medicine = medicine,
        favor = favor,
        cost = cost,
        duration = duration,
        serialisedImpacts = impacts,
        callback = callback
    }

    local getName = function() -- example
        return self.name
    end

    local infectSim = function(ObjectAlias)
        LogMessage("CodeRework, Medical. " .. GetName(ObjectAlias) .. " is suffering from: " .. self.name)
        diseases_giveSickness(self,ObjectAlias)
    end

    local cureSim = function(ObjectAlias)
        diseases_removeSickness(self,ObjectAlias)
    end

    LogMessage("CodeRework, Medical. Class " .. self.name .. " has successfully been created!")
    return {
        getName = getName,
        infectSim = infectSim,
        cureSim = cureSim
    }

end

Sprain 			 = newDisease("Sprain","Bandage",GL_FAVOR_MOD_SMALL,200,16,{-2,"134"},MoveSetActivity)
Cold 		  	 = newDisease("Cold","Bandage",GL_FAVOR_MOD_SMALL,250,24,{-1,"0123456789"},nil)
Influenza 	 = newDisease("Influenza","Medicine",GL_FAVOR_MOD_SMALL,400,16,{-3,"0123456789"},nil)
Pox          = newDisease("Pox","Medicine",GL_FAVOR_MOD_NORMAL,700,-1,{-6,"012"},nil)
BurnWound    = newDisease("BurnWound","PainKiller",GL_FAVOR_MOD_NORMAL,750,8,{1,"0"},nil)
Pneumonia    = newDisease("Pneumonia","Medicine",GL_FAVOR_MOD_GREATER,800,24,{-5,"0123456789"},nil)
Blackdeath   = newDisease("Blackdeath","PainKiller",GL_FAVOR_MOD_LARGE,1000,24,{-7,"0123456789"},nil)
Fracture     = newDisease("Fracture","PainKiller",GL_FAVOR_MOD_NORMAL,600,24,{-4,"134"},nil)
Caries       = newDisease("Caries","PainKiller",GL_FAVOR_MOD_NORMAL,800,48,{-3,"26"},nil)
allDiseases = {Sprain,Cold,Influenza,Pox,BurnWound,Pneumonia,Blackdeath,Fracture,Caries}

-- this list will be removed
diseases.list = {"Sprain","Cold","Influenza","Pox","BurnWound","Pneumonia","Blackdeath","Fracture","Caries",
["1"]="Sprain",["2"]="Cold",["3"]="Influenza",["4"]="Pox",["5"]="BurnWound",["6"]="Pneumonia",["7"]="Blackdeath",["8"]="Fracture",["9"]="Caries"}

function removeSickness(Illness,ObjectAlias)
	if GetImpactValue(ObjectAlias, Illness.name) == 1 then

		local length, modifier

	  if Illness.name ~= "BurnWound" then 
	  	length = string.len(Illness.serialisedImpacts[2])
	    modifier = Illness.serialisedImpacts[1]
	  end 

	  if Illness.name == "Pneumonia" then 
	  	Sleep(1)
	  end

  	LogMessage("CodeRework, Medical. " .. GetName(ObjectAlias) .. " has been cured from: " .. Illness.name)

  	diseases_ImpactManager(false, ObjectAlias, Illness.name, 0)
    diseases_NoTime(ObjectAlias, Illness.name, 0, false)

  	if not Illness.name == "BurnWound" then

  	  local new_duration = Illness.duration
  	  if not Illness.name == "Pox" then
  	    if math.mod(GetGametime(),24) < GetProperty(ObjectAlias, Illness.name.."Time") then
  	  	  new_duration = math.floor(GetProperty(ObjectAlias,Illness.name.."Time")-math.mod(GetGametime(),24))
  	    end
  	  end

  	  for i = 1,length do
  	  	local skill = skills[string.sub(Illness.serialisedImpacts[2],i,i)]
	    	AddImpact(ObjectAlias, skill, math.abs(modifier), new_duration)
  	  end

    end

    if Illness.extraCallback ~= nil then
      Illness.extraCallback(ObjectAlias)
    end

  	if GetSettlement(ObjectAlias,"City") then
  	  chr_DecrementInfectionCount(Illness.name.."Infected", "City")
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

	local length, modifier, skill
  local endtime = math.mod(GetGametime(),24)+Illness.duration

  if Illness.name ~= "BurnWound" then 
		length = string.len(Illness.serialisedImpacts[2])
		modifier = Illness.serialisedImpacts[1]
  end 

  if Illness.name == "Pneumonia" then 
		Sleep(1)
  end

  if not Illness.name == "BurnWound" and not diseases_checkSickness(ObjectAlias) then
		return 
  end
  
	if GetImpactValue(ObjectAlias, Illness.name) ~= 1 then

		if length then
      for i = 1,length do
        if Illness.name == 'BurnWound' then 
        	break 
        end
	        skill = skills[string.sub(Illness.serialisedImpacts[2],i,i)]
	       	AddImpact(ObjectAlias, skill, modifier, Illness.duration)
  	  end
  	end

		diseases_ImpactManager(true, ObjectAlias, Illness.name, Illness.duration)
		diseases_NoTime(ObjectAlias, Illness.name, endtime, true)

		if Illness.name == "Pox" or Illness.name == "Blackdeath" then
			AddImpact(ObjectAlias,"LifeExpanding", -1, -1) 
		end

		if Illness.name == "Pneumonia" then
			AddImpact(ObjectAlias, "LifeExpanding", -2, -1) 
		end
  end
end