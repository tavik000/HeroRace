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
        local integer REQUIRED_CAST_TIME_KEY = 6
        local integer MANA_COST_KEY = 7
        local integer currentItemId = 0
        
        set ItemDataTable = InitHashtable()
    
        set currentItemId = 'spsh' // SpellShieldAmulet
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_NONE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, true)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'bspd' // BootsOfSpeed
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_NONE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, true)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'pghe' // PotionOfGreaterHealing
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_HEAL)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01Q' // RatTransformer
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 3000.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_SPEED_UP)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01N' // IceArmor
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 900.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_ENEMY_CROWDED)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I016' // SilenceStaff
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 350.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ENEMY_CROWDED)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00I' // StaffOfTeleportation
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 2000.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_TELEPORT)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 1.5)
        set currentItemId = 'I01E' // PotionOfGreaterHealing, same as pghe
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_HEAL)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I000' // ForceStaff
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_SELF_FORCE_STAFF)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I015' // LongForceStaff
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 1200.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_SELF_FORCE_STAFF)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I002' // ForceMissile
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 3.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 5000.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 800.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I001' // ForceTrap
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 30.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 100.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01M' // XMark
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 3000.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00Q' // ElectricOrb
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 36.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 400.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_BACK_ENEMY)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_BACK)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01Z' // VoltReturn
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 3000.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01K' // ThunderBolt
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01W' // Charm
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_CONTROL_UNIT)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, MANA_COST_KEY, 70)
        set currentItemId = 'I02I' // Fissure
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 3000.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01J' // HookShot
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 2000.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 135.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ALL_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALL_UNIT_FRONT)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I003' // MeatHook
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 2300.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 120.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ALL_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALL_ENEMY_LEADING_OR_ALLY_TRAILING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I021' // Torrent
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 215.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I004' // IllusionStaff
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALL_ILLUSION)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I005' // RejuvenationPotion
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_HEAL)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01P' // WindWalk
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I012' // ScrollOfSpeed
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 2300.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_ALLY_CROWDED)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01V' // SpeedWard
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 400.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 700.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_SELF_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I006' // StasisTrap
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 450.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_CC)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01L' // EntanglingRoots
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01G' // Cyclone
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01O' // PipeOfInsight
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 1500.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_ALLY_CROWDED)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I007' // SnazzyPotion
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I02E' // RedPacket
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00Y' // BladeMail
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I008' // LightingShield
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 12.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 230.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT_SELF_THEN_FOLLOW_TARGET)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_BACK)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01X' // HolyCleanse
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 2000.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_CC)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I010' // BloodLust
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 2000.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_SPEED_UP)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I017' // ScrollOfProtection
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 1500.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_ALLY_CROWDED)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I009' // NovaBlast
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00B' // BlinkDagger
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 900.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_BLINK)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00C' // Ensnare
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01Y' // InvulnerabilityWard
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 2000.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 250.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ALLY_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_CC_OR_LOW_HEALTH)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01F' // LargeInvulnerabilityPotion
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00D' // InvulnerabilityPotion
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01U' // Banish
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 2000.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01T' // Hex
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00M' // HealingSalve
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 500.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_HEAL)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00E' // NetherSwap
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 800.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_FRONT)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I019' // InvisibilityWard
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 500.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 600.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_SELF_FRONT_DEFENSE_AND_CLEANSE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I01S' // Invisibility
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 2000.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_CC)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00F' // InvisibilityPotion
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 0.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00O' // EatTree
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 10.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 65.0)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_TREE_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00G' // ExplosiveBarrel
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 10.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 360.0 / 1.5)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_CC)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
        set currentItemId = 'I00H' // HealingWard
        call SaveReal(ItemDataTable, currentItemId, BASE_COOLDOWN_KEY, 10.0)
        call SaveReal(ItemDataTable, currentItemId, CAST_RANGE_KEY, 500.0)
        call SaveReal(ItemDataTable, currentItemId, EFFECTIVE_RADIUS_KEY, 500.0)
        call SaveInteger(ItemDataTable, currentItemId, CAST_TYPE_KEY, CAST_POINT_SELF_FRONT_HEAL)
        call SaveInteger(ItemDataTable, currentItemId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveBoolean(ItemDataTable, currentItemId, IS_PASSIVE_KEY, false)
        call SaveReal(ItemDataTable, currentItemId, REQUIRED_CAST_TIME_KEY, 0.0)
    
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

    function GetItemRequiredCastTime takes integer itemId returns real
        return LoadReal(ItemDataTable, itemId, 6)
    endfunction

    function GetItemManaCost takes integer itemId returns integer
        return LoadInteger(ItemDataTable, itemId, 7)
    endfunction

endlibrary