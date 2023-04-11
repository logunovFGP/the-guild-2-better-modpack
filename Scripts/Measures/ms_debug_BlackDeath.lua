function Run()
	diseases_removeAllSickness("")

	local result = InitData("@P"..
	"@B[Sprain,verstauchung,verstauchung,Hud/Buttons/btn_005_GatherVermin.tga]"..
	"@B[Cold,erkaeltung,erkaeltung,Hud/Buttons/btn_009_dine.tga]"..
	"@B[Influenza,grippe,grippe,Hud/Buttons/btn_012_WakeUpCall.tga]"..
	"@B[Pox,pocken,pocken,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[BurnWound,brandwunde,brandwunde,Hud/Buttons/btn_018_BuyAnimals.tga]"..
	"@B[Pneumonia,lungenentzuendung,lungenentzuendung,Hud/Buttons/btn_027_BuildTariffHut.tga]"..
	"@B[Blackdeath,pest,pest,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[Fracture,knochenbruch,knochenbruch,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[Caries,zahnfaeule,zahnfaeule,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[10,statistik,statistik,Hud/Buttons/btn_019_SlaughterAnimals.tga]",
	ms_blackdeath_AIInit,
	"What disease would you like to have?",
	"")

	if result ~= 10 and result ~= "C" then
		Disease.infectSim("",result)
		
	elseif result == 10 then

		GetSettlement("","City")

		local infections = {}
		for i = 1,9 do
			infections[i] = GetProperty("City",allDiseases[i].getName().."Infected") or 0
		end

		local InfectableSims = (CityGetCitizenCount("City") / 4) or 0
		local CurrentInfected = GetProperty("City","InfectedSims") or 0

	MsgNewsNoWait("","","","politics",-1,"Disease statistics",""..CurrentInfected.." of "..InfectableSims.." Sims are sick!"..
					"$NSprain: "..infections[1]..""..
					"$NCold: "..infections[2]..""..
					"$NInfluenza: "..infections[3]..""..
					"$NPox: "..infections[4]..""..
					"$NBurnWound: "..infections[5]..""..
					"$NPneumonia: "..infections[6]..""..
					"$NBlackdeath: "..infections[7]..""..
					"$NFracture: "..infections[8]..""..
					"$NCaries: "..infections[9].."")
		
	end
end

function AIInit()

end