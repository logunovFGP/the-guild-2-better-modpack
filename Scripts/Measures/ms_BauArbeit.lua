function Run()
	
	local impiwert = GetImpactValue("Destination", "BauArbeiter")
	if not GetStateImpact("Destination", "upgrading") then
		if impiwert > 0 then
			RemoveImpact("Destination", "BauArbeiter")
		end
	end

	if DynastyIsPlayer("") == true then	
		local neuwert
		if SimGetClass("") == 2 then
			neuwert = impiwert + 2
			AddImpact("Destination", "BauArbeiter", neuwert, -1)
		else
			neuwert = impiwert + 1
			AddImpact("Destination", "BauArbeiter", neuwert, -1)
		end
		SetProperty("Destination", "BauIntervall", neuwert)
		ms_bauarbeit_Arbeiter()
	else
		
		local baufast = 1 -- fallback
		if HasProperty("Destination", "baufast") then
			baufast = GetProperty("Destination", "baufast")
		end
		
		if impiwert < 1 then
			AddImpact("Destination", "BauArbeiter", baufast, -1)
		end
		
		if SimGetProfession("") == 59 or SimGetProfession("") == 60 then
			ms_bauarbeit_Meister()
		else
			ms_bauarbeit_Arbeiter()
		end
	end
end

function Meister()

	local doWork = { ms_bauarbeit_MasterA }
	CarryObject("", "Handheld_Device/Anim_scroll.nif", false)				 		 
	while GetImpactValue("Destination", "BauArbeiter") > 2 do
		if not GetStateImpact("Destination", "upgrading") then
			RemoveImpact("Destination", "BauArbeiter")
			break
		end
		
		local SleepDifference = (Rand(35) + 1)*0.1
		Sleep(SleepDifference)
		
		local BestPos = 5
			
		if not HasProperty("", "MyPos") then
			for i=1, 4 do
				local RandomPos = Rand(4)+1
				local Filter = "__F((Object.GetObjectsByRadius(Sim) == 1500) AND (Object.GetState(townnpc)) AND (Object.Property.MyPos == "..RandomPos.."))"
				local Number = Find("", Filter, "Workers", 1)
				if Number < 1 then
					BestPos = RandomPos
					SetProperty("", "MyPos", RandomPos)
					break
				end
				
				Sleep(SleepDifference)
			end
		else
			BestPos = GetProperty("", "MyPos")
		end
		
		doWork[1](BestPos)
	end

	CarryObject("", "", false)
	CarryObject("", "", true)	
	ms_bauarbeit_GoHome()
end

function Arbeiter()

	local doWork = { ms_bauarbeit_WorkA,
                 		ms_bauarbeit_WorkB,
                 		ms_bauarbeit_WorkC,
                 		ms_bauarbeit_WorkD}
	
	if AliasExists("Destination") then
		while GetImpactValue("Destination", "BauArbeiter") >= 1 do
			if not GetStateImpact("Destination", "upgrading") then
				RemoveImpact("Destination", "BauArbeiter")
				break
			end
			
			CarryObject("", "", false)
			CarryObject("", "", true)
			
			local SleepDifference = (Rand(35) + 1)*0.1
			Sleep(SleepDifference)
		
			local BestPos = 5
			
			if not HasProperty("", "MyPos") then
				for i=1, 4 do
					local RandomPos = Rand(4)+1
					
					local Filter = "__F((Object.GetObjectsByRadius(Sim) == 1500) AND (Object.GetState(townnpc)) AND (Object.Property.MyPos == "..RandomPos.."))"
					local Number = Find("", Filter, "Workers", 1)
					if Number < 1 then
						BestPos = RandomPos
						SetProperty("", "MyPos", RandomPos)
						break
					end
					
					Sleep(SleepDifference)
				end
			else
				BestPos = GetProperty("", "MyPos")
			end
		
			doWork[(Rand(4)+1)](BestPos)
		end
	end

	if not DynastyIsPlayer("") then
		ms_bauarbeit_GoHome()
	end
	
	return
end

function MasterA(Pos)
	
	if Pos == 5 then
		GetLocatorByName("Destination", "Entry1", "dest")
	end
	
	local platz = "Bomb"..Pos
	
	if not GetLocatorByName("Destination", platz, "dest") then
		GetLocatorByName("Destination", "Entry1", "dest")
	end
	
	if GetDistance("", "dest") > 100 then
	
		if not f_MoveTo("", "dest", GL_MOVESPEED_WALK) then
			SimBeamMeUp("", "dest", false)
		end
	end
		
	AlignTo("", "Destination")
	if Rand(2) == 0 then
		PlayAnimationNoWait("", "use_book_standing")
		Sleep(1)
		CarryObject("", "Handheld_Device/Anim_openscroll.nif", false)
		PlayAnimation("", "use_book_standing")
		CarryObject("", "Handheld_Device/Anim_scroll.nif", false)
	end
	
	local spruch = Rand(4)
	if SimGetProfession("") == 60 then
		if spruch == 0 then
			MsgSay("", "@L_HPFZ_BAUARBEIT_SPRUCH_+0")
		elseif spruch == 1 then
			MsgSay("", "@L_HPFZ_BAUARBEIT_SPRUCH_+1")
		elseif spruch == 2 then
			MsgSay("", "@L_HPFZ_BAUARBEIT_SPRUCH_+2")
		else
			MsgSay("", "@L_HPFZ_BAUARBEIT_SPRUCH_+3")
		end
	else
		BuildingGetOwner("Destination", "BuildingOwner")
		if spruch == 0 then
			MsgSay("", "@L_HPFZ_BAUARBEIT_SPRUCH_+4", GetID("BuildingOwner"))
		elseif spruch == 1 then
			MsgSay("", "@L_HPFZ_BAUARBEIT_SPRUCH_+5", GetID("BuildingOwner"))
		elseif spruch == 2 then
			MsgSay("", "@L_HPFZ_BAUARBEIT_SPRUCH_+6", GetID("BuildingOwner"))
		else
			MsgSay("", "@L_HPFZ_BAUARBEIT_SPRUCH_+7", GetID("BuildingOwner"))
		end
	end
	Sleep(1)
