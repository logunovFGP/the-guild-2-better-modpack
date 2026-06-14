local LICENCE_COST  = 2000   -- fee per kingdom licence
local LICENCE_HOURS = 24     -- in-game hours a licence lasts

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
		MsgBox("", "", "@P@B[0,@L_KR_BTN_OK_+0]", "@L_MEASURE_BuyTradePermit_NAME_+0", "@L_KR_NOT_HOME_+0")
		StopMeasure()
		return
	end

	local cats = {1, 2, 3, 4, 5, 7}
	local seen = {}
	local prompt = "@P"
	local i
	for i = 1, 6 do
		local C = cats[i]
		local Lr = GetData("#kr_routelord_"..C)
		if Lr == nil or Lr < 1 then Lr = C end
		if not seen[Lr] then
			seen[Lr] = true
			prompt = prompt.."@B["..Lr..",@L_KR_LORD_"..Lr.."_+0]"
		end
	end
	prompt = prompt.."@B[0,@L_KR_BTN_CANCEL_+0]"

	local L = MsgBox("", "", prompt,
		"@L_MEASURE_BuyTradePermit_NAME_+0", "@L_KR_PERMIT_PICK_+0", LICENCE_COST, LICENCE_HOURS)
	if L == nil or L <= 0 then
		StopMeasure()
		return
	end

	local lordName = "@L_KR_LORD_"..L.."_+0"

	if KontorGetLordPermitLeft ~= nil then
		local lft = KontorGetLordPermitLeft("", L)
		if lft ~= nil and lft > 0 then
			MsgBox("", "", "@P@B[0,@L_KR_BTN_OK_+0]",
				"@L_MEASURE_BuyTradePermit_NAME_+0", "@L_KR_PERMIT_HAVE_+0", lordName, lft)
			StopMeasure()
			return
		end
	end

	if GetMoney("Dynasty") < LICENCE_COST then
		MsgBox("", "", "@P@B[0,@L_KR_BTN_OK_+0]",
			"@L_MEASURE_BuyTradePermit_NAME_+0", "@L_KR_PERMIT_NOMONEY")
		StopMeasure()
		return
	end

	SpendMoney("Dynasty", LICENCE_COST, "TradePermit")

	if KontorGrantLordPermit ~= nil then
		KontorGrantLordPermit("", L, LICENCE_HOURS)
	end
	if LordshipAddFavor ~= nil then
		LordshipAddFavor("", L, 1)
	end

	local DestTime = GetGametime() + LICENCE_HOURS
	local ID = "krlic"..GetID("")..L
	MsgNewsNoWait("All", "", "@C[@L_KR_LICENCE_COOLDOWN_+0,%2i,%3l]", "economie", -1,
		"@L_MEASURE_BuyTradePermit_NAME_+0",
		"@L_KR_LICENCE_NEWS_+0",
		lordName,
		DestTime, ID)

	ShowOverheadSymbol("", false, true, 0, "-%1t", LICENCE_COST)
	if dyn_IsLocalPlayer("") then
		PlaySound3D("", "Effects/coins_to_moneybag+0.wav", 1.0)
	end
end

function CleanUp()
end