-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end

-- ------------------
-- AttackEnemy
-- ------------------
function AttackEnemy(Owner, OwnLevel, EnemyLevel)
	if AliasExists(Owner) then
		chr_GainXP(Owner, (EnemyLevel - OwnLevel + 10) * 5)
	end
end

-- ------------------
-- BuyNobilityTitle
-- ------------------
function BuyNobilityTitle(Owner, BaseXP, Title)
	
	local GainXP = BaseXP + (Title * 50)

	if AliasExists(Owner) then
		local Count = DynastyGetMemberCount(Owner)
		for i=0, Count-1 do
			if DynastyGetMember(Owner, i, "Member") then
				chr_GainXP("Member", GainXP)
			end
		end
	end
end

-- ------------------
-- CaptureBuilding
-- ------------------
function CaptureBuilding(Owner, BaseXP, BuildingLevel)
	if AliasExists(Owner) then
		chr_GainXP(Owner, BaseXP + BuildingLevel * 150)
	end
end

-- ------------------
-- CohabitWithCharacter
-- ------------------
function CohabitWithCharacter(Owner, ChildCount)
	if AliasExists(Owner) then
		if ChildCount == 0 then
			chr_GainXP(Owner, 150)
		else
			chr_GainXP(Owner, 100)
		end
	end
end

-- ------------------
-- CourtingSuccess
-- ------------------
function CourtingSuccess(Owner, Difficulty, Ceremony)
	if AliasExists(Owner) then
		if Difficulty < 4 then
			if Ceremony == 1 then
				chr_GainXP(Owner, 500)
			else
				chr_GainXP(Owner, 250)
			end
		elseif Difficulty < 7 then
			if Ceremony == 1 then
				chr_GainXP(Owner, 1000)
			else
				chr_GainXP(Owner, 500)
			end
		elseif not Difficulty == nil then
			if Ceremony == 1 then
				chr_GainXP(Owner, 1500)
			else
				chr_GainXP(Owner, 750)
			end
		end
	end
end

-- ------------------
-- BuildBuilding
-- ------------------
function BuildBuilding(Owner, Level)
	if AliasExists(Owner) then
		chr_GainXP(Owner, 250 + Level * 250)
	end
end

-- ------------------
-- RunForAnOffice
-- ------------------
function RunForAnOffice(Owner, OfficeLevel)
	if AliasExists(Owner) then
		chr_GainXP(Owner, OfficeLevel * 100)
	end
end

-- ------------------
-- DuelWithOpponent
-- ------------------
function DuelWithOpponent(Owner, Killed, SkillFactor)
	local BaseXP = GL_EXP_GAIN_HIGH_RISK
	
	if SkillFactor > 0 then
		if Killed then
			BaseXP = math.floor(BaseXP + (BaseXP * (0.2 * SkillFactor)))
		else
			BaseXP = math.floor(BaseXP + (BaseXP * (0.1 * SkillFactor)))
		end
	else
		if Killed then
			BaseXP = math.floor(BaseXP + (BaseXP * (0.05 * SkillFactor)))
			if BaseXP < GL_EXP_GAIN_HIGH_RISK then
				BaseXP = GL_EXP_GAIN_HIGH_RISK
			end
		end
	end
	
	if AliasExists(Owner) then
		chr_GainXP(Owner, BaseXP)
	end
end

-- ------------------
-- ChargeCharacter
-- ------------------
function ChargeCharacter(Owner, SentenceLevel)
	if AliasExists(Owner) then
		chr_GainXP(Owner, SentenceLevel * 100)
	end
end

-- ------------------
-- OrderASabotage
-- ------------------
function OrderASabotage(Owner, BaseXP)
	if AliasExists(Owner) then
		chr_GainXP(Owner, BaseXP)
	end
end

-- ------------------
-- LevelUpBuilding
-- ------------------
function LevelUpBuilding(Owner, Level)
	if AliasExists(Owner) then
		chr_GainXP(Owner, 250 + Level * 250)
	end
end

-- ------------------
-- ApplyDeposition
-- ------------------
function ApplyDeposition(Owner, OfficeLevel)
	if AliasExists(Owner) then
		chr_GainXP(Owner, OfficeLevel * 100)
	end
end

-- ------------------
-- BurgleAHouse
-- ------------------
function BurgleAHouse(Owner, BuildingLevel)
	if AliasExists(Owner) then
		chr_GainXP(Owner, BuildingLevel * 50)
	end
end

-- ------------------
-- HijackCharacter
-- ------------------
function HijackCharacter(Owner, Level)
	if AliasExists(Owner) then
		chr_GainXP(Owner, Level * 50)
	end
end

-- ------------------
-- WaylayForBooty
-- ------------------
function WaylayForBooty(Owner, ItemValue)
	if AliasExists(Owner) then
		local xp = ItemValue / 5
		if xp > 1000 then
			xp = 1000
		end
		chr_GainXP(Owner, xp)
	end
end

-- ------------------
-- School
-- ------------------
function School(Owner)
	chr_GainXP(Owner, 1000)
end

function Apprenticeship(Owner)
--	if SimGetClass(Owner)~=3 then
		chr_GainXP(Owner, 500)
--	end
end

function University(Owner)
	chr_GainXP(Owner, 1000)
end

function Doctor(Owner)
	chr_GainXP(Owner, 1000)
end

