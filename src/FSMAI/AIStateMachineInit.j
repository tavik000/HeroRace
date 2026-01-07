globals
    // Timer to AIHero mapping
    hashtable udg_TimerHeroMap
    hashtable udg_DebugTextTagTimerHeroMap
        
    // Unit to AIHero mapping
    hashtable udg_UnitAIHeroMap
        
    // Global timer for tracking game time
    timer gameTimer
        
    // Hero cast point (pre-swing) mapping by unit type
    hashtable heroCastPointMap
        
    // Temporary variables for filtering heroes
    player tempHeroOwner = null
    integer tempFindTeamType = 0
    unit tempHeroUnit = null
    AIHeroAbility tempAIHeroAbility = 0
    AIItem tempAIItem = 0

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

endglobals

library AIStateMachine requires KeyUtils, AIUtils

    // Initialize hero cast points (Pre-swing) by unit type
    private function InitializeHeroCastPoints takes nothing returns nothing
        // Configure cast points for different hero types
        call SaveReal(heroCastPointMap, 'H009', 0, 0.2)  // BloodMage
        // call SaveReal(heroCastPointMap, 'Hmkg', 0, 0.3)  // Mountain King  
        // TODO: Add more hero types as needed
    endfunction

    // Initialize hero-specific abilities (extend this function for different heroes)
    function InitializeHeroCombatData takes AIHero owner, integer difficulty returns HeroCombatData
        local HeroCombatData data = HeroCombatData.create(owner)
        local integer heroTypeId = GetUnitTypeId(owner.hero)
        
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
    endfunction

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
        call InitItemData()
    endmethod
endmodule

// We use a dummy struct to attach the initializer module to the library.
private struct Init extends array
implement Initializer
endstruct
  
endlibrary