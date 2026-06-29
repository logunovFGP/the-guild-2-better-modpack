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

	local cItem = GetProperty("Foundry", "CommItem")
	local cBudget = GetProperty("Foundry", "CommBudget")
	local cWantQ = GetProperty("Foundry", "CommWantQuality")
	if not cBudget then cBudget = 0 end
	if not cWantQ then cWantQ = 2 end
	local itemKey = "_COMM_PLACE_HEAD_+0"
	if cItem then itemKey = "_ITEM_"..ItemGetName(cItem).."_NAME_+0" end
	local qualKey = "_WOA_QUALITY_GOOD_+0"
	if cWantQ == 0 then qualKey = "_WOA_QUALITY_POOR_+0"
	elseif cWantQ == 1 then qualKey = "_WOA_QUALITY_COMMON_+0"
	elseif cWantQ == 3 then qualKey = "_WOA_QUALITY_EXCELLENT_+0" end

	if st == 1 then
		SetArg(1, itemKey); SetArg(2, qualKey); SetArg(3, cBudget)
		local answer = MsgBox("", "", "@P"..
			"@B[1,@L_COMM_MGR_ACCEPT_+0]".."@B[2,@L_COMM_MGR_DECLINE_+0]",
			"@L_COMM_MGR_PENDING_HEAD_+0", "@L_COMM_MGR_PENDING_BODY_+0")
		if answer == 1 then
			SetProperty("Foundry", "CommState", 2)
			ms_managecommission_NotifyBuyer("@L_COMM_NEWS_ACCEPT_HEAD_+0", "@L_COMM_NEWS_ACCEPT_BODY_+0")
			SetArg(1, itemKey); SetArg(2, qualKey); SetArg(3, cBudget)
			MsgBoxNoWait("", "", "@L_COMM_MGR_ACCEPTED_HEAD_+0", "@L_COMM_MGR_ACCEPTED_BODY_+0")
		else
			ms_managecommission_NotifyBuyer("@L_COMM_NEWS_DECLINE_HEAD_+0", "@L_COMM_NEWS_DECLINE_BODY_+0")
			RemoveProperty("Foundry", "CommState")
			RemoveProperty("Foundry", "CommBuyerDyn")
			RemoveProperty("Foundry", "CommBuyerChar")
			RemoveProperty("Foundry", "CommItem")
			RemoveProperty("Foundry", "CommBudget")
			RemoveProperty("Foundry", "CommWantQuality")
			RemoveProperty("Foundry", "CommPermil")
			RemoveProperty("Foundry", "CommQuality")
			MsgBoxNoWait("", "", "@L_COMM_MGR_DECLINED_HEAD_+0", "@L_COMM_MGR_DECLINED_BODY_+0")
		end
	elseif st == 2 then
		SetArg(1, itemKey); SetArg(2, qualKey); SetArg(3, cBudget)
		MsgBoxNoWait("", "", "@L_COMM_MGR_ACCEPTED_HEAD_+0", "@L_COMM_MGR_INPROGRESS_BODY_+0")
	else
		SetArg(1, itemKey); SetArg(2, qualKey); SetArg(3, cBudget)
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
