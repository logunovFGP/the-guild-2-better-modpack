--
-- OnLevelUp is called everytime the building level was changed, even when the building is build the first time.
-- This function is called bevor Setup
-- attention: this function call is unscheduled
--
function OnLevelUp()
end

function Run()
end

function Setup()
end

function PingHour()

	-- Check every worker every hour for bonuses from employer's abilities
	chr_CheckWorkerBonuses("")
	
	if BuildingGetOwner("", "MyBoss") and DynastyIsAI("MyBoss") then
		bld_CheckRepairs("")
	end
	
	GetScenario("World")
	if HasProperty("World", "messages") then
		if GetProperty("World", "messages") == 1 then
		--	if BuildingGetOwner("", "MyBoss") then
				MeasureRun("", "", "RandomEvents", false)
				return
		--	end
		end
	end
end
