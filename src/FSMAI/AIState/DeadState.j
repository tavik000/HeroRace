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