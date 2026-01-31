function AIDecide()

    if BuildingHasUpgrade("", "Schadelbrand") then
	    return "B"
	else
	    return "A"
	end

end

function Run()
	local Money = GetMoney("") 
	
	if Money < 800 then
		MsgQuick("", "@L_MEASURES_DIVEGETALC_FAIL_+2")
		return
	end	

	local cashskill = 0
	local secretskill = 0
	if BuildingGetOwner("", "Besitzer") then
		cashskill = GetSkillValue("Besitzer", BARGAINING)/100
		secretskill = GetSkillValue("Besitzer", SECRET_KNOWLEDGE)
	else
		return
 	end

	local menge = secretskill * 10
	local kostengrog = 800*(1-cashskill*2)
	local kostenbrand = 1200*(1-cashskill*2)
	local wahltext = ""
	local bodytext = ""

  	if BuildingHasUpgrade("", "Schadelbrand") then
	 	bodytext = bodytext.."@L_MEASURES_DIVEGETALC_BODY_+4"
	 	wahltext = wahltext.."@B[A,@L_MEASURES_DIVEGETALC_BODY_+2]@B[B,@L_MEASURES_DIVEGETALC_BODY_+3]"
	else
	 	bodytext = bodytext.."@L_MEASURES_DIVEGETALC_BODY_+0"
	 	wahltext = wahltext.."@B[A,@L_MEASURES_DIVEGETALC_BODY_+2]"
	end

 	wahltext = wahltext.."@B[C,@L_MEASURES_DIVEGETALC_BODY_+1]"
	
	local sauf
 	if IsGUIDriven() then
	    sauf = MsgBox("",false,"@P"..
	    wahltext,
	    "@L_MEASURES_DIVEGETALC_HEAD_+0",
	    bodytext, kostengrog, kostenbrand)
	else
	    sauf = ms_021_divegetalc_AIDecide()
	end
	
	local price
	local alcId
		
	if sauf == "B" then
		alcId = "Schadelbrand"
		price = kostenbrand
	elseif sauf == "A" then
		alcId = "PiratenGrog"
		price = kostengrog
	else
	  	return
	end
	
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
  	SetMeasureRepeat(TimeOut)

	if not CanAddItems("", alcId, menge, INVENTORY_STD) then
		MsgQuick("", "@L_MEASURES_DIVEGETALC_FAIL_+3")
		return
	end
	
	if not chr_SpendMoney("", price, "WaresSeaBought") then
		MsgQuick("", "@L_MEASURES_DIVEGETALC_FAIL_+2")
		StopMeasure()
	end
	
	economy_UpdateBalance("", "WaresBought", 0-price)
	
	AddItems("", alcId, menge, INVENTORY_STD)
	MsgQuick("", "@L_MEASURES_DIVEGETALC_SUCCESS_+0")
end

function CleanUp()
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end
