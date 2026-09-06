function Weight()
	-- rogue businesses only for a house whose main class is rogue
	if aitwp_MainClass("dynasty") ~= GL_CLASS_CHISELER then
		return 0
	end
	if SimGetClass("SIM") == GL_CLASS_CHISELER then
		return 100
	end
	return 0
end

function Execute()
end