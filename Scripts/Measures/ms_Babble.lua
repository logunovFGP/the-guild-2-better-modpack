-- -----------------------
-- alles für die Needs: Labern was das Zeug hält - 
-- -----------------------
function Run()

	if not AliasExists("Destination") then
		local TalkPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==2000)AND NOT(Object.GetStateImpact(no_idle))AND(Object.CanBeInterrupted(Babble))AND NOT(Object.HasDynasty()))","Destination", -1)
		if (TalkPartners == 0) then
			return
		end
		CopyAlias("Destination"..Rand(TalkPartners), "Destination")

	end

	if not ai_StartInteraction("", "Destination", 350, 90) then
		StopMeasure()
	end
	
	SetAvoidanceGroup("", "Destination")
	SetData("StartAnim", 1)
	
	if SimGetGender("") == GL_GENDER_MALE then
		PlaySound3DVariation("", "CharacterFX/male_neutral", 1)
	else
		PlaySound3DVariation("", "CharacterFX/female_neutral", 1)
	end
	
	PlayAnimationNoWait("", "talk")
	Sleep(1.0)
	
	if SimGetGender("Destination") == GL_GENDER_MALE then
		PlaySound3DVariation("Destination","CharacterFX/male_neutral", 1)
	else
		PlaySound3DVariation("Destination","CharacterFX/female_neutral", 1)
	end
	
	PlayAnimation("Destination", "talk")
	IncrementXPQuiet("", 5)
	IncrementXPQuiet("Destination", 5)
end

function CleanUp()

	if GetData("StartAnim") == 1 then
		if AliasExists("Destination") then
			StopAnimation("Destination")
		end
		StopAnimation("")
	end
	
	ReleaseAvoidanceGroup("")
end

