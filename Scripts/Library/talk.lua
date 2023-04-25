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
-- StartDialog
-- -----------------------
function StartDialog(IsLover, Age, Gender)
	
	local label = "@L_STARTDIALOG_START_"
	
	if Age < 16 then
		label = label.."TOYOUNG"
	else
		label = label.."TOADULT"
	end
	
	if Gender == GL_GENDER_MALE then
		label = label.."_MALE"
	else
		label = label.."_FEMALE"
	end
	
	if IsLover then
		label = label.."_LOVER"
	end
	
	return label
end

-- -----------------------
-- AnswerDialog
-- -----------------------
function AnswerDialog(IsLover, Age, Positive)
	
	local label = "@L_STARTDIALOG_ANSWER_"
	
	if Age < 16 then
		label = label.."YOUNG"
	else
		label = label.."ADULT"
	end
	
	if Positive then
		label = label.."_POSITIVE"
	else
		label = label.."_NEGATIVE"
	end
	
	if IsLover then
		label = label.."_LOVER"
	end
	
	return label
end

-- -----------------------
-- FavorDialog
-- -----------------------
function FavorDialog(IsLover, Age, Positive)
	
	local label = "@L_STARTDIALOG_FAVOR_"
	
	if Age < 16 then
		label = label.."YOUNG"
	else
		label = label.."ADULT"
	end
	
	if Positive then
		label = label.."_POSITIVE"
	else
		label = label.."_NEGATIVE"
	end
	
	if IsLover then
		label = label.."_LOVER"
	end
	
	return label
end

------------------------
-- AnswerCourtingMeasure
-- -----------------------
function AnswerCourtingMeasure(Kind, Rhetoric, Gender, CourtingProgress)

	local label = "@L_SOCIAL_ANSWER_"..Kind
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		if Rand(4) == 0 then
			label = label.."_WEAK_RHETORIC"
		else
			label = label.."_NORMAL_RHETORIC"
		end
	else
		if Rand(4) == 0 then
			label = label.."_NORMAL_RHETORIC"
		else
			label = label.."_GOOD_RHETORIC"
		end
	end	
	
	if (Kind == "TALK") or (Kind == "COMPLIMENT") or (Kind == "DANCE") or (Kind == "MAKE_A_PRESENT") then
		
		if (CourtingProgress < 1) then
			if (CourtingProgress < -5) then
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
	
		if (CourtingProgress < 1) then
			if (CourtingProgress < -5) then
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
		if Rand(4) == 0 then
			label = label.."_WEAK_RHETORIC"
		else
			label = label.."_NORMAL_RHETORIC"
		end
	else
		if Rand(4) == 0 then
			label = label.."_NORMAL_RHETORIC"
		else
			label = label.."_GOOD_RHETORIC"
		end
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
-- SocialMeasureSucceeded -- only for kisses and hugs
-- ----------------------
function SocialMeasureSucceeded(Gender, Rhetoric, Kind)

	local label = "@L_SOCIAL_ANSWER_SUCCEEDED_KISS"
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_MALE"
	else
		label = label.."_FEMALE"
	end
	
	if (Rhetoric < 3) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 6) then
		if Kind == "Kiss" then -- special case for kissing
			label = label.."_NORMAL_RHETORIC"
		else
			label = label.."_NORMAL_RHETORIC_+0"
		end
	else
		if Kind == "Kiss" then -- special case for kissing
			label = label.."_GOOD_RHETORIC"
		else
			label = label.."_GOOD_RHETORIC_+1"
		end
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
function FlirtAnswer(Rhetoric, Gender, Type)

	local label = "@L_FLIRT_ANSWER"
	
	if Type == nil or Type == 0 then
		label = label.."_GENERAL"
	end
	
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

