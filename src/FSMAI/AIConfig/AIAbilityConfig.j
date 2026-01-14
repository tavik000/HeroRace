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

        // MountainKing Abilities
        set currentAbilityId = 'A00C' // ThunderBolt
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 32.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "thunderbolt")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 5000.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 60)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 175.0)
        set currentAbilityId = 'A00R' // ThunderClap
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 20.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "thunderclap")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 350.0 - 50.0) // prevent missing
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_BACK_ENEMY)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_BACK_OR_CLOSE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 70)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 320.0)
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.01) // prevent interrupt by moving
        set currentAbilityId = 'A014' // Avatar 
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 26.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "metamorphosis")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 30)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)

        // Archmage Abilities
        set currentAbilityId = 'A01K' // ThunderFireball
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 29.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "firebolt")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_COMBO)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 70 + 30) // 20 for blizzard combo
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 1)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 300.0)
        call SaveReal(AbilityDataTable, currentAbilityId, PROJECTILE_SPEED_KEY, 800.0)
        set currentAbilityId = 'A001' // Blizzard
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 22.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 300.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_CC)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 285.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_OFFSET_KEY, 120.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_DELAY_KEY, 1.0)
        set currentAbilityId = 'A019' // MassTeleport
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 50.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "massteleport")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_TELEPORT_FULL_MAP)
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 3.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 135)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)

        // Arthas Abilities
        set currentAbilityId = 'A00P' // HammerBash
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 24.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "thunderbolt")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 150.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 200.0) // only for finding target
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_BACK_OR_CLOSE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 50)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 435.0)
        set currentAbilityId = 'A00J' // GoldenConvergence
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 23.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 850.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_BEHIND)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_CROWDED)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 50)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 130.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_OFFSET_KEY, 850.0 / 1.25) // in order to hit more targets
        set currentAbilityId = 'A01G' // GoldenDefense
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 30.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "rejuvination")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_HEAL)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 95)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)

        // Paladin Abilities
        set currentAbilityId = 'A01O' // InnerFire
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 30.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "innerfire")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_HEAL)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 45)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        set currentAbilityId = 'A01M' // HolyCleanse
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 25.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "antimagicshell")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 270.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_CC)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        set currentAbilityId = 'A00Q' // SolarIgnition
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 23.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 200.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_CC)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 55)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 255.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_OFFSET_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_DELAY_KEY, 0.5)

        // CrystalMaiden Abilities
        set currentAbilityId = 'A006' // Frostbite
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 33.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "acidbomb")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        set currentAbilityId = 'A008' // CrystalNova
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 30.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 360.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_CROWDED)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 60)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        set currentAbilityId = 'A005' // CrystalScatter
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 15.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "fanofknives")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 900.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_ALL_CROWDED)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 35)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 130.0)

        // LightKnight Abilities
        set currentAbilityId = 'A012' // HolyLight
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 26.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "holybolt")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALL_HOLY_LIGHT)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 65)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 450.0)
        set currentAbilityId = 'A011' // DivineShield
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 18.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "divineshield")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 30)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        set currentAbilityId = 'A0DW' // RapidMarch
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 42.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 4000.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_ALLY_CROWDED)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 90)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)

        // Lina Abilities
        set currentAbilityId = 'A00T' // DragonSlave
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 22.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "shockwave")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 1075.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 275.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 240.0)
        set currentAbilityId = 'A00F' // LightStrikeArray
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 25.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 225.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 45)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 240.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_DELAY_KEY, 0.65)
        set currentAbilityId = 'A010' // LagunaBlade
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 52.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "chainlightning")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 900.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_AVOID_OVERKILL)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 90)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 440.0)

        // BeastMaster Abilities
        set currentAbilityId = 'A038' // SummonGrizzly
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 53.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "summongrizzly")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 30)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 1)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 67.0 * 4) // 4 attacks
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.01) // prevent interrupt by moving
        set currentAbilityId = 'A037' // SummonQuillBeast
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 53.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "summonquillbeast")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 25)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 2)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 44.0 * 4) // 4 attacks
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.01) // prevent interrupt by moving
        set currentAbilityId = 'A02G' // Stampede
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 41.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "stampede")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 700.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 1000.0 - 200.0) // prevent missing
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_SELF_BEHIND_ENEMY_CROWDED)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 110)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 660.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_OFFSET_KEY, 10.0)
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 2.1) // channel time

        // Guldan Abilities
        set currentAbilityId = 'A01X' // Infernal(Small)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 19.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "dreadlordinferno")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 175.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_COMBO)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 60)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 1)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 165.0 + 40 * 5) // 5 attacks
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_DELAY_KEY, 0.65)
        set currentAbilityId = 'A03L' // Purge
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 22.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "purge")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_COMBO)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 2)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0)
        set currentAbilityId = 'A053' // HolyLight(Guldan)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 26.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "healingwave")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_HEAL)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 60)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)

        // Lion Abilities
        set currentAbilityId = 'A083' // EarthImpale
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 36.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "impale")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 265.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 70)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 255.0) 
        set currentAbilityId = 'A09D' // Hex(Lion)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 27.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "hex")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 45)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        set currentAbilityId = 'A089' // ManaDrain
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 45.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "drain")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 1300.0 - 400.0) // prevent missing
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 1300.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 0)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 2.5) // channel time
        set currentAbilityId = 'A0A4' // FingerOfDeath
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 80.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "fingerofdeath")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 1300.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 80)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 300.0)

        // ChaosBladeMaster Abilities
        set currentAbilityId = 'A03G' // HealingWard
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 40.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "healingward")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 500.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 500.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_SELF_FRONT_HEAL)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 50)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        set currentAbilityId = 'A03B' // CriticalStrike
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 18.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "thunderbolt")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 150.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 200.0) // only for finding target
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_BACK_OR_CLOSE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 30)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 280.0)
        set currentAbilityId = 'A02Y' // Omnislash
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 41.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 1000.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 650.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_AVOID_OVERKILL)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 100)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 750.0)

        // Farseer Abilities
        set currentAbilityId = 'A02P' // ChainLightning
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 24.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "chainlightning")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 950.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_CROWDED)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 65)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 235.0)
        set currentAbilityId = 'A032' // SpiritWolf
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 35.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "spiritwolf")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 73.0 * 4) // 4 attacks
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.01) // prevent interrupt by moving
        set currentAbilityId = 'A01Z' // EarthQuake
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 45.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 265.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 70)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_DELAY_KEY, 0.65)

        // TaurenChieftain Abilities
        set currentAbilityId = 'A03A' // Shockwave
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 18.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "shockwave")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 1200.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 140.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 60)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 245.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_DELAY_KEY, 0.75)
        set currentAbilityId = 'A036' // WarStomp
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 34.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "stomp")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 310.0 - 50.0) // prevent missing
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_BACK_ENEMY)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_BACK_OR_CLOSE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 70)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 285.0)
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.01) // prevent interrupt by moving

        // ShadowHunter Abilities
        set currentAbilityId = 'A033' // HealingWave
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 48.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "healingwave")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 1300.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ALLY_CHAIN_HEAL)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 50)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        set currentAbilityId = 'A031' // Hex(ShadowHunter)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 29.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "hex")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 55)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        set currentAbilityId = 'A021' // SerpentWard
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 45.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "ward")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_AVOID_OVERKILL)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 70)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 23.0 * 8 * 5) // 8 wards, 5 attacks each
        set currentAbilityId = 'A0J0' // BigBadVoodoo
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 60.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "voodoo")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 900.0 - 100.0) // prevent missing
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_ALLY_DEFENSE_AND_CLEANSE)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)    
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 5.0) // channel time

        // Eredar Abilities
        set currentAbilityId = 'A04A' // DemonParasite
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 45.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_COMBO)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 45)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 1)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 57.0 * 2 * 7.5) // 2 parasites, 7.5 attacks each
        set currentAbilityId = 'A05S' // TerrorDecay
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 42.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "roar")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, MAX_RANGE)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_COMBO_TARGET_NOT_CC)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 55)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 2)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.01) // prevent interrupt by moving
        set currentAbilityId = 'A049' // DemonShockwave
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 36.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "repair")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 1275.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 500.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_BACK)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 60)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 225.0)
        call SaveReal(AbilityDataTable, currentAbilityId, PROJECTILE_SPEED_KEY, 725.0)

        // Banshee Abilities
        set currentAbilityId = 'A056' // CarrionSwarm
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 32.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "carrionswarm")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 1000.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 100.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 210.0)
        call SaveReal(AbilityDataTable, currentAbilityId, PROJECTILE_SPEED_KEY, 950.0)
        set currentAbilityId = 'A05L' // Curse
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 27.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_COMBO)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 45)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 1)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 250.0)
        set currentAbilityId = 'A05H' // OutOfBody
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 30.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "shadowstrike")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_COMBO)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 35)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 2)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 150.0)
        set currentAbilityId = 'A05Q' // ChaosSorcery
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 35.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "unholyfrenzy")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)  
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_COMBO)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 3)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 360.0)
        set currentAbilityId = 'A050' // LocustSwarm
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 65.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "locustswarm")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 800.0 - 200.0) // prevent missing
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_ENEMY_CROWDED)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 60)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 400.0)
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.01) // prevent interrupt by moving

        // PitLord Abilities
        set currentAbilityId = 'A04O' // RainOfFire
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 30.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 245.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_POINT_ENEMY_FRONT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_CC)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 75)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 485.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_OFFSET_KEY, 120.0)
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_PREDICT_DELAY_KEY, 1.0)
        set currentAbilityId = 'A04R' // HowlOfTerror
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 28.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "howlofterror")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)  
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 1300.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_ENEMY_CROWDED)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 45)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 150.0)
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.01) // prevent interrupt by moving
        set currentAbilityId = 'A04Z' // Doom
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 73.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "doom")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_AVOID_OVERKILL)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 95)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 585.0)

        // PlagueCaster Abilities
        set currentAbilityId = 'A0H5' // DeathPulse
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 26.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "fanofknives")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 650.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT_ALL_CROWDED)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 55)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 225.0)
        set currentAbilityId = 'A0H3' // GhostShroud
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 47.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "channel")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 850.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_INSTANT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_NONE)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 40)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 0.0)
        call SaveReal(AbilityDataTable, currentAbilityId, REQUIRED_CAST_TIME_KEY, 0.01) // prevent interrupt by moving
        set currentAbilityId = 'A0H8' // ReaperScythe
        call SaveReal(AbilityDataTable, currentAbilityId, BASE_COOLDOWN_KEY, 60.0)
        call SaveStr(AbilityDataTable, currentAbilityId, ORDER_STRING_KEY, "thunderbolt")
        call SaveReal(AbilityDataTable, currentAbilityId, CAST_RANGE_KEY, MAX_RANGE)
        call SaveReal(AbilityDataTable, currentAbilityId, EFFECTIVE_RADIUS_KEY, 0.0)
        call SaveInteger(AbilityDataTable, currentAbilityId, CAST_TYPE_KEY, CAST_UNIT)
        call SaveInteger(AbilityDataTable, currentAbilityId, FIND_TARGET_TYPE_KEY, FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_ONLY)
        call SaveInteger(AbilityDataTable, currentAbilityId, MANA_COST_KEY, 85)
        call SaveInteger(AbilityDataTable, currentAbilityId, COMBO_INDEX_KEY, 0)
        call SaveReal(AbilityDataTable, currentAbilityId, EXPECTED_DAMAGE_KEY, 320.0)




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