function Weight()
	
	local Quote = GetHPRelative("SIM")
	if Quote > 0.85 then
		return 0
	end
	
	if not AliasExists("City") then
		if not GetSettlement("SIM", "City") then
			return 0
		end
	end
	
	if not CityGetNearestBuilding("City", "SIM", -1, GL_BUILDING_TYPE_LINGERPLACE, -1, -1, FILTER_IGNORE, "LingerPlace") then
		return 0
	end
	
	return 100
end


function Execute()
	MeasureRun("SIM", "LingerPlace", "Linger")
end

