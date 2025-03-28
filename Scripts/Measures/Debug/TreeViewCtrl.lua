function Run()
	local Node, Setting = FindNode("\\Application\\Game\\TreeViewCtrl"), FindNode("\\Settings\\DEBUG")

	local isActivated = Setting:GetValueInt("UseTreeViewCtrl")

	if not isActivated then
		LogMessage("@NAO TreeViewCtrl -> First run.")
		Setting:SetValueInt("UseTreeViewCtrl", 0)
		isActivated = Setting:GetValueInt("UseTreeViewCtrl")
	end

	if isActivated == 0 then
		Setting:SetValueInt("UseTreeViewCtrl", 1)
		Node = FindNode("\\Application\\Game")
		Node:EnableModule("TreeViewCtrl", 1)
		LogMessage("@NAO TreeViewCtrl -> ON.")
	else
		Setting:SetValueInt("UseTreeViewCtrl", 0)
		Node = FindNode("\\Application\\Game")
		Node:DisableModule("TreeViewCtrl")
		LogMessage("@NAO TreeViewCtrl -> OFF.")
	end
end