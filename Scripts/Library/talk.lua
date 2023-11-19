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
	
	local label = ""
	
	if Age < 16 then
		if Gender == GL_GENDER_MALE then
			label = "@L_STARTDIALOG_START_TOYOUNG_MALE"
		else
			label = "@L_STARTDIALOG_START_TOYOUNG_FEMALE"
		end
	else
		if IsLover then -- special label
			local Count = 1
			local Labels = {
						"@L_STARTDIALOG_START_TOADULT_LOVER_+0"
						}
						
			if Gender == GL_GENDER_MALE then
				local AddCount = 1
				local AddLabels = {
								"@L_FLIRT_SAYING1_GOOD_RHETORIC_TOMALE_+1"
								}
				for i = 1, AddCount do
					Count = Count + 1
					Labels[Count] = AddLabels[i]
				end
			else
				local AddCount = 1
				local AddLabels = {
								"@L_FLIRT_SAYING1_GOOD_RHETORIC_TOFEMALE_+1",
								}
				for i = 1, AddCount do
					Count = Count + 1
					Labels[Count] = AddLabels[i]
				end
			end
			
			Count = Rand(Count) + 1
			label = Labels[Count]
		else
			if Gender == GL_GENDER_MALE then
				local Count = 3
				local Labels = {
							"@L_FLIRT_SAYING1_NORMAL_RHETORIC_TOMALE",
							"@L_FLIRT_SAYING1_WEAK_RHETORIC_TOMALE",
							"@L_COURTLOVER_BEGIN_QUESTION_TOMALE_1ST_GOOD_RHETORIC_+1"
							}
				Count = Rand(Count) + 1
				label = Labels[Count]
			else
				local Count = 3
				local Labels = {
							"@L_FLIRT_SAYING1_NORMAL_RHETORIC_TOFEMALE",
							"@L_FLIRT_SAYING1_WEAK_RHETORIC_TOFEMALE",
							"@L_COURTLOVER_BEGIN_QUESTION_TOFEMALE_1ST_GOOD_RHETORIC_+1",
							}
				Count = Rand(Count) + 1
				label = Labels[Count]
			end
		end
	end
	
	return label
end

-- -----------------------
-- AnswerDialog
-- -----------------------
function AnswerDialog(IsLover, Age, Gender, Positive)
	
	local label = ""
	
	if Age < 16 then
		if Positive then
			local Count = 5
			local Labels = {
						"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_CHILD_+2",
						"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_CHILD_+3",
						"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_CHILD_+9",
						"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_CHILD_+0",
						"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_CHILD_+1"
						}
						
			Count = Rand(Count) + 1
			label = Labels[Count]
		else
			local Count = 5
			local Labels = {
						"@L_SIM_COMMENTS_OWN_DYNASTY_ORDER_CHILD_+0",
						"@L_SIM_COMMENTS_OWN_DYNASTY_ORDER_CHILD_+2",
						"@L_SIM_COMMENTS_OWN_DYNASTY_ORDER_CHILD_+4",
						"@L_SIM_COMMENTS_OWN_DYNASTY_ORDER_CHILD_+8",
						"@L_SIM_COMMENTS_OWN_DYNASTY_ORDER_CHILD_+9"
						}
			Count = Rand(Count) + 1
			label = Labels[Count]
		end
	else
		if Positive then
			if IsLover then -- special labels
				if Gender == GL_GENDER_MALE then
					local Count = 3
					local Labels = { 
								"@L_COURTLOVER_BEGIN_ANSWER_SUCCESS_MALE_GOOD_RHETORIC",
								"@L_COURTLOVER_BEGIN_ANSWER_SUCCESS_MALE_NORMAL_RHETORIC",
								"@L_FAMILY_2_COHABITATION_ANSWER_POSITIVE_GOOD_RHETORIC_+2"
								}
					
					Count = Rand(Count) + 1
					label = Labels[Count]
				else
					local Count = 3
					local Labels = {
								"@L_COURTLOVER_BEGIN_ANSWER_SUCCESS_FEMALE_WEAK_RHETORIC_+0",
								"@L_COURTLOVER_BEGIN_ANSWER_SUCCESS_FEMALE_NORMAL_RHETORIC_+1",
								"@L_FAMILY_2_COHABITATION_ANSWER_POSITIVE_GOOD_RHETORIC_+2"
								}
					Count = Rand(Count) + 1
					label = Labels[Count]
				end
			else
			
				local Count = 5
				local Labels = {
							"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_RANDOM_+8",
							"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_RANDOM_+11", 
							"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_RANDOM_+0",
							"@L_SIM_COMMENTS_WORKER_CLICK_ARTISAN_+5",
							"@L_SIM_COMMENTS_WORKER_CLICK_PATRON_+7"
							}
				Count = Rand(Count) + 1
				label = Labels[Count]
			end
		else
			local Count = 3
			local Labels = {
						"@L_SIM_COMMENTS_WORKER_ORDER_PATRON_BAD_FAVOR_+3",
						"@L_SIM_COMMENTS_WORKER_ORDER_FIGHTER_BAD_FAVOR_+6",
						"@L_SIM_COMMENTS_WORKER_ORDER_MYRMIDON_BAD_FAVOR_+2",
						}
			
			if Gender == GL_GENDER_MALE then
				local AddCount = 3
				local AddLabel = { 
								"@L_SOCIAL_ANSWER_TALK_NORMAL_RHETORIC_WAY_TOO_PROFOUND_+1",
								"@L_SOCIAL_ANSWER_DANCE_NORMAL_RHETORIC_PROFOUND_+1",
								"@L_SOCIAL_ANSWER_TALK_WEAK_RHETORIC_WAY_TOO_PROFOUND_+1"
								}
				
				for i = 1, AddCount do
					Count = Count +1
					Labels[Count] = AddLabel[i]
				end
			else
				local AddCount = 3
				local AddLabel = {
								"@L_SOCIAL_ANSWER_TALK_NORMAL_RHETORIC_WAY_TOO_PROFOUND_+0",
								"@L_SOCIAL_ANSWER_DANCE_NORMAL_RHETORIC_PROFOUND_+0",
								"@L_SOCIAL_ANSWER_TALK_WEAK_RHETORIC_WAY_TOO_PROFOUND_+0"
								}
								
				for i = 1, AddCount do
					Count = Count +1
					Labels[Count] = AddLabel[i]
				end
			end
			
			Count = Rand(Count) + 1
			label = Labels[Count]
		end
	end
	
	return label
