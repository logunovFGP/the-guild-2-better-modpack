function Init()
end

function Run()
	while true do
		
		if GetDynasty("", "MyDynasty") then
			if DynastyIsPlayer("MyDynasty") then
				SetState("", STATE_CHECKFORSPINNINGS, false)
				return
			end
		end
		
		if GetState("", STATE_TOTALLYDRUNK) then
			SetState("", STATE_CHECKFORSPINNINGS, false)
			return
		end
		
		if GetState("", STATE_LOCKED) then
			SetState("", STATE_CHECKFORSPINNINGS, false)
			return
		end
		
		if GetState("", STATE_ANIMAL) then
			SetState("", STATE_CHECKFORSPINNINGS, false)
			return
		end
		
		if GetState("", STATE_CUTSCENE) then
			SetState("", STATE_CHECKFORSPINNINGS, false)
			return
		end
		
		if not f_SimIsValid("") then -- check for states
			SetState("", STATE_CHECKFORSPINNINGS, false)
			return
		end
		
		if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
			SetState("", STATE_CHECKFORSPINNINGS, false)
			return
		end
		
		if GetInsideBuildingID("") >= 0 then
			return
		else
			GetPosition("", "StartPos")
			Sleep(30)
			if GetInsideBuildingID("") == -1 then -- outside
				GetPosition("", "CheckPos")
				if GetState("", STATE_CHECKFORSPINNINGS) then
					if GetDistance("StartPos", "CheckPos") <= 100 then 
						if GetCurrentMeasureName("") == "WorldTrader" then
							MoveStop("")
							MeasureRun("", nil, "WorldTrader", true)
							return
						else
							MoveStop("")
							SimStopMeasure("")
							return
						end
					end
				else
					return
				end
			else
				return
			end
		end
	end
end
		
function CleanUp()
	if GetState("", STATE_CHECKFORSPINNINGS) then
		SetState("", STATE_CHECKFORSPINNINGS, false)
	end
end