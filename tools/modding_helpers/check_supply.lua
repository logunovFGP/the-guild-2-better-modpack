-- Checks the auto-supply resource filter: economy_GetResourceNeeds and the
-- economy_FilterNeedsByLiveRecipes / economy_GetLiveProducts pair behind it, plus the
-- state_twp_autocart entry point an auto-managed building actually calls.
--
--   lua5.1 tools/modding_helpers/check_supply.lua
--
-- No engine needed, but unlike the other checks this one reads the REAL tables:
-- DB/BuildingToItems.dbt from the repo and DB/Items.dbt merged over the vanilla install
-- ($GUILD2, else the Steam path). The bug it guards is a data bug - a level 3 hospital
-- buying ToadExcrements because Mixture, a 1000 gold upgrade it never bought, needs them -
-- so a stubbed table would assert nothing about the rows that actually ship.

local Failures = 0

local function check(Name, Condition)
	if Condition then
		return
	end
	Failures = Failures + 1
	io.stderr:write("FAIL: " .. Name .. "\n")
end

local function has(List, Value)
	for i = 1, table.getn(List) do
		if List[i] == Value then
			return true
		end
	end
	return false
end

local function ids(Count, Items)
	local Out = {}
	for i = 1, Count do
		if Items[i] then
			table.insert(Out, Items[i][1])
		end
	end
	return Out
end

-- Lua 5.1 renamed these; the engine's Lua still has the old names the scripts use
string.gfind = string.gfind or string.gmatch
math.mod = math.mod or math.fmod

-- the real tables -------------------------------------------------------------
local VANILLA = os.getenv("GUILD2") or "G:/SteamLibrary/steamapps/common/The Guild 2 Renaissance"

local function Tokenize(Line)
	local Out, i, n = {}, 1, string.len(Line)
	while i <= n do
		local c = string.sub(Line, i, i)
		if c == " " or c == "\t" or c == "|" then
			i = i + 1
		elseif c == '"' then
			local j = string.find(Line, '"', i + 1, true) or (n + 1)
			table.insert(Out, string.sub(Line, i + 1, j - 1))
			i = j + 1
		else
			local j = i
			while j <= n do
				local d = string.sub(Line, j, j)
				if d == " " or d == "\t" or d == "|" then
					break
				end
				j = j + 1
			end
			table.insert(Out, string.sub(Line, i, j - 1))
			i = j
		end
	end
	return Out
end

-- returns rows[id][column] = value, typed by the column's declared INT/FLOAT/STRING
local function ParseDbt(Path)
	local File = io.open(Path, "rb")
	if not File then
		return nil
	end
	local Text = File:read("*a")
	File:close()

	local Columns, Types, Rows, InData = {}, {}, {}, false
	for Line in string.gmatch(Text, "[^\r\n]+") do
		if string.find(Line, "^%s*//") then
			-- comment
		elseif string.find(Line, '^%s*"id"') then
			local Header = Tokenize(Line)
			Columns, Types = {}, {}
			local i = 1
			while i + 1 <= table.getn(Header) do
				table.insert(Columns, Header[i])
				table.insert(Types, Header[i + 1])
				i = i + 3
			end
		elseif string.find(Line, "^%s*Data:") then
			InData = true
		elseif InData and string.find(Line, "^%s*%d") then
			local Values = Tokenize(Line)
			local Id = tonumber(Values[1])
			if Id then
				local Row = {}
				for c = 1, table.getn(Columns) do
					local Raw = Values[c]
					if Raw ~= nil then
						if Types[c] == "STRING" or Raw == "~" then
							Row[Columns[c]] = Raw
						else
							Row[Columns[c]] = tonumber(Raw) or Raw
						end
					end
				end
				Rows[Id] = Row
			end
		end
	end
	return Rows
end

local BuildingToItems = ParseDbt("DB/BuildingToItems.dbt")
check("DB/BuildingToItems.dbt parsed", BuildingToItems ~= nil and BuildingToItems[392] ~= nil)

local ItemsVanilla = ParseDbt(VANILLA .. "/DB/Items.dbt")
if not ItemsVanilla then
	io.stderr:write("FAIL: vanilla Items.dbt not found under " .. VANILLA ..
		"\n      set GUILD2 to the install; the recipes live there, the repo table is a delta\n")
	os.exit(1)
end
local ItemsMod = ParseDbt("DB/Items.dbt")

