-------------------------------------------------------------------------------
----
----	OVERVIEW "as_UseThesisPaper"
----
----	with this artifact, the player can try to change the faith of the sims 
----	in range to his own
----
-------------------------------------------------------------------------------


function Run()

	-- AI Script behavior
	if IsStateDriven() then
		local ItemName = "ThesisPaper"
		if GetItemCount("", ItemName, INVENTORY_STD) == 0 then
			if not ai_BuyItem("", ItemName, 1, INVENTORY_STD) then
				return
			end
		end
	end
	
	-- Measure parameter
	local EffectRange = 1200
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	if RemoveItems("", "ThesisPaper", 1) == 1 then
		
		-- initialize measure
		f_MoveTo("", "Destination", GL_MOVESPEED_RUN)
		MeasureSetNotRestartable()
		SetMeasureRepeat(TimeOut)	
	
		-- ani stuff	
		
		local Time
		Time = PlayAnimationNoWait("", "use_book_standing")
		Sleep(1)
		PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
		CarryObject("", "Handheld_Device/Anim_openscroll.nif", false)
		Sleep(2)
		local OwnReligion = SimGetReligion("")
		
		GetPosition("", "MyPosition")
		local count = Find("Owner", "__F((Object.GetObjectsByRadius(Sim) == "..EffectRange..") AND NOT(Object.HasSameReligion(Owner))", "Sim", -1) or 0
		
		SetData("Blocked", 1)
		--block listeners
		for i=0, count-1 do 
			SendCommandNoWait("Sim"..i, "ConvertReligion")
			AlignTo("Sim"..i, "")
			Sleep(0.2)
		end
		
		if OwnReligion == 0 then
			MsgSayNoWait("", "@L_PROCLAIM_THESISPAPER_CATHOLIC")
		else
			MsgSayNoWait("", "@L_PROCLAIM_THESISPAPER_PROTESTANT")
		end
		
		Sleep(Time-4)
		PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
		CarryObject("", "", false)
		
		-- convert if skill check is successfull
		for i=0, count-1 do
			local Alias = "Sim"..i
			Sleep(0.2)

			if chr_SkillCheck("", RHETORIC, 1, Alias, EMPATHY) then
				MsgSayNoWait(Alias, "@L_CHURCH_093_WINBELIEVERS_COMMENT_POSITIVE")
				SimSetReligion(Alias, OwnReligion)
				GetPosition(Alias, "ParticleSpawnPos")
				
				if (OwnReligion == 0) then
					ShowOverheadSymbol(Alias, false, true, 0, "@L$S[2015]")
					StartSingleShotParticle("particles/pray_glow.nif", "ParticleSpawnPos", 1, 4)
				else
					ShowOverheadSymbol(Alias, false, true, 0, "@L$S[2014]")
					StartSingleShotParticle("particles/pray_glow.nif", "ParticleSpawnPos", 1, 4)
				end
				
				PlayAnimation(Alias, "cogitate")
			else
				PlayAnimation(Alias, "shakehead")
			end
		end
		SetData("Blocked", 0)
			
		-- no sims of opposite religion to affect
		if (count == 0) then
			feedback_OverheadComment("", "@L_ARTEFACTS_OVERHEAD_+2", false, false)
			Sleep(1)
		end
			
		chr_GainXP("", GetData("BaseXP"))
	end
end

-- -----------------------
-- ConvertReligion
-- -----------------------
function ConvertReligion()
	while GetData("Blocked") == 1 do
		Sleep(4)
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	feedback_OverheadActionName("")
	SetData("Blocked", 0)
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

