
modifier_talent_cd=class({})

function modifier_talent_cd:IsHidden()
	return true
end

function modifier_talent_cd:IsPurgable()
	return false
end

function modifier_talent_cd:IsPurgeException()
	return false
end

function modifier_talent_cd:RemoveOnDeath()
	return false
end

function modifier_talent_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_talent_cd:IsPermanent()
	return true
end

function modifier_talent_cd:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING,
    }
end

function modifier_talent_cd:GetModifierPercentageCooldownStacking()
	return self.value
end

function modifier_talent_cd:OnCreated(tg)
	self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
