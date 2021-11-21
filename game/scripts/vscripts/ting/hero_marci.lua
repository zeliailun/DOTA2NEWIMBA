CreateTalents("npc_dota_hero_marci", "ting/hero_marci")
--鹰击

imba_marci_2 = class({})
LinkLuaModifier("modifier_imba_marci_2_buff", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_marci_2_shard_buff", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_marci_1_move", "ting/hero_marci", LUA_MODIFIER_MOTION_HORIZONTAL)
--LinkLuaModifier("modifier_imba_marci_2_move_slow", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_marci_2_motion", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_marci_2_jump", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_marci_2_motion_down", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_marci_2_shard", "ting/hero_marci", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_imba_marci_2_shard_buff", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)

function imba_marci_2:IsStealable() return false end


function imba_marci_2:CastFilterResultLocation(vLocation)  --缠绕不能释放
	if self:GetCaster():IsRooted() then
		return UF_FAIL_CUSTOM
	end
end

function imba_marci_2:GetCustomCastErrorLocation(vLocation)
	return "dota_hud_error_ability_disabled_by_root"
end



function imba_marci_2:GetCastRange(target)
	return self:GetSpecialValueFor("range")
end
function imba_marci_2:GetAOERadius()
	return self:GetSpecialValueFor("radius")+self:GetCaster():TG_GetTalentValue("special_bonus_imba_marci_t1")
end
--self:GetCursorTarget():AddNewModifier(caster,self,"modifier_imba_marci_2_shard",{duration = dur })
function imba_marci_2:OnSpellStart()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	local pos = self:GetCursorPosition()
	local target = self:GetCursorTarget() or nil
	local direction = (pos - self.caster:GetAbsOrigin()):Normalized()
		direction.z = 0
	local max_distance = self:GetSpecialValueFor("range")+self.caster:GetCastRangeBonus()
	local distance = math.min(max_distance, (self.caster:GetAbsOrigin() - pos):Length2D())
	local tralve_duration = 0.65
	self.caster:StartGestureWithPlaybackRate(ACT_DOTA_OVERRIDE_ABILITY_2,3)
				
	
	self.caster:ClearActivityModifiers()
	self.caster:AddActivityModifier("unleash")
	
	Timers:CreateTimer(0.15, function()
			self.caster:StartGesture(ACT_DOTA_RUN)
		end)

	
	EmitSoundOn("Hero_Marci.Rebound.Cast",self.caster)
	if not self.caster:Has_Aghanims_Shard() or not self:GetAutoCastState() then
		target = nil 
	end
	
	if self:GetCaster():HasModifier("modifier_imba_marci_2_jump") then
		local pos_z = self.caster:FindModifierByName("modifier_imba_marci_2_jump").next_pos_z
		self.caster:RemoveModifierByName("modifier_imba_marci_2_jump")
		self.caster:ClearActivityModifiers()
		self.caster:AddActivityModifier("unleash")
		--print(tostring(self.caster:GetAbsOrigin().z))
		self.caster:AddNewModifier(self.caster, self, "modifier_imba_marci_2_motion_down", {duration = 0.35, height = pos_z+30,direction = direction,dis = distance,pos_x = pos.x, pos_y = pos.y, pos_z = pos_z,tar = target and target:entindex() or nil})
		return
	end

	--self.caster:AddNewModifier(self.caster, self, "modifier_imba_marci_1_move", {duration = tralve_duration, direction = direction})
	self.caster:AddNewModifier(self.caster, self, "modifier_imba_marci_2_motion", {duration = 0.35, direction = direction,dis = distance,pos_x = pos.x, pos_y = pos.y, pos_z = pos.z})	

end
--跑得快 跳得高
modifier_imba_marci_2_buff = class({})
function modifier_imba_marci_2_buff:IsDebuff()			return false end
function modifier_imba_marci_2_buff:IsHidden() 			return false end
function modifier_imba_marci_2_buff:IsPurgable() 		return false end
function modifier_imba_marci_2_buff:IsPurgeException() 	return false end
function modifier_imba_marci_2_buff:DeclareFunctions() return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE} end
function modifier_imba_marci_2_buff:CheckState()
	return {
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,

			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = self:GetParent():HasModifier("modifier_imba_marci_2_jump"),
			}
end
function modifier_imba_marci_2_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.msp*self:GetStackCount()
end
function modifier_imba_marci_2_buff:OnCreated()
	if self:GetAbility()~= nil then
		self.ability = self:GetAbility()
		self.parent = self:GetParent()
		self.max = self.ability:GetSpecialValueFor("jump_max")
		self.msp = self.ability:GetSpecialValueFor("jump_movespeed")
		self.view = self.parent:TG_GetTalentValue("special_bonus_imba_marci_t7")
		if IsServer()  then
			if self:GetParent():TG_HasTalent("special_bonus_imba_marci_t7") then
				self:StartIntervalThink(0.1)
			end
			self:OnRefresh()
		end
	end
end

function modifier_imba_marci_2_buff:OnIntervalThink()
	if IsServer() then
		AddFOWViewer(self.parent:GetTeamNumber(), self.parent:GetAbsOrigin(), self.view, 0.2, false)
	end
end
function modifier_imba_marci_2_buff:OnRefresh()
	if IsServer() then
		self:SetStackCount(math.min(self:GetStackCount() + 1,self.max))
	end
end

--鹰击魔晶buff
modifier_imba_marci_2_shard_buff = class({})
function modifier_imba_marci_2_shard_buff:IsHidden() return true end
function modifier_imba_marci_2_shard_buff:IsPurgable() return false end
function modifier_imba_marci_2_shard_buff:IsPurgeException() return false end




modifier_imba_marci_2_motion_down = class({})

function modifier_imba_marci_2_motion_down:IsDebuff()			return false end
function modifier_imba_marci_2_motion_down:IsHidden() 			return true end
function modifier_imba_marci_2_motion_down:IsPurgable() 		return false end
function modifier_imba_marci_2_motion_down:IsPurgeException() 	return false end
function modifier_imba_marci_2_motion_down:DeclareFunctions() return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION,MODIFIER_EVENT_ON_ORDER} end
--function modifier_imba_marci_2_motion_down:GetOverrideAnimation() return ACT_DOTA_FLAIL end
--function modifier_imba_marci_2_motion_down:GetOverrideAnimation() return  ACT_DOTA_OVERRIDE_ABILITY_2 end
function modifier_imba_marci_2_motion_down:GetEffectName()
	return "particles/units/heroes/hero_tiny/tiny_toss_blur.vpcf"
