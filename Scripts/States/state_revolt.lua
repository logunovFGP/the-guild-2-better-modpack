function Init()
end

function Run()

	if IsType("", "Sim") then
		if GetImpactValue("", "REVOLT") == 1 then
			CommitAction("revolt", "", "")
			while GetImpactValue("", "REVOLT") > 0 do
				if GetState("", STATE_UNCONSCIOUS, true) then
					RemoveImpact("", "REVOLT")
					SetState("", STATE_DEAD, true)
					SetState("", STATE_UNCONSCIOUS, false)
				else
					Sleep(10)
				end
			end
			
			StopAction("revolt", "")
			SetState("", STATE_REVOLT, false)
			return
		end
	end
end

function CleanUp()

	SetState("Owner", STATE_REVOLT, false)
end

