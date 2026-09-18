-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_MedicalTreatment"
----
----	with this measure, the player can assign a sim to treat sick sims in hospital
----
-------------------------------------------------------------------------------

local function switch(c)
	local self = { casevar = c }

	self.caseof = function (self, code)
	return code[self.casevar]()
end

    return self
end
				
-- ::TWP::HEAL t= sim= hospital= cost= purse= outcome=<healed|nomoney|nomats>
-- One line per patient seen. Without it the next log cannot tell a queue that drained
-- from a town where nobody fell ill: the engine prints no "Executing Measures" line for
-- a production measure, so this file leaves no trace at all otherwise.
function Emit(SimAlias, Cost, Outcome)
	local Extra = ""
	-- A refusal with money in the purse is the interesting one, and it happened: on
	-- 2026-09-19 a sim was turned away at cost=461 holding purse=424750. GetMoney and
	-- SpendMoney both take a guildobject and are meant to be the same pot, so when the
	-- charge fails anyway the question is which pot each one really reads - the character
	-- panel shows that sim carrying 0 coins against assets of 474515, so GetMoney on a
	-- house member is very likely answering for the house. Log the house's own purse
	-- beside it, and the four flags that decide who is billed. Equal numbers would mean
	-- the bill belongs to the dynasty alias rather than the member.
	if Outcome == "nomoney" then
		local House = -1
		if GetDynasty(SimAlias, "TWP_HealDyn") then
			House = math.floor(GetMoney("TWP_HealDyn") or 0)
		end
		Extra = " dyn=" .. GetDynastyID(SimAlias) .. " housepurse=" .. House
			.. " dynsim=" .. tostring(IsDynastySim(SimAlias))
			.. " party=" .. tostring(IsPartyMember(SimAlias))
			.. " isplayer=" .. tostring(DynastyIsPlayer(SimAlias))
			.. " isai=" .. tostring(DynastyIsAI(SimAlias))
		RemoveAlias("TWP_HealDyn")
	end
	utility_Emit("::TWP::HEAL t=" .. string.format("%.2f", GetGametime())
		.. " sim=" .. GetID(SimAlias) .. " hospital=" .. GetID("Hospital")
		.. " cost=" .. math.floor(Cost or 0) .. " purse=" .. math.floor(GetMoney(SimAlias) or 0)
		.. " outcome=" .. Outcome .. Extra)
end

function ManageMedicine(checker, treatment, property) 

	switch(checker): caseof(
	{
		function() -- 1
			RemoveItems("Hospital", treatment, 1, INVENTORY_STD)
		end,

		function() -- 2
			RemoveItems("Hospital", treatment, 1, INVENTORY_SELL)
		end,

		function() -- 3
			SetProperty("Hospital", treatment.."s", property-1)
		end
	})

end