end	
	
function WorkA(Pos)
	if Pos == 5 then
		GetLocatorByName("Destination", "Entry1", "dest")
	end
	
	local platz = "Bomb"..Pos
	
	if not GetLocatorByName("Destination", platz, "dest") then
		GetLocatorByName("Destination", "Entry1", "dest")
	end
	
	if GetDistance("", "dest") > 100 then
		if not f_MoveTo("", "dest", GL_MOVESPEED_WALK) then
			SimBeamMeUp("", "dest", false)
		end
	end
	
	SetContext("", "rangerhut")
	CarryObject("", "Handheld_Device/Anim_Hammer.nif", false)
	AlignTo("", "Destination")
	Sleep(1)
	PlayAnimation("", "hammer_in")
	LoopAnimation("", "hammer_loop", 20)
	PlayAnimation("", "hammer_out")
end

function WorkB(Pos)
	if Pos == 5 then
		GetLocatorByName("Destination", "Entry1", "dest")
	end
	
	local platz = "Bomb"..Pos
	
	if not GetLocatorByName("Destination", platz, "dest") then
		GetLocatorByName("Destination", "Entry1", "dest")
	end
	
	if GetDistance("", "dest") > 100 then
		if not f_MoveTo("", "dest", GL_MOVESPEED_WALK) then
			SimBeamMeUp("", "dest", false)
		end
	end
	
	CarryObject("", "Handheld_Device/ANIM_Chisel.nif", false)
	AlignTo("", "Destination")
	Sleep(1)
	PlayAnimation("", "knee_work_in")
	LoopAnimation("", "knee_work_loop", 10)
	PlayAnimation("", "knee_work_out")
	
end

function WorkC(Pos)
	if Pos == 5 then
		GetLocatorByName("Destination", "Entry1", "dest")
	end
	
	local platz = "Bomb"..Pos
	
	if not GetLocatorByName("Destination", platz, "dest") then
		GetLocatorByName("Destination", "Entry1", "dest")
	end
	
	if GetDistance("", "dest") > 100 then
		if not f_MoveTo("", "dest", GL_MOVESPEED_WALK) then
			SimBeamMeUp("", "dest", false)
		end
	end
	
	SetContext("", "rangerhut")
	CarryObject("", "Handheld_Device/Anim_Hammer.nif", false)
	AlignTo("", "Destination")
	Sleep(1)
	PlayAnimation("", "chop_in")
	LoopAnimation("", "chop_loop", 20)
	PlayAnimation("", "chop_out")
end

function WorkD(Pos)
	if Pos == 5 then
		GetLocatorByName("Destination", "Entry1", "dest")
	end
	
	local platz = "Bomb"..Pos
	
	if not GetLocatorByName("Destination", platz, "dest") then
		GetLocatorByName("Destination", "Entry1", "dest")
	end
	
	if GetDistance("", "dest") > 100 then
		if not f_MoveTo("", "dest", GL_MOVESPEED_WALK) then
			SimBeamMeUp("", "dest", false)
		end
	end
	
	CarryObject("", "Handheld_Device/ANIM_Chisel.nif", false)
	AlignTo("", "Destination")
	Sleep(1)
	PlayAnimation("", "manipulate_top_r")
	PlayAnimation("", "manipulate_middle_twohand")
end

function GoHome()
	CarryObject("", "", false)
	CarryObject("", "", true)
	
	if AliasExists("Destination") then
		FindNearestBuilding("Destination", 1, 1, -1, false, "Haia")
		f_WeakMoveTo("", "Haia", GL_MOVESPEED_RUN, 20)
	end
	
	if not DynastyIsPlayer("") then
		InternalDie("")
		InternalRemove("")
	end
end

function CleanUp()

	RemoveProperty("", "MyPos")
	
	if AliasExists("Destination") then
		if GetStateImpact("Destination", "upgrading") then
	   		if SimGetClass("") == 2 then
				AddImpact("Destination", "BauArbeiter", -2, -1)
	   		else
				AddImpact("Destination", "BauArbeiter", -1, -1)
			end
		end
	end
	
	if AliasExists("") then
		if not DynastyIsPlayer("") then
			InternalDie("")
			InternalRemove("")
		end
	end
end
