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
		-- 2026-09-19 answered the first half: purse and housepurse came back identical
		-- (425867 both), so GetMoney on a member is reporting the house's money, not what
		-- the member carries - and SpendMoney still refused. A player's own character with
		-- 286536 paid 102 in the same run, so the charge is not broken for everyone.
		-- shadow= is the remaining suspect: a shadow dynasty is a background placeholder
		-- and its money may not be spendable at all, which would make the refusal correct
		-- and the gate wrong - PaysForTreatment should not bill a house that cannot pay.
		Extra = " dyn=" .. GetDynastyID(SimAlias) .. " housepurse=" .. House
			.. " dynsim=" .. tostring(IsDynastySim(SimAlias))
			.. " party=" .. tostring(IsPartyMember(SimAlias))
			.. " isplayer=" .. tostring(DynastyIsPlayer(SimAlias))
			.. " isai=" .. tostring(DynastyIsAI(SimAlias))
			.. " shadow=" .. tostring(DynastyIsShadow(SimAlias))
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

				-- Settle the bill BEFORE the treatment block, so a refusal simply skips it.
				-- It used to sit inside and leave with `break`, which walked out of the whole
				-- `while true` queue loop and, worse, skipped the two lines at the end of an
				-- iteration that clear STATE_DUEL - including SetState("", ...) on the DOCTOR.
				-- A doctor left in STATE_DUEL cannot be given a new order and cannot be
				-- cancelled, so one refused patient froze the hospital with everyone else still
				-- queued: reported from play on 2026-09-19. PropertiesEnd only ever cleared the
				-- patient's half.
				--
				-- Falling through instead means `cured` stays false, so the end of the iteration
				-- sets IgnoreHospital for twelve hours, releases both sims and takes the next
				-- patient - which is what "refused" should have meant all along.
				local Paid = true
				if CanHeal ~= false and gameplayformulas_PaysForTreatment("SickSim0") then
					Paid = chr_SpendMoney("SickSim0", v.Cost, "Offering")
					-- Then the house, which is how every other bill in the game is
					-- settled: ms_149_AttendSchool, ms_150_AttendApprenticeship,
					-- ms_151_AttendUniversity, ms_033_PayBonus and ms_148_RepairCart all
					-- charge the Dynasty alias and never the member. The hospital was the
					-- outlier, and it showed: on 2026-09-19 a member of an AI house was
					-- refused at cost=461 while ::TWP::HEAL recorded purse=425867 and
					-- housepurse=425867 - the same number, because GetMoney on a member
					-- reports the house - and SpendMoney on that member still said no. A
					-- player's own character paid 102 out of 286536 in the same run, so
					-- the charge works for some sims and not others. Asking the house
					-- second settles the bill whatever the reason, and a house that
					-- genuinely cannot pay still refuses, now with the twelve hour
					-- cooldown behind it.
					if not Paid and GetDynasty("SickSim0", "TWP_Payer") then
						Paid = chr_SpendMoney("TWP_Payer", v.Cost, "Offering")
						RemoveAlias("TWP_Payer")
					end
					if not Paid then
						ms_medicaltreatment_Emit("SickSim0", v.Cost, "nomoney")
						MsgSay("", "@L_MEDICUS_TREATMENT_DOC_NOMONEY")
					end
				end
				
				if CanHeal ~= false and Paid then
					-- one call, not one per branch: it was duplicated in both before
					ms_medicaltreatment_ManageMedicine(CanHeal, v.Med, v.MedsAmount)
					ms_medicaltreatment_Emit("SickSim0", v.Cost, "healed")

					chr_CreditMoney("Hospital", v.Cost, "Offering")
					-- Show the fee the way a sale shows one. economy.lua does exactly this
					-- after CreditMoney on a workshop counter, so treatment income stops
					-- being the one earner in the game with nothing to see: over the
					-- hospital because that is the account credited, and over the doctor
					-- because that is who the player is watching.
					feedback_OverheadMoney("Hospital", v.Cost)
					feedback_OverheadMoney("", v.Cost)
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

-- ms_medicaltreatment_PropertiesEnd lived here and is gone. Its two halves - releasing the
-- sim and remembering the refusal - were inlined into the per-patient epilogue on
-- 2026-02-06, and from then on nothing called it: the only reference left was the
-- commented-out line above. Deleted 2026-09-21 along with the analyzer pointer that still
-- told readers "PropertiesEnd(false, sim) sets IgnoreHospital", which was directions to a
-- function that no longer ran. The cooldown is written in the epilogue and READ in
-- idlelib_VisitDoc; the read side was the actual hole.

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
