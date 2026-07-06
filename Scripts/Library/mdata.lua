-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end

function GetDuration(MeasureID)
	local Duration = GetDatabaseValue("Measures", MeasureID, "duration")
  -- local script = GetDatabaseValue("Measures",MeasureID,"script")
	--for artifact duration
	if (MeasureID >= 5000) and (MeasureID <= 6000) then
  -- if string.find(script, "Artefacts", 1, true) then --for artifact duration -- TODO: wait for AID Release to be able to properly test if this is a functional alternative to the ID check
		Duration = Duration + (chr_ArtifactsDuration("", Duration))
	end
	return Duration
end

function GetTimeOut(MeasureID)
	local TimeOut = GetDatabaseValue("Measures", MeasureID, "repeat_time")
  -- local script = GetDatabaseValue("Measures",MeasureID,"script")
	--for artifact timeout
	if (MeasureID >= 5000) and (MeasureID <= 6000) then
  -- if string.find(script, "Artefacts", 1, true) then --for artifact duration
		TimeOut = TimeOut - (chr_ArtifactsDuration("", TimeOut))
	end
	return TimeOut
end

function GetPrice(MeasureName, Title)
	local BasePrice = 50
	-- special cases:
	
	if MeasureName == "AdoptOrphan" then
		BasePrice = GL_BASE_PRICE_ADOPTORPHAN
	end
	
	-- default case:
	local Cost = Title * Title * BasePrice
	return Cost
end