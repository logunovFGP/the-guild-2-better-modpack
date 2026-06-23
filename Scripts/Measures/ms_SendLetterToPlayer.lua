function Run()
	if not (GetLocalPlayerDynasty("LocalDyn") and GetDynasty("", "ActorDyn") and GetID("LocalDyn") == GetID("ActorDyn")) then
		return
	end

	if not DynastyHasUpgrade("", "Escritoire") then
		MsgBoxNoWait("", "", "@L_MP_LETTER_NEEDDESK_HEAD", "@L_MP_LETTER_NEEDDESK_BODY")
		return
	end

	if not DynastyIsPlayer("Destination") then
		return
	end

	GetDynasty("Destination", "LetterTarget")
	OpenLetterComposer("LetterTarget")
end