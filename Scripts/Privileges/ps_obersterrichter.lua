function GetPrivilegeList()
	return "HaveImmunity", "Set_SeverityOfLaw", "BeVenerability"
end

function InitOffice()
	SetOfficePrivileges( "Office", ps_obersterrichter_GetPrivilegeList() )
end


function TakeOffice(Messages)
	if (Messages == 1) then
		local AthmoLabel = "@L_CHARACTERS_3_OFFICES_NAME_Obersterrichter_ATHMO_+0"
		gameplayformulas_StartHighPriorMusic(MUSIC_POSITIVE_EVENT)
		feedback_MessageOffice("",
			ps_obersterrichter_GetPrivilegeList,
			"@L_PRIVILEGES_OFFICE_GAIN_HEAD_+0",
			"@L_PRIVILEGES_OFFICE_GAIN_BODY", GetID(""), GetSettlementID(""), AthmoLabel)
	end
	
	-- Remove the "HasRepealedImmunity" impact
	if GetImpactValue("", "HasRepealedImmunity") ~= 0 then
		RemoveImpact("", "HasRepealedImmunity")
	end
	
	chr_SetOfficeImpactList( "Office", ps_obersterrichter_GetPrivilegeList() )
end

function LooseOffice(Messages)
	if (Messages == 1) then
		feedback_MessageOffice("",
			ps_obersterrichter_GetPrivilegeList,
			"@L_PRIVILEGES_OFFICE_LOST_HEAD_+0",
			"@L_PRIVILEGES_OFFICE_LOST_BODY", GetID(""), GetSettlementID(""))
	end

	RemoveAllObjectDependendImpacts( "", "Office" )
end
 
