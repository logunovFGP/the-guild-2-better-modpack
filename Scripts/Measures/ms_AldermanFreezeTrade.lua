function Run()
	if IsStateDriven() then
		if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN) then
			StopMeasure()
			return
		end
	end
	if not GetInsideBuilding("", "Guildhouse") then
		StopMeasure()
		return
	end

	if not trade_IsAlderman("", "Guildhouse") then
		MsgBox("", "", "@P@B[0,@L_KR_BTN_OK_+0]", "@L_MEASURE_AldermanFreezeTrade_NAME_+0", "@L_KR_NOT_ALDERMAN_+0")
		StopMeasure()
		return
	end

	local now = ScenarioGetTimePlayed()
	local cdUntil = GetData("#kr_freeze_cooldown")
	if cdUntil and now < cdUntil then
		MsgBox("", "", "@P@B[0,@L_KR_BTN_OK_+0]", "@L_MEASURE_AldermanFreezeTrade_NAME_+0", "@L_KR_FREEZE_COOLDOWN_+0")
		StopMeasure()
		return
	end

	local choice = tonumber(MsgBox("", "", "@P@B[1,@L_KR_BTN_FREEZE_+0]@B[2,@L_KR_BTN_UNFREEZE_+0]@B[0,@L_KR_BTN_CANCEL_+0]", "@L_MEASURE_AldermanFreezeTrade_NAME_+0", "@L_KR_FREEZE_BODY_+0"))

	GetSettlement("", "AldCity")

	if choice == 1 then
		SetData("#kr_freeze_all", 1)
		if KontorFreezeAll ~= nil then KontorFreezeAll(1) end
		SetData("#kr_freeze_cooldown", now + 12)
		MsgQuick("", "@L_MEASURE_AldermanFreezeTrade_FROZEN")
		MsgNewsNoWait("All", "", "", "economie", -1, "@L_KR_FREEZE_NEWS_HEAD_+0", "@L_KR_FREEZE_NEWS_FROZEN_+0", GetID(""), GetID("AldCity"))
	elseif choice == 2 then
		SetData("#kr_freeze_all", 0)
		if KontorFreezeAll ~= nil then KontorFreezeAll(0) end
		SetData("#kr_freeze_cooldown", now + 12)
		MsgQuick("", "@L_MEASURE_AldermanFreezeTrade_LIFTED")
		MsgNewsNoWait("All", "", "", "economie", -1, "@L_KR_FREEZE_NEWS_HEAD_+0", "@L_KR_FREEZE_NEWS_LIFTED_+0", GetID(""), GetID("AldCity"))
	end
end

function CleanUp()
end