end

-- -----------------------
-- FavorDialog
-- -----------------------
function FavorDialog(Age, Gender, Positive)
	
	local label = ""
	
	if Age < 16 then
		if Positive then
			local Count = 4
			local Labels = {
						"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_CHILD_+4",
						"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_CHILD_+5",
						"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_CHILD_+6",
						"@L_SIM_COMMENTS_OWN_DYNASTY_CLICK_CHILD_+8"
						}
			Count = Rand(Count) + 1
			label = Labels[Count]
		else
			local Count = 3
			local Labels = {
						"@L_SIM_COMMENTS_OWN_DYNASTY_ORDER_CHILD_+3",
						"@L_SIM_COMMENTS_OWN_DYNASTY_ORDER_CHILD_+5",
						"@L_SIM_COMMENTS_OWN_DYNASTY_ORDER_CHILD_+6"
						}
			Count = Rand(Count) + 1
			label = Labels[Count]
		end
	else
		if Positive then
			if Gender == GL_GENDER_MALE then
				local Count = 4
				local Labels = {
							"@L_SOCIAL_ANSWER_BEWITCH_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+1",
							"@L_SOCIAL_ANSWER_BEWITCH_GOOD_RHETORIC_WELL_RECEIVED_+1",
							"@L_SOCIAL_ANSWER_TALK_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+1",
							"@L_SOCIAL_ANSWER_TALK_WEAK_RHETORIC_VERY_WELL_RECEIVED_+1"
							}
				Count = Rand(Count) + 1
				label = Labels[Count]
			else
				local Count = 4
				local Labels = {
							"@L_SOCIAL_ANSWER_BEWITCH_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+0",
							"@L_SOCIAL_ANSWER_BEWITCH_GOOD_RHETORIC_WELL_RECEIVED_+0",
							"@L_SOCIAL_ANSWER_TALK_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+0",
							"@L_SOCIAL_ANSWER_TALK_WEAK_RHETORIC_VERY_WELL_RECEIVED_+0"
							}
				Count = Rand(Count) + 1
				label = Labels[Count]
			end
		else
			if Gender == GL_GENDER_MALE then
				local Count = 5
				local Labels = {
							"@L_SOCIAL_ANSWER_BEWITCH_NORMAL_RHETORIC_OFFENSIVE_+1",
							"@L_SOCIAL_ANSWER_TALK_WEAK_RHETORIC_PROFOUND_+1",
							"@L_SOCIAL_ANSWER_COMPLIMENT_NORMAL_RHETORIC_PROFOUND_+1",
							"@L_SOCIAL_ANSWER_BEWITCH_WEAK_RHETORIC_OFFENSIVE_+1",
							"@L_SOCIAL_ANSWER_BEWITCH_NORMAL_RHETORIC_OFFENSIVE_+1"
							}
				Count = Rand(Count) + 1
				label = Labels[Count]
			else
				local Count = 5
				local Labels = {
							"@L_SOCIAL_ANSWER_BEWITCH_NORMAL_RHETORIC_OFFENSIVE_+0",
							"@L_SOCIAL_ANSWER_TALK_WEAK_RHETORIC_PROFOUND_+0",
							"@L_SOCIAL_ANSWER_COMPLIMENT_NORMAL_RHETORIC_PROFOUND_+0",
							"@L_SOCIAL_ANSWER_BEWITCH_WEAK_RHETORIC_OFFENSIVE_+0",
							"@L_SOCIAL_ANSWER_BEWITCH_NORMAL_RHETORIC_OFFENSIVE_+0"
							}
				Count = Rand(Count) + 1
				label = Labels[Count]
			end
		end
	end
	
	return label
