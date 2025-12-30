// --- CONFIGURATION ---
globals
    // States
    constant integer STATE_NONE = 0
    constant integer STATE_RUN = 1
    constant integer STATE_COMBAT = 2
    constant integer STATE_HAZARD = 3
    constant integer STATE_HEALING = 4
    constant integer STATE_DEAD = 5
    constant integer STATE_PICKUP_ITEM = 6
        
    // Difficulty Levels
    constant integer DIFF_EASY = 0
    constant integer DIFF_NORMAL = 1
    constant integer DIFF_HARD = 2
    constant integer DIFF_CRAZY = 3
    constant integer DIFF_NIGHTMARE = 4
        
    // Settings
    constant real HEAL_THRESHOLD = 0.40 // 40% HP
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
    constant real PICKUP_ITEM_RANGE_NORMAL = 800.0
    constant real PICKUP_ITEM_RANGE_SMALL = 200.0

    // Self Heal Threshold
    constant real SELF_HEAL_HP_PERCENTAGE_THRESHOLD = 40.0 // 40%

    // Combat settings
    constant real EASY_CD_MULTIPLIER = 2.0
    constant real NORMAL_CD_MULTIPLIER = 1.0
    constant real HARD_CD_MULTIPLIER = 1.0
    constant real CRAZY_CD_MULTIPLIER = 1.0
    constant real NIGHTMARE_CD_MULTIPLIER = 0.8 

    // Maximum abilities and items per hero
    constant integer MAX_ABILITIES_PER_HERO = 7
    constant integer MAX_ITEM_PER_HERO = 6

    // Turn time for 90 degree turns, giving turn rate 0.6
    constant real TURN_TIME = 0.2 
    constant real MAX_RANGE = 30000.0

    

    // Ability AI cast types
    constant integer CAST_NONE = 0 
    constant integer CAST_INSTANT = 1
    constant integer CAST_INSTANT_BACK_ENEMY = 2
    constant integer CAST_INSTANT_BACK_ENEMY_FOLLOW = 3
    constant integer CAST_INSTANT_ALL_CROWDED = 4
    constant integer CAST_INSTANT_ALLY_CROWDED = 5
    constant integer CAST_INSTANT_ENEMY_CROWDED = 6
    constant integer CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE = 7
    constant integer CAST_INSTANT_ALLY_DEFENSE_AND_CLEANSE = 8
    constant integer CAST_INSTANT_HEAL = 9
    constant integer CAST_INSTANT_HEAL_ALLY_CROWDED = 10
    constant integer CAST_INSTANT_HAVE_CORPSE = 11
    constant integer CAST_INSTANT_JUMP = 12


    constant integer CAST_POINT_ENEMY_FRONT = 20
    constant integer CAST_POINT_ENEMY_BEHIND = 21 // prioritize Hazard
    constant integer CAST_POINT_ENEMY_BEHIND_CROWDED = 22 // prioritize Hazard
    constant integer CAST_POINT_ENEMY_CROWDED = 23
    constant integer CAST_POINT_ALLY_DEFENSE_AND_CLEANSE = 24
    constant integer CAST_POINT_SELF_FRONT = 25
    constant integer CAST_POINT_SELF_BEHIND_ENEMY_CROWDED = 26
    constant integer CAST_POINT_TREE = 27
    constant integer CAST_POINT_BLINK = 28

    constant integer CAST_UNIT = 40 
    constant integer CAST_TREE_FRONT = 50

    constant integer FIND_TARGET_TYPE_NONE = 0
    constant integer FIND_TARGET_TYPE_ENEMY_COMBO = 1
    constant integer FIND_TARGET_TYPE_ENEMY_HEALTHY_RUNNING = 2
    constant integer FIND_TARGET_TYPE_ENEMY_LOW_HEALTH = 3
    constant integer FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_ONLY = 4
    constant integer FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_AVOID_OVERKILL = 5
    constant integer FIND_TARGET_TYPE_ENEMY_LOW_HEALTH_CROWDED = 6
    constant integer FIND_TARGET_TYPE_ENEMY_CLOSE_TO_SELF_OR_BACK = 7
    constant integer FIND_TARGET_TYPE_ENEMY_FRONT = 8
    constant integer FIND_TARGET_TYPE_ENEMY_SUMMON_OR_NEUTRAL_CLOSE_TO_ENEMY = 9

    constant integer FIND_TARGET_TYPE_ALLY_SPEED_UP = 20
    constant integer FIND_TARGET_TYPE_ALLY_HEAL = 21
    constant integer FIND_TARGET_TYPE_ALLY_CHAIN_HEAL = 22
    constant integer FIND_TARGET_TYPE_ALLY_DEFENSE_AND_CLEANSE = 23
    constant integer FIND_TARGET_TYPE_ALLY_FOLLOW_ENEMY = 24
    constant integer FIND_TARGET_TYPE_ALLY_TELEPORT = 25
    constant integer FIND_TARGET_TYPE_ALLY_TELEPORT_FULL_MAP = 26

    constant integer FIND_TARGET_TYPE_SELF_FORCE_STAFF = 40

    constant integer FIND_TARGET_TYPE_ALL_DEATH_COIL = 50
    constant integer FIND_TARGET_TYPE_ALL_SUMMON_OR_NEUTRAL_CLOSE_TO_ENEMY = 51


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