function Init()
end

function Run()
	
	local Label = ""
	local GlobalWarn = false
	
	-- get the correct label
	if GetImpactValue("", "Sprain") == 1 then
		Label = "HPFZ_KATASTR_KRANK_NAM_+0"
	elseif GetImpactValue("", "Cold") == 1 then
		Label = "HPFZ_KATASTR_KRANK_NAM_+1"
	elseif GetImpactValue("", "Influenza") == 1 then
		Label = "HPFZ_KATASTR_KRANK_NAM_+2"
	elseif GetImpactValue("", "BurnWound") == 1 then
		Label = "HPFZ_KATASTR_KRANK_NAM_+6"
	elseif GetImpactValue("", "Pox") == 1 then
		Label = "HPFZ_KATASTR_KRANK_NAM_+3"
	elseif GetImpactValue("", "Pneumonia") == 1 then
		Label = "HPFZ_KATASTR_KRANK_NAM_+7"
	elseif GetImpactValue("", "Blackdeath") == 1 then
		GlobalWarn = true
		Label = "HPFZ_KATASTR_KRANK_NAM_+8"
	elseif GetImpactValue("", "Fracture") == 1 then
		Label = "HPFZ_KATASTR_KRANK_NAM_+4"
	elseif GetImpactValue("", "Caries") == 1 then
		Label = "HPFZ_KATASTR_KRANK_NAM_+5"
	end
	
	if GlobalWarn then
		
		-- send global warning and save starting year
		if GetSettlement("", "MyHomeCity") then
			if not HasProperty("MyHomeCity", "ActivePlague") then
				local StartingYear = GetRound()
				SetProperty("MyHomeCity", "ActivePlague", StartingYear)
				MsgNewsNoWait("All", "", "", "intrigue", -1,
							"@L_HPFZ_KATASTR_STOD_KOPF",
							"@L_HPFZ_KATASTR_STOD_RUMPF_+0",
							GetID("MyHomeCity"))
			end
		end
		
		-- send personal messages
		if IsPartyMember("") then
			feedback_MessageCharacter("", "@L_HPFZ_KATASTR_STOD_WARNING_HEAD_+0",
								"@L_HPFZ_KATASTR_SICK_BODY_+0", GetID(""), Label)
		end
				
	
		if SimGetWorkingPlace("", "WorkBuilding") then
			if BuildingGetAISetting("WorkBuilding", "Produce_Selection") < 1 then
				MsgNewsNoWait("WorkBuilding", "", "", "production", -1, 
							"@@L_HPFZ_KATASTR_STOD_WARNING_HEAD_+1",
							"@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_DYNSIM_BODY_+0",
							GetID(""))
			end
		end
	
	else
		-- normal disease
		if IsPartyMember("") then
			feedback_MessageCharacter("", "@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_DYNSIM_HEAD_+0",
							"@L_HPFZ_KATASTR_SICK_BODY_+0", GetID(""), Label)
		end
				
	
		if SimGetWorkingPlace("", "WorkBuilding") then
			if BuildingGetAISetting("WorkBuilding", "Produce_Selection") < 1 then
				MsgNewsNoWait("WorkBuilding", "", "", "production", -1, 
							"@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_WORKER_HEAD_+0",
							"@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_DYNSIM_BODY_+0",
							GetID(""))
			end
		end
	end
	
	StopAction("sickness", "")
	RemoveOverheadSymbols("")
		
	------------------------------------------------------
	-- increase the number of infections
	gameplayformulas_IncreaseInfectionCountCity("")
	------------------------------------------------------
	
	while true do
		if not AliasExists("") then
			break
		end
		
		if GetImpactValue("", "Sprain") == 1 then
			state_sick_SprainBehaviour()
		elseif GetImpactValue("", "Cold") == 1 then
			state_sick_ColdBehaviour()
		elseif GetImpactValue("", "Influenza") == 1 then
			state_sick_InfluenzaBehaviour()
		elseif GetImpactValue("", "BurnWound") == 1 then
			state_sick_BurnWoundBehaviour()
		elseif GetImpactValue("", "Pox") == 1 then
			state_sick_PoxBehaviour()
		elseif GetImpactValue("", "Pneumonia") == 1 then
			state_sick_PneumoniaBehaviour()
		elseif GetImpactValue("", "Blackdeath") == 1 then
			state_sick_BlackdeathBehaviour()
		elseif GetImpactValue("", "Fracture") == 1 then
			state_sick_FractureBehaviour()
		elseif GetImpactValue("", "Caries") == 1 then
			state_sick_CariesBehaviour()
		else
			break
		end
	end
	
	if not AliasExists("") then
		return
	end
	
	SetState("", STATE_SICK, false)
