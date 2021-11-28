
modifier_talent_agi=class({})

function modifier_talent_agi:IsHidden()
	return true
end

function modifier_talent_agi:IsPurgable()
	return false
end

function modifier_talent_agi:IsPurgeException()
	return false
end

function modifier_talent_agi:RemoveOnDeath()
	return false
end

function modifier_talent_agi:IsPermanent()
	return true
end

function modifier_talent_agi:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_talent_agi:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    }
end

function modifier_talent_agi:GetModifierBonusStats_Agility()
	return self.value
end

function modifier_talent_agi:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
