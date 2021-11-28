
modifier_talent_str=class({})
function modifier_talent_str:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_talent_str:IsHidden()
	return true
end

function modifier_talent_str:IsPurgable()
	return false
end

function modifier_talent_str:IsPurgeException()
	return false
end

function modifier_talent_str:RemoveOnDeath()
	return false
end

function modifier_talent_str:IsPermanent()
	return true
end

function modifier_talent_str:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    }
end

function modifier_talent_str:GetModifierBonusStats_Strength()
	return self.value
end

function modifier_talent_str:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
