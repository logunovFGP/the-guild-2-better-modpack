local DELIVER_QTY    = 5    -- goods required to fulfil a request
local FAVOUR_REWARD  = 12   -- favour gained on fulfilment
local FAVOUR_PENALTY = 8    -- favour lost for an ignored request

function kr_ReqEpoch()
	return GetRound() * 4 + GetSeason()
end

function kr_ReqCategory(epoch)
	local m = epoch
	while m >= 6 do m = m - 6 end
	if m == 0 then return 1
	elseif m == 1 then return 2
	elseif m == 2 then return 3
	elseif m == 3 then return 4
	elseif m == 4 then return 5
	else return 7 end
end

function kr_LordOf(cat)
	local L = GetData("#kr_routelord_"..cat)
	if L == nil or L < 1 then L = cat end
	return L
end

function kr_ReqLord(epoch)
	local C    = ms_lordshiprequest_kr_ReqCategory(epoch)
	local supC = ms_lordshiprequest_kr_LordOf(C)
	local L    = ms_lordshiprequest_kr_LordOf(ms_lordshiprequest_kr_ReqCategory(epoch + 3))
	if L == supC then
		L = ms_lordshiprequest_kr_LordOf(ms_lordshiprequest_kr_ReqCategory(epoch + 4))
	end
	return L
end

function kr_CountCat(C)
	local n = 0
	local cnt = InventoryGetSlotCount("", INVENTORY_STD)
	local g
	for g = 0, cnt - 1 do
		local item, amt = InventoryGetSlotInfo("", g, INVENTORY_STD)
		if item and item ~= -1 and amt and amt > 0 and ItemGetCategory(item) == C then
			n = n + amt
		end
	end
	return n
end

function kr_DeliverCat(C, Q)
	local guard = 0
	while Q > 0 and guard < 200 do
		guard = guard + 1
		local removed = false
		local cnt = InventoryGetSlotCount("", INVENTORY_STD)
		local g
		for g = 0, cnt - 1 do
			local item, amt = InventoryGetSlotInfo("", g, INVENTORY_STD)
			if item and item ~= -1 and amt and amt > 0 and ItemGetCategory(item) == C then
				local take = amt
				if take > Q then take = Q end
				RemoveItems("", item, take, INVENTORY_STD)
				Q = Q - take
				removed = true
				break
			end
		end
		if not removed then break end
	end
	return Q
end

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

	if not GetHomeBuilding("", "Home") or GetSettlementID("Home") ~= GetSettlementID("Guildhouse") then
		MsgBox("", "", "@P@B[0,@L_KR_BTN_OK_+0]",
			"@L_MEASURE_LordshipRequest_NAME_+0", "@L_KR_NOT_HOME_+0")
		StopMeasure()
		return
	end

	local dynId = GetDynastyID("")
	if dynId == nil or dynId < 0 then
		StopMeasure()
		return
	end

	local epoch = ms_lordshiprequest_kr_ReqEpoch()
	local C = ms_lordshiprequest_kr_ReqCategory(epoch)
	local L = ms_lordshiprequest_kr_ReqLord(epoch)

	local doneKey = "#kr_reqdone_"..dynId
	local seenKey = "#kr_reqseen_"..dynId
	local lastDone = GetData(doneKey); if lastDone == nil then lastDone = -1 end
	local lastSeen = GetData(seenKey); if lastSeen == nil then lastSeen = -1 end

	if lastSeen < epoch then
		if lastSeen >= 0 and lastDone < (epoch - 1) and LordshipAddFavor ~= nil then
			local prevL = ms_lordshiprequest_kr_ReqLord(epoch - 1)
			LordshipAddFavor("", prevL, -FAVOUR_PENALTY)
		end
		SetData(seenKey, epoch)
	end

	local lordName = "@L_KR_LORD_"..L.."_+0"
	local catName  = "@L_KR_CAT_"..C.."_+0"

	if lastDone == epoch then
		MsgBox("", "", "@P@B[0,@L_KR_BTN_OK_+0]", "@L_MEASURE_LordshipRequest_NAME_+0", "@L_KR_REQ_DONE_+0", lordName)
		StopMeasure()
		return
	end

	local have = ms_lordshiprequest_kr_CountCat(C)

	local choice = MsgBox("", "", "@P@B[1,@L_KR_BTN_DELIVER_+0]@B[0,@L_KR_BTN_CANCEL_+0]",
		"@L_MEASURE_LordshipRequest_NAME_+0",
		"@L_KR_REQ_BODY_+0",
		lordName, DELIVER_QTY, catName, have)

	if choice ~= 1 then
		StopMeasure()
		return
	end

	if have < DELIVER_QTY then
		MsgBox("", "", "@P@B[0,@L_KR_BTN_OK_+0]", "@L_MEASURE_LordshipRequest_NAME_+0", "@L_KR_REQ_SHORT_+0", DELIVER_QTY, catName)
		StopMeasure()
		return
	end

	ms_lordshiprequest_kr_DeliverCat(C, DELIVER_QTY)
	if LordshipAddFavor ~= nil then
		LordshipAddFavor("", L, FAVOUR_REWARD)
	end
	SetData(doneKey, epoch)

	MsgBox("", "", "@P@B[0,@L_KR_BTN_OK_+0]", "@L_MEASURE_LordshipRequest_NAME_+0", "@L_KR_REQ_THANKS_+0", lordName)
end

function CleanUp()
end