struct GoaledState extends AIState

    static method create takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.stateID = STATE_GOALED
        return this
    endmethod

    method onEnter takes nothing returns nothing
        call this.botLog("Entering Goaled State")
        call owner.setDebugTextTagContent("Goaled: Entering")
        call owner.setDebugTextTagColorPreset("PINK")
        call IssueImmediateOrder(owner.hero, "stop")
    endmethod

    method onUpdate takes nothing returns nothing
        local integer currentWaypointIndex = owner.currentWaypointIndex
        local integer currentOrder = GetUnitCurrentOrder(owner.hero)
        local unit tower1 = udg_Monster[10]

        if not IsUnitAliveBJ(owner.hero) then
            return
        endif

        if owner.difficulty < DIFF_HARD then
            call owner.setDebugTextTagContent("Goaled: Idle")
            return
        endif
            
        call owner.setDebugTextTagContent("Goaled: Updating")
        call owner.setDebugTextTagColorPreset("PINK")

        if owner.TryEnterGiveItemState() then
            return 
        endif

        if owner.TryEnterPickupItemState() then
            return
        endif

        call owner.tryAvoidBlockingUnit() 

        if owner.tryEnterCombat() then
            return
        endif

        // If tower 1 died, also move to danger area
        if isHealthy() or IsUnitDeadBJ(tower1) or IsUnitAlly(tower1, GetOwningPlayer(owner.hero)) then
            if tryMoveToDangerArea() then
                return
            endif 
        else
            if tryMoveToSafeArea() then
                return
            endif
        endif

        if owner.tryEnterHazardState() then
            return
        endif

        if currentOrder == 0 then
            // Hero is idle (no current order) - reissue move command to current waypoint
            call this.botLog("Goaled Hero is idle, issuing move command")
            call owner.setDebugTextTagContent("Goaled: Reissuing Move Command")
            call owner.setDebugTextTagColorPreset("PINK")
            call owner.moveToNextWaypoint()
            return
        endif

    endmethod

    method tryMoveToDangerArea takes nothing returns boolean
        local integer dangerAreaWaypointIndex = 21
        if owner.currentWaypointIndex != dangerAreaWaypointIndex then
            call owner.setWaypointIndex(dangerAreaWaypointIndex) // Goaled Danger Area
            call owner.moveToNextWaypoint()
            return true
        endif
        return false
    endmethod

    method tryMoveToSafeArea takes nothing returns boolean
        local integer safeAreaWaypointIndex = 20
        if owner.currentWaypointIndex != safeAreaWaypointIndex then
            call owner.setWaypointIndex(safeAreaWaypointIndex) // Goaled Safe Area
            call owner.moveToNextWaypoint()
            return true
        endif
        return false
    endmethod

    method isHealthy takes nothing returns boolean
        return GetUnitLifePercent(owner.hero) >= 40.0
    endmethod

    method onExit takes nothing returns nothing
        call this.botLog("Exiting Goaled State")
        call owner.setDebugTextTagContent("Goaled: Exiting")
        call owner.setDebugTextTagColorPreset("PINK")
    endmethod
endstruct