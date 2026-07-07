function Run()
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)

	if not ai_GoInsideBuilding("", "",-1, GL_BUILDING_TYPE_TOWNHALL) then
		StopMeasure()
	end
	if not GetInsideBuilding("","building") then
		StopMeasure()
	end

	BuildingGetCity("building","city")
	local Percent = 0+ GetProperty("city","TurnoverTax")
	SetData("Oldpercent",Percent)
	local result = InitData("@P"..
	"@B[0,0,@L_PRIVILEGES_111_SETTURNOVERTAX_ACTION_BTN_+0,Hud/Buttons/btn_Money_Small.tga]"..
	"@B[10,10,@L_PRIVILEGES_111_SETTURNOVERTAX_ACTION_BTN_+1,Hud/Buttons/btn_Money_SmallLarge.tga]"..
	"@B[15,15,@L_PRIVILEGES_111_SETTURNOVERTAX_ACTION_BTN_+2,Hud/Buttons/btn_Money_Medium.tga]"..
	"@B[20,20,@L_PRIVILEGES_111_SETTURNOVERTAX_ACTION_BTN_+3,Hud/Buttons/btn_Money_MediumLarge.tga]"..
	"@B[30,30,@L_PRIVILEGES_111_SETTURNOVERTAX_ACTION_BTN_+4,Hud/Buttons/btn_Money_Large.tga]",
	ms_111_set_turnovertax_AIFunction,
	"@L_PRIVILEGES_111_SETTURNOVERTAX_ACTION_TEXT_+1",
	"@L_PRIVILEGES_111_SETTURNOVERTAX_ACTION_TEXT_+0",Percent)

	if result and result ~= "C" and result >= 0 then
		SetProperty("city","TurnoverTax",result)
	end
	
	SetMeasureRepeat(TimeOut)
	
	BuildingGetCity("building","city")
	local TaxValue = 0 + GetProperty("city","TurnoverTax")
	local Oldpercent = GetData("Oldpercent")
	if Oldpercent ~= TaxValue then
		MsgNewsNoWait("All","","","politics",-1,
			"@L_PRIVILEGES_111_SETTURNOVERTAX_MSG_HEADLINE_+0",
			"@L_PRIVILEGES_111_SETTURNOVERTAX_MSG_BODY",GetID(""),GetID("city"),Oldpercent,TaxValue)
		achievements_Unlock("", "PRIVILEGE_SET_TAXES")
	end
	StopMeasure()
end

function AIFunction()
	local MinTax = 0
	local MaxTax = 30
	
  -- taxes scale with difficulty (no high taxes on easy, no low taxes on hard) 
	local Difficulty = ScenarioGetDifficulty() -- 0 .. 4
	if Difficulty == 0 then -- Tax range: 0 .. 20
	    MaxTax = 20
	end
	if Difficulty == 1 then  -- Tax range: 0 .. 25
	    MaxTax = 25
	end
	if Difficulty == 3 then  -- Tax range: 5 .. 30
	    MinTax = 5
	end
	if Difficulty == 4 then -- Tax range: 10 .. 300
	    MinTax = 10
	end

	local AIChoice = 5 * Rand(7)
	AIChoice = math.max(AIChoice, MinTax)
	AIChoice = math.min(AIChoice, MaxTax)
	return AIChoice
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2",Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

