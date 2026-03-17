function GetPrivilegeList()
	return "CurryFavor", "PropitiateEnemies", "DeliverTheFalseGauntlet"
end

function InitOffice()
	SetOfficePrivileges( "Office", ps_konsul_GetPrivilegeList() )
end

function TakeOffice(Messages)
	if (Messages == 1) then
		local AthmoLabel = "@L_CHARACTERS_3_OFFICES_NAME_Konsul_ATHMO_+0"
		f_StartHighPriorMusic(MUSIC_POSITIVE_EVENT)
		feedback_MessageOffice("",
			ps_konsul_GetPrivilegeList,
			"@L_PRIVILEGES_OFFICE_GAIN_HEAD_+0",
			"@L_PRIVILEGES_OFFICE_GAIN_BODY", GetID(""), GetSettlementID(""), AthmoLabel)
	end

	achievements_Unlock("", "POLITICS_KONSUL")

	chr_SetOfficeImpactList( "Office", ps_konsul_GetPrivilegeList() )
end

function LooseOffice(Messages)
	if (Messages == 1) then
		feedback_MessageOffice("",
			ps_konsul_GetPrivilegeList,
			"@L_PRIVILEGES_OFFICE_LOST_HEAD_+0",
			"@L_PRIVILEGES_OFFICE_LOST_BODY", GetID(""), GetSettlementID(""))
	end

	RemoveAllObjectDependendImpacts("", "Office")
end
 
