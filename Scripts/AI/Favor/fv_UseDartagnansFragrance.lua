function Weight()
	local	Item = "DartagnansFragrance"
	
	if GetMeasureRepeat("SIM", "Use"..Item)>0 then
		return 0
	end
	
	if GetItemCount("SIM", Item,INVENTORY_STD)>0 then
		return 25
	end

	if GetMoney("SIM") < 2000 then
		return 0
	end

	return 5
end

function Execute()
	MeasureRun("SIM", nil, "UseDartagnansFragrance")
end
