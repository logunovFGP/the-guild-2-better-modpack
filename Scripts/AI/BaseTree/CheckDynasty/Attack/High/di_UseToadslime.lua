function Weight()
	local	Item = "Toadslime"
	if GetMeasureRepeat("SIM", "Use"..Item)>0 then
		return 0
	end
	
	if GetMoney("dynasty") < 2000 then
		return 0
	end

	local NumDynasties = ScenarioGetObjects("cl_Dynasty",99,"OutPutDyn")
	local MySettlementID = GetSettlementID("SIM")
	local Count
	local VictimNo
	
	for i=0,NumDynasties-1 do
		Count = DynastyGetMemberCount("OutPutDyn"..i)
		VictimNo = Rand(Count)
		if (DynastyGetMember("OutPutDyn"..i, VictimNo, "Victim")) then
			if GetSettlementID("Victim")==MySettlementID then	
				local DipToSim = DynastyGetDiplomacyState("dynasty","OutPutDyn"..i)
				if (DipToSim==DIP_FOE) then
					for x=0,3 do
						if DynastyGetRandomBuilding("Dynasty", nil, nil, "VicBuilding") and not (GetImpactValue("VicBuilding","toadslime")>0) and not (GetDistance("","VicBuilding")>1500) then
							if gameplayformulas_checkBuildingNoRoom("VicBuilding")==0 then
								return 100
							end
						end
					end
				end
			end
		end
	end
	
	return 0
end

function Execute()
	MeasureRun("SIM", "VicBuilding", "UseToadslime")
end
