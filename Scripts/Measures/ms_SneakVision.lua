function Run()

	if SimGetClass("") ~= 4 then
		return
	end

	local skill = GetSkillValue("", SHADOW_ARTS)
	if skill == nil then
		skill = 0
	end
	local t = skill / 10.0
	if t > 1.0 then
		t = 1.0
	end
	if t < 0.0 then
		t = 0.0
	end

	local duration = 0.5 + t * 1.0
	local cooldown = 8.0 - t * 4.0

	SetMeasureRepeat(cooldown)
	SneakVisActivate("", duration)
end

function CleanUp()
end
