WOA_DEBUG_FAST       = 0
WOA_MATERIAL_FACTOR  = 6    -- masterpiece needs this many times a normal item's inputs
WOA_BASE_HOURS       = 4    -- in-game hours of work for the very simplest item, before skill
WOA_HOURS_PER_BUILDTIME = 4 -- extra in-game hours per point of the item's Items.dbt buildtime
WOA_SETBACK_HOURS    = 3    -- in-game hours of work lost per mid-craft slip
WOA_TICK_SECONDS     = 2    -- seconds waited per loop
WOA_OH_STEP          = 10
WOA_MAX_BUTTONS      = 8

function woa_QualityFromPermil(permil)
	if permil < 1100 then return 0 end       -- Poor:      base .. +10%
	if permil < 1250 then return 1 end       -- Common:    +10% .. +25%
	if permil < 1450 then return 2 end       -- Good:      +25% .. +45%
	return 3                                 -- Excellent: +45% .. +70%
end

function woa_QualityOdds(skill)
	if skill < 0 then skill = 0 end
	local base = 1000 + (skill * 45)
	local c0, c1, c2, c3 = 0, 0, 0, 0
	local u = 0
	while u < 200 do
		local p = base + u - 40
		if p < 1000 then p = 1000 end
		if p > 1700 then p = 1700 end
		local q = ms_createworkofart_woa_QualityFromPermil(p)
		if q == 0 then c0 = c0 + 1
		elseif q == 1 then c1 = c1 + 1
		elseif q == 2 then c2 = c2 + 1
		else c3 = c3 + 1 end
		u = u + 1
	end
	return (c0 * 100 + 100) / 200, (c1 * 100 + 100) / 200, (c2 * 100 + 100) / 200, (c3 * 100 + 100) / 200
end

-- loca label for a quality tier word
function woa_QualityKey(tier)
	if tier == 0 then return "_WOA_QUALITY_POOR_+0" end
	if tier == 1 then return "_WOA_QUALITY_COMMON_+0" end
	if tier == 2 then return "_WOA_QUALITY_GOOD_+0" end
	return "_WOA_QUALITY_EXCELLENT_+0"
end

function woa_ClassOf(itemId)
	local dt = GetDatabaseValue("Items", itemId, "datatype")
	if dt == 2 then return "weapon" end
	if dt == 3 then return "armour" end
	return nil
end

function woa_HasMaterials(BldAlias, itemId, factor)
	local i = 1
	while i <= 3 do
		local prod = GetDatabaseValue("Items", itemId, "prod"..i)
		local nr   = GetDatabaseValue("Items", itemId, "nr"..i)
		if prod and prod > 0 and nr and nr > 0 then
			if GetItemCount(BldAlias, prod, INVENTORY_STD) < (nr * factor) then
				return false
			end
		end
		i = i + 1
	end
	return true
end

function woa_ConsumeMaterials(BldAlias, itemId, factor)
	local i = 1
	while i <= 3 do
		local prod = GetDatabaseValue("Items", itemId, "prod"..i)
		local nr   = GetDatabaseValue("Items", itemId, "nr"..i)
		if prod and prod > 0 and nr and nr > 0 then
			RemoveItems(BldAlias, prod, nr * factor, INVENTORY_STD)
		end
		i = i + 1
	end
end

function woa_SetMaterialArgs(itemId, factor, tokenArg)
	local qty = {}
	local nm  = {}
	local count = 0
	local i = 1
	while i <= 3 do
		local prod = GetDatabaseValue("Items", itemId, "prod"..i)
		local nr   = GetDatabaseValue("Items", itemId, "nr"..i)
		if prod and prod > 0 and nr and nr > 0 then
			count = count + 1
			qty[count] = nr * factor
			nm[count]  = "_ITEM_" .. ItemGetName(prod) .. "_NAME_+0"
		end
		i = i + 1
	end

	local tokens = ""
	local argi = tokenArg
	local c = 1
	while c <= count do
		argi = argi + 1; local qa = argi
		argi = argi + 1; local na = argi
		if c > 1 then tokens = tokens .. ", " end
		tokens = tokens .. "%" .. qa .. "ix %" .. na .. "l"
		c = c + 1
	end
	if tokens == "" then tokens = "-" end

	SetArg(tokenArg, tokens)
	argi = tokenArg
	c = 1
	while c <= count do
		argi = argi + 1; SetArg(argi, qty[c])
		argi = argi + 1; SetArg(argi, nm[c])
		c = c + 1
	end
