function Run()
	-- Get the court lover and call it "Destination" because the older version of the measure worked with a selection
	if not SimGetCourtLover("", "Destination") then
		return
	end
	
	local Title = GetNobilityTitle("")
	
	-- Get the court lover and call it "Destination" because the older version of the measure worked with a selection
	if not SimGetCourtLover("", "Destination") then
		return
	end
	
	if IsDynastySim("Destination") then
		if GetNobilityTitle("Destination") > Title then
			Title = GetNobilityTitle("Destination")
		end
	end
	
	local Cost = (Title * 2) * 300
	local InteractionDistance = 128
	
	FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "Weddingchapel")
	
	ms_077b_marrychapel_InviteGuests("Weddingchapel", "", "Destination")
		
	SetProperty("Weddingchapel", "Wedding", 1)
	BlockChar("Destination")
	SimSetBehavior("Destination", "")
		
	ms_077b_marrychapel_GotoChurch()
	
	if not HasProperty("", "WeddingPaid") then
		if not chr_SpendMoney("dynasty", Cost, "Wedding") then
			if not HasProperty("", "Tutorial") then
				MsgQuick("","@L_MEASURE_WEDDING_FAILURE_+1", GetID(""))
				LogMessage("Cost fail Marriage")
				StopMeasure()
			end
		end
		
		SetProperty("", "WeddingPaid", 1)
	end
	
		
	AlignTo("", "Destination")
	AlignTo("Destination", "")
			
	gameplayformulas_StartHighPriorMusic(MUSIC_MARRIAGE)
			
	BuildingFindSimByProperty("Weddingchapel", "BUILDING_NPC", 11, "Priest")			
	GetLocatorByName("Weddingchapel", "WeddingPriest", "PriestPos")
			
	f_MoveTo("Priest", "PriestPos")
	Sleep(5)
			
	SetAvoidanceGroup("", "Destination")

	AlignTo("", "Priest")
	AlignTo("Destination", "Priest")
	Sleep(20)

	if SimGetGender("") == GL_GENDER_MALE then
		AlignTo("Priest", "")
		Sleep(1)
		MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_HUSBAND_+0", GetID(""), GetID("Destination"))
		Sleep(1)
		MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_HUSBAND_+1", GetID(""), GetID("Destination"))
		MsgSay("", "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")
		AlignTo("Priest", "Destination")
		Sleep(1)
		MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_WIFE_+0", GetID("Destination"), GetID(""))
		MsgSay("Destination", "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")
		Sleep(1)

		-- kiss your wife good man...
		AlignTo("Priest", "")
		MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_FINALE_+0", GetID(""))
		AlignTo("", "Destination")
		AlignTo("Destination", "")
		Sleep(1)
				
		ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")
		ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")
			
		AnimLength = chr_MultiAnim("", "kiss_male", "Destination", "kiss_female", InteractionDistance, 1.0, true)
				
		Sleep(AnimLength * 0.5)
	else
		AlignTo("Priest", "Destination")
		Sleep(1)
		MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_HUSBAND_+0", GetID("Destination"), GetID(""))
		Sleep(1)
		MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_HUSBAND_+1", GetID("Destination"), GetID(""))
		MsgSay("Destination","_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")
		AlignTo("Priest", "")
		Sleep(1)
		MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_WIFE_+0", GetID("Destination"), GetID(""))
		MsgSay("", "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")
		Sleep(1)

		-- kiss your wife good man...
		AlignTo("Priest", "Destination")
		MsgSay("Priest","_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_FINALE_+0", GetID("Destination"))
		AlignTo("", "Destination")
		AlignTo("Destination", "")
		Sleep(1)
				
		ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")
		ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")
				
		AnimLength = chr_MultiAnim("Destination", "kiss_male", "", "kiss_female", InteractionDistance, 1.0, true)
		Sleep(AnimLength * 0.5)
	end
			
	ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")
	ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")
			
	if not HasProperty("Destination", "CourtDiff") then			
		CalculateCourtingDifficulty("", "Destination")
	end
			
	local Difficulty = GetProperty("Destination", "CourtDiff")
	xp_CourtingSuccess("Owner", Difficulty, 1)
	xp_CourtingSuccess("Destination", Difficulty, 1)
			
	Sleep(0.5)
	BuildingGetInsideSimList("Weddingchapel", "GuestList")
	local SimCnt = ListSize("GuestList")
	local GuestCount = 0
	local CheerCount = 0
	for i = 0, SimCnt-1 do
		ListGetElement("GuestList", i, "SimToCheck")
		if IsDynastySim("SimToCheck") and not GetState("SimToCheck", STATE_NPC) then
			if GetID("SimToCheck") ~= GetID("") and GetID("SimToCheck") ~= GetID("Destination") then
				chr_GainXP("SimToCheck", 150)
				ReleaseLocator("SimToCheck")
				if GetDynasty("SimToCheck", "CheckDyn") then
					if GetImpactValue("CheckDyn", "Ceremony") == 0 then
						AddImpact("CheckDyn", "Ceremony", 1, 6)
					end
				end
					
				ModifyFavorToSim("SimToCheck", "", 3)
				GuestCount = GuestCount + 1
					
				if CheerCount == 0 then
					
					CopyAlias("SimToCheck", "CommentSim")
					CheerCount = CheerCount + 1
				elseif CheerCount == 1 then
					if Rand(3) == 0 then
						CopyAlias("SimToCheck", "CheerSim1")
						CheerCount = CheerCount + 1
					end
				elseif CheerCount == 1 then
					if Rand(3) == 0 then
						CopyAlias("SimToCheck", "CheerSim2")
						CheerCount = CheerCount + 1
					end
				end
			end
		end
	end
			
	-- few sims might cheer
	if CheerCount > 1 then
		if Rand(2) == 0 then
			MsgSay("CheerSim1", "@L_PRIVILEGES_FLAMINGSPEECH_COMMENTS_+11")
		else
			MsgSay("CheerSim1", "@L_PRIVILEGES_FLAMINGSPEECH_COMMENTS_+0")
		end
		Sleep(0.2)
	end
		
	if CheerCount == 3 then
		if Rand(2) == 0 then
			MsgSay("CheerSim2", "@L_PRIVILEGES_FLAMINGSPEECH_COMMENTS_+7")
		else
			MsgSay("CheerSim2", "@L_CHURCH_091_PREPAREWORSHIP_WORSHIPPING_COMMENT_+1")
		end
	end
			
	Sleep(0.2)
			
	-- guest gives a comment
	if CheerCount > 0 then
		local TextLabel = "@L_FAMILY_1_MARRIAGE_COMMENT"
		
		if DynastyGetDiplomacyState("", "CommentSim") == DIP_FOE or GetFavorToDynasty("", "CommentSim") < 40 then -- enemy
			TextLabel = TextLabel.."_NEGATIVE"
		elseif SimGetAlignment("") >= 70 then -- bad guy
			TextLabel = TextLabel.."_NEGATIVE"
		elseif GetFavorToDynasty("", "CommentSim") <= 55 and DynastyGetDiplomacyState("", "CommentSim") < DIP_ALLIANCE then -- indifferent
			if Rand(2) == 0 then
				TextLabel = TextLabel.."_NEGATIVE"
			else
				TextLabel = TextLabel.."_POSITIVE"
			end
		else -- friend
			TextLabel = TextLabel.."_POSITIVE"
		end
			
		local RhetoricSkill = GetSkillValue("CommentSim", RHETORIC)
		if RhetoricSkill >= 7 then
			if Rand(4) == 0 then
				TextLabel = TextLabel.."_NORMAL_RHETORIC"
			else
				TextLabel = TextLabel.."_GOOD_RHETORIC"
			end
		elseif RhetoricSkill >= 4 then
			if Rand(4) == 0 then
				TextLabel = TextLabel.."_WEAK_RHETORIC"
			else
				TextLabel = TextLabel.."_NORMAL_RHETORIC"
			end
		else
			TextLabel = TextLabel.."_NORMAL_RHETORIC"
		end
				
		MsgSay("CommentSim", TextLabel)
		MsgNewsNoWait("", "CommentSim", "", "intrigue", -1, 
					"@L_MEASURE_MARRY_CEREMONY_HEAD_+0",
					TextLabel, GetID(""))
	end
			
	chr_SimAddFame("", GuestCount)
	MsgNewsNoWait("All", "", "", "politics", -1, 
				"@L_MEASURE_MARRY_CEREMONY_HEAD_+0",
				"@L_MEASURE_MARRY_CEREMONY_NEWS_BODY_+0",
				GetID(""), GetID("Destination"), GetID("Weddingchapel"), GuestCount)
			
	RemoveProperty("Destination", "CourtDiff")
	
	MeasureSetNotRestartable()
	PlaySound3D("Weddingchapel", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)
	RemoveProperty("Destination", "courted")
			
	if IsDynastySim("Destination") then
		DynastySetMinDiplomacyState("", "Destination", DIP_ALLIANCE, GetID(""), 24)
		DynastyForceCalcDiplomacy("")
		DynastyForceCalcDiplomacy("Destination")
	end
			
	AddImpact("", "LoveLevel", 10, 24) -- add some love for the next 24 hours
	AddImpact("Destination", "LoveLevel", 10, 24)
			
	if GetImpactValue("Destination", "LoveLevel") >= 10 then
		MsgNewsNoWait("", "Destination", "", "schedule", -1,
					"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
					"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
	end
			
	RemoveProperty("Destination", "Wedding")
	RemoveProperty("Weddingchapel", "Wedding")
	SimResetBehavior("Destination")
	RemoveProperty("", "WeddingPaid")
			
	SimMarry("", "Destination")	-- the destination is removed through this function
	PlaySound3D("Weddingchapel", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)
	StopMeasure()
end

function AIInitAnswer()
	
	local Timer = 0
	if GetImpactValue("GuestAlias", "OfficeTimer") > 0 then
		Timer = ImpactGetMaxTimeleft("GuestAlias", "OfficeTimer")
		if Timer <= 4 then
			return "C"
		end
	end
	
	if GetImpactValue("GuestAlias", "TrialTimer") > 0 then
		Timer = ImpactGetMaxTimeleft("GuestAlias", "TrialTimer")
		if Timer <= 4 then
			return "C"
		end
	end
	
	if GetImpactValue("GuestAlias", "DuelTimer") > 0 then
		Timer = ImpactGetMaxTimeleft("GuestAlias", "DuelTimer")
		if Timer <= 4 then
			return "C"
		end
	end
		
	if DynastyGetDiplomacyState("GuestAlias", "") < DIP_ALLIANCE or GetFavorToDynasty("", "GuestAlias") >= 60 or SimGetOfficeLevel("") > 0 then
		return "O"
	else
		if Rand(3) == 0 then
			return "O"
		else
			return "C"
		end
	end
end

function InviteGuests(Church, Sim1, Sim2)
	
	LogMessage("Start Invites")
	
	local InviterTitle = GetNobilityTitle(Sim1)
	if GetNobilityTitle(Sim2) > InviterTitle then
		InviterTitle = GetNobilityTitle(Sim2)
	end
	
	-- Dynasties will not get invited if the title is below theirs minus MinTitleSub
	local MinTitleSub = 2
	
	-- max family member invitations
	local MaxInvitePerFamily = 2
	
	-- invite guests
	if GetSettlement(Sim1, "MyCity") then
		local Guests = CityGetBuildings("MyCity", GL_BUILDING_CLASS_LIVINGROOM, -1, -1, -1, FILTER_HAS_DYNASTY, "Residence")
		LogMessage(Guests.." potencial guests found")
		local IncomingGuests = 0
		local SeatNumber = 29
		for i = 0, Guests-1 do
			if GetDynasty("Residence"..i, "GuestDyn") then
				if GetImpactValue("GuestDyn", "Ceremony") < 1 then
					local FamilyCount = DynastyGetFamilyMemberCount("GuestDyn")
					local FamilyGuests = 0
					-- invite family members who have time
					for u = 0, FamilyCount-1 do
						if DynastyGetFamilyMember("GuestDyn", u, "GuestAlias") then
							if GetID("GuestAlias") ~= GetID(Sim1) and GetID("GuestAlias") ~= GetID(Sim2) and GetID("GuestDyn") == GetDynastyID("GuestAlias") then
								local MinTitle = GetNobilityTitle("GuestAlias") - MinTitleSub
								if InviterTitle >= MinTitle and f_SimIsValid("GuestAlias") then
									if not GetState("GuestAlias", STATE_SICK) then
										if CanBeInterruptetBy("GuestAlias", Sim1, "Flirt") then
											LogMessage("Invitation started")
											local Invitation = MsgNews("GuestAlias", "", "@P"..
																	"@B[O, @L_THIEF_067_LETABDUCTEEOUT_ACTION_BTN_+0]"..
																	"@B[C, @L_THIEF_067_LETABDUCTEEOUT_ACTION_BTN_+1]", 
																	ms_077b_marrychapel_AIInitAnswer, "politics", 2, 
																	GetID(Sim1), GetID(Sim2), GetID(Church), GetID("GuestAlias"))
											if Invitation == "O" then	
												FamilyGuests = FamilyGuests + 1
												IncomingGuests = IncomingGuests + 1
												SetProperty("GuestAlias", "CeremonySeat", SeatNumber)
												SeatNumber = SeatNumber - 1
												LogMessage(GetName("GuestAlias").." kommt zur Hochzeit!")
												SendCommandNoWait("GuestAlias", "VisitCeremony")
											end
												
											if GetImpactValue("GuestDyn", "Ceremony") == 0 then
												AddImpact("GuestDyn", "Ceremony", 1, 0.2)
											end
										end
									end
								end
							end
						end
						if FamilyGuests == MaxInvitePerFamily then
							break
						end
					end
				end
			end
		end
	end		
end

function GotoChurch()

	f_MoveToNoWait("", "Weddingchapel", GL_MOVESPEED_WALK)
	f_MoveTo("Destination","Weddingchapel", GL_MOVESPEED_WALK)
	
	if not GetInsideBuilding("", "CheckInside") then
		if GetDistance("", "Weddingchapel") > 200 then
			SimBeamMeUp("", "Weddingchapel", false)
		end
	end
	
	if not GetInsideBuilding("Destination", "CheckInside") then
		if GetDistance("Destination", "Weddingchapel") > 200 then
			SimBeamMeUp("Destination", "Weddingchapel", false)
		end
	end
	 --f_FollowNoWait("", "Destination", GL_MOVESPEED_WALK, 250, true)		
	-------------------
	-- Go to the church
	-------------------
	
	--get the locators
	GetLocatorByName("Weddingchapel", "Front1", "MarryPos1") 
	GetLocatorByName("Weddingchapel", "Front2", "MarryPos2")

	--if another marriage is running
	while true do
		if LocatorStatus("Weddingchapel", "Front1", true) == 1 then
			break
		end
		Sleep(5)
	end

	--move the sims
	SendCommandNoWait("Destination", "GoToMarryPos")
	
	f_MoveTo("", "MarryPos1")
	f_BeginUseLocator("", "MarryPos1", GL_STANCE_STAND, true)

	--wait until both have arrived
	while not HasData("There") do
		Sleep(1)
	end
end

function GoToMarryPos()	
	f_MoveTo("", "MarryPos2")
	f_BeginUseLocator("", "MarryPos2", GL_STANCE_STAND, true) 
	
	SetData("There", 1)
	while true do
		Sleep(5)
	end
end

function VisitCeremony()
	f_MoveTo("", "Weddingchapel", GL_MOVESPEED_RUN)
	
	local MySeat = Rand(29) + 1
	if HasProperty("", "CeremonySeat") then
		MySeat = GetProperty("", "CeremonySeat")
		RemoveProperty("", "CeremonySeat")
	end
	
	LogMessage(GetName("").." ist eingetroffen, Sitz wählen")
	if GetFreeLocatorByName("Weddingchapel", "Sit", MySeat, MySeat, "SitPos") then
		LogMessage(GetName("").." hat seinen Sitz gefunden")
		f_MoveTo("", "SitPos", GL_MOVESPEED_WALK)
		f_BeginUseLocator("", "SitPos", GL_STANCE_SITBENCH)
	else
		GetFreeLocatorByName("Weddingchapel", "Sit", 8, 29, "SitPos")
		f_MoveTo("", "SitPos", GL_MOVESPEED_WALK)
		f_BeginUseLocator("", "SitPos", GL_STANCE_SITBENCH)
	end
	
	while true do
		Sleep(5)
		if not HasProperty("Weddingchapel", "Wedding") then
			break
		end
	end
	f_EndUseLocator("", "SitPos")
end

function CleanUp()
	ReleaseLocator("")
	ReleaseLocator("Destination")
	EndCutscene("")
	DestroyCutscene("cutscene")
	MoveSetActivity("")
	MoveSetActivity("Destination")
	ReleaseAvoidanceGroup("")
end