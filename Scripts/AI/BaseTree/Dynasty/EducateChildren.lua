-- Education is mandatory. Weight() finds the child and the measure - school for a
-- child in its school days, the apprenticeship (which sets the class) for a child in
-- its apprenticeship years, university for a scholar - so a pick is never wasted,
-- and its weight outranks everything else in Dynasty/. The apprenticeship is steered
-- into the dynasty's main class, or into rogue while the house lacks its fighter
-- (aitwp_WantedApprenticeClass); ms_150_AttendApprenticeship reads AI_ApprenticeClass.
function Weight()
	if not ReadyToRepeat("dynasty", "AI_Educate") then
		return 0
	end
	if not DynastyGetRandomBuilding("dynasty", GL_BUILDING_CLASS_LIVINGROOM, GL_BUILDING_TYPE_RESIDENCE, "home") then
		return 0
	end
	if not GetSettlement("home", "City") then
		return 0
	end
	if not (CityGetRandomBuilding("City", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "School")
			and gameplayformulas_CheckPublicBuilding("City", GL_BUILDING_TYPE_GUILDHOUSE)[1] > 0) then
		return 0
	end
	local MyID = GetID("dynasty")
	local FamilyCount = DynastyGetFamilyMemberCount("dynasty")
	for i = 0, FamilyCount - 1 do
		if DynastyGetFamilyMember("dynasty", i, "Pupil") and GetDynastyID("Pupil") == MyID and not GetState("Pupil", STATE_DEAD) then
			local Education = GetProperty("Pupil", "EduLevel") or EDULEVEL_NONE
			local Behavior = SimGetBehavior("Pupil")
			local Current = GetCurrentMeasureName("Pupil")
			if Behavior == "SchoolDays" and Education == EDULEVEL_NONE and Current ~= "AttendSchool" then
				SetData("EduMeasure", "AttendSchool")
				return utility_Trace("dynasty", "EducateChildren", 200)
			end
			if Behavior == "Apprenticeship" and not HasProperty("Pupil", "is_apprentice") and Current ~= "AttendApprenticeship" then
				SetData("EduMeasure", "AttendApprenticeship")
				return utility_Trace("dynasty", "EducateChildren", 200)
			end
			if (Behavior == "University" or SimGetAge("Pupil") >= 15) and SimGetClass("Pupil") == GL_CLASS_SCHOLAR
					and (Education == EDULEVEL_SCHOOL or Education == EDULEVEL_UNIVERSITY1) and Current ~= "AttendUniversity" then
				SetData("EduMeasure", "AttendUniversity")
				return utility_Trace("dynasty", "EducateChildren", 200)
			end
		end
	end
	return 0
end

function Execute()
	utility_Picked("dynasty", "EducateChildren")
	local Measure = GetData("EduMeasure")
	if not Measure or not AliasExists("Pupil") then
		return
	end
	-- an hour between school runs: a start the measure refuses must not eat every tick
	SetRepeatTimer("dynasty", "AI_Educate", 1)
	if Measure == "AttendApprenticeship" then
		SetProperty("Pupil", "AI_ApprenticeClass", aitwp_WantedApprenticeClass("dynasty"))
	end
	aitwp_Log(Measure .. " for " .. GetName("Pupil"), "dynasty")
	MeasureRun("Pupil", "School", Measure)
end
