local npcBot = GetBot();
local	ability1 = npcBot:GetAbilityByName( "storm_bolt" );
local	ability2 = npcBot:GetAbilityByName( "great_cleave" );
local	ability3 = npcBot:GetAbilityByName( "warcry" );
local	ability4 = npcBot:GetAbilityByName( "gods_strength" );

local ability1Desire = 0;
local ability2Desire = 0;
local ability3Desire = 0;
local ability4Desire = 0;
local ability1tar = nil;
local ability2loc = nil;
function AbilityUsageThink()

	if ( npcBot:IsUsingAbility() ) then return end;

	ability1Desire, ability1tar = GetAB1Desire();
	ability2Desire, ability2loc = GetAB2Desire();
	ability3Desire = GetAB3Desire();
	ability4Desire = GetAB4Desire();

	if ability1Desire > 0 and ability1tar~=nil then
		npcBot:Action_UseAbilityOnEntity( ability1, ability1tar );
		return;
	end
	if ability2Desire > 0 and ability2loc~=nil then
		npcBot:Action_UseAbilityOnLocation( ability2, ability2loc );
		return;
	end

	if ability3Desire > 0  then
		npcBot:Action_UseAbility( ability3);
		return;
	end

	if ability4Desire > 0  then
		npcBot:Action_UseAbility( ability4);
		return;
	end

end

----------------------------------------------------------------------------------------------------

function CanCastAbility1( npcTarget )
	return npcTarget:CanBeSeen()  and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

----------------------------------------------------------------------------------------------------

function GetAB1Desire()

	if ( not ability1:IsFullyCastable() ) then
		return BOT_ACTION_DESIRE_NONE, 0;
	end

	if ( not ability1:GetAutoCastState() ) then
		ability1:ToggleAutoCast()
      end

	local CastRange = ability1:GetCastRange();
	local npcTarget = npcBot:GetTarget();
	local modeBot=npcBot:GetActiveMode()
	local enemys = npcBot:GetNearbyHeroes(CastRange+300,true,BOT_MODE_NONE)

	if ( modeBot == BOT_MODE_RETREAT  )
	then
		for _,npcEnemy in pairs( enemys )
		do
			if ( npcBot:WasRecentlyDamagedByHero( npcEnemy, 7 ) )
			then
				if ( npcEnemy ~= nil and CanCastAbility1( npcEnemy ))
				then
					ability1:ToggleAutoCast()
					return BOT_ACTION_DESIRE_HIGH, npcEnemy;
				end
			end
		end
	end


	if ( modeBot == BOT_MODE_FARM )
	then
		local units=npcBot:GetNearbyHeroes(CastRange,true,BOT_MODE_NONE)
		if ( #units >= 3  )
		then
			local tar=units[RandomInt(1,  #units)]
			if ( tar ~= nil and CanCastAbility1( tar ) )
			then
				return BOT_ACTION_DESIRE_HIGH,tar ;
			else
				return BOT_ACTION_DESIRE_NONE ,0 ;
			end
		end
	end

	if ( npcBot:GetActiveMode() == BOT_MODE_ROAM or
		 npcBot:GetActiveMode() == BOT_MODE_TEAM_ROAM or
		 npcBot:GetActiveMode() == BOT_MODE_DEFEND_ALLY )
	then
		if ( npcTarget ~= nil and CanCastAbility1( npcTarget ) )
		then
			return BOT_ACTION_DESIRE_VERYHIGH, npcTarget;
		end
	end

	if ( npcTarget ~= nil and CanCastAbility1( npcTarget ) )
	then
		return BOT_ACTION_DESIRE_HIGH , npcTarget;
	end


	return BOT_ACTION_DESIRE_NONE, 0;

end



----------------------------------------------------------------------------------------------------


function GetAB2Desire()
	if ( not ability2:IsFullyCastable() ) then
		return BOT_ACTION_DESIRE_NONE, 0;
	end
	local modeBot=npcBot:GetActiveMode()
	local units=npcBot:GetNearbyHeroes(1600,true,BOT_MODE_NONE )

	if (
		modeBot == BOT_MODE_ATTACK or
		modeBot == BOT_MODE_ROSHAN or
		modeBot == BOT_MODE_DEFEND_ALLY or
		modeBot == BOT_MODE_TEAM_ROAM or
		modeBot == BOT_MODE_PUSH_TOWER_TOP or
		modeBot == BOT_MODE_PUSH_TOWER_MID or
		modeBot == BOT_MODE_PUSH_TOWER_BOT
		)
	then
		return BOT_ACTION_DESIRE_ABSOLUTE ,npcBot:GetLocation();
	end

	if ( #units>=1  )
	then
		return BOT_ACTION_DESIRE_ABSOLUTE , npcBot:GetLocation();
	end

	return BOT_ACTION_DESIRE_NONE, 0;
end


function GetAB3Desire()
	if ( not ability3:IsFullyCastable() ) then
		return BOT_ACTION_DESIRE_NONE, 0;
	end
	local modeBot=npcBot:GetActiveMode()
	if  (npcBot:IsSilenced() or npcBot:IsRooted () or npcBot:IsStunned () or   npcBot:HasModifier("modifier_item_heavens_halberd_v2_debuff")) then
		return BOT_ACTION_DESIRE_ABSOLUTE ;
	end

	if npcBot:WasRecentlyDamagedByAnyHero (0.5)  then
		return BOT_ACTION_DESIRE_ABSOLUTE ;
	end

		if (
		modeBot == BOT_MODE_ATTACK or
		modeBot == BOT_MODE_ROSHAN or
		modeBot == BOT_MODE_DEFEND_ALLY or
		modeBot == BOT_MODE_TEAM_ROAM or
		modeBot == BOT_MODE_PUSH_TOWER_TOP or
		modeBot == BOT_MODE_PUSH_TOWER_MID or
		modeBot == BOT_MODE_PUSH_TOWER_BOT
		)
	then
		return BOT_ACTION_DESIRE_ABSOLUTE;
	end

	return BOT_ACTION_DESIRE_NONE;
end

function GetAB4Desire()
	if ( not ability4:IsFullyCastable() ) then
		return BOT_ACTION_DESIRE_NONE, 0;
	end
	local modeBot=npcBot:GetActiveMode()
	if (
		modeBot == BOT_MODE_ATTACK or
		modeBot == BOT_MODE_ROSHAN or
		modeBot == BOT_MODE_DEFEND_ALLY or
		modeBot == BOT_MODE_TEAM_ROAM or
		modeBot == BOT_MODE_PUSH_TOWER_TOP or
		modeBot == BOT_MODE_PUSH_TOWER_MID or
		modeBot == BOT_MODE_PUSH_TOWER_BOT
		)
	then
		return BOT_ACTION_DESIRE_ABSOLUTE;
	end

	return BOT_ACTION_DESIRE_NONE;
end
