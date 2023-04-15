function Run()

	if GetImpactValue("", "spying") == 1 then
		return ""
	end
	
	local WatcherProf = SimGetProfession("Owner")

	if WatcherProf == GL_PROFESSION_CITYGUARD or WatcherProf == GL_PROFESSION_ELITEGUARD then
		CopyAlias("Actor", "Destination")
		return "InspectArea"
	end
	
	if WatcherProf == GL_PROFESSION_MYRMIDON then
		-- it's a thug, so check if this a thug from a friendly dynasty
		if GetDynasty("Actor", "ActorDynasty") and GetDynasty("Owner", "OwnerDynasty") then
			if DynastyGetDiplomacyState("ActorDynasty","OwnerDynasty") == DIP_ALLIANCE then
				CopyAlias("Actor", "Destination")
				return "InspectArea"
			end
		end
	end

	return ""
end
