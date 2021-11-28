item_rd_book=class({})

function item_rd_book:OnSpellStart()
      local caster=self:GetCaster()
      if caster.Random_Skill then
                  caster:EmitSound("DOTA_Item.Tango.Activate")
                  local name=caster.Random_Skill:GetName()
                  local lv=caster.Random_Skill:GetLevel()
                  local modifier_count = caster:GetModifierCount()
                  caster:RemoveAbility(name)
                  if modifier_count>0 then
                        for i = 0, modifier_count do
                              local modifier_name = caster:GetModifierNameByIndex(i)
                              if modifier_name~=nil then
                                    local mod=caster:FindModifierByName(modifier_name)
                                    if mod and mod:GetAbility()==caster.Random_Skill then
                                          caster:RemoveModifierByName(modifier_name)
                                    end
                              end
                        end
                  end
                  local ab=caster:AddAbility(TG_Ability_Get(caster))
                  ab:SetLevel(lv)
                  caster.Random_Skill=ab
                  CDOTA_PlayerResource.RD_SK[caster:GetPlayerOwnerID()]=ab:GetName()
		      CustomNetTables:SetTableValue("rd_skills", "RDSK", CDOTA_PlayerResource.RD_SK)
      end
      self:SpendCharge()
end