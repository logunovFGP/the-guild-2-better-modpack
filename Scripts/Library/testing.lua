--- Tests helpfuncs_RandWeighted
function TestRandWeighted()
	local TestRand
	local TestResults = {0, 0, 0, 0}
	local TestWeights = {40, 15, 5, 40}
	for i=1, 100 do
		TestRand = helpfuncs_RandWeighted(TestWeights)
		TestResults[TestRand] = TestResults[TestRand] + 1
	end
	local ResultString = ""
	for i=1, 4 do
		ResultString = ResultString .. "Weight " .. TestWeights[i] .. ": " .. TestResults[i] .. "$N"
	end
	MsgBox("","",
				"",
				"RandWeighted",
				ResultString)
end