-- "~" in the mod table means keep the vanilla value
local Items = {}
for Id, Row in pairs(ItemsVanilla) do
	local Merged = {}
	for Column, Value in pairs(Row) do
		Merged[Column] = Value
	end
	Items[Id] = Merged
end
for Id, Row in pairs(ItemsMod or {}) do
	local Merged = Items[Id] or {}
	for Column, Value in pairs(Row) do
		if Value ~= "~" then
			Merged[Column] = Value
		end
	end
	Items[Id] = Merged
end
check("Items.dbt merged: Mixture keeps its vanilla recipe", Items[369] ~= nil and Items[369].prod2 == 135)
check("Items.dbt merged: ToadExcrements is item 133", Items[133] ~= nil and Items[133].name == "ToadExcrements")

local NameToId = {}
for Id, Row in pairs(Items) do
	if Row.name and Row.name ~= "" then
		NameToId[Row.name] = Id
	end
end

-- engine stubs ----------------------------------------------------------------
INVENTORY_STD, INVENTORY_SELL = 0, 1
GL_BUILDING_TYPE_WAREHOUSE = 40

local World = {}
local Logged = {}

function GetDatabaseValue(TableName, Row, Column)
	local Source = BuildingToItems
	if TableName == "Items" then
		Source = Items
	end
	local Entry = Source[Row]
	if not Entry then
		return nil
	end
	return Entry[Column]
end

function AliasExists(Alias)
	return World[Alias] ~= nil
end

function BuildingGetProto(Alias)
	return World[Alias].proto
end

function BuildingGetType(Alias)
	return World[Alias].btype or 1
end

function BuildingGetWorkerCount(Alias)
	return World[Alias].workers
end

-- the engine's own signature is BuildingCanProduce(building, string); the mod calls it
-- with the numeric id everywhere, so accept both and resolve to an id
function BuildingCanProduce(Alias, Item)
	local Id = tonumber(Item) or NameToId[Item]
	if not Id then
		return false
	end
	return World[Alias].unlocked[Id] == true
end

function GetProperty(Alias, Key)
	return World[Alias].props[Key]
end

function SetProperty(Alias, Key, Value)
	World[Alias].props[Key] = Value
end

function RemoveProperty(Alias, Key)
	World[Alias].props[Key] = nil
end

function HasProperty(Alias, Key)
	return World[Alias].props[Key] ~= nil
end

function GetItemCount(Alias, ItemId, Inventory)
	if Inventory == INVENTORY_SELL then
		return 0
	end
	return World[Alias].stock[ItemId] or 0
end

function GetImpactValue(Alias, Name)
	return World[Alias].space or 500
end

function ItemGetID(Value)
	return tonumber(Value) or NameToId[Value]
end

function ItemGetName(ItemId)
	local Row = Items[ItemId]
	if not Row then
		return nil
	end
	return Row.name
end

function GetID(Alias)
	if not World[Alias] then
		return -1
	end
	return World[Alias].id
end

function GetGametime()
	return 12.0
end

function LogMessage(Text)
	table.insert(Logged, Text)
end

-- the library under test ------------------------------------------------------
dofile("Scripts/Library/helpfuncs.lua")
helpfuncs_StringToIdList, helpfuncs_IdListToString = StringToIdList, IdListToString
helpfuncs_QuickSort, helpfuncs_SortBySecondValue = QuickSort, SortBySecondValue
helpfuncs_RemoveElementFromList = RemoveElementFromList

-- utility.lua would pull the whole AI tree in; Emit and LogEnabled are all this path uses
function utility_LogEnabled()
	return true
end
function utility_Emit(Text)
	LogMessage(Text)
end

dofile("Scripts/Library/economy.lua")
economy_GetProducedItems, economy_GetResourceNeeds = GetProducedItems, GetResourceNeeds
economy_CalcCurrentResourceNeeds = CalcCurrentResourceNeeds
economy_GetItemIngredients, economy_GetProtoIngredientUsers = GetItemIngredients, GetProtoIngredientUsers
economy_BuildingCanProduceItem, economy_GetLiveProducts = BuildingCanProduceItem, GetLiveProducts
economy_FilterNeedsByLiveRecipes = FilterNeedsByLiveRecipes
economy_ProbeValue, economy_ProbeItemIdSpaces = ProbeValue, ProbeItemIdSpaces
-- The id probe is a runtime exploration aid, not behaviour under test, and it would take
-- Logged[1] away from every filter assertion below. Silenced here, exercised at the end.
ECONOMY_IDPROBE_DONE = 1
economy_StorageGetProducts = StorageGetProducts

