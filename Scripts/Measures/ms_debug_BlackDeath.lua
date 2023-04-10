function Run()
	diseases_removeSickness("")
	
	local result = InitData("@P"..
	"@B[1,verstauchung,verstauchung,Hud/Buttons/btn_005_GatherVermin.tga]"..
	"@B[2,erkaeltung,erkaeltung,Hud/Buttons/btn_009_dine.tga]"..
	"@B[3,grippe,grippe,Hud/Buttons/btn_012_WakeUpCall.tga]"..
	"@B[4,pocken,pocken,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[5,brandwunde,brandwunde,Hud/Buttons/btn_018_BuyAnimals.tga]"..
	"@B[6,lungenentzuendung,lungenentzuendung,Hud/Buttons/btn_027_BuildTariffHut.tga]"..
	"@B[7,pest,pest,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[8,knochenbruch,knochenbruch,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[9,zahnfaeule,zahnfaeule,Hud/Buttons/btn_019_SlaughterAnimals.tga]"..
	"@B[10,statistik,statistik,Hud/Buttons/btn_019_SlaughterAnimals.tga]",
	ms_blackdeath_AIInit,
	"What disease would you like to have?",
	"")

	local data = allDiseases[result] or false
	if not data == false then
		data.infectSim("",true)
	elseif result == 10 then

		GetSettlement("","City")

		local infections = {}
		for i = 1,9 do
			infections[i] = GetProperty("City",allDiseases[i].name.."Infected") or 0
		end

		local InfectableSims = (CityGetCitizenCount("City") / 4) or 0
		local CurrentInfected = GetProperty("City","InfectedSims") or 0

	MsgNewsNoWait("","","","politics",-1,"Disease statistics",""..CurrentInfected.." of "..InfectableSims.." Sims are sick!"..
					"$NVerstauchung: "..infections[1]..""..
					"$NErkältung: "..infections[2]..""..
					"$NGrippe: "..infections[3]..""..
					"$NPocken: "..infections[4]..""..
					"$NBrandwunde: "..infections[5]..""..
					"$NLungenentzündung: "..infections[6]..""..
					"$NPest: "..infections[7]..""..
					"$NKnochenbruch: "..infections[8]..""..
					"$NZahnfäule: "..infections[9].."")
		
	end
end

function AIInit()

end