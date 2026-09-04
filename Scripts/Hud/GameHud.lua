function Init()

	-- Steam Networking
	this:AddPanel("JoinRequestPanel","cl_StaticPanel","",false,true)
	this:AddPanel("ResyncRequestPanel","cl_StaticPanel","",false,true)
	this:AddPanel("ResyncMessage","cl_StaticPanel","",false,true)

   -- InGame Menus
  	this:AddPanel("InGameMenu","cl_StartMenuPanel","gui/menu/ingamemenu.gui",false)
  	this:AddPanel("InGameQuit","cl_StartMenuPanel","gui/menu/ingame_quitgame.gui",false)
  	this:AddPanel("InGameBack","cl_StartMenuPanel","gui/menu/ingame_quitgame.gui",false)
	this:AddPanel("ChatWindow","cl_ChatPanel","gui/Hud/panel_chat.gui",false)	
	this:AddPanel("WorldDeleteSheet", "cl_MessageBox","GUI/Menu/panel_delete_world.gui",false)
	this:AddPanel("SelectSaveGame","cl_StartMenuPanel","gui/menu/SelectSaveGame.gui",false)
 	this:AddPanel("RestartWarning","cl_StartMenuPanel","gui/menu/restartwarning.gui",false) 	
 	this:AddPanel("Options_Gfx","cl_StartMenuPanel","gui/menu/options_gfx.gui",false)
 	this:AddPanel("Options_Game","cl_StartMenuPanel","gui/menu/options_game.gui",false)
 	this:AddPanel("Options_Sound","cl_StartMenuPanel","gui/menu/options_sound.gui",false)
 	this:AddPanel("Options_Keymapper","cl_StartMenuPanel","gui/menu/options_key.gui",false)
 	this:AddPanel("Options_Keymapper_Popup","cl_StartMenuPanel","gui/menu/options_key_popup.gui",false)
 	this:AddPanel("Options_Keymapper_Restart","cl_StartMenuPanel","gui/menu/options_key_restart.gui",false)
 	this:AddPanel("Options_Keymapper_RestartActivePlay","cl_StartMenuPanel","gui/menu/options_key_restartactiveplay.gui",false)
 	this:AddPanel("Options_Keymapper_Duplicate","cl_StartMenuPanel","gui/menu/options_key_duplicate.gui",false)
 	this:AddPanel("Options_Keymapper_Debug","cl_StartMenuPanel","gui/menu/options_key_debug.gui", false)
 	this:AddPanel("WorldOverwriteSheet", "cl_MessageBox","GUI/Menu/panel_overwrite_world.gui",false)
 	this:AddPanel("SavingSheet","cl_MessageBox","gui/Menu/panel_saving.gui",false)
 	this:AddPanel("OptionsSheet","cl_OptionsSheet","gui/Menu/savegame.gui",false)

 	--this:AddPanel("Console", "cl_StartMenuPanel", "gui/hud/panel_console.gui", false) 


 	
 	
 	-- debug
 	this:AddPanel("HudRootAnalyser","cl_TestPanel","gui/debug/hudrootanalyser/warningpopup.gui", false) -- cl_TrialPanel

 	-- this:AddPanel("TestPanel","cl_TestPanel","gui/Hud/panel_test.gui",false)
 	this:AddPanel("PausePanel","cl_PausePanel","gui/Hud/panel_pause.gui",false)
 	 	
 	this:AddPanel("SystemMessagePanel","cl_InfoPanel","gui/Hud/panel_systemmessage.gui",true,true)
 	this:AddPanel("QuickMessagePanel","cl_InfoPanel","gui/Hud/panel_quickmessage.gui",true,true)
 	
 	this:AddPanel("ClientListPanel","cl_ClientListPanel","gui/Menu/clientlist.gui",false)
 	
 	-- tutorial
 	-- this:AddPanel("TutorialPanel","cl_TutorialPanel","gui/hud/panel_tutorial.gui", false)
 	
 	-- onscreen help
 	this:AddPanel("Guide","cl_GuidePanel","", false)

 	this:AddPanel("HelpCharacters","cl_OnscreenHelpPanel","gui/Hud/Helppanels/characters.gui",false)
	this:AddPanel("HelpSkill","cl_OnscreenHelpPanel","gui/Hud/Helppanels/skill.gui",false)
 	this:AddPanel("HelpItems","cl_OnscreenHelpPanel","gui/Hud/Helppanels/items.gui",false)
 	this:AddPanel("HelpBuildings","cl_OnscreenHelpPanel","gui/Hud/Helppanels/buildings.gui",false)
 	this:AddPanel("HelpUpgrades","cl_OnscreenHelpPanel","gui/Hud/Helppanels/upgrades.gui",false)
 	this:AddPanel("HelpCarts","cl_OnscreenHelpPanel","gui/Hud/Helppanels/carts.gui",false)
 	this:AddPanel("HelpMeasures","cl_OnscreenHelpPanel","gui/Hud/Helppanels/measures.gui",false)
 	this:AddPanel("HelpOffices","cl_OnscreenHelpPanel","gui/Hud/Helppanels/offices.gui",false)
 	this:AddPanel("HelpSettlement","cl_OnscreenHelpPanel","gui/Hud/Helppanels/settlement.gui",false)
 	this:AddPanel("HelpText","cl_OnscreenHelpPanel","gui/Hud/Helppanels/text.gui",false)
 	this:AddPanel("HelpShip","cl_OnscreenHelpPanel","gui/Hud/Helppanels/ship.gui",false)
 	
	-- Messagebox will be shown at this z-range
 	 	 	
 	this:AddPanel("ContextMenu","cl_ContextMenu","",false)
 	
 	-- sheets
 	this:AddPanel("SheetNavi","cl_SheetNavigation","gui/Hud/sheet_navi.gui",false)
 	this:AddPanel("SheetHeader","cl_SheetHeader","gui/Hud/sheet_header.gui",false)
 	
 	this:AddPanel("Connection2","cl_InventoryPanel","gui/Hud/panel_connection_02.gui",false)
 	this:AddPanel("InventorySheet","cl_InventorySheet","gui/Hud/panel_inventorysheet.gui",false)
 	this:AddPanel("TransportSheet","cl_TransportSheet","gui/Hud/panel_transportsheet.gui",false)
 	this:AddPanel("ShipSheet","cl_ShipSheet","gui/Hud/panel_shipsheet.gui",false)
 	this:AddPanel("Connection1","cl_InventoryPanel","gui/Hud/panel_connection_01.gui",false)
 	this:AddPanel("Connection3","cl_InventoryPanel","gui/Hud/panel_connection_03.gui",false)
 	this:AddPanel("StoreSheet","cl_StoreSheet","gui/Hud/panel_storesheet.gui",false)
 	this:AddPanel("ProductionSheet","cl_ProductionSheet","gui/Hud/panel_productionsheet.gui",false)

 	this:AddPanel("BuildingStatisticsSheet","cl_BuildingStatisticsSheet","",false)
 	this:AddPanel("CityNeedsSheet","cl_CityNeedsSheet","",false)
 	this:AddPanel("SimHistorySheet","cl_SimHistorySheet","",false)

 	this:AddPanel("MarketInventorySheet","cl_MarketInventorySheet","gui/Hud/panel_marketinventory2.gui",false)
 	-- this:AddPanel("NewMarketSheet","cl_NewMarketSheet","",false)
 	this:AddPanel("KontorPanel","cl_KontorPanel","",false)
 	this:AddPanel("BuildBuildingPatron","cl_BuildBuildingSheet","gui/Hud/panel_buildbuildingsheet_workshop.gui",false)
	this:AddPanel("BuildBuildingArtisan","cl_BuildBuildingSheet","gui/Hud/panel_buildbuildingsheet_workshop.gui",false)
	this:AddPanel("BuildBuildingScholar","cl_BuildBuildingSheet","gui/Hud/panel_buildbuildingsheet_workshop.gui",false)
	this:AddPanel("BuildBuildingChiseler","cl_BuildBuildingSheet","gui/Hud/panel_buildbuildingsheet_workshop.gui",false)
	--this:AddPanel("BuildBuildingSettlement","cl_BuildBuildingSheet","gui/Hud/panel_buildbuildingsheet_workshop.gui",false)
	this:AddPanel("BuildBuildingMisc","cl_BuildBuildingSheet","gui/Hud/panel_buildbuildingsheet_workshop.gui",false)
	this:AddPanel("BuildBuildingOffice","cl_BuildBuildingSheet","gui/Hud/panel_buildbuildingsheet_workshop.gui",false)


	-- Rags to Riches
	--this:AddPanel("BuildBuildingAll","cl_BuildBuildingSheet","gui/Rags/construct.gui",false)
	this:AddPanel("Achievements", "cl_AchievementsSheet", "gui/Hud/panel_achievements.gui", false)

 	-- Buttons have to be above of the sheets. Map has to be above of buttons. News have to be above the buttons
 	this:AddPanel("IndoorMapPanel","cl_IndoorMap","gui/Hud/panel_indoormap.gui")

 	this:AddPanel("NewsPanel","cl_NewsPanel","gui/Hud/panel_news.gui",true)
	this:AddPanel("ActionsPanel","cl_ActionsPanel2","gui/Hud/panel_actions2.gui")
	this:AddPanel("MeasureMessagePanel","cl_MeasureMessagePanel","gui/Hud/panel_measuremessage.gui",true,true)

	-- body
	this:AddPanel("ButtonPanelLeft","cl_ButtonPanel","gui/Hud/panel_down_left.gui")
	this:AddPanel("ButtonPanelRight","cl_ButtonPanel","gui/Hud/panel_down_right.gui")
	this:AddPanel("ButtonPanelDecorator","cl_StaticPanel","gui/Hud/panel_down_middle.gui")

 	-- start sheets
 	this:AddPanel("AdministrateDiplomacySheet", "cl_AdministrateDiplomacySheet", "gui/Hud/panel_diplomacy.gui",false)
	this:AddPanel("ImportantPersons", "cl_OverviewImportantPersonsSheet", "gui/Hud/panel_importantpersons.gui",false)
	this:AddPanel("OverviewBuildings","cl_OverviewBuildingsSheet","gui/Hud/panel_overviewbuildings2.gui",false)
	
	-- added for buildings for sale
	this:AddPanel("OverviewBuildingsForSaleSheet","cl_OverviewBuildingsForSaleSheet","gui/Hud/panel_overviewbuildingsforsale.gui",false)
	
	this:AddPanel("BuildingUpgradeSheet","cl_BuildingUpgradeTreePanel","gui/Hud/panel_upgradesheet.gui",false)
 	this:AddPanel("ShowCreditSheet","cl_CreditSheet","gui/Hud/panel_takecredit_final.gui", false)
	this:AddPanel("ChangeAppearancePanel","cl_ChangeAppearancePanel","gui/Hud/panel_changeappearance.gui", false)
 	this:AddPanel("_AdministrateBuilding","cl_AdministrateBuilding","gui/Hud/panel_AdministrateBuilding.gui", false)
 	this:AddPanel("_UpgradeShipSheet", "cl_UpgradeShipSheet", "gui/Hud/panel_upgradeship.gui",false)
	-- this:AddPanel("MessageBoxPanel","cl_MessageBoxPanel","gui/Hud/panel_messagebox.gui",false)
		
	this:AddPanel("_BuildingLevelTreeSheet","cl_BuildingLevelTreePanel","gui/Hud/panel_buildinglevelup.gui",false)
	this:AddPanel("DynastyStatusSheet","cl_DynastyStatusSheet","gui/Hud/panel_dynastystatussheet.gui",false)
	
	this:AddPanel("DiarySheet","cl_DiarySheet","gui/Hud/panel_diarysheet.gui",false)
	this:AddPanel("DatebookSheet","cl_DatebookSheet","gui/Hud/panel_datebooksheet.gui",false)
	this:AddPanel("EvidenceSheet","cl_MemorySheet","gui/Hud/panel_evidencesheet.gui",false)
	this:AddPanel("QuestbookSheet","cl_QuestbookSheet","gui/Hud/panel_questbooksheet.gui",false)
	
	this:AddPanel("AbilitySheet","cl_AbilitySheet","gui/Hud/panel_abilitysheet.gui",false)
	this:AddPanel("CharacterSheet","cl_CharacterSheet","gui/Hud/panel_charactersheet.gui",false)
	this:AddPanel("FamilyTreeSheet","cl_FamilyTreeSheet","gui/Hud/panel_familytreesheet.gui",false)
	this:AddPanel("MapSheet","cl_MapSheet","gui/Hud/panel_mapsheet.gui",false)
	this:AddPanel("_MessageFilterSheet","cl_MessageFilterSheet","gui/Hud/panel_messagefiltersheet.gui",false)
	this:AddPanel("_BuyCartSheet","cl_BuyCartSheet","gui/Hud/panel_buycart.gui",false)
	this:AddPanel("_BuyShipSheet","cl_BuyCartSheet","gui/Hud/panel_buyship.gui",false)
   this:AddPanel("_CityLawsSheet","cl_CityLawsSheet","gui/Hud/panel_citylaws.gui",false)
   this:AddPanel("_CityScheduleSheet","cl_CityScheduleSheet","gui/Hud/panel_cityschedule.gui",false)
	
	this:AddPanel("StatisticsBalanceLast","cl_BalanceSheet","gui/Hud/panel_balancesheet2.gui",false)
	this:AddPanel("StatisticsBalanceTotal","cl_BalanceSheet","gui/Hud/panel_balancesheet2.gui",false)	
	this:AddPanel("StatisticsSheetGold","cl_StatisticsSheet","gui/Hud/panel_statisticsheet.gui",false)
	this:AddPanel("StatisticsSheetAsset","cl_StatisticsSheet","gui/Hud/panel_statisticsheet.gui",false)
	--	this:AddPanel("StatisticsSheetSkill","cl_StatisticsSheet","gui/Hud/panel_statisticsheet.gui",false)
	--	this:AddPanel("StatisticsSheetAlign","cl_StatisticsSheet","gui/Hud/panel_statisticsheet.gui",false)
	--	this:AddPanel("StatisticsSheetPoints","cl_StatisticsSheet","gui/Hud/panel_statisticsheet.gui",false)
	
	this:AddPanel("_PamphletSheet","cl_PamphletSheet","gui/Hud/panel_pamphletsheet.gui",false)
	
	-- end sheets
	
	this:AddPanel("CharactersPanel","cl_CharactersPanel","gui/Hud/panel_characters.gui")
	this:AddPanel("ProgressPanel","cl_ProgressPanel","gui/Hud/panel_loverprogress.gui",false)
	this:AddPanel("MFDPanel","cl_MFD","gui/Hud/panel_mfd.gui")
	this:AddPanel("HirePanel","cl_HirePanel","gui/Hud/panel_treesheet.gui", false)
	
   -- Cutscene Panels
   this:AddPanel("TrialPanel","cl_TrialPanel","gui/Hud/panel_charge.gui",false,true)
   this:AddPanel("WeddingPanel","cl_WeddingPanel","gui/Hud/panel_charge.gui",false,true)
   this:AddPanel("OfficeApplicationPanel","cl_OfficeApplicationPanel","gui/Hud/panel_officeapplication.gui",false,true)
   this:AddPanel("OfficeDepositionPanel","cl_OfficeDepositionPanel","gui/Hud/panel_officedeposition.gui",false,true)
   this:AddPanel("BattleScreen", "cl_RenderCustomPanel", "gui/Hud/battle.gui", false, true)

	this:AddPanel("ImpactIconPanel","cl_ImpactIconPanel","gui/Hud/panel_impacticon.gui")
	
	-- Header
	this:AddPanel("HeaderName","cl_DatePanel","gui/Hud/panel_header_name.gui")  	
	this:AddPanel("HeaderSeason","cl_DatePanel","gui/Hud/panel_header_season.gui")  
	this:AddPanel("HeaderMoney","cl_DatePanel","gui/Hud/panel_header_money.gui")  
	this:AddPanel("HeaderDecorator","cl_StaticPanel","gui/Hud/panel_header_leiste.gui")
	--this:AddPanel("HeaderAchievements","cl_DatePanel","gui/Hud/panel_header_achievement.gui")
	
	this:AddPanel("RenderViewPanel","cl_RenderViewPanel","gui/Hud/panel_3dview.gui",true)
	this:AddPanel("MultiselectionPanel","cl_MultiselectionPanel","gui/Hud/panel_multiselection.gui")
	
	this:AddPanel("CountdownPanel","cl_CountdownPanel","gui/Hud/panel_countdown.gui",true,false)
	
	this:AddPanel("QuestlogPanel","cl_QuestlogPanel","gui/Hud/panel_questlog.gui",false)
	this:AddPanel("NPCPanel","cl_NPCPanel","gui/Hud/panel_npc.gui")
	-- this:AddPanel("MessagePanel","cl_MessagePanel","gui/Hud/panel_message.gui")

	-- Overalls
	this:AddPanel("Overall_Lodge","cl_ButtonPanel","gui/Hud/panel_overall_lodge.gui",false)
	this:AddPanel("Overall_Bank","cl_ButtonPanel","gui/Hud/panel_overall_bank.gui",false)
	
	this:AddPanel("DialogPanel","cl_DialogPanel","gui/Hud/panel_dialog.gui",true,true)
	this:AddPanel("StatusPanel","cl_StatusPanel","",true,true)
	this:AddPanel("LetterBoxPanel","cl_LetterBoxPanel","gui/Hud/panel_letterbox.gui",false,true)
	this:AddPanel("UserInputPanel","cl_UserInputPanel","",true,true)

	-- define Tabgroups
	-- BuildBuildin
	this:AddSheetToTabGroup("BuildBuilding","BuildBuildingPatron","@L_CHARACTERS_1_CLASSES_patron_NAME_+0")
	--this:AddSheetToTabGroup("BuildBuilding","BuildBuildingAll","Rags to Riches")
	this:AddSheetToTabGroup("BuildBuilding","BuildBuildingArtisan","@L_CHARACTERS_1_CLASSES_artisan_NAME_+0")
	this:AddSheetToTabGroup("BuildBuilding","BuildBuildingScholar","@L_CHARACTERS_1_CLASSES_scholar_NAME_+0")
	this:AddSheetToTabGroup("BuildBuilding","BuildBuildingChiseler","@L_CHARACTERS_1_CLASSES_chiseler_NAME_+0")
	--this:AddSheetToTabGroup("BuildBuilding","BuildBuildingSettlement","Settlement")
	this:AddSheetToTabGroup("BuildBuilding","BuildBuildingMisc","@L_BUILDBUILDING_MISC_+0")
	this:AddSheetToTabGroup("BuildBuilding","BuildBuildingOffice","@L_BUILDBUILDING_OFFICE_+0")
	this:SetTabGroupHeader("BuildBuilding","@L_BUILDBUILDING_+1")

	-- Statistics
	this:AddSheetToTabGroup("Statistics","StatisticsBalanceLast","@L_BALANCE_PANELNAMES_+0")
	this:AddSheetToTabGroup("Statistics","StatisticsBalanceTotal","@L_BALANCE_PANELNAMES_+1")		
	this:AddSheetToTabGroup("Statistics","StatisticsSheetGold","@L_GAMESTATISTICS_FINANCE_+0")
	this:AddSheetToTabGroup("Statistics","StatisticsSheetAsset","@L_GAMESTATISTICS_ASSETS_+0")
	--	this:AddSheetToTabGroup("Statistics","StatisticsSheetSkill","@L_GAMESTATISTICS_SKILLLEVEL_+0")
	-- this:AddSheetToTabGroup("Statistics","StatisticsSheetAlign","@L_GAMESTATISTICS_ALIGNMENT_+0")
	--	this:AddSheetToTabGroup("Statistics","StatisticsSheetPoints","@L_GAMESTATISTICS_POINTS_+0")
	this:SetTabGroupHeader("Statistics","@L_GAMESTATISTICS_HEADLINE_+0")
		
	-- DiarySheet
	this:AddSheetToTabGroup("Diary","DiarySheet","@L_DIARY_+0")
	this:AddSheetToTabGroup("Diary","DatebookSheet","@L_DATEBOOK_+0")
	this:AddSheetToTabGroup("Diary","EvidenceSheet","@L_EVIDENCES_+0")
	this:AddSheetToTabGroup("Diary","QuestbookSheet","@L_QUESTBOOK_+0")
	this:SetTabGroupHeader("Diary","@L_DIARY_+1")
	
	-- character sheet
	this:AddSheetToTabGroup("Character","CharacterSheet","@L_CHARACTER_+0")
	this:AddSheetToTabGroup("Character","AbilitySheet","@L_ABILITIES_+0")
	this:AddSheetToTabGroup("Character","FamilyTreeSheet","@L_BLOODLINE_HEADLINE_+0")
	this:SetTabGroupHeader("Character","@L_DYNASTY_+1")
	
	-- important units sheet
	this:AddSheetToTabGroup("Important","ImportantPersons","@L_IMPORTANTPERSONS_HEAD_+0")
	this:AddSheetToTabGroup("Important","OverviewBuildings","@L_INTERFACE_OVERVIEWBUILDINGS_HEAD_+0")
	this:SetTabGroupHeader("Important","@L_INTERFACE_IMPORTANT_+1")

	-- this:AddPanel("MiniMapPanel","cl_MiniMapPanel","gui/Hud/panel_minimap.gui")

	-- Include ( "hud/Minimap.lua" )

	-- minimap_Refresh()

	gamehud_TuneMeasureHelpPanel()

