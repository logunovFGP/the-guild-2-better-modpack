function Run()
	LogMessage("ms_AttendWedding, destination:")
	LogMessage(GetName("destination"))

	SetProperty("", "destination_ID", GetID("destination"))

	if not HasProperty("","#WEDDING_FORCED") then 
	
		local CurrentMeasure = GetCurrentMeasureName("")

		local list = {"AttendTrialMeeting","AttendOfficeMeeting","AttendDuel","AttendFestivity"}

		for i = 1, 4 do
			if CurrentMeasure == list[i] then
				return
			end
		end
	end
	
	if f_SimIsValid("") == false then 
		return
	end

	LogMessage(GetName("")..' is on the way to '..GetName("destination")) 

	SimSetProduceItemID("", -1, -1)

	if HasProperty("", "#WEDDING_FORCED") then
		if SimGetGender("") == GL_GENDER_FEMALE then
			GetLocatorByName("destination", "Exit1", "#POS")
		else
			GetLocatorByName("destination", "Exit2", "#POS")
		end
		f_AttendMoveTo("", "#POS", GL_MOVESPEED_RUN, 5)
	else
		f_AttendMoveTo("", "destination", GL_MOVESPEED_RUN, 5)
	end

	if DynastyIsAI("") then
		SimSetBehavior("", "CheckPrewedding")
	end
	
end