struct DeadState extends AIState
    static method create takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.stateID = STATE_DEAD
        return this
    endmethod

    method onEnter takes nothing returns nothing
        call this.botLog("Hero died - Entering Dead State")
        call owner.combatData.removeAllItems()
        call owner.resetIsCasting()
        set owner.isMovingForCast = false
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

        call this.applyDifficultyModifiersOnRevival()

        call owner.changeState(RunState.create())
    endmethod

    method applyDifficultyModifiersOnRevival takes nothing returns nothing
        // Apply difficulty-based modifiers on revival
        if owner.difficulty >= DIFF_CRAZY then
            if owner.difficulty == DIFF_NIGHTMARE then
                // Increase move speed
                call YDUserDataSet(unit, owner.hero, "speed", real, (YDUserDataGet(unit, owner.hero, "speed", real) + 5.0))
                call SetUnitMoveSpeed(owner.hero, GetUnitMoveSpeed(owner.hero) + 5.0)
                // +200 HP
                call UnitAddItemByIdSwapped( 'I00L', owner.hero ) 
                call this.botLog("Applying Crazy/Nightmare difficulty modifiers on revival: +5 Move Speed, +200 HP")
            else
                // +100 HP
                call UnitAddItemByIdSwapped( 'I02J', owner.hero )
                call this.botLog("Applying Crazy difficulty modifiers on revival: +100 HP")
            endif
        endif
    endmethod

    method onExit takes nothing returns nothing
        call this.botLog("Exiting Dead State")
        call owner.setDebugTextTagContent("Dead: Exiting")
        call owner.setDebugTextTagColorPreset("GRAY")
    endmethod
endstruct