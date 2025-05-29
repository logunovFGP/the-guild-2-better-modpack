function Run()
	local Element = FindNode("\\application\\game\\Hud")
	Element:ShowPanel("RentRoom", true)

	Element 	= FindNode("\\GUI\\HudRoot")
	local Beds	= {Element:FindChildDepth("Bed01"), Element:FindChildDepth("Bed02"), Element:FindChildDepth("Bed03")}

	if not HasProperty("", "AmountBeds") then
		SetProperty("", "AmountBeds", 3)
	end

	local Amount = GetProperty("", "AmountBeds")

	for i = 1, Amount do
		if not HasProperty("", "StatusBed"..i) then
			SetProperty("", "StatusBed"..i, "Vacant")
		end

		if not HasProperty("", "BedMoney"..i) then
			SetProperty("", "BedMoney"..i, 0)
		end

		local Data = {Image=Beds[i]:FindChildDepth("Bed"), Status=Beds[i]:FindChildDepth("Status")}

		Data.Image:SetValueString("TITLE", "Money made: " .. GetProperty("", "BedMoney"..i))

		local isOccupied = GetProperty("", "StatusBed"..i)

		LogMessage("@TAVERN ID: " .. isOccupied)

		if isOccupied ~= "Vacant" then
			if GetAliasByID(isOccupied, "Guest") then
				Data.Status:SetValueString("TEXT", GetName("Guest"))
			else
				Data.Status:SetValueString("TEXT", "Occupied")
			end
		else
			Data.Status:SetValueString("TEXT", "Vacant")
		end
	end
end

function CleanUp()

end

function OnButtonPressed_Close(x, y, device, key)
	local Element = FindNode("\\application\\game\\Hud")
	Element:ShowPanel("RentRoom", false)
end

function OnButtonPressed_SetPrice(x, y, device, key)
	local Price = this:GetValueInt("Price")
	Price = Price + 1

	if Price > 6 then
		Price = 1
	end

	this:SetValueInt("Price", Price)

	this:SetValueString("PTEXTURE", "Hud/tavern_rent_room/0"..Price.."_PriceP.tga")
	this:SetValueString("RTEXTURE", "Hud/tavern_rent_room/0"..Price.."_Price.tga")

	this:SetValueString("TITLE", "@L_LODGE_PRICE_FOR_BED_+"..Price)
end