-- by Napi96
function Prepare()
    ScenarioSetOutdoorScrollBoundaries(-40000, -39623, 46334, -49262, 49334, 49202, -49000, 49000)
    ScenarioSetNameLanguage("english")

    local worldname = "England"
    local mapid = f_GetDatabaseIdByName("maps", worldname)
    GetScenario("World")
    SetProperty("World", "mapid", mapid)
    SetProperty("World", "seamap", 1)

    ScenarioCreatePosition(10270.66, -39326.58, "blackberryPosNorwich")
    ScenarioCreateResource("blackberryPosNorwich", "Blackberry", "blackberryBushNorwich")

    --if not IsMultiplayerGame() then
    local Options = FindNode("\\Settings\\Options")
    local YearsPerRound = Options:GetValueInt("YearsPerRound")
    if YearsPerRound then
        ScenarioSetYearsPerRound(YearsPerRound)
    end
    --end

    SetProperty("World", "ambient", 0)
    if not IsMultiplayerGame() then
        local Options = FindNode("\\Settings\\Options")
        local Ambient = Options:GetValueInt("Ambient")
        if Ambient == 0 then
            SetProperty("World", "ambient", 1)
        end
    end

    SetProperty("World", "messages", 0)
    if not IsMultiplayerGame() then
        local Options = FindNode("\\Settings\\Options")
        local Messages = Options:GetValueInt("Messages")
        if Messages == 0 then
            SetProperty("World", "messages", 1)
        end
    end

    local Options = FindNode("\\Settings\\Options")
    local FrequencyOfficeSessions = Options:GetValueInt("FrequencyOfficeSessions")
    SetProperty("World", "fos", FrequencyOfficeSessions)
end


-- the "Start" function is called after everything has been initializied on the map (players/ai/...)
function Start()
end

