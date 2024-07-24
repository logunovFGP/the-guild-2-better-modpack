function Weight()
	return 0
end
			
function Execute()
	local ToDo = GetData("ToDo")
	SetRepeatTimer("dynasty", "AI_CheckChilds", 3)
	
	if ToDo == "School" then
		MeasureRun("Child", nil, "AttendSchool")
		return
	elseif ToDo == "Apprentice" then
		MeasureRun("Child", nil, "AttendApprenticeship")
		return
	elseif ToDo == "Uni" then
		MeasureRun("Child", nil, "AttendUniversity")
		return
	end
end

