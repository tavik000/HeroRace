library AIAbilityConfig
    globals
        hashtable AbilityDataTable
    endglobals

    function InitAbilityConfig takes nothing returns nothing
        local integer BASE_COOLDOWN_KEY = 0
        local integer ORDER_STRING_KEY = 1
        local integer CAST_RANGE_KEY = 2
        local integer EFFECTIVE_RADIUS_KEY = 3
        local integer CAST_TYPE_KEY = 4
        local integer FIND_TARGET_TYPE_KEY = 5
        local integer IS_PASSIVE_KEY = 6
        local integer REQUIRED_CAST_TIME_KEY = 7
        local integer MANA_COST_KEY = 8
        local integer IS_IGNORE_MAGIC_IMMUNE_KEY = 9
        local integer MUST_HAVE_BUFF_CODE_WHEN_FOLLOWING_KEY = 10
        local integer SHOULD_CHECK_OTHER_UNIT_BLOCKING_TARGET_UNIT_KEY = 11
        local integer MIN_TARGET_DISTANCE_KEY = 12
        local integer FOLLOW_TARGET_DURATION_KEY = 13
        local integer BASE_PREDICT_OFFSET_KEY = 14
        local integer BASE_PREDICT_DELAY_KEY = 15
        local integer PROJECTILE_SPEED_KEY = 16
        local integer COMBO_INDEX_KEY = 17
        local integer EXPECTED_DAMAGE_KEY = 18
        local integer currentAbilityId = 0
        
        set AbilityDataTable = InitHashtable()
    
        // template
        // set currentAbilityId = 'spsh' // SpellShieldAmulet
        // call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 0.0)
        // call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "banish")
        // call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)  
        // call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        // call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_NONE)
        // call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        // call SaveBoolean(AbilityDataTable, currentAbilityId, IS_PASSIVE_KEY, true)
        // call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.0)
        // call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 0)
        // call SaveBoolean(AbilityDataTable, currentAbilityId, IS_IGNORE_MAGIC_IMMUNE_KEY, false)
        // call SaveInteger(AbilityDataTable, currentAbilityId, MUST_HAVE_BUFF_CODE_WHEN_FOLLOWING_KEY, 0)
        // call SaveBoolean(AbilityDataTable, currentAbilityId, SHOULD_CHECK_OTHER_UNIT_BLOCKING_TARGET_UNIT_KEY, false)
        // call SaveReal(AbilityDataTable, currentAbilityId, MIN_TARGET_DISTANCE_KEY, 0.0)
        // call SaveReal(AbilityDataTable, currentAbilityId, FOLLOW_TARGET_DURATION_KEY, 0.0)
        // call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_OFFSET_KEY, 0.0)
        // call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_DELAY_KEY, 0.0)
        // call SaveReal(AbilityDataTable, currentAbilityId, PROJECTILE_SPEED_KEY, 0.0)
        // call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        // call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0)

        // BloodMage Abilities
        set currentAbilityId = 'A00W' // Banish
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 22.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "banish")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_COMBO)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 1)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0)
        set currentAbilityId = 'A00S' // Flame Strike
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 22.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "flamestrike")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 200.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_COMBO)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 70)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 2)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 866.0)
        set currentAbilityId = 'A01N' // Blood Lust
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 47.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "bloodlust")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 2500.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_SPEED_UP)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 50)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0)

    
        // Add more ability...
    endfunction

    function GetAbilityBaseCooldown takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 0)
    endfunction

    function GetAbilityOrderString takes integer abilityId returns string
        return LoadStr(AbilityDataTable, abilityId, 1)
    endfunction

    function GetAbilityCastRange takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 2)
    endfunction

    function GetAbilityEffectiveRadius takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 3)
    endfunction

    function GetAbilityCastType takes integer abilityId returns integer
        return LoadInteger(AbilityDataTable, abilityId, 4)
    endfunction

    function GetAbilityFindTargetType takes integer abilityId returns integer
        return LoadInteger(AbilityDataTable, abilityId, 5)
    endfunction

    function GetAbilityIsPassive takes integer abilityId returns boolean
        return LoadBoolean(AbilityDataTable, abilityId, 6)
    endfunction

    function GetAbilityRequiredCastTime takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 7)
    endfunction

    function GetAbilityManaCost takes integer abilityId returns integer
        return LoadInteger(AbilityDataTable, abilityId, 8)
    endfunction

    function GetAbilityIsIgnoreMagicImmune takes integer abilityId returns boolean
        return LoadBoolean(AbilityDataTable, abilityId, 9)
    endfunction

    function GetAbilityMustHaveBuffCodeWhenFollowing takes integer abilityId returns integer
        return LoadInteger(AbilityDataTable, abilityId, 10)
    endfunction

    function GetAbilityShouldCheckOtherUnitBlockingTargetUnit takes integer abilityId returns boolean
        return LoadBoolean(AbilityDataTable, abilityId, 11)
    endfunction

    function GetAbilityMinTargetDistance takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 12)
    endfunction

    function GetAbilityFollowTargetDuration takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 13)
    endfunction

    function GetAbilityBasePredictOffset takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 14)
    endfunction

    function GetAbilityBasePredictDelay takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 15)
    endfunction

    function GetAbilityProjectileSpeed takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 16)
    endfunction

    function GetAbilityComboIndex takes integer abilityId returns integer
        return LoadInteger(AbilityDataTable, abilityId, 17)
    endfunction

    function GetAbilityExpectedDamage takes integer abilityId returns real
        return LoadReal(AbilityDataTable, abilityId, 18)
    endfunction

endlibrary