end

function SprainBehaviour()

	MoveSetActivity("", "hobble")

	while GetImpactValue("", "Sprain") == 1 do
		Sleep(30)
	end
	
	-- disease finished
	MoveSetActivity("")
	
	if GetSettlement("", "City") then
		chr_DecrementInfectionCount("SprainInfected", "City")
	end
end

function ColdBehaviour()
	
	CommitAction("sickness", "", "") -- it's contagious
		
	while GetImpactValue("", "Cold") == 1 do
		Sleep(30)
		if (GetState("", STATE_IDLE) and MoveGetStance("") == GL_STANCE_STAND) then
			local AnimTime
			if Rand(10)>4 then
				AnimTime = PlayAnimationNoWait("", "sneeze")
				Sleep(0.5)
				PlaySound3DVariation("", "CharacterFX/sneeze", 1)
				Sleep(AnimTime-0.5)
			else
				AnimTime = PlayAnimationNoWait("", "cough")
				Sleep(1)
				PlaySound3DVariation("", "CharacterFX/disease_light_cough", 1)
				Sleep(AnimTime-1)
			end
		end
	end
	
	-- disease finished
	if GetSettlement("", "City") then
		chr_DecrementInfectionCount("ColdInfected", "City")
	end
	
	-- incubate
	if Rand(10) < 4 then
		Disease.Influenza:infectSim("")
	end
end

function InfluenzaBehaviour()
	
	MoveSetActivity("", "sick")
	CommitAction("sickness", "", "") -- it's contagious
	
	while GetImpactValue("", "Influenza") == 1 do
		Sleep(30)
		if (GetState("", STATE_IDLE) and MoveGetStance("") == GL_STANCE_STAND) then
			local AnimTime
			if Rand(10)>6 then
				AnimTime = PlayAnimationNoWait("", "sneeze")
				Sleep(0.5)
				PlaySound3DVariation("", "CharacterFX/sneeze", 1)
				Sleep(AnimTime-0.5)
			else
				AnimTime = PlayAnimationNoWait("", "cough")
				Sleep(1)
				PlaySound3DVariation("", "CharacterFX/disease_light_cough", 1)
				Sleep(AnimTime-1)
			end
		end
	end
	
	-- disease finished
	if GetSettlement("", "City") then
		chr_DecrementInfectionCount("InfluenzaInfected", "City")
	end
	MoveSetActivity("")
	
	-- incubate
	if Rand(10) < 6 then
		Disease.Pneumonia:infectSim("")
	end
end

function BurnWoundBehaviour()
	--ShowOverheadSymbol("",true,true,0,"Scheisse, ich hab mich verbrannt!")
	local HPChange = GetMaxHP("") * 0.1

	while true do
		Sleep(60)
		if not AliasExists("") or GetImpactValue("", "BurnWound") ~= 1 then
			break
		end
		
		if GetHPRelative("") <= 0.1 then -- in case you die
			SetProperty("", "WasSick", 1)
			SetProperty("", "ReasonToDie", "BurnWound")
		end
		
		while GetState("", STATE_CUTSCENE) do
			Sleep(20)
		end
		
		if not GetState("", STATE_CUTSCENE) then
			ModifyHP("", -HPChange, true)
		end
	end
		
	-- disease finished
	if GetSettlement("", "City") then
		chr_DecrementInfectionCount("BurnWoundInfected", "City")
	end
end