end

-- -----------------------
-- StartCompliment / Flirt
-- -----------------------
function StartCompliment(IsLover, Rhetoric, Gender)
	
	local label = "@L_FLIRT_SAYING1_"
	
	if Rhetoric > 4 then
		if Rand(3) == 0 then
			label = label.."NORMAL_RHETORIC"
		else
			label = label.."GOOD_RHETORIC"
		end
	else
		if Rand(3) == 0 then
			label = label.."NORMAL_RHETORIC"
		else
			label = label.."WEAK_RHETORIC"
		end
	end
	
	if Gender == GL_GENDER_MALE then
		if IsLover then -- special label (informal choice)
			if Rhetoric > 4 then
				if Rand(2) == 0 then
					label = "@L_FLIRT_SAYING1_GOOD_RHETORIC_TOMALE_+0"
				else
					label = "@L_FLIRT_SAYING1_GOOD_RHETORIC_TOMALE_+1"
				end
			else
				if Rand(2) == 0 then
					label = "@L_FLIRT_SAYING1_WEAK_RHETORIC_TOMALE_+2"
				else
					label = "@L_FLIRT_SAYING1_NORMAL_RHETORIC_TOMALE_+0"
				end
			end
		else
			label = label.."_TOMALE"
		end
	else
		if IsLover then -- special label (informal choice)
			if Rhetoric > 4 then
				if Rand(2) == 0 then
					label = "@L_FLIRT_SAYING1_GOOD_RHETORIC_TOFEMALE_+0"
				else
					label = "@L_FLIRT_SAYING1_GOOD_RHETORIC_TOFEMALE_+1"
				end
			else
				if Rand(2) == 0 then
					label = "@L_FLIRT_SAYING1_WEAK_RHETORIC_TOFEMALE_+2"
				else
					label = "@L_FLIRT_SAYING1_NORMAL_RHETORIC_TOFEMALE_+0"
				end
			end
		else
			label = label.."_TOFEMALE"
		end
	end
	
	return label
end