economy_StorageGetResources, economy_StorageSaveResources = StorageGetResources, StorageSaveResources
economy_StorageSaveProducts, economy_StorageUpdateOnLevelUp = StorageSaveProducts, StorageUpdateOnLevelUp

function DynastyIsPlayer(Alias)
	return true
end

dofile("Scripts/States/state_twp_autocart.lua")
state_twp_autocart_CalcResourceNeeds = CalcResourceNeeds

-- the world ---------------------------------------------------------------------
-- Hospital3, proto 392. The standard unlocks in DB/BuildingUpgrades.dbt are Lavender 120,
-- MiracleCure 362, Soap 361 and Bandage 360; everything above them is a paid upgrade.
-- This is a hospital that bought all of them except Mixture 369, the 1000 gold one.
local function Hospital(Unlocked, Selected)
	World.Hosp = {
		id = 7, proto = 392, workers = 2, space = 500,
		unlocked = Unlocked, stock = {}, props = {},
	}
	if Selected then
		World.Hosp.props.MgmStor_Products = Selected
	end
	return "Hosp"
end

local AllButMixture = { [360] = true, [361] = true, [362] = true, [364] = true,
	[365] = true, [366] = true, [370] = true, [371] = true }
local WithMixture = { [360] = true, [361] = true, [362] = true, [364] = true,
	[365] = true, [366] = true, [369] = true, [370] = true, [371] = true }

-- the row this is all about -------------------------------------------------------
check("Hospital3 requireditems still lists the three Mixture ingredients",
	string.find(BuildingToItems[392].requireditems, "48 135 133", 1, true) ~= nil)
check("Mixture 369 needs GhostlyFog, Toadslime and ToadExcrements",
	Items[369].prod1 == 48 and Items[369].prod2 == 135 and Items[369].prod3 == 133)

-- 1. unlock filter: Mixture not bought ---------------------------------------------
Logged = {}
local Count, Needs = economy_GetResourceNeeds(Hospital(AllButMixture))
local List = ids(Count, Needs)
check("locked Mixture: ToadExcrements 133 is not supplied", not has(List, 133))
check("locked Mixture: Toadslime 135 is not supplied", not has(List, 135))
check("locked Mixture: GhostlyFog 48 is not supplied", not has(List, 48))
check("locked Mixture: the other ten resources survive", Count == 10)
check("locked Mixture: Wool 8 still supplied", has(List, 8))
check("locked Mixture: Lavender 120 still supplied", has(List, 120))
check("locked Mixture: Charcoal 203 still supplied", has(List, 203))
check("locked Mixture: Bandage 360 still supplied as a MediPack input", has(List, 360))
check("amounts still scale by worker count", Needs[1][2] == 16)

local Line = Logged[1]
check("a SUPPLY line is emitted", Line ~= nil and string.find(Line, "::TWP::SUPPLY", 1, true) == 1)
check("SUPPLY names the building and proto", string.find(Line, "bld=7 proto=392", 1, true) ~= nil)
check("SUPPLY reports matched > 0, so the two id spaces do compare equal",
	string.find(Line, "matched=13", 1, true) ~= nil)
check("SUPPLY names the dropped goods",
	string.find(Line, "48:GhostlyFog:locked;135:Toadslime:locked;133:ToadExcrements:locked;", 1, true) ~= nil)
check("SUPPLY reports no malformed slot for this row", string.find(Line, "malformed", 1, true) == nil)

-- 2. unlock filter, the other way: Mixture bought ------------------------------------
Logged = {}
Count, Needs = economy_GetResourceNeeds(Hospital(WithMixture))
List = ids(Count, Needs)
check("unlocked Mixture: ToadExcrements 133 comes back", has(List, 133))
check("unlocked Mixture: Toadslime 135 comes back", has(List, 135))
check("unlocked Mixture: GhostlyFog 48 comes back", has(List, 48))
check("unlocked Mixture: the whole row is supplied", Count == 13)
check("unlocked Mixture: nothing is logged, because nothing was dropped", table.getn(Logged) == 0)

-- 3. produced filter: Mixture unlocked but deselected in the storage panel ------------
Logged = {}
Count, Needs = economy_GetResourceNeeds(
	Hospital(WithMixture, "360 361 362 365 366 364 370 371 "))
