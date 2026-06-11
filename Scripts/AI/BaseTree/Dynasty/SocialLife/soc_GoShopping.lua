function Weight()
	if not ReadyToRepeat("SIM", "AI_GoShopping") then
		return 0
	end

	if GetMoney("dynasty") < 800 then
		return 0
	end

	return 12
end

function Execute()
	SetRepeatTimer("SIM", "AI_GoShopping", 18)

	local Season = GetSeason()
	local Basket
	if Season == EN_SEASON_WINTER then
		Basket = { "Blanket", "HerbTea", "Mead" }
	elseif Season == EN_SEASON_SUMMER then
		Basket = { "SmallBeer", "WheatBeer", "FriedHerring" }
	elseif Season == EN_SEASON_AUTUMN then
		Basket = { "Wine", "Cake", "SmokedSalmon" }
	else
		Basket = { "Soap", "Perfume", "Wheatbread" }
	end

	local Item = Basket[Rand(3) + 1]

	local Money = GetMoney("dynasty")
	if Money > 20000 and Rand(4) == 0 then
		Item = "NoblesClothes"
	elseif Money > 8000 and Rand(4) == 0 then
		Item = "CitizensClothes"
	end

	MeasureCreate("SOC_BuyMeasure")
	MeasureAddData("SOC_BuyMeasure", "ItemToBuy", Item)
	MeasureStart("SOC_BuyMeasure", "SIM", nil, "AIBuyItem")
end