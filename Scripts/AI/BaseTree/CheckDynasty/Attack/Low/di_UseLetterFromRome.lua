function Weight()
	local	Item = "LetterFromRome"
	
	if GetMeasureRepeat("SIM", "Use"..Item)>0 then
		return 0
	end
	
	if GetItemCount("SIM", Item, INVENTORY_STD)>0 then
		return 50
	end

	if GetMoney("SIM") < 2500 then
		return 0
	end

	return 10
end

function Execute()
	MeasureRun("SIM", "Victim", "UseLetterFromRome")
end
