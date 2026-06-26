function Run()
	if not GetInsideBuilding("", "Foundry") then
		MsgQuick("", "@L_COMM_MGR_NOTYOURS_+0")
		StopMeasure(); return
	end
	if GetDynastyID("Foundry") ~= GetDynastyID("") then
		MsgQuick("", "@L_COMM_MGR_NOTYOURS_+0")
		StopMeasure(); return
	end

	local st = GetProperty("Foundry", "CommState")
	if not st or st == 0 then
		MsgBoxNoWait("", "", "@L_COMM_MGR_NONE_HEAD_+0", "@L_COMM_MGR_NONE_BODY_+0")
		StopMeasure(); return
	end

	if st == 1 then
		local answer = MsgBox("", "", "@P"..
			"@B[1,@L_COMM_MGR_ACCEPT_+0]".."@B[2,@L_COMM_MGR_DECLINE_+0]",
			"@L_COMM_MGR_PENDING_HEAD_+0", "@L_COMM_MGR_PENDING_BODY_+0")
		if answer == 1 then
			SetProperty("Foundry", "CommState", 2)
			ms_managecommission_NotifyBuyer("@L_COMM_NEWS_ACCEPT_HEAD_+0", "@L_COMM_NEWS_ACCEPT_BODY_+0")
			MsgBoxNoWait("", "", "@L_COMM_MGR_ACCEPTED_HEAD_+0", "@L_COMM_MGR_ACCEPTED_BODY_+0")
		else
			ms_managecommission_NotifyBuyer("@L_COMM_NEWS_DECLINE_HEAD_+0", "@L_COMM_NEWS_DECLINE_BODY_+0")
			RemoveProperty("Foundry", "CommState")
			RemoveProperty("Foundry", "CommBuyerDyn")
			RemoveProperty("Foundry", "CommBuyerChar")
			RemoveProperty("Foundry", "CommItem")
			RemoveProperty("Foundry", "CommBudget")
			RemoveProperty("Foundry", "CommPermil")
			RemoveProperty("Foundry", "CommQuality")
			MsgBoxNoWait("", "", "@L_COMM_MGR_DECLINED_HEAD_+0", "@L_COMM_MGR_DECLINED_BODY_+0")
		end
	elseif st == 2 then
		MsgBoxNoWait("", "", "@L_COMM_MGR_ACCEPTED_HEAD_+0", "@L_COMM_MGR_INPROGRESS_BODY_+0")
	else
		MsgBoxNoWait("", "", "@L_COMM_MGR_ACCEPTED_HEAD_+0", "@L_COMM_MGR_READY_BODY_+0")
	end

	StopMeasure()
end

-- notify the patron
function NotifyBuyer(head, body)
	local bId = GetProperty("Foundry", "CommBuyerChar")
	if bId and bId > 0 and GetAliasByID(bId, "CommPatron") then
		MsgNewsNoWait("", "CommPatron", "", "economy", -1, head, body)
	end
end

function CleanUp()
end
