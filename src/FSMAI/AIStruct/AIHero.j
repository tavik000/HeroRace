struct AIHero
    unit hero
    integer difficulty
    real castPt
    AIState currentState
    integer currentWaypointIndex
    HeroCombatData combatData
    real lastStartCastTime
    boolean isCasting
    real currentRequiredCastTime
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
        set this.currentRequiredCastTime = 0.0
        set this.castingAbility = 0
        set this.currentComboIndex = 1 // only for difficulty HARD and above
        set this.comboTargetUnit = null
        set this.debugTextTag = null
        set this.debugTextTagContent = ""
        set this.debugTextTagTimer = null
        set this.pickingUpItem = null


        // Initialize combat data
        set this.combatData = InitializeHeroCombatData(this, inDifficulty)

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

    method setWaypointIndex takes integer newIndex returns nothing
        set this.currentWaypointIndex = newIndex
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

    method shouldCrossSeaOrTree takes nothing returns boolean
        if this.difficulty >= DIFF_HARD then
            // Have force staff item
            if this.combatData.hasItemOfFindTargetType(FIND_TARGET_TYPE_SELF_FORCE_STAFF) then
                return true
            endif
            // Have blink-liked ability
            // TODO:
        endif
        return false
    endmethod

    method shouldEnterCombat takes nothing returns boolean
        local integer i = 0
        local boolean hasReadyAbility = false
        local boolean hasReadyItem = false
            
        if IsUnitStunOrSilence(this.hero) then
            call this.botLog("Cannot enter combat, hero is stunned or silenced.")
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

        if this.currentState.stateID == STATE_HAZARD or IsCurrentGoalWaypoint(this) then
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
        local integer itemId = GetItemTypeId(itm)
        local real baseCooldown = GetItemBaseCooldown(itemId)
        local real castRange = GetItemCastRange(itemId)
        local real effectiveRadius = GetItemEffectiveRadius(itemId)
        local integer castType = GetItemCastType(itemId)
        local integer findTargetType = GetItemFindTargetType(itemId)
        local boolean bIsPassive = GetItemIsPassive(itemId)
        local real requiredCastTime = GetItemRequiredCastTime(itemId)

        call this.botLog("Picked up item: " + GetItemName(itm))
        call this.setDebugTextTagContent("Item: Picked Up " + GetItemName(itm))
        call this.setDebugTextTagColorPreset("CYAN")
        call this.combatData.addItem(itm, itemId, baseCooldown, castRange, effectiveRadius, requiredCastTime, this.hero, bIsPassive, castType, findTargetType)
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
        call SetTextTagFadepoint(this.debugTextTag, - 1.0)

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