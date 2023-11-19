function Weight()
	return 0
end

function Execute()
	LogMessage("::TWP::AI:: AI crediting money directly...")
	f_CreditMoney("", 100, "BaseTree")
	
	Sleep(10)
	
	LogMessage("::TWP::AI:: AI spending money directly...")
	f_SpendMoney("", 100, "BaseTree")

	DynastyGetFamilyMember("dynasty", 0, "SIM")
	MeasureRun("SIM", nil, "Bricklebrit") 
end