--7298   "_FAMILY_1_MARRIAGE_ANSWER_WEAK_RHETORIC_TOMALE_+0"   "#E[LV_LOVING]Ja."   |
--7299   "_FAMILY_1_MARRIAGE_ANSWER_WEAK_RHETORIC_TOMALE_+1"   "#E[LV_LOVING]Gerne, mein Herr."   |
--7300   "_FAMILY_1_MARRIAGE_ANSWER_WEAK_RHETORIC_TOMALE_+2"   "#E[LV_LOVING]Nur zu gerne, Herr."   |
--7301   "_FAMILY_1_MARRIAGE_ANSWER_WEAK_RHETORIC_TOFEMALE_+0"   "#E[LV_LOVING]Ja."   |
--7302   "_FAMILY_1_MARRIAGE_ANSWER_WEAK_RHETORIC_TOFEMALE_+1"   "#E[LV_LOVING]Gerne, meine Dame."   |
--7303   "_FAMILY_1_MARRIAGE_ANSWER_WEAK_RHETORIC_TOFEMALE_+2"   "#E[LV_LOVING]Nur zu gerne."   |
--7304   "_FAMILY_1_MARRIAGE_ANSWER_NORMAL_RHETORIC_TOMALE_+0"   "#E[LV_LOVING]Liebend gerne, mein Herr."   |
--7305   "_FAMILY_1_MARRIAGE_ANSWER_NORMAL_RHETORIC_TOMALE_+1"   "#E[LV_LOVING]Aber natürlich. Ich habe auf diese Frage schon lange gewartet."   |
--7306   "_FAMILY_1_MARRIAGE_ANSWER_NORMAL_RHETORIC_TOMALE_+2"   "#E[LV_LOVING]Ich freue mich über Euren Antrag, mein Herr. Ja, ich liebe Euch ebenso wie Ihr es so oft sagtet. Lasst uns heiraten."   |
--7307   "_FAMILY_1_MARRIAGE_ANSWER_NORMAL_RHETORIC_TOFEMALE_+0"   "#E[LV_LOVING]Liebend gerne, meine Dame. Ich bin Euch verfallen."   |
--7308   "_FAMILY_1_MARRIAGE_ANSWER_NORMAL_RHETORIC_TOFEMALE_+1"   "#E[LV_LOVING]Aber natürlich. Ich habe auf diese Frage schon so lange gewartet, mich selbst jedoch nie getraut, Euch zu fragen. Dies nur aus Angst, Ihr würdet mich nicht wollen."   |
--7309   "_FAMILY_1_MARRIAGE_ANSWER_NORMAL_RHETORIC_TOFEMALE_+2"   "#E[LV_LOVING]Ich freue mich über Euren Antrag, meine Dame. Und ich willige nur zu gerne ein - lasst uns heiraten."   |
--7310   "_FAMILY_1_MARRIAGE_ANSWER_GOOD_RHETORIC_TOMALE_+0"   "#E[LV_LOVING]Ich könnte mir keinen besseren Ehemann vorstellen als Euch. Ja, ja, ach, ich freue mich so sehr, mit Euch zusammen zu leben."   |
--7311   "_FAMILY_1_MARRIAGE_ANSWER_GOOD_RHETORIC_TOMALE_+1"   "#E[LV_LOVING]Ihr erfüllt mir einen Herzenswunsch, mein Herr. Nur zu gerne will ich Euch heiraten."   |
--7312   "_FAMILY_1_MARRIAGE_ANSWER_GOOD_RHETORIC_TOMALE_+2"   "#E[LV_LOVING]Nichts erfüllt mein Herz mit mehr Freude, als mit Euch mein Leben verbringen zu dürfen. Ja, ich heirate Euch."   |
--7313   "_FAMILY_1_MARRIAGE_ANSWER_GOOD_RHETORIC_TOFEMALE_+0"   "#E[LV_LOVING]Ich könnte mir keine bessere Ehefrau vorstellen als Euch. Ja, ach, ich freue mich, mit Euch zusammen zu leben."   |
--7314   "_FAMILY_1_MARRIAGE_ANSWER_GOOD_RHETORIC_TOFEMALE_+1"   "#E[LV_LOVING]Ihr erfüllt mir einen Herzenswunsch, meine Dame. Nur zu gerne will ich Euch heiraten."   |
--7315   "_FAMILY_1_MARRIAGE_ANSWER_GOOD_RHETORIC_TOFEMALE_+2"   "#E[LV_LOVING]Nichts erfüllt mein Herz mit mehr Freude, als mit Euch mein Leben verbringen zu dürfen. Ja, ich heirate Euch."   |


	local label = "@L_FAMILY_1_MARRIAGE_ANSWER"
	
	if (Rhetoric < 4) then
		label = label.."_WEAK_RHETORIC"
	elseif (Rhetoric < 7) then
		label = label.."_NORMAL_RHETORIC"
	else
		if Rand(4) == 0 then
			label = label.."_NORMAL_RHETORIC"
		else
			label = label.."_GOOD_RHETORIC"
		end
	end
	
	if (Gender == GL_GENDER_MALE) then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
	end
	
	return label
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
-- SpeakPoem
-- -----------------------
function SpeakPoem(GenderDes, InLove)

	local label = "@L_GIVEAPOEM"
	
	if InLove then
		label = label.."_POETRY"
	else
		label = label.."_HOMAGE"
	end
	
	if GenderDes == GL_GENDER_FEMALE then
		label = label.."_TOFEMALE"
	else
		label = label.."_TOMALE"
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

