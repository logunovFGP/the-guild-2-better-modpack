function Run()

	-- etwa Abstand vom Geschehen, und gaffen
	GetFleePosition("Owner", "Actor", Rand(100)+150, "Away")
	f_MoveTo("Owner", "Away", GL_MOVESPEED_WALK)
	AlignTo("Owner", "Actor")
	Sleep(1)

	local ActionName = GetData("Action_Name")
	SetRepeatTimer("Owner", "Listen2Quacksalver", 2)
	local success = false
	
	--listen
	for i=1, 2 do -- 2 tries
		local rnd = Rand(4) + 1
		Sleep(rnd)
		if Rand(3) > 0 then
			PlayAnimation("Owner", "cogitate")
		else
			PlayAnimation("Owner", "talk")
		end
		
		if SimGetGender("") == GL_GENDER_MALE then
			if Rand(2) == 0 then
				PlayAnimationNoWait("Owner", "cheer_01")
			else
				PlayAnimationNoWait("Owner", "cheer_02")
			end
			PlaySound3DVariation("", "CharacterFX/male_cheer", 0.6)
		else
			if Rand(2) == 0 then
				PlayAnimationNoWait("Owner", "cheer_01")
			else
				PlayAnimationNoWait("Owner", "cheer_02")
			end
			PlaySound3DVariation("", "CharacterFX/female_cheer", 0.6)
		end
		Sleep(2)

		--buy stuff or not
		if (GetID("Actor")) and not ActionIsStopped("Action") and not success then
			local RhetoricSkillActor = GetSkillValue("Actor", RHETORIC)
			local MoneyToGet = RhetoricSkillActor * 20
			MoneyToGet = MoneyToGet + Rand(101)
			local RandomTime = 1+Rand(5)
			Sleep(RandomTime)
			if chr_SkillCheck("Actor", RHETORIC, 1, "", EMPATHY) and chr_GetBudget("", 2) > MoneyToGet then
				MsgSayNoWait("", "@L_MEASURE_LISTENQUACKSALVER_YES")
				PlayAnimation("", "nod")
				if RemoveItems("Actor", "MiracleCure", 1, INVENTORY_STD) == 1 then
					chr_CreditMoney("Actor", MoneyToGet, "Offering")
					chr_UseBudget("", 2, MoneyToGet)
					
					-- for the balance
				--	if ai_GetWorkBuilding("Actor", GL_BUILDING_TYPE_HOSPITAL, "Hospital") then
				--		local TotalIncome = 0
				--		if HasProperty("Hospital", "TotalIncome") then
				--			TotalIncome = GetProperty("Hospital","TotalIncome")
				--		end
				--		local RoundIncome = 0
				--		if HasProperty("Hospital", "RoundIncome") then
				--			RoundIncome = GetProperty("Hospital","RoundIncome")
				--		end
				--		local QuackIncome = 0
				--		if HasProperty("Hospital", "QuackIncome") then
				--			QuackIncome = GetProperty("Hospital","QuackIncome")
				--		end
				--		SetProperty("Hospital", "TotalIncome",(TotalIncome+MoneyToGet))
				--		SetProperty("Hospital", "RoundIncome",(RoundIncome+MoneyToGet))
				--		SetProperty("Hospital", "QuackIncome",(QuackIncome+MoneyToGet))
				--	end
					
					if dyn_IsLocalPlayer("Actor") then
						ShowOverheadSymbol("Actor", false, true, 0, "%1t", MoneyToGet)
					end
				end
			else
				if not success then
					MsgSayNoWait("", "@L_MEASURE_LISTENQUACKSALVER_NO")
					if SimGetGender("") == GL_GENDER_MALE then
						PlaySound3DVariation("", "CharacterFX/male_hoot", 0.7)
					else
						PlaySound3DVariation("", "CharacterFX/female_hoot", 0.7)
					end

					PlayAnimation("", "shake_head")
				end
			end
		end
	end

end

