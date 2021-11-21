-- Editors:
-- MysticBug, 20.09.2021
--Abilities
ranger_switch_weapon = class({})

LinkLuaModifier( "modifier_ranger_switch_weapon_passive", "mb/ranger/ranger_switch_weapon.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ranger_take_aim", "mb/ranger/ranger_switch_weapon.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ranger_take_aim_near", "mb/ranger/ranger_switch_weapon.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ranger_take_aim_near_debuff", "mb/ranger/ranger_switch_weapon.lua", LUA_MODIFIER_MOTION_NONE )

function ranger_switch_weapon:IsHiddenWhenStolen() 	return false end
function ranger_switch_weapon:IsRefreshable() 		return true  end
function ranger_switch_weapon:IsStealable() 		return true  end
function ranger_switch_weapon:GetIntrinsicModifierName() return "modifier_ranger_switch_weapon_passive" end
function ranger_switch_weapon:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_ranger_take_aim_near") then  
		return  "sniper_take_aim"	
	end	
	return "sniper_take_aim" 
end
--------------------------------------------------------------------------------
-- Ability Start
function ranger_switch_weapon:OnOwnerSpawned() --重生检查一下枪械模式
	if not IsServer() then return end
	if self:GetCaster():HasModifier("modifier_ranger_take_aim_near") and self:GetCaster():HasModifier("modifier_ranger_take_aim") then 
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_ranger_take_aim", {})
	end
end
function ranger_switch_weapon:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	-- switch weapon
	if caster:HasModifier("modifier_ranger_take_aim_near") then 
		caster:RemoveModifierByName("modifier_ranger_take_aim_near")
		caster:AddNewModifier(self:GetCaster(), self, "modifier_ranger_take_aim", {})
	else 
		caster:RemoveModifierByName("modifier_ranger_take_aim")
		caster:AddNewModifier(self:GetCaster(), self, "modifier_ranger_take_aim_near", {})
	end
	-- Sound
	caster:EmitSound("Ability.AssassinateLoad")
end


function ranger_switch_weapon:OnProjectileHit_ExtraData(target, location, keys)
	if target then 
		--AOE Damage
		local damageTable = {
			--victim = enemy,
			attacker = self:GetCaster(),
			damage = self:GetSpecialValueFor("proc_aoe_damage"),
			damage_type = self:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE, --Optional.
			ability = self, --Optional.
		} 
		local aoe_radius = self:GetSpecialValueFor("aoe_radius")

		local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), location, nil, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(enemies) do
			if enemy:IsAlive() then 
				damageTable.victim = enemy
				ApplyDamage(damageTable)
			end
		end
		--Effect
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, location)
		--ParticleManager:SetParticleControl(pfx, 1, Vector(0,0,aoe_radius))
		ParticleManager:SetParticleControl(pfx, 2, Vector(aoe_radius, aoe_radius, aoe_radius))
		Timers:CreateTimer(5.0, function()
				ParticleManager:DestroyParticle(pfx, true)
				ParticleManager:ReleaseParticleIndex(pfx)
				return nil
			end
		)
		local sound = CreateModifierThinker(self:GetCaster(), self, "modifier_dummy_thinker", {duration = 0.5}, location, self:GetCaster():GetTeamNumber(), false)
		sound:EmitSound("Hero_Techies.LandMine.Detonate")
	end
end
---------------------------------------------------------------------
--Modifiers
modifier_ranger_switch_weapon_passive = class({})

function modifier_ranger_switch_weapon_passive:IsDebuff()			return false end
function modifier_ranger_switch_weapon_passive:IsHidden() 			return true end
function modifier_ranger_switch_weapon_passive:IsPurgable() 		return false end
function modifier_ranger_switch_weapon_passive:IsPurgeException() 	return false end
function modifier_ranger_switch_weapon_passive:DeclareFunctions()	return {MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL} end
function modifier_ranger_switch_weapon_passive:OnCreated(table)
	if self:GetParent():HasModifier("modifier_ranger_take_aim_near") and self:GetParent():HasModifier("modifier_ranger_take_aim") then 
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_ranger_take_aim", {})
	end 
end

