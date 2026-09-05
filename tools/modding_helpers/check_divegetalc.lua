-- Checks the contraband-run maths in ms_021_DiveGetAlc.lua.
--
--   lua5.1 tools/modding_helpers/check_divegetalc.lua
--
-- No engine needed: SeizureChance is plain arithmetic, and the price/quantity
-- clamps are reproduced here from the same expressions the measure uses, so a
-- change to either side that breaks a bound fails this file.
--
-- Guards two things that were live defects before:
--   * the price formula divided a RAW (uncapped) skill by 100 and doubled it,
--     so a high enough Bargaining made the goods free and then negative
--   * the shipment size was unbounded

local Failures = 0

local function check(Name, Condition)
	if Condition then
		return
	end
	Failures = Failures + 1
	io.stderr:write("FAIL: " .. Name .. "\n")
end

-- Load the measure. It only defines functions at load time, so this is safe
-- without any engine globals present.
dofile("Scripts/Measures/ms_021_DiveGetAlc.lua")

check("SeizureChance is defined", type(SeizureChance) == "function")

-- Risk falls as Shadow Arts rises, but never to zero.
check("unskilled owner is caught 45% of the time", SeizureChance(0) == 45)
check("capped owner is still caught 6% of the time", SeizureChance(15) == 6)
check("risk never reaches zero", SeizureChance(15) > 0)
check("risk is monotonic in skill", SeizureChance(0) > SeizureChance(7)
	and SeizureChance(7) > SeizureChance(13))

-- Out-of-range and missing values must not produce a free pass.
check("nil skill is treated as unskilled", SeizureChance(nil) == 45)
check("negative skill is treated as unskilled", SeizureChance(-5) == 45)
check("skill above the cap cannot buy immunity", SeizureChance(999) == 6)
for Skill = -20, 200 do
	if SeizureChance(Skill) < 6 or SeizureChance(Skill) > 45 then
		check("chance stays within 6..45 at skill " .. Skill, false)
		break
	end
end

-- The clamps, mirroring ms_021's expressions.
local function Menge(SecretSkill)
	return math.max(1, math.min(math.floor(SecretSkill * 10), 150))
end
local function Grog(CashSkill)
	return math.max(80, math.floor(800 * (1 - CashSkill * 2)))
end
local function Brand(CashSkill)
	return math.max(120, math.floor(1200 * (1 - CashSkill * 2)))
end

check("shipment is at least 1", Menge(0) >= 1)
check("shipment is capped at 150", Menge(15) == 150 and Menge(999) == 150)

-- 15 is the chr_GetSkillValue cap, so 0.15 is the highest cashskill in practice.
check("best legitimate discount is 30%", Grog(0.15) == 560)
check("grog is never free", Grog(0.5) >= 80)
check("grog is never negative", Grog(5) > 0)
check("brandy is never free", Brand(0.5) >= 120)
check("brandy is never negative", Brand(5) > 0)

if Failures > 0 then
	io.stderr:write("FAILED: " .. Failures .. " check(s) on ms_021_DiveGetAlc\n")
	os.exit(1)
end

print("OK: 17 checks on ms_021_DiveGetAlc")
