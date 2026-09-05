function AIDecide()

    if BuildingHasUpgrade("", "Schadelbrand") then
	    return "B"
	else
	    return "A"
	end

end

-- Percent chance a contraband run is seized, given the owner's Shadow Arts.
-- 45% for an unskilled owner down to 6% at the skill cap of 15; never zero,
-- so smuggling always carries some risk.
function SeizureChance(stealthskill)
	stealthskill = math.max(0, math.min(stealthskill or 0, 15))
	return math.max(6, 45 - stealthskill * 3)
end

function Run()
	local Money = GetMoney("") 
	
	if Money < 800 then
		MsgQuick("", "@L_MEASURES_DIVEGETALC_FAIL_+2")
		return
	end	

	local cashskill = 0
	local secretskill = 0
	local stealthskill = 0
	if BuildingGetOwner("", "Besitzer") then
		-- chr_GetSkillValue caps at 15. The raw engine getter does not, and the
		-- price formula below divides by 100 and doubles: at raw Bargaining 50
		-- the goods become free, and above it the "price" turns negative and
		-- chr_SpendMoney would pay the owner to restock.
		cashskill = chr_GetSkillValue("Besitzer", BARGAINING)/100
		secretskill = chr_GetSkillValue("Besitzer", SECRET_KNOWLEDGE)
		stealthskill = chr_GetSkillValue("Besitzer", SHADOW_ARTS)
	else
		return
 	end

	-- Belt and braces: even if the cap above ever moves, a run never ends up
	-- free, negative, or hauling an unbounded shipment.
	local menge = math.max(1, math.min(math.floor(secretskill * 10), 150))
	local kostengrog = math.max(80, math.floor(800*(1-cashskill*2)))
	local kostenbrand = math.max(120, math.floor(1200*(1-cashskill*2)))
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
	
	-- The liquor is contraband, so a run can be intercepted and seized: the
	-- money is already spent above and the goods never arrive. Shadow Arts is
	-- what keeps the run quiet, so a skilled owner is rarely caught.
	if Rand(100) < ms_021_divegetalc_SeizureChance(stealthskill) then
		MsgQuick("", "@L_MEASURES_DIVEGETALC_FAIL_+2")
		return
	end
	
	AddItems("", alcId, menge, INVENTORY_STD)
	MsgQuick("", "@L_MEASURES_DIVEGETALC_SUCCESS_+0")
end

function CleanUp()
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end