-- -----------------------
-- AnswerCompliment / Flirt
-- -----------------------
function AnswerCompliment(IsLover, Rhetoric, Gender, IsPositive)
	
	local label = "@L_FLIRT_ANSWER_"
	
	if IsPositive then
		if IsLover then -- special label
			if Gender == GL_GENDER_MALE then
				local Choice = Rand(5) + 1
				local Labels = { "@L_FAMILY_2_COHABITATION_ANSWER_POSITIVE_NORMAL_RHETORIC_+0",
							"@L_FAMILY_2_COHABITATION_ANSWER_POSITIVE_GOOD_RHETORIC_+2",
							"@L_FLIRT_ANSWER_GOOD_RHETORIC_TOMALE_+1",
							"@L_FLIRT_ANSWER_GOOD_RHETORIC_TOMALE_+2",
							"@L_FLIRT_ANSWER_NORMAL_RHETORIC_TOMALE_+0" }
				label = Labels[Choice]
			else
				local Choice = Rand(5) + 1
				local Labels = { "@L_FAMILY_2_COHABITATION_ANSWER_POSITIVE_NORMAL_RHETORIC_+0",
							"@L_FAMILY_2_COHABITATION_ANSWER_POSITIVE_GOOD_RHETORIC_+2",
							"@L_FLIRT_ANSWER_GOOD_RHETORIC_TOFEMALE_+1",
							"@L_FLIRT_ANSWER_GOOD_RHETORIC_TOFEMALE_+2",
							"@L_FLIRT_ANSWER_NORMAL_RHETORIC_TOMFEALE_+0" }
				label = Labels[Choice]
			end
		else
			if Rhetoric > 4 then
				if Rand(3) == 0 then
					label = label.."NORMAL_RHETORIC"
				else
					label = label.."GOOD_RHETORIC"
				end
			else
				if Rand(3) == 0 then
					label = label.."NORMAL_RHETORIC"
				else
					label = label.."WEAK_RHETORIC"
				end
			end
			
			if Gender == GL_GENDER_MALE then
				label = label.."_TOMALE"
			else
				label = label.."_TOFEMALE"
			end
		end
	else
		if IsLover then -- special label
			if Rand(2) == 0 then
				label = "@L_FAMILY_2_COHABITATION_ANSWER_NEGATIVE_NORMAL_RHETORIC_+1"
			else
				label = "@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_WEAK_RHETORIC"
			end
		else
			if Gender == GL_GENDER_MALE then
				local Choice = 7
				local Labels = { "@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_WEAK_RHETORIC_+0",
							"@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_WEAK_RHETORIC_+2",
							"@L_SOCIAL_ANSWER_TALK_NORMAL_RHETORIC_WAY_TOO_PROFOUND_+1",
							"@L_COURTLOVER_BEGIN_ANSWER_FAILED_MALE_WEAK_RHETORIC_+0",
							"@L_COURTLOVER_BEGIN_ANSWER_FAILED_MALE_NORMAL_RHETORIC_+1",
							"@L_COURTLOVER_BEGIN_ANSWER_FAILED_MALE_GOOD_RHETORIC_+1",
							"@L_ATTENDTRIAL_ACCUSER_TEXT1_ANSWER_+2"
								}
				if Rhetoric > 4 then
					Choice = Choice + 1
					Labels[Choice] = "@L_SOCIAL_ANSWER_TALK_GOOD_RHETORIC_WAY_TOO_PROFOUND_+1"
				else
					Choice = Choice + 1
					Labels[Choice] = "_SOCIAL_ANSWER_TALK_WEAK_RHETORIC_WAY_TOO_PROFOUND_+1"
				end
				
				Choice = Rand(Choice) + 1
				label = Labels[Choice]
			else
				local Choice = 7
				local Labels = { "@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_WEAK_RHETORIC_+0",
							"@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_WEAK_RHETORIC_+2",
							"@L_SOCIAL_ANSWER_TALK_NORMAL_RHETORIC_WAY_TOO_PROFOUND_+0",
							"@L_COURTLOVER_BEGIN_ANSWER_FAILED_FEMALE_WEAK_RHETORIC_+0",
							"@L_COURTLOVER_BEGIN_ANSWER_FAILED_FEMALE_GOOD_RHETORIC_+0",
							"@L_COURTLOVER_BEGIN_ANSWER_FAILED_FEMALE_GOOD_RHETORIC_+1",
							"@L_ATTENDTRIAL_ACCUSER_TEXT1_ANSWER_+2"
								}
				if Rhetoric > 4 then
					Choice = Choice + 1
					Labels[Choice] = "@L_SOCIAL_ANSWER_TALK_GOOD_RHETORIC_WAY_TOO_PROFOUND_+0"
				else
					Choice = Choice + 1
					Labels[Choice] = "_SOCIAL_ANSWER_TALK_WEAK_RHETORIC_WAY_TOO_PROFOUND_+0"
				end
				
				Choice = Rand(Choice) + 1
				label = Labels[Choice]
			end
		end
	end
	
	return label
end

-- -----------------------
-- CommitCompliment / Flirt
-- -----------------------
function CommitCompliment(Rhetoric, Gender, Type)
	
	local label = ""
	if Type == "FLIRT" then
		label = "@L_FLIRT_SAYING2_"
	else
		label = "@L_COMPLIMENT_"
	end
	
	if Rhetoric > 4 then
		if Rand(3) == 0 then
			label = label.."NORMAL_RHETORIC"
		else
			label = label.."GOOD_RHETORIC"
		end
	else
		if Rand(3) == 0 then
			label = label.."NORMAL_RHETORIC"
		else
			label = label.."WEAK_RHETORIC"
		end
	end
	
	if Gender == GL_GENDER_MALE then
		label = label.."_TOMALE"
	else
		label = label.."_TOFEMALE"
	end
	
	return label
end