end
function modifier_imba_marci_2_motion_down:CheckState()
	return {--[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			--[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_TETHERED] = true,
			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
			}
end
function modifier_imba_marci_2_motion_down:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_imba_marci_2_motion_down:IsMotionController() return true end
function modifier_imba_marci_2_motion_down:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end

function modifier_imba_marci_2_motion_down:OnCreated(keys)
	if IsServer() then
		if self:GetAbility()~= nil  then
		
			self.ability = self:GetAbility()
			self.impact_radius = self.ability:GetSpecialValueFor("radius")+self:GetCaster():TG_GetTalentValue("special_bonus_imba_marci_t1")
			self.damage = self.ability:GetSpecialValueFor("damage")
			self.jump = self.ability:GetSpecialValueFor("jump_duration")+self:GetCaster():TG_GetTalentValue("special_bonus_imba_marci_t5")
			self.parent = self:GetParent()
			if keys.tar ~= nil then
				self.tar = EntIndexToHScript(keys.tar)
			end
			--print(tostring(self.tar:GetName()))
			self.duration = keys.duration
			self.pos = Vector(keys.pos_x, keys.pos_y, keys.pos_z)
			self.dis = keys.dis+300
			self.distance = (self.dis/self.duration)*FrameTime()
			self.height = keys.height or self:GetParent():GetAbsOrigin().z+350
			self.down = (self.height-200) / 15 

			--self.parent:StartGestureWithPlaybackRate(ACT_DOTA_OVERRIDE_ABILITY_2,2)
			--self.parent:AddActivityModifier("unleash")
			self.parent:MoveToPosition(self.pos)
			self:OnIntervalThink()
			self:StartIntervalThink(FrameTime())
		end
	end
end



function modifier_imba_marci_2_motion_down:OnIntervalThink()
	local motion_progress = math.min(self:GetElapsedTime() / self:GetDuration(), 1.0)
	local distance = self.distance
	local direction = (self.pos - self:GetParent():GetAbsOrigin()):Normalized()
	direction.z = 0.0
	local next_pos = GetGroundPosition(self.parent:GetAbsOrigin() + direction * distance, nil)
	next_pos.z = self.height - self.down
	self.height = next_pos.z
	--print(tostring(self.height))
	self:GetParent():SetOrigin(next_pos)
end

function modifier_imba_marci_2_motion_down:OnDestroy()
	if IsServer() then
		--self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_2_END)
		EmitSoundOn("Ability.TossImpact", self.parent)
		local has_enemy = false
		FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
		local shard_c = self.parent:FindModifierByName("modifier_imba_marci_2_shard_buff")
		if shard_c then 
			self.parent:RemoveModifierByName("modifier_imba_marci_2_shard_buff")		
			shard_c:GetCaster():RemoveModifierByName("modifier_imba_marci_2_shard")		
		end
		

			local enemies = FindUnitsInRadius( self.parent:GetTeamNumber(), self.parent:GetAbsOrigin(), nil, self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false )
			for _,enemy in pairs( enemies ) do
					--enemy:AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_imba_tiny_avalanche_flags",{duration = 1})
					local damageInfo =
					{
						victim = enemy,
						attacker = self:GetCaster(),
						damage = self.damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
					ApplyDamage( damageInfo )
					has_enemy = true
			end
			
		if has_enemy ~= true then
			if GridNav:IsNearbyTree(self.parent:GetAbsOrigin(),self.impact_radius, true) then
				has_enemy = true
			end
		end
			
			
			local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_epicenter_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(fx, 0, self:GetCaster():GetAbsOrigin())
			ParticleManager:SetParticleControl(fx, 1, Vector(self.impact_radius,1,1))
			ParticleManager:ReleaseParticleIndex(fx)
		
		if has_enemy then		

			local pos = self.parent:GetAbsOrigin()
			pos.z = self.height
			self.parent:AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_imba_marci_2_jump",{duration = self.jump,pos_x = pos.x, pos_y = pos.y, pos_z = pos.z})
			
			self:GetAbility():EndCooldown() 
			self:GetAbility():StartCooldown(0.5) 
			if self.tar ~= nil then
			--print("no nin")
				if IsInTable(self.tar, enemies) then
				--print("intable")
					if self.tar:TriggerStandardTargetSpell(self.ability) then
						return
						else
						self.tar:AddNewModifier(self.parent,self.ability,"modifier_imba_marci_2_shard",{duration = 4})
						self.parent:AddNewModifier(self.tar,self.ability,"modifier_imba_marci_2_shard_buff",{duration = 4})
					end
					
				end 

				
			end
		else
			if not self.parent:HasModifier("modifier_imba_marci_5") then
					self.parent:ClearActivityModifiers()
				else
					self.parent:AddActivityModifier("Unleash")
					self.parent:AddActivityModifier("Unleash")
			end
			self.ability:UseResources(false, false, true)
			self.parent:FadeGesture(ACT_DOTA_RUN)
					
			self.parent:StartGesture(ACT_DOTA_CAST_ABILITY_2_END)	
		end
		
		--[[	
		local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false )
			for _,enemy in pairs( enemies ) do
					--enemy:AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_imba_tiny_avalanche_flags",{duration = 1})
					local damageInfo =
					{
						victim = enemy,
						attacker = self:GetCaster(),
						damage = self.damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
					ApplyDamage( damageInfo )
			end
		if self:GetParent():HasModifier("modifier_imba_tiny_avalanche_flags") then
			local damageInfo =
					{
						victim = self:GetParent(),
						attacker = self:GetCaster(),
						damage = self.damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
					ApplyDamage( damageInfo )
		end
		--小投掷
		if self:GetParent():GetName() == "npc_dota_broodmother_spiderling" then
			local radius = self:GetAbility():GetSpecialValueFor("grab_radius")*math.max(1,self:GetCaster():GetModelScale()*0.8)
			local pos = self:GetCaster():GetAbsOrigin()
			local direction = (pos - self:GetParent():GetAbsOrigin()):Normalized()
			local height = 750
			local distance = math.min((pos - self:GetParent():GetAbsOrigin()):Length2D() + height/2,self:GetAbility():GetSpecialValueFor("toss_dis")+self:GetCaster():GetCastRangeBonus())
			local enemies_tick =  FindUnitsInRadius(self:GetCaster():GetTeamNumber(),
			self:GetParent():GetAbsOrigin(), nil, 300,
			DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,FIND_CLOSEST, false)

				if #enemies_tick >= 1 then
				for _,e in pairs(enemies_tick) do
					if not e:HasModifier("modifier_imba_marci_2_shard") then
						EmitSoundOn("Hero_Tiny.Toss.Target", e)
						self:GetParent():StartGesture(ACT_TINY_TOSS)
						e:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_marci_3_motion",
							{duration = 0.9, pos_x = pos.x, pos_y = pos.y, pos_z = pos.z, dis = distance,height = height ,damage = self.damage,impact_radius = self.impact_radius})
							return
					end
				end
				end
		end]]
	end
end
--鹰击跳跃 
modifier_imba_marci_2_jump = class({})

function modifier_imba_marci_2_jump:IsDebuff()			return false end
function modifier_imba_marci_2_jump:IsHidden() 			return false end
function modifier_imba_marci_2_jump:IsPurgable() 		return false end
function modifier_imba_marci_2_jump:IsPurgeException() 	return false end
function modifier_imba_marci_2_jump:DeclareFunctions() return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION,MODIFIER_EVENT_ON_ORDER} end
--function modifier_imba_marci_2_jump:GetOverrideAnimation() return ACT_DOTA_FLAIL end
function modifier_imba_marci_2_jump:GetOverrideAnimation() return  ACT_DOTA_OVERRIDE_ABILITY_2 end

function modifier_imba_marci_2_jump:GetEffectName()
	return "particles/units/heroes/hero_tiny/tiny_toss_blur.vpcf"
end
function modifier_imba_marci_2_jump:CheckState()
	return {--[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_FROZEN] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			--[MODIFIER_STATE_SILENCED] = true,
			--[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_ATTACK_IMMUNE] = true,
			
			}
