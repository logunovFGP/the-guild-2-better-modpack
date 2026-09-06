-- Checks ai_MakeDecision in Scripts/Library/AI.lua.
--
--   lua5.1 tools/modding_helpers/check_ai_decision.lua
--
-- No engine needed: the natives MakeDecision touches are stubbed below and Rand
-- is scripted, so every roll is exact rather than statistical.
--
-- Guards three things that were live defects before:
--   * the one-trait path returned the number 0, which is truthy in Lua, so the
--     bribe check in ms_041 accepted every bribe
--   * `value + Mod or 0` bound as `(value + Mod) or 0`, so a missing column still
--     errored on the addition instead of counting as 0
--   * the one-trait roll compared Rand(trait) against nothing; it is a percentage now

local Failures = 0

local function check(Name, Condition)
	if Condition then
		return
	end
	Failures = Failures + 1
	io.stderr:write("FAIL: " .. Name .. "\n")
end

-- engine stubs ---------------------------------------------------------------
local Persona = 3 -- "tactician" in AIPersonality.dbt
local Traits = { bribes = 40, greed = 70, ambition = 80 }

function HasProperty(Alias, Name)
	return Name == "AI_PERSONA"
end

function GetProperty(Alias, Name)
	return Persona
end

function GetDatabaseValue(TableName, Row, Column)
	check("only AIPersonality is read", TableName == "AIPersonality")
	check("row is the persona id", Row == Persona)
	return Traits[Column] -- nil for an unknown column, like the engine
end

function ai_ChoosePersonality(Alias)
	Persona = 0
end

local Rolls, LastN = {}, nil
function Rand(N)
	check("Rand is never asked for an empty range", N > 0)
	LastN = N
	local R = Rolls[1]
	if R == nil then
		return 0
	end
	for i = 1, #Rolls - 1 do
		Rolls[i] = Rolls[i + 1]
	end
	Rolls[#Rolls] = nil
	return R
end

local function roll(...)
	Rolls = { ... }
end

-- AI.lua is loaded under the ai_ namespace in game; loading it bare here defines
-- MakeDecision globally, which is all this file needs.
dofile("Scripts/Library/AI.lua")
check("MakeDecision is defined", type(MakeDecision) == "function")

-- one trait: a percentage roll on Rand(100) ------------------------------------
roll(39)
local R = MakeDecision("Dyn", "bribes", 0)
check("one-trait result is a boolean, not 0", type(R) == "boolean")
check("one-trait path rolls Rand(100)", LastN == 100)
check("roll 39 passes a 40% trait", R == true)
roll(40)
check("roll 40 fails a 40% trait", MakeDecision("Dyn", "bribes", 0) == false)

-- the modifier shifts the percentage and is clamped to 0..100
roll(59)
check("+20 makes 60%: roll 59 passes", MakeDecision("Dyn", "bribes", 20) == true)
roll(60)
check("+20 makes 60%: roll 60 fails", MakeDecision("Dyn", "bribes", 20) == false)
roll(99)
check("clamped at 100%: roll 99 passes", MakeDecision("Dyn", "bribes", 100) == true)
roll(0)
check("clamped at 0%: roll 0 fails", MakeDecision("Dyn", "bribes", -100) == false)

-- a missing column or a nil modifier counts as 0 instead of erroring
local Ok, Res = pcall(MakeDecision, "Dyn", "nosuchcolumn", 0)
check("unknown column does not error", Ok)
check("unknown column never passes", Res == false)
roll(39)
Ok, Res = pcall(MakeDecision, "Dyn", "bribes")
check("nil modifier does not error", Ok)
check("nil modifier counts as 0", Res == true)

-- two traits: Rand(T1) >= Rand(T2) ---------------------------------------------
roll(50, 60)
R = MakeDecision("Dyn", "ambition", 0, "greed", 0)
check("two-trait result is a boolean", type(R) == "boolean")
check("first roll 50 loses to second roll 60", R == false)
roll(60, 50)
check("first roll 60 beats second roll 50", MakeDecision("Dyn", "ambition", 0, "greed", 0) == true)
roll(55, 55)
check("a tie goes to the first trait", MakeDecision("Dyn", "ambition", 0, "greed", 0) == true)

-- a zero-width trait is not rolled at all (Rand(0) is undefined in the engine)
roll(0)
check("zero first trait: roll 0 on the second still ties", MakeDecision("Dyn", "nosuchcolumn", 0, "greed", 0) == true)
roll(1)
check("zero first trait loses to any positive second roll", MakeDecision("Dyn", "nosuchcolumn", 0, "greed", 0) == false)

-- a dynasty without a persona gets one assigned first
HasProperty = function() return false end
roll(0)
Ok, Res = pcall(MakeDecision, "Dyn", "bribes", 0)
check("missing persona is assigned, not an error", Ok)
check("ChoosePersonality stub ran", Persona == 0)

if Failures > 0 then
	io.stderr:write("FAILED: " .. Failures .. " check(s) on ai_MakeDecision\n")
	os.exit(1)
end
print("ok: ai_MakeDecision")
