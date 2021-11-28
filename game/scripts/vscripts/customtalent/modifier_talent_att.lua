
modifier_talent_att=class({})
function modifier_talent_att:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_talent_att:IsHidden()
	return true
end

function modifier_talent_att:IsPurgable()
	return false
end

function modifier_talent_att:IsPurgeException()
	return false
end

function modifier_talent_att:RemoveOnDeath()
	return false
end

function modifier_talent_att:IsPermanent()
	return true
end

function modifier_talent_att:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_talent_att:GetModifierPreAttack_BonusDamage()
	return self.value
end

function modifier_talent_att:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