end
function modifier_imba_marci_2_jump:IsMotionController() return true end
function modifier_imba_marci_2_jump:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end
function modifier_imba_marci_2_jump:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_imba_marci_2_jump:OnCreated(keys)
	if IsServer() then
		if self:GetAbility()~= nil  then
			self.ability = self:GetAbility()
			--self.impact_radius = self.ability:GetSpecialValueFor("radius")
			--self.damage = self.ability:GetSpecialValueFor("damage")
			self.parent = self:GetParent()
			self.caster = self:GetCaster()
			self.h = self.ability:GetSpecialValueFor("height")+self.caster:TG_GetTalentValue("special_bonus_imba_marci_t3")
			local mod = self.caster:AddNewModifier(self.caster,self.ability,"modifier_imba_marci_2_buff",{duration = self.ability:GetSpecialValueFor("duration")})
			local h = 0
			if mod then
				h = mod:GetStackCount()
			end
			--self.duration = keys.duration
			--self.damage = keys.damage
			self.pos = Vector(keys.pos_x,keys.pos_y,keys.pos_z)
			
			--print(tostring(self.pos))
			self.parent:SetOrigin(self.pos)
			--self.pos = self.parent:GetAbsOrigin()
			self.next_pos_z = nil
			self.height = self.parent:GetAbsOrigin().z + h*self.h +100
			--print(tostring(self.pos))
			
	    local pp =
				{
					EffectName ="particles/econ/items/windrunner/windranger_arcana/windranger_arcana_spell_powershot.vpcf",
					Ability = self.ability,
					vSpawnOrigin =self.caster:GetAbsOrigin(),
					vVelocity =self.caster:GetForwardVector(),
					Source = self.caster,
					bHasFrontalCone = true,
					bReplaceExisting = true,
					iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
					iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
					iUnitTargetType = DOTA_UNIT_TARGET_NONE,
					bProvidesVision = false,
				}
				ProjectileManager:CreateLinearProjectile( pp )
			
			self:OnIntervalThink()
			self:StartIntervalThink(FrameTime())
		end			
	end
end


function modifier_imba_marci_2_jump:OnIntervalThink()
	local motion_progress = math.min(self:GetElapsedTime() / self:GetDuration(), 1.0)

	local next_pos = GetGroundPosition(self.parent:GetAbsOrigin(), nil)

	next_pos.z = next_pos.z - 4 * self.height * motion_progress ^ 2 + 4 * self.height * motion_progress + 100
	self.next_pos_z = next_pos.z
	self:GetParent():SetOrigin(next_pos)
end

function modifier_imba_marci_2_jump:OnDestroy()
	if IsServer() then
		self:StartIntervalThink(-1)

		self.parent:FadeGesture(ACT_DOTA_RUN)
		if not self.parent:HasModifier("modifier_imba_marci_5") then
			self.parent:ClearActivityModifiers()
				else
			self.parent:AddActivityModifier("Unleash")
			self.parent:AddActivityModifier("Unleash")
		end
		EmitSoundOn("Ability.TossImpact", self.parent)
		if self:GetRemainingTime() > 0.03 then
			return
		end
		self.ability:UseResources(false, false, true)
		local shard_c = self.parent:FindModifierByName("modifier_imba_marci_2_shard_buff")
		if shard_c then 
			self.parent:RemoveModifierByName("modifier_imba_marci_2_shard_buff")		
			shard_c:GetCaster():RemoveModifierByName("modifier_imba_marci_2_shard")		
		end
		--FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
		--[[
		local nFXIndex = ParticleManager:CreateParticle( "particles/creatures/ogre/ogre_melee_smash.vpcf", PATTACH_WORLDORIGIN, self.parent )
			ParticleManager:SetParticleControl( nFXIndex, 0, self.parent:GetAbsOrigin() )
			ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.impact_radius, self.impact_radius, self.impact_radius ) )
			ParticleManager:ReleaseParticleIndex( nFXIndex )]]

		--self.parent:AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_imba_marci_2_jump",{duration = 1.5})
		--[[	
		local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false )
			for _,enemy in pairs( enemies ) do
					--enemy:AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_imba_tiny_avalanche_flags",{duration = 1})
					local damageInfo =
					{
						victim = enemy,
						attacker = self:GetCaster(),
						damage = self.damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
					ApplyDamage( damageInfo )
			end
		if self:GetParent():HasModifier("modifier_imba_tiny_avalanche_flags") then
			local damageInfo =
					{
						victim = self:GetParent(),
						attacker = self:GetCaster(),
						damage = self.damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
					ApplyDamage( damageInfo )
		end
		--小投掷
		if self:GetParent():GetName() == "npc_dota_broodmother_spiderling" then
			local radius = self:GetAbility():GetSpecialValueFor("grab_radius")*math.max(1,self:GetCaster():GetModelScale()*0.8)
			local pos = self:GetCaster():GetAbsOrigin()
			local direction = (pos - self:GetParent():GetAbsOrigin()):Normalized()
			local height = 750
			local distance = math.min((pos - self:GetParent():GetAbsOrigin()):Length2D() + height/2,self:GetAbility():GetSpecialValueFor("toss_dis")+self:GetCaster():GetCastRangeBonus())
			local enemies_tick =  FindUnitsInRadius(self:GetCaster():GetTeamNumber(),
			self:GetParent():GetAbsOrigin(), nil, 300,
			DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,FIND_CLOSEST, false)

				if #enemies_tick >= 1 then
				for _,e in pairs(enemies_tick) do
					if not e:HasModifier("modifier_imba_marci_2_shard") then
						EmitSoundOn("Hero_Tiny.Toss.Target", e)
						self:GetParent():StartGesture(ACT_TINY_TOSS)
						e:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_marci_2_motion",
							{duration = 0.9, pos_x = pos.x, pos_y = pos.y, pos_z = pos.z, dis = distance,height = height ,damage = self.damage,impact_radius = self.impact_radius})
							return
					end
				end
				end
		end]]
	end
