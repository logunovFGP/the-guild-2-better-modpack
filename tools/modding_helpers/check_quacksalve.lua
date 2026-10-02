-- Checks the Quacksalve maths: favour a buyer loses per miracle cure sold, the lampoon chance.
--
--   lua5.1 tools/modding_helpers/check_quacksalve.lua
--
-- No engine needed. The spec, as agreed:
--   loss           = max(4 - difficulty, ceil((5 + difficulty) * (1 - rhetoric / 10)))
--   lampoon chance = 7 * difficulty percent
-- with difficulty 0 (Very easy) .. 4 (Very difficult).

local Failures = 0
local NL = string.char(10)

local function check(Name, Condition)
	if Condition then
		return
	end
	Failures = Failures + 1
	io.stderr:write("FAIL: " .. Name .. NL)
end

dofile("Scripts/Library/GamePlayFormulas.lua")
check("QuackFavorLoss is defined", type(QuackFavorLoss) == "function")
check("QuackPamphletChance is defined", type(QuackPamphletChance) == "function")

-- the whole table: rhetoric 0..12 across, difficulty 0..4 down
local Expected = {
	[0] = { 5, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4 },
	[1] = { 6, 6, 5, 5, 4, 3, 3, 3, 3, 3, 3, 3, 3 },
	[2] = { 7, 7, 6, 5, 5, 4, 3, 3, 2, 2, 2, 2, 2 },
	[3] = { 8, 8, 7, 6, 5, 4, 4, 3, 2, 1, 1, 1, 1 },
	[4] = { 9, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0, 0 },
}
for D = 0, 4 do
	for R = 0, 12 do
		local Got = QuackFavorLoss(R, D)
		check("loss at difficulty " .. D .. ", rhetoric " .. R .. " is " .. Expected[D][R + 1] .. " (got " .. Got .. ")",
			Got == Expected[D][R + 1])
	end
end

-- the two outcomes the spec was written to produce
for D = 0, 3 do
	check("below Very difficult even rhetoric 12 still costs favour (difficulty " .. D .. ")", QuackFavorLoss(12, D) > 0)
end
check("on Very difficult rhetoric 12 costs no favour", QuackFavorLoss(12, 4) == 0)
for D = 0, 4 do
	for R = 0, 12 do
		check("a sale never gains favour", QuackFavorLoss(R, D) >= 0)
	end
end

-- gameplayformulas_ is the in-game name; bare dofile defines the functions unprefixed
gameplayformulas_QuackLevelBonus = QuackLevelBonus

check("no level bonus up to level 4", QuackLevelBonus(1) == 0 and QuackLevelBonus(4) == 0)
check("level bonus starts at level 5", QuackLevelBonus(5) == 1)
check("level 10 carries +6", QuackLevelBonus(10) == 6)
check("pitch is rhetoric plus level bonus", QuackPitch(7, 8) == 11 and QuackPitch(7, 3) == 7)

-- prices with the bargaining roll at 0 (Roll at its mean of 20; Rand(41) is 0..40)
check("a mid seller (R5 B5 L5) floors at 152", QuackPrice(5, 5, 5, 20, 0) == 152)
check("a novice (R2 B1 L1) floors at 78", QuackPrice(2, 1, 1, 20, 0) == 78)
check("a maxed seller (R10 B10 L10) floors at 302", QuackPrice(10, 10, 10, 20, 0) == 302)
check("each bargaining point earns 8..13", QuackPrice(5, 5, 5, 0, 5) - QuackPrice(5, 5, 5, 0, 0) == 25)
check("the bargaining roll tops out at 13 per point", QuackPrice(0, 10, 1, 0, 5) - QuackPrice(0, 0, 1, 0, 0) == 130)
local function mean(R, B, L)
	local Sum = 0
	for BR = 0, 5 do Sum = Sum + QuackPrice(R, B, L, 20, BR) end
	return Sum / 6
end
check("a mid seller averages about 165", mean(5, 5, 5) == 164.5)
check("a maxed seller averages about 327", mean(10, 10, 10) == 327)
check("the random part spans 40", QuackPrice(5, 5, 5, 40) - QuackPrice(5, 5, 5, 0) == 40)
check("a cure is never free", QuackPrice(0, 0, 1, 0) > 0)
check("bargaining raises the price", QuackPrice(5, 6, 5, 0) > QuackPrice(5, 5, 5, 0))
check("rhetoric raises the price", QuackPrice(6, 5, 5, 0) > QuackPrice(5, 5, 5, 0))
check("level below 5 does not change the price", QuackPrice(5, 5, 1, 0) == QuackPrice(5, 5, 4, 0))
check("level above 4 raises the price", QuackPrice(5, 5, 6, 0) > QuackPrice(5, 5, 5, 0))

check("no lampoons on Very easy", QuackPamphletChance(0) == 0)
check("28% lampoon chance on Very difficult", QuackPamphletChance(4) == 28)

if Failures > 0 then
	io.stderr:write("FAILED: " .. Failures .. " check(s) on Quacksalve maths" .. NL)
	os.exit(1)
end

print("OK: Quacksalve maths (favour, lampoons, pitch, price)")
