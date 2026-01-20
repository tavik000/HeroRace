// --- CONFIGURATION ---
globals
    // States
    constant integer STATE_NONE = 0
    constant integer STATE_RUN = 1
    constant integer STATE_COMBAT = 2
    constant integer STATE_HAZARD = 3
    constant integer STATE_FOLLOW = 4
    constant integer STATE_DEAD = 5
    constant integer STATE_PICKUP_ITEM = 6
    constant integer STATE_GOALED = 7
    constant integer STATE_GIVE_ITEM = 8
        
    // Difficulty Levels
    constant integer DIFF_EASY = 0
    constant integer DIFF_NORMAL = 1
    constant integer DIFF_HARD = 2
    constant integer DIFF_CRAZY = 3
    constant integer DIFF_NIGHTMARE = 4
        
    // Settings
    constant real UPDATE_PERIOD = 0.30

    // Hazard Types
    constant integer HAZARD_TYPE_NONE = 0
    constant integer HAZARD_TYPE_SLOW_SPIKE = 1
    constant integer HAZARD_TYPE_FAST_SPIKE = 2
    constant integer HAZARD_TYPE_NET = 3
    constant integer HAZARD_TYPE_SPIDER_NET = 4
        
    // Slow Spike Hazard Settings 
    constant real SLOW_SPIKE_SPEED = 155.0
    constant real SLOW_SPIKE_RADIUS = 110.0
    constant integer SLOW_SPIKE_UNIT_TYPE_ID = 'e047'

    // Net Hazard Settings
    constant real NET_SPEED = 155.0
    constant real NET_RADIUS = 110.0
    constant integer NET_UNIT_TYPE_ID = 'e048'

    // Spider Net Hazard Settings
    constant real SPIDER_NET_RADIUS = 200.0 // the trigger is 150, add 50 for buffer
    constant integer SPIDER_NET_UNIT_TYPE_ID = 'u022'

    // Pickup Item Range
    constant real PICKUP_ITEM_RANGE_LARGE = 1000.0
    constant real PICKUP_ITEM_RANGE_NORMAL = 800.0
    constant real PICKUP_ITEM_RANGE_SMALL = 200.0

    // Give Item Range
    constant real GIVE_ITEM_RANGE = 400.0

    // Heal HP Percentage Threshold
    constant real HEAL_HP_PERCENTAGE_THRESHOLD = 40.0 // 40% HP
    // Force Use Item Threshold
    constant real FORCE_USE_ITEM_HP_PERCENTAGE_THRESHOLD = 30.0 // 30%

    // Combat settings
    constant real EASY_CD_MULTIPLIER = 2.5
    constant real NORMAL_CD_MULTIPLIER = 1.0
    constant real HARD_CD_MULTIPLIER = 1.0
    constant real CRAZY_CD_MULTIPLIER = 1.0
    constant real NIGHTMARE_CD_MULTIPLIER = 0.6 

    constant real CRAZY_EXTRA_DAMAGE_PERCENTAGE = 0.2 
    constant real NIGHTMARE_EXTRA_DAMAGE_PERCENTAGE = 0.6

    // Maximum abilities and items per hero
    constant integer MAX_ABILITIES_PER_HERO = 7
    constant integer MAX_ITEM_PER_HERO = 6

    // Turn time for 90 degree turns, giving turn rate 0.6
    constant real TURN_TIME = 0.2 
    constant real MAX_RANGE = 300000.0

    

    // Ability AI cast types
    constant integer CAST_NONE = 0 

    constant integer CAST_INSTANT = 1
    constant integer CAST_INSTANT_BACK_ENEMY = 2
    constant integer CAST_INSTANT_BACK_ENEMY_FOLLOW = 3
    constant integer CAST_INSTANT_ENEMY_CROWDED = 4
    constant integer CAST_INSTANT_BACK_ALLY = 5
    constant integer CAST_INSTANT_ALLY_CROWDED = 6
    constant integer CAST_INSTANT_ALLY_DEFENSE_AND_CLEANSE = 7
    constant integer CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE = 8
    constant integer CAST_INSTANT_ALL_CROWDED = 9
    constant integer CAST_INSTANT_HEAL = 10
    constant integer CAST_INSTANT_HEAL_ALLY_CROWDED = 11
    constant integer CAST_INSTANT_HAVE_CORPSE = 12
    constant integer CAST_INSTANT_JUMP = 13
    constant integer CAST_INSTANT_COMBO_TARGET_NOT_CC = 14
    constant integer CAST_INSTANT_ANIMATE_DEAD = 15


    constant integer CAST_POINT_ENEMY_FRONT = 20
    constant integer CAST_POINT_ENEMY_BEHIND = 21 // prioritize Hazard
    constant integer CAST_POINT_ENEMY_CROWDED = 22
    constant integer CAST_POINT_ALLY_DEFENSE_AND_CLEANSE = 23
    constant integer CAST_POINT_ALLY_FRONT = 24
    constant integer CAST_POINT_SELF_FRONT = 25
    constant integer CAST_POINT_SELF_FRONT_DEFENSE_AND_CLEANSE = 26
    constant integer CAST_POINT_SELF_FRONT_HEAL = 27
    constant integer CAST_POINT_SELF_BEHIND_ENEMY_CROWDED = 28
    constant integer CAST_POINT_ALL_FRONT = 29
    constant integer CAST_POINT_TREE_NEAR_ENEMY = 30
    constant integer CAST_POINT_BLINK = 31

    constant integer CAST_UNIT = 40 
    constant integer CAST_UNIT_SELF_THEN_FOLLOW_TARGET = 41
    constant integer CAST_TREE_FRONT = 50

    constant integer FIND_TARGET_TYPE_NONE = 0
    constant integer FIND_TARGET_TYPE_ENEMY_COMBO = 1
    constant integer FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING = 2
    constant integer FIND_TARGET_TYPE_ENEMY_LOW_HEALTH = 3
    constant integer FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_ONLY = 4
    constant integer FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_AVOID_OVERKILL = 5
    constant integer FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_CROWDED = 6
    constant integer FIND_TARGET_TYPE_ENEMY_FRONT = 7
    constant integer FIND_TARGET_TYPE_ENEMY_BACK = 8
    constant integer FIND_TARGET_TYPE_ENEMY_BACK_OR_CLOSE = 9 
    constant integer FIND_TARGET_TYPE_ENEMY_CONTROL_UNIT = 10
    constant integer FIND_TARGET_TYPE_ENEMY_CC = 11

    constant integer FIND_TARGET_TYPE_ALLY_SPEED_UP = 20
    constant integer FIND_TARGET_TYPE_ALLY_HEAL = 21
    constant integer FIND_TARGET_TYPE_ALLY_CHAIN_HEAL = 22
    constant integer FIND_TARGET_TYPE_ALLY_CC = 23
    constant integer FIND_TARGET_TYPE_ALLY_FOLLOW_ENEMY = 24
    constant integer FIND_TARGET_TYPE_ALLY_TELEPORT = 25
    constant integer FIND_TARGET_TYPE_ALLY_TELEPORT_FULL_MAP = 26
    constant integer FIND_TARGET_TYPE_ALLY_CC_OR_LOW_HEALTH = 27

    constant integer FIND_TARGET_TYPE_SELF_FORCE_STAFF = 40

    constant integer FIND_TARGET_TYPE_ALL_ILLUSION = 51
    constant integer FIND_TARGET_TYPE_ALL_FRONT = 52 // Furthest
    constant integer FIND_TARGET_TYPE_ALL_UNIT_FRONT = 53 // Furthest, including non-hero units
    constant integer FIND_TARGET_TYPE_ALL_ENEMY_LEADING_OR_ALLY_TRAILING = 54 
    constant integer FIND_TARGET_TYPE_ALL_HOLY_LIGHT = 55 
    constant integer FIND_TARGET_TYPE_ALL_DEATH_COIL = 56


    constant integer FIND_TEAM_TYPE_NONE = 0
    constant integer FIND_TEAM_TYPE_ALLIES = 1
    constant integer FIND_TEAM_TYPE_ENEMIES = 2
    constant integer FIND_TEAM_TYPE_ALL = 3

    // Debug Text Tag Color Presets (RGB 0-100 format)
    constant real COLOR_WHITE_R = 100.0
    constant real COLOR_WHITE_G = 100.0
    constant real COLOR_WHITE_B = 100.0
    constant real COLOR_RED_R = 100.0
    constant real COLOR_RED_G = 0.0
    constant real COLOR_RED_B = 0.0
    constant real COLOR_GREEN_R = 0.0
    constant real COLOR_GREEN_G = 100.0
    constant real COLOR_GREEN_B = 0.0
    constant real COLOR_BLUE_R = 0.0
    constant real COLOR_BLUE_G = 0.0
    constant real COLOR_BLUE_B = 100.0
    constant real COLOR_YELLOW_R = 100.0
    constant real COLOR_YELLOW_G = 100.0
    constant real COLOR_YELLOW_B = 0.0
    constant real COLOR_ORANGE_R = 100.0
    constant real COLOR_ORANGE_G = 64.7
    constant real COLOR_ORANGE_B = 0.0
    constant real COLOR_PURPLE_R = 50.2
    constant real COLOR_PURPLE_G = 0.0
    constant real COLOR_PURPLE_B = 50.2
    constant real COLOR_CYAN_R = 0.0
    constant real COLOR_CYAN_G = 100.0
    constant real COLOR_CYAN_B = 100.0
    constant real COLOR_PINK_R = 100.0
    constant real COLOR_PINK_G = 75.3
    constant real COLOR_PINK_B = 79.6
    constant real COLOR_GRAY_R = 36.5
    constant real COLOR_GRAY_G = 36.5
    constant real COLOR_GRAY_B = 36.5

endglobals