function Weight()
	local	Item = "Cake"
	
	if GetMeasureRepeat("SIM", "Use"..Item)>0 then
		return 0
	end

	if GetFavorToDynasty("dynasty", "VictimDynasty") < 50 then
		return 0
	end
	
	if GetItemCount("SIM", Item,INVENTORY_STD)>0 then
		return 100
	end
	
	if GetMoney("SIM") < 2000 then
		return 0
	end

	return 10
end

function Execute()
	MeasureRun("SIM", "Victim", "UseCake")
end