function modifier_ranger_switch_weapon_passive:GetModifierProcAttack_BonusDamage_Physical(keys)
	if not IsServer() then
		return
	end
	if keys.attacker ~= self:GetParent() or self:GetParent():IsIllusion() or self:GetParent():PassivesDisabled() or not keys.target:IsAlive() then
		return 
	end
	if keys.target:IsBuilding() or keys.target:IsOther() then
		return
	end
	if PseudoRandom:RollPseudoRandom(self:GetAbility(), self:GetAbility():GetSpecialValueFor("proc_chance")) then
		if self:GetParent():HasModifier("modifier_ranger_take_aim_near") then 
			--Sound
			keys.target:EmitSound("Hero_Sniper.DuckTarget")
			--Damage
			local proc_damage = self:GetAbility():GetSpecialValueFor("proc_damage")
			--Debuff
			keys.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_ranger_take_aim_near_debuff", {duration = self:GetAbility():GetSpecialValueFor("slow_duration")})
			return proc_damage
		else
			--Throw AOE
			local info = 
			{
				Target = keys.target,
				Source = self:GetParent(),
				Ability = self:GetAbility(),	
				EffectName = ("particles/units/heroes/hero_techies/techies_base_attack.vpcf"),
				iMoveSpeed = (self:GetParent():IsRangedAttacker() and self:GetParent():GetProjectileSpeed() or 900),
				iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
				bDrawsOnMinimap = false,
				bDodgeable = true,
				bIsAttack = false,
				bVisibleToEnemies = true,
				bReplaceExisting = false,
				flExpireTime = GameRules:GetGameTime() + 10,
				bProvidesVision = false,
				ExtraData = {}
			}
			ProjectileManager:CreateTrackingProjectile(info)
		end 
	end 
end

modifier_ranger_take_aim = class({})

function modifier_ranger_take_aim:IsDebuff()			return false end
function modifier_ranger_take_aim:IsHidden() 			return false end
function modifier_ranger_take_aim:IsPurgable() 		return false end
function modifier_ranger_take_aim:IsPurgeException() 	return false end
function modifier_ranger_take_aim:AllowIllusionDuplicate() return false end
function modifier_ranger_take_aim:RemoveOnDeath()	return true end
function modifier_ranger_take_aim:DeclareFunctions() return {MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE, MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, MODIFIER_PROPERTY_MOVESPEED_LIMIT, MODIFIER_PROPERTY_MOVESPEED_MAX} end
function modifier_ranger_take_aim:GetModifierAttackRangeBonus() return self:GetAbility():GetSpecialValueFor("bonus_attack_range") end

modifier_ranger_take_aim_near = class({})

function modifier_ranger_take_aim_near:IsDebuff()			return false end
function modifier_ranger_take_aim_near:IsHidden() 		return false end
function modifier_ranger_take_aim_near:IsPurgable() 		return false end
function modifier_ranger_take_aim_near:IsPurgeException() return false end
function modifier_ranger_take_aim_near:AllowIllusionDuplicate() return false end
function modifier_ranger_take_aim_near:RemoveOnDeath()	return true end
function modifier_ranger_take_aim_near:DeclareFunctions() return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACK_RANGE_BASE_OVERRIDE,MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT} end
function modifier_ranger_take_aim_near:GetModifierAttackRangeOverride() return self:GetAbility():GetSpecialValueFor("attack_range_limit") end
function modifier_ranger_take_aim_near:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("move_speed") end
function modifier_ranger_take_aim_near:GetModifierBaseDamageOutgoing_Percentage() return (0 - self:GetAbility():GetSpecialValueFor("damage_reduction")) end
function modifier_ranger_take_aim_near:GetModifierBaseAttackTimeConstant() return self:GetAbility():GetSpecialValueFor("bonus_attack_time") end

modifier_ranger_take_aim_near_debuff = class({})

function modifier_ranger_take_aim_near_debuff:IsDebuff()			return true end
function modifier_ranger_take_aim_near_debuff:IsHidden() 			return false end
function modifier_ranger_take_aim_near_debuff:IsPurgable() 			return false end
function modifier_ranger_take_aim_near_debuff:IsPurgeException() 	return false end
function modifier_ranger_take_aim_near_debuff:GetEffectName() return "particles/units/heroes/hero_sniper/sniper_headshot_slow.vpcf" end
function modifier_ranger_take_aim_near_debuff:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_ranger_take_aim_near_debuff:ShouldUseOverheadOffset() return true end
function modifier_ranger_take_aim_near_debuff:DeclareFunctions() return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE} end
function modifier_ranger_take_aim_near_debuff:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("slow") end