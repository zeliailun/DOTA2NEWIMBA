
item_spell_amp_potion = class({})
LinkLuaModifier( "modifier_item_spell_amp_potion", "items/item_spell_amp_potion.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_spell_amp_potion:Precache( context )
	PrecacheResource( "particle", "particles/generic_gameplay/spell_amp_potion_owner.vpcf", context )
end

--------------------------------------------------------------------------------

function item_spell_amp_potion:OnSpellStart()
	if IsServer() then
		local kv =
		{
			duration = self:GetSpecialValueFor( "buff_duration" ),
		}

		self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_item_spell_amp_potion", kv )

		EmitSoundOn( "SpellAmpPotion.Activate", self:GetCaster() )

		self:SpendCharge()
	end
end


modifier_item_spell_amp_potion = class({})

function modifier_item_spell_amp_potion:RemoveOnDeath()
	return false
end

--------------------------------------------------------------------------------

function modifier_item_spell_amp_potion:GetEffectName()
	return "particles/generic_gameplay/spell_amp_potion_owner.vpcf"
end

--------------------------------------------------------------------------------

function modifier_item_spell_amp_potion:GetTexture()
	return "item_spell_amp_potion"
end

--------------------------------------------------------------------------------

function modifier_item_spell_amp_potion:OnCreated( kv )
	if not self:GetAbility() then
		return
	end
	self.spell_amp_bonus_pct = self:GetAbility():GetSpecialValueFor( "spell_amp_bonus_pct" )
end

--------------------------------------------------------------------------------

function modifier_item_spell_amp_potion:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE_UNIQUE
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_item_spell_amp_potion:GetModifierSpellAmplify_PercentageUnique( params )
	if self:GetParent():IsIllusion() then
		return 0
	end

	return self.spell_amp_bonus_pct
end

--------------------------------------------------------------------------------