function Run()

	if not ai_GetWorkBuilding("", GL_BUILDING_TYPE_HOSPITAL, "Hospital") then
		StopMeasure()
		return
	end

	local PlayerOrdered = not IsStateDriven()
	local ManualWorker = IsDynastySim("") or PlayerOrdered
	if not ManualWorker and HasProperty("", "AIManual") and GetProperty("", "AIManual") ~= 0 then
		ManualWorker = true
	end

	local tcap0 = "MActRule_" .. MeasureGetID("MedicalTreatment") .. "_"
	if not ManualWorker then
		if HasProperty("Hospital", tcap0 .. "enabled") and (GetProperty("Hospital", tcap0 .. "enabled") - 1) == 0 then
			SimSetProduceItemID("", 0, -1)
			StopMeasure()
			return
		end
		if HasProperty("Hospital", tcap0 .. "maxw") then
			if BuildingGetProducerCount("Hospital", PT_MEASURE, "MedicalTreatment") > (GetProperty("Hospital", tcap0 .. "maxw") - 1) then
				SimSetProduceItemID("", 0, -1)
				StopMeasure()
				return
			end
		end
	end

	if GetInsideBuildingID("") ~= GetID("Hospital") then
		if not f_MoveTo("", "Hospital", GL_MOVESPEED_RUN) then
			return
		end
	end
	
	local BedFree = false
	local BedNumber = 0
	local MyID = GetID("")
	
	local HospitalID = GetID("Hospital")
	
	for i=1,5 do
		if HasProperty("Hospital", "Locator"..i) then
			local Holder = GetProperty("Hospital", "Locator"..i)
			if Holder == MyID then
				BedFree = true
				BedNumber = i
				SetData("BedNumber", i)
				break
			end
			if not GetAliasByID(Holder, "BedHolder") then
				RemoveProperty("Hospital", "Locator"..i)
			elseif GetState("BedHolder", STATE_DEAD) then
				RemoveProperty("Hospital", "Locator"..i)
			elseif GetInsideBuildingID("BedHolder") ~= HospitalID then
				RemoveProperty("Hospital", "Locator"..i)
			end
		end
	end
	
	if not BedFree then
		for i=1,5 do
			if not HasProperty("Hospital", "Locator"..i) then
				SetProperty("Hospital", "Locator"..i, MyID)
				BedFree = true
				BedNumber = i
				SetData("BedNumber", i)
				break
			end
		end
	end
	
	if not BedFree then
		LogMessage("Hospital no free bed found")
		StopMeasure()
		return
	end
	
	GetLocatorByName("Hospital", "Treatment"..BedNumber, "TreatmentPos")
	if not f_BeginUseLocator("", "TreatmentPos", GL_STANCE_STAND, true) then
		return
	end
	
	SetData("IsProductionMeasure", 0)
	SimSetProduceItemID("", -GetCurrentMeasureID(""), -1)
	SetData("IsProductionMeasure", 1)

	local AtStation = true

	while true do

		local tcap = "MActRule_" .. MeasureGetID("MedicalTreatment") .. "_"
		if not ManualWorker then
			if HasProperty("Hospital", tcap .. "enabled") and (GetProperty("Hospital", tcap .. "enabled") - 1) == 0 then
				SimSetProduceItemID("", 0, -1)
				StopMeasure()
				break
			end
			if HasProperty("Hospital", tcap .. "maxw") then
				if BuildingGetProducerCount("Hospital", PT_MEASURE, "MedicalTreatment") > (GetProperty("Hospital", tcap .. "maxw") - 1) then
					SimSetProduceItemID("", 0, -1)
					StopMeasure()
					break
				end
			end
		end

		local SickSimFilter = "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.Property.WaitingForTreatment==1))"
		local NumSickSims = Find("", SickSimFilter, "SickSim", -1)
		
		if NumSickSims < 1 then
			if PlayerOrdered then
				if not AtStation then
					GetLocatorByName("Hospital", "Treatment"..BedNumber, "TreatmentPos")
					AtStation = f_BeginUseLocator("", "TreatmentPos", GL_STANCE_STAND, true)
				end
				Sleep(5)
			else
				SimSetProduceItemID("", 0, -1)
				StopMeasure()
				break
			end
		else
			AtStation = false
			
			if not AliasExists("SickSim0") then
				LogMessage("Hospital: NoSickSim0 found")
				return
			end

			--if not GetState("SickSim0", STATE_SICK) then
				--ms_medicaltreatment_PropertiesEnd(true,"SickSim0")
			--end
			
			SetData("Blocked", 0)
			if not SendCommandNoWait("SickSim0", "BlockMe") then
				LogMessage("Hospital: Cant block SickSim0")
				break
			end
			
			Sleep(0.5)
			if not f_MoveTo("SickSim0", "Owner", GL_MOVESPEED_WALK, 128) then
				return
			end
			AlignTo("SickSim0", "")
			AlignTo("", "SickSim0")
			
			Sleep(1)
			MeasureSetNotRestartable()
			SetState("", STATE_DUEL, true)
			
			MsgSay("SickSim0", "@L_MEDICUS_TREATMENT_PATIENT")
			MsgSay("", "@L_MEDICUS_TREATMENT_DOC_INTRO")
			f_MoveTo("SickSim0", "Owner", GL_MOVESPEED_WALK, 60)
			PlayAnimation("", "manipulate_middle_twohand")

			local CanHeal = false
			local found = false
			local cured = false
			local v = {}

			for k, x in diseases_GetDiseaseIterator() do
				if GetImpactValue("SickSim0", x:getName()) and GetImpactValue("SickSim0", x:getName()) == 1 then
					v.MedsAmount= 0
					v.Name		= x:getName()
					v.Cost		= x:getCost()
					v.Med			= x:getMedicine()
					v.Favour	= x:getFavor()
					found = true
					break
				end
			end

			if found == false then
				if (GetHP("SickSim0") == GetMaxHP("SickSim0")) then
					cured = true
					MsgSay("","@L_MEDICUS_TREATMENT_DOC_NOTHING")					
					SimResetBehavior("SickSim0")
					RemoveProperty("SickSim0", "WaitingForTreatment")
				else 
					v = {Cost=(GetMaxHP("SickSim0")-GetHP("SickSim0")), Med="Bandage", Favour=GL_FAVOR_MOD_SMALL}
				end
			end

			if cured == false then

				if GetItemCount("Hospital",v.Med,INVENTORY_STD)>0 then
					CanHeal = 1
				elseif GetItemCount("Hospital",v.Med,INVENTORY_SELL)>0 then
					CanHeal = 2
				elseif HasProperty("Hospital",v.Med.."s") and GetProperty("Hospital",v.Med.."s")>0 then 
					v.MedsAmount = GetProperty("Hospital",v.Med.."s")
					CanHeal = 3
				else
					ms_medicaltreatment_Emit("SickSim0", v.Cost, "nomats")
					MsgSayNoWait("","@L_MEDICUS_TREATMENT_DOC_NOMATS",ItemGetLabel(v.Med,false))
					Sleep(2)

					if GetImpactValue("Hospital","hospitalmessagesent") == 0 then
						AddImpact("Hospital","hospitalmessagesent",1,4)
						feedback_MessageWorkshop("Hospital","@L_MEDICUS_TREATMENT_MSG_NOMATS_HEAD_+0","@L_MEDICUS_TREATMENT_MSG_NOMATS_BODY_+0",GetID("Hospital"),ItemGetLabel(v.Med,false))
					end
						
					if v.Med == "Bandage" and BuildingGetAISetting("Hospital", "Produce_Selection") > 0 then
						if BuildingGetProducerCount("Hospital", PT_MEASURE, "MedicalTreatment") > 1 then
							SimSetProduceItemID("", 0, -1)
							StopMeasure()
						end
					end
					
				end

				if CanHeal ~= false then

					if gameplayformulas_PaysForTreatment("SickSim0") then
						if chr_SpendMoney("SickSim0", v.Cost, "Offering") then
							ms_medicaltreatment_ManageMedicine(CanHeal, v.Med, v.MedsAmount)
						else
							-- Turned away for want of coin. Two things went wrong here and
							-- both are in these five lines.
							--
							-- PropertiesEnd(true, ...) took the branch that does NOT set
							-- IgnoreHospital, so nothing remembered the refusal: the sim
							-- left, ai_VisitDoc came round an hour later, the ranking in
							-- idlelib_VisitDoc picked the same hospital and they queued
							-- again. Every other unsuccessful outcome sets that 12 hour
							-- cooldown further down; only this one skipped it, and the
							-- false branch that sets it was never called from anywhere.
							--
							-- And `return` left Run() entirely, not just this patient, so
							-- one empty purse stopped the doctor working the whole queue
							-- until the measure was picked again.
							ms_medicaltreatment_Emit("SickSim0", v.Cost, "nomoney")
							MsgSay("", "@L_MEDICUS_TREATMENT_DOC_NOMONEY")
							ms_medicaltreatment_PropertiesEnd(false,"SickSim0")
							break
						end
					else
							ms_medicaltreatment_ManageMedicine(CanHeal, v.Med, v.MedsAmount)
					end
					ms_medicaltreatment_Emit("SickSim0", v.Cost, "healed")

					chr_CreditMoney("Hospital", v.Cost, "Offering")
					economy_UpdateBalance("Hospital", "Service", v.Cost)
					SetProperty("Hospital", "BalanceOffering", (GetProperty("Hospital", "BalanceOffering") or 0) + v.Cost)
					local TotalIncome = 0
					local RoundIncome = 0
					local MedicalIncome = 0

					if HasProperty("Hospital", "TotalIncome") then
						TotalIncome = GetProperty("Hospital","TotalIncome")
					end

					if HasProperty("Hospital", "RoundIncome") then
						RoundIncome = GetProperty("Hospital","RoundIncome")
					end

					if HasProperty("Hospital", "MedicalIncome") then
						MedicalIncome = GetProperty("Hospital","MedicalIncome")
					end

					SetProperty("Hospital", "TotalIncome",(TotalIncome +v.Cost))
					SetProperty("Hospital", "RoundIncome",(RoundIncome +v.Cost))
					SetProperty("Hospital", "MedicalIncome",(MedicalIncome +v.Cost))
							
					if found then 
						MsgSayNoWait("", "@L_MEDICUS_TREATMENT_DOC_"..string.upper(v.Name))
						Sleep(2)

						Disease[v.Name]:cureSim("SickSim0")
						
						local list = {["Fracture"]=1,["BurnWound"]=1,["Pox"]=1,["Caries"]=1,["Pneumonia"]=1,["Blackdeath"]=1}

						if list[v.Name] ~= nil then
							ms_medicaltreatment_LayToBed("", "SickSim0", BedNumber)

							if v.Name == "Blackdeath" then
								AddImpact("SickSim0","PlagueImmunity", 1, 120)
							end
						end

					else
						MsgSayNoWait("", "@L_MEDICUS_TREATMENT_DOC_HPLOSS") 
						ModifyHP("SickSim0", GetMaxHP("SickSim0") - GetHP("SickSim0"), true)
						Sleep(2)
					end
						
					if HasData("LayStill") then
						RemoveData("LayStill")
					end
							
					if BuildingGetOwner("Hospital", "MyBoss") then
						chr_ModifyFavor("SickSim0", "MyBoss", v.Favour)
					end

					cured = true
					achievements_IncrementStat("Owner", "STAT_PLAGUE_CURED")

					Sleep(1)

					if HasProperty("SickSim0", "WaitingForTreatment") then
						RemoveProperty("SickSim0", "WaitingForTreatment")
					end

					SetData("Blocked", 1)
					SetState("", STATE_DUEL, false)

				end

			end

			Sleep(1)

			if cured == false then
				SetProperty("SickSim0", "IgnoreHospital", GetID("Hospital"))
				SetProperty("SickSim0", "IgnoreHospitalTime", GetGametime()+12)
			else
				MoveSetActivity("SickSim0")
				AddImpact("SickSim0", "Resist", 1, 6)
				achievements_IncrementStat("Owner", "STAT_SICK_HEALED")
			end

			if HasProperty("SickSim0", "WaitingForTreatment") then
				RemoveProperty("SickSim0", "WaitingForTreatment")
			end

			SetData("Blocked", 1)
			SetState("", STATE_DUEL, false)
			-- this should be enough for BlockMe task to iterate once more before going for the next sim
			Sleep(3)
			-- to be sure
			SetState("SickSim0", STATE_DUEL, false)
			
		end
	end
