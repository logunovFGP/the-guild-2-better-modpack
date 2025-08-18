function Run()
	CopyAlias("","Workshop")
	local Choice
	local ResourceCount, Resources
	local ProductCount, Products
	
	repeat
		-- First dialog handles control: Help, Manage Resources, Manage Products, Done
		local Options = "@B[1,@L_TWP_MANAGESTORAGE_INITIATE_OPTION_+0,]".. -- Help
			"@B[2,@L_TWP_MANAGESTORAGE_INITIATE_OPTION_+1,]".. -- Choose Resources
			"@B[3,@L_TWP_MANAGESTORAGE_INITIATE_OPTION_+2,]" -- Choose Suppliers
		
		Choice = MsgBox("","Owner","@P"..Options,"@L_TWP_MANAGESTORAGE_INITIATE_HEAD_+0","", GetID("Workshop"))
		
		if Choice == 1 then
			MsgBox("", "Owner", "", "@L_TWP_MANAGESTORAGE_INITIATE_OPTION_+0", "@L_TWP_MANAGESTORAGE_HELP_BODY_+0")
		elseif Choice == 2 then
			ResourceCount, Resources = ms_twp_managestorage_ManageResources("")
		elseif Choice == 3 then
			ProductCount, Products = ms_twp_managestorage_ManageProducts("")
		elseif Choice == nil or Choice == "C" then -- cancel
			StopMeasure()
		end
	until Choice == 4 -- Start measure
end

function ManageProducts(BldAlias)
	--Make sure to use current values if they already exist
	local ProductCount, Products, ProtectedAmounts = economy_StorageGetProducts(BldAlias)
	for i = 1, ProductCount do
		ProtectedAmounts[i] = ProtectedAmounts[i] or 0
	end

	local ChosenItemId
	local Buttons = ""
	local Id, ItemTexture, Subtext
	local Tooltip = ""
	local BldType = BuildingGetType(BldAlias)

	local ChosenItem
	repeat
		Buttons = "@P"
		for i=1, ProductCount do
			Id = Products[i]
			ItemTexture = "Hud/Items/Item_"..ItemGetName(Id)..".tga"
			Tooltip = ItemGetLabel(Id, false)
			Subtext = ProtectedAmounts[i] or 0
			-- result, Tooltip, label, icon
			Buttons = Buttons.."@B[" .. i .. "," .. Subtext .. "," .. Tooltip .. "," .. ItemTexture .."]"
		end
		-- add extra button if warehouse and Count < 16
		if GL_BUILDING_TYPE_WAREHOUSE == BldType and ProductCount < 16 then
			Buttons = Buttons.."@B[" .. -1 .. ",,,hud/buttons/btn_220_Train.tga]"
		end
		Buttons = Buttons.."@B[C,@L_GENERAL_BUTTONS_OK_+0,@L_GENERAL_BUTTONS_OK_+0,Hud/Buttons/btn_Ok.tga]" 
		ChosenItem = InitData(
			Buttons, -- PanelParam
			0, -- AIFunc
			"@L_TWP_SALESCART_CHOOSEPRODUCT_HEAD_+0",-- HeaderLabel
			"Body"
		)
		if ChosenItem and ChosenItem == -1 then
			if ChosenItem == -1 then -- warehouse, add any available item from inventory
				BuildingGetOwner(BldAlias, "BldOwner")
				local NewItemId = economy_ChooseItemFromInventory(BldAlias, "BldOwner")
				if NewItemId then
					ProductCount = ProductCount + 1
					Products[ProductCount] = NewItemId
					ProtectedAmounts[ProductCount] = 0
					ChosenItem = ProductCount
				else
					ChosenItem = false
				end
			end
		end
		if ChosenItem and ChosenItem ~= "C" then
			local Options = "@B[-1,@L_TWP_SALESCART_CHOOSEAMOUNT_+0,]".. -- do not sell (for warehouse: remove entry)
											"@B[0,@L_TWP_SALESCART_CHOOSEAMOUNT_+1,]".. -- sell all
											"@B[10,@L_TWP_SALESCART_CHOOSEAMOUNT_+2,]".. -- leave 10 in storage
											"@B[20,@L_TWP_SALESCART_CHOOSEAMOUNT_+3,]".. -- leave 20 in storage
											"@B[40,@L_TWP_SALESCART_CHOOSEAMOUNT_+4,]".. -- leave 40 in storage
											"@B[80,@L_TWP_SALESCART_CHOOSEAMOUNT_+5,]"   -- leave 80 in storage
			local ItemId = Products[ChosenItem]
			local ChosenMinAmount = MsgBox("","Owner","@P"..Options,"@L_TWP_SALESCART_CHOOSEAMOUNT_HEAD_+0","_TWP_SALESCART_CHOOSEAMOUNT_BODY_+0", ItemGetLabel(ItemId,false))
			if ChosenMinAmount and ChosenMinAmount ~= "C" then
				if ChosenMinAmount >= 0 then
					ProtectedAmounts[ChosenItem] = ChosenMinAmount
				elseif GL_BUILDING_TYPE_WAREHOUSE == BldType then
					-- for warehouses, selecting no sales will remove the entry
					_, ProtectedAmounts = helpfuncs_RemoveElementFromList(ProtectedAmounts, ProductCount, ChosenItem)
					ProductCount, Products = helpfuncs_RemoveElementFromList(Products, ProductCount, ChosenItem)
				end
			end
			
		end
	until ChosenItem == nil or ChosenItem =="C"
	
	-- save changes at the end
	economy_StorageSaveProducts(BldAlias, ProductCount, Products, ProtectedAmounts)
	return ProductCount, Products, ProtectedAmounts
