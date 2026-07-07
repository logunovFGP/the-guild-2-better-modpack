function Run()
	
	local impiwert = GetImpactValue("Destination", "BauArbeiter")
	if not GetStateImpact("Destination", "upgrading") then
		if impiwert > 0 then
			RemoveImpact("Destination", "BauArbeiter")
		end
	end
	
	local SleepDifference = (Rand(10) + 1)*0.2
	Sleep(SleepDifference)
	
	local BauPos = 5
	
	if not HasProperty("Destination", "BauPos1") then
		BauPos = 1
		SetProperty("Destination", "BauPos1", 1)
	elseif not HasProperty("Destination", "BauPos2") then
		BauPos = 2
		SetProperty("Destination", "BauPos2", 1)
	elseif not HasProperty("Destination", "BauPos3") then
		BauPos = 3
		SetProperty("Destination", "BauPos3", 1)
	elseif not HasProperty("Destination", "BauPos4") then
		BauPos = 4
		SetProperty("Destination", "BauPos4", 1)
	end

	if IsPartyMember("") then	
		local neuwert
		if SimGetClass("") == GL_CLASS_ARTISAN then
			neuwert = impiwert + 2
			AddImpact("Destination", "BauArbeiter", neuwert, -1)
			SetProperty("Destination", "BauIntervall", neuwert)
			ms_bauarbeit_Arbeiter(BauPos)
		else
			neuwert = impiwert + 1
			AddImpact("Destination", "BauArbeiter", neuwert, -1)
			SetProperty("Destination", "BauIntervall", neuwert)
			ms_bauarbeit_Meister(BauPos)
		end
	else
		
		local baufast = 1 -- fallback
		if HasProperty("Destination", "baufast") then
			baufast = GetProperty("Destination", "baufast")
		end
		
		if impiwert < 1 then
			AddImpact("Destination", "BauArbeiter", baufast, -1)
		end
		
		if SimGetProfession("") == GL_PROFESSION_BAUMEISTER or SimGetProfession("") == GL_PROFESSION_BAUKUENSTLER then
			ms_bauarbeit_Meister(BauPos)
		else
			ms_bauarbeit_Arbeiter(BauPos)
		end
	end
end

function Meister(Pos)

	local doWork = { ms_bauarbeit_MasterA,
				ms_bauarbeit_WorkD}
	CarryObject("", "Handheld_Device/Anim_scroll.nif", false)				 		 
	while GetImpactValue("Destination", "BauArbeiter") > 2 do
		if not GetStateImpact("Destination", "upgrading") then
			RemoveImpact("Destination", "BauArbeiter")
			break
		end
		
		local Random = Rand(2) +1
		doWork[Random](Pos)
	end

	CarryObject("", "", false)
	CarryObject("", "", true)
	if not IsPartyMember("") then
		ms_bauarbeit_GoHome()
	end
end

function Arbeiter(Pos)

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
		
			doWork[(Rand(4)+1)](Pos)
		end
	end

	if not IsPartyMember("") then
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
	
	if not GetStateImpact("Destination", "upgrading") then
		return
	end
	
	local spruch = Rand(4)
	if SimGetProfession("") == GL_PROFESSION_BAUKUENSTLER or IsPartyMember("") then
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
	
	if not GetStateImpact("Destination", "upgrading") then
		return
	end
	
	SetContext("", "rangerhut")
	CarryObject("", "Handheld_Device/Anim_Hammer.nif", false)
	AlignTo("", "Destination")
	Sleep(1)
	PlayAnimation("", "hammer_in")
	LoopAnimation("", "hammer_loop", 10)
	if not GetStateImpact("Destination", "upgrading") then
		return
	end
	LoopAnimation("", "hammer_loop", 10)
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
	if not GetStateImpact("Destination", "upgrading") then
		return
	end
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
	LoopAnimation("", "chop_loop", 10)
	if not GetStateImpact("Destination", "upgrading") then
		return
	end
	LoopAnimation("", "chop_loop", 10)
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
	if not GetStateImpact("Destination", "upgrading") then
		return
	end
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
	
	InternalDie("")
	InternalRemove("")
end

function CleanUp()
	
	StopAnimation("")
	CarryObject("", "", false)
	CarryObject("", "", true)
	
	if AliasExists("Destination") then
		
		for i=1, 4 do
			if HasProperty("Destination", "BauPos"..i) then
				RemoveProperty("Destination", "BauPos"..i)
			end
		end
		
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