end

-- checker: did the visit achieve anything. Both halves used to be in one branch, so the
-- only caller - the no-money refusal - had to choose between sending the sim on its way
-- and remembering that this hospital turned it away. It chose the first and the patient
-- came straight back. Releasing the sim is unconditional now; the cooldown is the part
-- that depends on the outcome.
function PropertiesEnd(checker,sim)
	Sleep(2)
	MoveSetActivity(sim)
	if checker == false then
		SetProperty(sim, "IgnoreHospital", GetID("Hospital"))
		SetProperty(sim, "IgnoreHospitalTime", GetGametime()+12)
	else
		AddImpact(sim, "Resist", 1, 6)
	end

	if HasProperty(sim, "WaitingForTreatment") then
		RemoveProperty(sim, "WaitingForTreatment")
	end

	SetData("Blocked", 1)
	SetState(sim, STATE_DUEL, false)
end


function BlockMe()
	while GetData("Blocked")==0 do
		if not GetState("", STATE_DUEL) then
			SetState("", STATE_DUEL, true)
		end
		Sleep(1)
	end
	
	if HasProperty("", "WaitingForTreatment") then
		RemoveProperty("", "WaitingForTreatment")
	end

	SetState("", STATE_DUEL, false)
	CreateScriptcall("SendHome", 0, "Measures/ms_MedicalTreatment.lua", "LeaveBuilding", "")
	return