-- -----------------------
-- FavorCompliment / Flirt
-- -----------------------
function FavorCompliment(Rhetoric, Gender, IsPositive)
	
	local label = ""
	
	if IsPositive then
		
		local Count = 1
		local Labels = {
					"@L_INTRIGUE_041_BRIBECHARACTER_SPEAK_SUCCESS_+0"
					}
		if Gender == GL_GENDER_MALE then
			--male
			local AddCount = 5
			local AddLabels = {
						"@L_SOCIAL_ANSWER_COMPLIMENT_WEAK_RHETORIC_WELL_RECEIVED_+1",
						"@L_SOCIAL_ANSWER_COMPLIMENT_WEAK_RHETORIC_VERY_WELL_RECEIVED_+1",
						"@L_SOCIAL_ANSWER_COMPLIMENT_GOOD_RHETORIC_WELL_RECEIVED_+1",
						"@L_SOCIAL_ANSWER_COMPLIMENT_NORMAL_RHETORIC_WELL_RECEIVED_+1",
						"@L_SOCIAL_ANSWER_COMPLIMENT_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+1"
						}
			-- rhetoric based
			if Rhetoric > 4 then
				local RhetLabels = { 
								"@L_SOCIAL_ANSWER_HUG_GOOD_RHETORIC_WELL_RECEIVED_+1",
								"@L_SOCIAL_ANSWER_COMPLIMENT_GOOD_RHETORIC_VERY_WELL_RECEIVED_+1"
								}
				for i=1, 2 do
					AddCount = AddCount + 1
					AddLabels[AddCount] = RhetLabels[i]
				end
			else
				local RhetLabels = { 
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_MALE_WEAK_RHETORIC_+1",
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_MALE_WEAK_RHETORIC_+0"
								}
				for i=1, 2 do
					AddCount = AddCount + 1
					AddLabels[AddCount] = RhetLabels[i]
				end
			end
			
			for i=1, AddCount do
				Count = Count + 1
				Labels[Count] = AddLabels[i]
			end
		else
			--female
			local AddCount = 5
			local AddLabels = { 
						"@L_SOCIAL_ANSWER_COMPLIMENT_WEAK_RHETORIC_WELL_RECEIVED_+0",
						"@L_SOCIAL_ANSWER_COMPLIMENT_WEAK_RHETORIC_VERY_WELL_RECEIVED_+0",
						"@L_SOCIAL_ANSWER_COMPLIMENT_GOOD_RHETORIC_WELL_RECEIVED_+0",
						"@L_SOCIAL_ANSWER_COMPLIMENT_NORMAL_RHETORIC_WELL_RECEIVED_+0",
						"@L_SOCIAL_ANSWER_COMPLIMENT_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+0"  
						}
			-- rhetoric based
			if Rhetoric > 4 then
				local RhetLabels = { 
								"@L_SOCIAL_ANSWER_HUG_GOOD_RHETORIC_WELL_RECEIVED_+0",
								"@L_SOCIAL_ANSWER_COMPLIMENT_GOOD_RHETORIC_VERY_WELL_RECEIVED_+0"
								}
				for i=1, 2 do
					AddCount = AddCount + 1
					AddLabels[AddCount] = RhetLabels[i]
				end
			else
				local RhetLabels = { 
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_FEMALE_WEAK_RHETORIC_+1",
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_FEMALE_WEAK_RHETORIC_+0"
								}
				for i=1, 2 do
					AddCount = AddCount + 1
					AddLabels[AddCount] = RhetLabels[i]
				end
			end
			
			for i=1, AddCount do
				Count = Count + 1
				Labels[Count] = AddLabels[i]
			end
		end
		
		Count = Rand(Count) + 1
		label = Labels[Count]
	else
		local Count = 3
		local Labels = {
					"@L_INTRIGUE_041_BRIBECHARACTER_SPEAK_FAILED",
					"@L_PROCLAMATION_NEGATIVE_+2",
					"@L_PROCLAMATION_NEGATIVE_+3"
					}
		if Gender == GL_GENDER_MALE then
			--male
			local AddCount = 6
			local AddLabels = {
						"@L_SOCIAL_ANSWER_HUG_WEAK_RHETORIC_OFFENSIVE_+1",
						"@L_SOCIAL_ANSWER_HUG_NORMAL_RHETORIC_WAY_TOO_OFFENSIVE_+1",
						"@L_SOCIAL_ANSWER_BEWITCH_WEAK_RHETORIC_WAY_TOO_OFFENSIVE_+1",
						"@L_SOCIAL_ANSWER_COMPLIMENT_WEAK_RHETORIC_WAY_TOO_PROFOUND_+1",
						"@L_SOCIAL_ANSWER_COMPLIMENT_NORMAL_RHETORIC_WAY_TOO_PROFOUND_+1",
						"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_MALE_NORMAL_RHETORIC_+0"
						}
			-- rhetoric based
			if Rhetoric > 4 then
				local RhetLabels = { 
								"@L_SOCIAL_ANSWER_COMPLIMENT_GOOD_RHETORIC_PROFOUND_+1",
								"@L_SOCIAL_ANSWER_COMPLIMENT_NORMAL_RHETORIC_PROFOUND_+1",
								"@L_SOCIAL_ANSWER_COMPLIMENT_GOOD_RHETORIC_WAY_TOO_PROFOUND_+1",
								"@L_SOCIAL_ANSWER_BEWITCH_NORMAL_RHETORIC_WAY_TOO_OFFENSIVE_+1",
								"@L_SOCIAL_ANSWER_BEWITCH_GOOD_RHETORIC_WAY_TOO_OFFENSIVE_+1",
								"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_MALE_GOOD_RHETORIC_+0"
								}
				for i=1, 6 do
					AddCount = AddCount + 1
					AddLabels[AddCount] = RhetLabels[i]
				end
			else
				local RhetLabels = { 
								"@L_SIM_COMMENTS_WORKER_ORDER_FIGHTER_BAD_FAVOR_+7",
								"@L_SIM_COMMENTS_WORKER_ORDER_PATRON_BAD_FAVOR_+4",
								"@L_SIM_COMMENTS_WORKER_CLICK_EASTEREGG_+4"
								}
				for i=1, 3 do
					AddCount = AddCount + 1
					AddLabels[AddCount] = RhetLabels[i]
				end
			end
			
			for i=1, AddCount do
				Count = Count + 1
				Labels[Count] = AddLabels[i]
			end
		else
			--female
			local AddCount = 6
			local AddLabels = { 
						"@L_SOCIAL_ANSWER_HUG_WEAK_RHETORIC_OFFENSIVE_+0",
						"@L_SOCIAL_ANSWER_HUG_NORMAL_RHETORIC_WAY_TOO_OFFENSIVE_+0",
						"@L_SOCIAL_ANSWER_BEWITCH_WEAK_RHETORIC_WAY_TOO_OFFENSIVE_+0",
						"@L_SOCIAL_ANSWER_COMPLIMENT_WEAK_RHETORIC_WAY_TOO_PROFOUND_+0",
						"@L_SOCIAL_ANSWER_COMPLIMENT_NORMAL_RHETORIC_WAY_TOO_PROFOUND_+0",
						"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_FEMALE_NORMAL_RHETORIC_+0"  
						}
			-- rhetoric based
			if Rhetoric > 4 then
				local RhetLabels = { 
								"@L_SOCIAL_ANSWER_COMPLIMENT_GOOD_RHETORIC_PROFOUND_+0",
								"@L_SOCIAL_ANSWER_COMPLIMENT_NORMAL_RHETORIC_PROFOUND_+0" ,
								"@L_SOCIAL_ANSWER_COMPLIMENT_GOOD_RHETORIC_WAY_TOO_PROFOUND_+0",
								"@L_SOCIAL_ANSWER_BEWITCH_NORMAL_RHETORIC_WAY_TOO_OFFENSIVE_+0",
								"@L_SOCIAL_ANSWER_BEWITCH_GOOD_RHETORIC_WAY_TOO_OFFENSIVE_+0",
								"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_FEMALE_GOOD_RHETORIC_+0"
								}
				for i=1, 6 do
					AddCount = AddCount + 1
					AddLabels[AddCount] = RhetLabels[i]
				end
			else
				local RhetLabels = { 
								"@L_SIM_COMMENTS_WORKER_ORDER_FIGHTER_BAD_FAVOR_+7",
								"@L_SIM_COMMENTS_WORKER_ORDER_PATRON_BAD_FAVOR_+4",
								"@L_SIM_COMMENTS_WORKER_CLICK_EASTEREGG_+4"
								}
				for i=1, 3 do
					AddCount = AddCount + 1
					AddLabels[AddCount] = RhetLabels[i]
				end
			end
			
			for i=1, AddCount do
				Count = Count + 1
				Labels[Count] = AddLabels[i]
			end
		end
		Count = Rand(Count) + 1
		label = Labels[Count]
	end
	
	return label