function PneumoniaBehaviour()
	
	MoveSetActivity("", "sick")
	CommitAction("sickness", "", "") -- it's contagious
	
	while GetImpactValue("", "Pneumonia") == 1 do
		Sleep(30)
		if (GetState("", STATE_IDLE) and MoveGetStance("") == GL_STANCE_STAND) then
			local AnimTime
			if Rand(10)>4 then
				AnimTime = PlayAnimationNoWait("", "sneeze")
				Sleep(0.5)
				PlaySound3DVariation("", "CharacterFX/sneeze", 1)
				Sleep(AnimTime-0.5)
			else
				AnimTime = PlayAnimationNoWait("", "cough")
				Sleep(1)
				PlaySound3DVariation("", "CharacterFX/disease_seriously_cough", 1)
				Sleep(AnimTime-1)
			end
		end
	end
	
	-- disease finished
	if GetSettlement("", "City") then
		chr_DecrementInfectionCount("PneumoniaInfected", "City")
	end
	
	if Rand(4) > 0 then
		SetProperty("", "WasSick", 1)
		SetProperty("", "ReasonToDie", "Pneumonia")
		
		while GetState("", STATE_CUTSCENE) do
			Sleep(20)
		end
		ModifyHP("", -GetMaxHP(""), true)
	end
end

function PoxBehaviour()

	CommitAction("sickness", "", "") -- it's contagious
	while GetImpactValue("", "Pox") == 1 do
		Sleep(30)
		if (GetState("", STATE_IDLE) and MoveGetStance("") == GL_STANCE_STAND) then
			local AnimTime
			
			AnimTime = PlayAnimationNoWait("", "cough")
			Sleep(1)
			PlaySound3DVariation("", "CharacterFX/disease_seriously_cough", 1)
			Sleep(AnimTime-1)
		end
	end
	
	-- disease finished
	if GetSettlement("", "City") then
		chr_DecrementInfectionCount("PoxInfected", "City")
	end
	
	SetProperty("", "PoxImmunity", 1)
end

function BlackdeathBehaviour()
	
	MoveSetActivity("", "sick")
	CommitAction("sickness", "", "") -- contagious
	
	while GetImpactValue("", "Blackdeath") == 1 do
		Sleep(20)
		if (GetState("", STATE_IDLE) and MoveGetStance("") == GL_STANCE_STAND) then
			local AnimTime
			AnimTime = PlayAnimationNoWait("", "cough")
			Sleep(1)
			PlaySound3DVariation("", "CharacterFX/disease_seriously_cough", 1)
			Sleep(AnimTime-1)
		end
	end
	
	-- disease finished
	if GetSettlement("", "City") then
		chr_DecrementInfectionCount("BlackdeathInfected", "City")
		local BlackdeathCount = GetProperty("City", "BlackdeathInfected") or 0
		
		if BlackdeathCount == 0 then
			-- message everyone that the plague is gone
			if HasProperty("City", "ActivePlague") then
				RemoveProperty("City", "ActivePlague")
			end
			
			local DeathCounter = GetProperty("City", "PlagueDeathCounter") or 0
				
			MsgNewsNoWait("All", "", "", "intrigue", -1,
							"@L_HPFZ_KATASTR_STOD_CURED_KOPF_+0",
							"@L_HPFZ_KATASTR_STOD_CURED_RUMPF_+0",
							GetID("City"), GetID(""), DeathCounter)
		end
	end
	
	SetProperty("", "BlackdeathImmunity", 1)
	MoveSetActivity("")
	
	if Rand(10) > 1 then
		while GetState("", STATE_CUTSCENE) do
			Sleep(20)
		end
		
		SetProperty("", "WasSick", 1)
		SetProperty("", "ReasonToDie", "Blackdeath")
	
		ModifyHP("", -GetMaxHP(""), true)
	end
end

function FractureBehaviour()

	MoveSetActivity("", "hobble")
		
	while GetImpactValue("", "Fracture") == 1 do
		Sleep(30)
	end

	-- disease finished
	if GetSettlement("", "City") then
		chr_DecrementInfectionCount("FractureInfected", "City")
	end
	
	MoveSetActivity("")
end

function CariesBehaviour()

	while GetImpactValue("", "Caries") == 1 do
		Sleep(30)
	end
	
	-- disease finished
	if GetSettlement("", "City") then
		chr_DecrementInfectionCount("CariesInfected", "City")		
	end
end

function CleanUp()

	GfxDetachAllObjects()
	GetSettlement("", "City")
	
	if AliasExists("City") then
		if HasProperty("City", "InfectedSims") then
			local CurrentInfected = GetProperty("City", "InfectedSims") - 1
			SetProperty("City", "InfectedSims", CurrentInfected)
		end
	end
	
	MoveSetActivity("")
	StopAction("sickness", "")
	AddImpact("", "Resist", 1, 6)
	RemoveOverheadSymbols("")	
end

