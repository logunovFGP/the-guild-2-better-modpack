function Run()
	local MeasureID = GetCurrentMeasureID("")
	
	if not GetInsideBuilding("", "HomeBuilding") then
		return
	end
	
	local MaxStudyAI = 3
	local EndTime = GetGametime() + MaxStudyAI
	local Found = 0
	
	while true do
		if GetLocatorByName("HomeBuilding", "TakeBook", "TakeBookPos") then
			if f_BeginUseLocator("", "TakeBookPos", GL_STANCE_STAND, true) then
				Found = 1
				local Time = PlayAnimationNoWait("", "manipulate_middle_up_r")
				Sleep(2)
				CarryObject("", "Handheld_Device/ANIM_Closedbook.nif", false)
				Sleep(Time-2.5)
				
				if GetLocatorByName("HomeBuilding", "ReadBook", "ReadBookPos") then
					f_BeginUseLocator("", "ReadBookPos", GL_STANCE_STAND, true)
					Sleep(1)
				elseif GetFreeLocatorByName("HomeBuilding", "Stroll", 1, 3, "ReadBookPos") then
					f_BeginUseLocator("", "ReadBookPos", GL_STANCE_STAND, true)
				end
				
				for i = 0, 3 do
					Time = PlayAnimationNoWait("", "use_book_standing")
					Sleep(1)
					CarryObject("", "Handheld_Device/ANIM_book.nif", false)
					Sleep(Time-2)
					CarryObject("", "Handheld_Device/ANIM_Closedbook.nif", false)
					Sleep(1.5)
				end
				Sleep(1)
				f_EndUseLocator("","ReadBookPos")
				
				if GetFreeLocatorByName("HomeBuilding", "ChildStroll", 4, 4, "TrainEndPos") then
					f_BeginUseLocator("", "TrainEndPos", GL_STANCE_STAND, true)
					Sleep(0.2)
					f_EndUseLocator("", "TrainEndPos")
				end
				
				f_BeginUseLocator("", "TakeBookPos", GL_STANCE_STAND, true)
				Time = PlayAnimationNoWait("", "manipulate_middle_up_r")
				Sleep(2)
				CarryObject("", "", false)
				Sleep(Time-2.5)
				Sleep(1.5)
				f_EndUseLocator("", "TakeBookPos")
			else
				Found = 0
			end
		end
		
		if Found == 0 then
			MsgQuick("", "@L_GENERAL_MEASURES_220_TRAINCHARACTER_FAILURES_+0", GetID("Owner"))
			StopMeasure()
		end
		
		if GetLocatorByName("HomeBuilding", "manipulate_middle_twohand_pos_012", "TablePos") then
			if f_BeginUseLocator("", "TablePos", GL_STANCE_STAND, true) then
				Found = 1
				for i = 0, 2 do
					PlayAnimation("", "cogitate")
					PlayAnimation("", "manipulate_middle_twohand")
				end
				f_EndUseLocator("", "TablePos")
			else
				Found = 0
			end
		end
		
		if Found == 1 then
			chr_GainXP("", 10)
		else
			MsgQuick("", "@L_GENERAL_MEASURES_220_TRAINCHARACTER_FAILURES_+0", GetID("Owner"))
			StopMeasure()
		end
		
		if GetGametime() >= EndTime and DynastyIsAI("") then
			break
		end
		
		PlayAnimation("", "cogitate")
	end

	StopMeasure()
end

function CleanUp()
	
	if AliasExists("TablePos") then
		f_EndUseLocator("", "TablePos")
	end
	
	if AliasExists("TakeBookPos") then
		f_EndUseLocator("", "TakeBookPos")
	end
	
	if AliasExists("ReadBookPos") then
		f_EndUseLocator("", "ReadBookPos")
	end
end