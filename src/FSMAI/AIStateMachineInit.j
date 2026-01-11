globals
    // Timer to AIHero mapping
    hashtable udg_TimerHeroMap
    hashtable udg_DebugTextTagTimerHeroMap
        
    // Unit to AIHero mapping
    hashtable udg_UnitAIHeroMap
        
    // Global timer for tracking game time
    timer gameTimer
        
    // Temporary variables for filtering heroes
    player tempHeroOwner = null
    integer tempFindTeamType = 0
    unit tempHeroUnit = null
    AIAbility tempAIAbility = 0
    AIItem tempAIItem = 0
    destructable tempTree = null
    real tempNearestTreeDist = MAX_RANGE

    // Temporary variables for item search
    item tempFoundItem = null
    real tempFoundItemX = 0.0
    real tempFoundItemY = 0.0
    real tempFoundItemUnitFacingAngle = 0.0
    real tempFoundItemRange = 0.0
    real tempFoundItemMinDist = 999999.0

    // The array to hold the waypoint regions.
    rect array WaypointAreas

    // The actual number of waypoints initialized.
    integer GoalWaypointIndex = 14

    // Fixed Location Point
    real TopRightAreaCenterX = 0.0
    real TopRightAreaCenterY = 0.0
    real BotRightAreaCenterX = 0.0
    real BotRightAreaCenterY = 0.0
    real GoalX = 0.0
    real GoalY = 0.0

endglobals

library AIStateMachine requires KeyUtils, AIUtils

    // Initialize hero-specific abilities (extend this function for different heroes)
    function InitializeHeroCombatData takes AIHero owner, integer difficulty returns HeroCombatData
        local HeroCombatData data = HeroCombatData.create(owner)
        local integer heroTypeId = GetUnitTypeId(owner.hero)
        local integer abilityCount = 0
        local integer i = 0
        local integer abilityId = 0
        
        // Check if hero has configuration
        if HeroHasConfig(heroTypeId) then
            set abilityCount = GetHeroAbilityCount(heroTypeId)
            call BotLog("Initializing hero abilities from config, count: " + I2S(abilityCount))
            
            // Add all configured abilities
            set i = 0
            loop
                exitwhen i >= abilityCount
                set abilityId = GetHeroAbilityId(heroTypeId, i)
                call data.addAbilityById(abilityId)
                set i = i + 1
            endloop
        else
            call BotLogError("No ability configuration found for hero type: " + I2S(heroTypeId))
        endif
        
        return data
    endfunction

    // This function will run once at map initialization to set up the waypoints.
    private function InitializeWaypoints takes nothing returns nothing
        set WaypointAreas[0] = gg_rct_AIWayPointArea01 // Not used
        set WaypointAreas[1] = gg_rct_AIWayPointArea01 // After Start Area
        set WaypointAreas[2] = gg_rct_AIWayPointArea02
        set WaypointAreas[3] = gg_rct_AIWayPointArea03 // Left of Upper Strait
        set WaypointAreas[31] = gg_rct_AIWayPointAreaCrossSea // Cross Sea Area
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
        set WaypointAreas[131] = gg_rct_AIWayPointAreaCrossTree // Before Spider Net Hazard
        set WaypointAreas[14] = gg_rct_Finish
        set GoalWaypointIndex = 14 // Update this to match the number of waypoints you added.
        // Goaled safe area and danger area
        set WaypointAreas[20] = gg_rct_AIGoaledSafeArea
        set WaypointAreas[21] = gg_rct_AIGoaledDangerArea

        // Initialize fixed location points
        set TopRightAreaCenterX = GetRectCenterX(gg_rct_TrackProgressTopRight)
        set TopRightAreaCenterY = GetRectCenterY(gg_rct_TrackProgressTopRight)
        set BotRightAreaCenterX = GetRectCenterX(gg_rct_TrackProgressBotRight)
        set BotRightAreaCenterY = GetRectCenterY(gg_rct_TrackProgressBotRight)
        set GoalX = GetRectCenterX(gg_rct_Finish)
        set GoalY = GetRectCenterY(gg_rct_Finish)
    endfunction

    // This module ensures our initialization functions are called when the map loads.
    private module Initializer
    private static method onInit takes nothing returns nothing
        set udg_TimerHeroMap = InitHashtable()
        set udg_DebugTextTagTimerHeroMap = InitHashtable()
        set udg_UnitAIHeroMap = InitHashtable()
        set gameTimer = CreateTimer()
        call TimerStart(gameTimer, 999999.0, false, null)
        call InitializeWaypoints()
        call InitItemConfig()
        call InitAbilityConfig()
        call InitHeroConfig()
    endmethod
endmodule

// We use a dummy struct to attach the initializer module to the library.
private struct Init extends array
implement Initializer
endstruct
  
endlibrary