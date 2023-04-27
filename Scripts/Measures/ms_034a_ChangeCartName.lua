function Init()
	InitData("SayPanel", 0, "@L_GENERAL_CHANGE_CART_NAME_HEADER", "DoesntMatter")
end

function Run()
	local label = GetData("TF0")
	if (string.len(label) > 0 ) then
		SetName("", label)
	end
end

function CleanUp()
end