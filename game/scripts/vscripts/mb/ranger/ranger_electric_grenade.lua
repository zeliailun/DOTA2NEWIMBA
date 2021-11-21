-- Editors:
-- MysticBug, 20.09.2021
--Abilities
ranger_electric_grenade = class({})

LinkLuaModifier( "modifier_ranger_electric_grenade_debuff", "mb/ranger/ranger_electric_grenade.lua", LUA_MODIFIER_MOTION_NONE )

function ranger_electric_grenade:IsHiddenWhenStolen() 	return false end
function ranger_electric_grenade:IsRefreshable() 		return true  end
function ranger_electric_grenade:IsStealable() 		return true  end
--------------------------------------------------------------------------------
-- Ability Start
function ranger_electric_grenade:OnSpellStart()
	local caster      = self:GetCaster()
	local pos         = self:GetCursorPosition()
	local distance    = (pos - caster:GetAbsOrigin()):Length2D()
	local direction   = (pos - caster:GetAbsOrigin()):Normalized()
	      direction.z = 0
	--local pfxname     = "particles/units/heroes/hero_sniper/sniper_shard_concussive_grenade_model.vpcf"
	local pfxname     = "particles/heroes/ranger/ranger_electric_grenade.vpcf"
	local target      = CreateModifierThinker(caster, self, "modifier_dummy_thinker", {duration = 5}, pos, caster:GetTeamNumber(), false)
	local info = 
	{
		Ability = self,
		EffectName = pfxname,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = distance,
		fStartRadius = 0,
		fEndRadius = 0,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_NONE,
		bDeleteOnHit = true,
		vVelocity = direction * 1200,
		bProvidesVision = false,
		ExtraData = {dummy = target:entindex()}
	}
	ProjectileManager:CreateLinearProjectile(info)
	caster:EmitSound("Hero_Sniper.ConcussiveGrenade.Cast")
end


function ranger_electric_grenade:OnProjectileThink_ExtraData(pos, keys)
	if keys.dummy and EntIndexToHScript(keys.dummy) then
		EntIndexToHScript(keys.dummy):SetOrigin(GetGroundPosition(pos, nil))
		AddFOWViewer(self:GetCaster():GetTeamNumber(), pos, 200, FrameTime(), false)
	end
end

function ranger_electric_grenade:OnProjectileHit_ExtraData(target, pos, keys)
	if keys.dummy and EntIndexToHScript(keys.dummy) then
		EntIndexToHScript(keys.dummy):SetOrigin(GetGroundPosition(pos, nil))
		local dummy = EntIndexToHScript(keys.dummy)
		
		local damageTable = {
			--victim = enemy,
			attacker = self:GetCaster(),
			damage = self:GetSpecialValueFor("grenade_damage"),
			damage_type = self:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE, --Optional.
			ability = self, --Optional.
		} 
		local grenade_radius = self:GetSpecialValueFor("grenade_radius")
		--AOE Damage
		local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), pos, nil, grenade_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(enemies) do
			if enemy:IsAlive() then 
				damageTable.victim = enemy
				ApplyDamage(damageTable)
				--add
				enemy:AddNewModifier(self:GetCaster(), self, "modifier_ranger_electric_grenade_debuff", {duration = self:GetSpecialValueFor("debuff_duration")})
			end
		end
		--effect
		local particle = ParticleManager:CreateParticle("particles/econ/items/razor/razor_ti6/razor_plasmafield_ti6.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, pos)
		ParticleManager:SetParticleControl(particle, 1, Vector(grenade_radius, grenade_radius, 1))
		
		Timers:CreateTimer(0.6,
		function()
			ParticleManager:SetParticleControl(particle, 1, Vector(-grenade_radius, grenade_radius, 1))
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
		end)
		dummy:EmitSound("Item.Maelstrom.Chain_Lightning")
	end
end

--------------------------------------------------------------
--		   MODIFIER_RANGER_ELECTRIC_GRENADE_DEBUFF          --
--------------------------------------------------------------
--DEBUFF
modifier_ranger_electric_grenade_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ranger_electric_grenade_debuff:IsHidden() return false end
function modifier_ranger_electric_grenade_debuff:IsDebuff() return true end
function modifier_ranger_electric_grenade_debuff:IsPurgable() return true end
--------------------------------------------------------------------------------
-- Initializations
function modifier_ranger_electric_grenade_debuff:OnCreated( kv )
	-- references  
end

function modifier_ranger_electric_grenade_debuff:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_ranger_electric_grenade_debuff:GetEffectName() return "particles/units/heroes/hero_razor/razor_ambient.vpcf" end
function modifier_ranger_electric_grenade_debuff:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_ranger_electric_grenade_debuff:ShouldUseOverheadOffset() return true end
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ranger_electric_grenade_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}

	return funcs
end
function modifier_ranger_electric_grenade_debuff:OnAttackLanded(keys)
	if not IsServer() then
		return
	end
	if keys.target ~= self:GetParent() or not keys.target:IsAlive() then
		return
	end
	if PseudoRandom:RollPseudoRandom(self:GetAbility(), self:GetAbility():GetSpecialValueFor("electric_chance")) then
		-- precache damage
		local damageTable = {
			victim = keys.target,
			attacker = keys.attacker,
			damage = self:GetAbility():GetSpecialValueFor("electric_damage"),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(), --Optional.
		}
		local damage_calculate = ApplyDamage(damageTable)
		-- overhead event
		SendOverheadEventMessage(
			nil, --DOTAPlayer sendToPlayer,
			OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
			keys.target,
			damage_calculate,
			keys.attacker:GetPlayerOwner() -- DOTAPlayer sourcePlayer
		)
	end
end
--------------------------------------------------------------------------------
-- Graphics & Animations