List = ids(Count, Needs)
check("deselected Mixture: ToadExcrements 133 is not supplied", not has(List, 133))
check("deselected Mixture: Toadslime 135 is not supplied", not has(List, 135))
check("deselected Mixture: GhostlyFog 48 is not supplied", not has(List, 48))
check("deselected Mixture: the other ten survive", Count == 10)

-- one product deeper: deselect PainKiller 371 as well. Fungi 204 feeds only PainKiller so
-- it goes; Lavender 120 and Fruit 941 feed other recipes and must stay.
Logged = {}
Count, Needs = economy_GetResourceNeeds(
	Hospital(WithMixture, "360 361 362 365 366 364 370 "))
List = ids(Count, Needs)
check("deselected PainKiller: Fungi 204 is not supplied", not has(List, 204))
check("deselected PainKiller: Lavender 120 stays, other recipes use it", has(List, 120))
check("deselected PainKiller: Fruit 941 stays, other recipes use it", has(List, 941))

-- 4. an entry no recipe references is deliberate and must survive ---------------------
-- Divehouse2 produces nothing and drinks SmallBeer 42, WheatBeer 44, PiratenGrog 935
World.Dive = { id = 11, proto = 381, workers = 1, unlocked = {}, stock = {}, props = {} }
Count, Needs = economy_GetResourceNeeds("Dive")
List = ids(Count, Needs)
check("divehouse keeps SmallBeer 42 though it produces nothing", has(List, 42))
check("divehouse keeps WheatBeer 44", has(List, 44))
check("divehouse keeps PiratenGrog 935", has(List, 935))
check("divehouse list is untouched", Count == 3)

-- Alchimist1 lists its own Lavender 120 and Blackberry 121 as resources it grows
World.Alch = { id = 12, proto = 170, workers = 1,
	unlocked = { [120] = true, [121] = true, [123] = true, [967] = true }, stock = {}, props = {} }
Count, Needs = economy_GetResourceNeeds("Alch")
List = ids(Count, Needs)
check("alchemist keeps its self-grown Lavender 120", has(List, 120))
check("alchemist keeps its self-grown Blackberry 121", has(List, 121))

-- 5. the repaired Bankhouse row reads as one list -------------------------------------
World.Bank = { id = 13, proto = 666, workers = 1,
	unlocked = { [963] = true, [959] = true, [954] = true, [953] = true, [957] = true, [962] = true },
	stock = {}, props = {} }
Count, Needs = economy_GetResourceNeeds("Bank")
List = ids(Count, Needs)
check("Bankhouse2 supplies Pergament 963, the id that was missing from the row", has(List, 963))
check("Bankhouse2 has six resources, one per usage", Count == 6)
for i = 1, Count do
	check("Bankhouse2 resource " .. i .. " has an id and an amount",
		Needs[i] ~= nil and Needs[i][1] ~= nil and Needs[i][2] ~= nil)
end

-- 6. the entry point the auto-managed cart actually calls ------------------------------
-- state_twp_autocart_CalcResourceNeeds is what the cart runs every cycle before it drives
-- to market, so this is the shopping list, not just the resource list.
local Alias = Hospital(AllButMixture)
local Stocked = { 8, 120, 940, 941, 204, 364, 201, 203, 360, 365 }
for i = 1, table.getn(Stocked) do
	World.Hosp.stock[Stocked[i]] = 99
end
local NeedCount, ShoppingList = state_twp_autocart_CalcResourceNeeds(Alias)
check("a fully stocked hospital has nothing to buy", NeedCount == 0)

World.Hosp.stock = { [8] = 1 }
NeedCount, ShoppingList = state_twp_autocart_CalcResourceNeeds(Alias)
local Shopping = ids(NeedCount, ShoppingList)
check("the cart's shopping list is not empty", NeedCount > 0)
check("the cart never shops for ToadExcrements 133", not has(Shopping, 133))
check("the cart never shops for Toadslime 135", not has(Shopping, 135))
check("the cart never shops for GhostlyFog 48", not has(Shopping, 48))
check("the cart does shop for Lavender 120", has(Shopping, 120))

Alias = Hospital(WithMixture)
World.Hosp.stock = { [8] = 1 }
NeedCount, ShoppingList = state_twp_autocart_CalcResourceNeeds(Alias)
Shopping = ids(NeedCount, ShoppingList)
check("with Mixture bought the cart does shop for ToadExcrements", has(Shopping, 133))

