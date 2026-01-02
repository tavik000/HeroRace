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
        // Turn Time and Pre-swing and ability required cast time
        local boolean isCastOvertime = currentTime > (owner.lastStartCastTime + owner.castPt + TURN_TIME + owner.currentRequiredCastTime)
        local boolean isCastFailed = owner.isCasting and isCastOvertime

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
            else
                call this.botLog("Casting ability with required cast time: " + owner.castingAbility.orderString + ", skippingg update")
                call owner.setDebugTextTagContent("Combat: Casting " + owner.castingAbility.orderString)
                call owner.setDebugTextTagColorPreset("RED")
                return
            endif
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
        local real currentTime = TimerGetElapsed(gameTimer)

        if difficulty < DIFF_NORMAL then
            return false
        endif

        set heroItem = owner.combatData.getReadyItem()            
        if heroItem != 0 then
            call owner.setDebugTextTagContent("Combat: Try using item " + GetItemName(heroItem.itemHandle))
            call owner.setDebugTextTagColorPreset("RED")
            if heroItem.tryUse() then
                set owner.currentRequiredCastTime = heroItem.requiredCastTime
                set owner.lastStartCastTime = currentTime
                return true
            endif
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
        set targetUnit = FindTargetForAbility(owner, heroAbil)
            
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

    method onExit takes nothing returns nothing
        call this.botLog("Exiting Combat State")
        call owner.setDebugTextTagContent("Combat: Exit")
        call owner.setDebugTextTagColorPreset("RED")
    endmethod
endstruct