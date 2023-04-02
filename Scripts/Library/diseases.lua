-- -----------------------
-- Init
-- -----------------------
function Init()
	--needed for caching
end

	diseases = 
	{
	["Sprain"] 		= {
	  string="Sprain",
	  medicine="Bandage",
	  favor=GL_FAVOR_MOD_SMALL,
	  cost = 200,
	  duration = 16,
	  callback = diseases_Sprain
	},

	["Cold"] 		= {
	  string="Cold",
	  medicine="Bandage",
	  favor=GL_FAVOR_MOD_SMALL,
	  cost = 250,
	  duration = 24,
	  callback = diseases_Cold
	},

	["Influenza"] 	= {
	  string="Influenza",
	  medicine="Medicine",
	  favor=GL_FAVOR_MOD_SMALL,
	  cost = 400,
	  duration = 16,
	  callback = diseases_Influenza
	},

	["Pox"] 		= {
	  string="Pox",
	  medicine="Medicine",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 700,
	  duration = -1,
	  callback = diseases_Pox
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
	  callback = diseases_Pneumonia
	},

	["Blackdeath"] 	= {
	  string="Blackdeath",
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_LARGE,
	  cost = 1000,
	  duration = 24,
	  callback = diseases_Blackdeath
	},

	["Fracture"] 	= {
	  string="Fracture",
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 600,
	  duration = 24,
	  callback = diseases_Fracture
	},

	["Caries"] 		= {
	  string="Caries",
	  medicine="PainKiller",
	  favor=GL_FAVOR_MOD_NORMAL,
	  cost = 800,
	  duration = 48,
	  callback = diseases_Caries
	}

	}

function CheckDisease(ObjectAlias, Force)
	
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

-- -----------------------
-- LEVEL 1 DISEASES
-- -----------------------

-- -----------------------
-- Sprain / Verstauchung
-- -----------------------

function Sprain(ObjectAlias, State, Force)
	-- State: true = character should get a fracture, false = the fracture should heal
	
	local DUR = diseases["Sprain"].duration
	local endtime = math.mod(GetGametime(),24)+DUR

	if State and not diseases_CheckDisease(ObjectAlias, Force) then
		return		
	end

	if State and GetImpactValue(ObjectAlias, "Sprain") ~= 1 then
	local data = {
		{"Sprain", 1},
		{"Sickness", 1},
		--[[{"MoveSpeed", 0.8},]]
		{"dexterity", -2},
		{"craftsmanship", -2},
		{"fighting", -2}
	}

	for i = 1, 5 do
		AddImpact(ObjectAlias, data[i][1], data[i][2], DUR)
	end

			SetState(ObjectAlias, STATE_SICK, true)
			SetProperty(ObjectAlias, "SprainTime", endtime)
	elseif not State and GetImpactValue(ObjectAlias, "Sprain") == 1 then
			RemoveImpact(ObjectAlias, "Sprain")
			RemoveImpact(ObjectAlias, "Sickness")
			SetState(ObjectAlias, STATE_SICK, false)
			
			--RemoveImpact(ObjectAlias,"MoveSpeed")
			-- instead of RemoveImpact we add a impact for the rest of the time
			if math.mod(GetGametime(),24) < GetProperty(ObjectAlias, "SprainTime") then
				duration = math.floor(GetProperty(ObjectAlias,"SprainTime")-math.mod(GetGametime(),24))
				AddImpact(ObjectAlias, "dexterity", 2, duration)
				AddImpact(ObjectAlias, "craftsmanship", 2, duration)
				AddImpact(ObjectAlias, "fighting", 2, duration)
				RemoveProperty(ObjectAlias, "SprainTime")
				MoveSetActivity(ObjectAlias)
			end
			
			if GetSettlement(ObjectAlias, "City") then
				chr_DecrementInfectionCount("SprainInfected", "City")
			end
		end
	end