end

------------------------
-- Reject Kiss / Hug
-- -----------------------
function RejectKiss(OwnerGender, DestGender, IsKiss)
	local label = ""
	if OwnerGender == GL_GENDER_MALE then
		local Count = 9
		local Labels = {
					"@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_NORMAL_RHETORIC",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_MALE_GOOD_RHETORIC_+0",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_MALE_NORMAL_RHETORIC_+0",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_MALE_NORMAL_RHETORIC_+1",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_MALE_WEAK_RHETORIC_+0",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_MALE_WEAK_RHETORIC_+1",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_MALE_GOOD_RHETORIC_+1",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_MALE_WEAK_RHETORIC_+0",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_MALE_NORMAL_RHETORIC_+0"
					}
					
		if DestGender == GL_GENDER_FEMALE then
			local AddCount = 6
			local AddLabel = {
							"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_MALE_GOOD_RHETORIC_+1",
							"@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_GOOD_RHETORIC_+0",
							"@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_GOOD_RHETORIC_+2",
							"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_MALE_GOOD_RHETORIC_+0",
							"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_MALE_WEAK_RHETORIC_+1",
							"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_MALE_NORMAL_RHETORIC_+1"
							}
			if IsKiss then
				local KissCount = 2
				local KissLabel = {
							"@L_SOCIAL_ANSWER_KISS_NORMAL_RHETORIC_WAY_TOO_OFFENSIVE_+1",
							"@L_SOCIAL_ANSWER_KISS_GOOD_RHETORIC_WAY_TOO_OFFENSIVE_+1"
							}
				for i=1, KissCount do
					AddCount = AddCount + 1
					AddLabel[AddCount] = KissLabel[i]
				end
			end
			
			for i=1, AddCount do
				Count = Count + 1
				Labels[Count] = AddLabel[i]
			end
		end
		
		Count = Rand(Count) + 1
		label = Labels[Count]
	else
		local Count = 9
		local Labels = {
					"@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_NORMAL_RHETORIC",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_FEMALE_GOOD_RHETORIC_+0",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_FEMALE_NORMAL_RHETORIC_+0",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_FEMALE_NORMAL_RHETORIC_+1",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_FEMALE_WEAK_RHETORIC_+0",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_FEMALE_WEAK_RHETORIC_+1",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_FEMALE_GOOD_RHETORIC_+1",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_FEMALE_WEAK_RHETORIC_+0",
					"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_FEMALE_NORMAL_RHETORIC_+0"
					}
					
		if DestGender == GL_GENDER_MALE then
			local AddCount = 6
			local AddLabel = {
						"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_SLAP_FEMALE_GOOD_RHETORIC_+1",
						"@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_GOOD_RHETORIC_+0",
						"@L_FAMILY_2_COHABITATION_ANSWER_OUTRAGED_GOOD_RHETORIC_+2",
						"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_FEMALE_GOOD_RHETORIC_+0",
						"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_FEMALE_WEAK_RHETORIC_+1",
						"@L_SOCIAL_ANSWER_FAILED_BEFORE_START_OUTRAGED_FEMALE_NORMAL_RHETORIC_+1"
						}
			
			if IsKiss then
				local KissCount = 2
				local KissLabel = {
							"@L_SOCIAL_ANSWER_KISS_NORMAL_RHETORIC_WAY_TOO_OFFENSIVE_+0",
							"@L_SOCIAL_ANSWER_KISS_GOOD_RHETORIC_WAY_TOO_OFFENSIVE_+0"
							}
				for i=1, KissCount do
					AddCount = AddCount + 1
					AddLabel[AddCount] = KissLabel[i]
				end
			end
			
			for i=1, AddCount do
				Count = Count + 1
				Labels[Count] = AddLabel[i]
			end
		
			Count = Rand(Count) + 1
			label = Labels[Count]
		end
	end
	
	return label
