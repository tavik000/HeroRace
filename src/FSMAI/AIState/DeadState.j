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

        if owner.TryEnterPickupItemState() then
            return
        endif

        call owner.changeState(RunState.create())
    endmethod

    method applyDifficultyModifiersOnRevival takes nothing returns nothing
        local real speedBonus = 0.0
        local real defaultMoveSpeed = GetUnitDefaultMoveSpeed(owner.hero)
        local real maxSpeed = 400.0
        // Apply difficulty-based modifiers on revival
        if owner.difficulty >= DIFF_CRAZY then
            if owner.difficulty == DIFF_NIGHTMARE then
                // Increase extra damage
                set owner.deadDamageBonusPercentage = owner.deadDamageBonusPercentage + 0.05 // 5% extra damage on revival per death
                // Increase move speed
                if GetUnitMoveSpeed(owner.hero) >= defaultMoveSpeed and GetUnitMoveSpeed(owner.hero) < maxSpeed then
                    set speedBonus = 10.0
                    call YDUserDataSet(unit, owner.hero, "speed", real, (YDUserDataGet(unit, owner.hero, "speed", real) + speedBonus))
                    call SetUnitMoveSpeed(owner.hero, GetUnitMoveSpeed(owner.hero) + speedBonus)
                endif
                // +200 HP
                call UnitAddItemByIdSwapped('I00L', owner.hero) 
                call this.botLog("Applying Crazy/Nightmare difficulty modifiers on revival: +10 Move Speed, +200 HP, + 5% Extra Damage")
            else
                // Increase extra damage
                set owner.deadDamageBonusPercentage = owner.deadDamageBonusPercentage + 0.02 // 2% extra damage on revival per death
                // Apply speed and HP bonus
                if GetUnitMoveSpeed(owner.hero) >= defaultMoveSpeed and GetUnitMoveSpeed(owner.hero) < maxSpeed then
                    set speedBonus = 5.0
                    call YDUserDataSet(unit, owner.hero, "speed", real, (YDUserDataGet(unit, owner.hero, "speed", real) + speedBonus))
                    call SetUnitMoveSpeed(owner.hero, GetUnitMoveSpeed(owner.hero) + speedBonus)
                endif
                // +100 HP
                call UnitAddItemByIdSwapped('I02J', owner.hero)
                call this.botLog("Applying Crazy difficulty modifiers on revival: +5 Move Speed, +100 HP, + 2% Extra Damage")
            endif
        endif
    endmethod

    method onExit takes nothing returns nothing
        call this.botLog("Exiting Dead State")
        call owner.setDebugTextTagContent("Dead: Exiting")
        call owner.setDebugTextTagColorPreset("GRAY")
    endmethod
endstruct