end
modifier_imba_marci_2_motion = class({})
LinkLuaModifier("modifier_imba_marci_2_jump", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
function modifier_imba_marci_2_motion:IsDebuff()			return false end
function modifier_imba_marci_2_motion:IsHidden() 			return true end
function modifier_imba_marci_2_motion:IsPurgable() 		return false end
function modifier_imba_marci_2_motion:IsPurgeException() 	return false end

--function modifier_imba_marci_2_motion:GetOverrideAnimation() return ACT_DOTA_FLAIL end
--function modifier_imba_marci_2_motion:GetOverrideAnimation() return  ACT_DOTA_OVERRIDE_ABILITY_2 end

function modifier_imba_marci_2_motion:GetEffectName()
	return "particles/units/heroes/hero_tiny/tiny_toss_blur.vpcf"
end
function modifier_imba_marci_2_motion:CheckState()
	return {--[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			--[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_TETHERED] = true,
			[MODIFIER_STATE_COMMAND_RESTRICTED] = true,}
end
function modifier_imba_marci_2_motion:IsMotionController() return true end
function modifier_imba_marci_2_motion:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end
function modifier_imba_marci_2_motion:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_imba_marci_2_motion:OnCreated(keys)
	if IsServer() then
		if self:GetAbility()~= nil  then
		
			self.ability = self:GetAbility()
			self.impact_radius = self.ability:GetSpecialValueFor("radius")+self:GetCaster():TG_GetTalentValue("special_bonus_imba_marci_t1")
			self.damage = self.ability:GetSpecialValueFor("damage")
			self.jump = self:GetAbility():GetSpecialValueFor("jump_duration")+self:GetCaster():TG_GetTalentValue("special_bonus_imba_marci_t5")
			self.parent = self:GetParent()
			--print(self.impact_radius)
			
			self.duration = keys.duration
			self.pos = Vector(keys.pos_x, keys.pos_y, keys.pos_z)
			self.dis = keys.dis+300
			
			local dis_t =(self.dis/self.duration)
			self.distance = dis_t*FrameTime()
			self.height = self.parent:GetAbsOrigin().z+350

			--self.parent:MoveToPosition(self.pos)
			self:OnIntervalThink()
			self:StartIntervalThink(FrameTime())		

		end
	end
end


function modifier_imba_marci_2_motion:OnIntervalThink()
	local motion_progress = math.min(self:GetElapsedTime() / self:GetDuration(), 1.0)
	local distance = self.distance
	local direction = (self.pos - self.parent:GetAbsOrigin()):Normalized()
	direction.z = 0.0
	local next_pos = GetGroundPosition(self.parent:GetAbsOrigin() + direction * distance, nil)
	next_pos.z = next_pos.z - 3 * self.height * motion_progress ^ 2 + 3 * self.height * motion_progress
	self.parent:SetOrigin(next_pos)
end

function modifier_imba_marci_2_motion:OnDestroy()
	if IsServer() then
		local has_enemy = false
		EmitSoundOn("Ability.TossImpact", self.parent)
		FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
	
			
		local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self.parent:GetAbsOrigin(), nil, self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false )
			for _,enemy in pairs( enemies ) do
					--enemy:AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_imba_tiny_avalanche_flags",{duration = 1})
					local damageInfo =
					{
						victim = enemy,
						attacker = self:GetCaster(),
						damage = self.damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
					ApplyDamage( damageInfo )
					has_enemy = true
			end
			
		if has_enemy ~= true then
			if GridNav:IsNearbyTree(self.parent:GetAbsOrigin(),self.impact_radius, true) then
				has_enemy = true
			end
		end
		
		if has_enemy then		
		local pos = self.parent:GetAbsOrigin()
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_epicenter_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(fx, 0, self:GetCaster():GetAbsOrigin())
		ParticleManager:SetParticleControl(fx, 1, Vector(250,1,1))
		ParticleManager:ReleaseParticleIndex(fx)

		self.parent:AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_imba_marci_2_jump",{duration = self.jump,pos_x = pos.x, pos_y = pos.y, pos_z = pos.z})
			self:GetAbility():EndCooldown() 
			self:GetAbility():StartCooldown(0.1) 
		else
			local shard_c = self.parent:FindModifierByName("modifier_imba_marci_2_shard_buff")
			if shard_c then 
				self.parent:RemoveModifierByName("modifier_imba_marci_2_shard_buff")		
				shard_c:GetCaster():RemoveModifierByName("modifier_imba_marci_2_shard")		
			end
			
			if not self.parent:HasModifier("modifier_imba_marci_5") then
				self.parent:ClearActivityModifiers()
				else
				self.parent:AddActivityModifier("Unleash")
				self.parent:AddActivityModifier("Unleash")				
			end
			self.ability:UseResources(false, false, true)
			self.parent:FadeGesture(ACT_DOTA_RUN)
			
			self.parent:StartGesture(ACT_DOTA_CAST_ABILITY_2_END)			
		end
		--[[	
		if self:GetParent():HasModifier("modifier_imba_tiny_avalanche_flags") then
			local damageInfo =
					{
						victim = self:GetParent(),
						attacker = self:GetCaster(),
						damage = self.damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
					ApplyDamage( damageInfo )
		end
		--小投掷
		if self:GetParent():GetName() == "npc_dota_broodmother_spiderling" then
			local radius = self:GetAbility():GetSpecialValueFor("grab_radius")*math.max(1,self:GetCaster():GetModelScale()*0.8)
			local pos = self:GetCaster():GetAbsOrigin()
			local direction = (pos - self:GetParent():GetAbsOrigin()):Normalized()
			local height = 750
			local distance = math.min((pos - self:GetParent():GetAbsOrigin()):Length2D() + height/2,self:GetAbility():GetSpecialValueFor("toss_dis")+self:GetCaster():GetCastRangeBonus())
			local enemies_tick =  FindUnitsInRadius(self:GetCaster():GetTeamNumber(),
			self:GetParent():GetAbsOrigin(), nil, 300,
			DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,FIND_CLOSEST, false)

				if #enemies_tick >= 1 then
				for _,e in pairs(enemies_tick) do
					if not e:HasModifier("modifier_imba_marci_2_shard") then
						EmitSoundOn("Hero_Tiny.Toss.Target", e)
						self:GetParent():StartGesture(ACT_TINY_TOSS)
						e:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_marci_2_motion",
							{duration = 0.9, pos_x = pos.x, pos_y = pos.y, pos_z = pos.z, dis = distance,height = height ,damage = self.damage,impact_radius = self.impact_radius})
							return
					end
				end
				end
		end]]
	end
end
--魔晶抓取
modifier_imba_marci_2_shard = class({})

function modifier_imba_marci_2_shard:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function modifier_imba_marci_2_shard:IsHidden()
	return true
end

function modifier_imba_marci_2_shard:IsPurgable()
	return false
end
function modifier_imba_marci_2_shard:IsPurgeException()
	return false
end
function modifier_imba_marci_2_shard:RemoveOnDeath()
	return true
end
function modifier_imba_marci_2_shard:OnCreated( kv )
	if IsServer() then
		if self:ApplyHorizontalMotionController() == false or self:ApplyVerticalMotionController() == false then
			self:Destroy()
			return
		end

		self.hold_time = kv.hold_time


		self.nProjHandle = -1
		self.flTime = 0.0
		self.flHeight = 0.0

		self.impact_radius = 400
		self:GetParent():StartGesture(ACT_DOTA_DIE)
		self.bDropped = false
		self:StartIntervalThink( 4 )
	end
end

--------------------------------------------------------------------------------

function modifier_imba_marci_2_shard:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_ORDER,
	}
	return funcs
end

--------------------------------------------------------------------------------

function modifier_imba_marci_2_shard:CheckState()
	local state =
	{
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVULNERABLE] = Is_Chinese_TG(self:GetParent(),self:GetCaster()),
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_FROZEN] = true,
	}
	return state
end
function modifier_imba_marci_2_shard:OnOrder(keys)
	if not IsServer() then
		return
	end
	if keys.unit==self:GetParent() and Is_Chinese_TG(self:GetParent(),self:GetCaster())then
		if  keys.order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
			self:Destroy()
		end
	end
end
--------------------------------------------------------------------------------

function modifier_imba_marci_2_shard:OnDestroy()
	if IsServer() then

		RemoveAnimationTranslate(self:GetCaster())
		self:GetParent():RemoveHorizontalMotionController( self )
		self:GetParent():RemoveVerticalMotionController( self )

		self:GetCaster():RemoveModifierByName("modifier_imba_tiny_tree_grab_hero_flag")
	end
end

--------------------------------------------------------------------------------

