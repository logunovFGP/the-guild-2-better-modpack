-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_MineGuards"
----
----	With this measure the player who ones the mine can send out a mercenary to protect it
----  
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
		
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	-- Get the mine
		if not ai_GetWorkBuilding("", GL_BUILDING_TYPE_MINE, "Mine") then
			StopMeasure()
			return
		end
		
	if not chr_SpendMoney("", 1000, "misc") then
		StopMeasure()
	end

	if not GetHomeBuilding("", "Home") then
		CopyAlias("Mine", "Home")
	end
	
	local CurMeasID = GetCurrentMeasureID("")
	SetMeasureRepeat(TimeOut)
	
	-- Spawn the guards at the mine
	GetLocatorByName("Mine", "walledge2", "GuardSpawnPos")
	for i=0, 2 do
	local i = 0
		if not SimCreate(941, "Home", "GuardSpawnPos", "Guard"..i) then
			StopMeasure()
		else			
			local PosX, PosY, PosZ = GetWorldPositionXYZ("Mine")
			SetProperty("Guard"..i, "ProtectMine", GetID("Mine"))
			SetProperty("Guard"..i, "DestX", PosX+(400-Rand(600)))
			SetProperty("Guard"..i, "DestZ", PosZ+(200-Rand(400)))
			SetProperty("Guard"..i, "CurMeasID", CurMeasID)
			SetProperty("Guard"..i, "DynID", GetDynastyID(""))
			SimSetBehavior("Guard"..i, "MineGuardsDuty")
			
			-- Get the guard a weapon
			if not HasProperty("Guard"..i, "Equiped") then
				AddItems("Guard"..i, "LeatherArmor", 1, INVENTORY_EQUIPMENT)
				AddItems("Guard"..i, "IronCap", 1, INVENTORY_EQUIPMENT)
				AddItems("Guard"..i, "IronBrachelet", 1, INVENTORY_EQUIPMENT)
				AddItems("Guard"..i, "Longsword", 1, INVENTORY_EQUIPMENT)
				SetProperty("Guard"..i, "Equiped", 1)
				SetProperty("Guard"..i, "Guarding", 1)
			end

			CarryObject("Guard"..i, "Handheld_Device/ANIM_Shield3.nif", true)
			-- Get the destination position
			if not ScenarioCreatePosition(GetProperty("Guard"..i, "DestX"), GetProperty("Guard"..i, "DestZ"), "DestPos") then
				StopMeasure()
			end

			f_MoveTo("Guard"..i, "DestPos", GL_MOVESPEED_RUN)
			f_Stroll("Guard"..i, 400, 3)
			GfxRotateToAngle("Guard"..i, 0, Rand(360), 0, 1, true)
			-- Avert the guard from anything else but his duty !
			SetState("Guard"..i, STATE_NPCFIGHTER, true)
		end
	end	
end

-- -----------------------
-- GetOSHData
-- -----------------------
function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
	OSHSetMeasureCost("@L_INTERFACE_HEADER_+6", 1000)
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
end

