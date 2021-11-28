
modifier_talent_msp=class({})
function modifier_talent_msp:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_talent_msp:IsHidden()
	return true
end

function modifier_talent_msp:IsPurgable()
	return false
end

function modifier_talent_msp:IsPurgeException()
	return false
end

function modifier_talent_msp:RemoveOnDeath()
	return false
end

function modifier_talent_msp:IsPermanent()
	return true
end

function modifier_talent_msp:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    }
end

function modifier_talent_msp:GetModifierMoveSpeedBonus_Constant()
	return self.value
end

function modifier_talent_msp:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