function modifier_imba_marci_2_shard:OnIntervalThink()
	if IsServer() then
		if self.bDropped == false then
			self.bDropped = true
			self:GetCaster():RemoveModifierByName( "modifier_storegga_grabbed_buff" )

			self.nProjHandle = -2
			self.flTime = 0.5
			self.flHeight = GetGroundHeight( self:GetParent():GetAbsOrigin(), self:GetParent() )

			self:StartIntervalThink( self.flTime )
			return
		else
			local vLocation = GetGroundPosition( self:GetParent():GetAbsOrigin(), self:GetParent() )

			local nFXIndex = ParticleManager:CreateParticle( "particles/creatures/ogre/ogre_melee_smash.vpcf", PATTACH_WORLDORIGIN, self:GetParent() )
			ParticleManager:SetParticleControl( nFXIndex, 0, vLocation )
			ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.impact_radius, self.impact_radius, self.impact_radius ) )
			ParticleManager:ReleaseParticleIndex( nFXIndex )

			EmitSoundOnLocationWithCaster( vLocation, "Ability.TossImpact", self:GetCaster() )
			self:Destroy()
		end
	end
end

--------------------------------------------------------------------------------

function modifier_imba_marci_2_shard:UpdateHorizontalMotion( me, dt )
	if IsServer() then
		local vLocation = me:GetAbsOrigin()
		if self.nProjHandle == -1 then
			local attach = self:GetCaster():ScriptLookupAttachment( "attach_attack2" )
			vLocation = self:GetCaster():GetAttachmentOrigin( attach )
		elseif self.nProjHandle ~= -2 then
			vLocation = ProjectileManager:GetLinearProjectileLocation( self.nProjHandle )
		end
		vLocation.z = 0.0
		me:SetOrigin( vLocation )
	end
end

--------------------------------------------------------------------------------

function modifier_imba_marci_2_shard:UpdateVerticalMotion( me, dt )
	if IsServer() then
		local vMyPos = me:GetOrigin()
		if self.nProjHandle == -1 then
			local attach = self:GetCaster():ScriptLookupAttachment( "attach_attack2" )
			local vLocation = self:GetCaster():GetAttachmentOrigin( attach )
			vMyPos.z = vLocation.z
		else
			local flGroundHeight = GetGroundHeight( vMyPos, me )
			local flHeightChange = dt * self.flTime * self.flHeight * 1.3
			vMyPos.z = math.max( vMyPos.z - flHeightChange, flGroundHeight )
		end
		me:SetOrigin( vMyPos )
	end
end

--------------------------------------------------------------------------------

function modifier_imba_marci_2_shard:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

--------------------------------------------------------------------------------

function modifier_imba_marci_2_shard:OnVerticalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end


function modifier_imba_marci_2_shard:OnDeath( params )
	if IsServer() then
		if params.unit == self:GetCaster() then
			self:Destroy()
		end
	end

	return 0
end

imba_marci_3 = class({})

LinkLuaModifier("modifier_imba_marci_3_motion", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_marci_3_down", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
function imba_marci_3:IsStealable() return false end


function imba_marci_3:CastFilterResultLocation(vLocation)  --缠绕不能释放
	if self:GetCaster():IsRooted() then
		return UF_FAIL_CUSTOM
	end
end

function imba_marci_3:GetCustomCastErrorLocation(vLocation)
	return "dota_hud_error_ability_disabled_by_root"
end

function imba_marci_3:CastFilterResultTarget(target)
	if target ~= self:GetCaster() then
		return UF_FAIL_OBSTRUCTED
	end
end
function imba_marci_3:GetCastRange(target)
	return self:GetSpecialValueFor("range")
end
function imba_marci_3:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function imba_marci_3:OnSpellStart()
	if not IsServer() then return end
	self.caster = self:GetCaster()

	local pos = self:GetCursorPosition()
	local direction = (pos - self.caster:GetAbsOrigin()):Normalized()
		direction.z = 0
	local max_distance = self:GetSpecialValueFor("range")  + self.caster:GetCastRangeBonus()
	local distance = math.min(max_distance, (self.caster:GetAbsOrigin() - pos):Length2D())
	local tralve_duration = 1
	
	if self:GetCaster():HasModifier("modifier_imba_marci_2_jump") then
		local pos_z = self.caster:FindModifierByName("modifier_imba_marci_2_jump").next_pos_z
		self.caster:RemoveModifierByName("modifier_imba_marci_2_jump")
		--print(tostring(self.caster:GetAbsOrigin().z))
		self.caster:AddNewModifier(self.caster, self, "modifier_imba_marci_3_down", {duration = 0.2, height = pos_z+30,direction = direction,dis = distance,pos_x = pos.x, pos_y = pos.y, pos_z = pos_z})
		return
	end
	--self.caster:AddNewModifier(self.caster, self, "imba_marci_3_yidong", {duration = tralve_duration, direction = direction})
	self.caster:AddNewModifier(self.caster, self, "modifier_imba_marci_3_motion", {duration = 0.2, direction = direction,dis = distance,pos_x = pos.x, pos_y = pos.y, pos_z = pos.z})	


end

modifier_imba_marci_3_motion = class({})

function modifier_imba_marci_3_motion:IsDebuff()			return false end
function modifier_imba_marci_3_motion:IsHidden() 			return true end
function modifier_imba_marci_3_motion:IsPurgable() 		return false end
function modifier_imba_marci_3_motion:IsPurgeException() 	return false end
function modifier_imba_marci_3_motion:DeclareFunctions() return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION,MODIFIER_EVENT_ON_ORDER} end
--function modifier_imba_marci_3_motion:GetOverrideAnimation() return ACT_DOTA_FLAIL end
function modifier_imba_marci_3_motion:GetOverrideAnimation() return  ACT_DOTA_OVERRIDE_ABILITY_2 end

function modifier_imba_marci_3_motion:GetEffectName()
	return "particles/units/heroes/hero_tiny/tiny_toss_blur.vpcf"
