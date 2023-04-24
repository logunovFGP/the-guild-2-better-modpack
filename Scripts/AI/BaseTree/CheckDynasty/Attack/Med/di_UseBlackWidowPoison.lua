function Weight()
	local	Item = "BlackWidowPoison"
	if GetMeasureRepeat("SIM", "Use"..Item)>0 then
		return 0
	end

	if GetItemCount("SIM", Item, INVENTORY_STD) > 0 then
		return 100
	end
	
	if GetMoney("SIM") < 2500 then
		return 0
	end

	local NumDynasties = ScenarioGetObjects("cl_Dynasty",99,"OutPutDyn")
	local MySettlementID = GetSettlementID("SIM")
	local Count
	local VictimNo
	
	for i=0,NumDynasties-1 do
		Count = DynastyGetMemberCount("OutPutDyn"..i)
		VictimNo = Rand(Count)
		if (DynastyGetMember("OutPutDyn"..i, VictimNo, "NewVictim")) then
			if GetSettlementID("NewVictim")==MySettlementID then	
				local DipToSim = DynastyGetDiplomacyState("dynasty","OutPutDyn"..i)
				if (DipToSim==DIP_FOE) and not (GetImpactValue("NewVictim","poisoned")>0) and not (GetDistance("SIM","NewVictim")>1500) then
					return 100
				end
			end
		end
	end
	
	return 0
end

function Execute()
	if not AliasExists("NewVictim") then
		CopyAlias("Victim", "NewVictim")
	end
	MeasureRun("SIM", "NewVictim", "UseBlackWidowPoison")
end