-- -----------------------
-- Cold / Erkaeltung
-- -----------------------
function Cold(ObjectAlias, State, Force)
	-- State: true = character should get a dysentery, false = the dysentery should heal
	
	local DUR = diseases["Cold"].duration
	local modifier = 1 -- all talents
	local endtime = math.mod(GetGametime(),24)+DUR
	local TalentList = {"constitution", "dexterity", "charisma", "fighting", "craftsmanship", "shadow_arts", 
					"rhetoric", "empathy", "bargaining", "secret_knowledge" }

	if State == true then
		if not diseases_CheckDisease(ObjectAlias, Force) then
			return		
		end
		
		if not (GetImpactValue(ObjectAlias, "Cold") == 1) then
			AddImpact(ObjectAlias, "Cold", 1, DUR)
			AddImpact(ObjectAlias, "Sickness", 1, DUR)
			SetState(ObjectAlias, STATE_SICK, true)
			SetProperty(ObjectAlias, "ColdTime", endtime)
			
			-- add malus
			for i=1, 10 do
				AddImpact(ObjectAlias, TalentList[i], -1, DUR)
			end
		end
	else
		if (GetImpactValue(ObjectAlias,"Cold")==1) then
			RemoveImpact(ObjectAlias,"Cold")
			RemoveImpact(ObjectAlias,"Sickness")
			SetState(ObjectAlias,STATE_SICK,false)
			-- instead of RemoveImpact we add a impact for the rest of the time
			if math.mod(GetGametime(),24) < GetProperty(ObjectAlias, "ColdTime") then
				duration = math.floor(GetProperty(ObjectAlias,"ColdTime")-math.mod(GetGametime(),24))
				RemoveProperty(ObjectAlias, "ColdTime")
				
				-- add bonus
				for i=1, 10 do
					AddImpact(ObjectAlias, TalentList[i], 1, duration)
				end
			end
			
			if GetSettlement(ObjectAlias,"City") then
				chr_DecrementInfectionCount("ColdInfected", "City")
			end
		end
	end
end

-- -----------------------
-- LEVEL 2 DISEASES
-- -----------------------
-- -----------------------
-- Influenza / Grippe
-- -----------------------
function Influenza(ObjectAlias, State, Force)
	-- State: true = character should get a dysentery, false = the dysentery should heal
	
	local DUR = diseases["Influenza"].duration
	local endtime = math.mod(GetGametime(),24)+DUR
	local TalentList = {"constitution", "dexterity", "charisma", "fighting", "craftsmanship", "shadow_arts", 
					"rhetoric", "empathy", "bargaining", "secret_knowledge" }
		
	if State == true then
		if not diseases_CheckDisease(ObjectAlias, Force) then
			return		
		end
		
		if not (GetImpactValue(ObjectAlias,"Influenza") == 1) then
			AddImpact(ObjectAlias, "Influenza", 1, DUR)
			AddImpact(ObjectAlias, "Sickness", 1, DUR)
			SetState(ObjectAlias, STATE_SICK, true)
			SetProperty(ObjectAlias, "InfluenzaTime", endtime)

			-- add malus
			for i=1, 10 do
				AddImpact(ObjectAlias, TalentList[i], -3, DUR)
			end
		end
	else
		if (GetImpactValue(ObjectAlias,"Influenza") == 1) then
			RemoveImpact(ObjectAlias, "Influenza")
			RemoveImpact(ObjectAlias, "Sickness")
			SetState(ObjectAlias, STATE_SICK,false)
			-- instead of RemoveImpact we add a impact for the rest of the time
			if math.mod(GetGametime(),24) < GetProperty(ObjectAlias, "InfluenzaTime") then
				duration = math.floor(GetProperty(ObjectAlias, "InfluenzaTime")-math.mod(GetGametime(),24))
				RemoveProperty(ObjectAlias, "InfluenzaTime")
				
				-- add bonus
				for i=1, 10 do
					AddImpact(ObjectAlias, TalentList[i], 3, duration)
				end
			end
			
			if GetSettlement(ObjectAlias, "City") then
				chr_DecrementInfectionCount("InfluenzaInfected", "City")				
			end
		end
	end
end
-- -----------------------
-- Burn / Brandwunde
-- -----------------------
function BurnWound(ObjectAlias, State)
	-- State: true = character should get a fracture, false = the fracture should heal
	
	local DUR = diseases["BurnWound"].duration

	if State == true then
		if not (GetImpactValue(ObjectAlias,"BurnWound")==1) then
			AddImpact(ObjectAlias,"BurnWound",1,DUR)
			AddImpact(ObjectAlias,"Sickness",1,DUR)
			SetState(ObjectAlias,STATE_SICK,true)
		end
	else
		if GetImpactValue(ObjectAlias,"BurnWound")==1 then
			RemoveImpact(ObjectAlias,"BurnWound")
			RemoveImpact(ObjectAlias,"Sickness")
			SetState(ObjectAlias,STATE_SICK,false)

			if GetSettlement(ObjectAlias,"City") then
				chr_DecrementInfectionCount("BurnWoundInfected", "City")	
			end
		end
	end
end


