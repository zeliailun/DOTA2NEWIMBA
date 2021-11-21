-- Editors:
-- MysticBug, 20.09.2021

function TG_Direction(fpos,spos)
	local DIR=( fpos - spos):Normalized()
	DIR.z=0
	return DIR
  end
--Abilities
ranger_dr_marksmanship = class({})

LinkLuaModifier("modifier_ranger_dr_marksmanship_effect", "mb/ranger/ranger_dr_marksmanship.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ranger_dr_marksmanship_armor", "mb/ranger/ranger_dr_marksmanship.lua", LUA_MODIFIER_MOTION_NONE) 
LinkLuaModifier("modifier_ranger_dr_trueshot_damage_stack", "mb/ranger/ranger_dr_marksmanship.lua", LUA_MODIFIER_MOTION_NONE) 
LinkLuaModifier("modifier_ranger_dr_marksmanship_self", "mb/ranger/ranger_dr_marksmanship.lua", LUA_MODIFIER_MOTION_NONE)

function ranger_dr_marksmanship:GetCastRange(vLocation, hTarget) return self:GetSpecialValueFor("radius") - self:GetCaster():GetCastRangeBonus() end

function ranger_dr_marksmanship:GetIntrinsicModifierName() return "modifier_ranger_dr_marksmanship_effect" end

function ranger_dr_marksmanship:OnProjectileHit_ExtraData(target, location, ExtraData)
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

modifier_ranger_dr_marksmanship_effect = class({})

function modifier_ranger_dr_marksmanship_effect:IsDebuff()				return false end
function modifier_ranger_dr_marksmanship_effect:IsPurgable() 			return false end
function modifier_ranger_dr_marksmanship_effect:IsPurgeException() 		return false end
function modifier_ranger_dr_marksmanship_effect:GetPriority() 			return MODIFIER_PRIORITY_LOW end
function modifier_ranger_dr_marksmanship_effect:IsHidden()				return true  end
function modifier_ranger_dr_marksmanship_effect:IsAura()
	if self:GetParent():IsIllusion() or self:GetParent():PassivesDisabled() then return false end
	return true
end
function modifier_ranger_dr_marksmanship_effect:GetAuraDuration() return 0.5 end
function modifier_ranger_dr_marksmanship_effect:GetModifierAura() return "modifier_ranger_dr_trueshot_damage_stack" end
function modifier_ranger_dr_marksmanship_effect:IsAuraActiveOnDeath() 		return false end
function modifier_ranger_dr_marksmanship_effect:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("aura_radius") end
function modifier_ranger_dr_marksmanship_effect:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_ranger_dr_marksmanship_effect:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_ranger_dr_marksmanship_effect:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_ranger_dr_marksmanship_effect:GetAuraEntityReject(hTarget)	
	return not self:GetAbility():IsTrained() or self:GetParent():PassivesDisabled() 
end
function modifier_ranger_dr_marksmanship_effect:OnCreated()
	--refer
	self.wh          = self:GetAbility():GetSpecialValueFor( "mult_wh" )
	self.ch          = self:GetAbility():GetSpecialValueFor( "mult_ch" )
	self.num         = self:GetAbility():GetSpecialValueFor( "mult_num" )
	self.pure_chance = self:GetAbility():GetSpecialValueFor( "pure_chance" )

	if IsServer() then
		self.pfx = nil
		self.mult_shot = true
		self.mult_shot_attack = true
		self.reduction = 0
		self.bonus_range = 200
		self.records = {}
		self.parent = self:GetParent()
		self:StartIntervalThink(0.1)	
	end
end

