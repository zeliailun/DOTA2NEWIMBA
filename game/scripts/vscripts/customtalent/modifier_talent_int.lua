
modifier_talent_int=class({})
function modifier_talent_int:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_talent_int:IsHidden()
	return true
end

function modifier_talent_int:IsPurgable()
	return false
end

function modifier_talent_int:IsPurgeException()
	return false
end

function modifier_talent_int:RemoveOnDeath()
	return false
end

function modifier_talent_int:IsPermanent()
	return true
end

function modifier_talent_int:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    }
end

function modifier_talent_int:GetModifierBonusStats_Intellect()
	return self.value
end

function modifier_talent_int:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
