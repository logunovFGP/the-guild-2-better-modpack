-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_MedicalTreatment"
----
----	with this measure, the player can assign a sim to treat sick sims in hospital
----
-------------------------------------------------------------------------------

local function switch(c)
  local self = {casevar = c}

    self.caseof = function (self,code)
      return code[self.casevar]()
    end

    return self
end
				
local function ManageMedicine(checker,treatment,property) 

	switch(checker): caseof(
	{
		function() -- 1
			RemoveItems("Hospital",treatment,1,INVENTORY_STD)
		end,

		function() -- 2
			RemoveItems("Hospital",treatment,1,INVENTORY_SELL)
		end,

		function() -- 3
			SetProperty("Hospital",treatment.."s",property-1)
		end
	})

end

function Run()

	if not ai_GetWorkBuilding("", GL_BUILDING_TYPE_HOSPITAL, "Hospital") then
		StopMeasure()
	end
	
	if GetInsideBuildingID("") ~= GetID("Hospital") then
		if not f_MoveTo("", "Hospital", GL_MOVESPEED_RUN) then
			return
		end
	end
	
	local BedFree = false
	local BedNumber = 0
	local MyID = GetID("")
	
	-- check property instead of locator
	for i=1,5 do
		if HasProperty("Hospital", "Locator"..i) then
			if GetProperty("Hospital", "Locator"..i) == MyID then
				BedFree = true
				BedNumber = i
				SetData("BedNumber", i)
				break
			end
		else
			SetProperty("Hospital", "Locator"..i, MyID)
			BedFree = true
			BedNumber = i
			SetData("BedNumber", i)
			break
		end
	end
	
	if not BedFree then
		LogMessage("Hospital no free bed found")
		StopMeasure()
	end
	
	-- go to your place
	
	GetLocatorByName("Hospital", "Treatment"..BedNumber, "TreatmentPos")
	if not f_BeginUseLocator("", "TreatmentPos", GL_STANCE_STAND, true) then
		return
	end
	
	SetData("IsProductionMeasure", 0)
	SimSetProduceItemID("", -GetCurrentMeasureID(""), -1)
	SetData("IsProductionMeasure", 1)
	
	while true do
		local SickSimFilter = "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.Property.WaitingForTreatment==1))"
		local NumSickSims = Find("", SickSimFilter, "SickSim", -1)
		if NumSickSims < 1 then
			
			if not AliasExists("") then
				LogMessage("Hospital: I lost myself")
				break
			end			

			-- bored
			if Rand(9) == 0 then
				MoveStop("")
				PlayAnimation("", "cogitate")
			else
				Sleep(6)
			end
			
			-- AI stops measure if no patients are available to do better things
			if BuildingGetAISetting("Hospital", "Produce_Selection") > 0 then
				if BuildingGetProducerCount("Hospital", PT_MEASURE, "MedicalTreatment") > 1 then
					SimSetProduceItemID("", -1, -1)
					StopMeasure()
				end
			end
		else
			
			-- block the patient
			if not AliasExists("SickSim0") then
				LogMessage("Hospital: NoSickSim0 found")
				return
			end
			
			SetData("Blocked", 0)
			if not SendCommandNoWait("SickSim0", "BlockMe") then
				LogMessage("Hospital: Cant block SickSim0")
				break
			end
			
			-- patient moves
			Sleep(0.5)
			if not f_MoveTo("SickSim0", "Owner", GL_MOVESPEED_WALK, 128) then
				return
			end
			AlignTo("SickSim0", "")
			AlignTo("", "SickSim0")
			
			Sleep(1)
			MeasureSetNotRestartable()
			SetState("", STATE_DUEL, true) -- no measure cancel!
			
			-- Dialog
			MsgSay("SickSim0", "@L_MEDICUS_TREATMENT_PATIENT")
			MsgSay("", "@L_MEDICUS_TREATMENT_DOC_INTRO")
			f_MoveTo("SickSim0", "Owner", GL_MOVESPEED_WALK, 60)
			PlayAnimation("", "manipulate_middle_twohand")

			local Cured = false
			local Illness = false
			local CanHeal = false
			local sickness = 0
			local Costs
			local Med
			local FavorMod
			
			for k, v in diseases_GetDiseaseIterator() do
				if GetImpactValue("SickSim0", v:getName()) and GetImpactValue("SickSim0", v:getName()) == 1 then
					sickness = v
					Illness = true
					Costs = v:getCost()
					Med = v:getMedicine()
					FavorMod = v:getFavor()
					LogMessage("Medicine: "..(Med)..", FavorMod: "..(FavorMod)..", Costs: "..(Costs))
				break
				end
			end

			if not Illness then
				if (GetHP("SickSim0") == GetMaxHP("SickSim0")) then
					MsgSay("","@L_MEDICUS_TREATMENT_DOC_NOTHING")
					Cured = true
					SimResetBehavior("SickSim0")
					RemoveProperty("SickSim0", "WaitingForTreatment")
				else 
					Costs = (GetMaxHP("SickSim0") - GetHP("SickSim0"))
					Med = "Bandage"
					FavorMod = GL_FAVOR_MOD_SMALL
				end
			end

			if Cured == false then

				LogMessage( GetProperty("Hospital",Med.."s") )
				local NumOfMeds = 0
				if GetItemCount("Hospital",Med,INVENTORY_STD)>0 then
					CanHeal = 1
				elseif GetItemCount("Hospital",Med,INVENTORY_SELL)>0 then
					CanHeal = 2
				elseif HasProperty("Hospital",Med.."s") and GetProperty("Hospital",Med.."s")>0 then 
					NumOfMeds = GetProperty("Hospital",Med.."s")
					CanHeal = 3
				end

				if CanHeal ~= false then
					
					if DynastyIsPlayer("SickSim0") then
						
						if chr_SpendMoney("SickSim0", Costs, "Offering") then
							ManageMedicine(CanHeal,Med,NumOfMeds)
							CreditMoney("Hospital", Costs, "Offering")
							
							if Illness ~= false then 
								MsgSayNoWait("", "@L_MEDICUS_TREATMENT_DOC_"..string.upper(sickness:getName()))
								Sleep(2)
								Disease[sickness:getName()]:cureSim("SickSim0")
								local sublist = {"Fracture","BurnWound","Pox","Pneumonia","Blackdeath"}
								for i = 1,5 do
								  if sickness.getName() == sublist[i] then
								  	ms_medicaltreatment_LayToBed("","SickSim0",BedNumber)
								  	  if sickness.getName() == "Blackdeath" then
								  	  	AddImpact("SickSim0","PlagueImmunity", 1, 120)
								  	  end
								  end 
								end
							else
								MsgSayNoWait("", "@L_MEDICUS_TREATMENT_DOC_HPLOSS") 
								Sleep(2)
								ModifyHP("SickSim0", GetMaxHP("SickSim0") - GetHP("SickSim0"), true)
							end
						
							if HasData("LayStill") then
								RemoveData("LayStill")
							end
							
							if BuildingGetOwner("Hospital", "MyBoss") then
								chr_ModifyFavor("SickSim0", "MyBoss", FavorMod)
							end
							Cured = true
						else
							MsgSay("", "@L_MEDICUS_TREATMENT_DOC_NOMONEY")
						end
					else
						-- heal the AI
						local data = GetProperty("Hospital",Med.."s")
						ManageMedicine(CanHeal,Med,data) 							
						CreditMoney("Hospital",Costs,"Offering")
						-- for the balance
							local TotalIncome = 0
							if HasProperty("Hospital", "TotalIncome") then
								TotalIncome = GetProperty("Hospital","TotalIncome")
							end
							local RoundIncome = 0
							if HasProperty("Hospital", "RoundIncome") then
								RoundIncome = GetProperty("Hospital","RoundIncome")
							end
							local MedicalIncome = 0
							if HasProperty("Hospital", "MedicalIncome") then
								MedicalIncome = GetProperty("Hospital","MedicalIncome")
							end
							SetProperty("Hospital", "TotalIncome",(TotalIncome+Costs))
							SetProperty("Hospital", "RoundIncome",(RoundIncome+Costs))
							SetProperty("Hospital", "MedicalIncome",(MedicalIncome+Costs))

							


						local list = {["Fracture"]=1,["BurnWound"]=1,["Pox"]=1,["Caries"]=1,["Pneumonia"]=1,["Blackdeath"]=1}
						if Illness ~= false then
							MsgSayNoWait("","@L_MEDICUS_TREATMENT_DOC_"..string.upper(sickness:getName()))

							Disease[sickness:getName()]:cureSim("SickSim0")
						    if not list[sickness.getName()] == nil then
						      ms_medicaltreatment_LayToBed("", "SickSim0", BedNumber)
						    end
						else
							MsgSayNoWait("", "@L_MEDICUS_TREATMENT_DOC_HPLOSS") 

							local ToHeal = GetMaxHP("SickSim0") - GetHP("SickSim0")
							ModifyHP("SickSim0", ToHeal, true)
					    end
						
						if HasData("LayStill") then
							RemoveData("LayStill")
						end
						
						-- modify the favor to the boss
							if BuildingGetOwner("Hospital", "MyBoss") then
								chr_ModifyFavor("SickSim0", "MyBoss", FavorMod)
							end
						Cured = true
					end
				else
					--not enough mats
					MsgSayNoWait("","@L_MEDICUS_TREATMENT_DOC_NOMATS",ItemGetLabel(Med,false))
					Sleep(2)
					if GetImpactValue("Hospital","hospitalmessagesent")==0 then
						AddImpact("Hospital","hospitalmessagesent",1,4)
						feedback_MessageWorkshop("Hospital","@L_MEDICUS_TREATMENT_MSG_NOMATS_HEAD_+0",
									"@L_MEDICUS_TREATMENT_MSG_NOMATS_BODY_+0",
									GetID("Hospital"),ItemGetLabel(Med,false))
					end
					
					-- if bandages are missing, AI stops to produce something
					if Med == "Bandage" then
						if BuildingGetAISetting("Hospital", "Produce_Selection") > 0 then
							if BuildingGetProducerCount("Hospital", PT_MEASURE, "MedicalTreatment") > 1 then
								SimSetProduceItemID("", -1, -1)
								StopMeasure()
							end
						end
					end
				end
			end


			if not Cured then
			 	SetProperty("SickSim0", "IgnoreHospital", GetID("Hospital"))
			 	SetProperty("SickSim0", "IgnoreHospitalTime", GetGametime()+12)
			else
				MoveSetActivity("SickSim0","")
				AddImpact("SickSim0", "Resist", 1, 6)
			end

			if HasProperty("SickSim0", "WaitingForTreatment") then
				RemoveProperty("SickSim0", "WaitingForTreatment")
			end

			SetData("Blocked", 1)
			SetState("", STATE_DUEL, false)
		end
	end
end

function BlockMe()
	while GetData("Blocked")~=1 do
		Sleep(1)
		if not GetState("", STATE_DUEL) then
			SetState("", STATE_DUEL, true)
		end
	end
	
	if HasProperty("", "WaitingForTreatment") then
		RemoveProperty("", "WaitingForTreatment")
	end

	SetState("", STATE_DUEL, false)
	CreateScriptcall("SendHome", 0, "Measures/ms_MedicalTreatment.lua", "LeaveBuilding", "")
	return
end

function LeaveBuilding()
	Sleep(3)
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