function NeedMore(ItemName, ItemId)

	local count = GetItemCount("Hut", ItemName, INVENTORY_STD)

	local keep = 0
	if GetInventory("Hut", INVENTORY_STD, "FishStd") then
		keep = GetProperty("FishStd", "Keep_"..ItemId) or 0
		if keep <= 0 then
			keep = GetProperty("FishStd", "Need_"..ItemId) or 0
		end
	end

	if keep > 0 then
		return count < keep
	end

	local maxcount = InventoryGetSlotSize("Hut", ItemName, INVENTORY_STD) - 10
	return count < maxcount
end

function ProductWants(ProductName, ProductId)

	if not GetInventory("Hut", INVENTORY_STD, "FishStd") then
		return false
	end

	local off = GetProperty("FishStd", "NoProduce_"..ProductId) or 0
	if off ~= 0 then
		return false
	end

	local keep = GetProperty("FishStd", "Keep_"..ProductId) or 0
	if keep <= 0 then
		keep = GetProperty("FishStd", "Need_"..ProductId) or 0
	end

	if keep <= 0 then
		return true
	end

	return GetItemCount("Hut", ProductName, INVENTORY_STD) < keep
end


function Weight()
	if not GetHomeBuilding("", "Hut") then
		return 0
	end

	if fish_dofishing_ProductWants("FriedHerring", GL_ITEM_FRIEDHERRING) then
		if fish_dofishing_NeedMore("Herring", GL_ITEM_HERRING) then
			if ResourceFind("Hut","Herring","Resource", true) then
				return 100
			end
		end
	end

	if fish_dofishing_ProductWants("SmokedSalmon", GL_ITEM_SMOKEDSALMON) then
		if fish_dofishing_NeedMore("Salmon", GL_ITEM_SALMON) then
			if ResourceFind("Hut","Salmon","Resource", true) then
				return 100
			end
		end
	end

	if fish_dofishing_NeedMore("Herring", GL_ITEM_HERRING) then
		if ResourceFind("Hut","Herring","Resource", true) then
			return 60
		end
	end

	if fish_dofishing_NeedMore("Salmon", GL_ITEM_SALMON) then
		if ResourceFind("Hut","Salmon","Resource", true) then
			return 60
		end
	end

	return 0

end

function Execute()
	MeasureRun("", "Resource", "Fishing")
end
