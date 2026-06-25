function Run()
	if dyn_IsLocalPlayer("") then
		return
	end

	if not GetLocalPlayerDynasty("LocalDyn") then
		return
	end

	if not DynastyHasUpgrade("LocalDyn", "Escritoire") then
		MsgBoxNoWait("", "", "@L_MP_LETTER_NEEDDESK_HEAD", "@L_MP_LETTER_NEEDDESK_BODY")
		return
	end

	if not GetDynasty("", "TargetDyn") then
		return
	end
	if not DynastyIsPlayer("TargetDyn") then
		return
	end
	if GetID("TargetDyn") == GetID("LocalDyn") then
		return
	end

	OpenLetterComposer("TargetDyn")
end
