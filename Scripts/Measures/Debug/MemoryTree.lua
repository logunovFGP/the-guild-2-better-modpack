function Run()
	local Node, Setting = FindNode("\\Application\\Game\\MemoryTree"), FindNode("\\Settings\\DEBUG")

	local isActivated = Setting:GetValueInt("UseMemoryTree")

	if not isActivated then
		LogMessage("@NAO MemoryTree -> First run.")
		Setting:SetValueInt("UseMemoryTree", 0)
		isActivated = Setting:GetValueInt("UseMemoryTree")
	end

	if isActivated == 0 then
		Setting:SetValueInt("UseMemoryTree", 1)
		Node = FindNode("\\Application\\Game")
		Node:EnableModule("MemoryTree", 1)
		LogMessage("@NAO MemoryTree -> ON.")
	else
		Setting:SetValueInt("UseMemoryTree", 0)
		Node = FindNode("\\Application\\Game")
		Node:DisableModule("MemoryTree")
		LogMessage("@NAO MemoryTree -> OFF.")
	end
end