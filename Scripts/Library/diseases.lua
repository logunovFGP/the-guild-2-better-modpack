-- -----------------------
-- Init
-- -----------------------
function Init()
	--needed for caching
end

diseases = {

	["Sprain"] 		= {
	  string="Sprain",
	  medicine="Bandage",
	  favor=GL_FAVOR_MOD_SMALL,
	  cost = 200,
	  duration = 16,
	  callback = diseases_Sprain,
	  listImpact = 
	  { 3,
		{"dexterity",-2},
		{"craftsmanship",-2},
		{"fighting",-2}
	  }
	},

	["Cold"] 		= {
	  string="Cold",
	  medicine="Bandage",
	  favor=GL_FAVOR_MOD_SMALL,
	  cost = 250,
	  duration = 24,
	  callback = diseases_Cold,
	  listImpact = 
	  {
	  	10,
	  	{"constitution",-1},
	  	{"dexterity",-1},
	  	{"charisma",-1},
	  	{"fighting",-1},
	  	{"craftsmanship",-1},
	  	{"shadow_arts",-1},
	  	{"rhetoric",-1},
	  	{"empathy",-1},
	  	{"bargaining",-1},
	  	{"secret_knowledge",-1}
	  }
	},

	["Influenza"] 	= {
	  string="Influenza",
	  medicine="Medicine",
	  favor=GL_FAVOR_MOD_SMALL,
	  cost = 400,
	  duration = 16,
	  callback = diseases_Influenza,
	  listImpact = 
	  {
	  	10,
	  	{"constitution",-3},
	  	{"dexterity",-3},
	  	{"charisma",-3},
	  	{"fighting",-3},
	  	{"craftsmanship",-3},
	  	{"shadow_arts",-3},
	  	{"rhetoric",-3},
	  	{"empathy",-3},
	  	{"bargaining",-3},
	  	{"secret_knowledge",-3}
	  }
	},

	["Pox"] 		= {
	  string="Pox",
	  medicine="Medicine",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 700,
	  duration = -1,
	  callback = diseases_Pox,
	  listImpact =
	  { 3,
	  	{"constitution",-6},
	  	{"charisma",-6},
	  	{"dexterity",-6}
	  }
	},

	["BurnWound"] 	= {
	  string="BurnWound",
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 750,
	  duration = 8,
	  callback = diseases_BurnWound
	},

	["Pneumonia"] 	= {
	  string="Pneumonia",
	  medicine="Medicine",
	  favor=GL_FAVOR_MOD_GREATER,
	  cost = 800,
	  duration = 24,
	  callback = diseases_Pneumonia,
	  listImpact = 
	  {
	  	10,
	  	{"constitution",-5},
	  	{"dexterity",-5},
	  	{"charisma",-5},
	  	{"fighting",-5},
	  	{"craftsmanship",-5},
	  	{"shadow_arts",-5},
	  	{"rhetoric",-5},
	  	{"empathy",-5},
	  	{"bargaining",-5},
	  	{"secret_knowledge",-5}
	  }
	},

	["Blackdeath"] 	= {
	  string="Blackdeath",
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_LARGE,
	  cost = 1000,
	  duration = 24,
	  callback = diseases_Blackdeath,
	  listImpact = 
	  {
	  	10,
	  	{"constitution",-7},
	  	{"dexterity",-7},
	  	{"charisma",-7},
	  	{"fighting",-7},
	  	{"craftsmanship",-7},
	  	{"shadow_arts",-7},
	  	{"rhetoric",-7},
	  	{"empathy",-7},
	  	{"bargaining",-7},
	  	{"secret_knowledge",-7}
	  }
	},

	["Fracture"] 	= {
	  string="Fracture",
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 600,
	  duration = 24,
	  callback = diseases_Fracture,
	  listImpact =
	  { 3,
	  	{"craftsmanship",-4},
	  	{"Fighting",-4},
	  	{"dexterity",-4}
	  }
	},

	["Caries"] 		= {
	  string="Caries",
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 800,
	  duration = 48,
	  callback = diseases_Caries,
	  listImpact =
	  { 2,
	  	{"rhetoric",-3},
	  	{"charisma",-3}
	  }
	}

	}

--[[CodeRework: sort diseases-related calls under classes]]
local diseaseeee = {test = 1}
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
	       false = the sickness or injury should heal		 ]]

  local ID = diseases[Sickness]
  local endtime = math.mod(GetGametime(),24)+ID.duration

  if Sickness == "Pneumonia" then 
  	Sleep(1)
  end

  if State then
    if not Sickness == "BurnWound" and not disease_check(ObjectAlias, Force) then
  	  return
    end
    if GetImpactValue(ObjectAlias, Sickness) ~= 1 then
      if not Sickness == "BurnWound" then
        for i = 1,ID.listImpact[1] do
       	  AddImpact(ObjectAlias, ID.listImpact[i+1][1], ID.listImpact[i+1][2], ID.duration)
        end
  	  end
        AddImpact(ObjectAlias, Sickness, 1, ID.duration)
        AddImpact(ObjectAlias, "Sickness", 1, ID.duration)
        SetState(ObjectAlias, STATE_SICK, true)
        if not Sickness == "Caries" and not Sickness == "BurnWound" then
          SetProperty(ObjectAlias, Sickness.."Time", endtime)
        end
        if Sickness == "Pox" then
          AddImpact(ObjectAlias,"LifeExpanding", -1, -1)  -- RemoveImpact later?
        end
        if Sickness == "Pneumonia" then
          AddImpact(ObjectAlias, "LifeExpanding", -2, -1) -- RemoveImpact later?
        end
        if Sickness == "Blackdeath" then
          AddImpact(ObjectAlias, "LifeExpanding", -1, -1) -- RemoveImpact later?
        end
    end

  elseif not State and GetImpactValue(ObjectAlias, Sickness) == 1 then
  	RemoveImpact(ObjectAlias, Sickness)
  	RemoveImpact(ObjectAlias, "Sickness")
  	SetState(ObjectAlias, STATE_SICK, false)

  	if not Sickness == "BurnWound" then

  	  local new_duration = ID.duration
  	  if not Sickness == "Pox" then
  	    if math.mod(GetGametime(),24) < GetProperty(ObjectAlias, Sickness.."Time") then
  	  	  new_duration = math.floor(GetProperty(ObjectAlias,Sickness.."Time")-math.mod(GetGametime(),24))
  	    end
  	  end

  	  for i = 1,ID.listImpact[1] do
	    AddImpact(ObjectAlias, ID.listImpact[i+1][1], math.abs(ID.listImpact[i+1][2]), new_duration)
  	  end

  	  if not Sickness == "Caries" then
  	    RemoveProperty(ObjectAlias, Sickness.."Time")
  	  end

    end

  	if Sickness == "Sprain" then 
  	  MoveSetActivity(ObjectAlias)
  	end

  	if GetSettlement(ObjectAlias,"City") then
  	  chr_DecrementInfectionCount(Sickness.."Infected", "City")
  	end

  end
end

function GetTreatmentCost(Disease)
  return diseases[Disease].cost or 75
end