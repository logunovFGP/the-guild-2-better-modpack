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

diseases = {

	["Sprain"] 		= {
	  medicine="Bandage",
	  favor=GL_FAVOR_MOD_SMALL,
	  cost = 200,
	  duration = 16,
	  serialisedImpacts={-2,"134"},
	  extraCallback=MoveSetActivity
	},

	["Cold"] 		= {
	  medicine="Bandage",
	  favor=GL_FAVOR_MOD_SMALL,
	  cost = 250,
	  duration = 24,
	  serialisedImpacts={-1,"0123456789"}
	},

	["Influenza"] 	= {
	  medicine="Medicine",
	  favor=GL_FAVOR_MOD_SMALL,
	  cost = 400,
	  duration = 16,
	  serialisedImpacts={-3,"0123456789"}
	},

	["Pox"] 		= {
	  medicine="Medicine",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 700,
	  duration = -1,
	  serialisedImpacts={-6,"012"}
	},

	["BurnWound"] 	= {
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 750,
	  duration = 8
	},

	["Pneumonia"] 	= {
	  medicine="Medicine",
	  favor=GL_FAVOR_MOD_GREATER,
	  cost = 800,
	  duration = 24,
	  serialisedImpacts={-5,"0123456789"}
	},

	["Blackdeath"] 	= {
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_LARGE,
	  cost = 1000,
	  duration = 24,
	  serialisedImpacts={-7,"0123456789"}
	},

	["Fracture"] 	= {
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 600,
	  duration = 24,
	  serialisedImpacts={-4,"134"}
	},

	["Caries"] 		= {
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 800,
	  duration = 48,
	  serialisedImpacts={-3,"26"}
	}

	}

function disease_check(ObjectAlias, Force)
	LogMessage("Ran function check under class diseases")

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

	if not Force then
		if GetImpactValue(ObjectAlias, "Resist") > 0 then
			return false
		end

		if GetImpactValue("City", "Sickness") > 1 then
			return false
		end
	end
	
	if not HasProperty("City", "InfectedSims") then
		SetProperty("City", "InfectedSims", 1)
	else
		CurrentInfected = GetProperty("City", "InfectedSims") + 1
		
		if (CurrentInfected <= InfectableSims) or Force then
			SetProperty("City", "InfectedSims", CurrentInfected)
		else
			return false
		end
	end

	AddImpact("City", "Sickness", 1, 0.25)
	return true
end

function giveSickness(Sickness, ObjectAlias, State, Force)
--[[State: true  = character should get potential complications
	       false = the sickness or injury should heal]]

  local ID = diseases[Sickness]
  local endtime = math.mod(GetGametime(),24)+ID.duration

  if not Sickness == "BurnWound" then 
  	local length = string.len(ID.serialisedImpacts[2])
    local modifier = ID.serialisedImpacts[1]
  end 

  if Sickness == "Pneumonia" then 
  	Sleep(1)
  end

  if State then
    if not Sickness == "BurnWound" and not disease_check(ObjectAlias, Force) then
  	  return
    end
    if GetImpactValue(ObjectAlias, Sickness) ~= 1 then
      if not Sickness == "BurnWound" then
        for i = 1,length do
          local skill = skills[string.sub(ID.serialisedImpacts[2],i,i)]
       	  AddImpact(ObjectAlias, skill, modifier, ID.duration)
        end
  	  end

  	    diseases_ImpactManager(true, ObjectAlias, Sickness, ID.duration)
        diseases_NoTime(ObjectAlias, Sickness, endtime, true)

        if Sickness == "Pox" or Sickness == "Blackdeath" then
          AddImpact(ObjectAlias,"LifeExpanding", -1, -1)  -- RemoveImpact later?
        end
        if Sickness == "Pneumonia" then
          AddImpact(ObjectAlias, "LifeExpanding", -2, -1) -- RemoveImpact later?
        end
    end

  elseif not State and GetImpactValue(ObjectAlias, Sickness) == 1 then
  	diseases_ImpactManager(false, ObjectAlias, Sickness, 0)
    diseases_NoTime(ObjectAlias, Sickness, 0, false)

  	if not Sickness == "BurnWound" then

  	  local new_duration = ID.duration
  	  if not Sickness == "Pox" then
  	    if math.mod(GetGametime(),24) < GetProperty(ObjectAlias, Sickness.."Time") then
  	  	  new_duration = math.floor(GetProperty(ObjectAlias,Sickness.."Time")-math.mod(GetGametime(),24))
  	    end
  	  end

  	  for i = 1,length do
  	  	local skill = skills[string.sub(ID.serialisedImpacts[2],i,i)]
	    AddImpact(ObjectAlias, skill, math.abs(modifier), new_duration)
  	  end

    end

    if ID.extraCallback ~= nil then
      ID.extraCallback(ObjectAlias)
    end

  	if GetSettlement(ObjectAlias,"City") then
  	  chr_DecrementInfectionCount(Sickness.."Infected", "City")
  	end

  end
end

function GetTreatmentCost(Disease)
  return diseases[Disease].cost or 75
end