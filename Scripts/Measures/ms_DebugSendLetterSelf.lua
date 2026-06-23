function Run()
	if not (GetLocalPlayerDynasty("LocalDyn") and GetDynasty("", "ActorDyn") and GetID("LocalDyn") == GetID("ActorDyn")) then
		return
	end

	GetDynasty("", "SelfTarget")
	OpenLetterComposer("SelfTarget")
end
