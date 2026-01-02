library AIItemConfig
    globals
        hashtable ItemDataTable
    endglobals

    function InitItemData takes nothing returns nothing
        local integer BASE_COOLDOWN_KEY = 0
        local integer CAST_RANGE_KEY = 1
        local integer EFFECTIVE_RADIUS_KEY = 2
        local integer CAST_TYPE_KEY = 3
        local integer FIND_TARGET_TYPE_KEY = 4
        local integer IS_PASSIVE_KEY = 5
        local integer currentItemId = 0
        
        set ItemDataTable = InitHashtable()
    
        set currentItemId = 'spsh' // SpellShieldAmulet
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_NONE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, true)
        set currentItemId = 'bspd' // BootsOfSpeed
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_NONE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, true)
        set currentItemId = 'pghe' // PotionOfGreaterHealing
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_HEAL)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        set currentItemId = 'I01E' // PotionOfGreaterHealing, same as pghe
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_HEAL)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        set currentItemId = 'I01Q' // RatTransformer
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 3000.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_SPEED_UP)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        set currentItemId = 'I01N' // IceArmor
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 900.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_ENEMY_CROWDED)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        set currentItemId = 'I016' // SilenceStaff
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 350.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ENEMY_CROWDED)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        set currentItemId = 'I010' // BloodLust
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 2000.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_SPEED_UP)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
    
        // Add more items...
    endfunction

    function GetItemBaseCooldown takes integer itemId returns real
        return LoadReal(ItemDataTable, itemId, 0)
    endfunction

    function GetItemCastRange takes integer itemId returns real
        return LoadReal(ItemDataTable, itemId, 1)
    endfunction

    function GetItemEffectiveRadius takes integer itemId returns real
        return LoadReal(ItemDataTable, itemId, 2)
    endfunction

    function GetItemCastType takes integer itemId returns integer
        return LoadInteger(ItemDataTable, itemId, 3)
    endfunction

    function GetItemFindTargetType takes integer itemId returns integer
        return LoadInteger(ItemDataTable, itemId, 4)
    endfunction

    function GetItemIsPassive takes integer itemId returns boolean
        return LoadBoolean(ItemDataTable, itemId, 5)
    endfunction
endlibrary