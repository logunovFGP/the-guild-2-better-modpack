-- -----------------------
-- Resizing GUI panels at runtime.
--
-- The .gui files under GUI/ are binary serialised, so a panel size cannot be
-- edited there. It can be changed on the live node tree instead, which is what
-- this does. Registered in Library/stdafx.lua, so the entry points are reachable
-- from any script as guilayout_<Name>.
--
-- WHAT IS ACTUALLY TRUE OF THIS ENGINE, all of it verified in game:
--
--   * ABS_HEIGHT and ABS_WIDTH are the only geometry properties that carry a
--     value. HEIGHT, WIDTH and ABS_YPOS all read 0 on every node.
--   * A write at HudInit survives into a layout that happens much later, when
--     the panel is first displayed. That is why this works at all.
--   * RESIZE and SHOW_VERTICAL_SCROLLBAR do NOT work. Both read back changed and
--     neither has any effect: no fitting to content, no scrollbar. The engine
--     consults them when it builds a panel and never again. Reading back a
--     changed value proves the property store accepted it, nothing more.
--   * Every change is per-session and gone on restart. Nothing persists without
--     re-applying it at HudInit -- which also means a bad write is recoverable
--     by quitting.
--
-- A window is NOT one node that its parts inherit from. It is a panel plus
-- siblings that each hold their own height:
--
--   Container            the panel, ABS_HEIGHT 394
--     cl_WinContainer    the bordered frame, ABS_HEIGHT 394 -- the same height,
--                        and it KEEPS that height when the panel grows
--     Label              the description text, ABS_HEIGHT 217 -- this is what
--                        cuts a long description off mid-sentence
--     Icon, cl_Sprite    art
--     Header             ~27-32px
--     Container          the 38px button strip
--
-- So growing the panel alone only exposes the panel backdrop below the border
-- and reveals no extra text. The panel, the frame and the text node all have to
-- be set. That is the whole trick.
-- -----------------------
function Init()
 --needed for caching
end

-- The HudRoot path, built with string.char rather than written as a literal.
-- The path needs one backslash before each segment, and every tool that has
-- edited these files -- heredocs, shell quoting, helper scripts -- has at some
-- point halved or doubled a backslash escape and left the syntax valid but the
-- path wrong. The only symptom is FindNode returning nil. No backslash in the
-- source, no way to get it wrong.
GL_HUDROOT = string.char(92) .. "GUI" .. string.char(92) .. "HudRoot"