end

function CleanUp() 	
end

-- -----------------------
-- On-screen help panels: let them size to their content.
--
-- Three rounds of probing established:
--   * runtime property writes take -- ABS_HEIGHT, SHOW_VERTICAL_SCROLLBAR and
--     RESIZE all read back changed
--   * the panels cannot be told apart at HudInit. None is named after its
--     AddPanel name (all are plain "Container"), the AddPanel order does not map
--     onto HudRoot's child order, and "@LProduction" matches 13 children. Worse,
--     measures.gui, items.gui and upgrades.gui share every extractable string --
--     they are the same layout and only differ once populated.
--
-- So stop trying to single out the measure window. All thirteen Helppanels/*.gui
-- files share the texture "Hud/sheets/onscreenhelp/bg.tga" and nothing else does,
-- which identifies the cohort exactly. Every one of them shows a description that
-- can overflow, so every one of them wants the same treatment.
--
-- RESIZE and SHOW_VERTICAL_SCROLLBAR are settled and did not work: both read
-- back changed on all 11 panels and the tooltip stayed clipped mid-sentence with
-- no scrollbar, so the engine reads them when the panel is built and never
-- again. ABS_HEIGHT is worth one more try only because the earlier attempts
-- failed for a reason that is now gone -- they stretched the multiplayer lobby
-- and the character help panel, which was the wrong panel, not the wrong
-- property. This run also logs the geometry of each panel and its first
-- children, because a clipped paragraph may be clipped by a text child rather
-- than by the panel.
--
-- Observed: 11 of 137 children match, indices 39..49, one contiguous block,
-- and both writes read back changed. So the texture is a sound fingerprint and
-- the writes land; two of the thirteen .gui files are simply not HudRoot
-- children at HudInit. Whether RESIZE actually re-lays-out is a separate
-- question -- the engine may only read it when the panel is built.
--
-- Every step is wrapped: a wrong node name has to land in the log, never break
-- HudInit. Node API from Hud/Debug/HudRootAnalyser.lua. Grep for @HELPPANEL.
-- -----------------------
local COHORT_TEXTURE = "onscreenhelp/bg"
local SANITY_LIMIT = 20

local function Str(Node, Property)
	local ok, value = pcall(function() return Node:GetValueString(Property) end)
	if ok and value then
		return tostring(value)
	end
	return ""
end

local function IsHelpPanel(Node, Depth)
	if string.find(Str(Node, "TEXTURE_FILENAME"), COHORT_TEXTURE, 1, true) then
		return true
	end
	if Depth <= 0 then
		return false
	end
	local ok, count = pcall(function() return Node:GetChildCnt() end)
	if not ok or not count then
		return false
	end
	for i = 0, count - 1 do
		local got, child = pcall(function() return Node:GetChildAt(i) end)
		if got and child then
			local found = false
			pcall(function() found = IsHelpPanel(child, Depth - 1) end)
			if found then
				return true
			end
		end
	end
	return false
end

-- Reads whichever of these exist; a missing property reads back nil and is
-- skipped, so the list can be optimistic.
local GEO = { "ABS_HEIGHT", "ABS_WIDTH", "HEIGHT", "WIDTH", "ABS_YPOS" }

local function Geo(Node)
	local out = ""
	for i = 1, #GEO do
		local ok, value = pcall(function() return Node:GetValueInt(GEO[i]) end)
		if ok and value ~= nil then
			out = out .. " " .. GEO[i] .. "=" .. tostring(value)
		end
	end
	return out
end

local function SetInt(Node, Property, Value)
	local okBefore, before = pcall(function() return Node:GetValueInt(Property) end)
	if not okBefore or before == nil then
		LogMessage("@HELPPANEL " .. Property .. " is not readable, left alone")
		return
	end
	pcall(function() Node:SetValueInt(Property, Value) end)
	local _, after = pcall(function() return Node:GetValueInt(Property) end)
	LogMessage("@HELPPANEL " .. (Node:GetName() or "?") .. "." .. Property ..
				": " .. tostring(before) .. " -> " .. tostring(after) ..
				(tostring(before) == tostring(after) and "  IGNORED" or "  TOOK"))
end

-- How much taller to make a help panel. A blunt number on purpose: this run is
-- to learn whether a post-construction geometry write is honoured at all, not to
-- find the right height.
local HEIGHT_BONUS = 240
local CHILDREN_LOGGED = 6

function TuneMeasureHelpPanel()
	local ok, err = pcall(function()
		local Root = FindNode("\GUI\HudRoot")
		if not Root then
			LogMessage("@HELPPANEL HudRoot not found")
			return
		end
		local count = Root:GetChildCnt() or 0

		local found = {}
		for i = 0, count - 1 do
			local got, child = pcall(function() return Root:GetChildAt(i) end)
			if got and child then
				local hit = false
				pcall(function() hit = IsHelpPanel(child, 4) end)
				if hit then
					found[#found + 1] = i
				end
			end
		end

		LogMessage("@HELPPANEL " .. #found .. " of " .. tostring(count) ..
					" children carry the help-panel texture; expected 11")

		if #found == 0 or #found > SANITY_LIMIT then
			LogMessage("@HELPPANEL count outside the sane range, changing nothing")
			return
		end

		for i = 1, #found do
			local got, Panel = pcall(function() return Root:GetChildAt(found[i]) end)
			if got and Panel then
				LogMessage("@HELPPANEL panel " .. found[i] .. Geo(Panel))

				-- The text is clipped, so the clipping element may be a child
				-- rather than the panel. Log the first few so the next step does
				-- not have to guess which node owns the height.
				local kids = 0
				pcall(function() kids = Panel:GetChildCnt() or 0 end)
				for k = 0, math.min(kids, CHILDREN_LOGGED) - 1 do
					local gotKid, Kid = pcall(function() return Panel:GetChildAt(k) end)
					if gotKid and Kid then
						LogMessage("@HELPPANEL   " .. found[i] .. "." .. k .. " " ..
									(Kid:GetName() or "?") .. Geo(Kid))
					end
				end

				local _, before = pcall(function() return Panel:GetValueInt("ABS_HEIGHT") end)
				if before ~= nil then
					SetInt(Panel, "ABS_HEIGHT", before + HEIGHT_BONUS)
				end
			end
		end
	end)

	if not ok then
		LogMessage("@HELPPANEL error: " .. tostring(err))
	end
end
