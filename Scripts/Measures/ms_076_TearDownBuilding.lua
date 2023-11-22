function AIDecision()
	return 1
end

function Run()

	if not chr_CheckDestroy() then
		return
	end

	local Value = BuildingGetValue("")* 0.35
	local Result = MsgNews("","","@P"..
			"@B[1,@L_REPLACEMENTS_BUTTONS_JA_+0]"..
			"@B[C,@L_REPLACEMENTS_BUTTONS_NEIN_+0]",
			ms_076_teardownbuilding_AIDecision,  --AIFunc
			"building", --MessageClass
			2, --TimeOut
			"@L_INTERFACE_TEARDOWN_MSG_HEAD_+0",
			"@L_INTERFACE_TEARDOWN_MSG_BODY_+0",
			GetID(""), Value)
			
	if Result == "C" then
		return
	end

	MeasureSetNotRestartable()
	
	-- kill spawned animals
	local filter ="__F( (Object.GetObjectsByRadius(Sim)==1300)AND(Object.GetProfession()<59)AND(Object.GetProfession()>54))"

	if filter then
		local k = Find("", filter, "PflegeViehs", 9)
		for l=0, k-1 do
			if AliasExists("PflegeViehs"..l) then
				InternalDie("PflegeViehs"..l)
				InternalRemove("PflegeViehs"..l)
			end
		end
	end
	
	if BuildingGetOwner("", "FormerOwner") then
		bld_ClearBuildingStash("", "FormerOwner")
	end
	chr_CreditMoney("", Value, "BuildingSold")
	SetState("", STATE_DEAD, true)
end