end

function ManageResources(BldAlias)
	--Make sure to use current values if they already exist
	local ResourceCount, Resources = economy_StorageGetResources(BldAlias)

	local ChosenItemId
	local Buttons = ""
	local Id, ItemTexture, Subtext
	local Tooltip = ""
	local BldType = BuildingGetType(BldAlias)

	local ChosenItem
	repeat
		Buttons = "@P"
		for i=1, ResourceCount do
			Id = Resources[i][1]
			ItemTexture = "Hud/Items/Item_"..ItemGetName(Id)..".tga"
			Tooltip = ItemGetLabel(Id, false)
			Subtext = Resources[i][2] or 0
			-- result, Tooltip, label, icon
			Buttons = Buttons.."@B[" .. i .. "," .. Subtext .. "," .. Tooltip .. "," .. ItemTexture .."]"
		end
		-- add extra button if warehouse and Count < 16
		if GL_BUILDING_TYPE_WAREHOUSE == BldType and ResourceCount < 16 then
			Buttons = Buttons.."@B[" .. -1 .. ",,,hud/buttons/btn_220_Train.tga]"
		end
		Buttons = Buttons.."@B[C,@L_GENERAL_BUTTONS_OK_+0,@L_GENERAL_BUTTONS_OK_+0,Hud/Buttons/btn_Ok.tga]" 
		ChosenItem = InitData(
			Buttons, -- PanelParam
			0, -- AIFunc
			"@L_TWP_SUPPLYWORKSHOP_CHOOSERESOURCE_HEAD_+0",-- HeaderLabel
			"Body"
		)
		if ChosenItem and ChosenItem == -1 then
			if ChosenItem == -1 then -- warehouse, add any available item from inventory
				BuildingGetOwner(BldAlias, "BldOwner")
				local NewItemId = economy_ChooseItemFromInventory(BldAlias, "BldOwner")
				if NewItemId then
					ResourceCount = ResourceCount + 1
					Resources[ResourceCount] = { NewItemId, 0 }
					ChosenItem = ResourceCount
				else
					ChosenItem = false
				end
			end
		end
		if ChosenItem and ChosenItem ~= "C" then
			local Options = ""
			if GL_BUILDING_TYPE_WAREHOUSE == BldType then
				Options = Options .. "@B[-1,@L_TWP_SUPPLYWORKSHOP_REMOVE_+0,]"
			end
			Options = Options .. "@B[80,80,]@B[60,60,]@B[50,50,]@B[40,40,]@B[30,30,]@B[20,20,]@B[10,10,]@B[0,0,]"
			local ItemId = Resources[ChosenItem][1]
			local ChosenMinAmount = MsgBox("","Owner","@P"..Options,"@L_TWP_SUPPLYWORKSHOP_CHOOSEAMOUNT_HEAD_+0","_TWP_SUPPLYWORKSHOP_CHOOSEAMOUNT_BODY_+0", ItemGetLabel(ItemId,false))
			if ChosenMinAmount and ChosenMinAmount ~= "C" then
				if ChosenMinAmount >= 0 then
					Resources[ChosenItem][2] = ChosenMinAmount
				elseif GL_BUILDING_TYPE_WAREHOUSE == BldType then
					-- for warehouses, selecting none will remove the entry
					ResourceCount, Resources = helpfuncs_RemoveElementFromList(Resources, ResourceCount, ChosenItem)
				end
			end
			
		end
	until ChosenItem == nil or ChosenItem =="C"
	
	-- save changes at the end
	economy_StorageSaveResources(BldAlias, ResourceCount, Resources)
	return ResourceCount, Resources
end




