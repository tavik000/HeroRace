library AIStateMachine requires optional KeyUtils
    
    // --- CONFIGURATION ---
    globals
        // States
        constant integer STATE_PRE_GAME = 0
        constant integer STATE_RUN = 1
        constant integer STATE_COMBAT = 2
        constant integer STATE_HAZARD = 3
        constant integer STATE_HEALING = 4
        
        // Difficulty Levels
        constant integer DIFF_EASY = 0
        constant integer DIFF_NORMAL = 1
        constant integer DIFF_HARD = 2
        
        // Settings
        constant real HEAL_THRESHOLD = 0.40 // 40% HP
        constant real CAST_RANGE = 700.00
        constant real UPDATE_PERIOD = 0.30
        
        // Timer to AIHero mapping
        public hashtable udg_TimerHeroMap

        // The array to hold the waypoint regions.
        private rect array WaypointAreas
        // The actual number of waypoints initialized.
        public integer WaypointCount = 0
    endglobals

    // This function will run once at map initialization to set up the waypoints.
    private function InitializeWaypoints takes nothing returns nothing
        // IMPORTANT: Create regions in the World Editor and replace these
        // variable names (e.g., gg_rct_Waypoint_001) with your actual region variables.
        set WaypointAreas[0] = gg_rct_AIWayPointArea01
        set WaypointAreas[1] = gg_rct_AIWayPointArea01
        set WaypointAreas[2] = gg_rct_AIWayPointArea02
        // set WaypointAreas[2] = gg_rct_Waypoint_003
        set WaypointCount = 3 // Update this to match the number of waypoints you added.
    endfunction

    struct AIState 
        integer stateID
        AIHero owner
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
            local rect waypointArea
            local real x
            local real y

            call BJDebugMsg("Entering Run State")
            // Increment waypoint index, wrapping around if it reaches the end
            set owner.currentWaypointIndex = owner.currentWaypointIndex + 1
            set waypointArea = WaypointAreas[owner.currentWaypointIndex]
            set x = GetRandomReal(GetRectMinX(waypointArea), GetRectMaxX(waypointArea))
            set y = GetRandomReal(GetRectMinY(waypointArea), GetRectMaxY(waypointArea))
            call IssuePointOrder(owner.hero, "move", x, y)      
        endmethod

        method onUpdate takes nothing returns nothing
            local rect currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
            local real heroX = GetUnitX(owner.hero)
            local real heroY = GetUnitY(owner.hero)
            
            call BJDebugMsg("Updating Run State")
            
            // Check if hero has reached the current waypoint area
            if RectContainsCoords(currentWaypointArea, heroX, heroY) then
                call BJDebugMsg("Reached waypoint " + I2S(owner.currentWaypointIndex))
                // Move to next waypoint
                set owner.currentWaypointIndex = (owner.currentWaypointIndex + 1)
                if owner.currentWaypointIndex >= WaypointCount then
                    set owner.currentWaypointIndex = 0  // Loop back to start
                endif
                
                // Move to the new waypoint
                set currentWaypointArea = WaypointAreas[owner.currentWaypointIndex]
                call IssuePointOrder(owner.hero, "move", GetRandomReal(GetRectMinX(currentWaypointArea), GetRectMaxX(currentWaypointArea)), GetRandomReal(GetRectMinY(currentWaypointArea), GetRectMaxY(currentWaypointArea)))
            endif
        endmethod

        method onExit takes nothing returns nothing
            call BJDebugMsg("Exiting Run State")
        endmethod
    endstruct



    struct AIHero
        unit hero
        integer difficulty
        AIState currentState
        integer currentWaypointIndex
        
        // Constructor
        static method create takes unit u, integer diff returns thistype
            local thistype this = thistype.allocate()
            local timer t = CreateTimer()
            set this.hero = u
            set this.difficulty = diff
            set this.currentState = 0
            set this.currentWaypointIndex = 0


            call this.changeState(RunState.create())

            
            // Start the loop
            call SaveInteger(udg_TimerHeroMap, GetHandleId(t), 0, this)
            call TimerStart(t, UPDATE_PERIOD, true, function thistype.onUpdate)
            return this
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

      

        static method onUpdate takes nothing returns nothing
            local thistype this = LoadInteger(udg_TimerHeroMap, GetHandleId(GetExpiredTimer()), 0)
            if this != null and this.currentState != null then
                call this.currentState.onUpdate()
            endif
        endmethod
    endstruct

    // This module ensures our initialization functions are called when the map loads.
    private module Initializer
        private static method onInit takes nothing returns nothing
            call BJDebugMsg("AIStateMachine initializing...")
            set udg_TimerHeroMap = InitHashtable()
            call InitializeWaypoints()
        endmethod
    endmodule

    // We use a dummy struct to attach the initializer module to the library.
    private struct Init extends array
        implement Initializer
    endstruct
  
endlibrary