end
function modifier_imba_marci_3_motion:CheckState()
	return {--[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			--[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_TETHERED] = true,
			[MODIFIER_STATE_COMMAND_RESTRICTED] = true,}
end

function modifier_imba_marci_3_motion:IsMotionController() return true end
function modifier_imba_marci_3_motion:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end
function modifier_imba_marci_3_motion:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_imba_marci_3_motion:OnCreated(keys)
	if IsServer() then
		if self:GetAbility()~= nil  then
		
			self.ability = self:GetAbility()
			self.impact_radius = self.ability:GetSpecialValueFor("radius")
			self.damage = self.ability:GetSpecialValueFor("damage")
			self.stun = self.ability:GetSpecialValueFor("base_stun")
			self.parent = self:GetParent()
			
			self.duration = keys.duration
			self.pos = Vector(keys.pos_x, keys.pos_y, keys.pos_z)
			self.dis = keys.dis+200
			local dis_t =(self.dis/self.duration)
			self.distance = dis_t*FrameTime()
			self.height = keys.height or self.parent:GetAbsOrigin().z+350
			self.dist_a = 0
			self.damageInfo =
					{
						attacker = self:GetCaster(),
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
			self:OnIntervalThink()
			self:StartIntervalThink(FrameTime())
		end
	end
end


function modifier_imba_marci_3_motion:OnIntervalThink()
	local motion_progress = math.min(self:GetElapsedTime() / self:GetDuration(), 1.0)
	local distance = self.distance
	local direction = (self.pos - self.parent:GetAbsOrigin()):Normalized()
	direction.z = 0.0
	local next_pos = GetGroundPosition(self.parent:GetAbsOrigin() + direction * distance, nil)
	next_pos.z = next_pos.z - 4 * self.height * motion_progress ^ 2 + 4 * self.height * motion_progress
	self.parent:SetOrigin(next_pos)
end

function modifier_imba_marci_3_motion:OnDestroy()
	if IsServer() then

		self.parent:StartGesture(ACT_DOTA_CAST_ABILITY_2_END)
		EmitSoundOn("Ability.TossImpact", self.parent)
		--FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
		local shard_c = self.parent:FindModifierByName("modifier_imba_marci_2_shard_buff")
		if shard_c then 
			self.parent:RemoveModifierByName("modifier_imba_marci_2_shard_buff")		
			shard_c:GetCaster():RemoveModifierByName("modifier_imba_marci_2_shard")		
		end
		
		local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(),self.parent:GetAbsOrigin(), nil, self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false )
		for _,enemy in pairs( enemies ) do
				enemy:AddNewModifier(self.parent,self.ability,"modifier_imba_stunned",{duration = self.stun})
				self.damageInfo.victim = enemy
				self.damageInfo.damage = self.damage
				ApplyDamage( self.damageInfo )
				
			end	
		
		local nFXIndex = ParticleManager:CreateParticle( "particles/creatures/ogre/ogre_melee_smash.vpcf", PATTACH_WORLDORIGIN, self.parent )
			ParticleManager:SetParticleControl( nFXIndex, 0, self.parent:GetAbsOrigin() )
			ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.impact_radius, self.impact_radius, self.impact_radius ) )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
		--[[	
		local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false )
			for _,enemy in pairs( enemies ) do
					--enemy:AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_imba_tiny_avalanche_flags",{duration = 1})
					local damageInfo =
					{
						victim = enemy,
						attacker = self:GetCaster(),
						damage = self.damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
					ApplyDamage( damageInfo )
			end
		if self:GetParent():HasModifier("modifier_imba_tiny_avalanche_flags") then
			local damageInfo =
					{
						victim = self:GetParent(),
						attacker = self:GetCaster(),
						damage = self.damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
					ApplyDamage( damageInfo )
		end
		--小投掷
		if self:GetParent():GetName() == "npc_dota_broodmother_spiderling" then
			local radius = self:GetAbility():GetSpecialValueFor("grab_radius")*math.max(1,self:GetCaster():GetModelScale()*0.8)
			local pos = self:GetCaster():GetAbsOrigin()
			local direction = (pos - self:GetParent():GetAbsOrigin()):Normalized()
			local height = 750
			local distance = math.min((pos - self:GetParent():GetAbsOrigin()):Length2D() + height/2,self:GetAbility():GetSpecialValueFor("toss_dis")+self:GetCaster():GetCastRangeBonus())
			local enemies_tick =  FindUnitsInRadius(self:GetCaster():GetTeamNumber(),
			self:GetParent():GetAbsOrigin(), nil, 300,
			DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,FIND_CLOSEST, false)

				if #enemies_tick >= 1 then
				for _,e in pairs(enemies_tick) do
					if not e:HasModifier("modifier_imba_marci_2_shard") then
						EmitSoundOn("Hero_Tiny.Toss.Target", e)
						self:GetParent():StartGesture(ACT_TINY_TOSS)
						e:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_marci_3_motion",
							{duration = 0.9, pos_x = pos.x, pos_y = pos.y, pos_z = pos.z, dis = distance,height = height ,damage = self.damage,impact_radius = self.impact_radius})
							return
					end
				end
				end
		end]]
	end
end

modifier_imba_marci_3_down = class({})

function modifier_imba_marci_3_down:IsDebuff()			return false end
function modifier_imba_marci_3_down:IsHidden() 			return true end
function modifier_imba_marci_3_down:IsPurgable() 		return false end
function modifier_imba_marci_3_down:IsPurgeException() 	return false end
function modifier_imba_marci_3_down:DeclareFunctions() return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION,MODIFIER_EVENT_ON_ORDER} end
--function modifier_imba_marci_3_down:GetOverrideAnimation() return ACT_DOTA_FLAIL end
function modifier_imba_marci_3_down:GetOverrideAnimation() return  ACT_DOTA_OVERRIDE_ABILITY_2 end

function modifier_imba_marci_3_down:GetEffectName()
	return "particles/units/heroes/hero_tiny/tiny_toss_blur.vpcf"
