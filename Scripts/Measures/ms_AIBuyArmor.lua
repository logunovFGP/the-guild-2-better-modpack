-------------------------------------------------------------------------------
----
----	OVERVIEW "AIBuyArmor.lua"
----
----	with this measure the AI buys an armor and uses it
----	Community Update: handles all armor slots (head/body/hands), not only body
----
-------------------------------------------------------------------------------
function Run()
	
	local ItemName
	
	if HasProperty("", "AIBuyArmor") then
		ItemName = GetProperty("", "AIBuyArmor")
	else
		return
	end
	
	-- Buy the item
	if GetItemCount("", ItemName, INVENTORY_STD) == 0 and GetItemCount("", ItemName, INVENTORY_EQUIPMENT) == 0 then
		if not ai_BuyItem("", ItemName, 1, INVENTORY_STD) then
			return
		end
	end
	
	-- Animation
	local Time = PlayAnimationNoWait("", "use_object_standing")
	Sleep(0.5)
	PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
	Sleep(Time-2)
	MsgSay("", "@L_BUYARMOR_COMMENT")
	Sleep (0.5)
	
	if GetItemCount("", ItemName) > 0 then
	
		-- Equip directly if the item's slot is free
		if GetRemainingInventorySpace("", ItemName, INVENTORY_EQUIPMENT) > 0 then
			RemoveItems("", ItemName, 1, INVENTORY_STD)
			AddItems("", ItemName, 1, INVENTORY_EQUIPMENT)
		
		else
			-- slot occupied: swap out a worse piece of the same slot, if any.
			-- epics are not listed, so they never get swapped out.
			local Slots = {
				{ "LeatherArmor", "WarCuirass", "Chainmail", "Platemail" },
				{ "IronCap", "FullHelmet" },
				{ "IronBrachelet", "LeatherGloves" },
			}
			
			-- locate ItemName's slot list and its tier index
			local slot
			local idx
			local s = 1
			while Slots[s] do
				local i = 1
				while Slots[s][i] do
					if Slots[s][i] == ItemName then
						slot = Slots[s]
						idx = i
					end
					i = i + 1
				end
				s = s + 1
			end

			if slot then
				-- remove the first equipped piece lower than ItemName, then equip it
				local done = false
				local j = 1
				while j < idx and not done do
					if GetItemCount("", slot[j], INVENTORY_EQUIPMENT) > 0 then
						RemoveItems("", slot[j], 1, INVENTORY_EQUIPMENT)
						RemoveItems("", ItemName, 1, INVENTORY_STD)
						AddItems("", ItemName, 1, INVENTORY_EQUIPMENT)
						done = true
					end
					j = j + 1
				end
			end
		end
	end
	StopMeasure()
end

function CleanUp()
	if HasProperty("", "AIBuyArmor") then
		RemoveProperty("", "AIBuyArmor")
	end
end
