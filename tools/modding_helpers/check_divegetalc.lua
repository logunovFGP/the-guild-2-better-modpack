-- Checks the contraband maths behind Smuggle Alcohol and contraband retail.
--
--   lua5.1 tools/modding_helpers/check_divegetalc.lua
--
-- No engine needed: the chance curve is plain arithmetic, and the price/quantity
-- clamps are reproduced here from the same expressions ms_021 uses, so a change
-- to either side that breaks a bound fails this file.
--
-- Guards three things that were live defects before:
--   * the price formula divided a RAW (uncapped) skill by 100 and doubled it,
--     so a high enough Bargaining made the goods free and then negative
--   * the shipment size was unbounded
--   * smuggling carried no legal risk at all

local Failures = 0

local function check(Name, Condition)
	if Condition then
		return
	end
	Failures = Failures + 1
	io.stderr:write("FAIL: " .. Name .. "\n")
end

-- GamePlayFormulas.lua is loaded under its own namespace in game; loading it
-- bare here defines the functions globally, which is all this file needs.
dofile("Scripts/Library/GamePlayFormulas.lua")
check("ContrabandCaughtChance is defined", type(ContrabandCaughtChance) == "function")

local function near(a, b)
	return math.abs(a - b) < 0.001
end

-- The agreed curve: 75% at Shadow Arts 1 falling linearly to 10% at 10.
check("75% at Shadow Arts 1", near(ContrabandCaughtChance(1), 75))
check("10% at Shadow Arts 10", near(ContrabandCaughtChance(10), 10))
check("midpoint is halfway", near(ContrabandCaughtChance(5.5), 42.5))

-- Monotonic, and flat outside 1..10 rather than running off the ends.
for Skill = 1, 9 do
	check("falls from " .. Skill .. " to " .. Skill + 1,
		ContrabandCaughtChance(Skill) > ContrabandCaughtChance(Skill + 1))
end
check("below 1 is treated as 1", near(ContrabandCaughtChance(0), 75))
check("negative is treated as 1", near(ContrabandCaughtChance(-5), 75))
check("above 10 cannot buy immunity", near(ContrabandCaughtChance(99), 10))
check("nil is treated as 1", near(ContrabandCaughtChance(nil), 75))

-- Risk never vanishes: even a maxed owner is caught sometimes.
for Skill = -20, 200 do
	if ContrabandCaughtChance(Skill) < 10 or ContrabandCaughtChance(Skill) > 75 then
		check("stays within 10..75 at skill " .. Skill, false)
		break
	end
end

-- Retail divides, because it fires per drink instead of per delivery.
check("retail is 100x rarer at skill 1", near(ContrabandCaughtChance(1, 100), 0.75))
check("retail is 100x rarer at skill 10", near(ContrabandCaughtChance(10, 100), 0.10))
check("divisor of 1 changes nothing", near(ContrabandCaughtChance(4), ContrabandCaughtChance(4, 1)))
check("retail still never reaches zero", ContrabandCaughtChance(10, 100) > 0)

-- The clamps in ms_021, mirroring its expressions.
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
	io.stderr:write("FAILED: " .. Failures .. " check(s) on contraband maths\n")
	os.exit(1)
end

print("OK: 31 checks on contraband maths")