end

function woa_GotoAnvil()
	if GetLocatorByName("Workshop", "Anvil", "WoAAnvilPos") then
		GetLocatorByName("Workshop", "spark_anvil", "WoASparkAnvil")   -- wherethe hammer sparks play
		f_MoveTo("", "WoAAnvilPos")
		RemoveAlias("WoAAnvilPos")
		return 1
	end
	if GetLocatorByName("Workshop", "Forge", "WoAForgePos") then
		f_MoveTo("", "WoAForgePos")
		RemoveAlias("WoAForgePos")
	end
	return 0
end

function woa_TargetHours(itemId, skill)
	if WOA_DEBUG_FAST == 1 then return 1 end
	local bt = GetDatabaseValue("Items", itemId, "buildtime")
	if not bt or bt < 1 then bt = 1 end
	if skill < 0 then skill = 0 end
	if skill > 10 then skill = 10 end
	local skillF = 100 - (skill * 5)
	if skillF < 50 then skillF = 50 end
	local hours = ((bt * WOA_HOURS_PER_BUILDTIME) + WOA_BASE_HOURS) * skillF / 100
	if hours < 1 then hours = 1 end
	return hours
end

function Init()
end

function Run()
	if not GetInsideBuilding("", "Workshop") then
		StopMeasure()
		return
	end

	local hpStart = GetHPRelative("")
	if hpStart >= 0 and hpStart < 0.20 then
		MsgBoxNoWait("", "", "@L_WOA_TOOHURT_HEAD_+0", "@L_WOA_TOOHURT_BODY_+0")
		StopMeasure(); return
	end

	local itemId, permil, quality
	local resuming = HasProperty("", "WoA_Active")

	-- a craft is already in progress here so hold up!
	if resuming then
		local rdoneH = GetProperty("", "WoA_DoneHours"); if not rdoneH then rdoneH = 0 end
		local rskill = GetSkillValue("", CRAFTSMANSHIP); if rskill < 0 then rskill = 0 end
		local ritem  = GetProperty("", "WoA_Item")
		local rtarget = ms_createworkofart_woa_TargetHours(ritem, rskill)
		local rpct = (rdoneH * 100) / rtarget
		SetArg(1, rpct)
		if MsgBox("", "", "@P".."@B[1,@L_WOA_RESUME_CONTINUE_+0]".."@B[2,@L_WOA_RESUME_ABANDON_+0]", "@L_WOA_RESUME_HEAD_+0", "@L_WOA_RESUME_BODY_+0") ~= 1 then
			RemoveProperty("", "WoA_Active"); RemoveProperty("", "WoA_Item")
			RemoveProperty("", "WoA_Permil"); RemoveProperty("", "WoA_Quality"); RemoveProperty("", "WoA_DoneHours")
			resuming = false
		end
	end

	if resuming then
		itemId  = GetProperty("", "WoA_Item")
		permil  = GetProperty("", "WoA_Permil")
		quality = GetProperty("", "WoA_Quality")
	else
		-- 1) Armour or Weapon?
		local class = MsgBox("", "", "@P".."@B[1,@L_WOA_PICK_ARMOUR_+0]".."@B[2,@L_WOA_PICK_WEAPON_+0]", "@L_WOA_PICK_CLASS_HEAD_+0", "@L_WOA_PICK_CLASS_BODY_+0")
		local wantClass
		if class == 1 then wantClass = "armour"
		elseif class == 2 then wantClass = "weapon"
		else StopMeasure(); return end

		-- 2) enumerate the items this smithy can currently produce, of that class
		local buttons = ""
		local map = {}
		local n = 0
		local id = 1
		while id < 1260 and n < WOA_MAX_BUTTONS do
			if ms_createworkofart_woa_ClassOf(id) == wantClass and BuildingCanProduce("Workshop", id) then
				n = n + 1
				map[n] = id
				local nm = ItemGetName(id)
				buttons = buttons .. "@B["..n..",@L_ITEM_"..nm.."_NAME_+0]"
			end
			id = id + 1
		end
		if n == 0 then
			MsgBoxNoWait("", "", "@L_WOA_NONE_HEAD_+0", "@L_WOA_NONE_BODY_+0")
			StopMeasure(); return
		end

		local pick = MsgBox("", "", "@P"..buttons, "@L_WOA_PICK_ITEM_HEAD_+0", "@L_WOA_PICK_ITEM_BODY_+0")
		if not map[pick] then StopMeasure(); return end
		itemId = map[pick]

		local skill = GetSkillValue("", CRAFTSMANSHIP)
		if skill < 0 then skill = 0 end
		permil = 1000 + (skill * 45) + (Rand(200) - 40)
		if permil < 1000 then permil = 1000 end
		if permil > 1700 then permil = 1700 end
		quality = ms_createworkofart_woa_QualityFromPermil(permil)

		local matFactor = WOA_MATERIAL_FACTOR
		if WOA_DEBUG_FAST == 1 then matFactor = 1 end

		local op, oc, og, oe = ms_createworkofart_woa_QualityOdds(skill)
		local mode, modeP = 0, op
		if oc > modeP then mode = 1; modeP = oc end
		if og > modeP then mode = 2; modeP = og end
		if oe > modeP then mode = 3; modeP = oe end
		local estHours = ms_createworkofart_woa_TargetHours(itemId, skill) + 0.5
		SetArg(1, ms_createworkofart_woa_QualityKey(mode))
		SetArg(2, estHours)
		ms_createworkofart_woa_SetMaterialArgs(itemId, matFactor, 3)
		local confirmBody
		if modeP >= 55 then         confirmBody = "@L_WOA_CONFIRM_CONF_+0"     -- the tier is a near sure thing
		elseif modeP >= 35 then     confirmBody = "@L_WOA_CONFIRM_HOPE_+0"     -- likely, but the spread is real
		else                        confirmBody = "@L_WOA_CONFIRM_UNSURE_+0"   -- up in the air idk maybe
		end
		if MsgBox("", "", "@P".."@B[1,@L_WOA_CONFIRM_YES_+0]".."@B[2,@L_WOA_CONFIRM_NO_+0]", "@L_WOA_CONFIRM_HEAD_+0", confirmBody) ~= 1 then
			StopMeasure(); return
		end

		if not ms_createworkofart_woa_HasMaterials("Workshop", itemId, matFactor) then
			ms_createworkofart_woa_SetMaterialArgs(itemId, matFactor, 1)
			MsgBoxNoWait("", "", "@L_WOA_NOMAT_HEAD_+0", "@L_WOA_NOMAT_BODY_+0")
			StopMeasure(); return
		end

		ms_createworkofart_woa_ConsumeMaterials("Workshop", itemId, matFactor)
		SetProperty("", "WoA_Active", 1)
		SetProperty("", "WoA_Item", itemId)
		SetProperty("", "WoA_Permil", permil)
		SetProperty("", "WoA_Quality", quality)
		SetProperty("", "WoA_DoneHours", 0)
	end

	local skill = GetSkillValue("", CRAFTSMANSHIP)
	if skill < 0 then skill = 0 end
	local targetHours = ms_createworkofart_woa_TargetHours(itemId, skill)

	local accidentChance = 60 - (skill * 5)
	if accidentChance < 5 then accidentChance = 5 end
	local SETBACK_CHECKS = 4
	local sbHit = {}
	local sbDmgPct = {}
	local k = 1
	while k <= SETBACK_CHECKS do
		if Rand(100) < accidentChance then sbHit[k] = 1 else sbHit[k] = 0 end
		sbDmgPct[k] = 5 + Rand(11)
		k = k + 1
	end

	SetContext("", "smithy")
	CarryObject("", "Handheld_Device/Anim_Hammer.nif", false)
	local atAnvil = ms_createworkofart_woa_GotoAnvil()
	local animLen = PlayAnimationNoWait("", "hammer_loop")
	local useAnim = (atAnvil == 1) and animLen and (animLen > 0.001)
	if useAnim then PlayAnimation("", "hammer_in") end

	local doneHours = GetProperty("", "WoA_DoneHours")
	if not doneHours then doneHours = 0 end
	local lastT = GetGametime()
	local lastOH = -100
	local nextCheck = 1
	SetProcessMaxProgress("", 1000)
	while doneHours < targetHours do
		if not GetInsideBuilding("", "Workshop") then
			if useAnim then PlayAnimation("", "hammer_out") end
			CarryObject("", "", false)
			RemoveOverheadSymbol("WoAOH")
			ResetProcessProgress("")
			SetProperty("", "WoA_DoneHours", doneHours)
			StopMeasure(); return
		end

		local now = GetGametime()
		local delta = now - lastT
		if delta < 0 then delta = 0 end
		doneHours = doneHours + delta
		lastT = now

		local pct = (doneHours * 100) / targetHours
		if pct > 100 then pct = 100 end
		SetProcessProgress("", (doneHours * 1000) / targetHours)

		if (pct - lastOH) >= WOA_OH_STEP then
			lastOH = pct
			RemoveOverheadSymbol("WoAOH")
			ShowOverheadSymbol("", true, true, "WoAOH", "@L_WOA_OH_+0", pct)
		end

		while nextCheck <= SETBACK_CHECKS and doneHours >= (targetHours * nextCheck) / (SETBACK_CHECKS + 1) do
			if sbHit[nextCheck] == 1 then
				local before = (doneHours * 100) / targetHours
				targetHours = targetHours + WOA_SETBACK_HOURS
				local after = (doneHours * 100) / targetHours
				SetArg(1, "_ITEM_" .. ItemGetName(itemId) .. "_NAME_+0")
				SetArg(2, before)
				SetArg(3, after)
				MsgBoxNoWait("", "", "@L_WOA_ACCIDENT_SETBACK_HEAD_+0", "@L_WOA_ACCIDENT_SETBACK_BODY_+0")
				lastOH = -100

				local maxhp = GetMaxHP("")
				if maxhp and maxhp > 0 then
					local dmg = (maxhp * sbDmgPct[nextCheck]) / 100
					if dmg < 1 then dmg = 1 end
					ModifyHP("", -dmg, true, 1)
				end
				local hpNow = GetHPRelative("")
				if hpNow >= 0 and hpNow < 0.20 then
					if useAnim then PlayAnimation("", "hammer_out") end
					CarryObject("", "", false)
					RemoveOverheadSymbol("WoAOH")
					ResetProcessProgress("")
					SetProperty("", "WoA_DoneHours", doneHours)
					MsgBoxNoWait("", "", "@L_WOA_ACCIDENT_HURT_HEAD_+0", "@L_WOA_STOPPED_HURT_BODY_+0")
					StopMeasure(); return
				end
			end
			nextCheck = nextCheck + 1
		end

		SetProperty("", "WoA_DoneHours", doneHours)

		if useAnim then
			PlayAnimation("", "hammer_loop")
		else
			Sleep(WOA_TICK_SECONDS)
		end
	end
	if useAnim then PlayAnimation("", "hammer_out") end
	RemoveOverheadSymbol("WoAOH")
	ResetProcessProgress("")
	CarryObject("", "", false)

	local accident = 0
	local interrupted = false
	if Rand(100) < accidentChance then
		if Rand(10) < 6 and quality > 0 then
			quality = quality - 1
			permil = (permil * 7) / 10
			if permil < 200 then permil = 200 end
			accident = 1
		else
			local maxhp = GetMaxHP("")
			local fdmg = 1
			if maxhp and maxhp > 0 then fdmg = (maxhp * (5 + Rand(11))) / 100 end
			if fdmg < 1 then fdmg = 1 end
			ModifyHP("", -fdmg, true, 1)
			accident = 2
			local hp = GetHPRelative("")
			if hp >= 0 and hp < 0.20 then
				interrupted = true
			end
		end
	end

	if interrupted then
		RemoveProperty("", "WoA_Active");  RemoveProperty("", "WoA_Item")
		RemoveProperty("", "WoA_Permil");  RemoveProperty("", "WoA_Quality")
		RemoveProperty("", "WoA_DoneHours")
		MsgBoxNoWait("", "", "@L_WOA_ACCIDENT_HURT_HEAD_+0", "@L_WOA_INTERRUPT_BODY_+0")
		StopMeasure(); return
	end

	InitData("SayPanel", 0, "@L_WOA_NAME_HEAD_+0", "@L_WOA_NAME_BODY_+0")
	local cname = GetData("TF0")
	if not cname then cname = "" end

	local placedWhere = 0
	if CanAddItems("Workshop", itemId, 1, INVENTORY_STD) then
		CreateWorkOfArt("Workshop", itemId, permil, quality, cname, INVENTORY_STD, ""); placedWhere = 1
	elseif CanAddItems("", itemId, 1, INVENTORY_STD) then
		CreateWorkOfArt("", itemId, permil, quality, cname, INVENTORY_STD, ""); placedWhere = 2
	elseif CanAddItems("", itemId, 1, INVENTORY_EQUIPMENT) then
		CreateWorkOfArt("", itemId, permil, quality, cname, INVENTORY_EQUIPMENT, ""); placedWhere = 3
	elseif GetHome("", "WoAHome") and CanAddItems("WoAHome", itemId, 1, INVENTORY_STD) then
		CreateWorkOfArt("WoAHome", itemId, permil, quality, cname, INVENTORY_STD, ""); placedWhere = 4
	end

	local woaXP = 15 + (quality * 13) + (permil / 80)
	if woaXP < 10 then woaXP = 10 end
	IncrementXP("", woaXP)

	RemoveProperty("", "WoA_Active")
	RemoveProperty("", "WoA_Item")
	RemoveProperty("", "WoA_Permil")
	RemoveProperty("", "WoA_Quality")
	RemoveProperty("", "WoA_DoneHours")

	if accident == 2 then
		MsgBoxNoWait("", "", "@L_WOA_ACCIDENT_HURT_HEAD_+0", "@L_WOA_ACCIDENT_HURT_BODY_+0")
	elseif accident == 1 then
		MsgBoxNoWait("", "", "@L_WOA_ACCIDENT_QUAL_HEAD_+0", "@L_WOA_ACCIDENT_QUAL_BODY_+0")
	end

	if placedWhere == 0 then
		MsgBoxNoWait("", "", "@L_WOA_NOROOM_HEAD_+0", "@L_WOA_NOROOM_BODY_+0")
	elseif placedWhere == 4 then
		MsgBoxNoWait("", "", "@L_WOA_DONE_HEAD_+0", "@L_WOA_DONE_HOME_BODY_+0")
	else
		MsgBoxNoWait("", "", "@L_WOA_DONE_HEAD_+0", "@L_WOA_DONE_BODY_+0")
	end

	StopMeasure()
end

function CleanUp()
	ResetProcessProgress("")
	RemoveOverheadSymbol("WoAOH")
	CarryObject("", "", false)
end