-- -----------------------
-- Leprosy (intern Pox) / Lepra
-- -----------------------
function Pox(ObjectAlias, State, Force)
	-- State: true = character should get a fracture, false = the fracture should heal
	
	local DUR = diseases["Pox"].duration
	local modifier = 6
	
	if State == true then
		if not diseases_CheckDisease(ObjectAlias,Force) then
			return		
		end
		if not (GetImpactValue(ObjectAlias,"Pox")==1) then
			AddImpact(ObjectAlias,"Pox",1,DUR)
			AddImpact(ObjectAlias,"Sickness",1,DUR)
			SetState(ObjectAlias,STATE_SICK,true)
			
			AddImpact(ObjectAlias,"LifeExpanding", -1, -1) -- lose lifetime on infection
			AddImpact(ObjectAlias,"constitution",-6,DUR)
			AddImpact(ObjectAlias,"charisma",-6,DUR)
			AddImpact(ObjectAlias,"dexterity", -6, DUR)
		end
	else
		if GetImpactValue(ObjectAlias,"Pox")==1 then
			RemoveImpact(ObjectAlias,"Pox")
			RemoveImpact(ObjectAlias,"Sickness")
			SetState(ObjectAlias,STATE_SICK, false)
			
			AddImpact(ObjectAlias,"constitution", 6, DUR)
			AddImpact(ObjectAlias,"charisma", 6, DUR)
			AddImpact(ObjectAlias,"dexterity", 6, DUR)


			if GetSettlement(ObjectAlias,"City") then
				chr_DecrementInfectionCount("PoxInfected", "City")				
			end
		end
	end
end
-- -----------------------
-- LEVEL 3 DISEASES
-- -----------------------
-- -----------------------
-- Pneumonia / lungenentzuendung
-- -----------------------
function Pneumonia(ObjectAlias, State, Force)
	-- State: true = character should get a dysentery, false = the dysentery should heal
	
	local DUR = diseases["Pneumonia"].duration
	local endtime = math.mod(GetGametime(),24)+5
	local TalentList = {"constitution", "dexterity", "charisma", "fighting", "craftsmanship", "shadow_arts", 
					"rhetoric", "empathy", "bargaining", "secret_knowledge" }
	
	Sleep(1)
	if State == true then
		if not diseases_CheckDisease(ObjectAlias, Force) then
			return		
		end
		
		if not (GetImpactValue(ObjectAlias,"Pneumonia") == 1) then
			AddImpact(ObjectAlias, "LifeExpanding", -2, -1) -- lose lifetime on infection
			AddImpact(ObjectAlias, "Pneumonia", 1, 5)
			AddImpact(ObjectAlias, "Sickness", 1, 5)
			SetState(ObjectAlias, STATE_SICK, true)
			SetProperty(ObjectAlias, "PneumoniaTime", endtime)

			-- add malus
			for i=1, 10 do
				AddImpact(ObjectAlias, TalentList[i], -5, 5)
			end
		end
	else
		if (GetImpactValue(ObjectAlias, "Pneumonia")==1) then
			RemoveImpact(ObjectAlias, "Pneumonia")
			RemoveImpact(ObjectAlias, "Sickness")
			SetState(ObjectAlias,STATE_SICK, false)
			-- instead of RemoveImpact we add a impact for the rest of the time
			if math.mod(GetGametime(),24) < GetProperty(ObjectAlias, "PneumoniaTime") then
				duration = math.floor(GetProperty(ObjectAlias, "PneumoniaTime")-math.mod(GetGametime(),24))
				RemoveProperty(ObjectAlias, "PneumoniaTime")
				
				-- add bonus
				for i=1, 10 do
					AddImpact(ObjectAlias, TalentList[i], 5, duration)
				end
			end

			if GetSettlement(ObjectAlias,"City") then
				chr_DecrementInfectionCount("PneumoniaInfected", "City")				
			end
		end
	end
end


-- -----------------------
-- Blackdeath / pest
-- -----------------------
function Blackdeath(ObjectAlias, State, Force)
	-- State: true = character should get a dysentery, false = the dysentery should heal
	
	local DUR = diseases["Blackdeath"].duration
	local endtime = math.mod(GetGametime(),24)+DUR
	local TalentList = {"constitution", "dexterity", "charisma", "fighting", "craftsmanship", "shadow_arts", 
					"rhetoric", "empathy", "bargaining", "secret_knowledge" }
	
	if State == true then
	
		if not diseases_CheckDisease(ObjectAlias, Force) then
			return		
		end
		
		if not (GetImpactValue(ObjectAlias, "Blackdeath") == 1) then
			AddImpact(ObjectAlias, "Blackdeath", 1, DUR)
			AddImpact(ObjectAlias, "Sickness", 1, DUR)
			SetState(ObjectAlias, STATE_SICK, true)
			SetProperty(ObjectAlias, "BlackdeathTime", endtime)

			-- add malus
			for i=1, 10 do
				AddImpact(ObjectAlias, TalentList[i], -7, DUR)
			end
		end
	else
		if (GetImpactValue(ObjectAlias, "Blackdeath") == 1) then
			RemoveImpact(ObjectAlias, "Blackdeath")
			RemoveImpact(ObjectAlias, "Sickness")
			SetState(ObjectAlias, STATE_SICK, false)
			-- instead of RemoveImpact we add a impact for the rest of the time
			if math.mod(GetGametime(),24) < GetProperty(ObjectAlias,"BlackdeathTime") then
				duration = math.floor(GetProperty(ObjectAlias,"BlackdeathTime")-math.mod(GetGametime(),24))
				RemoveProperty(ObjectAlias, "BlackdeathTime")
				
				-- add bonus
				for i=1, 10 do
					AddImpact(ObjectAlias, TalentList[i], 7, duration)
				end
			end
			
			if GetSettlement(ObjectAlias,"City") then
				chr_DecrementInfectionCount("BlackdeathInfected", "City")				
			end
		end
	end