-- 7. probes ----------------------------------------------------------------------------
-- every recipe locked: the filter would empty the list, so it hands back the full one
-- rather than leave the building with nothing to buy at all
Logged = {}
Count, Needs = economy_GetResourceNeeds(Hospital({}))
check("no unlocked recipe at all falls back to the unfiltered list", Count == 13)
check("the fallback still says so in the log",
	Logged[1] ~= nil and string.find(Logged[1], "live=0", 1, true) ~= nil)

-- a proto with no BuildingToItems row buys nothing and does not error
World.Ghost = { id = 14, proto = 999, workers = 1, unlocked = {}, stock = {}, props = {} }
Count, Needs = economy_GetResourceNeeds("Ghost")
check("a building with no BuildingToItems row needs nothing", Count == 0)

-- a dead alias is not a crash
Count, Needs = economy_GetResourceNeeds("NoSuchBuilding")
check("an alias that does not exist needs nothing", Count == 0)

-- a worker count of zero still multiplies by one
Alias = Hospital(AllButMixture)
World.Hosp.workers = 0
Count, Needs = economy_GetResourceNeeds(Alias)
check("zero workers still asks for the base amount", Needs[1][2] == 8)

-- an empty MgmStor_Products string means "never configured", not "produce nothing"
Alias = Hospital(AllButMixture, "")
Count, Needs = economy_GetResourceNeeds(Alias)
check("an empty product property is treated as unconfigured", Count == 10)

-- A row whose two columns disagree. Count comes from requireditems, so the harmful
-- direction is fewer usages than items: those slots reach the caller as {nil, amount} and
-- CalcCurrentResourceNeeds indexes [1] on them. They must be dropped and named.
local Saved = BuildingToItems[392].requireditemusages
BuildingToItems[392].requireditemusages = "8 16 8 8 8 4 6 3 1 1 1 "
Logged = {}
Alias = Hospital(WithMixture)
Count, Needs = economy_GetResourceNeeds(Alias)
check("the two idless slots are dropped, the eleven real ones stay", Count == 11)
check("the idless slots are named in the log",
	Logged[1] ~= nil and string.find(Logged[1], "slot12:malformed;slot13:malformed;", 1, true) ~= nil)
for i = 1, Count do
	check("surviving resource " .. i .. " still has an id", Needs[i] ~= nil and Needs[i][1] ~= nil)
end

-- the other direction, a usage with no item, is harmless: Count comes from requireditems
-- so the extra never reaches the caller. Recorded here so the asymmetry is not a surprise.
BuildingToItems[392].requireditemusages = Saved .. " 4 "
Logged = {}
Alias = Hospital(WithMixture)
Count, Needs = economy_GetResourceNeeds(Alias)
check("a trailing orphan usage is ignored, not returned", Count == 13)
BuildingToItems[392].requireditemusages = Saved


-- 8. a drop says which of the two filters took it ---------------------------------------
Logged = {}
Count, Needs = economy_GetResourceNeeds(Hospital(AllButMixture))
check("an unbought recipe reports its ingredients as locked",
	Logged[1] ~= nil and string.find(Logged[1], "133:ToadExcrements:locked;", 1, true) ~= nil)
check("nothing is called deselected when nothing was deselected",
	Logged[1] ~= nil and string.find(Logged[1], "deselected", 1, true) == nil)

Logged = {}
Count, Needs = economy_GetResourceNeeds(
	Hospital(WithMixture, "360 361 362 365 366 364 370 371 "))
check("a recipe taken out of the storage panel reports deselected",
	Logged[1] ~= nil and string.find(Logged[1], "133:ToadExcrements:deselected;", 1, true) ~= nil)
check("nothing is called locked when the recipe is unlocked",
	Logged[1] ~= nil and string.find(Logged[1], ":locked;", 1, true) == nil)

-- 9. the harmless direction of a misaligned row is still named ---------------------------
-- Count comes from requireditems, so a surplus usage never reaches a caller. It is still a
-- wrong row, and the four repaired on 2026-09-19 were all this shape.
local Saved2 = BuildingToItems[392].requireditemusages
BuildingToItems[392].requireditemusages = Saved2 .. " 4 "
Logged = {}
Count, Needs = economy_GetResourceNeeds(Hospital(WithMixture))
check("a surplus usage is reported as an orphan",
	Logged[1] ~= nil and string.find(Logged[1], "usage14:orphan;", 1, true) ~= nil)
