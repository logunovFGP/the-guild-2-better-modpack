-------------------------------------------------------------------------------
--
--  lib_ManageActions
--
--  Backs the "Actions" tab of the Manage Building panel!
--
--  The file is split into two parts:
--    1) GENERIC CORE  - works for ANY building that registers a mact definition.
--    2) BUILDING DEFS - building-specific definitions.
--
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--  1) GENERIC CORE
-------------------------------------------------------------------------------

function mact_Register(btype, def)
	if MACT_REGISTRY == nil then
		MACT_REGISTRY = {}
	end
	MACT_REGISTRY[btype] = def
end

function mact_RegisterMod(btype, def)
	if MACT_PENDING == nil then
		MACT_PENDING = {}
		MACT_PENDING_N = 0
	end
	MACT_PENDING_N = MACT_PENDING_N + 1
	MACT_PENDING[MACT_PENDING_N] = { btype, def }
end

function mact_Init()
	MACT_REGISTRY = {}
	if lib_manageactions_mact_RegisterBuiltins ~= nil then
		lib_manageactions_mact_RegisterBuiltins()
	end
	if MACT_PENDING ~= nil then
		local i = 1
		while MACT_PENDING[i] ~= nil do
			lib_manageactions_mact_Register(MACT_PENDING[i][1], MACT_PENDING[i][2])
			i = i + 1
		end
	end
	if lib_manageactions_mact_RegisterMods ~= nil then
		lib_manageactions_mact_RegisterMods()
	end
	MACT_INITED = 1
end

function mact_EnsureInit()
	if MACT_INITED == nil or MACT_REGISTRY == nil then
		lib_manageactions_mact_Init()
	end
end

function mact_GetDef()
	lib_manageactions_mact_EnsureInit()
	return MACT_REGISTRY[BuildingGetType("")]
end

function mact_ResolveActions(def)
	local a = def.actions
	if a == nil then
		return nil
	end
	if type(a) == "function" then
		return a()
	end
	return a
end

function mact_ActionUnlocked(a)
	if BuildingGetProducerCount("", PT_MEASURE, a.measure) > 0 then
		return 1
	end
	if a.unlockUpgrade ~= nil then
		if BuildingHasUpgrade("", a.unlockUpgrade) then
			return 1
		end
		if DynastyHasUpgrade("", a.unlockUpgrade) then
			return 1
		end
	end
	if a.unlockProduce ~= nil then
		if BuildingCanProduce("", a.unlockProduce) then
			return 1
		end
	end
	if a.unlockItem ~= nil then
		if GetItemCount("", a.unlockItem, INVENTORY_STD) > 0 then
			return 1
		end
		if GetItemCount("", a.unlockItem, INVENTORY_SELL) > 0 then
			return 1
		end
	end
	if a.unlockUpgrade ~= nil or a.unlockProduce ~= nil or a.unlockItem ~= nil then
		return 0
	end
	return 1
end

function mact_ActionField(a)
	local mid = MeasureGetID(a.measure)
	local busy = BuildingGetProducerCount("", PT_MEASURE, a.measure)
	local unlocked = lib_manageactions_mact_ActionUnlocked(a)
	local pat = 0
	if a.usesWaiting ~= nil then
		pat = a.usesWaiting
	end
	return "" .. mid .. "," .. a.loca .. "," .. busy .. "," .. unlocked .. "," .. pat
end

function UIData()
	local def = lib_manageactions_mact_GetDef()
	if def == nil then
		return "0"
	end

	local out = "0"

	local actions = lib_manageactions_mact_ResolveActions(def)
	if actions == nil then
		return out
	end

	local i = 1
	while actions[i] ~= nil do
		out = out .. "#" .. lib_manageactions_mact_ActionField(actions[i])
		i = i + 1
	end
	return out
end

function HasActionTab()
	if lib_manageactions_mact_GetDef() ~= nil then
		return 1
	end
	return 0
end

function PeopleConfig()
	local def = lib_manageactions_mact_GetDef()
	if def == nil or def.people == nil then
		return ""
	end
	local p = def.people
	local prop = ""
	if p.property ~= nil then
		prop = p.property
	end
	local sick = 0
	if p.includeSick ~= nil then
		sick = p.includeSick
	end
	local title = "_ADMINACT_PATIENTS"
	if p.title ~= nil then
		title = p.title
	end
	local empty = "_ADMINACT_NOPAT"
	if p.empty ~= nil then
		empty = p.empty
	end
	local statusA = "_ADMINACT_STATUS_WAIT"
	if p.statusWaiting ~= nil then
		statusA = p.statusWaiting
	end
	local statusB = "_ADMINACT_STATUS_TREAT"
	if p.statusActive ~= nil then
		statusB = p.statusActive
	end
	local active = ""
	if p.activeProperty ~= nil then
		active = p.activeProperty
	end
	return prop .. "|" .. sick .. "|" .. title .. "|" .. empty .. "|" .. statusA .. "|" .. statusB .. "|" .. active
