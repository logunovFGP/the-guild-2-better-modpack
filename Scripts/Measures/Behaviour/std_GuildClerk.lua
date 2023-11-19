function Run()

	SetState("", STATE_TOWNNPC, true)
	SimSetMortal("", false)
	GetHomeBuilding("", "home")
	BuildingGetCity("home", "homecity")
	CityGetRandomBuilding("homecity", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "myguildhouse")

	local FindLocator = "GuildClerkPos"
	if GetFreeLocatorByName("myguildhouse", FindLocator, -1, -1, "destpos", false) then
		if f_BeginUseLocator("", "destpos", GL_STANCE_STAND, true) then
			SetExclusiveMeasure("", "StartDialog", EN_PASSIVE)
		end
	end
	
	if not AliasExists("destpos") then
		LogMessage("No Guild Clerk post found")
		StopMeasure()
	end

	while true do
		std_guildclerk_CheckAge()
		Sleep(600)
	end
end

function CheckAge()
	if SimGetAge("") > 65 then
		SimSetAge("", 60)
	end
end

function CleanUp()
	if AliasExists("destpos") then
		f_EndUseLocator("", "destpos", GL_STANCE_STAND)
	end
	AllowAllMeasures("")
end