-- All 13 Helppanels/*.gui carry this texture and nothing else in the tree does,
-- which is the only reliable way to find them: a panel takes NODE_NAME from its
-- .gui so they are all plain "Container", the AddPanel order does not map onto
-- the HudRoot child order, and measures.gui / items.gui / upgrades.gui share
-- every extractable string. 11 of the 13 are HudRoot children at HudInit.
GL_HELP_PANEL_TEXTURE = "onscreenhelp/bg"

-- Six lines of headroom at the ~19px these panels render at. There is no way to
-- ask the engine how tall the wrapped text came out, so a fixed number is the
-- only option -- it is a ceiling, not a fit. The worst overflow found, the
-- Break bones measure description, lost about two lines.
-- ponytail: fixed headroom, measure the text instead if a description outgrows it
GL_HELP_PANEL_HEADROOM = 120

-- Set true to log every node touched. Off by default: the summary line is
-- enough once it works, and the per-node lines run 30-odd per launch.
GL_GUILAYOUT_VERBOSE = false

-- Names of nodes that hold a block of text, lowercased. Grown by name rather
-- than by size, because size alone cannot tell a 313px portrait from a 217px
-- paragraph -- a height-share rule stretched an Icon on the character panel and
-- still missed a 226px Label on a taller one.
local TEXT_NODES = {
	label		= true,
	desc		= true,
	text		= true,
	general		= true,
	pricedesc	= true
}

-- A child within this many pixels of its panel height is the bordered frame.
local FRAME_TOLERANCE = 4

-- Below this a named text node is a one-line caption -- a "Price", a 19px
-- "Desc" -- where extra height buys nothing.
local MIN_TEXT_HEIGHT = 60

-- How deep to look for the cohort texture, and how deep to grow. The frame and
-- the text node are direct children, but a panel can wrap them in one more
-- container, so 2 covers what has been seen with room to spare.
local SEARCH_DEPTH = 4
local GROW_DEPTH = 2

-- More matches than this means the fingerprint is wrong, and a wrong fingerprint
-- has already stretched the multiplayer lobby once. Refuse rather than guess.
local SANITY_LIMIT = 20

local function Int(Node, Property)
	local ok, value = pcall(function() return Node:GetValueInt(Property) end)
	if ok then
		return value
	end
	return nil
end

local function Str(Node, Property)
	local ok, value = pcall(function() return Node:GetValueString(Property) end)
	if ok and value then
		return tostring(value)
	end
	return ""
end

local function Name(Node)
	local ok, value = pcall(function() return Node:GetName() end)
	if ok and value then
		return tostring(value)
	end
	return "?"
end

local function ChildCount(Node)
	local ok, count = pcall(function() return Node:GetChildCnt() end)
	if ok and count then
		return count
	end
	return 0
end

local function ChildAt(Node, Index)
	local ok, kid = pcall(function() return Node:GetChildAt(Index) end)
	if ok then
		return kid
	end
	return nil
end

local function HasTexture(Node, Texture, Depth)
	if string.find(string.lower(Str(Node, "TEXTURE_FILENAME")), Texture, 1, true) then
		return true
	end
	if Depth <= 0 then
		return false
	end
	for i = 0, ChildCount(Node) - 1 do
		local Kid = ChildAt(Node, i)
		if Kid and HasTexture(Kid, Texture, Depth - 1) then
			return true
		end
	end
	return false
end

-- Returns true if the height changed. A node can refuse silently, so the
-- read-back is the only way to know.
local function Raise(Node, Bonus)
	local Before = Int(Node, "ABS_HEIGHT")
	if not Before or Before <= 0 then
		return false
	end
	pcall(function() Node:SetValueInt("ABS_HEIGHT", Before + Bonus) end)
	local After = Int(Node, "ABS_HEIGHT")
	local Took = After ~= nil and After ~= Before
	if GL_GUILAYOUT_VERBOSE then
		LogMessage("@GUILAYOUT   " .. Name(Node) .. " " .. tostring(Before) ..
					" -> " .. tostring(After) .. (Took and "  TOOK" or "  IGNORED"))
	end
	return Took
end

-- The bordered frame, or a block of text. Everything else -- art, headers, the
-- button strip -- is left alone, because there a height change moves content
-- rather than revealing it.
local function WantsHeight(Node, PanelHeight)
	local Height = Int(Node, "ABS_HEIGHT")
	if not Height or Height <= 0 then
		return false
	end
	if math.abs(Height - PanelHeight) <= FRAME_TOLERANCE then
		return true
	end
	return TEXT_NODES[string.lower(Name(Node))] == true and Height >= MIN_TEXT_HEIGHT
end

local function GrowInside(Node, PanelHeight, Bonus, Depth)
	local Grown = 0
	for i = 0, ChildCount(Node) - 1 do
		local Kid = ChildAt(Node, i)
		if Kid then
			if WantsHeight(Kid, PanelHeight) then
				if Raise(Kid, Bonus) then
					Grown = Grown + 1
				end
			end
			if Depth > 0 then
				Grown = Grown + GrowInside(Kid, PanelHeight, Bonus, Depth - 1)
			end
		end
	end
	return Grown
end

-- -----------------------
-- Entry points.
-- -----------------------

-- Every child of RootPath carrying Texture in its TEXTURE_FILENAME, or whose
-- descendants do. Texture is matched lowercased as a plain substring, so
-- "onscreenhelp/bg" finds "Hud/sheets/onscreenhelp/bg.tga".
--
-- Returns a list of nodes, empty if the root is missing.
function FindPanelsByTexture(RootPath, Texture, Depth)
	local Found = {}
	local Root = FindNode(RootPath)
	if not Root then
		LogMessage("@GUILAYOUT " .. tostring(RootPath) .. " not found")
		return Found
	end
	for i = 0, ChildCount(Root) - 1 do
		local Kid = ChildAt(Root, i)
		if Kid and HasTexture(Kid, string.lower(Texture), Depth or SEARCH_DEPTH) then
			Found[#Found + 1] = Kid
		end
	end
	return Found
end

-- Makes one window Bonus pixels taller: the panel, its bordered frame and any
-- text block inside it. Returns how many nodes actually changed -- 3 for a
-- typical help window, 0 meaning nothing was touched.
function GrowPanel(Panel, Bonus)
	local Height = Int(Panel, "ABS_HEIGHT")
	if not Height or Height <= 0 then
		return 0
	end
	local Grown = 0
	if Raise(Panel, Bonus) then
		Grown = Grown + 1
	end
	return Grown + GrowInside(Panel, Height, Bonus, GROW_DEPTH)
end

-- Gives every on-screen help window room for a longer description. Call once
-- from HudInit; the change is per-session, so it has to run on every launch.
--
-- Bonus defaults to GL_HELP_PANEL_HEADROOM. Never raises: a wrong fingerprint or
-- a missing node lands in the log and leaves the GUI untouched.
function GrowHelpPanels(Bonus)
	local Grown = 0
	local ok, err = pcall(function()
		Bonus = Bonus or GL_HELP_PANEL_HEADROOM
		local Panels = FindPanelsByTexture(GL_HUDROOT, GL_HELP_PANEL_TEXTURE)
		if #Panels == 0 or #Panels > SANITY_LIMIT then
			LogMessage("@GUILAYOUT help panels: " .. #Panels ..
						" matched, outside the sane range, changing nothing")
			return
		end
		for i = 1, #Panels do
			Grown = Grown + GrowPanel(Panels[i], Bonus)
		end
		LogMessage("@GUILAYOUT help panels: " .. #Panels .. " matched, " .. Grown ..
					" nodes grown by " .. Bonus .. "px")
	end)
	if not ok then
		LogMessage("@GUILAYOUT error: " .. tostring(err))
	end
	return Grown
end
