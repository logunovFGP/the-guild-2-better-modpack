function kr_DefaultLord(cat)
	if GetData("#kr_routelord_"..cat) == nil then
		SetData("#kr_routelord_"..cat, cat)
	end
end

function kr_SetClassRoutes(cls, openVal)
	if cls == 1 then
		SetData("#kr_route_2", openVal); ms_managetraderoutes_kr_DefaultLord(2)
	elseif cls == 2 then
		SetData("#kr_route_3", openVal); ms_managetraderoutes_kr_DefaultLord(3)
		SetData("#kr_route_4", openVal); ms_managetraderoutes_kr_DefaultLord(4)
		SetData("#kr_route_7", openVal); ms_managetraderoutes_kr_DefaultLord(7)
	elseif cls == 3 then
		SetData("#kr_route_1", openVal); ms_managetraderoutes_kr_DefaultLord(1)
		SetData("#kr_route_5", openVal); ms_managetraderoutes_kr_DefaultLord(5)
	end
end

function kr_ClassRepCat(cls)
	if cls == 1 then return 2
	elseif cls == 2 then return 3
	elseif cls == 3 then return 1
	end
	return 0
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
			"@L_MEASURE_ManageTradeRoutes_NAME_+0", "@L_KR_NOT_HOME_+0")
		StopMeasure()
		return
	end

	local cls = SimGetClass("")
	local repCat = ms_managetraderoutes_kr_ClassRepCat(cls)
	if repCat == 0 then
		MsgQuick("", "@L_MEASURE_ManageTradeRoutes_NOROUTES")
		StopMeasure()
		return
	end

	local masterId = nil
	if cls == 1 then masterId = GetProperty("Guildhouse", "PatronMaster")
	elseif cls == 2 then masterId = GetProperty("Guildhouse", "ArtisanMaster")
	elseif cls == 3 then masterId = GetProperty("Guildhouse", "ScholarMaster")
	elseif cls == 4 then masterId = GetProperty("Guildhouse", "ChiselerMaster")
	end

	if masterId == nil or masterId == 0 or masterId ~= GetID("") then
		MsgQuick("", "@L_MEASURE_ManageTradeRoutes_NOTMASTER")
		StopMeasure()
		return
	end

	local isOpen = (GetData("#kr_route_"..repCat) == 1)
	local stateWord = "@L_KR_ROUTES_CLOSED_+0"
	if isOpen then stateWord = "@L_KR_ROUTES_OPEN_+0" end

	local choice = MsgBox("", "", "@P@B[1,@L_KR_BTN_OPEN_+0]@B[2,@L_KR_BTN_CLOSE_+0]@B[0,@L_KR_BTN_CANCEL_+0]",
		"@L_MEASURE_ManageTradeRoutes_NAME_+0",
		"@L_KR_ROUTES_BODY_+0", stateWord)

	if choice == 1 then
		ms_managetraderoutes_kr_SetClassRoutes(cls, 1)
		MsgQuick("", "@L_MEASURE_ManageTradeRoutes_OPENED")
	elseif choice == 2 then
		ms_managetraderoutes_kr_SetClassRoutes(cls, 0)
		MsgQuick("", "@L_MEASURE_ManageTradeRoutes_CLOSED")
	end
end

function CleanUp()
end