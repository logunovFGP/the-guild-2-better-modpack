function Run()
	local RatBoyFilter = "__F( (Object.GetObjectsByRadius(Sim)==3200)AND(Object.HasProperty(ImYourDestiny)))"
	local NumRatBoys = Find("", RatBoyFilter, "RatBoy", -1)
	if NumRatBoys>0 then
		f_FollowNoWait("", "RatBoy", GL_MOVESPEED_RUN,Rand(200)+200, false, false)
	end

	MsgMeasure("", "@L_RATBOY_MSGMEASURE_+0")
	
	while HasProperty("RatBoy", "ImYourDestiny") do
		if HasProperty("RatBoy", "LetsGo") then
			if not GetOutdoorLocator("MapExit1", 1, "MapExit") then
				if not GetOutdoorLocator("MapExit2", 1, "MapExit") then
				    if not GetOutdoorLocator("MapExit3", 1, "MapExit") then
						break
					end
				end
			end
			
			MsgMeasure("", "@L_RATBOY_MSGMEASURE_+1")

			f_MoveTo("", "MapExit", GL_MOVESPEED_WALK)
			
			if not AliasExists("RatBoy") then
				break
			end

			while HasProperty("RatBoy", "LetsGo") do
				if HasProperty("RatBoy", "KillingTime") then
					local Age = SimGetAge("")
					local SettlementId = GetSettlementID("")
					feedback_MessageCharacter("", "@L_FAMILY_6_DEATH_MSG_DEAD_OWNER_HEAD", "@L_FAMILY_6_DEATH_MSG_DEAD_OWNER_BODY_MALE", GetID(""), Age, SettlementId)
					ModifyHP("", -GetMaxHP(""))
				end
				Sleep(5)
			end
		end
		Sleep(2)
	end
end

function CleanUp()
end

