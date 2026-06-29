COMM_MAX_BUTTONS = 8

function Run()
	if not GetInsideBuilding("", "Foundry") then
		MsgQuick("", "@L_COMM_NEEDSMITHY_+0")
		StopMeasure(); return
	end

	local myDyn = GetDynastyID("")
	local st = GetProperty("Foundry", "CommState")

	if st and st > 0 then
		local buyerDyn = GetProperty("Foundry", "CommBuyerDyn")
		if buyerDyn ~= myDyn then
			MsgBoxNoWait("", "", "@L_COMM_BUSY_HEAD_+0", "@L_COMM_BUSY_BODY_+0")
			StopMeasure(); return
		end
		if st == 3 then
			ms_debugmanagecommission_Collect()
		elseif st == 2 then
			MsgBoxNoWait("", "", "@L_COMM_MINE_HEAD_+0", "@L_COMM_INPROGRESS_BODY_+0")
		else
			MsgBoxNoWait("", "", "@L_COMM_MINE_HEAD_+0", "@L_COMM_PENDING_BODY_+0")
		end
		StopMeasure(); return
	end

	ms_debugmanagecommission_Place(myDyn)
	StopMeasure()
end

function Place(myDyn)
	local class = MsgBox("", "", "@P".."@B[1,@L_WOA_PICK_ARMOUR_+0]".."@B[2,@L_WOA_PICK_WEAPON_+0]", "@L_COMM_PLACE_HEAD_+0", "@L_COMM_PLACE_BODY_+0")
	local wantClass
	if class == 1 then wantClass = "armour"
	elseif class == 2 then wantClass = "weapon"
	else return end

	local haveClassFn = (ms_createworkofart_woa_ClassOf ~= nil)
	local buttons = ""
	local map = {}
	local n = 0
	local id = 1
	while id < 1260 and n < COMM_MAX_BUTTONS do
		local ok
		if haveClassFn then
			ok = (ms_createworkofart_woa_ClassOf(id) == wantClass) and BuildingCanProduce("Foundry", id)
		else
			ok = BuildingCanProduce("Foundry", id)
		end
		if ok then
			n = n + 1
			map[n] = id
			buttons = buttons .. "@B["..n..",@L_ITEM_"..ItemGetName(id).."_NAME_+0]"
		end
		id = id + 1
	end
	if n == 0 then
		MsgBoxNoWait("", "", "@L_COMM_NONE_HEAD_+0", "@L_COMM_NONE_BODY_+0")
		return
	end

	local pick = MsgBox("", "", "@P"..buttons, "@L_COMM_PICKITEM_HEAD_+0", "@L_COMM_PICKITEM_BODY_+0")
	if not map[pick] then return end
	local itemId = map[pick]

	local qChoice = MsgBox("", "", "@P"..
		"@B[1,@L_WOA_QUALITY_COMMON_+0]"..
		"@B[2,@L_WOA_QUALITY_GOOD_+0]"..
		"@B[3,@L_WOA_QUALITY_EXCELLENT_+0]",
		"@L_COMM_QUALITY_HEAD_+0", "@L_COMM_QUALITY_BODY_+0")
	local wantQ
	if qChoice == 1 then wantQ = 1
	elseif qChoice == 2 then wantQ = 2
	elseif qChoice == 3 then wantQ = 3
	else return end

	local budgetChoice = MsgBox("", "", "@P"..
		"@B[1,@L_COMM_BUDGET_1_+0]".."@B[2,@L_COMM_BUDGET_2_+0]"..
		"@B[3,@L_COMM_BUDGET_3_+0]".."@B[4,@L_COMM_BUDGET_4_+0]",
		"@L_COMM_BUDGET_HEAD_+0", "@L_COMM_BUDGET_BODY_+0")
	local tiers = { 500, 1500, 4000, 10000 }
	local budget = tiers[budgetChoice]
	if not budget then return end

	if GetMoney("") < budget then
		MsgBoxNoWait("", "", "@L_COMM_POOR_HEAD_+0", "@L_COMM_POOR_BODY_+0")
		return
	end

	SetProperty("Foundry", "CommBuyerDyn", myDyn)
	SetProperty("Foundry", "CommBuyerChar", GetID(""))
	SetProperty("Foundry", "CommItem", itemId)
	SetProperty("Foundry", "CommBudget", budget)
	SetProperty("Foundry", "CommWantQuality", wantQ)

	if DynastyIsHumanControlled("Foundry") then
		SetProperty("Foundry", "CommState", 1)
		if BuildingGetOwner("Foundry", "CommBoss") then
			MsgNewsNoWait("", "CommBoss", "", "economy", -1, "@L_COMM_NEWS_NEW_HEAD_+0", "@L_COMM_NEWS_NEW_BODY_+0")
		end
		MsgBoxNoWait("", "", "@L_COMM_SENT_HEAD_+0", "@L_COMM_SENT_BODY_+0")
	else
		SetProperty("Foundry", "CommState", 2)
		MsgBoxNoWait("", "", "@L_COMM_SENT_HEAD_+0", "@L_COMM_AUTOACCEPT_BODY_+0")
	end
end

function Collect()
	local itemId  = GetProperty("Foundry", "CommItem")
	local budget  = GetProperty("Foundry", "CommBudget")
	local permil  = GetProperty("Foundry", "CommPermil")
	local quality = GetProperty("Foundry", "CommQuality")
	if not itemId or not budget then return end
	if not permil  then permil  = 1000 end
	if not quality then quality = 0 end

	if not CanAddItems("", itemId, 1, INVENTORY_STD) then
		MsgBoxNoWait("", "", "@L_COMM_COLLECT_NOROOM_HEAD_+0", "@L_COMM_COLLECT_NOROOM_BODY_+0")
		return
	end

	if not chr_SpendMoney("", budget, "Commission") then
		MsgBoxNoWait("", "", "@L_COMM_COLLECT_POOR_HEAD_+0", "@L_COMM_COLLECT_POOR_BODY_+0")
		return
	end
	if BuildingGetOwner("Foundry", "CommBoss") then
		if GetDynasty("CommBoss", "CommBossDyn") then
			chr_CreditMoney("CommBossDyn", budget, "Commission")
		end
	end

	CreateWorkOfArt("", itemId, permil, quality, "", INVENTORY_STD, "")

	ms_debugmanagecommission_ClearCommission("Foundry")
	MsgBoxNoWait("", "", "@L_COMM_COLLECT_DONE_HEAD_+0", "@L_COMM_COLLECT_DONE_BODY_+0")
end

function ClearCommission(alias)
	RemoveProperty(alias, "CommState")
	RemoveProperty(alias, "CommBuyerDyn")
	RemoveProperty(alias, "CommBuyerChar")
	RemoveProperty(alias, "CommItem")
	RemoveProperty(alias, "CommBudget")
	RemoveProperty(alias, "CommWantQuality")
	RemoveProperty(alias, "CommPermil")
	RemoveProperty(alias, "CommQuality")
end

function CleanUp()
end
