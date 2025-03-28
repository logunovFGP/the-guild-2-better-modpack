function Run()
	local Node, Setting = FindNode("\\Application\\Game\\PerformanceTree"), FindNode("\\Settings\\DEBUG")

	local isActivated = Setting:GetValueInt("UsePerformanceTree")

	if not isActivated then
		LogMessage("@NAO PerformanceTree -> First run.")
		Setting:SetValueInt("UsePerformanceTree", 0)
		isActivated = Setting:GetValueInt("UsePerformanceTree")
	end

	if isActivated == 0 then
		Setting:SetValueInt("UsePerformanceTree", 1)
		Node = FindNode("\\Application\\Game")
		Node:EnableModule("PerformanceTree", 1)
		LogMessage("@NAO PerformanceTree -> ON.")
	else
		Setting:SetValueInt("UsePerformanceTree", 0)
		Node = FindNode("\\Application\\Game")
		Node:DisableModule("PerformanceTree")
		LogMessage("@NAO PerformanceTree -> OFF.")
	end
end