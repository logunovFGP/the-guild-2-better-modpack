function Run()

	if not ai_GoInsideBuilding("", "", -1, GL_BUILDING_TYPE_TOWNHALL) then
		return
	end

	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)

	if not GetSettlement("", "city") then
		return
	end

	local CityTreasure = GetMoney("city")
	local CityTreasureMin = 1000
	local money = 0
	local MaxMoney = (CityTreasure - CityTreasureMin)/10
	
	if MaxMoney > 10000 then
		MaxMoney = 10000
	end
	
	local MinSteal = MaxMoney * 0.25
	
	if CityTreasure < CityTreasureMin then
		MsgQuick("", "@L_MEASURE_EMBEZZLEPUBLICMONEY_FAILURE_+0", GetID("city"))
		return
	else
		local Random = Rand(10) + 1
		money = ((MaxMoney - MinSteal) / 10) * Random + MinSteal
	end
	
	GetInsideBuilding("", "Townhall")
	
	if GetLocatorByName("Townhall", "EmbezzleMoney", "Result") then
		f_MoveTo("", "Result")
	end
	
	PlayAnimation("", "manipulate_middle_twohand")
	
	SetMeasureRepeat(TimeOut)
	chr_SpendMoney("city", money, "CostThiefs")
	chr_CreditMoney("", money, "IncomeThiefs")
	achievements_Unlock("Owner", "PRIVILEGE_EMBEZZLE")
	
	feedback_MessageCharacter("Owner",
						"@L_PRIVILEGES_108_EMBEZZLEPUBLICMONEY_SUCCESS_HEAD_+0",
						"@L_PRIVILEGES_108_EMBEZZLEPUBLICMONEY_SUCCESS_BODY_+0", GetID("Owner"), GetID("city"), money)

	chr_GainXP("", GetData("BaseXP"))

	--for the mission
	mission_ScoreCrime("", money)
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

