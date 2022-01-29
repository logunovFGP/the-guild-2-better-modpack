-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end

function GetDuration(MeasureID)
	local Duration = GetDatabaseValue("Measures", MeasureID, "duration")
	
	--for artifact duration
	if (MeasureID >= 5000) and (MeasureID <= 6000) then
		Duration = Duration + (chr_ArtifactsDuration("", Duration))
	end
	return Duration
end

function GetTimeOut(MeasureID)
	local TimeOut = GetDatabaseValue("Measures", MeasureID, "repeat_time")
	
	--for artifact timeout
	if (MeasureID >= 5000) and (MeasureID <= 6000) then
		TimeOut = TimeOut - (chr_ArtifactsDuration("", TimeOut))
	end
	return TimeOut
end

function GetPrice(MeasureName, Title)
	local BasePrice = 50
	-- special cases:
	
	if MeasureName == "AdoptOrphan" then
		BasePrice = GL_ADOPTION_BASE_PRICE
	end
	
	-- default case:
	local Cost = Title * Title * BasePrice
	return Cost
end