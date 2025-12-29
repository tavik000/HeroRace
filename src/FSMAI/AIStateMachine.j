library AIStateMachine requires optional KeyUtils
    
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

        // Combat settings
        constant real EASY_CD_MULTIPLIER = 2.0
        constant real NORMAL_CD_MULTIPLIER = 1.0
        constant real HARD_CD_MULTIPLIER = 1.0
        constant real CRAZY_CD_MULTIPLIER = 1.0
        constant real NIGHTMARE_CD_MULTIPLIER = 0.8 

        // Maximum abilities and items per hero
        constant integer MAX_ABILITIES_PER_HERO = 7
        constant integer MAX_ITEM_PER_HERO = 6
        
        // Timer to AIHero mapping
        public hashtable udg_TimerHeroMap
        public hashtable udg_DebugTextTagTimerHeroMap
        
        // Unit to AIHero mapping
        public hashtable udg_UnitAIHeroMap
        
        // Global timer for tracking game time
        public timer gameTimer
        
        // Hero cast point (pre-swing) mapping by unit type
        public hashtable heroCastPointMap
        
        // Temporary variables for filtering heroes
        private player tempHeroOwner
        private boolean bTempFilterForAllies
        private unit tempHeroUnit
        private AIHeroAbility tempAIHeroAbility

        // Temporary variables for item search
        item tempFoundItem = null
        real tempFoundItemX = 0.0
        real tempFoundItemY = 0.0
        real tempFoundItemUnitFacingAngle = 0.0
        real tempFoundItemRange = 0.0
        real tempFoundItemMinDist = 999999.0

        // The array to hold the waypoint regions.
        private rect array WaypointAreas
        // The actual number of waypoints initialized.
        public integer WaypointCount = 0

        // Turn time for 90 degree turns, giving turn rate 0.6
        constant real TURN_TIME = 0.2 

        constant real MAX_RANGE = 30000.0

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

    function BotLog takes string msg returns nothing
        if udg_bEnableLogBot then
            call BJDebugMsg("[AI Bot] " + msg)
        endif
    endfunction

    function BotLogWithPlayer takes player p, string msg returns nothing
        local integer playerIndex = GetPlayerId(p) + 1
        local string playerName = ""
        if udg_bEnableLogBot then
            if playerIndex >= 0 and playerIndex <= 12 then
                set playerName = udg_PlayerNameWithHero[playerIndex]
                if playerName != null and playerName != "" then
                    call BJDebugMsg("[AI Bot] " + playerName + " " + msg)
                else
                    call BJDebugMsg("[AI Bot] Player " + I2S(playerIndex) + " " + msg)
                endif
            else
                call BJDebugMsg("[AI Bot] " + msg)
            endif
        endif
    endfunction

    function BotLogError takes string msg returns nothing
        call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + msg)
    endfunction

    function BotLogErrorWithPlayer takes player p, string msg returns nothing
        local integer playerIndex = GetPlayerId(p) + 1
        local string playerName = ""
        if playerIndex >= 0 and playerIndex <= 12 then
            set playerName = udg_PlayerNameWithHero[playerIndex]
            if playerName != null and playerName != "" then
                call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + playerName + " " + msg)
            else
                call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r Player " + I2S(playerIndex) + " " + msg)
            endif
        else
            call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + msg)
        endif
    endfunction

    // Helper function to get cooldown multiplier based on difficulty
    function GetCooldownMultiplier takes integer difficulty returns real
        if difficulty == DIFF_EASY then
            return EASY_CD_MULTIPLIER
        elseif difficulty == DIFF_NORMAL then
            return NORMAL_CD_MULTIPLIER
        elseif difficulty == DIFF_HARD then
            return HARD_CD_MULTIPLIER
        elseif difficulty == DIFF_CRAZY then
            return CRAZY_CD_MULTIPLIER
        elseif difficulty == DIFF_NIGHTMARE then
            return NIGHTMARE_CD_MULTIPLIER
        else
            return 1.0
        endif
    endfunction

    function IsApplyingCombo takes integer difficulty returns boolean
        if difficulty == DIFF_HARD or difficulty == DIFF_CRAZY or difficulty == DIFF_NIGHTMARE then
            return true
        else
            return false
        endif
    endfunction

    function IsUnitInAnyHazardZone takes unit u returns boolean
        local real ux = GetUnitX(u)
        local real uy = GetUnitY(u)
        if RectContainsCoords(gg_rct_HazardSlowSpikeArea, ux, uy) then
            return true
        endif
        if RectContainsCoords(gg_rct_HazardFastSpikeArea, ux, uy) then
            return true
        endif
        if RectContainsCoords(gg_rct_HazardNetArea, ux, uy) then
            return true
        endif
        if RectContainsCoords(gg_rct_HazardSpiderNetArea, ux, uy) then
            return true
        endif
        return false
    endfunction

    function IsInSlowSpikeHazardZone takes AIHero aiHero returns boolean
        local integer wpi = aiHero.currentWaypointIndex
        if wpi == 8 then
            return true
        endif
        return false
    endfunction

    function IsInFastSpikeHazardZone takes AIHero aiHero returns boolean
        local integer wpi = aiHero.currentWaypointIndex
        if IsTriggerEnabled(gg_trg_FastSpike) then
            if wpi == 10 then
                return true
            endif
        endif
        return false
    endfunction

    function IsInNetHazardZone takes AIHero aiHero returns boolean
        local integer wpi = aiHero.currentWaypointIndex
        if IsTriggerEnabled(gg_trg_Net01) then
            if wpi == 12 then
                return true
            endif
        endif
        return false
    endfunction

    function IsInSpiderNetHazardZone takes AIHero aiHero returns boolean
        local real heroX = GetUnitX(aiHero.hero)
        local real heroY = GetUnitY(aiHero.hero)
        local integer wpi = aiHero.currentWaypointIndex
        if RectContainsCoords(gg_rct_HazardSpiderNetArea, heroX, heroY) then
            if wpi == 14 then
                return true
            endif
        endif
        return false
    endfunction

    function IsFinalWaypoint takes AIHero aiHero returns boolean
        if aiHero.currentWaypointIndex >= WaypointCount then
            return true
        endif
        return false
    endfunction

    function EnumItemsAction takes nothing returns nothing
        local item itm = GetEnumItem()
        local real dist = DistanceBetweenXY(tempFoundItemX, tempFoundItemY, GetItemX(itm), GetItemY(itm))
        local real itemAngle = AngleBetweenXY(tempFoundItemX, tempFoundItemY, GetItemX(itm), GetItemY(itm))
        local boolean bIsInFrontArc = IsWithinForwardArc(itemAngle, tempFoundItemUnitFacingAngle)
        if not bIsInFrontArc then
            set tempFoundItemRange = tempFoundItemRange * 0.65
        endif
        if dist < tempFoundItemMinDist and dist <= tempFoundItemRange then
            set tempFoundItemMinDist = dist
            set tempFoundItem = itm
        endif
    endfunction

    function GetSuitablePickupItemInRange takes unit u, real range returns item
        local item foundItem = null
        local real ux = GetUnitX(u)
        local real uy = GetUnitY(u)
        local rect rec = Rect(ux - range, uy - range, ux + range, uy + range)

        set tempFoundItem = null
        set tempFoundItemX = ux
        set tempFoundItemY = uy
        set tempFoundItemRange = range
        set tempFoundItemMinDist = 999999.0
        set tempFoundItemUnitFacingAngle = GetUnitFacing(u)

        call EnumItemsInRectBJ(rec, function EnumItemsAction)
        call RemoveRect(rec)
        set foundItem = tempFoundItem

        return foundItem
    endfunction



    // Initialize hero cast points (Pre-swing) by unit type
    private function InitializeHeroCastPoints takes nothing returns nothing
        // Configure cast points for different hero types
        call SaveReal(heroCastPointMap, 'H009', 0, 0.2)  // BloodMage
        // call SaveReal(heroCastPointMap, 'Hmkg', 0, 0.3)  // Mountain King  
        // TODO: Add more hero types as needed
    endfunction

    // Initialize hero-specific abilities (extend this function for different heroes)
    function InitializeHeroCombatData takes unit hero, integer difficulty returns HeroCombatData
        local HeroCombatData data = HeroCombatData.create()
        local integer heroTypeId = GetUnitTypeId(hero)

        
        // Example: Add abilities based on hero type
        if heroTypeId == 'H009' then  // BloodMage example
            call BotLog("Adding abilities for BloodMage")
            call data.addAbility('A00S', 22.0, CAST_POINT_ENEMY_FRONT, "flamestrike", 70, MAX_RANGE, FIND_TARGET_TYPE_ENEMY_COMBO, 200, 2, 866.0)   // Flame Strike
            call data.addAbility('A00W', 22.0, CAST_UNIT, "banish", 40, MAX_RANGE, FIND_TARGET_TYPE_ENEMY_COMBO, 0, 1, 0.0)   // Banish
            call data.addAbility('A01N', 47.0, CAST_UNIT, "bloodlust", 50, 2500, FIND_TARGET_TYPE_ALLY_SPEED_UP, 0, 0, 0.0) // Blood Lust
            
        elseif heroTypeId == 'Hmkg' then  // Mountain King example
            // call data.addAbility('AHtc', 6.0, CAST_UNIT, "thunderclap", 75, 250, FIND_TARGET_TYPE_ENEMY_UNIT, 0)      // Thunder Clap
            // Add more hero types as needed...
        endif
        
        return data
    endfunction

    function GetHeroCastPoint takes integer heroTypeId returns real
        if HaveSavedReal(heroCastPointMap, heroTypeId, 0) then
            return LoadReal(heroCastPointMap, heroTypeId, 0)
        else
            call BotLogError("Unknown hero type for GetHeroCastPoint: " + I2S(heroTypeId))
            return 0.5  // Default cast point for unknown hero types
        endif
    endfunction

    // Helper function for basic unit validation
    function IsValidHeroTarget takes unit filterUnit returns boolean
        if not IsUnitAliveBJ(filterUnit) then
            return false
        endif
        if not IsUnitType(filterUnit, UNIT_TYPE_HERO) then
            return false
        endif
        if not IsUnitVisible(filterUnit, tempHeroOwner) then
            return false
        endif
        return true
    endfunction

    // Generic filter function for heroes (enemies or allies)
    function FilterHeroes takes nothing returns boolean
        local unit filterUnit = GetFilterUnit()
        
        if not IsValidHeroTarget(filterUnit) then
            set filterUnit = null
            return false
        endif

        if tempAIHeroAbility != 0 then
            if not tempAIHeroAbility.customFilter(filterUnit) then
                set filterUnit = null
                return false
            endif
        endif

        // Check if we want allies or enemies
        if bTempFilterForAllies then
            // Filter for allies (same team, but not the same unit)
            if IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
        else
            // Filter for enemies
            if not IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
            if IsUnitInvulnerableOrMagicImmune(filterUnit) then
                set filterUnit = null
                return false
            endif
        endif
        
        set filterUnit = null
        return true
    endfunction

    function GetAIHeroFromUnit takes unit u returns AIHero
        if u == null then
            return 0
        endif
        return LoadInteger(udg_UnitAIHeroMap, GetHandleId(u), 0)
    endfunction

    function DestroyAIHero takes unit u returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.destroy()
        endif
    endfunction

    function OnAIHeroCastComplete takes unit u returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.onCastComplete()
        endif
    endfunction

    function OnAIHeroGetItem takes unit u, item itm returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.onGetItem(itm)
        endif
    endfunction

    // This function will run once at map initialization to set up the waypoints.
    private function InitializeWaypoints takes nothing returns nothing
        // IMPORTANT: Create regions in the World Editor and replace these
        set WaypointAreas[0] = gg_rct_AIWayPointArea01 // Not used
        set WaypointAreas[1] = gg_rct_AIWayPointArea01 // After Start Area
        set WaypointAreas[2] = gg_rct_AIWayPointArea02
        set WaypointAreas[3] = gg_rct_AIWayPointArea03 // Left of Upper Strait
        set WaypointAreas[4] = gg_rct_AIWayPointArea04
        set WaypointAreas[5] = gg_rct_AIWayPointArea05 // Upper of 3 Fishes
        set WaypointAreas[6] = gg_rct_AIWayPointArea06 // Left of 3 Fishes 
        set WaypointAreas[7] = gg_rct_AIWayPointArea07 // Before Slow Spike Hazard
        set WaypointAreas[8] = gg_rct_AIWayPointArea08 // After Slow Spike Hazard
        set WaypointAreas[9] = gg_rct_AIWayPointArea09 // Before Fast Spike Hazard
        set WaypointAreas[10] = gg_rct_AIWayPointArea10 // After Fast Spike Hazard
        set WaypointAreas[11] = gg_rct_AIWayPointArea11 // Before Net Hazard
        set WaypointAreas[12] = gg_rct_AIWayPointArea12 // After Net Hazard
        set WaypointAreas[13] = gg_rct_AIWayPointArea13 // Before Spider Net Hazard
        set WaypointAreas[14] = gg_rct_Finish
        set WaypointCount = 14 // Update this to match the number of waypoints you added.
    endfunction

    // Ability AI cast types
    globals
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

    endglobals

    struct AIItem
        integer itemId // item type
        item itemHandle
        real baseCooldown
        real lastUseTime
        real castRange
        unit ownerHero
        boolean bIsPassive



        static method create takes item newItemHandle, integer newItemId, real newBaseCooldown, real newCastRange, unit newOwnerHero, boolean bNewIsPassive returns thistype
            local thistype this = thistype.allocate()
            set this.itemHandle = newItemHandle
            set this.itemId = newItemId
            set this.baseCooldown = newBaseCooldown
            set this.castRange = newCastRange
            set this.ownerHero = newOwnerHero
            set this.bIsPassive = bNewIsPassive
            set this.lastUseTime = 0.0
            return this
        endmethod

        method isReadyToUse takes nothing returns boolean
            return not bIsPassive
        endmethod

        method tryUse takes nothing returns nothing
            // local integer itemSlot = GetInventoryIndexOfItemTypeBJ(this.ownerHero, this.itemId)
            call UnitUseItemTarget( this.ownerHero, this.itemHandle, this.ownerHero)
            call this.botLog("Using item: " + GetItemName(this.itemHandle))
            // TODO
        endmethod

        method destroy takes nothing returns nothing
            call this.deallocate()
        endmethod

        method botLog takes string msg returns nothing
            call BotLogWithPlayer(GetOwningPlayer(this.ownerHero), msg)
        endmethod

        method botLogError takes string msg returns nothing
            call BotLogErrorWithPlayer(GetOwningPlayer(this.ownerHero), msg)
        endmethod
    endstruct

    struct AIHeroAbility
        integer abilityId
        real baseCooldown
        integer castType
        real lastCastTime
        integer comboIndex  // For chaining abilities in sequence
        string orderString  
        integer manaCost    
        real castRange
        integer findTargetType
        real effectiveRadius
        real expectedDamage  // For combo targeting logic

        static method create takes integer aid, real cd, integer inCastType, string order, integer mana, real inCastRange, integer inFindTargetType, real inEffectiveRadius, integer inComboIndex, real inExpectedDamage returns thistype
            local thistype this = thistype.allocate()
            set this.abilityId = aid
            set this.baseCooldown = cd
            set this.castType = inCastType
            set this.lastCastTime = 0.0
            set this.comboIndex = inComboIndex
            set this.orderString = order
            set this.manaCost = mana
            set this.castRange = inCastRange
            set this.findTargetType = inFindTargetType
            set this.effectiveRadius = inEffectiveRadius
            set this.expectedDamage = inExpectedDamage
        
            return this
        endmethod

        method isCooldownReady takes integer difficulty returns boolean
            local real currentTime = TimerGetElapsed(gameTimer)
            local real requiredCooldown 
            local real cooldownMultiplier = GetCooldownMultiplier(difficulty)
            if this.lastCastTime == 0.0 then
                return true
            endif
            set requiredCooldown = this.baseCooldown * cooldownMultiplier
            if currentTime >= this.lastCastTime + requiredCooldown then
                return true
            endif
            return false
        endmethod


        method isManaReady takes unit caster returns boolean
            local real currentMana = GetUnitState(caster, UNIT_STATE_MANA)
            if currentMana >= I2R(this.manaCost) then
                return true
            endif
            return false
        endmethod

        method customFilter takes unit u returns boolean
            // Custom filtering logic for specific abilities
            if this.abilityId == 'A00W' then  // Banish ability
                if UnitHasBuffBJ(u, 'BHbn') then
                    call BotLog("Skipping banish target, already banished, unit: " + GetUnitName(u))
                    return false
                endif
            endif
            return true
        endmethod

        
        method destroy takes nothing returns nothing
            call this.deallocate()
        endmethod
    endstruct

    struct HeroCombatData
        AIHeroAbility array abilities[MAX_ABILITIES_PER_HERO]
        integer abilityCount
        real comboExpectedDamage
        real comboOverkillThresholdPercent
        AIItem array items[MAX_ITEM_PER_HERO]
        AIHero ownerAIHero

        
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.abilityCount = 0
            set this.comboExpectedDamage = 0.0
            set this.comboOverkillThresholdPercent = 0.3 // Default to 30% of combo damage
            return this
        endmethod
        
        method addAbility takes integer abilityId, real cooldown, integer castType, string orderString, integer manaCost, real castRange, integer findTargetType, real effectiveRadius, integer comboIndex, real expectedDamage returns nothing
            if this.abilityCount < MAX_ABILITIES_PER_HERO then
                set this.abilities[this.abilityCount] = AIHeroAbility.create(abilityId, cooldown, castType, orderString, manaCost, castRange, findTargetType, effectiveRadius, comboIndex, expectedDamage)
                if comboIndex > 0 then
                    set this.comboExpectedDamage = this.comboExpectedDamage + this.abilities[this.abilityCount].expectedDamage
                endif
                set this.abilityCount = this.abilityCount + 1
            else
                // Exceeded max abilities - handle error as needed
                call this.botLogError("Exceeded max abilities for hero combat data.")
            endif
        endmethod

        method addItem takes item newItemHandle, integer itemId, real baseCooldown, real castRange, unit ownerHero, boolean isPassive returns nothing
            local integer i = 0
            loop
                exitwhen i >= MAX_ITEM_PER_HERO
                if this.items[i] == null then
                    set this.items[i] = AIItem.create(newItemHandle, itemId, baseCooldown, castRange, ownerHero, isPassive)
                    return
                endif
                set i = i + 1
            endloop
            // Exceeded max items - handle error as needed
            call this.botLogError("Exceeded max items for hero combat data.")
        endmethod
        
        method removeItem takes item itemHandle returns nothing
            local integer i = 0
            loop
                exitwhen i >= MAX_ITEM_PER_HERO
                if this.items[i] != null then
                    if this.items[i].itemHandle == itemHandle then
                        call this.items[i].destroy()
                        set this.items[i] = 0
                        return
                    endif
                endif
                set i = i + 1
            endloop
            // Item not found - handle error as needed
            call this.botLogError("Item not found in hero combat data for removal.")
        endmethod
        
        method destroy takes nothing returns nothing
            local integer i = 0
            loop
                exitwhen i >= this.abilityCount
                call this.abilities[i].destroy()
                set i = i + 1
            endloop
            loop
                exitwhen i >= MAX_ITEM_PER_HERO
                if this.items[i] != null then
                    call this.items[i].destroy()
                endif
                set i = i + 1
            endloop
            call this.deallocate()
        endmethod

        method getAbilityByComboIndex takes integer comboIndex returns AIHeroAbility
            local integer i = 0
            loop
                exitwhen i >= this.abilityCount
                if this.abilities[i].comboIndex == comboIndex then
                    return this.abilities[i]
                endif
                set i = i + 1
            endloop
            return 0
        endmethod

        method hasReadyAbility takes unit hero, integer difficulty returns boolean
            local AIHeroAbility heroAbil = this.getReadyAbility(hero, difficulty)
            if heroAbil != 0 then
                return true
            endif
            return false
        endmethod

        method getReadyAbility takes unit hero, integer difficulty returns AIHeroAbility
            local integer i = 0
            local AIHeroAbility heroAbil
            local real currentMana
            local boolean bCheckCombo = IsApplyingCombo(difficulty)
            local AIHero aiHero = GetAIHeroFromUnit(hero)

            if bCheckCombo then
                // Check for combo abilities starting from index 1
                set heroAbil = this.getAbilityByComboIndex(1)
                if heroAbil != 0 then
                    // Exist any combo ability
                    // If combo ability cooldown are ready, prioritize them
                    if this.areComboAbilityCooldownReady(hero, difficulty, aiHero.currentComboIndex) then
                        // Check if we have enough mana for combo
                        if this.hasEnoughManaForCombo(hero, aiHero.currentComboIndex) then
                            // Cooldown ready and enough mana - proceed with combo
                            set heroAbil = this.getReadyComboAbility(hero, difficulty, aiHero.currentComboIndex)
                            if heroAbil != 0 then
                                return heroAbil
                            endif
                        else
                            // Cooldown ready but not enough mana - don't fallback to non-combo abilities, prioritize mana waiting
                            return 0
                        endif
                    endif
                    // If combo cooldown are not ready, continue to check non-combo abilities
                endif
            endif

            // Check if any ability is ready for combat based on difficulty
            loop
                exitwhen i >= this.abilityCount
                set heroAbil = this.abilities[i]
                
                if bCheckCombo and heroAbil.comboIndex > 0 then
                    // Skip combo abilities if not checking for combos
                else
                    // Check cooldown (skip for first-time cast)
                    if heroAbil.isCooldownReady(difficulty) then
                        // Check if ability is available
                        if GetUnitAbilityLevel(hero, heroAbil.abilityId) <= 0 then
                            call this.botLogError("Ability not available: " + heroAbil.orderString)
                        else
                            // Check if hero has enough mana
                            set currentMana = GetUnitState(hero, UNIT_STATE_MANA)
                            if not heroAbil.isManaReady(hero) then
                                call this.botLog("Not enough mana for ability. Need: " + I2S(heroAbil.manaCost) + ", Have: " + I2S(R2I(currentMana)))
                                call aiHero.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - No Mana" + "(" + I2S(heroAbil.manaCost) + "/" + I2S(R2I(currentMana)) + ")")
                                call aiHero.setDebugTextTagColorPreset("RED")
                            else
                                return heroAbil
                            endif
                        endif
                    endif
                endif
                set i = i + 1
            endloop

            return 0
        endmethod

        method getReadyComboAbility takes unit hero, integer difficulty, integer startingComboIndex returns AIHeroAbility
            local integer i = startingComboIndex
            local AIHeroAbility heroAbil
            local AIHeroAbility resultComboAbility = 0
            local AIHero aiHero = GetAIHeroFromUnit(hero)
            if aiHero == 0 then
                call this.botLogError("AIHero not found for unit in getReadyComboAbility.")
                return 0
            endif


            // Check if a sequence of combo abilities are ready
            loop
                set heroAbil = this.getAbilityByComboIndex(i)
                // Reach end of combo sequence
                exitwhen heroAbil == 0
                
                // Check cooldown
                if not heroAbil.isCooldownReady(difficulty) then
                    call this.botLog("Ability cooldown not ready for combo: " + heroAbil.orderString)
                    call aiHero.setDebugTextTagContent("Combat: Combo CD Not Ready " + heroAbil.orderString)
                    call aiHero.setDebugTextTagColorPreset("RED")
                    return 0
                endif
                
                // Check if ability is available
                if GetUnitAbilityLevel(hero, heroAbil.abilityId) <= 0 then
                    call this.botLogError("Ability not available for combo: " + heroAbil.orderString)
                    return 0
                endif
                
                if i == aiHero.currentComboIndex then
                    set resultComboAbility = heroAbil
                    call this.botLog("Found ready combo ability at comboIndex " + I2S(i) + ": " + heroAbil.orderString)
                    call aiHero.setDebugTextTagContent("Combat: Found Combo Ability " + heroAbil.orderString)
                    call aiHero.setDebugTextTagColorPreset("RED")
                endif
                set i = i + 1
            endloop

            if not this.hasEnoughManaForCombo(hero, startingComboIndex) then
                call this.botLog("Not enough mana for remaining combo abilities from index " + I2S(startingComboIndex))
                return 0
            endif

            call this.botLog("Combo abilities ready, returning ability: " + resultComboAbility.orderString)
            call aiHero.setDebugTextTagContent("Combat: Combo Ability Ready " + resultComboAbility.orderString)
            call aiHero.setDebugTextTagColorPreset("RED")

            return resultComboAbility
        endmethod

        method hasEnoughManaForCombo takes unit hero, integer currentComboIndex returns boolean
            local real currentMana = GetUnitState(hero, UNIT_STATE_MANA)
            local real requiredMana = 0.0
            local integer i = currentComboIndex
            local AIHeroAbility heroAbil
            local AIHero aiHero = GetAIHeroFromUnit(hero)
            
            // Calculate mana cost for remaining combo abilities from currentComboIndex
            loop
                set heroAbil = this.getAbilityByComboIndex(i)
                // Reach end of combo sequence
                exitwhen heroAbil == 0
                
                set requiredMana = requiredMana + heroAbil.manaCost
                set i = i + 1
            endloop
            
            if currentMana >= requiredMana then
                return true
            endif
            call this.botLog("Not enough mana for remaining combo. (" + I2S(R2I(currentMana)) + "/" + I2S(R2I(requiredMana)) + ")")
            call aiHero.setDebugTextTagContent("Combat: No Mana, (" + I2S(R2I(currentMana)) + "/" + I2S(R2I(requiredMana)) + ")")
            call aiHero.setDebugTextTagColorPreset("RED")
            return false
        endmethod

        method areComboAbilityCooldownReady takes unit hero, integer difficulty, integer currentComboIndex returns boolean
            local integer i = currentComboIndex
            local AIHeroAbility heroAbil
            
            // Check if combo abilities have their cooldowns ready (starting from currentComboIndex)
            loop
                set heroAbil = this.getAbilityByComboIndex(i)
                // Reach end of combo sequence
                exitwhen heroAbil == 0
                
                // Check cooldown
                if not heroAbil.isCooldownReady(difficulty) then
                    return false
                endif
                
                // Check if ability is available
                if GetUnitAbilityLevel(hero, heroAbil.abilityId) <= 0 then
                    return false
                endif
                
                set i = i + 1
            endloop
            
            // All remaining combo abilities have cooldowns ready
            return true
        endmethod

        method hasReadyItem takes nothing returns boolean
            local AIItem heroItem = this.getReadyItem()
            if heroItem != 0 then
                return true
            endif
            return false
        endmethod

        method getReadyItem takes nothing returns AIItem
            local integer i = 0
            local AIItem heroItem
            local real currentMana
            local unit ownerHero = ownerAIHero.hero

            if ownerHero == null then
                call this.botLogError("Owner hero is null in getReadyItem.")
                return 0
            endif

            // Check if any item is ready for use
            loop
                exitwhen i >= MAX_ITEM_PER_HERO
                set heroItem = this.items[i]
                if heroItem != 0 then
                    if not UnitHasItem(ownerHero, heroItem.itemHandle) then
                        call this.removeItem(heroItem.itemHandle)
                    else
                        if heroItem.isReadyToUse() then
                            return heroItem
                        endif
                    endif
                endif
                set i = i + 1
            endloop

            return 0
        endmethod

        method botLog takes string msg returns nothing
            call BotLogWithPlayer(GetOwningPlayer(ownerAIHero.hero), msg)
        endmethod

        method botLogError takes string msg returns nothing
            call BotLogErrorWithPlayer(GetOwningPlayer(ownerAIHero.hero), msg)
        endmethod

    endstruct


    struct AIState 
        integer stateID
        AIHero owner
        
        method botLog takes string msg returns nothing
            call BotLogWithPlayer(GetOwningPlayer(owner.hero), msg)
        endmethod
        
        method botLogError takes string msg returns nothing
            call BotLogErrorWithPlayer(GetOwningPlayer(owner.hero), msg)
        endmethod
        
        stub method onEnter takes nothing returns nothing
            // Placeholder for state entry logic
        endmethod
        stub method onUpdate takes nothing returns nothing
            // Placeholder for timer callbackj
        endmethod
        stub method onExit takes nothing returns nothing
            // Placeholder for state exit logic
        endmethod

        stub method destroy takes nothing returns nothing
            call this.deallocate()
        endmethod
    endstruct

    struct RunState extends AIState
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_RUN
            return this
        endmethod

        method onEnter takes nothing returns nothing
            call this.botLog("Entering Run State")
            call owner.setDebugTextTagContent("Run: Entering")
            call owner.setDebugTextTagColorPreset("GREEN")
            call owner.moveToNextWaypoint()
        endmethod


        method onUpdate takes nothing returns nothing
            local rect currentWaypointArea 
            local real heroX 
            local real heroY 
            local real targetX
            local real targetY
            local integer currentOrder
            local unit blockingUnit
            local boolean hasBlockingUnitAhead
            local boolean hasBlockingUnitBehind
            local real blockDetectRadius = 100.0
            
            // Safety check - ensure hero is alive
            if not IsUnitAliveBJ(owner.hero) then
                return
            endif
            
            // call this.botLog("Updating Run State, waypoint index: " + I2S(owner.currentWaypointIndex))
            call owner.setDebugTextTagContent("Run: Updating, WPI " + I2S(owner.currentWaypointIndex))
            call owner.setDebugTextTagColorPreset("GREEN")
            
            
            set currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
            set heroX = GetUnitX(owner.hero)
            set heroY = GetUnitY(owner.hero)
            set currentOrder = GetUnitCurrentOrder(owner.hero)
            
            // Check if hero has reached the current waypoint area
            if RectContainsCoords(currentWaypointArea, heroX, heroY) then
                call this.botLog("Reached waypoint " + I2S(owner.currentWaypointIndex))
                call owner.setDebugTextTagContent("Run: Reached Waypoint " + I2S(owner.currentWaypointIndex))
                call owner.setDebugTextTagColorPreset("GREEN")
                if owner.currentWaypointIndex >= WaypointCount then
                    call this.botLog("Reached final waypoint")
                    call owner.setDebugTextTagContent("Run: Reached Final Waypoint")
                    call owner.setDebugTextTagColorPreset("GREEN")
                    // TODO Goaled State
                else
                    // Move to next waypoint
                    set owner.currentWaypointIndex = (owner.currentWaypointIndex + 1)
                endif
                
                // Move to the new waypoint
                call owner.moveToNextWaypoint()
                return
            elseif currentOrder == 0 then
                // Hero is idle (no current order) - reissue move command to current waypoint
                call this.botLog("Hero is idle, reissuing move command")
                call owner.setDebugTextTagContent("Run: Reissuing Move Command")
                call owner.setDebugTextTagColorPreset("GREEN")
                call owner.moveToNextWaypoint()
            endif
            
            // Check for spike hazards first (highest priority, only between waypoints 7-8)
            if owner.shouldEnterHazardState() then
                call this.botLog("Spike hazard detected - entering spike dodge state")
                call owner.changeState(HazardState.create())
                return
            endif

            call owner.searchPickupItemAround()
            if owner.shouldEnterPickupItemState() then
                call this.botLog("Pickup item detected - entering pickup item state")
                call owner.setDebugTextTagContent("Run: Entering Pickup Item")
                call owner.setDebugTextTagColorPreset("CYAN")
                call owner.changeState(PickUpItemState.create())
                return
            endif
            
            // Check if we should enter combat state
            if owner.shouldEnterCombat() then
                call this.botLog("Entering combat - abilities ready")
                call owner.setDebugTextTagContent("Run: Entering Combat")
                call owner.setDebugTextTagColorPreset("GREEN")
                call owner.changeState(CombatState.create())
                return
            endif

            // Check for blocking units ahead
            set blockingUnit = this.getBlockingUnitAround(blockDetectRadius, false)
            set hasBlockingUnitAhead = blockingUnit != null
            if hasBlockingUnitAhead then
                call this.botLog("Blocking unit detected ahead, dodging")
                call owner.setDebugTextTagContent("Run: Dodging Blocking Unit Ahead")
                call owner.setDebugTextTagColorPreset("YELLOW")
                call owner.avoidTargetUnitAhead(blockingUnit, GetUnitMoveSpeed(blockingUnit) * 0.1, 2.0, true)
                return
            endif
            // Check for blocking units behind
            set blockingUnit = this.getBlockingUnitAround(blockDetectRadius, true)
            set hasBlockingUnitBehind = blockingUnit != null
            if hasBlockingUnitBehind then
                call this.botLog("Blocking unit detected behind, dodging")
                call owner.setDebugTextTagContent("Run: Dodging Blocking Unit Behind")
                call owner.setDebugTextTagColorPreset("YELLOW")
                call owner.avoidTargetUnitBehind(blockingUnit, false, 2.0, true)
                return
            endif

            set currentWaypointArea = null
        endmethod

        method onExit takes nothing returns nothing
            call this.botLog("Exiting Run State")
            call owner.setDebugTextTagContent("Run: Exiting")
            call owner.setDebugTextTagColorPreset("GREEN")
        endmethod

        method getBlockingUnitAround takes real detectRadius, boolean bCheckBehind returns unit
            local group blockingUnitGroup = CreateGroup()
            local unit u // for enumerating units
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            local unit resultUnit = null
            local boolexpr filter = Filter(function AntiLeak)
            local real closestDistance = 99999.0
            local real currentTargetDistance
            
            call GroupEnumUnitsInRange(blockingUnitGroup, heroX, heroY, detectRadius, filter)
            loop
                set u = FirstOfGroup(blockingUnitGroup)
                exitwhen u == null

                call GroupRemoveUnit(blockingUnitGroup, u)
                if this.checkBlockingUnit(u, bCheckBehind) then
                    set currentTargetDistance = DistanceBetweenXY(heroX, heroY, GetUnitX(u), GetUnitY(u))
                    if currentTargetDistance < closestDistance then
                        set closestDistance = currentTargetDistance
                        set resultUnit = u
                    endif
                endif
            endloop
            call DestroyGroup(blockingUnitGroup)
            
            return resultUnit
        endmethod

        method checkBlockingUnit takes unit u, boolean bCheckBehind returns boolean
            if u == owner.hero then
                return false
            endif
            if not IsUnitValid(u) then
                return false
            endif
            if bCheckBehind then
                if IsUnitInFrontOfUnit(u, owner.hero) then
                    return false
                endif
            else
                if not IsUnitInFrontOfUnit(u, owner.hero) then
                    return false
                endif
            endif
            call owner.botLog("Blocking unit found: " + GetUnitName(u))
            return true
        endmethod

    endstruct

    struct DeadState extends AIState
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_DEAD
            return this
        endmethod

        method onEnter takes nothing returns nothing
            call this.botLog("Hero died - Entering Dead State")
            call owner.setDebugTextTagContent("Dead: Entering")
            call owner.setDebugTextTagColorPreset("GRAY")
            call IssueImmediateOrder(owner.hero, "stop")
        endmethod

        method onUpdate takes nothing returns nothing
            if not IsUnitAliveBJ(owner.hero) then
                return
            endif
            
            call this.botLog("Hero revived - Returning to Run State")
            call owner.setDebugTextTagContent("Dead: Revived")
            call owner.setDebugTextTagColorPreset("GRAY")
            call owner.changeState(RunState.create())
        endmethod

        method onExit takes nothing returns nothing
            call this.botLog("Exiting Dead State")
            call owner.setDebugTextTagContent("Dead: Exiting")
            call owner.setDebugTextTagColorPreset("GRAY")
        endmethod
    endstruct

    struct HazardState extends AIState
        integer hazardType  // 0 = Spike, 1 = Net, etc.
        boolean bIsGoingThroughFastSpike = false

        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_HAZARD
            return this
        endmethod

        method onEnter takes nothing returns nothing
            if IsInSlowSpikeHazardZone(owner) then
                set this.hazardType = HAZARD_TYPE_SLOW_SPIKE
                call this.botLog("Detected Slow Spike Hazard Zone")
                call owner.setDebugTextTagContent("Hazard: Slow Spike Zone")
                call owner.setDebugTextTagColorPreset("ORANGE")
            elseif IsInFastSpikeHazardZone(owner) then
                set this.hazardType = HAZARD_TYPE_FAST_SPIKE
                call this.botLog("Detected Fast Spike Hazard Zone")
                call owner.setDebugTextTagContent("Hazard: Fast Spike Zone")
                call owner.setDebugTextTagColorPreset("ORANGE")
            elseif IsInNetHazardZone(owner) then
                set this.hazardType = HAZARD_TYPE_NET
                call this.botLog("Detected Net Hazard Zone")
                call owner.setDebugTextTagContent("Hazard: Net Zone")
                call owner.setDebugTextTagColorPreset("ORANGE")
            elseif IsInSpiderNetHazardZone(owner) then
                set this.hazardType = HAZARD_TYPE_SPIDER_NET
                call this.botLog("Detected Spider Net Hazard Zone")
                call owner.setDebugTextTagContent("Hazard: Spider Net Zone")
                call owner.setDebugTextTagColorPreset("ORANGE")
            else
                // Other hazard types can be added here
                call this.botLogError("Unknown hazard type detected!")
            endif
        endmethod
        
        method onUpdate takes nothing returns nothing
            if not IsUnitAliveBJ(owner.hero) then
                return
            endif

            call owner.searchPickupItemAround()
            if owner.shouldEnterPickupItemState() then
                call this.botLog("Pickup item detected - entering pickup item state")
                call owner.setDebugTextTagContent("Hazard: Entering Pickup Item")
                call owner.setDebugTextTagColorPreset("CYAN")
                call owner.changeState(PickUpItemState.create())
                return
            endif

            if this.hazardType == HAZARD_TYPE_SLOW_SPIKE then
                call this.onSlowSpikeHazardZoneUpdate()
            elseif this.hazardType == HAZARD_TYPE_FAST_SPIKE then
                call this.onFastSpikeHazardZoneUpdate()
            elseif this.hazardType == HAZARD_TYPE_NET then
                call this.onNetHazardZoneUpdate()
            elseif this.hazardType == HAZARD_TYPE_SPIDER_NET then
                call this.onSpiderNetHazardZoneUpdate()
            else
                call this.botLogError("Unknown hazard type in update!")
            endif
        endmethod
        
        method onSlowSpikeHazardZoneUpdate takes nothing returns nothing
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            local real avoidanceDetectRadiusBase = 150
            local real slowSpikeRadius = SLOW_SPIKE_RADIUS
            local real avoidanceDetectRadius = avoidanceDetectRadiusBase + slowSpikeRadius
            local boolean hasSlowSpikeAhead = false
            local boolean hasSlowSpikeBehind = false
            local unit slowSpikeUnit = null
            local rect currentWaypointArea
            call this.botLog("onSlowSpikeHazardZoneUpdate")

            set currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
            
            // Check if hero has reached the current waypoint area
            if RectContainsCoords(currentWaypointArea, heroX, heroY) then
                call owner.changeState(RunState.create())
                return
            endif

            if IsUnitInvulnerableOrMagicImmune(owner.hero) then
                call this.botLog("Hero is invulnerable or magic immune, skipping spike avoidance")
                call owner.setDebugTextTagContent("Hazard: Magic Immune - No Dodge")
                call owner.setDebugTextTagColorPreset("ORANGE")
                return
            endif

            // check ahead
            set slowSpikeUnit = this.getHazardAround(avoidanceDetectRadius, false, SLOW_SPIKE_UNIT_TYPE_ID, SLOW_SPIKE_SPEED, SLOW_SPIKE_RADIUS)
            set hasSlowSpikeAhead = slowSpikeUnit != null

            // detect slow spike ahead within certain radius
            if hasSlowSpikeAhead then
                call this.botLog("Slow Spike detected ahead, issuing dodge maneuver")
                call owner.setDebugTextTagContent("Hazard: Dodging Slow Spike Ahead")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call owner.avoidTargetUnitAhead(slowSpikeUnit, SLOW_SPIKE_SPEED, 1.0, false)
                return
            else 
                // check behind
                set slowSpikeUnit = this.getHazardAround(avoidanceDetectRadius, true, SLOW_SPIKE_UNIT_TYPE_ID, SLOW_SPIKE_SPEED, SLOW_SPIKE_RADIUS)
                set hasSlowSpikeBehind = slowSpikeUnit != null
                if hasSlowSpikeBehind then
                    call this.botLog("Slow Spike detected behind, issuing dodge maneuver")
                    call owner.setDebugTextTagContent("Hazard: Dodging Slow Spike Behind")
                    call owner.setDebugTextTagColorPreset("ORANGE")
                    call owner.avoidTargetUnitBehind(slowSpikeUnit, true, 1.0, false)
                    return
                endif
            endif

            // No more spikes around, keep moving to next waypoint
            call this.botLog("No Slow Spikes")
            call owner.moveToNextWaypoint()
        endmethod

        method checkHazardUnit takes unit u, boolean bCheckBehind, integer checkingUnitTypeId, real checkingUnitMoveSpeed, real hazardHitRadius returns boolean
            local real targetUnitX = GetUnitX(u)
            local real targetUnitY = GetUnitY(u)
            local real targetMoveSpeed = checkingUnitMoveSpeed
            local real targetUnitMovingAngle = GetUnitFacing(u)
            local real predictedTargetUnitX = targetUnitX + targetMoveSpeed * UPDATE_PERIOD * Cos(targetUnitMovingAngle * bj_DEGTORAD)
            local real predictedTargetUnitY = targetUnitY + targetMoveSpeed * UPDATE_PERIOD * Sin(targetUnitMovingAngle * bj_DEGTORAD)
            local real ownerHeroX = GetUnitX(owner.hero)
            local real ownerHeroY = GetUnitY(owner.hero)

            // Aloc is Locus ability
            if GetUnitTypeId(u) == checkingUnitTypeId and GetUnitAbilityLevel(u, 'Aloc') > 0 then
                if not bCheckBehind then
                    if IsUnitInFrontOfUnit(u, owner.hero) then
                        if not IsUnitInRangeXY(u, ownerHeroX, ownerHeroY, hazardHitRadius) then
                            call this.botLog("hazard unit detected ahead and within avoidance range.")
                            return true
                        else
                            call this.botLog("hazard unit detected ahead but too close to dodge.")
                        endif
                    endif
                else
                    if not IsUnitInFrontOfUnit(u, owner.hero) then
                        if not IsUnitInRangeXY(u, ownerHeroX, ownerHeroY, hazardHitRadius) then
                            call this.botLog("hazard unit detected behind and within avoidance range.")
                            return true
                        else
                            call this.botLog("hazard unit detected behind but too close to dodge.")
                        endif
                    endif
                endif
            endif
            return false
        endmethod

        method getHazardAround takes real detectRadius, boolean bCheckBehind, integer hazardUnitTypeId, real hazardUnitMoveSpeed, real hazardHitRadius returns unit
            local group spikeGroup = CreateGroup()
            local unit u
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            local unit resultUnit = null
            local boolexpr filter = Filter(function AntiLeak)
            local real closestDistance = 99999.0
            local real currentTargetDistance
            
            // Detect locus unit must use GroupEnumUnitsOfPlayer for Player(11)
            call GroupEnumUnitsOfPlayer(spikeGroup, Player(11), filter) 
            loop
                set u = FirstOfGroup(spikeGroup)
                exitwhen u == null

                call GroupRemoveUnit(spikeGroup, u)
                if IsUnitInRangeXY(u, heroX, heroY, detectRadius)  then
                    if this.checkHazardUnit(u, bCheckBehind, hazardUnitTypeId, hazardUnitMoveSpeed, hazardHitRadius) then
                        set currentTargetDistance = DistanceBetweenXY(heroX, heroY, GetUnitX(u), GetUnitY(u))
                        if currentTargetDistance < closestDistance then
                            set closestDistance = currentTargetDistance
                            set resultUnit = u
                        endif
                    endif
                endif
            endloop
            call DestroyGroup(spikeGroup)
            
            return resultUnit
        endmethod

        method onFastSpikeHazardZoneUpdate takes nothing returns nothing
            local integer currentOrder
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            local rect currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]

            if not IsTriggerEnabled(gg_trg_FastSpike) then
                call this.botLog("Fast Spike trigger is disabled, skipping hazard handling")
                call owner.setDebugTextTagContent("Hazard: Fast Spike Trigger Disabled")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call owner.moveToNextWaypoint()
                call owner.changeState(RunState.create())
                return
            endif

            // Check if hero has reached the current waypoint area
            if RectContainsCoords(currentWaypointArea, heroX, heroY) then
                call owner.changeState(RunState.create())
                return
            endif

            if this.bIsGoingThroughFastSpike then
                set currentOrder = GetUnitCurrentOrder(owner.hero)
                if currentOrder == 0 then
                    // Hero is idle (no current order) - reissue move command to current waypoint
                    call this.botLog("Hero is idle, reissuing move command")
                    call owner.setDebugTextTagContent("Hazard: Reissuing Move Command")
                    call owner.setDebugTextTagColorPreset("ORANGE")
                    call owner.moveToNextWaypoint()
                endif
                return
            endif

            if udg_bShouldBotGoFastSpike then
                set bIsGoingThroughFastSpike = true
                call this.botLog("Fast Spike hazard - going through quickly")
                call owner.setDebugTextTagContent("Hazard: Fast Spike - Going Through")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call owner.moveToNextWaypoint()
            else
                call this.botLog("Fast Spike hazard - waiting to proceed")
                call owner.setDebugTextTagContent("Hazard: Fast Spike - Waiting")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call IssueImmediateOrder(owner.hero, "stop")
            endif
        endmethod

        method onNetHazardZoneUpdate takes nothing returns nothing
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            local real avoidanceDetectRadiusBase = 150
            local real netRadius = NET_RADIUS
            local real avoidanceDetectRadius = avoidanceDetectRadiusBase + netRadius
            local boolean hasNetAhead = false
            local boolean hasNetBehind = false
            local unit netUnit = null
            local rect currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]


            if not IsTriggerEnabled(gg_trg_Net01) then
                call this.botLog("Net trigger is disabled, skipping hazard handling")
                call owner.setDebugTextTagContent("Hazard: Net Trigger Disabled")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call owner.moveToNextWaypoint()
                call owner.changeState(RunState.create())
                return
            endif

            // Check if hero has reached the current waypoint area
            if RectContainsCoords(currentWaypointArea, heroX, heroY) then
                call owner.changeState(RunState.create())
                return
            endif

            if IsUnitInvulnerableOrMagicImmune(owner.hero) then
                call this.botLog("Hero is invulnerable or magic immune, skipping spike avoidance")
                call owner.setDebugTextTagContent("Hazard: Magic Immune - No Dodge")
                call owner.setDebugTextTagColorPreset("ORANGE")
                return
            endif

            // check ahead
            set netUnit = this.getHazardAround(avoidanceDetectRadius, false, NET_UNIT_TYPE_ID, NET_SPEED, NET_RADIUS)
            set hasNetAhead = netUnit != null

            // detect net ahead within certain radius
            if hasNetAhead then
                call this.botLog("Net detected ahead, issuing dodge maneuver")
                call owner.setDebugTextTagContent("Hazard: Dodging Net Ahead")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call owner.avoidTargetUnitAhead(netUnit, NET_SPEED, 1.0, false)
                return
            else 
                // check behind
                set netUnit = this.getHazardAround(avoidanceDetectRadius, true, NET_UNIT_TYPE_ID, NET_SPEED, NET_RADIUS)
                set hasNetBehind = netUnit != null
                if hasNetBehind then
                    call this.botLog("Net detected behind, issuing dodge maneuver")
                    call owner.setDebugTextTagContent("Hazard: Dodging Net Behind")
                    call owner.setDebugTextTagColorPreset("ORANGE")
                    call owner.avoidTargetUnitBehind(netUnit, true, 1.0, false)
                    return
                endif
            endif

            // No more net around, keep moving to next waypoint
            call this.botLog("No Nets")
            call owner.moveToNextWaypoint()
        endmethod

        method onSpiderNetHazardZoneUpdate takes nothing returns nothing
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            local real avoidanceDetectRadiusBase = 100
            local real netRadius = SPIDER_NET_RADIUS
            local real avoidanceDetectRadius = avoidanceDetectRadiusBase + netRadius
            local boolean hasNetAhead = false
            local boolean hasNetBehind = false
            local unit netUnit = null
            local rect currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
            local boolean isNetInvisible = false

            // Check if hero has reached the current waypoint area
            if not IsInSpiderNetHazardZone(owner) then
                call owner.changeState(RunState.create())
                return
            endif

            if IsUnitInvulnerableOrMagicImmune(owner.hero) then
                call this.botLog("Hero is invulnerable or magic immune, skipping spike avoidance")
                call owner.setDebugTextTagContent("Hazard: Magic Immune - No Dodge")
                call owner.setDebugTextTagColorPreset("ORANGE")
                return
            endif

            // check ahead
            set netUnit = this.getHazardAround(avoidanceDetectRadius, false, SPIDER_NET_UNIT_TYPE_ID, 0, SPIDER_NET_RADIUS)
            if netUnit != null then
                set isNetInvisible = GetUnitAbilityLevel(netUnit, 'Apiv') > 0
            endif
            set hasNetAhead = netUnit != null and not isNetInvisible

            // detect net ahead within certain radius
            if hasNetAhead then
                call this.botLog("Spider Net detected ahead, issuing dodge maneuver")
                call owner.setDebugTextTagContent("Hazard: Dodging Spider Net Ahead")
                call owner.setDebugTextTagColorPreset("ORANGE")
                call owner.avoidTargetUnitAhead(netUnit, 0, 1.0, false)
                return
            else 
                // check behind
                set netUnit = this.getHazardAround(avoidanceDetectRadius, true, SPIDER_NET_UNIT_TYPE_ID, 0, SPIDER_NET_RADIUS)
                if netUnit != null then
                    set isNetInvisible = GetUnitAbilityLevel(netUnit, 'Apiv') > 0
                endif
                set hasNetBehind = netUnit != null and not isNetInvisible
                if hasNetBehind then
                    call this.botLog("Spider Net detected behind, issuing dodge maneuver")
                    call owner.setDebugTextTagContent("Hazard: Dodging Spider Net Behind")
                    call owner.setDebugTextTagColorPreset("ORANGE")
                    call owner.avoidTargetUnitBehind(netUnit, true, 1.0, false)
                    return
                endif
            endif

            // No more spider net around, keep moving to next waypoint
            call owner.moveToNextWaypoint()

        endmethod


        method onExit takes nothing returns nothing
            call this.botLog("Exiting Slow Spike Hazard State")
            call owner.setDebugTextTagContent("Hazard: Slow Spike Exiting")
            call owner.setDebugTextTagColorPreset("ORANGE")
        endmethod


    endstruct

    struct CombatState extends AIState
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_COMBAT
            return this
        endmethod

        method onEnter takes nothing returns nothing
            call this.botLog("Entering Combat State")
            call owner.setDebugTextTagContent("Combat: Entering")
            call owner.setDebugTextTagColorPreset("RED")
        endmethod

        method onUpdate takes nothing returns nothing
            local real currentTime = TimerGetElapsed(gameTimer)
            local integer difficulty = owner.difficulty
            local boolean isCastOvertime = currentTime > owner.lastStartCastTime + owner.castPt + TURN_TIME // Turn Time and Pre-swing 
            local boolean isCastFailed = owner.isCasting and isCastOvertime

            if isCastFailed then
                call this.botLog("Casting failed or interrupted, resetting casting state")
                call owner.setDebugTextTagContent("Combat: Cast Failed " + owner.castingAbility.orderString)
                call owner.setDebugTextTagColorPreset("RED")
                set owner.isCasting = false
                set owner.castingAbility = 0
            endif

            if owner.isCasting then
                call this.botLog("Currently casting an ability, skipping update")
                call owner.setDebugTextTagContent("Combat: Casting " + owner.castingAbility.orderString)
                call owner.setDebugTextTagColorPreset("RED")
                return
            endif

            // Safety check - ensure hero is alive
            if not IsUnitAliveBJ(owner.hero) then
                return
            endif

            // Use Item
            if this.tryUseItem() then
                return
            endif
            
            if difficulty == DIFF_EASY then
                if this.tryExecuteEasyCombat() then
                    // Successfully cast an ability
                    return
                endif
            elseif difficulty == DIFF_NORMAL then
                if this.tryExecuteNormalCombat() then
                    // Successfully cast an ability
                    return
                endif
            else // HARD
                if this.tryExecuteHardCombat() then
                    // Successfully cast an ability
                    return
                endif
            endif
            
            // Return to run state after combat
            call owner.changeState(RunState.create())
        endmethod

        method tryUseItem takes nothing returns boolean
            local AIItem heroItem
            local integer difficulty = owner.difficulty

            if difficulty < DIFF_NORMAL then
                return false
            endif

            set heroItem = owner.combatData.getReadyItem()            
            if heroItem != 0 then
                call owner.setDebugTextTagContent("Combat: Try using item " + GetItemName(heroItem.itemHandle))
                call owner.setDebugTextTagColorPreset("RED")
                call heroItem.tryUse()
                return true
            endif
            
            return false
        endmethod

        method tryExecuteEasyCombat takes nothing returns boolean
            local integer i = 0
            local AIHeroAbility heroAbil
            local real currentTime = TimerGetElapsed(gameTimer)
            local integer difficulty = owner.difficulty
            
            // Cast first available ability with 2x cooldown spacing
            set heroAbil = owner.combatData.getReadyAbility(owner.hero, difficulty)
            if heroAbil != 0 then
                if this.tryCastAbility(heroAbil) then
                    set owner.isCasting = true
                    set owner.castingAbility = heroAbil
                    set owner.lastStartCastTime = currentTime
                    return true
                endif
            endif
            return false
        endmethod

        method tryExecuteNormalCombat takes nothing returns boolean
            return this.tryExecuteEasyCombat()
        endmethod

        method tryExecuteHardCombat takes nothing returns boolean
            // Advanced combat with countering - implement specific logic as needed
            return this.tryExecuteNormalCombat()  // For now, use normal combat
            // TODO: Add counter-casting logic based on enemy states
        endmethod

        method canCastAbility takes AIHeroAbility heroAbil returns boolean
            // Check if hero is stunned or silenced
            if IsUnitStunOrSilence(owner.hero) then
                call this.botLog("Cannot cast ability, hero is stunned or silenced.")
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Stunned/Silenced")
                call owner.setDebugTextTagColorPreset("YELLOW")
                return false
            endif

            // Check if ability is available
            if GetUnitAbilityLevel(owner.hero, heroAbil.abilityId) <= 0 then
                call BotLogError("Ability not available: " + heroAbil.orderString)
                return false
            endif
            
            // Check if hero has enough mana
            if not heroAbil.isManaReady(owner.hero) then
                call this.botLog("Not enough mana for ability: " + heroAbil.orderString)
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Not Enough Mana")
                call owner.setDebugTextTagColorPreset("RED")
                return false
            endif
            
            return true
        endmethod

        method shouldUpdateComboTarget takes AIHeroAbility heroAbil, unit targetUnit returns boolean
            if not IsApplyingCombo(owner.difficulty) then
                return false
            endif
            
            if heroAbil.comboIndex <= 0 then
                return false
            endif
            
            if owner.comboTargetUnit == targetUnit then
                return false
            endif
            
            return true
        endmethod

        method findTargetForAbility takes AIHeroAbility heroAbil returns unit
            local unit targetUnit = null
            
            
            // Find new target based on ability type
            if heroAbil.findTargetType == FIND_TARGET_TYPE_ENEMY_COMBO then
                // Use smart combo targeting for combo abilities, random for others
                if IsApplyingCombo(owner.difficulty) and heroAbil.comboIndex > 0 then
                    if owner.comboTargetUnit != null then
                        // Check if we should use existing combo target
                        set targetUnit = owner.comboTargetUnit
                        call this.botLog("Using existing combo target for combo ability: " + GetUnitName(targetUnit))
                        call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Using Combo Target " + GetUnitName(targetUnit))
                        call owner.setDebugTextTagColorPreset("RED")
                        return targetUnit
                    endif
                    set targetUnit = this.findBestComboTarget(heroAbil.castRange, heroAbil)
                    call this.botLog("Finding best combo target, result: " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Combo Target " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagColorPreset("RED")
                    return targetUnit
                else
                    // Fallback to random enemy hero
                    set targetUnit = this.findRandomEnemyHeroInRange(heroAbil.castRange, heroAbil)
                    call this.botLog("Finding random enemy hero, result: " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Enemy Hero Target " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagColorPreset("RED")
                    return targetUnit
                endif
            endif

            if heroAbil.findTargetType == FIND_TARGET_TYPE_ALLY_SPEED_UP then
                set targetUnit = this.findSpeedUpAllyTargetInRange(heroAbil.castRange, heroAbil)
                call this.botLog("Finding ally hero target, result: " + GetUnitName(targetUnit))
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Ally Hero Target " + GetUnitName(targetUnit))
                call owner.setDebugTextTagColorPreset("RED")
                return targetUnit
            endif

            
            return targetUnit
        endmethod

        method castInstantAbility takes AIHeroAbility heroAbil returns boolean
            call IssueImmediateOrder(owner.hero, heroAbil.orderString)
            call this.botLog("Casting instant ability: " + heroAbil.orderString)
            return true
        endmethod

        method castPointAbility takes AIHeroAbility heroAbil, unit targetUnit returns boolean
            local real heroFacing
            local real offset
            local real targetX
            local real targetY
            
            if targetUnit == null then
                call this.botLog("No target found for point ability: " + heroAbil.orderString)
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - No Target")
                call owner.setDebugTextTagColorPreset("RED")
                return false
            endif
            
            set heroFacing = GetUnitFacing(targetUnit) * bj_DEGTORAD
            set offset = heroAbil.effectiveRadius
            set targetX = GetUnitX(targetUnit) + offset * Cos(heroFacing)
            set targetY = GetUnitY(targetUnit) + offset * Sin(heroFacing) 
            call IssuePointOrder(owner.hero, heroAbil.orderString, targetX, targetY)
            call this.botLog("Casting point target ability in front: " + heroAbil.orderString)
            return true
        endmethod

        method castUnitAbility takes AIHeroAbility heroAbil, unit targetUnit returns boolean
            if targetUnit != null then
                call IssueTargetOrder(owner.hero, heroAbil.orderString, targetUnit)
                call this.botLog("Casting unit target ability: " + heroAbil.orderString)
                return true
            else
                call this.botLog("No target found for unit ability: " + heroAbil.orderString)
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - No Target")
                call owner.setDebugTextTagColorPreset("RED")
                return false
            endif
        endmethod

        method tryCastAbility takes AIHeroAbility heroAbil returns boolean
            local unit targetUnit
            
            call this.botLog("Attempting to cast ability: " + heroAbil.orderString)
            call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString)
            call owner.setDebugTextTagColorPreset("RED")
            
            if not this.canCastAbility(heroAbil) then
                return false
            endif
            
            // Handle instant abilities (no target needed)
            if heroAbil.castType == CAST_INSTANT then
                return this.castInstantAbility(heroAbil)
            endif
            
            // Find target for targeted abilities
            set targetUnit = this.findTargetForAbility(heroAbil)
            
            // Update combo target if needed
            if this.shouldUpdateComboTarget(heroAbil, targetUnit) then
                set owner.comboTargetUnit = targetUnit
            endif
            
            // Execute cast based on type
            if heroAbil.castType == CAST_POINT_ENEMY_FRONT then
                return this.castPointAbility(heroAbil, targetUnit)
            elseif heroAbil.castType == CAST_UNIT then
                return this.castUnitAbility(heroAbil, targetUnit)
            else
                call this.botLogError("Unsupported cast type for ability: " + heroAbil.orderString)
                return false
            endif
        endmethod

        method findNearestEnemy takes nothing returns unit
            // Simple implementation - find first enemy in range
            // TODO: Implement proper enemy detection based on your map's enemy system
            return null  // Placeholder - replace with actual enemy finding logic
        endmethod

        method findRandomHeroInRange takes real range, boolean isForAllies, AIHeroAbility heroAbil returns unit
            local group heroes = CreateGroup()
            local unit randomHero
            
            // Set temp variables for filter function
            set tempHeroOwner = GetOwningPlayer(owner.hero)
            set bTempFilterForAllies = isForAllies
            set tempHeroUnit = owner.hero
            set tempAIHeroAbility = heroAbil
            
            call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterHeroes))
            set randomHero = GroupPickRandomUnit(heroes)
            
            // Clean up
            set tempAIHeroAbility = 0
            call DestroyGroup(heroes)
            set heroes = null
            
            return randomHero
        endmethod

        method findRandomEnemyHeroInRange takes real range, AIHeroAbility heroAbil returns unit
            return this.findRandomHeroInRange(range, false, heroAbil)
        endmethod
        
        method findRandomAllyHeroInRange takes real range, AIHeroAbility heroAbil returns unit
            return this.findRandomHeroInRange(range, true, heroAbil)
        endmethod

        method findSpeedUpAllyTargetInRange takes real range, AIHeroAbility heroAbil returns unit
            local group heroes = CreateGroup()
            local unit currentUnit = null
            local real minHpPercent = 50 
            local unit bestTarget = null
            local real minSpeed = 200.0
            local real maxSpeed = 350.0

            // Not Allowed Target: CCed, In Hazard Zone, Speed <200 or >350
            // Priority Order:
            // 1. HP >= 50%
            // 2. Behind
            // 3. Far from Hero
            // 3. Self

            // Set temp variables for filter function
            set tempHeroOwner = GetOwningPlayer(owner.hero)
            set bTempFilterForAllies = true
            set tempHeroUnit = owner.hero
            set tempAIHeroAbility = heroAbil
            call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterHeroes))

            call this.botLog("group unit count for speed-up ally target: " + I2S(CountUnitsInGroup(heroes)))
            
            loop
                set currentUnit = FirstOfGroup(heroes)
                exitwhen currentUnit == null
                call GroupRemoveUnit(heroes, currentUnit)
                call this.botLog("Evaluating ally unit: " + GetUnitName(currentUnit))
                call this.botLog(" GetUnitLifePercent(currentUnit): " + R2S(GetUnitLifePercent(currentUnit)))
                if not IsUnitStunOrSlow(currentUnit) then
                    if not IsUnitInAnyHazardZone(currentUnit) then
                        if GetUnitMoveSpeed(currentUnit) >= minSpeed and GetUnitMoveSpeed(currentUnit) <= maxSpeed then
                            // Valid Target
                            if bestTarget == null then
                                set bestTarget = currentUnit
                                call this.botLog("New best speed-up ally target: " + GetUnitName(currentUnit))
                            elseif GetUnitLifePercent(currentUnit) >= minHpPercent and GetUnitLifePercent(bestTarget) < minHpPercent then
                                // Current has >=50% HP, best has <50% HP 
                                set bestTarget = currentUnit
                                call this.botLog("New best speed-up ally target based on HP%: " + GetUnitName(currentUnit))
                            elseif bestTarget == owner.hero then
                                if IsUnitBehindUnit(currentUnit, owner.hero) then
                                    // Current is behind, previous best is self
                                    set bestTarget = currentUnit
                                    call this.botLog("New best speed-up ally target based on Position: " + GetUnitName(currentUnit))
                                endif
                            elseif IsUnitInFrontOfUnit(bestTarget, owner.hero) then
                                if IsUnitBehindUnit(currentUnit, owner.hero) then
                                    if currentUnit != owner.hero then
                                        // Current is behind, previous best is in front
                                        set bestTarget = currentUnit
                                        call this.botLog("New best speed-up ally target based on Position: " + GetUnitName(currentUnit))
                                    endif
                                endif
                            elseif DistanceBetweenUnits(owner.hero, currentUnit) > DistanceBetweenUnits(owner.hero, bestTarget) then
                                // Both are in same relative position, choose farther one
                                set bestTarget = currentUnit
                                call this.botLog("New best speed-up ally target based on Distance: " + GetUnitName(currentUnit))
                            endif
                        else
                            call this.botLog(" Ally unit speed out of range, skipping: " + GetUnitName(currentUnit))
                        endif
                    else
                        call this.botLog(" Ally unit is in hazard zone, skipping: " + GetUnitName(currentUnit))
                    endif
                else
                    call this.botLog(" Ally unit is CCed, skipping: " + GetUnitName(currentUnit))
                endif
            endloop

            if IsUnitInFrontOfUnit(bestTarget, owner.hero) then
                set bestTarget = owner.hero
                call this.botLog("Ally unit in front, defaulting to self.")
            endif

            // Clean up
            call DestroyGroup(heroes)
            set heroes = null
            set currentUnit = null
            set tempAIHeroAbility = 0
            set tempHeroUnit = null
            set tempHeroOwner = null

            return bestTarget
        endmethod

        method evaluateComboTarget takes unit currentUnit, unit bestTarget, real bestTargetHp, boolean bestIsKillableTarget, boolean bestIsStunOrSlow, real comboExpectedDamage, real comboMinThreshold returns unit
            local real currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
            local boolean isKillableTarget
            local boolean isStunOrSlow
            
            if currentHp >= comboMinThreshold then
                set isKillableTarget = (currentHp <= comboExpectedDamage)
                set isStunOrSlow = IsUnitStunOrSlow(currentUnit)
            
                if bestTarget == null then
                    return currentUnit
                elseif isStunOrSlow and not bestIsStunOrSlow then
                    return currentUnit
                elseif (isStunOrSlow == bestIsStunOrSlow) then
                    if isKillableTarget and not bestIsKillableTarget then
                        return currentUnit
                    elseif isKillableTarget and bestIsKillableTarget and currentHp > bestTargetHp then
                        return currentUnit
                    elseif not isKillableTarget and not bestIsKillableTarget and currentHp < bestTargetHp then
                        return currentUnit
                    endif
                endif
            endif
            return bestTarget
        endmethod

        method findBestComboTarget takes real range, AIHeroAbility heroAbil returns unit
            local group heroes = CreateGroup()
            local unit currentUnit = null
            local unit bestTarget = null
            local real currentHp
            local real bestTargetHp = 0.0
            local boolean bestIsKillableTarget = false
            local boolean bestIsStunOrSlow = false
            local real comboExpectedDamage = owner.combatData.comboExpectedDamage
            local real comboMinThreshold = comboExpectedDamage * owner.combatData.comboOverkillThresholdPercent
            
            // Set temp variables for filter function
            set tempHeroOwner = GetOwningPlayer(owner.hero)
            set bTempFilterForAllies = false
            set tempHeroUnit = owner.hero
            set tempAIHeroAbility = heroAbil
            call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterHeroes))
            
            // Iterate through filtered enemies to find best target
            loop
                set currentUnit = FirstOfGroup(heroes)
                exitwhen currentUnit == null
                call GroupRemoveUnit(heroes, currentUnit)
                
                set currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
                
                //  Current Priority Order:                                                                                     
                // 1. Avoid Overkill 
                // 2. Prioritize Stunned/Slowed
                // 3. Secure Kills
                // 4. Minimize Overkill Among Kills
                // 5. Damage Efficiency
                // 6. Fallback to Overkill

                set bestTarget = this.evaluateComboTarget(currentUnit, bestTarget, bestTargetHp, bestIsKillableTarget, bestIsStunOrSlow, comboExpectedDamage, comboMinThreshold)
                if bestTarget == currentUnit then
                    set bestTargetHp = currentHp
                    set bestIsKillableTarget = (currentHp <= comboExpectedDamage)
                    set bestIsStunOrSlow = IsUnitStunOrSlow(currentUnit)
                endif

            endloop
            
            // Clean up
            call DestroyGroup(heroes)
            set heroes = null
            set currentUnit = null
            
            if bestTarget != null then
                // Log selected target details
                if bestIsKillableTarget then
                    if bestIsStunOrSlow then
                        call this.botLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:1")
                        call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:1)")
                        call owner.setDebugTextTagColorPreset("RED")
                    else
                        call this.botLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:0")
                        call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:0)")
                        call owner.setDebugTextTagColorPreset("RED")
                    endif
                else
                    if bestIsStunOrSlow then
                        call this.botLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:1")
                        call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:1)")
                        call owner.setDebugTextTagColorPreset("RED")
                    else
                        call this.botLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:0")
                        call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:0)")
                    endif
                endif
            else
                set bestTarget = this.findFallbackComboTarget(range, heroAbil)
            endif
            
            set tempAIHeroAbility = 0            
            return bestTarget
        endmethod

        method findFallbackComboTarget takes real range, AIHeroAbility heroAbil returns unit
            local group heroes = CreateGroup()
            local unit currentUnit = null
            local unit bestTarget = null
            local real bestTargetHp = 0.0
            local real currentHp
            
            call this.botLog("No suitable combo target found, trying fallback to overkill targets")
            
            set tempHeroOwner = GetOwningPlayer(owner.hero)
            set bTempFilterForAllies = false
            set tempHeroUnit = owner.hero
            set tempAIHeroAbility = heroAbil
            call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterHeroes))
            
            loop
                set currentUnit = FirstOfGroup(heroes)
                exitwhen currentUnit == null
                call GroupRemoveUnit(heroes, currentUnit)
                
                set currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
                
                if bestTarget == null or currentHp > bestTargetHp then
                    set bestTarget = currentUnit
                    set bestTargetHp = currentHp
                endif
            endloop
            
            call DestroyGroup(heroes)
            set heroes = null
            set tempAIHeroAbility = 0
            
            if bestTarget != null then
                call this.botLog("Fallback combo target selected: " + GetUnitName(bestTarget))
                call owner.setDebugTextTagContent("Combat: Combo Target (Overkill): " + GetUnitName(bestTarget))
                call owner.setDebugTextTagColorPreset("RED")
            else
                call this.botLog("No combo targets found at all")
                call owner.setDebugTextTagContent("Combat: No Combo Target")
                call owner.setDebugTextTagColorPreset("RED")
            endif
            
            return bestTarget
        endmethod

        method onExit takes nothing returns nothing
            call this.botLog("Exiting Combat State")
            call owner.setDebugTextTagContent("Combat: Exit")
            call owner.setDebugTextTagColorPreset("RED")
        endmethod
    endstruct

    struct PickUpItemState extends AIState
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            set this.stateID = STATE_PICKUP_ITEM
            return this
        endmethod

        method onEnter takes nothing returns nothing
            call this.botLog("Entering Pick Up Item State")
            call owner.setDebugTextTagContent("Item: Picking Up")
            call owner.setDebugTextTagColorPreset("CYAN")

            // Pick up the item
            if owner.pickingUpItem != null then
                call IssueTargetOrder(owner.hero, "smart", owner.pickingUpItem) 
            else
                call this.botLog("No item to pick up")
                call owner.setDebugTextTagContent("Item: No Item Found")
                call owner.setDebugTextTagColorPreset("CYAN")
                // Transition back to RunState if no item found
                call owner.changeState(RunState.create())
            endif
        endmethod

        method onUpdate takes nothing returns nothing
            // check if item has been picked up
            if owner.pickingUpItem == null or IsItemOwned(owner.pickingUpItem) or IsUnitInventoryFull(owner.hero) then
                call this.botLog("Item picked up or no item to pick up, transitioning to Run State")
                call owner.setDebugTextTagContent("Item: Picked Up")
                call owner.setDebugTextTagColorPreset("CYAN")
                call owner.changeState(RunState.create())
            endif
        endmethod

        method onExit takes nothing returns nothing
            call this.botLog("Exiting Pick Up Item State")
            call owner.setDebugTextTagContent("Item: Exit")
            call owner.setDebugTextTagColorPreset("CYAN")
        endmethod
    endstruct


    struct AIHero
        unit hero
        integer difficulty
        real castPt
        AIState currentState
        integer currentWaypointIndex
        HeroCombatData combatData
        real lastStartCastTime
        boolean isCasting
        AIHeroAbility castingAbility
        timer updateTimer
        integer currentComboIndex
        unit comboTargetUnit
        texttag debugTextTag
        string debugTextTagContent
        timer debugTextTagTimer
        item pickingUpItem
        
        // Constructor
        static method create takes unit u, integer inDifficulty returns thistype
            local thistype this = thistype.allocate()
            set this.updateTimer = CreateTimer()
            set this.hero = u
            set this.difficulty = inDifficulty
            set this.castPt = GetHeroCastPoint(GetUnitTypeId(u))
            set this.currentState = 0
            set this.currentWaypointIndex = 1
            set this.lastStartCastTime = 0.0
            set this.isCasting = false
            set this.castingAbility = 0
            set this.currentComboIndex = 1 // only for difficulty HARD and above
            set this.comboTargetUnit = null
            set this.debugTextTag = null
            set this.debugTextTagContent = ""
            set this.debugTextTagTimer = null
            set this.pickingUpItem = null


            // Initialize combat data
            set this.combatData = InitializeHeroCombatData(u, inDifficulty)
            set this.combatData.ownerAIHero = this

            call this.changeState(RunState.create())

            
            // Start the loop
            call SaveInteger(udg_TimerHeroMap, GetHandleId(this.updateTimer), 0, this)
            call TimerStart(this.updateTimer, UPDATE_PERIOD, true, function thistype.onUpdate)
            
            // Store unit to AIHero mapping
            call SaveInteger(udg_UnitAIHeroMap, GetHandleId(this.hero), 0, this)
            if udg_bEnableBotTextTag then
                call this.createDebugTextTag()
            endif

            return this
        endmethod

        method moveToNextWaypoint takes nothing returns nothing
            local rect currentWaypointArea
            local real x
            local real y

            set currentWaypointArea = WaypointAreas[currentWaypointIndex]
            set x = GetRandomReal(GetRectMinX(currentWaypointArea), GetRectMaxX(currentWaypointArea))
            set y = GetRandomReal(GetRectMinY(currentWaypointArea), GetRectMaxY(currentWaypointArea))
            call IssuePointOrder(hero, "move", x, y)
            
            set currentWaypointArea = null
        endmethod

        method shouldEnterCombat takes nothing returns boolean
            local integer i = 0
            local AIHeroAbility heroAbil
            local real currentMana
            local boolean hasReadyAbility = false
            local boolean hasReadyItem = false
            
            if IsUnitStunOrSilence(this.hero) then
                call BotLog("Cannot enter combat, hero is stunned or silenced.")
                call this.setDebugTextTagContent("Run: Stunned/Silenced")
                call this.setDebugTextTagColorPreset("YELLOW")
                return false
            endif

            set hasReadyItem = this.combatData.hasReadyItem()
            if hasReadyItem then
                return true
            endif

            set hasReadyAbility = this.combatData.hasReadyAbility(this.hero, this.difficulty)
            if hasReadyAbility then
                return true
            endif
            return false
        endmethod

        method searchPickupItemAround takes nothing returns nothing
            local item itm
            local real searchRadius

            if this.difficulty < DIFF_NORMAL then
                return
            endif

            if this.currentState.stateID == STATE_HAZARD or IsFinalWaypoint(this) then
                set searchRadius = PICKUP_ITEM_RANGE_SMALL
            else
                set searchRadius = PICKUP_ITEM_RANGE_NORMAL
            endif

            set this.pickingUpItem = GetSuitablePickupItemInRange(this.hero, searchRadius)
        endmethod

        method shouldEnterPickupItemState takes nothing returns boolean
            // call this.botLog("shouldenter: Item found to pick up: " + GetItemName(this.pickingUpItem))
            return this.pickingUpItem != null
        endmethod

        method changeState takes AIState newState returns nothing
            if this.currentState != null then
                call this.currentState.onExit()
                call this.currentState.destroy()
            endif
            set this.currentState = newState
            set this.currentState.owner = this
            call this.currentState.onEnter()
        endmethod

        method botLog takes string msg returns nothing
            call BotLogWithPlayer(GetOwningPlayer(this.hero), msg)
        endmethod
        
        method botLogError takes string msg returns nothing
            call BotLogErrorWithPlayer(GetOwningPlayer(this.hero), msg)
        endmethod
        
        method shouldEnterHazardState takes nothing returns boolean
            if this.difficulty < DIFF_HARD then
                return false
            endif

            if IsInSlowSpikeHazardZone(this) then
                return true
            endif

            if IsInFastSpikeHazardZone(this) then
                return true
            endif

            if IsInNetHazardZone(this) then
                return true
            endif
            
            if IsInSpiderNetHazardZone(this) then
                return true
            endif

            return false
        endmethod

        method destroy takes nothing returns nothing
            // Clean up combat data
            if this.combatData != null then
                call this.combatData.destroy()
                set this.combatData = 0
            endif
            
            // Clean up current state
            if this.currentState != null then
                call this.currentState.destroy()
                set this.currentState = 0
            endif
            
            // Clean up timer
            if this.updateTimer != null then
                call RemoveSavedInteger(udg_TimerHeroMap, GetHandleId(this.updateTimer), 0)
                call PauseTimer(this.updateTimer)
                call DestroyTimer(this.updateTimer)
                set this.updateTimer = null
            endif

            if this.debugTextTag != null then
                call this.destroyDebugTextTag()
            endif
            
            // Remove unit to AIHero mapping
            if this.hero != null then
                call RemoveSavedInteger(udg_UnitAIHeroMap, GetHandleId(this.hero), 0)
                call RemoveUnit(this.hero)
            endif

            // Nullify unit handle
            set this.hero = null
            
            call this.deallocate()
        endmethod

        static method onUpdate takes nothing returns nothing
            local thistype this = LoadInteger(udg_TimerHeroMap, GetHandleId(GetExpiredTimer()), 0)
            if this != null and this.currentState != null then
                // Check if hero died and transition to dead state if needed
                if not IsUnitAliveBJ(this.hero) and this.currentState.stateID != STATE_DEAD then
                    call this.changeState(DeadState.create())
                else
                    call this.currentState.onUpdate()
                endif
            endif

        endmethod

        method onCastComplete takes nothing returns nothing
            local real currentTime = TimerGetElapsed(gameTimer)
            local integer difficulty = this.difficulty
            set this.isCasting = false
            set this.castingAbility.lastCastTime = currentTime
            // Advance combo index if casting combo ability
            if IsApplyingCombo(difficulty) and this.castingAbility.comboIndex > 0 then
                set this.currentComboIndex = this.currentComboIndex + 1
                call this.botLog("Advancing combo index to: " + I2S(this.currentComboIndex))
                // If no further combo ability, reset combo index
                if this.combatData.getAbilityByComboIndex(this.currentComboIndex) == 0 then
                    set this.currentComboIndex = 1
                    set this.comboTargetUnit = null
                    call this.botLog("Combo sequence complete, resetting combo index to 1")
                endif
            endif

            call this.botLog("Casting complete for ability: " + this.castingAbility.orderString + ", current combo index: " + I2S(this.currentComboIndex))
            call this.setDebugTextTagContent("Combat: " + this.castingAbility.orderString + " done, CCI: " + I2S(this.currentComboIndex))
            call this.setDebugTextTagColorPreset("RED")
            set this.castingAbility = 0
        endmethod

        method onGetItem takes item itm returns nothing
            call this.botLog("Picked up item: " + GetItemName(itm))
            call this.setDebugTextTagContent("Item: Picked Up " + GetItemName(itm))
            call this.setDebugTextTagColorPreset("CYAN")
            call this.combatData.addItem(itm, GetItemTypeId(itm), 99999, this.hero)
        endmethod

        method avoidTargetUnitAhead takes unit targetUnit, real targetMoveSpeed, real moveDistanceScale, boolean bLeanTowardWaypoint returns nothing
            local real heroX = GetUnitX(this.hero)
            local real heroY = GetUnitY(this.hero)
            local real targetUnitX = GetUnitX(targetUnit)
            local real targetUnitY = GetUnitY(targetUnit)
            local real moveDistance = GetUnitMoveSpeed(this.hero) * UPDATE_PERIOD * moveDistanceScale
            local real heroMovingAngle = GetUnitFacing(this.hero)
            local real targetUnitMovingAngle = GetUnitFacing(targetUnit)
            local real predictedTargetUnitX = targetUnitX + targetMoveSpeed * 2 * UPDATE_PERIOD * Cos(targetUnitMovingAngle * bj_DEGTORAD)
            local real predictedTargetUnitY = targetUnitY + targetMoveSpeed * 2 * UPDATE_PERIOD * Sin(targetUnitMovingAngle * bj_DEGTORAD)
            local real predictedTargetUnitToHeroAngle = NormalizeAngle(Atan2(heroY - predictedTargetUnitY, heroX - predictedTargetUnitX) * bj_RADTODEG)
            local real avoidAngle = GetMiddleAngle(heroMovingAngle, predictedTargetUnitToHeroAngle)
            local real moveX
            local real moveY

            call this.botLog("Avoiding target unit: " + GetUnitName(targetUnit))
            call this.botLog("heroMovingAngle: " + R2S(heroMovingAngle) + ", predictedTargetUnitToHeroAngle: " + R2S(predictedTargetUnitToHeroAngle))
            call this.botLog("Calculated avoidAngle: " + R2S(avoidAngle))
            if bLeanTowardWaypoint then
                set avoidAngle = GetMiddleAngle(heroMovingAngle, avoidAngle)
                call this.botLog("Leaning 2x toward waypoint, new avoidAngle: " + R2S(avoidAngle))
            endif


            set moveX = heroX + moveDistance * Cos(avoidAngle * bj_DEGTORAD)
            set moveY = heroY + moveDistance * Sin(avoidAngle * bj_DEGTORAD)

            call IssuePointOrder(this.hero, "move", moveX, moveY)
        endmethod

        method avoidTargetUnitBehind takes unit targetUnit, boolean canGoBackward, real moveDistanceScale, boolean bLeanTowardWaypoint returns nothing
            local real heroX = GetUnitX(this.hero)
            local real heroY = GetUnitY(this.hero)
            local real targetUnitX = GetUnitX(targetUnit)
            local real targetUnitY = GetUnitY(targetUnit)
            local real moveDistance = GetUnitMoveSpeed(this.hero) * UPDATE_PERIOD * moveDistanceScale
            local real targetUnitToHeroAngle = NormalizeAngle(Atan2(heroY - targetUnitY, heroX - targetUnitX) * bj_RADTODEG)
            local rect currentWaypointArea = WaypointAreas[currentWaypointIndex]
            local real nextWaypointX = GetRandomReal(GetRectMinX(currentWaypointArea), GetRectMaxX(currentWaypointArea))
            local real nextWaypointY = GetRandomReal(GetRectMinY(currentWaypointArea), GetRectMaxY(currentWaypointArea))
            local real heroToNextWaypointAngle = NormalizeAngle(Atan2(nextWaypointY - heroY, nextWaypointX - heroX) * bj_RADTODEG)
            local real avoidAngle
            local real moveX
            local real moveY
            
            if canGoBackward then
                if AngleDiff(heroToNextWaypointAngle, targetUnitToHeroAngle) <= 135.0 then
                    set avoidAngle = GetMiddleAngle(heroToNextWaypointAngle, targetUnitToHeroAngle)
                    call this.botLog("Initial avoidAngle (forward): " + R2S(avoidAngle) + ", heroToNextWaypointAngle: " + R2S(heroToNextWaypointAngle) + ", targetUnitToHeroAngle: " + R2S(targetUnitToHeroAngle))
                else
                    set avoidAngle = GetMiddleAngle(NormalizeAngle(heroToNextWaypointAngle + 180.0), targetUnitToHeroAngle)
                    call this.botLog("Initial avoidAngle (backward): " + R2S(avoidAngle) + ", heroToNextWaypointAngle: " + R2S(heroToNextWaypointAngle) + ", targetUnitToHeroAngle: " + R2S(targetUnitToHeroAngle))
                endif
            else
                set avoidAngle = GetMiddleAngle(heroToNextWaypointAngle, targetUnitToHeroAngle)
                call this.botLog("Initial avoidAngle (backward): " + R2S(avoidAngle) + ", heroToNextWaypointAngle: " + R2S(heroToNextWaypointAngle) + ", targetUnitToHeroAngle: " + R2S(targetUnitToHeroAngle))
                if bLeanTowardWaypoint then
                    set avoidAngle = GetMiddleAngle(heroToNextWaypointAngle, avoidAngle)
                    call this.botLog("Leaning 2x toward waypoint, new avoidAngle: " + R2S(avoidAngle))
                endif
            endif

            call this.botLog("Avoiding target unit behind: " + GetUnitName(targetUnit))
            call this.botLog("Calculated avoidAngle: " + R2S(avoidAngle))
            set moveX = heroX + moveDistance * Cos(avoidAngle * bj_DEGTORAD)
            set moveY = heroY + moveDistance * Sin(avoidAngle * bj_DEGTORAD)

            call IssuePointOrder(this.hero, "move", moveX, moveY)
        endmethod


        method createDebugTextTag takes nothing returns nothing
            set this.debugTextTag = CreateTextTag()
            set this.debugTextTagContent = "Bot"
            call setDebugTextTagContent(this.debugTextTagContent)
            call SetTextTagColorBJ(this.debugTextTag, 255, 255, 255, 0)
            call SetTextTagPos (this.debugTextTag, GetUnitX(this.hero) + this.calculateTextCenterOffset(), GetUnitY(this.hero) - 80.0, 0.0)
            call SetTextTagPermanent(this.debugTextTag, true)
            call SetTextTagSuspended(this.debugTextTag, true)
            call SetTextTagVisibility(this.debugTextTag, true)
            call SetTextTagFadepoint(this.debugTextTag, -1.0)

            set this.debugTextTagTimer = CreateTimer()
            call TimerStart(this.debugTextTagTimer, 0.03, true, function thistype.updateDebugTextTagPosition)
            call SaveInteger(udg_DebugTextTagTimerHeroMap, GetHandleId(this.debugTextTagTimer), 0, this)
        endmethod

        static method updateDebugTextTagPosition takes nothing returns nothing
            local thistype this = LoadInteger(udg_DebugTextTagTimerHeroMap, GetHandleId(GetExpiredTimer()), 0)
            if this.debugTextTag != null then
                call SetTextTagPos(this.debugTextTag, GetUnitX(this.hero) + this.calculateTextCenterOffset(), GetUnitY(this.hero) - 80.0, 0.0)
            endif
        endmethod

        method setDebugTextTagContent takes string content returns nothing
            set this.debugTextTagContent = content
            if this.debugTextTag != null then
                call SetTextTagTextBJ(this.debugTextTag, this.debugTextTagContent, 8.0)
            endif
        endmethod

        method calculateTextCenterOffset takes nothing returns real
            local integer stringLength = StringLength(this.debugTextTagContent)
            local real characterWidth = 65.0  // Approximate character width in Warcraft III units
            return - (stringLength * characterWidth) / 5.3
        endmethod

        method setDebugTextTagColor takes real r, real g, real b, real a returns nothing
            if this.debugTextTag != null then
                call SetTextTagColorBJ(this.debugTextTag, r, g, b, a)
            endif
        endmethod

        method setDebugTextTagColorPreset takes string colorName returns nothing
            local integer alpha = 0
            if colorName == "WHITE" then
                call this.setDebugTextTagColor(COLOR_WHITE_R, COLOR_WHITE_G, COLOR_WHITE_B, alpha)
            elseif colorName == "RED" then
                call this.setDebugTextTagColor(COLOR_RED_R, COLOR_RED_G, COLOR_RED_B, alpha)
            elseif colorName == "GREEN" then
                call this.setDebugTextTagColor(COLOR_GREEN_R, COLOR_GREEN_G, COLOR_GREEN_B, alpha)
            elseif colorName == "BLUE" then
                call this.setDebugTextTagColor(COLOR_BLUE_R, COLOR_BLUE_G, COLOR_BLUE_B, alpha)
            elseif colorName == "YELLOW" then
                call this.setDebugTextTagColor(COLOR_YELLOW_R, COLOR_YELLOW_G, COLOR_YELLOW_B, alpha)
            elseif colorName == "ORANGE" then
                call this.setDebugTextTagColor(COLOR_ORANGE_R, COLOR_ORANGE_G, COLOR_ORANGE_B, alpha)
            elseif colorName == "PURPLE" then
                call this.setDebugTextTagColor(COLOR_PURPLE_R, COLOR_PURPLE_G, COLOR_PURPLE_B, alpha)
            elseif colorName == "CYAN" then
                call this.setDebugTextTagColor(COLOR_CYAN_R, COLOR_CYAN_G, COLOR_CYAN_B, alpha)
            elseif colorName == "PINK" then
                call this.setDebugTextTagColor(COLOR_PINK_R, COLOR_PINK_G, COLOR_PINK_B, alpha)
            elseif colorName == "GRAY" then
                call this.setDebugTextTagColor(COLOR_GRAY_R, COLOR_GRAY_G, COLOR_GRAY_B, alpha)
            else
                call BotLogError("Unknown color preset: " + colorName)
                call this.setDebugTextTagColor(COLOR_WHITE_R, COLOR_WHITE_G, COLOR_WHITE_B, alpha)
            endif
        endmethod

        method destroyDebugTextTag takes nothing returns nothing
            if this.debugTextTag != null then
                call SetTextTagVisibility(this.debugTextTag, false)
                set this.debugTextTag = null
            endif
        endmethod
    endstruct

    // This module ensures our initialization functions are called when the map loads.
    private module Initializer
        private static method onInit takes nothing returns nothing
            set udg_TimerHeroMap = InitHashtable()
            set udg_DebugTextTagTimerHeroMap = InitHashtable()
            set udg_UnitAIHeroMap = InitHashtable()
            set heroCastPointMap = InitHashtable()
            set gameTimer = CreateTimer()
            call TimerStart(gameTimer, 999999.0, false, null)
            call InitializeHeroCastPoints()
            call InitializeWaypoints()
        endmethod
    endmodule

    // We use a dummy struct to attach the initializer module to the library.
    private struct Init extends array
        implement Initializer
    endstruct
  
endlibrary