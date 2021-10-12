item_imba_death = class({})
LinkLuaModifier("modifier_imba_death_passive", "ting/items/item_death", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_death_invisible", "ting/items/item_death", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_death_fly", "ting/items/item_death", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_death_boken", "ting/items/item_death", LUA_MODIFIER_MOTION_NONE)
function item_imba_death:GetIntrinsicModifierName() return "modifier_imba_death_passive" end
function item_imba_death:GetAbilityTextureName() return "death"  end
function item_imba_death:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	caster:EmitSound("DOTA_Item.InvisibilitySword.Activate")


	local pfx = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_death_lines.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(pfx, 1, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(pfx)
	
	local ex = true
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius_s"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do	
		if enemy and enemy:IS_TrueHero_TG() then 
			ex = false
			break
		end
	end
	local modifier = caster:AddNewModifier(caster,self,"modifier_imba_death_invisible",{duration = duration})
	if ex == true then
		if modifier~=nil then
			modifier:SetStackCount(1)
		end
	else
		if modifier~=nil then
			modifier:SetStackCount(0)
		end
	end
	
	
	if caster:HasModifier("modifier_item_premium_phase_boots_pa") then
		caster:AddNewModifier(caster,self,"modifier_imba_death_fly",{duration = duration})
	end

end


--主动隐身

modifier_imba_death_invisible = class({})
LinkLuaModifier("modifier_imba_death_boken", "ting/items/item_death", LUA_MODIFIER_MOTION_NONE)

function modifier_imba_death_invisible:IsDebuff()			return false end
function modifier_imba_death_invisible:IsHidden() 			return false end
function modifier_imba_death_invisible:IsPurgable() 		return false end
function modifier_imba_death_invisible:IsPurgeException() 	return false end 
function modifier_imba_death_invisible:IsPurgeException() 	return false end 
function modifier_imba_death_invisible:OnCreated()
	if self:GetAbility() == nil then 
		return  
	end 
	self.ability = self:GetAbility()
	self.critical = self.ability:GetSpecialValueFor("critical")
	self.movespeed = self.ability:GetSpecialValueFor("move_speed_ex")
	self.duration_boken = self.ability:GetSpecialValueFor("duration_boken")
	self.duration_stun = self.ability:GetSpecialValueFor("duration_stun")	
	
	self.ex = true
end
function modifier_imba_death_invisible:DeclareFunctions() 	return {MODIFIER_EVENT_ON_TAKEDAMAGE,MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS, MODIFIER_PROPERTY_DISABLE_AUTOATTACK, MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_ABILITY_EXECUTED,MODIFIER_PROPERTY_INVISIBILITY_LEVEL,MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT} end

function modifier_imba_death_invisible:GetDisableAutoAttack() return true end	
function modifier_imba_death_invisible:GetModifierProjectileSpeedBonus()
    return  99999
end
function modifier_imba_death_invisible:GetModifierMoveSpeedBonus_Constant() return self.movespeed end
function modifier_imba_death_invisible:GetTexture()		return "item_death" end	
function modifier_imba_death_invisible:CheckState()
	local tab_a = {[MODIFIER_STATE_INVISIBLE] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true}
	local tab_b = {
		[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true
		}
	if self:GetStackCount() > 0 then
			return tab_b 
		else 
			return tab_a
	end
	return tab_a
end
function modifier_imba_death_invisible:OnTakeDamage(keys)
	if self.ex then 
		if keys.attacker == self:GetParent() and keys.unit:IS_TrueHero_TG() then
			self:SetStackCount(0)
			self.ex = false
		end
	end
end

function modifier_imba_death_invisible:OnAttackLanded(keys)
	if not IsServer() then
		return
	end
	
	if keys.attacker == self:GetParent() and keys.attacker:HasModifier("modifier_imba_death_invisible") then 
		keys.target:AddNewModifier_RS(keys.attacker,self.ability,"modifier_imba_death_boken",{duration = self.duration_boken})
		self:GetParent():RemoveModifierByName("modifier_imba_death_fly")
		
		if keys.attacker:HasModifier("modifier_item_premium_phase_boots_pa") then
			keys.target:AddNewModifier_RS(keys.attacker,self.ability,"modifier_imba_stunned",{duration = self.duration_stun})
		end	
		self:Destroy()
	end
end

function modifier_imba_death_invisible:GetModifierPreAttack_CriticalStrike(keys)
	if IsServer() and keys.attacker == self:GetParent() and not keys.target:IsBuilding() and not keys.target:IsOther() then	
			return self.critical		
	end
end

function modifier_imba_death_invisible:OnAbilityExecuted(keys)
	if not IsServer() then
		return
	end
	if keys.unit ~= self:GetParent() then
		return
	end
	if keys.ability:GetAbilityName() == "item_imba_death"  then
		return
	end	
	if keys.ability:GetAbilityName() == "item_premium_phase_boots"  then
		return
	end	
	
	if keys.unit == self:GetParent() and keys.unit:HasModifier("modifier_imba_death_invisible") then 
		self:GetParent():RemoveModifierByName("modifier_imba_death_fly")			
	end
	self:Destroy()
end



function modifier_imba_death_invisible:GetEffectName() 
		return "particles/generic_hero_status/status_invisibility_start.vpcf" 
end

function modifier_imba_death_invisible:GetEffectAttachType() return PATTACH_ABSORIGIN end
function modifier_imba_death_invisible:GetModifierInvisibilityLevel() return 1 end







--飞行buff
modifier_imba_death_fly = class({})
function modifier_imba_death_fly:IsDebuff()			return false end
function modifier_imba_death_fly:IsHidden() 			return true end
function modifier_imba_death_fly:IsPurgable() 		return false end
function modifier_imba_death_fly:IsPurgeException() 	return false end 
function modifier_imba_death_fly:CheckState()
	if self:GetParent():HasModifier("modifier_item_premium_phase_boots_pa") then
		return {[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true}
	end
end

--破坏
modifier_imba_death_boken = class({})
function modifier_imba_death_boken:IsDebuff()			return true end
function modifier_imba_death_boken:IsHidden() 			return false end
function modifier_imba_death_boken:IsPurgable() 		return true end
function modifier_imba_death_boken:GetTexture()		return "item_death" end	
function modifier_imba_death_boken:CheckState()
	return	{[MODIFIER_STATE_PASSIVES_DISABLED] = true}
end

--被动
modifier_imba_death_passive = class({})
function modifier_imba_death_passive:IsDebuff()			return false end
function modifier_imba_death_passive:IsHidden() 			return true end
function modifier_imba_death_passive:IsPurgable() 			return false end
function modifier_imba_death_passive:IsPurgeException() 	return false end


function modifier_imba_death_passive:OnCreated()		
	if not self:GetAbility() then   
		return  
	end 
	self.ability = self:GetAbility()
	self.parent  = self:GetParent()
	self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
	self.bonus_asp = self.ability:GetSpecialValueFor("bonus_asp")
	self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
	self.movespeed = self.ability:GetSpecialValueFor("movespeed")
	self.chance    = self.ability:GetSpecialValueFor("crit_chance")
	self.crit	   = self.ability:GetSpecialValueFor("critical")
	self.duration = self.ability:GetSpecialValueFor("duration_boot")
end

function modifier_imba_death_passive:GetModifierPreAttack_CriticalStrike(keys)
	if IsServer() and keys.attacker == self:GetParent() and not keys.target:IsBuilding() and not keys.target:IsOther() then
			if PseudoRandom:RollPseudoRandom(self.ability, self.chance) then
				return self.crit		
			end
	end
end

function modifier_imba_death_passive:DeclareFunctions() return {MODIFIER_EVENT_ON_ABILITY_EXECUTED,MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_PROVIDES_FOW_POSITION, MODIFIER_EVENT_ON_DEATH} end
function modifier_imba_death_passive:GetModifierBonusStats_Agility() return self.bonus_agi end
function modifier_imba_death_passive:GetModifierPreAttack_BonusDamage() return self.bonus_damage end
function modifier_imba_death_passive:GetModifierAttackSpeedBonus_Constant() return self.bonus_asp end
function modifier_imba_death_passive:GetModifierMoveSpeedBonus_Percentage() return self.movespeed end
function modifier_imba_death_passive:OnAbilityExecuted(keys)
	if not IsServer() then
		return
	end
	if keys.unit ~= self.parent then
		return
	end

	if keys.ability:GetAbilityName() == "item_premium_phase_boots" then
		self.parent:AddNewModifier(self.parent,self.ability,"modifier_imba_death_invisible",{duration = self.duration})
	end
	
end




