function Run()

	-- send the message to the user
	local Gender = SimGetGender("")
	local HeaderLabel, BodyLabel, SubstLabel, HeaderAlt
	
	if (Gender == GL_GENDER_MALE) then
		HeaderLabel = "@L_FAMILY_2_COHABITATION_BIRTH_MESSAGE_HEAD_SON_+0";
		HeaderAlt = "@L_FAMILY_2_COHABITATION_BIRTH_MESSAGE_HEAD_SON_+1"; 
		BodyLabel = "@L_FAMILY_2_COHABITATION_BIRTH_MESSAGE_BODY_SON_+0";
		SubstLabel = "@L_FAMILY_2_COHABITATION_BIRTH_BAPTISM_SON_+0";
	else
		HeaderLabel = "@L_FAMILY_2_COHABITATION_BIRTH_MESSAGE_HEAD_DAUGHTER_+0";
		HeaderAlt = "@L_FAMILY_2_COHABITATION_BIRTH_MESSAGE_HEAD_DAUGHTER_+1"; 
		BodyLabel = "@L_FAMILY_2_COHABITATION_BIRTH_MESSAGE_BODY_DAUGHTER_+0";
		SubstLabel = "@L_FAMILY_2_COHABITATION_BIRTH_BAPTISM_DAUGHTER_+0";
	end
	
	local PanelParam = "@N".."@B[0,@L_FAMILY_2_COHABITATION_BIRTH_BAPTISM_BTN_+1]"    
	
	if AliasExists("SetName") then
		PanelParam = "MB_OK"    		
		SubstLabel = ""
	end
	
	SimGetSpouse("Destination", "Spouse")
	if (IsPartyMember("Destination") or IsPartyMember("Spouse")) then
		MsgNews("Destination", "", PanelParam, 0, "default", 1, HeaderLabel, BodyLabel, GetID("Destination"), SubstLabel)
	else
		MsgNews("dynasty", "", PanelParam, 0, "default", 1, HeaderAlt, BodyLabel, GetID("Destination"), SubstLabel)
	end	
end
