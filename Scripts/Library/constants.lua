-- -----------------------
-- Shared lookup tables.
--
-- Registered in Library/stdafx.lua, so every function here is reachable from any
-- script as constants_<Name>.
-- -----------------------
function Init()
 --needed for caching
end

-- Nobility title number -> name, with the rung baked into the string so the order
-- is readable wherever it is printed.
--
-- The key is the number GetNobilityTitle() returns: the 1-based id of
-- DB/NobilityTitle.dbt, 1 at the bottom of the ladder and 14 at the top. Keeping
-- the key equal to the engine's own number matters -- a 0-based table would not
-- line up with the comparisons in the scripts.
--
-- The English names are from the community wikis, cross-checked against the German
-- words in NobilityTitle.dbt (given after each entry). Title 6 is confirmed in
-- game: characters show as "Free Citizen <name>". The names are not in any shipped
-- text table, so a player-facing string should still come from
-- GetNobilityTitleLabel(n) passed as a %1l argument; use this map for logs,
-- ordering and comparisons.
--
-- 9 and 10 are the shakiest: Freiherr and Baron are the same rank historically, so
-- the two adjacent rungs are reported both as Baron / Allodial Baron and as
-- Landgrave / Baronet. Verify in game before showing either to a player.
Title_to_string_map = {
	[1]  = "Serf [1]",							-- Unfreier
	[2]  = "Commoner [2]",						-- Gemeiner
	[3]  = "Yeoman [3]",						-- Freisasse
	[4]  = "Citizen without Full Rights [4]",	-- Beisasse
	[5]  = "Citizen [5]",						-- Buerger
	[6]  = "Free Citizen [6]",					-- Freibuerger, confirmed in game
	[7]  = "Patrician [7]",						-- Patrizier, grants the Nobility passive
	[8]  = "Nobleman [8]",						-- Edelmann, first rung needing imperial fame
	[9]  = "Baron [9]",							-- Freiherr, may be Landgrave
	[10] = "Allodial Baron [10]",				-- Baron, may be Baronet
	[11] = "Count [11]",						-- Graf
	[12] = "Marquis [12]",						-- Markgraf
	[13] = "Prince [13]",						-- Fuerst
	[14] = "Imperial Prince [14]"				-- Reichsfuerst
}

-- Patrician, the rung where the Nobility passive is granted -- observed in game.
-- Not the same boundary as the imperial fame gate: minimperialfame in
-- NobilityTitle.dbt first goes above zero one rung later, at Nobleman.
GL_TITLE_FIRST_NOBLE = 7

-- Returns nil for a number off the ladder rather than a half-formed string, so a
-- caller can tell the difference.
function TitleName(Title)
	return Title_to_string_map[Title]
end