end
function modifier_imba_marci_3_down:CheckState()
	return {--[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			--[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_TETHERED] = true,
			[MODIFIER_STATE_COMMAND_RESTRICTED] = true,}
end
function modifier_imba_marci_3_down:IsMotionController() return true end
function modifier_imba_marci_3_down:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end
function modifier_imba_marci_3_down:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_imba_marci_3_down:OnCreated(keys)
	if IsServer() then
		if self:GetAbility()~= nil  then
			self.ability = self:GetAbility()
			self.impact_radius = self.ability:GetSpecialValueFor("radius")
			self.stun = self.ability:GetSpecialValueFor("base_stun")
			self.parent = self:GetParent()	
			

			self.duration = keys.duration

			self.pos = Vector(keys.pos_x, keys.pos_y, keys.pos_z)
			self.dis = keys.dis+200
			local dis_t =(self.dis/self.duration)
			self.distance = dis_t*FrameTime()
			self.height = keys.height or self.parent:GetAbsOrigin().z+350
			self.height_talent = self.height
			self.height_ex = math.max(math.ceil((self.height-400)/100)*0.3,0)
			self.stun = self.stun + self.height_ex
			self.damage = self.ability:GetSpecialValueFor("damage")*math.max(self.height_ex,1)
			--print(tostring(self.height_ex))
			self.down = self.height / (keys.duration/0.02)
			self.dist_a = 0
			self:OnIntervalThink()
			self:StartIntervalThink(FrameTime())
			self.damageInfo =
					{
						attacker = self:GetCaster(),
						damage_type = DAMAGE_TYPE_MAGICAL,
						ability = self:GetAbility(),
					}
		end
	end
end



function modifier_imba_marci_3_down:OnIntervalThink()
	local motion_progress = math.min(self:GetElapsedTime() / self:GetDuration(), 1.0)
	local distance = self.distance
	local direction = (self.pos - self.parent:GetAbsOrigin()):Normalized()
	direction.z = 0.0
	local next_pos = GetGroundPosition(self.parent:GetAbsOrigin() + direction * distance, nil)
	next_pos.z = self.height - self.down--next_pos.z - 4 * self.height * motion_progress ^ 2 + 4 * self.height * motion_progress
	self.height = next_pos.z
	--print(tostring(self.height))
	self.parent:SetOrigin(next_pos)
end

function modifier_imba_marci_3_down:OnDestroy()
	if IsServer() then
		EmitSoundOn("Ability.TossImpact", self.parent)
		local ab = self.parent:FindAbilityByName("imba_marci_2")
		if ab and ab:GetLevel() > 0 then
			ab:UseResources(false, false, true)
		end
		
		self.parent:StartGesture(ACT_DOTA_CAST_ABILITY_2_END)
		FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
		
		
		local shard_c = self.parent:FindModifierByName("modifier_imba_marci_2_shard_buff")
		local shard_tar = nil
		if shard_c then 
			shard_tar = shard_c:GetCaster()
			self.parent:RemoveModifierByName("modifier_imba_marci_2_shard_buff")					
			shard_c:GetCaster():RemoveModifierByName("modifier_imba_marci_2_shard")		
		end
	
	
	local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(),self.parent:GetAbsOrigin(), nil, self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false )
			for _,enemy in pairs( enemies ) do
				if shard_tar ~= nil then
					if enemy == shard_tar and self.parent:TG_HasTalent("special_bonus_imba_marci_t6") then
						self.damageInfo.victim = enemy
						--print(tostring(self.height_talent))
						self.damageInfo.damage = self.height_talent*self.parent:TG_GetTalentValue("special_bonus_imba_marci_t6")*0.01
						ApplyDamage( self.damageInfo )
					end
				end
				enemy:AddNewModifier(self.parent,self.ability,"modifier_imba_stunned",{duration = self.stun})
				self.damageInfo.victim = enemy
				self.damageInfo.damage = self.damage
				ApplyDamage( self.damageInfo )
				
			end	
	local pfx1 = ParticleManager:CreateParticle( "particles/units/heroes/hero_marci/marci_dispose_land_aoe.vpcf", PATTACH_WORLDORIGIN, self.parent )
	ParticleManager:SetParticleControl( pfx1,0, self.parent:GetAbsOrigin() )
	ParticleManager:SetParticleControl( pfx1,1, Vector(500,500,0) )
	ParticleManager:ReleaseParticleIndex( pfx1 )

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_huskar/huskar_inner_fire_ring_b.vpcf", PATTACH_POINT, self.parent)
	ParticleManager:SetParticleControl(particle, 1, Vector(self.impact_radius, 0, 0))
	ParticleManager:SetParticleControl(particle, 3, self.parent:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(particle)
	
	
	local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_huskar/huskar_inner_fire_rays.vpcf", PATTACH_POINT, self.parent)
	ParticleManager:SetParticleControl(particle2, 1, Vector(self.impact_radius, 0, 0))
	ParticleManager:SetParticleControl(particle2, 3, self.parent:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(particle2)

		
	end
end

--龙拳
imba_marci_1 = class({})

LinkLuaModifier("modifier_imba_marci_1_move", "ting/hero_marci", LUA_MODIFIER_MOTION_BOTH)


function imba_marci_1:IsStealable() return false end



function imba_marci_1:OnSpellStart()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	EmitSoundOn("Hero_Lina.DragonSlave", self.caster)
	self.caster:AddNewModifier(self.caster,self,"modifier_imba_marci_1_move",{duration = 0.1})
	if self.caster:TG_HasTalent("special_bonus_imba_marci_t4") then
		ProjectileManager:ProjectileDodge(self.caster)
	end
	

	
	
end

modifier_imba_marci_1_move = class({})
function modifier_imba_marci_1_move:GetStatusEffectName()
    return "particles/status_fx/status_effect_omnislash.vpcf"
end


function modifier_imba_marci_1_move:IsDebuff() return false end
function modifier_imba_marci_1_move:IsHidden() return true end
function modifier_imba_marci_1_move:IsPurgable() return false end

function modifier_imba_marci_1_move:DeclareFunctions() return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE} end
function modifier_imba_marci_1_move:GetModifierPreAttack_BonusDamage() return self.damage end
function modifier_imba_marci_1_move:GetMotionPriority() 	
	return DOTA_MOTION_CONTROLLER_PRIORITY_LOW
end
function modifier_imba_marci_1_move:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_imba_marci_1_move:OnCreated(params)
	if not IsServer() then return end
	if self:GetAbility() == nil then return end
	
	
	self.caster = self:GetCaster()
	self.parent = self:GetParent()   
	self.ability = self:GetAbility()

	self.distance =self.ability:GetSpecialValueFor("distance")
	self.width =self.ability:GetSpecialValueFor("width")
	self.damage = self.ability:GetSpecialValueFor("damage")
	
	self.pos = self.parent:GetAbsOrigin()
	self.angle = self:GetParent():GetForwardVector() 
	self.force_pos = GetGroundPosition(( self.pos + self.angle * self.distance ), nil)
	
	self.speed = self.distance / self:GetDuration()
	self.parent:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK,3)
	
	if self.parent:HasModifier("modifier_imba_marci_2_jump") then 
		self.force_pos = GetGroundPosition(( self.pos + self.angle * self.distance*2 ), nil)
		self.force_pos.z = self.caster:GetAbsOrigin().z
	end
    local p1 = ParticleManager:CreateParticle("particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_omni_dash.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControlEnt(p1, 0, self.parent, PATTACH_ABSORIGIN, nil, self.parent:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(p1, 0, self.force_pos)
    ParticleManager:SetParticleControl(p1, 1, self.caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(p1, 2, self.force_pos)
	ParticleManager:SetParticleControlForward( p1, 0, self.angle*-1 )
	ParticleManager:SetParticleControlForward( p1, 1, self.angle*-1 )
	ParticleManager:SetParticleControlForward( p1, 2, self.angle*-1 )
    --ParticleManager:SetParticleControl(p1, 2, self.force_pos)
    ParticleManager:ReleaseParticleIndex(p1)
	
	if self:GetParent():HasModifier("modifier_imba_marci_2_jump") then
		self:GetParent():SetOrigin( self.force_pos )
		self:Destroy()
	end
	local enemies = FindUnitsInLine(
			self.caster:GetTeamNumber(),
			self.pos,
			self.force_pos, 
			self.parent,
			self.width, 
			DOTA_UNIT_TARGET_TEAM_ENEMY, 
			DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, 
			DOTA_UNIT_TARGET_FLAG_NONE+DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
	
			for _,enemy in pairs( enemies ) do
				self.caster:PerformAttack(enemy, true, true, true, false, false, false, true)	
			end

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end
	
end

function modifier_imba_marci_1_move:OnDestroy()
	if not IsServer() then return end


	self:GetParent():RemoveHorizontalMotionController( self )
	--self:GetParent():FadeGesture(ACT_DOTA_ATTACK)
	--ResolveNPCPositions(self:GetParent():GetAbsOrigin(), 128)

end

function modifier_imba_marci_1_move:UpdateHorizontalMotion( me, dt )
	if not IsServer() then return end
	local distance = (self.force_pos - me:GetAbsOrigin()):Normalized()
	local next_pos = me:GetAbsOrigin() + distance * self.speed * dt
	me:SetOrigin( next_pos )
	GridNav:DestroyTreesAroundPoint(next_pos, 80, false)
end

function modifier_imba_marci_1_move:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function modifier_imba_marci_1_move:CheckState()
	if Is_Chinese_TG(self:GetParent(),self:GetCaster()) then
		local state =
		{
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		}
	return state
	end
	return
end

--玛西被动

imba_marci_4 = class({})  

LinkLuaModifier("modifier_imba_marci_4", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
function imba_marci_4:GetIntrinsicModifierName() return "modifier_imba_marci_4" end
function imba_marci_4:Set_InitialUpgrade() 			
    return {LV=1} 
end


modifier_imba_marci_4 = class({})
function modifier_imba_marci_4:IsDebuff() return false end
function modifier_imba_marci_4:IsPurgable() return false end
function modifier_imba_marci_4:IsPurgeException() return false end
function modifier_imba_marci_4:RemoveOnDeath() return false end
function modifier_imba_marci_4:IsHidden() return true end
function modifier_imba_marci_4:DeclareFunctions() 
    return {
        MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
    } 
end
function modifier_imba_marci_4:CheckState()
	return
		{
			[MODIFIER_STATE_SILENCED] = false,
		}
end

function modifier_imba_marci_4:GetModifierTurnRate_Percentage() 
    return 2000
end
function modifier_imba_marci_4:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA  end


--猛虎内劲破
imba_marci_5 = class({})
LinkLuaModifier("modifier_imba_marci_5", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_marci_5_pa", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_marci_5_re", "ting/hero_marci", LUA_MODIFIER_MOTION_NONE)

function imba_marci_5:GetIntrinsicModifierName()
	return "modifier_imba_marci_5_pa"
end

function imba_marci_5:OnSpellStart()
	local caster = self:GetCaster()
	EmitSoundOn("Hero_Marci.Unleash.Cast", caster)
	--caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_1)
	
	

	
	caster:AddActivityModifier("Unleash")
	local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_marci/marci_unleash_cast_rings.vpcf", PATTACH_WORLDORIGIN, caster )
	ParticleManager:SetParticleControl( nFXIndex, 0, caster:GetAbsOrigin() )
	--ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.impact_radius, self.impact_radius, self.impact_radius ) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )

	caster:AddNewModifier(caster, self, "modifier_imba_marci_5", {duration = self:GetSpecialValueFor("duration")})
end

modifier_imba_marci_5 = class({})
function modifier_imba_marci_5:IsDebuff()			return false end
function modifier_imba_marci_5:IsHidden() 			return false end
function modifier_imba_marci_5:IsPurgable() 		return false end
function modifier_imba_marci_5:IsPurgeException() 	return false end
function modifier_imba_marci_5:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function modifier_imba_marci_5:DeclareFunctions() return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE} end
function modifier_imba_marci_5:GetStatusEffectName()	return "particles/units/heroes/hero_marci/marci_unleash_buff.vpcf" end

