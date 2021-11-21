-- Editors:
-- MysticBug, 29.10.2021
------------------------------------------------------------
--		   		 RANGER_SNIPER_ASSASSINATE         		  --
------------------------------------------------------------
ranger_sniper_assassinate = class({})

LinkLuaModifier( "modifier_ranger_sniper_assassinate_stack", "mb/ranger/ranger_sniper_assassinate.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Phase Start
function ranger_sniper_assassinate:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	-- play effects
	local sound_cast = "Ability.AssassinateLoad"
	EmitSoundOnClient( sound_cast, caster:GetPlayerOwner() )

	-- Check Stack 
	if not caster:HasModifier("modifier_ranger_sniper_assassinate_stack") then 
		caster:AddNewModifier(caster, self, "modifier_ranger_sniper_assassinate_stack", {})
	end

	return true -- if success
end

function ranger_sniper_assassinate:GetCastPoint()
	--Scepter
	if self:GetCaster():HasScepter() then 
		return self:GetSpecialValueFor("scepter_cast_point_pct")
	end
	return self.BaseClass.GetCastPoint(self)
end
--------------------------------------------------------------------------------
-- Ability Start
function ranger_sniper_assassinate:OnSpellStart()
	--damage stack  mark 
	self.wait = false
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- load data
	local projectile_name = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf"
	local projectile_speed = self:GetSpecialValueFor("projectile_speed")

	local info = {
		Target = target,
		Source = caster,
		Ability = self,	
		
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		bDodgeable = true,                           -- Optional
		ExtraData = { buckshot = true}
	}
	ProjectileManager:CreateTrackingProjectile(info)

	-- effects
	local sound_cast = "Ability.Assassinate"
	EmitSoundOn( sound_cast, caster )
	local sound_target = "Hero_Sniper.AssassinateProjectile"
	EmitSoundOn( sound_cast, target )
end
--------------------------------------------------------------------------------
-- Projectile
function ranger_sniper_assassinate:OnProjectileHit_ExtraData( target, location, extradata )
	-- cancel if gone
	if (not target) or target:IsInvulnerable() or target:IsOutOfGame() or target:TriggerSpellAbsorb( self ) then
		return
	end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local damage_stack = caster:GetModifierStackCount("modifier_ranger_sniper_assassinate_stack", nil) * self:GetSpecialValueFor("damage_stack")
	local damageTable = {
		victim = target,
		attacker = caster,
		damage = damage + damage_stack,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self, --Optional.
	}
	
	if extradata.buckshot == 1 then 
		-- load data
		local projectile_name = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf"
		local projectile_speed = self:GetSpecialValueFor("projectile_speed")
		local scatter_range = self:GetSpecialValueFor("scatter_range")
		local scatter_width = self:GetSpecialValueFor("scatter_width")
		local info = {
			Target = target,
			Source = caster,   
			Ability = self,	
			
			EffectName = projectile_name,
			iMoveSpeed = projectile_speed,
			bDodgeable = true,                           -- Optional
			ExtraData = { buckshot = false}
		}
		-- buckshot
		local direction = GetDirection2D(target:GetAbsOrigin(), caster:GetAbsOrigin())
		local enemies = FindUnitsInTrapezoid(caster:GetTeamNumber(), direction, GetGroundPosition(target:GetAbsOrigin(), nil), scatter_width, scatter_range, scatter_range, nil, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(enemies) do
			if enemy:IsAlive() and enemy ~= target then
				info.Target = enemy
				info.Source = target  --just for pfx
				ProjectileManager:CreateTrackingProjectile(info)
			end
		end
	else
		-- buck 
		local buckshot_damage_pct = self:GetSpecialValueFor("buckshot_damage_pct")
		damageTable.damage = (damage + damage_stack) * buckshot_damage_pct / 100
	end
	-- print("AssassinateDamage Buckshot",damageTable.damage,extradata.buckshot)
	-- apply damage
	local damage_calculate = ApplyDamage(damageTable)
	-- overhead event
	SendOverheadEventMessage(
		nil, --DOTAPlayer sendToPlayer,
		OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
		target,
		damage_calculate,
		caster:GetPlayerOwner() -- DOTAPlayer sourcePlayer
	)
	-- short stun
	target:Interrupt()
	-- Scepter Stun
	if caster:HasScepter() then 
		--scepter_stun_duration
		local scepter_stun_duration = self:GetSpecialValueFor("scepter_stun_duration")
		target:AddNewModifier(caster, self, "modifier_stunned", { duration = scepter_stun_duration})
	end
	-- effects1
	local sound_cast = "Hero_Sniper.AssassinateDamage"
	EmitSoundOn( sound_cast, target )
end

function ranger_sniper_assassinate:KillCredit(target)
	if not self.wait and target:IsHero() then
		local buff = self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_ranger_sniper_assassinate_stack", {})
		if buff then
			buff:SetStackCount(buff:GetStackCount() + 1)
		end
		self.wait = true
	end
end

-----------------------------------------------------
--	    MODIFIER_RANGER_SNIPER_ASSASSINATE_STACK   --
-----------------------------------------------------
--big_game_hunter

modifier_ranger_sniper_assassinate_stack = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ranger_sniper_assassinate_stack:IsHidden() return false end
function modifier_ranger_sniper_assassinate_stack:IsDebuff() return false end
function modifier_ranger_sniper_assassinate_stack:IsPurgable() return false end
function modifier_ranger_sniper_assassinate_stack:RemoveOnDeath() return self:GetParent():IsIllusion() end
--------------------------------------------------------------------------------
-- Initializations
function modifier_ranger_sniper_assassinate_stack:OnCreated( kv )
	self.damage_stack = self:GetAbility() ~= nil and self:GetAbility():GetSpecialValueFor("damage_stack") or 20
	if IsServer() then
		--self:PlayEffects()
	end
end
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ranger_sniper_assassinate_stack:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_EVENT_ON_DEATH
	}
	return funcs
end
function modifier_ranger_sniper_assassinate_stack:OnTooltip() return self:GetStackCount() * self.damage_stack end
function modifier_ranger_sniper_assassinate_stack:OnDeath(keys)
	if not IsServer() then
		return
	end
	if keys.attacker == self:GetParent() and keys.unit:IsHero() and keys.inflictor and  keys.inflictor:GetName() == "ranger_sniper_assassinate" then
		self:GetAbility():KillCredit(keys.unit)
	end	
end
--------------------------------------------------------------------------------
-- Status Effects
--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ranger_sniper_assassinate_stack:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_sniper/sniper_crosshair.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticleForTeam( particle_cast, PATTACH_OVERHEAD_FOLLOW, self:GetParent(), self:GetCaster():GetTeamNumber() )
	-- buff particle
	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		true
	)
end