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
        // Initial update on enter
        call this.onUpdate()
    endmethod

    method onUpdate takes nothing returns nothing
        local real currentTime = TimerGetElapsed(gameTimer)
        local integer difficulty = owner.difficulty
        // Turn Time and Pre-swing and ability required cast time
        local boolean isCastOvertime = currentTime > (owner.lastStartCastTime + owner.castPt + TURN_TIME + owner.currentRequiredCastTime)
        local boolean isCastFailed = owner.isCasting and isCastOvertime

        call owner.setDebugTextTagContent("Combat: Updating")
        call owner.setDebugTextTagColorPreset("RED")

        if isCastFailed then
            call this.botLog("Casting failed detected for ability: " + owner.castingAbility.orderString)
            call owner.setDebugTextTagContent("Combat: Cast Failed " + owner.castingAbility.orderString)
            call owner.setDebugTextTagColorPreset("RED")
            set owner.isCasting = false
            set owner.castingAbility = 0
            set owner.currentRequiredCastTime = 0
        endif

        if owner.isCasting then
            call this.botLog("Currently casting an ability, skipping update")
            call owner.setDebugTextTagContent("Combat: Casting " + owner.castingAbility.orderString)
            call owner.setDebugTextTagColorPreset("RED")
            return
        endif

        if owner.currentRequiredCastTime > 0 then
            if isCastOvertime then
                call this.botLog("Casting Finished for ability: " + owner.castingAbility.orderString)
                set owner.isCasting = false
                set owner.castingAbility = 0
                set owner.currentRequiredCastTime = 0
                call owner.setDebugTextTagContent("Combat: Cast Finished")
                call owner.setDebugTextTagColorPreset("RED")
            else
                call this.botLog("Casting ability with required cast time: " + owner.castingAbility.orderString + ", skippingg update")
                call owner.setDebugTextTagContent("Combat: Casting " + owner.castingAbility.orderString)
                call owner.setDebugTextTagColorPreset("RED")
                return
            endif
        endif

        if not IsUnitAliveBJ(owner.hero) then
            return
        endif

        if this.tryUseAnyReadyItem() then
            return
        endif
            
        if this.tryCastAnyReadyAbility() then
            return
        endif
            
        // Return to run state after combat
        call owner.changeState(RunState.create())
    endmethod

    method tryUseAnyReadyItem takes nothing returns boolean
        local AIItem heroItem
        local integer difficulty = owner.difficulty
        local real currentTime = TimerGetElapsed(gameTimer)

        if difficulty < DIFF_NORMAL then
            return false
        endif

        set heroItem = owner.combatData.getReadyItem()            
        if heroItem != 0 then
            call owner.setDebugTextTagContent("Combat: Try using item " + GetItemName(heroItem.itemHandle))
            call owner.setDebugTextTagColorPreset("RED")
            if heroItem.tryUse() then
                set owner.isCasting = true
                set owner.currentRequiredCastTime = heroItem.requiredCastTime
                set owner.lastStartCastTime = currentTime
                call owner.combatData.syncItemCooldown(heroItem)
                return true
            endif
        endif
            
        return false
    endmethod

    method tryCastAnyReadyAbility takes nothing returns boolean
        local integer i = 0
        local AIHeroAbility heroAbil
        local real currentTime = TimerGetElapsed(gameTimer)
        local integer difficulty = owner.difficulty
            
        // Cast first available ability with 2x cooldown spacing
        set heroAbil = owner.combatData.getReadyAbility(owner.hero, difficulty)
        if heroAbil != 0 then
            if heroAbil.tryCast() then
                set owner.isCasting = true
                set owner.castingAbility = heroAbil
                set owner.lastStartCastTime = currentTime
                return true
            endif
        endif
        return false
    endmethod

    method onExit takes nothing returns nothing
        call this.botLog("Exiting Combat State")
        call owner.setDebugTextTagContent("Combat: Exit")
        call owner.setDebugTextTagColorPreset("RED")
    endmethod
endstruct