
modifier_talent_castrange=class({})
function modifier_talent_castrange:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_talent_castrange:IsHidden()
	return true
end

function modifier_talent_castrange:IsPurgable()
	return false
end

function modifier_talent_castrange:IsPurgeException()
	return false
end

function modifier_talent_castrange:RemoveOnDeath()
	return false
end

function modifier_talent_castrange:IsPermanent()
	return true
end

function modifier_talent_castrange:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
    }
end

function modifier_talent_castrange:GetModifierCastRangeBonusStacking()
	return self.value
end

function modifier_talent_castrange:OnCreated(tg)
    self.value = self:GetParent():TG_GetTalentValue(self:GetAbility():GetName())
end