function modifier_imba_marci_5:GetModifierAttackSpeedBonus_Constant()  
	return self.asp 
end
function modifier_imba_marci_5:GetModifierPreAttack_CriticalStrike(keys)
	if IsServer() and keys.attacker == self:GetParent() and not keys.target:IsBuilding() and not keys.target:IsOther() then
			if PseudoRandom:RollPseudoRandom(self.ability, self.chance) then
				return self.crit		
			end
	end
end

function modifier_imba_marci_5:OnCreated()
	if  self:GetAbility()~= nil then
		self.ability = self:GetAbility()
		self.asp = self.ability:GetSpecialValueFor("asp")+self:GetParent():TG_GetTalentValue("special_bonus_imba_marci_t2")
		self.chance = self.ability:GetSpecialValueFor("chance")
		self.crit = self.ability:GetSpecialValueFor("crit")
		if IsServer() then
			self:GetParent():AddActivityModifier("unleash")
		end
	end

end	
function modifier_imba_marci_5:OnDestroy()
	if not IsServer() then return end
	self:GetParent():ClearActivityModifiers()
end

modifier_imba_marci_5_pa = class({})
function modifier_imba_marci_5_pa:IsPurgable() return false end
function modifier_imba_marci_5_pa:IsPurgeException() return false end
function modifier_imba_marci_5_pa:IsHidden()
	return true
end
function modifier_imba_marci_5_pa:DeclareFunctions()
	return {

			MODIFIER_EVENT_ON_ATTACK_LANDED,
			}
end


function modifier_imba_marci_5_pa:OnAttackLanded(keys)
	if IsServer() then

		if keys.attacker == self:GetParent() and keys.target then
			if keys.damage > self:GetParent():GetAverageTrueAttackDamage(self:GetParent()) * 1.65 then 
				local ability = self:GetAbility()
				local radius = ability:GetSpecialValueFor("radius")
				local damage_aoe = ability:GetSpecialValueFor("aoe_damage")
				local re_du = ability:GetSpecialValueFor("re_du") - keys.attacker:TG_GetTalentValue("special_bonus_imba_marci_t8")
				local hp_re = ability:GetSpecialValueFor("heal")
				local health = keys.attacker:GetMaxHealth()*hp_re*0.01
				
				--暴击回血
				keys.attacker:Heal(health, keys.attacker)	
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, keys.attacker, health, nil)

				--大招buff 
				if  keys.attacker:HasModifier("modifier_imba_marci_5") then
				
					EmitSoundOn("Hero_Marci.Unleash.Charged.3d", keys.attacker)
					EmitSoundOn("Hero_Marci.Unleash.Charged", keys.attacker)
					if not keys.attacker:HasModifier("modifier_imba_marci_5_re") then --暴击延迟刷新
						keys.attacker:AddNewModifier(keys.attacker,ability,"modifier_imba_marci_5_re",{duration = re_du})
					end
					
					local f_angle = keys.attacker:GetForwardVector() 
					local r_angle = keys.attacker:GetRightVector()
					local u_angle = keys.attacker:GetUpVector()
							

					local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_marci/marci_unleash_attack.vpcf", PATTACH_ABSORIGIN, keys.target)
						ParticleManager:SetParticleControl(particle, 0, keys.attacker:GetAbsOrigin())
						ParticleManager:SetParticleControl(particle, 1, keys.target:GetAbsOrigin())
						ParticleManager:SetParticleControl(particle, 2, keys.target:GetAbsOrigin())	
						ParticleManager:SetParticleControlOrientation(particle, 0, f_angle, r_angle, u_angle)
						ParticleManager:SetParticleControlOrientation(particle, 1, f_angle, r_angle, u_angle)
						ParticleManager:SetParticleControlOrientation(particle, 2, f_angle, r_angle, u_angle)
						ParticleManager:ReleaseParticleIndex(particle)
					
					if keys.attacker:HasScepter() then --a杖
					
						local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_marci/marci_unleash_pulse.vpcf", PATTACH_POINT, keys.target)
						ParticleManager:SetParticleControl(particle2, 1, Vector(radius, radius, 0))
						ParticleManager:SetParticleControl(particle2, 0, keys.target:GetAbsOrigin())
						ParticleManager:ReleaseParticleIndex(particle2)
						
						local enemies = FindUnitsInRadius( keys.attacker:GetTeamNumber(), keys.attacker:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false )
						for _,enemy in pairs( enemies ) do
					--enemy:AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_imba_tiny_avalanche_flags",{duration = 1})
							local damageInfo =
							{
								victim = enemy,
								attacker = keys.attacker,
								damage = keys.damage*damage_aoe*0.01,
								damage_type = DAMAGE_TYPE_MAGICAL,
								ability = ability,
							}
						ApplyDamage( damageInfo )
					
						end	
					end
				end

		


			end
	
			
		end
	end
end


modifier_imba_marci_5_re = class({})
function modifier_imba_marci_5_re:IsDebuff() return false end
function modifier_imba_marci_5_re:IsPurgable() return false end
function modifier_imba_marci_5_re:IsPurgeException() return false end
function modifier_imba_marci_5_re:RemoveOnDeath() return false end
function modifier_imba_marci_5_re:IsHidden() return false end
function modifier_imba_marci_5_re:OnDestroy()
	if IsServer() then
		local ability = self:GetParent():FindAbilityByName("imba_marci_1")
		if ability ~= nil then
			if ability:GetLevel() > 0 then
				
				ability:EndCooldown()

			end
		end
	end
end


--particles/units/heroes/hero_marci/marci_unleash_buff.vpcf