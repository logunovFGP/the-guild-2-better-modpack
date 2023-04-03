-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_MedicalTreatment"
----
----	with this measure, the player can assign a sim to treat sick sims in hospital
----
-------------------------------------------------------------------------------
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
			SetState("", STATE_DUEL, true) -- no measure cancel
			
			-- Dialog
			MsgSay("SickSim0", "@L_MEDICUS_TREATMENT_PATIENT")
			MsgSay("", "@L_MEDICUS_TREATMENT_DOC_INTRO")
			f_MoveTo("SickSim0", "Owner", GL_MOVESPEED_WALK, 60)
			PlayAnimation("", "manipulate_middle_twohand")
			local Costs = 50
			local Cured = false
			local Disease = false
			local CanHeal = false
			local Medicine, Label, FavorMod
			local list = {"Sprain","Cold","Influenza","Pox","BurnWound","Pneumonia","Blackdeath","Fracture","Caries"}
			local label
			local sickness = 0

			for i = 1,9 do 
			  label = list[i]
			  LogMessage('Hospital: An attempt to GetImpactValue with ["'..label..'"] has been executed!')
			  LogMessage('GetImpactValue results: '..GetImpactValue("SickSim0", label))
			  if GetImpactValue("SickSim0", list[i]) == 1 then
			  	sickness = list[i]
			  	LogMessage(list[i]..' has been detected!')
			  	break
			  end
			end

			if sickness ~= 0 then
			  	LogMessage('Hospital: value label set to '..label)
			    Disease = label
			    LogMessage('Hospital: value Disease set to '..Disease)
			    Medicine = diseases[label].medicine
			    LogMessage('Hospital: Looking for some '..Medicine..'(s)')
			    FavorMod = diseases[label].favor
			    LogMessage('Hospital: FavorMod is set to '..FavorMod)
			    Label = string.upper(label)
			    LogMessage('Hospital: UPPER LABEL is '..Label)
			  elseif sickness == 0 and (GetHP("SickSim0") < GetMaxHP("SickSim0")) then
			  	Medicine = "Bandage"
			  	FavorMod = GL_FAVOR_MOD_SMALL
			  	Label = "HPLOSS"
			  elseif sickness == 0 and (GetHP("SickSim0") == GetMaxHP("SickSim0")) then
				MsgSay("","@L_MEDICUS_TREATMENT_DOC_NOTHING")
				Cured = true
				SimResetBehavior("SickSim0")
				RemoveProperty("SickSim0", "WaitingForTreatment")
			end

			if Cured == false then
				-- TREATMENT
				if Disease == false then -- special case HP LOSS
					Costs = GetMaxHP("SickSim0") - GetHP("SickSim0")
				else
					Costs = diseases_GetTreatmentCost(Disease)
				end
				
				local NumOfMeds = 0
				
				if GetItemCount("Hospital",Medicine,INVENTORY_STD)>0 then
					CanHeal = 1
				elseif GetItemCount("Hospital",Medicine,INVENTORY_SELL)>0 then
					CanHeal = 2
				elseif HasProperty("Hospital",Medicine.."s") and GetProperty("Hospital",Medicine.."s")>0 then 
					NumOfMeds = GetProperty("Hospital",Medicine.."s")
					CanHeal = 3
				end
				
				if CanHeal ~= false then
					if DynastyIsPlayer("SickSim0") then
						-- only Players need to pay
						if chr_SpendMoney("SickSim0", Costs, "Offering") then
							-- remove medicine
							if CanHeal == 1 then
								RemoveItems("Hospital",Medicine,1,INVENTORY_STD)
							elseif CanHeal == 2 then
								RemoveItems("Hospital",Medicine,1,INVENTORY_SELL)
							elseif CanHeal == 3 then
								SetProperty("Hospital",Medicine.."s",(NumOfMeds-1))
							end
							
							CreditMoney("Hospital", Costs, "Offering")
							MsgSay("", "@L_MEDICUS_TREATMENT_DOC_"..Label)
							
							if Disease ~= false then 
								--local callCore = diseases[Disease].callback
								--callCore("SickSim0",false)
								diseases_giveSickness(Disease,"SickSim0",false)
								local sublist = {"Fracture","BurnWound","Pox","Pneumonia","Blackdeath"}
								for i = 1,5 do
								  if Disease == sublist[i] then
								  	ms_medicaltreatment_LayToBed("","SickSim0",BedNumber)
								  	  if Disease == "Blackdeath" then
								  	  	AddImpact("SickSim0","PlagueImmunity", 1, 120)
								  	  end
								  end 
								end
							else
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
						else
							-- no money
							MsgSay("", "@L_MEDICUS_TREATMENT_DOC_NOMONEY")
						end
					else
						-- heal the AI
						
						-- remove medicine
						if CanHeal == 1 then
							RemoveItems("Hospital", Medicine,1,INVENTORY_STD)
						elseif CanHeal == 2 then
							RemoveItems("Hospital", Medicine,1,INVENTORY_SELL)
						elseif CanHeal == 3 then
							SetProperty("Hospital", Medicine.."s",(GetProperty("Hospital",Medicine.."s")-1))
						end
							
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
							
						MsgSay("","@L_MEDICUS_TREATMENT_DOC_"..Label)

						local list = {["Fracture"]=1,["BurnWound"]=1,["Pox"]=1,["Caries"]=1,["Pneumonia"]=1,["Blackdeath"]=1}
						if Disease ~= false then
						  diseases_giveSickness(Disease,"SickSim0", false)
						    if not list[Disease] == nil then
						      ms_medicaltreatment_LayToBed("", "SickSim0", BedNumber)
						    end
						else
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
					MsgSay("","@L_MEDICUS_TREATMENT_DOC_NOMATS",ItemGetLabel(Medicine,false))
					if GetImpactValue("Hospital","hospitalmessagesent")==0 then
						AddImpact("Hospital","hospitalmessagesent",1,4)
						feedback_MessageWorkshop("Hospital","@L_MEDICUS_TREATMENT_MSG_NOMATS_HEAD_+0",
									"@L_MEDICUS_TREATMENT_MSG_NOMATS_BODY_+0",
									GetID("Hospital"),ItemGetLabel(Medicine,false))
					end
					
					-- if bandages are missing, AI stops to produce something
					if Medicine == "Bandage" then
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
			 	-- search for another hospital
			 	SetProperty("SickSim0", "IgnoreHospital", GetID("Hospital"))
			 	SetProperty("SickSim0", "IgnoreHospitalTime", GetGametime()+12)
			else
				MoveSetActivity("SickSim0")
				AddImpact("SickSim0", "Resist", 1, 6)
			end
			if HasProperty("SickSim0", "WaitingForTreatment") then
				RemoveProperty("SickSim0", "WaitingForTreatment")
			end
			SetData("Blocked", 1)
			Sleep(2)
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
	CreateScriptcall("SendHome", 0.001, "Measures/ms_MedicalTreatment.lua", "LeaveBuilding", "")
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

