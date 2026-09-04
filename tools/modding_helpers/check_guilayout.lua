-- Offline check for Library/guilayout.lua. Run from the repo root:
--
--   lua5.1 tools/modding_helpers/check_guilayout.lua
--
-- The engine is not needed: the node API is four getters and two setters, so a
-- table with those methods is a faithful stand-in. The trees below are real
-- geometry, copied from a @HELPPANEL dump of a running game, which is what makes
-- the assertions worth anything.

local function Node(name, height, texture, kids)
	local n = {
		name	= name,
		height	= height,
		texture	= texture or "",
		kids	= kids or {}
	}
	function n:GetName() return self.name end
	function n:GetChildCnt() return #self.kids end
	function n:GetChildAt(i) return self.kids[i + 1] end
	function n:GetValueString(Property)
		if Property == "TEXTURE_FILENAME" then return self.texture end
		return ""
	end
	function n:GetValueInt(Property)
		if Property == "ABS_HEIGHT" then return self.height end
		return 0
	end
	function n:SetValueInt(Property, Value)
		if Property == "ABS_HEIGHT" then self.height = Value end
	end
	return n
end

local BG = "Hud/sheets/onscreenhelp/bg.tga"

-- Engine globals the library uses.
LogMessage = function() end
local Rooted
FindNode = function() return Rooted end

dofile("Scripts/Library/guilayout.lua")

local Failures = 0
local function Check(Label, Got, Want)
	if Got ~= Want then
		print("FAIL  " .. Label .. ": got " .. tostring(Got) .. ", want " .. tostring(Want))
		Failures = Failures + 1
	end
end

-- -----------------------
-- Panel 43: the measures / items / upgrades layout, the one that was clipping
-- Break bones. Panel, frame and Label must grow; art and the button strip
-- must not.
-- -----------------------
local Label43 = Node("Label", 217)
local Frame43 = Node("cl_WinContainer", 394, BG)
local Icon43 = Node("Icon", 42)
local Strip43 = Node("Container", 38)
local Panel43 = Node("Container", 394, "", {
	Node("cl_Sprite", 61), Node("cl_Sprite", 42), Icon43, Label43, Frame43, Strip43
})

Check("panel 43 nodes grown", GrowPanel(Panel43, 120), 3)
Check("panel 43 panel height", Panel43.height, 514)
Check("panel 43 frame height", Frame43.height, 514)
Check("panel 43 text height", Label43.height, 337)
Check("panel 43 icon untouched", Icon43.height, 42)
Check("panel 43 button strip untouched", Strip43.height, 38)

-- -----------------------
-- Panel 39, the character help panel. Its Content wrapper holds an Icon 313px
-- tall, and a rule that went by height alone stretched that portrait. Art stays
-- put however tall it is. RVContainer is skill bars, not text, so it stays too.
-- -----------------------
local Portrait = Node("Icon", 313)
local Content39 = Node("Content", 477, BG, { Portrait })
local Bars39 = Node("RVContainer", 324)
local Caption39 = Node("Desc", 19)
local Panel39 = Node("Container", 477, "", {
	Content39, Node("Label", 128), Caption39, Bars39, Node("DynastyIcon", 51), Node("Container", 38)
})

GrowPanel(Panel39, 120)
Check("panel 39 tall art untouched", Portrait.height, 313)
Check("panel 39 skill bars untouched", Bars39.height, 324)
Check("panel 39 one-line caption untouched", Caption39.height, 19)
Check("panel 39 frame grown", Content39.height, 597)

-- -----------------------
-- Panel 42. Its Label is 226 against a 596px panel -- under 40% of it, so a
-- height-share rule left this description unable to grow at all.
-- -----------------------
local Label42 = Node("Label", 226)
local Desc42 = Node("Desc", 209)
local Panel42 = Node("Container", 596, "", {
	Node("Container", 596, BG), Node("LResource", 22), Node("ItemContainer", 153), Label42, Desc42
})

GrowPanel(Panel42, 120)
Check("panel 42 text grown", Label42.height, 346)
Check("panel 42 second text grown", Desc42.height, 329)

-- -----------------------
-- Finding the cohort. The texture sits on a descendant, not on the panel, and
-- it is matched case-insensitively as a substring.
-- -----------------------
Rooted = Node("HudRoot", 0, "", {
	Node("Container", 400, "", { Node("Inner", 400, BG) }),
	Node("Container", 300, "", { Node("Inner", 300, "Hud/sheets/other.tga") }),
	Node("Container", 200, BG)
})
Check("cohort matched", #FindPanelsByTexture("ignored", "onscreenhelp/bg"), 2)

-- Nothing matches: refuse rather than guess, and change nothing.
Rooted = Node("HudRoot", 0, "", { Node("Container", 400) })
Check("empty cohort grows nothing", GrowHelpPanels(120), 0)

-- A missing root must not raise out of HudInit.
Rooted = nil
Check("missing root grows nothing", GrowHelpPanels(120), 0)

if Failures == 0 then
	print("OK: 14 checks on guilayout")
else
	print(Failures .. " failure(s)")
	os.exit(1)
end
