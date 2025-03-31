function Run()
	local Activity = {"drunk","carry","carrypeel","pillory","arrest","execute","converse","unconscious",
	"carrywood","childplay","chop","duel","duelshoot","fighting","fightingunarmed","wagondraw","wagonsteer"}
	local InitData = InitData("@P"..
	"@B[1,drunk,drunk,hud/buttons/btn_will.tga]"..
	"@B[2,carry,carry,hud/buttons/btn_will.tga]"..
	"@B[3,carrypeel,carrypeel,hud/buttons/btn_will.tga]"..
	"@B[4,pillory,pillory,hud/buttons/btn_will.tga]"..
	"@B[5,arrest,arrest,hud/buttons/btn_will.tga]"..
	"@B[6,execute,execute,hud/buttons/btn_will.tga]"..
	"@B[7,converse,converse,hud/buttons/btn_will.tga]"..
	"@B[8,unconscious,unconscious,hud/buttons/btn_will.tga]"..
	"@B[9,carrywood,carrywood,hud/buttons/btn_will.tga]"..
	"@B[10,childplay,childplay,hud/buttons/btn_will.tga]"..
	"@B[11,chop,chop,hud/buttons/btn_will.tga]"..
	"@B[12,duel,duel,hud/buttons/btn_will.tga]"..
	"@B[13,duelshoot,duelshoot,hud/buttons/btn_will.tga]"..
	"@B[14,fighting,fighting,hud/buttons/btn_will.tga]"..
	"@B[15,fightingunarmed,fightingunarmed,hud/buttons/btn_will.tga]"..
	"@B[16,wagondraw,wagondraw,hud/buttons/btn_will.tga]"..
	"@B[17,wagonsteer,wagonsteer,hud/buttons/btn_will.tga]"..
	"@B[18,Clear Activity,Clear Activity,hud/buttons/btn_will.tga]",
	nil,
	"Which MoveSetStance do you want to try?",
	"")

	if InitData == 18 then
		MoveSetActivity("")
	else
		MoveSetActivity("", Activity[InitData])
	end
end