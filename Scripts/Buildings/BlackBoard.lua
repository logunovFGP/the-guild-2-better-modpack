--
-- Setup is called after the building is build. The function is called after OnLevelUp
-- attention: this function call is unscheduled
--
function Setup()
	if not HasProperty("", "PamphletCnt") then
		SetProperty("", "PamphletCnt", 0)
	end
end

function PingHour()
	local PamphletToRemove
	for i=0, 3 do
		if HasProperty("", "Pamphlet_"..i) then
				local DynID = GetProperty("", "Pamphlet_"..i)
				if DynID and GetAliasByID(DynID, "PamTarget"..i) and AliasExists("PamTarget"..i) then
					if not PamphletToRemove and Rand(100) < 8 then -- some chance for the pamphlet to just wither away
						PamphletToRemove = i
					end
				else
					-- invalid ID, remove pamphlet
					PamphletToRemove = i
				end
		end
	end
	
	if PamphletToRemove and BlackBoardRemovePamphlet("", PamphletToRemove) then
		if HasProperty("", "Pamphlet_"..PamphletToRemove) then
			RemoveProperty("", "Pamphlet_"..PamphletToRemove)
		end

		if HasProperty("", "Pamphlet_"..PamphletToRemove.."Dur") then
			RemoveProperty("", "Pamphlet_"..PamphletToRemove.."Dur")
		end
	end
end

function Run()
end

function OnLevelUp()
end
