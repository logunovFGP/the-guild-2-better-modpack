function Run()
	GetSettlement("", "Settlement")

	InitAlias("Cart", MEASUREINIT_SELECTION, "", "Select the cart to check the inventory of.")

	if AliasExists("Cart") then
		Count = InventoryGetSlotCount("Cart", INVENTORY_STD)
		LogMessage("@CART " .. GetName("Cart") .. "'s inventory count is " .. Count)
		local _ID, _COUNT
		for i = 0, Count - 1 do
			_ID, _COUNT = InventoryGetSlotInfo("Cart", i)
			LogMessage("@CART Slot #" .. i + 1 .. " contains x" .._COUNT .. " " .. ItemGetName(_ID) .. "(s)")
		end
	end

	if AliasExists("Cart") then
		return
	end


	InitAlias("Object", MEASUREINIT_SELECTION, "", "Select the object to remove ownership from.")

	GetPosition("", "Spawn")



	SimCreate(918, "", "Spawn", "Boy")
	GetDynasty("Boy", "MyDynasty")

	--DynastyAddMember("MyDynasty", "Boy")

	Sleep(1)

	

	--BuildingSetOwner("Object", "")

	BuildingBuy("Object", "", BM_CAPTURE)


	local Class = BuildingGetCharacterClass("Object")

	LogMessage("@NAO Character Class is " .. Class .. ".")

	if GetDynasty("Object", "Dynasty") then
		LogMessage("@NAO Dynasty is found (" .. GetName("Dynasty") .. ").")
	end

	SetProperty("Object", "Dynasty", GetID(""))

	local DynastyID = GetDynastyID("Object")
	LogMessage("@NAO Dynasty ID is " .. DynastyID)

	if BuildingGetOwner("Object", "TheOwner") then
		LogMessage("@NAO Found the owner of " .. GetName("Object") .. " that is " .. GetName("TheOwner") .. ".")
	else
		LogMessage("@NAO Found no owner of " .. GetName("Object") .. ".")
		return
	end



	LogMessage("@NAO Name: " .. GetName("Object"))

	--InitAlias("Position", MEASUREINIT_SELECTION, "", "Select where to move it to.")

	GetPosition("Object", "Position")

	--local x, y, z = PositionGetVector("Position")

	GfxStartParticle("SchleierRauch", "particles/build.nif", "Position", 3.5)

		--Sleep(2)
		-- Position: x= y= z=
		--SetPosition("Object", -18285.48, -797.33, 15550.82)

		--GetPosition("Object", "Position")

		--CameraTerrainSetPos("Position")

end

function CleanUp()

end