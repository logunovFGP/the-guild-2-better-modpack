-- Modify range accordingly for more or less precision.
-- Owner is nil but can be set.
-- Kontors must be linked to a foreign Settlement.
function Run()
	GetSettlement("", "City")
	InitAlias("Target", MEASUREINIT_SELECTION, "", "Select where to construct this building.")
	GetPosition("Target", "TargetPosition")
	CityBuildNewBuilding("City", 491, nil, "Building", "TargetPosition", 25000)
end

-- Use this function to remove the ownership of any building, thus giving it to the settlement of your choice.
function RemoveBuildingOwnership()
	InitAlias("Target", MEASUREINIT_SELECTION, "", "Select the building to modify the ownership of.")

	if not AliasExists("Target") then
		return
	end

	DynastyCreate(-1, false, 0, "New", true)
 	BossCreate("", GL_GENDER_MALE, GL_CLASS_CHISELER, 5, "Boss")
	SimSetReligion("Boss", 0)
	DynastyAddMember("New", "Boss")

	BuildingSetOwner("Target", "Boss")
		
	if BuildingBuy("Target", "Boss", BM_CAPTURE) then
		MsgQuick("", "Success")
	else
		MsgQuick("", "Failure")
	end

	Kill("Boss")
	GetPosition("Target", "Position")
	GfxStartParticle("SchleierRauch", "particles/build.nif", "Position", 3.5)
	CameraTerrainSetPos("Position")
end

function CleanUp()

end