function Run()
	local Stance = {GL_STANCE_STAND,GL_STANCE_SIT,GL_STANCE_SITBENCH,GL_STANCE_SITGROUND,GL_STANCE_CROUCH,GL_STANCE_KNEEL,GL_STANCE_LAY,GL_STANCE_LAYGROUND}
	local InitData = InitData("@P"..
	"@B[1,GL_STANCE_STAND,GL_STANCE_STAND,hud/buttons/btn_will.tga]"..
	"@B[2,GL_STANCE_SIT,GL_STANCE_SIT,hud/buttons/btn_will.tga]"..
	"@B[3,GL_STANCE_SITBENCH,GL_STANCE_SITBENCH,hud/buttons/btn_will.tga]"..
	"@B[4,GL_STANCE_SITGROUND,GL_STANCE_SITGROUND,hud/buttons/btn_will.tga]"..
	"@B[5,GL_STANCE_CROUCH,GL_STANCE_CROUCH,hud/buttons/btn_will.tga]"..
	"@B[6,GL_STANCE_KNEEL,GL_STANCE_KNEEL,hud/buttons/btn_will.tga]"..
	"@B[7,GL_STANCE_LAY,GL_STANCE_LAY,hud/buttons/btn_will.tga]"..
	"@B[8,GL_STANCE_LAYGROUND,GL_STANCE_LAYGROUND,hud/buttons/btn_will.tga]",
	nil,
	"Which MoveSetStance do you want to try?",
	"")

	MoveSetStance("", Stance[InitData])
end