end

function mact_RuleBase(measureName)
	return "MActRule_" .. MeasureGetID(measureName) .. "_"
end

function mact_RuleEnabled(buildingAlias, measureName)
	local base = lib_manageactions_mact_RuleBase(measureName)
	if HasProperty(buildingAlias, base .. "enabled") then
		return (GetProperty(buildingAlias, base .. "enabled") - 1) ~= 0
	end
	return true
end

function mact_RuleValue(buildingAlias, measureName, field, default)
	local base = lib_manageactions_mact_RuleBase(measureName)
	if HasProperty(buildingAlias, base .. field) then
		return GetProperty(buildingAlias, base .. field) - 1
	end
	return default
end

function mact_RuleMaxWorkers(buildingAlias, measureName, default)
	return lib_manageactions_mact_RuleValue(buildingAlias, measureName, "maxw", default)
end

function mact_RuleMinCount(buildingAlias, measureName, default)
	return lib_manageactions_mact_RuleValue(buildingAlias, measureName, "minp", default)
end

function mact_RulePriority(buildingAlias, measureName, default)
	return lib_manageactions_mact_RuleValue(buildingAlias, measureName, "prio", default)
end

function mact_LeafWeight(buildingAlias, measureName, count)
	if not lib_manageactions_mact_RuleEnabled(buildingAlias, measureName) then
		return 0
	end
	if count < lib_manageactions_mact_RuleMinCount(buildingAlias, measureName, 1) then
		return 0
	end
	if BuildingGetProducerCount(buildingAlias, PT_MEASURE, measureName) >= lib_manageactions_mact_RuleMaxWorkers(buildingAlias, measureName, 99) then
		return 0
	end
	if lib_manageactions_mact_RulePriority(buildingAlias, measureName, 1) == 0 then
		return 20
	end
	return 100
end

function mact_MeasureShouldStop(buildingAlias, measureName)
	if not lib_manageactions_mact_RuleEnabled(buildingAlias, measureName) then
		return true
	end
	if BuildingGetProducerCount(buildingAlias, PT_MEASURE, measureName) > lib_manageactions_mact_RuleMaxWorkers(buildingAlias, measureName, 99) then
		return true
	end
	return false
end


-------------------------------------------------------------------------------
--  2) BUILDING DEFS
-------------------------------------------------------------------------------

function mact_RegisterBuiltins()
	lib_manageactions_mact_Register(GL_BUILDING_TYPE_HOSPITAL, lib_manageactions_mact_DefHospital())
end

function mact_DefHospital()
	local def = {}

	def.actions = function()
		local list = {}
		list[1] = { measure = "MedicalTreatment", loca = "_MACT_TREAT", usesWaiting = 1 }
		list[2] = { measure = "Quacksalver",      loca = "_MACT_QUACK", unlockUpgrade = "MiracleCure", unlockProduce = "MiracleCure", unlockItem = "MiracleCure" }
		return list
	end

	def.people = {
		property = "WaitingForTreatment",
		activeProperty = "BeingTreated",
		includeSick = 1,
		title = "_ADMINACT_PATIENTS",
		empty = "_ADMINACT_NOPAT",
		statusWaiting = "_ADMINACT_STATUS_WAIT",
		statusActive = "_ADMINACT_STATUS_TREAT",
	}

	return def
end


-------------------------------------------------------------------------------
--  3) MOD DEFS (Reforged)
--
--  mact_Init calls mact_RegisterMods when it exists and vanilla never defines
--  it, so everything above is the vanilla file unchanged and this is the only
--  addition. Keep it that way: it is what makes the next upstream merge a copy.
-------------------------------------------------------------------------------

function mact_RegisterMods()
	lib_manageactions_mact_Register(GL_BUILDING_TYPE_BANKHOUSE, lib_manageactions_mact_DefBankhouse())
end

-- Clerks serving customers who want a credit (bank_SetOfferCredit) and going after
-- defaulters (bank_SetCollectDebts). The roster lists sims waiting for a credit.
function mact_DefBankhouse()
	local def = {}

	def.actions = function()
		local list = {}
		list[1] = { measure = "OfferCredit",  loca = "_MACT_LOAN", usesWaiting = 1 }
		list[2] = { measure = "CollectDebts", loca = "_MACT_COLLECT" }
		return list
	end

	def.people = {
		property = "WaitForCredit",
		title = "_ADMINACT_BORROWERS",
		empty = "_ADMINACT_NOBORROWERS",
		statusWaiting = "_ADMINACT_STATUS_WANTLOAN",
		statusActive = "_ADMINACT_STATUS_WANTLOAN",
	}

	return def
end
