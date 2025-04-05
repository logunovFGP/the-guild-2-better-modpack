function Run()
	if GetLocalPlayerDynasty("Player")	then
		for i = 0, DynastyGetMemberCount("Player") - 1 do
			if DynastyGetMember("Player", i, "Member") then
				LogMessage("@NAO Local Character: " .. GetName("Member"))
				break
			end
		end
	end

	SimBeamMeUp("Member", "", true)

	if CameraIsTerrain() then
		CameraIndoorSetBuilding("")
	end

	GetPosition("Member", "Position")
	GetSettlement("", "Settlement")

	local Count = -1
	repeat
		Count = Count + 1
		SimCreate(720, "Settlement", "Position", "Musician"..Count)
	until (Count == 2)

	Sleep(1)

	if (Count == 2) then
	    CreateCutscene("Debug/_WIP_Wedding", "Cutscene(_WIP_Wedding)")

	    local Participants = {"Member", "Musician0", "Musician1", "Musician2"}
	    for k, v in helpfuncs_myipairs(Participants) do
	    	CopyAliasToCutscene(v, "Cutscene(_WIP_Wedding)", v)
	    end

	    Sleep(1)

	    CutsceneCallScheduled("Cutscene(_WIP_Wedding)", "Init")
	end
end