function AIInit(CostLow, CostMedium, CostHigh)
	local MyMoney = GetMoney("")
	if MyMoney > CostHigh*2 then
		return "H"
	elseif MyMoney > CostMedium*2 then
		return "M"
	elseif MyMoney > CostLow then
		return "L"
	else
		return "C"
	end
end

function Run()

	if not AliasExists("Destination") then
		StopMeasure()
	end

	-- if the "Destination" sim is dead, AddEvidence will cause a crash, so we need to check for that
	if GetState("Destination", STATE_DEAD) or GetState("Destination", STATE_UNCONSCIOUS) then
		return
	end
	
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	local BardFilter = "__F((Object.GetObjectsByRadius(Sim)==3000)AND(Object.Property.IsBard == 1)AND(Object.Property.BardIsFree == 1))"
	local NumBards = Find("", BardFilter, "Bard", -1)
	
	if NumBards < 1 then
		StopMeasure()
	end
	
	MoveStop("Bard")
	MeasureSetNotRestartable()
	SetProperty("Bard", "BardIsFree", 0)
	BlockChar("Bard")
	
	AlignTo("", "Bard")
	AlignTo("Bard", "")
	Sleep(1)
	
	
	local DestTitle = GetNobilityTitle("Destination",false) --1..10
	local DestLevel = SimGetLevel("Destination")
	
	local LowPrice = 200 * DestLevel * DestTitle
	local MidPrice = LowPrice * 2
	local HighPrice = LowPrice * 5
	
	local result = MsgNews("", "Destination", "@P"..
			"@B[L,@L_MESSAGES_SLANDER_MSG_BUTTONS_+0]"..
			"@B[M,@L_MESSAGES_SLANDER_MSG_BUTTONS_+1]"..
			"@B[H,@L_MESSAGES_SLANDER_MSG_BUTTONS_+2]",
			function() return ms_slander_AIInit(LowPrice, MidPrice, HighPrice) end, "intrigue", 1,
			"@L_MESSAGES_SLANDER_MSG_HEAD_+0",
			"@L_MESSAGES_SLANDER_MSG_BODY_+0",
			LowPrice, MidPrice, HighPrice)
	
	if result == "C" then
		StopMeasure()
	end
	
	local Evidence = 0
	local EvidenceLabel = "INTRO"
	local Costs = 0
	local Choice = 0
	
	--low crimes
	if result == "L" then
		Costs = LowPrice
		Choice = Rand(4)
		if Choice == 0 then
			Evidence = 1	--sabotage		5
			EvidenceLabel = "SABOTAGE"
		elseif Choice == 1 then
			Evidence = 6	--blackmail		5
			EvidenceLabel = "BLACKMAIL"
		elseif Choice == 2 then
			Evidence = 10	--calumny		4
			EvidenceLabel = "CALUMNY"
		else
			Evidence = 12	--raiding		5
			EvidenceLabel = "RAIDING"
		end
	--mid crimes
	elseif result == "M" then
		Costs = MidPrice
		Choice = Rand(6)
		if Choice == 0 then
			Evidence = 7	--slugging		6
			EvidenceLabel = "SLUGGING"
		elseif Choice == 1 then
			Evidence = 11	--poison		6
			EvidenceLabel = "POISON"
		elseif Choice == 2 then
			Evidence = 18	--attackcivilian		8
			EvidenceLabel = "ATTACKCIVILIAN"
		elseif Choice == 3 then
			Evidence = 14	--marauding		7
			EvidenceLabel = "MARAUDING"
		elseif Choice == 4 then
			Evidence = 19	--attackcart		6
			EvidenceLabel = "ATTACKCART"
		else
			Evidence = 20	--theft			6
			EvidenceLabel = "THEFT"
		end		
	--high crimes
	elseif result == "H" then
		Costs = HighPrice
		Choice = Rand(5)
		if Choice == 0 then
			Evidence = 15	--abduction		8
			EvidenceLabel = "ABDUCTION"
		elseif Choice == 1 then
			Evidence = 16	--murder		15
			EvidenceLabel = "MURDER"
		else
			Evidence = 7	--slugging	8
			EvidenceLabel = "SLUGGING"
		end
	end
	
	if not chr_SpendMoney("", Costs, "CostBribes") then
		MsgSay("Bard", "@L_MESSAGES_SLANDER_SPEECH_NOMONEY_+0")
		return
	end	
	
	SetMeasureRepeat(TimeOut)
	CreateCutscene("default", "cutscene")
	CutsceneAddSim("cutscene", "")
	CutsceneAddSim("cutscene", "Bard")
	CutsceneCameraCreate("cutscene", "")	
	camera_CutscenePlayerLock("cutscene", "Bard")	
	
	local SimFilter = "__F((Object.GetObjectsByRadius(Sim)==12000)AND(Object.IsDynastySim())AND NOT(Object.GetState(townnpc)))"
	local NumSims = Find("", SimFilter, "Sim", 10)
	MsgSay("Bard", "@L_MESSAGES_SLANDER_SPEECH_INTRO_+0")
	while true do
		ScenarioGetRandomObject("cl_Sim", "CurrentRandomSim")
		if IsDynastySim("CurrentRandomSim") then
			CopyAlias("CurrentRandomSim", "EvidenceVictim")
			break
		end
		Sleep(0.1) 
	end

	-- in an extremely unlikely case the Destination sim can die during Sleep(), so we need to check again
	-- we lose some money in this case, but it's better than crashing the game
	if GetState("Destination", STATE_DEAD) or GetState("Destination", STATE_UNCONSCIOUS) then
		return
	end

	local HearsayStep = 2
	if result == "H" then
		HearsayStep = 1
	elseif result == "M" then
		HearsayStep = 1 + Rand(2)
	end
	AddEvidence("", "Destination", "EvidenceVictim", Evidence, HearsayStep, "Destination", "Sim0", "Sim1", "Sim2", "Sim3", "Sim4", "Sim5", "Sim6", "Sim7", "Sim8", "Sim9")
	
	MsgSay("Bard","@L_MESSAGES_SLANDER_SPEECH_"..EvidenceLabel.."_+0", GetID("Destination"))
	SetProperty("Bard", "BardIsFree", 1)
	chr_GainXP("", GetData("BaseXP"))
	Sleep(0.2)
	MsgNewsNoWait("Destination", "", "", "intrigue", -1, "@L_HPFZ_GENERAL_MEASURES_SLANDER_VICTIM_HEAD_+0",
					"@L_HPFZ_GENERAL_MEASURES_SLANDER_VICTIM_BODY_+0", GetID("Destination"))
end

function CleanUp()
	if AliasExists("Bard") then
		SetProperty("Bard", "BardIsFree", 1)
	end
	
	DestroyCutscene("cutscene")
	ReleaseAvoidanceGroup("")
	MoveSetActivity("")
	StopAnimation("")

end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

