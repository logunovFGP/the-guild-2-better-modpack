function Run()
	local Node, Setting = FindNode("\\Application\\Game\\TreeGraphCtrl"), FindNode("\\Settings\\DEBUG")

	local isActivated = Setting:GetValueInt("UseTreeGraphCtrl")

	if not isActivated then
		LogMessage("@NAO TreeGraphCtrl -> First run.")
		Setting:SetValueInt("UseTreeGraphCtrl", 0)
		isActivated = Setting:GetValueInt("UseTreeGraphCtrl")
	end

	if isActivated == 0 then
		Setting:SetValueInt("UseTreeGraphCtrl", 1)
		Node = FindNode("\\Application\\Game")
		Node:EnableModule("TreeGraphCtrl", 1)
		LogMessage("@NAO TreeGraphCtrl -> ON.")
	else
		Setting:SetValueInt("UseTreeGraphCtrl", 0)
		Node = FindNode("\\Application\\Game")
		Node:DisableModule("TreeGraphCtrl")
		LogMessage("@NAO TreeGraphCtrl -> OFF.")
	end
end