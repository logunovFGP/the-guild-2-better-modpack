local varManager =
	function()
		local self = {
			enable = {true,true,true},
			texture = {'Ok','Ok','Ok'},
			property = {"DEBUG_WEDDING_AFFORDABLE","DEBUG_WEDDING_FULL_GUESTS","DEBUG_WEDDING_TELEPORT_GUESTS"}
		}
		self.tog =
			function(ID,TEXTURE,STRING)
				self.texture[ID] = TEXTURE
				self.enable[ID] = not self.enable[ID]
			end

		self.toggle =
			function(ID)
				if self.enable[ID] then
					self.texture[ID] = 'cross'
				else
					self.texture[ID] = 'Ok'
				end
				self.enable[ID] = not self.enable[ID]
			end

		return self
	end

local wedding = varManager()

function Run()

	local result = InitData("@P"..
	"@B[1,Afford.,Can the Sim pay the expenses for the wedding to occur?,hud/buttons/btn_"..wedding.texture[1]..".tga]"..
	"@B[2,Guests,Should all guests attend the wedding ceremony?,hud/buttons/btn_"..wedding.texture[2]..".tga]"..
	"@B[3,Telep.,Should all attending Sims be teleported to the wedding ceremony?,hud/buttons/btn_"..wedding.texture[3]..".tga]"..
	"@B[4,Sched.,Start an immediate CityScheduleCutsceneEvent for development purposes.,hud/buttons/btn_ShowBuildingsForSale.tga]"..
	"@B[5,Start!,Run the cutscene!,Hud/MouseIcons_highlighted/btn_marry.tga]",
	nil,
	"Select the options for the debug measure, then Start!",
	"")

	if result ~= "C" then

		if result < 4 then 
			wedding.toggle(result)
			ms_debug_weddings_Run()
		end

		if result == 4 then

			local function returnSlot()

				local schedule = { 
					getYear = 0,
					getHour = 6,
					setHour = 0,
					getRounds = math.floor( GetGametime() / 24 ),
					getDate = nil,
					minDelay = 4 
				}

				-- Possible slots: 06:00 | 12:00 | 18:00 | 00:00

				FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WEDDING_CHAPEL")

				--[[

				LIST OF ADDED PROPERTIES
					#WEDDING_CHAPEL
						* AMOUNT
						* YEAR
						* HOUR_ADDON
						* SLOT_OVER(INDEX)

					#GROOM
						* WEDDING_IS_OVER
						* WEDDING_DATE
						* WEDDING_HOUR
						* WEDDING_FORCED
						* WEDDING_GUESTS(Amount)

					#BRIDE
						* WEDDING_IS_OVER
						* WEDDING_DATE
						* WEDDING_HOUR
						* WEDDING_FORCED
						* WEDDING_GUESTS(Amount)

					#GUEST
						* AttendingWedding
						* WEDDING_HOUR(GUEST)
						* WEDDING_SIM1(GUEST)
						* WEDDING_SIM2(GUEST)


					[Exception]
						* WEDDING_MAIN -> #GROOM or #BRIDE (Sim who proposed to other Sim)

				]]

				-- Init. properties (if unexisting)
				if not HasProperty("#WEDDING_CHAPEL", "AMOUNT") then 
					SetProperty("#WEDDING_CHAPEL", "AMOUNT", 0)
				end

				if not HasProperty("#WEDDING_CHAPEL", "YEAR") then
					SetProperty("#WEDDING_CHAPEL", "YEAR", 0)
				end

				if not HasProperty("#WEDDING_CHAPEL", "HOUR_ADDON") then
					SetProperty("#WEDDING_CHAPEL", "HOUR_ADDON", 1)
				end

				-- Inst. properties (won't be conflicting)
				local ID = GetProperty("#WEDDING_CHAPEL","AMOUNT")
				SetProperty("#WEDDING_CHAPEL", "AMOUNT", ID+1)

				local YEAR = GetProperty("#WEDDING_CHAPEL", "YEAR")
				schedule.getYear = YEAR

				local HOUR = GetProperty("#WEDDING_CHAPEL", "HOUR_ADDON") + 1
				SetProperty("#WEDDING_CHAPEL", "HOUR_ADDON", HOUR)

				-- Script calculations.
				schedule.getHour = 6 + (HOUR - 1) * 6

				if HOUR > 4 then
				    SetProperty("#WEDDING_CHAPEL", "HOUR_ADDON", 1)
				    schedule.getHour = 6
				end

				LogMessage("Hour slot defined: "..schedule.getHour.."h00.")

				if math.floor(GetProperty("#WEDDING_CHAPEL","AMOUNT")) == math.floor((GetProperty("#WEDDING_CHAPEL","AMOUNT")) / 4) * 4 then
					SetProperty("#WEDDING_CHAPEL", "YEAR", YEAR + 1)
					schedule.getYear = YEAR + 1
				end

				schedule.getDate = ( ( ( 24 * ( schedule.getRounds+schedule.getYear ) ) * 60 - GetGametime() * 60 ) / 60 ) + schedule.getHour

				LogMessage("("..schedule.getHour.."h00). Will there be enough time? ".. schedule.getDate .." ("..schedule.minDelay.." hours required).")

				if schedule.getDate > schedule.minDelay then
					schedule.getDate = ( ( 24 * ( schedule.getRounds+schedule.getYear ) ) * 60 ) + schedule.getHour * 60
					LogMessage("Script confirmed "..schedule.getHour.."h00 as a perfect date for this Wedding Ceremony.")
				else

					local timeMessages = {
					    [6] = 12,
					    [12] = 18,
					    [18] = 24,
					    [24] = 6
					}

					if timeMessages[schedule.getHour] then
					    LogMessage("Script determined " .. timeMessages[schedule.getHour] .. "h00 as a better fit for this ceremony.")
					    schedule.getDate = (24 * (schedule.getRounds + schedule.getYear) * 60) + timeMessages[schedule.getHour] * 60
					end

				end

				-- Utilities.

				local function SetProperties(data, result)
					SetProperty("",			data, result)
					SetProperty("#Courted", data, result)
				end

				local function SimAddDates(date)
					local list = {"","#Courted"}
					for i = 1, 2 do
						SimAddDatebookEntry(list[i],date, "#WEDDING_CHAPEL","Your Wedding Ceremony...","Two love-birds are getting married soon, you should probably attend the event in a great moment of community.")
						SimAddDate(list[i],"#WEDDING_CHAPEL", "#WEDDING_CHAPEL", date -120, "AttendWedding")
					end
				end

				SimGetCourtLover("", "#Courted")

				-- Dual properties
				SetProperties("WEDDING_IS_OVER", 0)
				SetProperties("WEDDING_DATE", schedule.getDate)
				SetProperties("WEDDING_HOUR", schedule.getHour)
				SetProperties("WEDDING_FORCED", 1)
				SetProperties("WEDDING_GUESTS(Amount)", -1)

				-- Single properties
				SetProperty("", "#WEDDING_MAIN", 1)

				-- Callbacks
				SimAddDates(schedule.getDate)

				return schedule.getDate

			end

			do
				local v = returnSlot()
				ms_debug_weddings_InviteGuests("#WEDDING_CHAPEL", "", "#Courted", v)
			end

		elseif result == 5 then
			--ms_debug_weddings_DEBUG_StartWedding()
		end

	end
end

local function AIInitAnswer()

	local Timer = 0
	if GetImpactValue("GuestAlias", "OfficeTimer") > 0 then
		Timer = ImpactGetMaxTimeleft("GuestAlias", "OfficeTimer")
		if Timer <= 4 then
			return "C"
		end
	end
	
	if GetImpactValue("GuestAlias", "TrialTimer") > 0 then
		Timer = ImpactGetMaxTimeleft("GuestAlias", "TrialTimer")
		if Timer <= 4 then
			return "C"
		end
	end
	
	if GetImpactValue("GuestAlias", "DuelTimer") > 0 then
		Timer = ImpactGetMaxTimeleft("GuestAlias", "DuelTimer")
		if Timer <= 4 then
			return "C"
		end
	end
		
	if DynastyGetDiplomacyState("GuestAlias", "") < DIP_ALLIANCE or GetFavorToDynasty("", "GuestAlias") >= 60 or SimGetOfficeLevel("") > 0 then
		return "O"
	else
		if Rand(1) == 0 then
			return "O"
		else
			return "C"
		end
	end
end

function InviteGuests(Chapel, Sim1, Sim2, Hour)
LogMessage("InviteGuests() func.")

    local function canInviteGuest(GuestAlias, GuestDyn)
        return true --math.max(GetNobilityTitle(Sim1), GetNobilityTitle(Sim2)) >= GetNobilityTitle(GuestAlias) - 2 and f_SimIsValid(GuestAlias) and not GetState(GuestAlias, STATE_SICK) and CanBeInterruptetBy(GuestAlias, Sim1, "Flirt")
    end

    local function inviteGuest(GuestAlias)
        local Invitation = MsgNews(GuestAlias, "", "@P"..
            "@B[O, @L_THIEF_067_LETABDUCTEEOUT_ACTION_BTN_+0]"..
            "@B[C, @L_THIEF_067_LETABDUCTEEOUT_ACTION_BTN_+1]", 
            AIInitAnswer, "politics", 2, 
            "@L_FAMILY_1_MARRIAGE_MESSAGE_HEAD_LEAVE_+0",
            "@L_MEASURE_MARRY_CEREMONY_ASK_BODY_+0",
            GetID(Sim1), GetID(Sim2), GetID(Chapel), GetID(GuestAlias))

        	if Invitation == "O" then 
        		return true 
        	else 
        		return false 
        	end

    end

    if GetSettlement(Sim1, "MyCity") then
        for i = 0, CityGetBuildings("MyCity", GL_BUILDING_CLASS_LIVINGROOM, -1, -1, -1, FILTER_HAS_DYNASTY, "Residence") - 1 do
            if GetDynasty("Residence"..i, "GuestDyn") and GetImpactValue("GuestDyn", "Ceremony") < 1 then
                local FamilyGuests = 0
                for u = 0, DynastyGetFamilyMemberCount("GuestDyn") - 1 do
                    if DynastyGetFamilyMember("GuestDyn", u, "GuestAlias") and
                       GetID("GuestAlias") ~= GetID(Sim1) and GetID("GuestAlias") ~= GetID(Sim2) and
                       GetID("GuestDyn") == GetDynastyID("GuestAlias") and canInviteGuest("GuestAlias", "GuestDyn") then
                        if inviteGuest("GuestAlias") then
                        	LogMessage(GetName("GuestAlias").." will be attending the ceremony.")
                        	SetProperty("GuestAlias","AttendingWedding",1)
                        	SetProperty("GuestAlias","WEDDING_HOUR(GUEST)",Hour)
                        	SetProperty("GuestAlias","WEDDING_SIM1(GUEST)",GetID(Sim1))
                        	SetProperty("GuestAlias","WEDDING_SIM2(GUEST)",GetID(Sim2))
                            FamilyGuests = FamilyGuests + 1
                            local date = GetProperty(Sim1,"WEDDING_DATE")
                            SimAddDate("GuestAlias", "#WEDDING_CHAPEL", "#WEDDING_CHAPEL", date-120, "AttendWedding")
                            SimAddDatebookEntry("GuestAlias", date, "#WEDDING_CHAPEL","Wedding ceremony...","Two love-birds are getting married soon, you should probably attend the event in a great moment of community.")
                        else
                        	LogMessage(GetName("GuestAlias").." will NOT be attending the ceremony.")
                        end
                        if GetImpactValue("GuestDyn", "Ceremony") == 0 then
                            AddImpact("GuestDyn", "Ceremony", 1, 0.2)
                        end
                    end
                    if FamilyGuests == 2 then
                        break
                    end
                end
            end
        end
    end
end

function DEBUG_StartWedding()
	for i = 1, 3 do
		if wedding.enable[i] then
			SetProperty("", wedding.property[i], 1)
		else
			SetProperty("", wedding.property[i], 0)
		end
	end
	ms_debug_weddings_DEBUG_RunCutscene()
end


function DEBUG_RunCutscene()

	FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WeddingChapel")

	if (CameraIndoorGetBuilding("#WeddingChapel") == false) then
		CameraIndoorSetBuilding("#WeddingChapel")
	end

	if SimGetCourtLover("", "#Courted") then
		local Checker = "#Courted"
	end

	if Checker ~= nil then 

		LogMessage('CodeRework :: '..GetName("").." and "..GetName(Checker).." are now preparing for the Wedding Ceremony.")

		Sleep(0.1)

		SetProperty(Checker, "courted", 1)
		SetState(Checker, STATE_INLOVE, true)
		SetData("CourtLoverSet", 1)
		SimSetCourtLover("", Checker)

		MeasureRun("", Checker, "MarryChapel", true)

	else

		LogMessage("No Lover was found for "..GetName(""))

	end

end

function Start()
end

function CleanUp()
end