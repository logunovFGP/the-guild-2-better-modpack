function Run()
	-- children run
	if SimGetAge("") <= 16 then
		return "Flee"
	end

	-- spies ignore fires
	if GetImpactValue("", "spying") == 1 then 
		return ""
	end
	
	-- mine guards ignore fire
	if HasProperty("", "Guarding") then 
		return ""
	end

	-- Hijackers will ignore fire
	if GetCurrentMeasureName("") == "SquadHijackMember"  then
		return ""
	end

	-- protection money pressers will ignore fires
	if GetState("", STATE_ROBBERGUARD) then
		return ""
	end

	-- city guards will help
	if (SimGetProfession("")==GL_PROFESSION_CITYGUARD or SimGetProfession("")==GL_PROFESSION_ELITEGUARD) then
		return "PutoutFire"
	end
	
	-- Employees will help to put fire out if Favor to boss is high enough
	if SimGetWorkingPlaceID("Owner") == GetID("Actor") then
		if BuildingGetOwner("Actor", "BuildingOwner") then
			if GetFavorToSim("Owner", "BuildingOwner") > 40 then
				return "PutoutFire"
			else
				SetData("Distance", 1000)
				return "Gape"
			end
		end
	end
	
	-- protect your home
	if GetHomeBuildingId("") == GetID("Actor") then
		return "PutoutFire"
	end

	-- case for myrmidons
	local DynID = GetDynastyID("")
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		if GetImpactValue("Actor", "buildingbombedby") == DynID then
			return ""
		else
			if DynID == GetDynastyID("Actor") then
				return "PutoutFire"
			end
		end
	end
	
	local State
	State = DynastyGetDiplomacyState("", "Actor")
	
	-- diplomacy
	if GetDynasty("Actor", "ActorDyn") then
		if GetFavorToDynasty("", "ActorDyn") >= 60 then
			return "PutoutFire"
		end

		if State >= DIP_ALLIANCE then
			return "PutoutFire"
		end
	
		if State < DIP_NEUTRAL then
			SetData("Distance", 1000)
			return "Gape"
		end
	end 
	
	-- good guys help
	if SimGetAlignment("") <= 45 then
		return "PutoutFire"
	end
	
	-- all others flee
	SetData("Distance", 1500)
	return "Flee"
end