check("the surplus usage still does not become a resource", Count == 13)
BuildingToItems[392].requireditemusages = Saved2

-- 10. level up merges the resource list by item id, not by index -------------------------
-- BuildingToItems does not list the same items in the same order at every level: hospital
-- 2 is 8 120 940 941 201 203 and hospital 3 puts 204 and 364 at index 5 and 6. Appending
-- the tail of the new list by position duplicated 201 and 203, dropped 204 and 364, and
-- moved the configured minimum amounts onto whatever item landed on their index.
Alias = Hospital(AllButMixture)
World.Hosp.proto = 391
World.Hosp.props.MgmStor_Resources = "8 120 940 941 201 203 "
World.Hosp.props.MgmStor_ResourceMins = "8 16 8 8 6 99 "
World.Hosp.proto = 392
economy_StorageUpdateOnLevelUp(Alias)

local Stored = World.Hosp.props.MgmStor_Resources
local StoredCount, StoredIds = helpfuncs_StringToIdList(Stored)
local _, StoredMins = helpfuncs_StringToIdList(World.Hosp.props.MgmStor_ResourceMins)
local Seen = {}
local Duplicates = 0
for i = 1, StoredCount do
	if Seen[StoredIds[i]] then
		Duplicates = Duplicates + 1
	end
	Seen[StoredIds[i]] = i
end
check("level up leaves no duplicate resource", Duplicates == 0)
check("level up kept Fungi 204, which the positional append used to drop", Seen[204] ~= nil)
check("level up kept Salve 364, which the positional append used to drop", Seen[364] ~= nil)
check("level up did not add an ingredient of the recipe still locked", Seen[133] == nil)
check("level up produced the ten live resources", StoredCount == 10)
check("the configured minimum stayed on Charcoal 203",
	Seen[203] ~= nil and StoredMins[Seen[203]] == 99)

-- the id probe -------------------------------------------------------------------------
-- Shape only, deliberately. The stubs above answer ItemGetID and BuildingCanProduce with
-- `tonumber(Value) or NameToId[Value]`, which accepts every form; the whole reason the
-- probe exists is that no harness can say which form the real engine resolves. What can
-- be checked here is that the line carries every field and stays parseable, because
-- kv() in ai_telemetry.py splits on whitespace and would silently drop a value with a
-- space in it.
ECONOMY_IDPROBE_DONE = nil
local ProbeBld = Hospital(WithMixture)
Logged = {}
economy_ProbeItemIdSpaces(ProbeBld, 392)
local Probe = Logged[1]
check("id probe: emits one line", Probe ~= nil and string.find(Probe, "::TWP::IDPROBE", 1, true) == 1)
check("id probe: fires only once a session", ECONOMY_IDPROBE_DONE == 1)
Logged = {}
economy_ProbeItemIdSpaces(ProbeBld, 392)
check("id probe: and is silent the second time", Logged[1] == nil)
local Fields = { "bld=", "proto=", "listid=", "getname=", "id_byname=", "id_bynumstr=",
	"id_bynum=", "prod1=", "canprod_num=", "canprod_numstr=", "canprod_name=" }
for i = 1, table.getn(Fields) do
	check("id probe: carries " .. Fields[i], string.find(Probe, Fields[i], 1, true) ~= nil)
end
check("id probe: every value is typed", string.find(Probe, "listid=number:", 1, true) ~= nil)
-- a name with a space in it must not split the line into two keys
check("id probe: a nil answer still reads as one token",
	economy_ProbeValue(nil) == "nil:-")
check("id probe: a spaced name is collapsed",
	economy_ProbeValue("Toad Excrements") == "string:Toad_Excrements")
-- kv() keeps only tokens containing "=", so a value with a space in it would be dropped
-- silently rather than noisily: assert every token past the tag still carries one
local Loose = 0
for Token in string.gfind(string.gsub(Probe, "^::TWP::IDPROBE%s+", ""), "%S+") do
	if string.find(Token, "=", 1, true) == nil then
		Loose = Loose + 1
	end
end
check("id probe: every token is a key=value pair", Loose == 0)

if Failures > 0 then
	io.stderr:write(Failures .. " check(s) failed\n")
	os.exit(1)
end
print("check_supply: all checks passed")
