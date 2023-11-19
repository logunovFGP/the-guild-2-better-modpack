function onEnter() 
	--LogText("ms_DiseasedBuilding::onEnter")
	if CheckSkill("", 1, 4) then
		if IsDynastySim("") then
			if not GetState("", STATE_SICK) then
				Disease.Cold:infectSim("")
				feedback_MessageCharacter("","@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_DYNSIM_HEAD_+0",
							"@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_DYNSIM_BODY_+0",GetID(""))
			end
		else
			if not GetState("", STATE_SICK) then
				Disease.Influenza:infectSim("")
				feedback_MessageCharacter("","@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_WORKER_HEAD_+0",
							"@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_WORKER_BODY_+0",GetID(""))
				--SimStopMeasure("")
			end
		end			
	end
end

function onExit()
	if CheckSkill("", 1, 4) then
		if IsDynastySim("") then
			if not GetState("", STATE_SICK) then
				Disease.Cold:infectSim("")
				feedback_MessageCharacter("","@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_DYNSIM_HEAD_+0",
							"@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_DYNSIM_BODY_+0",GetID(""))
			end
		else
			if not GetState("", STATE_SICK) then
				Disease.Influenza:infectSim("")
				feedback_MessageCharacter("","@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_WORKER_HEAD_+0",
							"@L_ARTEFACTS_178_USETOADSLIME_MSG_VICTIM_WORKER_BODY_+0",GetID(""))
				--SimStopMeasure("")
			end
		end			
	end
end
