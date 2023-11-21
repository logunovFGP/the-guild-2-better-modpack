function Weight()

	if not ReadyToRepeat("dynasty", "AI_CheckChilds") then
		return 0
	end

	local Count = DynastyGetMemberCount("dynasty")
	
	for i=0, Count-1 do
		if DynastyGetMember("dynasty", i, "Parent") then
			local Childs = SimGetChildrenCount("Parent")
			if Childs > 0 then
				for c=0, Childs-1 do
					if SimGetChildren("Parent", c, "Child") then
						
						-- check for settlement
						if not GetSettlement("Child", "City") then
							GetSettlement("Parent", "City")
							GetHomeBuilding("Parent", "MyHome")
							SetHomeBuilding("Child", "MyHome")
						end
			
						local ChildAge = SimGetAge("Child")
						local EduLevel = GetProperty("Child", "EduLevel") or 0
						local Measure = GetCurrentMeasureName("Child")
						
						-- idle?
						if Measure == "Schooldays" or Measure == "Apprenticeship" or Measure == "University" then
					
							-- check for school
							if EduLevel == 0 and ChildAge >= GL_AGE_FOR_SCHOOL and ChildAge < GL_AGE_FOR_APPRENTICESHIP and GetMoney("Parent") > GL_SCHOOLMONEY then
								SetData("ToDo", "School")
								return 100
							end
							
							-- check for apprenticeship
							if not HasProperty("Child", "is_apprentice") and ChildAge >= GL_AGE_FOR_APPRENTICESHIP and ChildAge < GL_AGE_FOR_UNIVERSITY and GetMoney("Parent") > GL_APPRENTICESHIPMONEY then
								SetData("ToDo", "Apprentice")
								return 100
							end
							
							-- check for university
							if SimGetClass("Child") == 3 and EduLevel > 0 and EduLevel < 3 and GetMoney("Parent") > GL_UNIVERSITYMONEY then
								SetData("ToDo", "Uni")
								return 100
							end
						end
					end
				end
			end
		end
	end
	
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

