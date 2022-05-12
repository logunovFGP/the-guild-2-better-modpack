-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_talk"
----
----	Script functions library for talk situations
----
-------------------------------------------------------------------------------

-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end

-- -----------------------
-- ThreatCharacter
-- -----------------------
function ThreatCharacter(Rhetoric)

	local label = "@L_INTRIGUE_THREAT_CHARACTER"
	
	if (Rhetoric < 4) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 7) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	return label
end

-- -----------------------
-- AskLiaison
-- -----------------------
function AskLiaison(Rhetoric, Gender)

	local label = "@L_LIAISON_QUESTION"
	
	if (Rhetoric < 4) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 7) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end

-- -----------------------
-- AnswerLiaison
-- -----------------------
function AnswerLiaison(Rhetoric, Gender)

	local label = "@L_LIAISON_ANSWER"
	
	if (Rhetoric < 4) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 7) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
		
	return label
end

-- -----------------------
-- AnswerCourtingMeasure
-- -----------------------
function AnswerCourtingMeasure(Kind, Rhetoric, Gender, CourtingProgress)

	local label = "@L_SOCIAL_ANSWER_"..Kind
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end	
	
	if (Kind == "TALK") or (Kind == "COMPLIMENT") or (Kind == "DANCE") or (Kind == "MAKE_A_PRESENT") then
		
		if (CourtingProgress <= 0) then
			if (CourtingProgress < -6) then
				label = label.."_WAY_TOO_PROFOUND_"
			else
				label = label.."_PROFOUND_"
			end
		else
			if (CourtingProgress >= 15) then
				label = label.."_VERY_WELL_RECEIVED_"
			else			
				label = label.."_WELL_RECEIVED_"
			end
		end
		
	else
	
		if (CourtingProgress <= 0) then
			if (CourtingProgress <- 6) then
				label = label.."_WAY_TOO_OFFENSIVE_"
			else
				label = label.."_OFFENSIVE_"
			end
		else
			if (CourtingProgress >= 15) then
				label = label.."_VERY_WELL_RECEIVED_"
			else			
				label = label.."_WELL_RECEIVED_"
			end
		end		
	
	end
	
	label = label.."+"..Gender
	return label
end

-- -----------------------
-- AnswerMissingVariation
-- -----------------------
function AnswerMissingVariation(Gender, Rhetoric)

	local label = "@L_SOCIAL_ANSWER_NO_VARIATION"
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_MALE"
	else
		label = label.."_FEMALE"
	end
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	return label
	
end

-- -----------------------
-- AnswerBathSuccess
-- -----------------------
function AnswerBathing(Gender, Rhetoric, Success)

	local label = "@L_SOCIAL_ANSWER_TAKE_A_BATH"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end

	if (Success == true) then
		label = label.."_WELL_RECEIVED"
	else
		label = label.."_OFFENSIVE"
	end

	if (Gender == GL_GENDER_MALE) then
		label = label.."_+1"
	else
		label = label.."_+0"
	end
		
	return label
	
end

-- ------------------------------
-- SocialMeasureFailedBeforeStart
-- ------------------------------
function SocialMeasureFailedBeforeStart(Gender, Rhetoric, Kind)

	local label = "@L_SOCIAL_ANSWER_FAILED_BEFORE_START"
	
	if (Kind == "Slap") then
		label = label.."_SLAP"
	else
		label = label.."_OUTRAGED"
	end
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_MALE"
	else
		label = label.."_FEMALE"
	end
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	return label
	
end

-- ----------------------
-- SocialMeasureSucceeded
-- ----------------------
function SocialMeasureSucceeded(Gender, Rhetoric, Kind)

	Assert(Kind, "Param 'Kind' not specified")
	if not Kind then
		return
	end
	local label = "@L_SOCIAL_ANSWER_SUCCEEDED_"..Kind
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_MALE"
	else
		label = label.."_FEMALE"
	end
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	return label
	
end

-- -----------------------
-- AskCohabit
-- -----------------------
function AskCohabit(Rhetoric, Gender)

	local label = "@L_FAMILY_2_COHABITATION_QUESTION"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender==GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end

-- -----------------------
-- AnswerCohabit
-- -----------------------
function AnswerCohabit(Rhetoric, Gender, Success)

	local label = "@L_FAMILY_2_COHABITATION"
	
	if (Success == 1) then
		label = label.."_ANSWER_POSITIVE"
	elseif (Success == 2) then
		label = label.."_ANSWER_NEGATIVE"
	else
		label = label.."_ANSWER_OUTRAGED"
	end
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	return label
end

-- ---------------
-- MakeACompliment
-- ---------------
function MakeACompliment(Gender, Rhetoric)

	local label = "@L_COMPLIMENT"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender==GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
		
end

-- -----------------------
-- FlirtSaying1
-- -----------------------
function FlirtSaying1(Rhetoric, Gender)

	local label = "@L_FLIRT_SAYING1"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender==GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end

-- -----------------------
-- FlirtAnswer
-- -----------------------
function FlirtAnswer(Rhetoric, Gender)

	local label = "@L_FLIRT_ANSWER"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender==GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end

-- -----------------------
-- FlirtSaying2
-- -----------------------
function FlirtSaying2(Rhetoric, Gender)

	local label = "@L_FLIRT_SAYING2"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender==GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end

-- -----------------------
-- AskMarriage
-- -----------------------
function AskMarriage(Rhetoric, Gender)

	local label = "@L_FAMILY_1_MARRIAGE_QUESTION"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end

-- -----------------------
-- AnswerMarriage
-- -----------------------
function AnswerMarriage(Rhetoric, Gender)

	local label = "@L_FAMILY_1_MARRIAGE_ANSWER"
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		label = label.."_NORMAL_RHETORIC"
	else
		label = label.."_GOOD_RHETORIC"
	end
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
end