end

function LeaveBuilding()
	f_ExitCurrentBuilding("")
	if DynastyIsAI("") then
		if Rand(2) == 0 then
			f_Stroll("", 1000, 6)
		else
			idlelib_GoHome()
		end
	end
end

function LayToBed(Doc, SickSim, BedNumber)
	GetLocatorByName("Hospital", "Bed"..BedNumber,"BedPos")

	if not f_BeginUseLocator(SickSim, "BedPos", GL_STANCE_LAY, true) then
		return
	end
	
	if not f_BeginUseLocator(Doc,"TreatmentPos", GL_STANCE_STAND, true) then
		return
	end
	
	Sleep(0.5)
	SetData("LayStill", 1)
	
	if not SendCommandNoWait(SickSim,"LayBack") then
		return
	end

	AlignTo(Doc, SickSim)
	Sleep(0.5)
	PlayAnimation(Doc, "treatpatientinbed_01")
	Sleep(0.5)
	f_EndUseLocator(Doc, "TreatmentPos", GL_STANCE_STAND)
	Sleep(0.5)
end

function LayBack()
	PlayAnimation("", "sickinbed_idle_in")
	while HasData("LayStill") do
		LoopAnimation("", "sickinbed_idle_01", 2)
	end
	PlayAnimation("", "sickinbed_idle_out")
	f_EndUseLocator("", "BedPos", GL_STANCE_STAND)
end

function CleanUp()
	SimSetProduceItemID("", 0, -1)
	SetData("Blocked",1)

	if HasData("BedNumber") then
		RemoveProperty("Hospital","Locator"..(GetData("BedNumber")))
		RemoveData("BedNumber")
	end

	RemoveData("LayStill")
	StopAnimation("")
	f_EndUseLocator("", "TreatmentPos", GL_STANCE_STAND)
	
	if HasProperty("", "BigBrother") then
		RemoveProperty("", "BigBrother")
	end
	
	SetState("", STATE_DUEL, false)
	
	if AliasExists("SickSim0") then
		SetState("SickSim0", STATE_DUEL, false)
	end
end