end

------------------------
-- Favor Kiss / Hug
-- -----------------------
function FavorKiss(Gender, IsPositive, IsKiss, IsLover)
	
	local label = ""
	
	if IsPositive then
		if Gender == GL_GENDER_MALE then
			if IsLover then
				label = "@L_LIAISON_ANSWER_GOOD_RHETORIC_TOFEMALE_+0"
			else
				if IsKiss then
					local Count = 7
					local Labels = {
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_MALE_NORMAL_RHETORIC_+1",
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_MALE_GOOD_RHETORIC_+0",
								"@L_SOCIAL_ANSWER_KISS_GOOD_RHETORIC_WELL_RECEIVED_+1",
								"@L_SOCIAL_ANSWER_KISS_GOOD_RHETORIC_VERY_WELL_RECEIVED_+1",
								"@L_SOCIAL_ANSWER_KISS_WEAK_RHETORIC_VERY_WELL_RECEIVED_+1",
								"@L_SOCIAL_ANSWER_KISS_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+1",
								"@L_SOCIAL_ANSWER_KISS_NORMAL_RHETORIC_WELL_RECEIVED_+1"
								}
					Count = Rand(Count) + 1
					label = Labels[Count]
				else
					local Count = 10
					local Labels = {
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_MALE_WEAK_RHETORIC",
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_MALE_NORMAL_RHETORIC_+0",
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_MALE_GOOD_RHETORIC_+1",
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_MALE_WEAK_RHETORIC_+0",
								"@L_SOCIAL_ANSWER_HUG_WEAK_RHETORIC_WELL_RECEIVED_+1",
								"@L_SOCIAL_ANSWER_HUG_WEAK_RHETORIC_VERY_WELL_RECEIVED_+1",
								"@L_SOCIAL_ANSWER_HUG_NORMAL_RHETORIC_WELL_RECEIVED_+1",
								"@L_SOCIAL_ANSWER_HUG_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+1",
								"@L_SOCIAL_ANSWER_HUG_GOOD_RHETORIC_WELL_RECEIVED_+1",
								"@L_SOCIAL_ANSWER_HUG_GOOD_RHETORIC_VERY_WELL_RECEIVED_+1"
								}
				
					Count = Rand(Count) + 1
					label = Labels[Count]
				end
			end
		else
		
			if IsLover then
				label = "@L_LIAISON_ANSWER_GOOD_RHETORIC_TOMALE_+0"
			else
				if IsKiss then
					local Count = 7
					local Labels = {
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_FEMALE_NORMAL_RHETORIC_+1",
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_FEMALE_GOOD_RHETORIC_+0",
								"@L_SOCIAL_ANSWER_KISS_GOOD_RHETORIC_WELL_RECEIVED_+0",
								"@L_SOCIAL_ANSWER_KISS_GOOD_RHETORIC_VERY_WELL_RECEIVED_+0",
								"@L_SOCIAL_ANSWER_KISS_WEAK_RHETORIC_VERY_WELL_RECEIVED_+0",
								"@L_SOCIAL_ANSWER_KISS_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+0",
								"@L_SOCIAL_ANSWER_KISS_NORMAL_RHETORIC_WELL_RECEIVED_+0"
								}
					Count = Rand(Count) + 1
					label = Labels[Count]
				else
					local Count = 10
					local Labels = {
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_FEMALE_WEAK_RHETORIC",
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_FEMALE_NORMAL_RHETORIC_+0",
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_FEMALE_GOOD_RHETORIC_+1",
								"@L_SOCIAL_ANSWER_SUCCEEDED_KISS_FEMALE_WEAK_RHETORIC_+0",
								"@L_SOCIAL_ANSWER_HUG_WEAK_RHETORIC_WELL_RECEIVED_+0",
								"@L_SOCIAL_ANSWER_HUG_WEAK_RHETORIC_VERY_WELL_RECEIVED_+0",
								"@L_SOCIAL_ANSWER_HUG_NORMAL_RHETORIC_WELL_RECEIVED_+0",
								"@L_SOCIAL_ANSWER_HUG_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+0",
								"@L_SOCIAL_ANSWER_HUG_GOOD_RHETORIC_WELL_RECEIVED_+0",
								"@L_SOCIAL_ANSWER_HUG_GOOD_RHETORIC_VERY_WELL_RECEIVED_+0"
								}
				
					Count = Rand(Count) + 1
					label = Labels[Count]
				end
			end
		end
	else
		if Gender == GL_GENDER_MALE then
			if IsKiss then
				local Count = 6
				local Labels = {
							"@L_SOCIAL_ANSWER_KISS_WEAK_RHETORIC_OFFENSIVE_+1",
							"@L_SOCIAL_ANSWER_KISS_WEAK_RHETORIC_WAY_TOO_OFFENSIVE_+1",
							"@L_SOCIAL_ANSWER_KISS_NORMAL_RHETORIC_OFFENSIVE_+1",
							"@L_SOCIAL_ANSWER_KISS_NORMAL_RHETORIC_WAY_TOO_OFFENSIVE_+1",
							"@L_SOCIAL_ANSWER_KISS_GOOD_RHETORIC_OFFENSIVE_+1",
							"@L_SOCIAL_ANSWER_KISS_GOOD_RHETORIC_WAY_TOO_OFFENSIVE_+1"
							}
					
				Count = Rand(Count) + 1
				label = Labels[Count]
			else
				local Count = 6
				local Labels = {
							"@L_SOCIAL_ANSWER_HUG_WEAK_RHETORIC_WELL_RECEIVED_+1",
							"@L_SOCIAL_ANSWER_HUG_WEAK_RHETORIC_VERY_WELL_RECEIVED_+1",
							"@L_SOCIAL_ANSWER_HUG_NORMAL_RHETORIC_WELL_RECEIVED_+1",
							"@L_SOCIAL_ANSWER_HUG_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+1",
							"@L_SOCIAL_ANSWER_HUG_GOOD_RHETORIC_WELL_RECEIVED_+1",
							"@L_SOCIAL_ANSWER_HUG_GOOD_RHETORIC_VERY_WELL_RECEIVED_+1"
							}
					
				Count = Rand(Count) + 1
				label = Labels[Count]
			end
		else
			if IsKiss then
				local Count = 6
				local Labels = {
							"@L_SOCIAL_ANSWER_KISS_WEAK_RHETORIC_OFFENSIVE_+0",
							"@L_SOCIAL_ANSWER_KISS_WEAK_RHETORIC_WAY_TOO_OFFENSIVE_+0",
							"@L_SOCIAL_ANSWER_KISS_NORMAL_RHETORIC_OFFENSIVE_+0",
							"@L_SOCIAL_ANSWER_KISS_NORMAL_RHETORIC_WAY_TOO_OFFENSIVE_+0",
							"@L_SOCIAL_ANSWER_KISS_GOOD_RHETORIC_OFFENSIVE_+0",
							"@L_SOCIAL_ANSWER_KISS_GOOD_RHETORIC_WAY_TOO_OFFENSIVE_+0"
							}
					
				Count = Rand(Count) + 1
				label = Labels[Count]
			else
				local Count = 6
				local Labels = {
							"@L_SOCIAL_ANSWER_HUG_WEAK_RHETORIC_WELL_RECEIVED_+0",
							"@L_SOCIAL_ANSWER_HUG_WEAK_RHETORIC_VERY_WELL_RECEIVED_+0",
							"@L_SOCIAL_ANSWER_HUG_NORMAL_RHETORIC_WELL_RECEIVED_+0",
							"@L_SOCIAL_ANSWER_HUG_NORMAL_RHETORIC_VERY_WELL_RECEIVED_+0",
							"@L_SOCIAL_ANSWER_HUG_GOOD_RHETORIC_WELL_RECEIVED_+0",
							"@L_SOCIAL_ANSWER_HUG_GOOD_RHETORIC_VERY_WELL_RECEIVED_+0"
							}
					
				Count = Rand(Count) + 1
				label = Labels[Count]
			end
		end
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

