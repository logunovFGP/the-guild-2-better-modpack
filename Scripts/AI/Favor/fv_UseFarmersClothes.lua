function Weight()
	local	Item = "FarmersClothes"
	local value = ai_CheckTitleVSJewellery("SIM",1,20)

	if GetMeasureRepeat("SIM", "Use"..Item)>0 then
		return 0
	end
	
	if GetItemCount("SIM", Item,INVENTORY_STD)>0 then
		value = value + 30
		return value
	end

	if GetMoney("SIM") < 2000 then
		return 0
	end

	return value
end

function Execute()
	MeasureRun("SIM", nil, "UseFarmersClothes")
end
