item_hand_of_god=class({})

LinkLuaModifier("modifier_item_hand_of_god_pa", "items/item_hand_of_god.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_hand_of_god_buff", "items/item_hand_of_god.lua", LUA_MODIFIER_MOTION_NONE)
function item_hand_of_god:GetIntrinsicModifierName() 
    return "modifier_item_hand_of_god_pa" 
end

function item_hand_of_god:OnSpellStart()
	local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local target_pos = target:GetAbsOrigin()
    local gold =self:GetSpecialValueFor("gold")
        caster:EmitSound( "DOTA_Item.Hand_Of_Midas" )
        local pfx= ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN,target)
        ParticleManager:SetParticleControl(pfx, 0, target_pos)
        ParticleManager:SetParticleControl(pfx, 1, target_pos)
        ParticleManager:ReleaseParticleIndex( pfx )
        target:ForceKill(false)
        caster:ModifyGold( gold , true, DOTA_ModifyGold_Unspecified )
        caster:AddExperience( target:GetDeathXP()*self:GetSpecialValueFor("xp") , DOTA_ModifyXP_Unspecified, false, false )
        SendOverheadEventMessage(caster, OVERHEAD_ALERT_GOLD, caster,gold, caster)
        caster:AddNewModifier(caster, self, "modifier_item_hand_of_god_buff", {duration=50})  
end

modifier_item_hand_of_god_pa=class({})

function modifier_item_hand_of_god_pa:IsHidden() 			
    return true 
end

function modifier_item_hand_of_god_pa:IsPurgable() 			
    return false 
end

function modifier_item_hand_of_god_pa:IsPurgeException() 	
    return false 
end

function modifier_item_hand_of_god_pa:DeclareFunctions() 
    return 
    {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    } 
end

function modifier_item_hand_of_god_pa:GetModifierAttackSpeedBonus_Constant()
    if  self:GetAbility() then 
        return self:GetAbility():GetSpecialValueFor("attsp") 
    end
    return 0
end

modifier_item_hand_of_god_buff=class({})

function modifier_item_hand_of_god_buff:IsHidden() 			
    return true 
end

function modifier_item_hand_of_god_buff:IsPurgable() 			
    return false 
end

function modifier_item_hand_of_god_buff:IsPurgeException() 	
    return false 
end