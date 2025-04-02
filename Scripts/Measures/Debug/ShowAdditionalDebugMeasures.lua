function Run()
	if GetProperty("", "ShowAdditionalDebugMeasures") ~= nil then
		RemoveProperty("", "ShowAdditionalDebugMeasures")
	else
		SetProperty("", "ShowAdditionalDebugMeasures", 1)
	end
end