function Run()
	
	GetScenario("World")
	local DebugActions = 0
	if not HasProperty("World", "DebugActions") then
		SetProperty("World", "DebugActions", 1)
	end
	
	DebugActions = GetProperty("World", "DebugActions")
	
	if DebugActions == 1 then
		MsgQuick("", "DebugActions was 1, set to 0") 
		SetProperty("World", "DebugActions", 0)
	else
		MsgQuick("", "DebugActions was 0, set to 1") 
		SetProperty("World", "DebugActions", 1)
	end
end

function CleanUp()
end