function modifier_ranger_dr_marksmanship_effect:OnIntervalThink()
	local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, self:GetAbility():GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	if (#enemies > 0 or self:GetParent():PassivesDisabled()) then
		self:SetStackCount(1)
		if self.pfx then
			ParticleManager:DestroyParticle(self.pfx, false)
			ParticleManager:ReleaseParticleIndex(self.pfx)
			self.pfx = nil
		end
	else
		self:SetStackCount(0)
	end

	if self:GetStackCount() == 0 and not self.pfx then
		self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_drow/drow_marksmanship.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
		ParticleManager:SetParticleControl(self.pfx, 0, self:GetCaster():GetAbsOrigin())
		ParticleManager:SetParticleControl(self.pfx, 2, Vector(2,0,0))
		ParticleManager:SetParticleControlEnt(self.pfx, 3, self:GetCaster(), PATTACH_POINT_FOLLOW, "bow_top", self:GetCaster():GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(self.pfx, 5, self:GetCaster(), PATTACH_POINT_FOLLOW, "bow_bot", self:GetCaster():GetAbsOrigin(), true)
	end
end

function modifier_ranger_dr_marksmanship_effect:OnDestroy()
	if IsServer() and self.pfx then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
		self.pfx = nil
	end
end

function modifier_ranger_dr_marksmanship_effect:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, 
			MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, 
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_ATTACK, 
			MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
			MODIFIER_PROPERTY_PROJECTILE_NAME
			}
end

--function modifier_ranger_dr_marksmanship_effect:GetModifierBonusStats_Agility() return self:GetStackCount() ~= 0 and 0 or self:GetAbility():GetSpecialValueFor("agility_bonus") end
function modifier_ranger_dr_marksmanship_effect:GetModifierMoveSpeedBonus_Percentage() return self:GetStackCount() ~= 0 and 0 or self:GetAbility():GetSpecialValueFor("movement_speed_bonus") end
function modifier_ranger_dr_marksmanship_effect:GetModifierAttackRangeBonus() return self:GetStackCount() ~= 0 and 0 or self:GetAbility():GetSpecialValueFor("range_bonus") end
function modifier_ranger_dr_marksmanship_effect:GetModifierProjectileName() return "particles/units/heroes/hero_drow/drow_marksmanship_frost_arrow.vpcf" end
function modifier_ranger_dr_marksmanship_effect:GetPriority() 		return MODIFIER_PRIORITY_HIGH end
function modifier_ranger_dr_marksmanship_effect:StatusEffectPriority() return 20 end
function modifier_ranger_dr_marksmanship_effect:OnAttackLanded(keys)
	if not IsServer() then
		return
	end

	if keys.attacker == self:GetParent() and self.mult_shot_attack and keys.target:IsAlive() and (keys.target:IsHero() or keys.target:IsCreep() or keys.target:IsBoss()) then
		if PseudoRandom:RollPseudoRandom(self:GetAbility(), self.pure_chance) then
			keys.attacker:AddNewModifier(keys.attacker, self:GetAbility(), "modifier_ranger_dr_marksmanship_self", {})
			keys.target:EmitSound("Hero_DrowRanger.Marksmanship.Target")
			local dmg = ApplyDamage({victim = keys.target, attacker = self:GetParent(), damage = self:GetAbility():GetSpecialValueFor("pure_pct"), damage_type = self:GetAbility():GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, keys.target, dmg, nil)
			if keys.target:GetPhysicalArmorValue(false) > 0 then
				keys.target:AddNewModifier(keys.attacker, self:GetAbility(), "modifier_ranger_dr_marksmanship_armor", {})
			end			
		end
	end
end
function modifier_ranger_dr_marksmanship_effect:OnAttackRecordDestroy(keys)
	if not IsServer() then
		return
	end	
	if keys.attacker == self:GetParent() and keys.target:HasModifier("modifier_ranger_dr_marksmanship_armor") then
		keys.target:RemoveModifierByName("modifier_ranger_dr_marksmanship_armor")
	end	
	if keys.attacker == self:GetParent() and keys.attacker:HasModifier("modifier_ranger_dr_marksmanship_self") then
		keys.attacker:RemoveModifierByName("modifier_ranger_dr_marksmanship_self")
	end		
end
function modifier_ranger_dr_marksmanship_effect:OnAttack( params )
	if not IsServer() then
		return
	end	
	if params.attacker~=self:GetParent() then return end
	--if self:GetStackCount()<=0 then return end

	-- record attack
	self.records[params.record] = true

	-- decrement stack
	if params.no_attack_cooldown then return end

	-- not proc for attacking allies
	if params.target:GetTeamNumber()==params.attacker:GetTeamNumber() then return end

	-- not proc if attack can't use attack modifiers
	if not params.process_procs then return end

	--multshot
	if params.attacker == self:GetParent() and not self:GetParent():PassivesDisabled() and RollPseudoRandomPercentage(self.ch,0,self:GetParent()) then
		local pos   = params.attacker:GetAbsOrigin()
		local spawn = params.target:GetAbsOrigin()
		local dirt  = TG_Direction(spawn+Vector(1,1,1),pos)
		for i=1,self.num do 
			local dir              = TG_Direction(RotatePosition(pos, QAngle(0, (-1) * 30 + (i - 1) * 60 / (self.num - 1), 0), pos + dirt * 1000),spawn)
			local projectileTable1 = 
			{
			EffectName       = "particles/units/heroes/hero_drow/drow_multishot_proj_linear_proj.vpcf",
			vSpawnOrigin     = self:GetParent():GetAttachmentOrigin(self:GetParent():ScriptLookupAttachment("attach_attack1")),
			Ability          = self:GetAbility(),
			vVelocity        = dir*1000,
			fDistance        = 1000,
			fStartRadius     = self.wh,
			fEndRadius       = self.wh,
			Source           = params.attacker,
			bIgnoreSource    = true,
			bHasFrontalCone  = false,
			iUnitTargetTeam  = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			iUnitTargetType  = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			}
			Projectile=ProjectileManager:CreateLinearProjectile( projectileTable1 )
		end 
		self:GetAbility():UseResources(false, false, true)
		--Sound
		params.attacker:EmitSound("Hero_DrowRanger.Multishot.Attack")
	end
end

modifier_ranger_dr_marksmanship_self = class({})

function modifier_ranger_dr_marksmanship_self:IsDebuff()			return false end
function modifier_ranger_dr_marksmanship_self:IsHidden() 			return true end
function modifier_ranger_dr_marksmanship_self:IsPurgable() 			return false end
function modifier_ranger_dr_marksmanship_self:IsPurgeException() 	return false end
function modifier_ranger_dr_marksmanship_self:CheckState()
	return {[MODIFIER_STATE_CANNOT_MISS] = true}
end

modifier_ranger_dr_marksmanship_armor = class({})

function modifier_ranger_dr_marksmanship_armor:IsDebuff()				return true end
function modifier_ranger_dr_marksmanship_armor:IsHidden() 			return false end
function modifier_ranger_dr_marksmanship_armor:IsPurgable() 			return false end
function modifier_ranger_dr_marksmanship_armor:IsPurgeException() 	return false end
function modifier_ranger_dr_marksmanship_armor:DeclareFunctions() return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS} end
function modifier_ranger_dr_marksmanship_armor:GetModifierPhysicalArmorBonus(keys)
	return 0 - self:GetParent():GetPhysicalArmorBaseValue()
end

modifier_ranger_dr_trueshot_damage_stack = class({})

function modifier_ranger_dr_trueshot_damage_stack:IsDebuff()			return false end
function modifier_ranger_dr_trueshot_damage_stack:IsHidden() 			return false end
function modifier_ranger_dr_trueshot_damage_stack:IsPurgable() 			return false end
function modifier_ranger_dr_trueshot_damage_stack:IsPurgeException() 	return false end
function modifier_ranger_dr_trueshot_damage_stack:OnCreated()
	self:SetStackCount((self:GetAbility():GetSpecialValueFor("attack_bonus")))
end

function modifier_ranger_dr_trueshot_damage_stack:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, 
			}
end

function modifier_ranger_dr_trueshot_damage_stack:GetModifierPreAttack_BonusDamage() return self:GetStackCount() end