end
-- -----------------------
-- Fracture / knochenbruch
-- -----------------------
function Fracture(ObjectAlias, State,Force)
	-- State: true = character should get a fracture, false = the fracture should heal
	
	local DUR = diseases["Fracture"].duration
	local endtime = math.mod(GetGametime(),24)+DUR

	if State == true then
		if not diseases_CheckDisease(ObjectAlias,Force) then
			return		
		end
		if not (GetImpactValue(ObjectAlias,"Fracture")==1) then
			AddImpact(ObjectAlias, "LifeExpanding", -1, -1) -- lose lifetime on infection
			AddImpact(ObjectAlias,"Fracture",1,DUR)
			AddImpact(ObjectAlias,"Sickness",1,DUR)
			SetState(ObjectAlias,STATE_SICK,true)
			SetProperty(ObjectAlias,"FractureTime", endtime)
			
			--AddImpact(ObjectAlias,"MoveSpeed",0.6,DUR)
			AddImpact(ObjectAlias,"craftsmanship", -4,DUR)
			AddImpact(ObjectAlias,"Fighting", -4,DUR)
			AddImpact(ObjectAlias,"dexterity", -4,DUR)
		end
	else
		if GetImpactValue(ObjectAlias,"Fracture")==1 then
			RemoveImpact(ObjectAlias,"Fracture")
			RemoveImpact(ObjectAlias,"Sickness")
			SetState(ObjectAlias,STATE_SICK,false)
			
			--RemoveImpact(ObjectAlias,"MoveSpeed")
			-- instead of RemoveImpact we add a impact for the rest of the time
			if math.mod(GetGametime(),24)<GetProperty(ObjectAlias,"FractureTime") then
				duration = math.floor(GetProperty(ObjectAlias,"FractureTime")-math.mod(GetGametime(),24))
				AddImpact(ObjectAlias,"craftsmanship", 4, duration)
				AddImpact(ObjectAlias,"Fighting", 4, duration)
				AddImpact(ObjectAlias,"dexterity", 4, duration)
				RemoveProperty(ObjectAlias, "FractureTime")
			end
			
			if GetSettlement(ObjectAlias,"City") then
				chr_DecrementInfectionCount("FractureInfected", "City")				
			end
		end
	end

end
-- -----------------------
-- Caries / zahnfaeule
-- -----------------------
function Caries(ObjectAlias, State, Force)
	-- State: true = character should get a fracture, false = the fracture should heal
	
	local DUR = diseases["Caries"].duration

	if State == true then
		if not diseases_CheckDisease(ObjectAlias,Force) then
			return		
		end
		if not (GetImpactValue(ObjectAlias,"Caries")==1) then
			AddImpact(ObjectAlias,"Caries",1,DUR)
			AddImpact(ObjectAlias,"Sickness",1,DUR)
			SetState(ObjectAlias,STATE_SICK,true)
			
			AddImpact(ObjectAlias,"rhetoric",-3,DUR)
			AddImpact(ObjectAlias,"charisma",-3,DUR)
		end
	else
		if GetImpactValue(ObjectAlias,"Caries")==1 then
			RemoveImpact(ObjectAlias,"Caries")
			RemoveImpact(ObjectAlias,"Sickness")
			SetState(ObjectAlias,STATE_SICK,false)
			
			AddImpact(ObjectAlias,"rhetoric",3,DUR)
			AddImpact(ObjectAlias,"charisma",3,DUR)
			
			if GetSettlement(ObjectAlias,"City") then
				chr_DecrementInfectionCount("CariesInfected", "City")				
			end
		end
	end
end

-- -----------------------
-- GetTreatmentCost
-- -----------------------
function GetTreatmentCost(Disease)
  return diseases[Disease].cost or 75
end


