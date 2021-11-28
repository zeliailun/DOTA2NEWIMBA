
modifier_talent_attackrange=class({})
function modifier_talent_attackrange:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_talent_attackrange:IsHidden()
	return true
end

function modifier_talent_attackrange:IsPurgable()
	return false
end

function modifier_talent_attackrange:IsPurgeException()
	return false
end

function modifier_talent_attackrange:RemoveOnDeath()
	return false
end

function modifier_talent_attackrange:IsPermanent()
	return true
end

function modifier_talent_attackrange:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    }
end

function modifier_talent_attackrange:GetModifierAttackRangeBonus()
	return self.value
end

function modifier_talent_attackrange:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
