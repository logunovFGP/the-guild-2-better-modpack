function Run()
	diseases_giveSickness("Sprain","",false)	
	diseases_giveSickness("Cold","",false) -- d
	diseases_giveSickness("Influenza","",false)
	diseases_giveSickness("BurnWound","",false)
	diseases_giveSickness("Pox","",false)
	diseases_giveSickness("Pneumonia","",false)
	diseases_giveSickness("Blackdeath","",false)
	diseases_giveSickness("Fracture","",false)
	diseases_giveSickness("Caries","",false)
	
	local result = InitData("@P"..
	"@B[btn1,verstauchung,verstauchung,Hud/Buttons/btn_005_GatherVermin.tga]"..
	"@B[btn2,erkaeltung,erkaeltung,Hud/Buttons/btn_009_dine.tga]"..
	"@B[btn3,grippe,grippe,Hud/Buttons/btn_012_WakeUpCall.tga]"..
	"@B[btn4,brandwunde,brandwunde,Hud/Buttons/btn_018_BuyAnimals.tga]"..
	"@B[btn5,pocken,pocken,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[btn6,lungenentzuendung,lungenentzuendung,Hud/Buttons/btn_027_BuildTariffHut.tga]"..
	"@B[btn7,pest,pest,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[btn8,knochenbruch,knochenbruch,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[btn9,zahnfaeule,zahnfaeule,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[btn10,statistik,statistik,Hud/Buttons/btn_019_SlaughterAnimals.tga]",
	ms_blackdeath_AIInit,
	"Welche Krankheit hättens denn gern?",
	"")

	if result=="btn1" then
		diseases_giveSickness("Sprain","",true,true)
	elseif result=="btn2" then
		diseases_giveSickness("Cold","",true,true)
	elseif result=="btn3" then
		diseases_giveSickness("Influenza","",true,true)
	elseif result=="btn4" then
		diseases_giveSickness("BurnWound","",true,true)
	elseif result=="btn5" then
		diseases_giveSickness("Pox","",true,true)
	elseif result=="btn6" then
		diseases_giveSickness("Pneumonia","",true,true)
	elseif result=="btn7" then
		diseases_giveSickness("Blackdeath","",true,true)
	elseif result=="btn8" then
		diseases_giveSickness("Fracture","",true,true)
	elseif result=="btn9" then
		diseases_giveSickness("Caries","",true,true)
	elseif result=="btn10" then
		GetSettlement("","City")
		local SprainInfected = GetProperty("City","SprainInfected")
		local ColdInfected = GetProperty("City","ColdInfected")
		local InfluenzaInfected = GetProperty("City","InfluenzaInfected")
		local BurnWoundInfected = GetProperty("City","BurnWoundInfected")
		local PoxInfected = GetProperty("City","PoxInfected")
		local PneumoniaInfected = GetProperty("City","PneumoniaInfected")
		local BlackdeathInfected = GetProperty("City","BlackdeathInfected")
		local FractureInfected = GetProperty("City","FractureInfected")
		local CariesInfected = GetProperty("City","CariesInfected")
		local InfectableSims = CityGetCitizenCount("City") / 4
		local CurrentInfected = GetProperty("City","InfectedSims")
		
		if not CurrentInfected then
			CurrentInfected = 0
		end
		if not InfectableSims then
			InfectableSims = 0
		end
		if not SprainInfected then
			SprainInfected = 0
		end
		if not ColdInfected then
			ColdInfected = 0
		end
		if not InfluenzaInfected then
			InfluenzaInfected = 0
		end
		if not BurnWoundInfected then
			BurnWoundInfected = 0
		end
		if not PoxInfected then
			PoxInfected = 0
		end
		if not PneumoniaInfected then
			PneumoniaInfected = 0
		end
		if not BlackdeathInfected then
			BlackdeathInfected = 0
		end
		if not FractureInfected then
			FractureInfected = 0
		end
		if not CariesInfected then
			CariesInfected = 0
		end

	MsgNewsNoWait("","","","politics",-1,"Krankheitsstatistik",""..CurrentInfected.." von "..InfectableSims.." Sims sind krank"..
					"$NVerstauchung: "..SprainInfected..""..
					"$NErkältung: "..ColdInfected..""..
					"$NGrippe: "..InfluenzaInfected..""..
					"$NBrandwunde: "..BurnWoundInfected..""..
					"$NPocken: "..PoxInfected..""..
					"$NLungenentzündung: "..PneumoniaInfected..""..
					"$NPest: "..BlackdeathInfected..""..
					"$NKnochenbruch: "..FractureInfected..""..
					"$NZahnfäule: "..CariesInfected.."")
		
	end
end

function AIInit()
	return "btn2"
end

