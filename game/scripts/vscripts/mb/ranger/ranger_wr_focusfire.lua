
-- Editors:
-- MysticBug, 20.09.2021

function TG_Direction(fpos,spos)
	local DIR=( fpos - spos):Normalized()
	DIR.z=0
	return DIR
  end

ranger_wr_focusfire=ranger_wr_focusfire or class({})
LinkLuaModifier("modifier_ranger_wr_focusfire_att", "mb/ranger/ranger_wr_focusfire", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ranger_wr_focusfire_attsp", "mb/ranger/ranger_wr_focusfire", LUA_MODIFIER_MOTION_NONE)

function ranger_wr_focusfire:IsHiddenWhenStolen() return false end
function ranger_wr_focusfire:IsStealable() return true end
function ranger_wr_focusfire:GetIntrinsicModifierName() 
    return "modifier_ranger_wr_focusfire_att" 
end

function ranger_wr_focusfire:GetCooldown(iLevel)return self.BaseClass.GetCooldown(self,iLevel) end

function ranger_wr_focusfire:OnProjectileHit_ExtraData(target, location, kv)
	if target then
		local damageTable = {
						victim = target,
						attacker = self:GetCaster(),
						damage =  self:GetSpecialValueFor( "dam" ),
						damage_type =DAMAGE_TYPE_MAGICAL,
						ability = self,
						}
						ApplyDamage(damageTable)
	end
end

modifier_ranger_wr_focusfire_att = modifier_ranger_wr_focusfire_att or class({})

function modifier_ranger_wr_focusfire_att:IsPassive() return true end
function modifier_ranger_wr_focusfire_att:IsPurgable()	return false end
function modifier_ranger_wr_focusfire_att:IsPurgeException() return false end
function modifier_ranger_wr_focusfire_att:IsHidden() return true end
function modifier_ranger_wr_focusfire_att:OnCreated()				
	if IsServer() then 
		self.wh=self:GetAbility():GetSpecialValueFor( "wh" )
		self.ch=self:GetAbility():GetSpecialValueFor( "ch" )
		self.num=self:GetAbility():GetSpecialValueFor( "num" ) 
		self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_ranger_wr_focusfire_attsp", {})
	end
end

function modifier_ranger_wr_focusfire_att:OnRefresh()	self:OnCreated()	end

function modifier_ranger_wr_focusfire_att:DeclareFunctions()	return {MODIFIER_EVENT_ON_ATTACK,} end

function modifier_ranger_wr_focusfire_att:OnAttack(mb)
	if not IsServer() or not self:GetAbility():IsCooldownReady() or self:GetParent():IsIllusion() or mb.target==mb.attacker then
		return
	end
	if mb.attacker == self:GetParent() and not self:GetParent():PassivesDisabled() and  RollPseudoRandomPercentage(self.ch,0,self:GetParent()) then
			mb.attacker:EmitSound("Ability.Powershot")
			local pos=mb.attacker:GetAbsOrigin()
			local spawn=mb.target:GetAbsOrigin()
			local dirt=TG_Direction(spawn+Vector(1,1,1),pos)
			for i=1,self.num do 
				local dir=TG_Direction(RotatePosition(pos, QAngle(0, math.random(-10,10), 0), pos + dirt * 1000),spawn) 
				local projectileTable2 =
				{
				EffectName ="particles/econ/items/windrunner/windranger_arcana/windranger_arcana_spell_powershot.vpcf",
				Ability = self:GetAbility(),
				vSpawnOrigin =pos,
				vVelocity =dir*5000,
				fDistance =1000,
				fStartRadius = self.wh,
				fEndRadius = self.wh,
				Source = mb.attacker,
				bIgnoreSource=true,
				bHasFrontalCone = false,
				iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
				iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				}
				Projectile=ProjectileManager:CreateLinearProjectile( projectileTable2 )
			end 
			self:GetAbility():UseResources(false, false, true)
	end
end

modifier_ranger_wr_focusfire_attsp=modifier_ranger_wr_focusfire_attsp or class({})

function modifier_ranger_wr_focusfire_attsp:IsHidden() 			return true end
function modifier_ranger_wr_focusfire_attsp:IsPurgable() 		return false end
function modifier_ranger_wr_focusfire_attsp:IsPurgeException() 	return false end
function modifier_ranger_wr_focusfire_attsp:DeclareFunctions()  return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT} end
function modifier_ranger_wr_focusfire_attsp:GetModifierAttackSpeedBonus_Constant()
	if not self:GetParent():PassivesDisabled() then
		return self:GetAbility():GetSpecialValueFor( "attsp" )
	end
end 