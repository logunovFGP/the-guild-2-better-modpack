function Run()

	if not BuildingGetCity("","City") then
		StopMeasure()
	end

	local diseases_infect = 
	{
	  {infected = 0, string = "Sprain", 	ItemCnt = 0},
	  {infected = 0, string = "Cold", 		ItemCnt = 0},
	  {infected = 0, string = "Influenza",  ItemCnt = 0},
	  {infected = 0, string = "Pox", 		ItemCnt = 0},
	  {infected = 0, string = "BurnWound",  ItemCnt = 0},
	  {infected = 0, string = "Pneumonia",  ItemCnt = 0},
	  {infected = 0, string = "Blackdeath", ItemCnt = 0},
	  {infected = 0, string = "Fracture", 	ItemCnt = 0},
	  {infected = 0, string = "Caries", 	ItemCnt = 0}
	}

	for i = 1,9 do
	  local index = diseases_infect[i]
	  index.ItemCnt = GetItemCount("", allDiseases[i]:getMedicine())
	  if HasProperty("City",index.string.."Infected") then
		index.infected = GetProperty("City",index.string.."Infected")
	  end
	end

	local index = diseases_infect
	MsgBoxNoWait("dynasty", "", 
						"@L_MEASURE_showdiseasedpeople_HEAD_+0",
						"@L_MEASURE_showdiseasedpeople_BODY_+0",
						GetID("City"), 
						"@L_ONSCREENHELP_9_ACTION_IMPACT_Sprain_NAME_+0", index[1].infected, index[1].ItemCnt, ItemGetLabel("Bandage",false), 
						"@L_ONSCREENHELP_9_ACTION_IMPACT_Cold_NAME_+0", index[2].infected, index[2].ItemCnt, ItemGetLabel("Bandage",false), 
						"@L_ONSCREENHELP_9_ACTION_IMPACT_Influenza_NAME_+0", index[3].infected, index[3].ItemCnt, ItemGetLabel("Medicine",false), 
						"@L_ONSCREENHELP_9_ACTION_IMPACT_Pox_NAME_+0", index[4].infected, index[4].ItemCnt, ItemGetLabel("Medicine",false), 
						"@L_ONSCREENHELP_9_ACTION_IMPACT_BurnWound_NAME_+0", index[5].infected, index[5].ItemCnt, ItemGetLabel("PainKiller",false),
						"@L_ONSCREENHELP_9_ACTION_IMPACT_Pneumonia_NAME_+0", index[6].infected, index[6].ItemCnt, ItemGetLabel("Medicine",false), 
						"@L_ONSCREENHELP_9_ACTION_IMPACT_Blackdeath_NAME_+0", index[7].infected, index[7].ItemCnt, ItemGetLabel("PainKiller",false), 
						"@L_ONSCREENHELP_9_ACTION_IMPACT_Fracture_NAME_+0", index[8].infected, index[8].ItemCnt, ItemGetLabel("PainKiller",false), 
						"@L_ONSCREENHELP_9_ACTION_IMPACT_Caries_NAME_+0", index[9].infected, index[9].ItemCnt, ItemGetLabel("PainKiller",false) )

end