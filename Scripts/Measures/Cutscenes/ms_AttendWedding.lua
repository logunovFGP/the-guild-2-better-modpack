function Run()

	FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WEDDING_CHAPEL")

	if not HasProperty("","#WEDDING_FORCED") then 
		if GetState("", STATE_CUTSCENE) then
			return
		end
		
		local CurrentMeasure = GetCurrentMeasureName("")

		local list = {"AttendTrialMeeting","AttendOfficeMeeting","AttendDuel","AttendFestivity"}

		for i = 1, 4 do
			if CurrentMeasure == list[i] then
				return
			end
		end
		
		if GetImpactValue("", "SuppressAttendMessage") > 0 then
			return
		end
	end
	
	if f_SimIsValid("") == false then 
		return
	end

	LogMessage(GetName("")..' is on the way to '..GetName("#WEDDING_CHAPEL"))

	if HasProperty("","#WEDDING_FORCED") then
		if SimGetGender("") == GL_GENDER_FEMALE then
			GetLocatorByName("#WEDDING_CHAPEL", "Exit1", "#POS")
		else
			GetLocatorByName("#WEDDING_CHAPEL", "Exit2", "#POS")
		end
		f_MoveToNoWait("", "#POS", GL_MOVESPEED_RUN)
	else
		f_MoveTo("", "destination", GL_MOVESPEED_RUN)
	end

	local isInside = false

	repeat
		if GetInsideBuilding("", "#BUILDING") ~= false then
			if GetID("#BUILDING") == GetID("#WEDDING_CHAPEL") then
				isInside = true
				CutsceneCallThread("Wedding", "ChatterGuests", "")
				break
			else
				Sleep(1)
			end
		else
			Sleep(1)
		end
	until (isInside == true)
end