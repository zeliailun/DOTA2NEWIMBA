
modifier_talent_all=class({})

function modifier_talent_all:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_talent_all:IsHidden()
	return true
end

function modifier_talent_all:IsPurgable()
	return false
end

function modifier_talent_all:IsPurgeException()
	return false
end

function modifier_talent_all:RemoveOnDeath()
	return false
end

function modifier_talent_all:IsPermanent()
	return true
end

function modifier_talent_all:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    }
end

function modifier_talent_all:GetModifierBonusStats_Agility()
	return self.value
end
function modifier_talent_all:GetModifierBonusStats_Intellect()
	return self.value
end
function modifier_talent_all:GetModifierBonusStats_Strength()
	return self.value
end
function modifier_talent_all:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
