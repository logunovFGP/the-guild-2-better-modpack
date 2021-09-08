-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_mmp_ShowBalanceWorkshop"
----
----	this measure shows a balance sheet for the workshop to see, how
----     much profit you make each round.
----
----    designed by Fajeth
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------

function Run()
	
	CopyAlias("", "Workshop")
	
	-- before showing the balance sheet, ask what you want to do
	local result
	
	
	local MsgSell = GetProperty("Workshop","MsgSell")
	local Label = "@L_MEASURE_SHOWBALANCE_MSG_+0"
	
	if MsgSell == 1 then
		MsgSellLabel = "@L_MEASURE_SHOWBALANCE_MESSAGES_ON_+0"
		Label = "@L_MEASURE_SHOWBALANCE_MSG_+1"
	else
		MsgSellLabel = "@L_MEASURE_SHOWBALANCE_MESSAGES_OFF_+0"
	end
	
	result = MsgNews("","","@P"..
					"@B[0,"..Label.."]"..
					"@B[1,@L_MEASURE_SHOWBALANCE_BAL_+0]"..
					"@B[2,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
					0,
					"production",-1,"@L_MEASURE_SHOWBALANCE_HEAD_+0",
					"@L_MEASURE_SHOWBALANCE_BODY_+0",GetID(""),MsgSellLabel)
					
	if result == 0 then
		-- switch messages
		if GetProperty("Workshop","MsgSell") == 1 then
			SetProperty("Workshop","MsgSell",0)
		else
			SetProperty("Workshop","MsgSell",1)
		end
		StopMeasure()
	elseif result == 1 then
		-- show the balance
		local Balance = 0
		local BalanceLastItem = "Vieh" -- debug
		local BalanceLastPrice = 0
		local LabelOne = "Pig"
		local LabelTwo = "Sheep"
		local BalanceItemCount = 0
		BuildingGetOwner("Workshop","WSOwner")
		local BalanceLastBuyer = GetID("WSOwner")
		local BalanceItemOne = 0
		local BalanceItemOneSum = 0
		local BalanceItemTwo = 0
		local BalanceItemTwoSum = 0
		local ItemOneAvg = 0
		local ItemTwoAvg = 0
		local Wages = 0
		
		if BuildingGetType("Workshop")==6 then -- bakery
			BalanceLastItem = "Cookie"
			LabelOne = "Cookie"
			LabelTwo = "Wheatbread"
		elseif BuildingGetType("Workshop")==7 then -- smithy
			BalanceLastItem = "Tool"
			LabelOne = "Tool"
			LabelTwo = "Dagger"
		elseif BuildingGetType("Workshop")==8 then -- joinery
			BalanceLastItem = "Torch"
			LabelOne = "Torch"
			LabelTwo = "Schnitzi"
		elseif BuildingGetType("Workshop")==9 then -- tailor
			BalanceLastItem = "MoneyBag"
			LabelOne = "MoneyBag"
			LabelTwo = "Blanket"
		elseif BuildingGetType("Workshop")==110 then -- stonemason
			BalanceLastItem = "vase"
			LabelOne = "vase"
			LabelTwo = "Grindingbrick"
		elseif BuildingGetType("Workshop")==16 then -- alchemist
			BalanceLastItem = "HerbTea"
			LabelOne = "HerbTea"
			LabelTwo = "Phiole"
		elseif BuildingGetType("Workshop")==98 then -- cemetery
			BalanceLastItem = "Schadelkerze" 
			LabelOne = "Schadelkerze"
			LabelTwo = "Knochenarmreif"
		end
		
		if HasProperty("Workshop","Balance") then
			Balance = GetProperty("Workshop","Balance")
		end
		
		if HasProperty("Workshop","BalanceLastItem") then
			BalanceLastItem = GetProperty("Workshop","BalanceLastItem")
		end
		
		if HasProperty("Workshop","BalanceLastPrice") then
			BalanceLastPrice = GetProperty("Workshop","BalanceLastPrice")
		end
		
		if HasProperty("Workshop","BalanceItemCount") then
			BalanceItemCount = GetProperty("Workshop","BalanceItemCount")
		end
		if HasProperty("Workshop","BalanceLastBuyer") then
			BalanceLastBuyer = GetProperty("Workshop","BalanceLastBuyer")
		end
		if HasProperty("Workshop","BalanceItemOne") then
			BalanceItemOne = GetProperty("Workshop","BalanceItemOne")
		end
		if HasProperty("Workshop","BalanceItemOneSum") then
			BalanceItemOneSum = GetProperty("Workshop","BalanceItemOneSum")
		end
		if HasProperty("Workshop","BalanceItemTwo") then
			BalanceItemTwo = GetProperty("Workshop","BalanceItemTwo")
		end
		if HasProperty("Workshop","BalanceItemTwoSum") then
			BalanceItemTwoSum = GetProperty("Workshop","BalanceItemTwoSum")
		end
		
		-- wages
		local numFound = 0
		local	Alias
		local count = BuildingGetWorkerCount("Workshop")
	
		for number=0, count-1 do
			Alias = "Worker"..numFound
			if BuildingGetWorker("Workshop", number, Alias) then
				numFound = numFound + 1
			end
		end
	
		if numFound > 0 then
			for loop_var=0, numFound-1 do
				Alias = "Worker"..loop_var
				Wages = Wages + SimGetWage(Alias,"Workshop")
			end
		end
		
		ItemOneAvg = math.floor(BalanceItemOneSum/BalanceItemOne)
		ItemTwoAvg = math.floor(BalanceItemTwoSum/BalanceItemTwo)
		
		MsgBoxNoWait("dynasty", BalanceLastBuyer, "@L_MEASURE_SHOWBALANCE_SHEET_HEAD_+0",
						"@L_MEASURE_SHOWBALANCE_SHEET_BODY_+0",GetID("Workshop"), 
						BalanceLastBuyer, BalanceItemCount, ItemGetLabel((BalanceLastItem),true),BalanceLastPrice, 
						ItemGetLabel((LabelOne),false),BalanceItemOne, BalanceItemOneSum, ItemOneAvg,
						ItemGetLabel((LabelTwo),false),BalanceItemTwo, BalanceItemTwoSum, ItemTwoAvg,
						Balance,
						Wages)
	end
end
