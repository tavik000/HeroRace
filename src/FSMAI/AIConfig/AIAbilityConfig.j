library AIAbilityConfig
    globals
        hashtable AbilityDataTable
    endglobals

    function InitAbilityData takes nothing returns nothing
        local integer BASE_COOLDOWN_KEY = 0
        local integer CAST_RANGE_KEY = 1
        local integer EFFECTIVE_RADIUS_KEY = 2
        local integer CAST_TYPE_KEY = 3
        local integer FIND_TARGET_TYPE_KEY = 4
        local integer IS_PASSIVE_KEY = 5
        local integer REQUIRED_CAST_TIME_KEY = 6
        local integer MANA_COST_KEY = 7
        local integer IS_IGNORE_MAGIC_IMMUNE_KEY = 8
        local integer MUST_HAVE_BUFF_CODE_WHEN_FOLLOWING_KEY = 9
        local integer SHOULD_CHECK_OTHER_UNIT_BLOCKING_TARGET_UNIT_KEY = 10
        local integer MIN_TARGET_DISTANCE_KEY = 11
        local integer FOLLOW_TARGET_DURATION_KEY = 12
        local integer BASE_PREDICT_OFFSET_KEY = 13
        local integer BASE_PREDICT_DELAY_KEY = 14
        local integer PROJECTILE_SPEED_KEY = 15
        local integer currentAbilityId = 0
        
        set ItemDataTable = InitHashtable()
    
        set currentAbilityId = 'spsh' // SpellShieldAmulet
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(AbilityDataTable, currentAbilityId, IS_PASSIVE_KEY, true)
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 0)
        call SaveBoolean(AbilityDataTable, currentAbilityId, IS_IGNORE_MAGIC_IMMUNE_KEY, false)
        call SaveInteger(AbilityDataTable, currentAbilityId, MUST_HAVE_BUFF_CODE_WHEN_FOLLOWING_KEY, 0)
        call SaveBoolean(AbilityDataTable, currentAbilityId, SHOULD_CHECK_OTHER_UNIT_BLOCKING_TARGET_UNIT_KEY, false)
        call SaveReal(AbilityDataTable, currentAbilityId, MIN_TARGET_DISTANCE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, FOLLOW_TARGET_DURATION_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_OFFSET_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_DELAY_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, PROJECTILE_SPEED_KEY, 0.0)
    
        // Add more ability...
    endfunction

    function GetAbilityBaseCooldown takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 0)
    endfunction

    function GetAbilityCastRange takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 1)
    endfunction

    function GetAbilityEffectiveRadius takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 2)
    endfunction

    function GetAbilityCastType takes integer abilityId returns integer
        return LoadInteger(AbilityDataTable, abilityId, 3)
    endfunction

    function GetAbilityFindTargetType takes integer abilityId returns integer
        return LoadInteger(AbilityDataTable, abilityId, 4)
    endfunction

    function GetAbilityIsPassive takes integer abilityId returns boolean
        return LoadBoolean(AbilityDataTable, abilityId, 5)
    endfunction

    function GetAbilityRequiredCastTime takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 6)
    endfunction

    function GetAbilityManaCost takes integer abilityId returns integer
        return LoadInteger(AbilityDataTable, abilityId, 7)
    endfunction

    function GetAbilityIsIgnoreMagicImmune takes integer abilityId returns boolean
        return LoadBoolean(AbilityDataTable, abilityId, 8)
    endfunction

    function GetAbilityMustHaveBuffCodeWhenFollowing takes integer abilityId returns integer
        return LoadInteger(AbilityDataTable, abilityId, 9)
    endfunction

    function GetAbilityShouldCheckOtherUnitBlockingTargetUnit takes integer abilityId returns boolean
        return LoadBoolean(AbilityDataTable, abilityId, 10)
    endfunction

    function GetAbilityMinTargetDistance takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 11)
    endfunction

    function GetAbilityFollowTargetDuration takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 12)
    endfunction

    function GetAbilityBasePredictOffset takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 13)
    endfunction

    function GetAbilityBasePredictDelay takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 14)
    endfunction

    function GetAbilityProjectileSpeed takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 15)
    endfunction

endlibrary