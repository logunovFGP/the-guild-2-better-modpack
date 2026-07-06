-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_HushMoney"
----
----	with this measure the player can send out a mercenary to collect 
----     hushmoney from every bad character within a selected area
----     impact HaveBeenPickpocketed
-------------------------------------------------------------------------------

function Run()

	f_MoveTo("", "Destination", GL_MOVESPEED_RUN)
	--the time a mercenary must wait to check the same person again
	local TimeToWait = 4
	local Value
	local	TimeOut
	TimeOut = GetData("TimeOut")
	
	if TimeOut then
		TimeOut = GetGametime() + TimeOut
	end
	
	if not SimGetWorkingPlace("", "MyHome") then
		if IsPartyMember("") then
			local NextBuilding = ai_GetNearestDynastyBuilding("", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_CASTLE)
			if not NextBuilding then
				StopMeasure()
			end
			CopyAlias(NextBuilding, "MyHome")
		else
			StopMeasure()
		end
	end
	
	while true do
		if TimeOut then
			if TimeOut < GetGametime() then
				break
			end
		end
		local NumOfObjects = Find("Owner","__F( (Object.GetObjectsByRadius(Sim)==1000) AND NOT(Object.BelongsToMe()) AND((Object.GetProfession() == 15)OR (Object.GetProfession() == 18)OR (Object.GetProfession() == 19)OR (Object.GetProfession() == 26)OR (Object.GetProfession() == 30)) AND NOT(Object.HasImpact(HaveBeenPickpocketed)) AND NOT(Object.GetState(cutscene))AND NOT(Object.GetState(townnpc))AND(Object.MinAge(16)))","Sims",-1)

		if NumOfObjects>0 then
			local DoIt = 0
			local DestAlias

			for FoundObject=0,NumOfObjects-1 do
				DestAlias = "Sims"..FoundObject
				if GetImpactValue(DestAlias,"HaveBeenPickpocketed")>0 then
					DoIt = 0				
				elseif GetCurrentMeasureName(DestAlias) == "PickpocketPeople" and SimGetProfession(DestAlias) == GL_PROFESSION_THIEF then 
					DoIt = 1
					break
				elseif GetCurrentMeasureName(DestAlias) == "ScoutAHouse" and SimGetProfession(DestAlias) == GL_PROFESSION_THIEF then 
					DoIt = 1
					break
				elseif GetCurrentMeasureName(DestAlias) == "PressProtectionMoney" and SimGetProfession(DestAlias) == GL_PROFESSION_ROBBER then 
					DoIt = 1
					break
				elseif GetCurrentMeasureName(DestAlias) == "OrderASabotage_Bomb" and SimGetProfession(DestAlias) == GL_PROFESSION_MYRMIDON then 
					DoIt = 1
					break
				elseif GetCurrentMeasureName(DestAlias) == "OrderASabotage_CombustionBomb" and SimGetProfession(DestAlias) == GL_PROFESSION_MYRMIDON then 
					DoIt = 1
					break
				elseif GetCurrentMeasureName(DestAlias) == "AssignToLaborOfLove" and SimGetProfession(DestAlias) == GL_PROFESSION_COCOTTE then 
					DoIt = 1
					break
				elseif GetCurrentMeasureName(DestAlias) == "AssignToThiefOfLove" and SimGetProfession(DestAlias) == GL_PROFESSION_COCOTTE then 
					DoIt = 1
					break
				elseif GetCurrentMeasureName(DestAlias) == "AssignToPoisonEnemy" and SimGetProfession(DestAlias) == GL_PROFESSION_COCOTTE then 
					DoIt = 1
					break
				end
			end

			if DoIt==1 then
				if SendCommandNoWait(DestAlias, "BlockMe") then 
					SetData("Blocked", 1)
						
					f_MoveTo("", DestAlias, GL_MOVESPEED_WALK, 160)
					AlignTo("Owner", DestAlias)
					PlayAnimationNoWait("", "cheer_02")
					local random = Rand(5)
					
					if SimGetGender(DestAlias) == GL_GENDER_MALE then
						MsgSay("", "@L_MEASURE_hushmoney_SAYING_MALE_+"..random)				
					else
						MsgSay("", "@L_MEASURE_hushmoney_SAYING_FEMALE_+"..random)				
					end
					
					Sleep(1)	

					PlayAnimationNoWait("", "use_object_standing")
					CarryObject("","Handheld_Device/Anim_Bag.nif",false)
					PlaySound3D("","Locations/wear_clothes/wear_clothes+1.wav", 1.0)
					Sleep(1)	
					
					local	MercLevel	= SimGetLevel("")
					local RogueBonus =  GetImpactValue("MyHome", "RogueBonus") + 1 or 1
					local	VictimSpendValue = (Rand(50)+(MercLevel * 50) + 50)*RogueBonus
										
					AddImpact(DestAlias, "HaveBeenPickpocketed", 1, TimeToWait)
					BuildingGetOwner("MyHome", "MercOwner")
					
					if GetHomeBuilding(DestAlias, "VictimHome") then
						if BuildingGetOwner("VictimHome", "VictimOwner") then
							local favourloss = GL_FAVOR_MOD_SMALL
							chr_ModifyFavor("VictimOwner", "MercOwner", -favourloss)
						end
					end
					
					chr_RecieveMoney("MercOwner", VictimSpendValue, "IncomeBribes")
					economy_UpdateBalance("MyHome", "Service", VictimSpendValue)
					if achievements_isValidSim("MercOwner", "CRIME_COLLECT_HUSH_MONEY") then
						UpdateStat("STAT_HUSH_MONEY", (GetStat("STAT_HUSH_MONEY") or 0) + math.floor(VictimSpendValue))
					end
					IncrementXPQuiet("", 15)

					PlaySound3D("", "Effects/coins_to_moneybag+0.wav", 1.0)
					PlayAnimationNoWait("", "fetch_store_obj_R")
					Sleep(1)
					PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
					CarryObject("", "", false)	
					
					if IsPartyMember(DestAlias) then
						local Value = GetMoney(DestAlias) * 0.05
						
						if VictimSpendValue > Value then
							VictimSpendValue = Value
						end
						
						chr_SpendMoney(DestAlias, VictimSpendValue,"CostBribes")
					end

					Sleep(0.75)
					SetData("Blocked", 0)
				end
			end	
		end
		
		local NextAnim = Rand(2)
		
		if NextAnim == 0 then
			PlayAnimation("", "watch_for_guard")
		elseif NextAnim == 1 then
			PlayAnimation("", "sentinal_idle")
		else
			Sleep(2.0)		
		end
		
		f_MoveTo("", "Destination", GL_MOVESPEED_WALK, 50)
		GfxRotateToAngle("", 0, Rand(360), 0, 1, true)
		Sleep(1)
	end
end

function BlockMe()
	while GetData("Blocked") == 1 do
		Sleep(3)
	end
end


function CleanUp()
	--stop hiding
	--SetState("",STATE_HIDDEN,false)
	StopAnimation("")
	--StopAction("pickpocket","")
end

