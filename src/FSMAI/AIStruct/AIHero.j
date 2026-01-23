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
    AIAbility castingAbility
    timer updateTimer
    integer currentComboIndex
    unit comboTargetUnit
    texttag debugTextTag
    string debugTextTagContent
    timer debugTextTagTimer
    item pickingUpItem
    item givingItem
    destructable eatingTree
    integer lastCastingChannelAbilityId
    boolean isMovingForCast
    real lastX
    real lastY
    integer idleReissueCount
    real lastIdleReissueTime
        
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
        set this.givingItem = null
        set this.eatingTree = null
        set this.lastCastingChannelAbilityId = 0
        set this.isMovingForCast = false
        set this.lastX = GetUnitX(u)
        set this.lastY = GetUnitY(u)
        set this.idleReissueCount = 0
        set this.lastIdleReissueTime = 0.0


        // Initialize combat data
        set this.combatData = InitializeHeroCombatData(this, inDifficulty)

        call this.changeState(RunState.create())

            
        // Start the loop
        call SaveInteger(udg_TimerHeroMap, GetHandleId(this.updateTimer), 0, this)
        call TimerStart(this.updateTimer, UPDATE_PERIOD, true, function thistype.onUpdate)
            
        // Store unit to AIHero mapping
        call SaveInteger(udg_UnitAIHeroMap, GetHandleId(this.hero), 0, this)

        // Nerf or Buff hero based on difficulty
        if inDifficulty == DIFF_EASY then
            call this.applyEasyDifficultyModifiers()
        elseif inDifficulty == DIFF_NORMAL then
            // No changes for normal difficulty
        elseif inDifficulty == DIFF_HARD then
            // No changes for hard difficulty
        elseif inDifficulty == DIFF_CRAZY then
            call this.applyCrazyDifficultyModifiers()
        elseif inDifficulty == DIFF_NIGHTMARE then
            call this.applyNightmareDifficultyModifiers()
        endif

        if udg_bEnableBotTextTag then
            call this.createDebugTextTag()
        endif

        return this
    endmethod

    method getCastPoint takes nothing returns real
        return this.castPt
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

    method setWaypointIndex takes integer newIndex returns nothing
        local boolean hasNearbyEnemy = false
        if newIndex == 12 then
            if IsStoneManStable() then
                set hasNearbyEnemy = GetHeroCountAroundUnit(this.hero, HAZARD_NEAR_ENEMY_DETECT_RADIUS, FIND_TEAM_TYPE_ENEMIES) > 0
                if hasNearbyEnemy then
                    set this.currentWaypointIndex = 121 // Go to Stone wait area
                    call this.botLog("Stone Man is stable, going to wait area before Net Hazard, WPI: " + I2S(this.currentWaypointIndex))
                    return
                endif
            endif
        endif
        set this.currentWaypointIndex = newIndex
        call this.botLog("Setting WPI to: " + I2S(newIndex))
    endmethod

    method updateWaypointAfterAnyKindOfTeleport takes nothing returns nothing
        local real teleportX = GetUnitX(this.hero)
        local real teleportY = GetUnitY(this.hero)
        local integer previousIndex = this.currentWaypointIndex
        local integer newWaypointIndex

        // cross sea special case handling
        if previousIndex == 31 then
            set previousIndex = 3
        endif
        if previousIndex == 131 then
            set previousIndex = 13
        endif

        set newWaypointIndex = GetNearestForwardWaypointIndex(previousIndex - 1, teleportX, teleportY)

        call this.botLog("Updating waypoint after any kind of teleport. Current Index: " + I2S(this.currentWaypointIndex) + ", New Index: " + I2S(newWaypointIndex))
        
        if newWaypointIndex > this.currentWaypointIndex then
            set this.currentWaypointIndex = newWaypointIndex
            call this.moveToNextWaypoint()
            call this.botLog("Updated waypoint after teleport to index: " + I2S(newWaypointIndex))
        endif

        // update track progress, if close to TopRight rather than BotRight, set to 1, otherwise set to 2
        if teleportX <= - 20596.0 and teleportY >= 18822.0 then
            // belong to top left area, no need to update
            call this.botLog("Teleport in Top Left area, no track progression update needed.")
            return
        endif
        if DistanceBetweenXY(teleportX, teleportY, TopRightAreaCenterX, TopRightAreaCenterY) < DistanceBetweenXY(teleportX, teleportY, BotRightAreaCenterX, BotRightAreaCenterY) then
            call SaveInteger(udg_HeroTrackProgressionMap, GetHandleId(this.hero), S2I("trackProgress"), 1)
            call this.botLog("Updated track progression to 1 (Top Right side)")
        else
            call SaveInteger(udg_HeroTrackProgressionMap, GetHandleId(this.hero), S2I("trackProgress"), 2)
            call this.botLog("Updated track progression to 2 (Bottom Right side)")
        endif

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

    method shouldGoThroughThreeFish takes nothing returns boolean
        return not IsThreeFishHazardStable()
    endmethod

    method shouldCrossSeaOrTree takes nothing returns boolean
        local AIAbility crossingAbility
        if this.difficulty >= DIFF_HARD then
            if IsHeroGoaled(this.hero) then
                return false
            endif

            // Have force staff item
            if this.combatData.hasItemOfFindTargetType(FIND_TARGET_TYPE_SELF_FORCE_STAFF) then
                return true
            endif
            // Have blink-liked item or ability
            if this.combatData.hasItemOfCastType(CAST_POINT_BLINK) then
                return true
            endif
            if this.combatData.hasAbilityOfCastType(CAST_POINT_BLINK) then
                set crossingAbility = this.combatData.getAbilityOfCastType(CAST_POINT_BLINK)
                if crossingAbility != 0 then
                    if crossingAbility.isCooldownReady(this.difficulty) then
                        return true
                    endif
                endif
                return true
            endif
            if this.combatData.hasAbilityOfCastType(CAST_INSTANT_JUMP) then
                set crossingAbility = this.combatData.getAbilityOfCastType(CAST_INSTANT_JUMP)
                if crossingAbility != 0 then
                    if crossingAbility.isCooldownReady(this.difficulty) then
                        return true
                    endif
                endif
                return true
            endif
        endif
        return false
    endmethod

    method shouldEnterCombat takes nothing returns boolean
        local integer i = 0
        local boolean hasReadyAbility = false
        local boolean hasReadyItem = false
        local player randomEnemyPlayer = Player(11)

        if IsUnitInvisible(this.hero, randomEnemyPlayer) then
            // call this.botLog("Cannot enter combat, hero is invisible.")
            call this.setDebugTextTagContent("Run: Invisible")
            call this.setDebugTextTagColorPreset("YELLOW")
            return false
        endif
            
        if IsUnitStunOrSilence(this.hero) then
            // call this.botLog("Cannot enter combat, hero is stunned or silenced.")
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

        if not IsHeroGoaled(this.hero) then
            if this.currentState.stateID == STATE_HAZARD or IsCurrentGoalWaypoint(this) or this.currentState.stateID == STATE_DEAD then
                set searchRadius = PICKUP_ITEM_RANGE_SMALL
            else
                set searchRadius = PICKUP_ITEM_RANGE_NORMAL
            endif
        else
            set searchRadius = PICKUP_ITEM_RANGE_LARGE
        endif

        set this.pickingUpItem = GetSuitablePickupItemInRange(this.hero, searchRadius)
    endmethod

    method shouldEnterPickupItemState takes nothing returns boolean
        local boolean bIsInventoryFull = IsUnitInventoryFull(this.hero)

        if not IsAIHardOrAbove(this.difficulty) then
            return false
        endif

        if bIsInventoryFull then
            return false
        endif

        // call this.botLog("should enter: Item found to pick up: " + GetItemName(this.pickingUpItem))
        return this.pickingUpItem != null
    endmethod

    method TryEnterPickupItemState takes nothing returns boolean
        if not IsUnitValid(this.hero) then
            return false
        endif

        call this.searchPickupItemAround()
        if this.shouldEnterPickupItemState() then
            call this.botLog("Entering Pickup Item State")
            call this.setDebugTextTagContent(StateId2String(this.currentState) + ": Entering Pickup Item")
            call this.setDebugTextTagColorPreset("CYAN")
            call this.changeState(PickUpItemState.create())
            return true
        endif
        return false
    endmethod

    method TryEnterGiveItemState takes nothing returns boolean
        local item itmToGive = null
        local unit targetUnit = null

        if not IsUnitValid(this.hero) then
            return false
        endif

        if GetUnitLifePercent(this.hero) > FORCE_USE_ITEM_HP_PERCENTAGE_THRESHOLD then
            return false
        endif

        set itmToGive = this.combatData.getAnyItemToGive()
        if itmToGive == null then
            return false
        endif

        set targetUnit = FindBackOrCloseTargetInRange(this.hero, GIVE_ITEM_RANGE, 150.0, false, true, FIND_TEAM_TYPE_ALLIES, 0, 0)
        if targetUnit == null then
            return false
        endif

        if IsUnitInventoryFull(targetUnit) then
            return false
        endif

        set this.givingItem = itmToGive
        call this.changeState(GiveItemState.create(targetUnit))
        return true
    endmethod
        
    method shouldEnterHazardState takes nothing returns boolean
        local boolean hasNearbyEnemy = false

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

        if IsInOrangeFishWaitArea(this) then
            set hasNearbyEnemy = GetHeroCountAroundUnit(this.hero, HAZARD_NEAR_ENEMY_DETECT_RADIUS, FIND_TEAM_TYPE_ENEMIES) > 0
            if IsOrangeFishStable() and hasNearbyEnemy then
                return true
            endif
        endif

        if IsInPurpleFishWaitArea(this) then
            set hasNearbyEnemy = GetHeroCountAroundUnit(this.hero, HAZARD_NEAR_ENEMY_DETECT_RADIUS, FIND_TEAM_TYPE_ENEMIES) > 0
            if IsPurpleFishStable() and hasNearbyEnemy then
                return true
            endif
        endif

        return false
    endmethod

    method tryEnterHazardState takes nothing returns boolean
        if not IsUnitValid(this.hero) then
            return false
        endif

        if this.shouldEnterHazardState() then
            call this.botLog("Spike hazard detected - entering spike dodge state")
            call this.changeState(HazardState.create())
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
        local real currentX = GetUnitX(this.hero)
        local real currentY = GetUnitY(this.hero)
        local real movedDistance = DistanceBetweenXY(currentX, currentY, this.lastX, this.lastY)

        if this != null and this.currentState != null then
            // Sudden teleport detection
            set this.lastX = GetUnitX(this.hero)
            set this.lastY = GetUnitY(this.hero)
            if movedDistance > 550.0 then
                call this.updateWaypointAfterAnyKindOfTeleport()
            endif

            // Check if hero died and transition to dead state if needed
            if not IsUnitAliveBJ(this.hero) and this.currentState.stateID != STATE_DEAD then
                call this.changeState(DeadState.create())
            else
                call this.currentState.onUpdate()
            endif
        endif

        if this.eatingTree != null then
            if GetDestructableLife(this.eatingTree) <= 0.0 then
                set this.eatingTree = null
                call this.botLog("Finished eating tree.")
            endif
        endif

    endmethod

    method setCurrentCastingAbility takes AIAbility abil returns nothing
        set this.isCasting = true
        set this.castingAbility = abil
        call this.botLog("Set current casting ability to: " + abil.orderString)
    endmethod

    method resetIsCasting takes nothing returns nothing
        set this.isCasting = false
        set this.castingAbility = 0
        call this.botLog("Reset isCasting flag and castingAbility.")
    endmethod

    method onCastComplete takes nothing returns nothing
        local real currentTime = TimerGetElapsed(gameTimer)
        local integer difficulty = this.difficulty

        if this.castingAbility != 0 then
            set this.castingAbility.lastCastTime = currentTime
            // Advance combo index if casting combo ability
            if IsDifficultyApplyingCombo(difficulty) and this.castingAbility.comboIndex > 0 then
                set this.currentComboIndex = this.currentComboIndex + 1
                call this.botLog("Advancing combo index to: " + I2S(this.currentComboIndex))
                // If no further combo ability, reset combo index
                if this.combatData.getAbilityByComboIndex(this.currentComboIndex) == 0 then
                    set this.currentComboIndex = 1
                    set this.comboTargetUnit = null
                    call this.botLog("Combo sequence complete, resetting combo index to 1, reset combo target.")
                endif
            endif
            call this.botLog("Casting complete for ability (start CD): " + this.castingAbility.orderString + ", current combo index: " + I2S(this.currentComboIndex))
            call this.setDebugTextTagContent("Combat: " + this.castingAbility.orderString + " done, CCI: " + I2S(this.currentComboIndex))
            call this.setDebugTextTagColorPreset("RED")
        else
            call this.botLog("Casting complete but no casting ability recorded. No CD started. (could be item)")
        endif

        call resetIsCasting()
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
        local integer manaCost = GetItemManaCost(itemId)

        call this.botLog("Picked up item: " + GetItemName(itm))
        call this.setDebugTextTagContent("Item: Picked Up " + GetItemName(itm))
        call this.setDebugTextTagColorPreset("CYAN")
        call this.combatData.addItem(itm, itemId, baseCooldown, castRange, effectiveRadius, requiredCastTime, manaCost, this.hero, bIsPassive, castType, findTargetType)
    endmethod

    method onBeTargetedByEnemyAbilityImmediate takes unit caster, integer abilityId returns nothing
        local AIAbility shadowmeldAbil
        local boolean bIsProjectileAbility = IsTargetUnitProjectileAbility(abilityId)
        local real distanceToEnemyCaster = 0.0
        local real projectileSpeed = 0.0

        if IsNightTime() then
            set shadowmeldAbil = this.combatData.getAbilityOfCastType(CAST_INSTANT_SELF_SHADOWMELD)
            if shadowmeldAbil != 0 then
                if not shadowmeldAbil.bIsReadyToCast then
                    if bIsProjectileAbility then
                        set distanceToEnemyCaster = DistanceBetweenUnits(this.hero, caster)
                        set projectileSpeed = GetNonAIAbilityProjectileSpeed(abilityId)
                        if distanceToEnemyCaster > projectileSpeed * 1.0 then
                            call shadowmeldAbil.markAsReadyToCast()
                            call this.botLog("Marking Shadowmeld ability as ready to cast due to being targeted by projectile ability: " + GetObjectName(abilityId))
                        endif
                    endif
                endif
            endif
        endif
    endmethod

    method onBeTargetedByEnemyAbilityProjectileDelayed takes unit caster, integer abilityId returns nothing
        local AIItem selfDefenseItem
        local AIAbility selfDefenseAbility

        set selfDefenseItem = this.combatData.getAnySelfDefenseItem()
        if selfDefenseItem != 0 then
            if not selfDefenseItem.bIsReadyToUse then
                call selfDefenseItem.markAsReadyToUse()
                call this.botLog("Marking self-defense item as ready to use: " + GetItemName(selfDefenseItem.itemHandle))
                return
            endif
        endif
        set selfDefenseAbility = this.combatData.getAnySelfDefenseAbility()
        if selfDefenseAbility != 0 then
            if not selfDefenseAbility.bIsReadyToCast then
                call selfDefenseAbility.markAsReadyToCast()
                call this.botLog("Marking self-defense ability as ready to cast: " + selfDefenseAbility.orderString)
                return
            endif
        endif

    endmethod

    method onBeTargetedByEnemyAttack takes unit attacker returns nothing
        local AIItem selfDefenseItem
        local AIAbility selfDefenseAbility
        // call this.botLog("Hero is being targeted by enemy attack from unit: " + GetUnitName(attacker))
        set selfDefenseItem = this.combatData.getAnySelfDefenseItem()
        if selfDefenseItem != 0 then
            if not selfDefenseItem.bIsReadyToUse then
                call this.botLog("Marking self-defense item as ready to use: " + GetItemName(selfDefenseItem.itemHandle))
                call selfDefenseItem.markAsReadyToUse()
                return
            endif
        endif
        set selfDefenseAbility = this.combatData.getAnySelfDefenseAbility()
        if selfDefenseAbility != 0 then
            if not selfDefenseAbility.bIsReadyToCast then
                call this.botLog("Marking self-defense ability as ready to cast: " + selfDefenseAbility.orderString)
                call selfDefenseAbility.markAsReadyToCast()
                return
            endif
        endif
    endmethod

    method onBeMeatHookedReturnFinish takes nothing returns nothing
        call this.updateWaypointAfterAnyKindOfTeleport()
    endmethod

    method onBeTargetedByBomberSelfDestruct takes boolean isMegaBomber returns nothing
        local AIAbility shadowmeldAbil = 0
        local unit nearbyEnemyUnit = null
        if not isMegaBomber then
            if IsNightTime() then
                set shadowmeldAbil = this.combatData.getAbilityOfCastType(CAST_INSTANT_SELF_SHADOWMELD)
                if shadowmeldAbil != 0 then
                    if not shadowmeldAbil.bIsReadyToCast then
                        call shadowmeldAbil.markAsReadyToCast()
                        call this.botLog("Marked Shadowmeld ability as ready to cast due to being targeted by Bomber Self-Destruct.")
                    endif
                endif
            endif
        else
            // Mega Bomber, follow an enemy nearby if possible
            set nearbyEnemyUnit = FindBackOrCloseTargetInRange(this.hero, 1000.0, 150.0, false, false, FIND_TEAM_TYPE_ENEMIES, 0, 0)
            if nearbyEnemyUnit != null then
                call this.changeState(FollowState.create(nearbyEnemyUnit, 20.0, 0, true))
            endif
        endif
    endmethod

    method getBlockingUnitAround takes real detectRadius, boolean bCheckBehind returns unit
        local group blockingUnitGroup = CreateGroup()
        local unit u // for enumerating units
        local real heroX = GetUnitX(this.hero)
        local real heroY = GetUnitY(this.hero)
        local unit resultUnit = null
        local boolexpr filter = Filter(function AntiLeak)
        local real closestDistance = 99999.0
        local real currentTargetDistance
            
        call GroupEnumUnitsInRange(blockingUnitGroup, heroX, heroY, detectRadius, filter)
        loop
            set u = FirstOfGroup(blockingUnitGroup)
            exitwhen u == null

            call GroupRemoveUnit(blockingUnitGroup, u)
            if this.checkBlockingUnit(u, bCheckBehind) then
                set currentTargetDistance = DistanceBetweenXY(heroX, heroY, GetUnitX(u), GetUnitY(u))
                if currentTargetDistance < closestDistance then
                    set closestDistance = currentTargetDistance
                    set resultUnit = u
                endif
            endif
        endloop
        call DestroyGroup(blockingUnitGroup)
            
        return resultUnit
    endmethod

    method checkBlockingUnit takes unit u, boolean bCheckBehind returns boolean
        if u == this.hero then
            return false
        endif
        if not IsUnitValid(u) then
            return false
        endif
        if bCheckBehind then
            if IsUnitInFrontOfUnit(u, this.hero) then
                return false
            endif
        else
            if not IsUnitInFrontOfUnit(u, this.hero) then
                return false
            endif
        endif
        // call this.botLog("Blocking unit found: " + GetUnitName(u))
        return true
    endmethod

    method tryAvoidBlockingUnit takes nothing returns boolean
        local unit blockingUnit
        local boolean hasBlockingUnitAhead = false
        local boolean hasBlockingUnitBehind = false
        local real blockDetectRadius = 100.0

        // Check for blocking units ahead
        set blockingUnit = this.getBlockingUnitAround(blockDetectRadius, false)
        set hasBlockingUnitAhead = blockingUnit != null
        if hasBlockingUnitAhead then
            // call this.botLog("Blocking unit detected ahead, dodging")
            call this.setDebugTextTagContent(StateId2String(this.currentState.stateID) + ": Dodging Blocking Unit Ahead")
            call this.setDebugTextTagColorPreset("YELLOW")
            call this.avoidTargetUnitAhead(blockingUnit, GetUnitMoveSpeed(blockingUnit) * 0.1, 2.0, true)
            return true
        endif
        // Check for blocking units behind
        set blockingUnit = this.getBlockingUnitAround(blockDetectRadius, true)
        set hasBlockingUnitBehind = blockingUnit != null
        if hasBlockingUnitBehind then
            // call this.botLog("Blocking unit detected behind, dodging")
            call this.setDebugTextTagContent(StateId2String(this.currentState.stateID) + ": Dodging Blocking Unit Behind")
            call this.setDebugTextTagColorPreset("YELLOW")
            call this.avoidTargetUnitBehind(blockingUnit, false, 2.0, true)
            return true
        endif

        return false
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
        // call this.botLog("heroMovingAngle: " + R2S(heroMovingAngle) + ", predictedTargetUnitToHeroAngle: " + R2S(predictedTargetUnitToHeroAngle))
        // call this.botLog("Calculated avoidAngle: " + R2S(avoidAngle))
        if bLeanTowardWaypoint then
            set avoidAngle = GetMiddleAngle(heroMovingAngle, avoidAngle)
            // call this.botLog("Leaning 2x toward waypoint, new avoidAngle: " + R2S(avoidAngle))
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
                // call this.botLog("Initial avoidAngle (forward): " + R2S(avoidAngle) + ", heroToNextWaypointAngle: " + R2S(heroToNextWaypointAngle) + ", targetUnitToHeroAngle: " + R2S(targetUnitToHeroAngle))
            else
                set avoidAngle = GetMiddleAngle(NormalizeAngle(heroToNextWaypointAngle + 180.0), targetUnitToHeroAngle)
                // call this.botLog("Initial avoidAngle (backward): " + R2S(avoidAngle) + ", heroToNextWaypointAngle: " + R2S(heroToNextWaypointAngle) + ", targetUnitToHeroAngle: " + R2S(targetUnitToHeroAngle))
            endif
        else
            set avoidAngle = GetMiddleAngle(heroToNextWaypointAngle, targetUnitToHeroAngle)
            // call this.botLog("Initial avoidAngle (backward): " + R2S(avoidAngle) + ", heroToNextWaypointAngle: " + R2S(heroToNextWaypointAngle) + ", targetUnitToHeroAngle: " + R2S(targetUnitToHeroAngle))
            if bLeanTowardWaypoint then
                set avoidAngle = GetMiddleAngle(heroToNextWaypointAngle, avoidAngle)
                // call this.botLog("Leaning 2x toward waypoint, new avoidAngle: " + R2S(avoidAngle))
            endif
        endif

        call this.botLog("Avoiding target unit behind: " + GetUnitName(targetUnit))
        // call this.botLog("Calculated avoidAngle: " + R2S(avoidAngle))
        set moveX = heroX + moveDistance * Cos(avoidAngle * bj_DEGTORAD)
        set moveY = heroY + moveDistance * Sin(avoidAngle * bj_DEGTORAD)

        call IssuePointOrder(this.hero, "move", moveX, moveY)
    endmethod

    method tryEnterCombat takes nothing returns boolean
        if not IsUnitValid(this.hero) then
            return false
        endif

        call this.combatData.tryPrepareTargetForItems()
        call this.combatData.tryPrepareTargetForAbilities()

        // Check if we should enter combat state
        if this.shouldEnterCombat() then
            call this.botLog(StateId2String(this.currentState.stateID) + " Entering combat - abilities or item ready")
            call this.changeState(CombatState.create())
            return true
        endif
        return false
    endmethod

    method applyEasyDifficultyModifiers takes nothing returns nothing
        // -400 HP
        call UnitAddItemByIdSwapped( 'I02K', this.hero)
        call UnitAddItemByIdSwapped( 'I02K', this.hero)
        call UnitAddItemByIdSwapped( 'I02K', this.hero)
        call UnitAddItemByIdSwapped( 'I02K', this.hero)
        call this.botLog("Applied Easy difficulty modifiers: -400 HP")
    endmethod

    method applyCrazyDifficultyModifiers takes nothing returns nothing
        local real speedBoost = 10.0

        // Increase move speed
        call YDUserDataSet(unit, this.hero, "speed", real, (YDUserDataGet(unit, this.hero, "speed", real) + speedBoost))
        call SetUnitMoveSpeed(this.hero, GetUnitMoveSpeed(this.hero) + speedBoost)

        // +200 HP
        call UnitAddItemByIdSwapped( 'I00L', this.hero ) 
        call this.botLog("Applied Crazy difficulty modifiers: +5 move speed and +200 HP")
    endmethod

    method applyNightmareDifficultyModifiers takes nothing returns nothing
        local real speedBoost = 35.0

        // Increase move speed
        call YDUserDataSet(unit, this.hero, "speed", real, (YDUserDataGet(unit, this.hero, "speed", real) + speedBoost))
        call SetUnitMoveSpeed(this.hero, GetUnitMoveSpeed(this.hero) + speedBoost)

        // +400 HP
        call UnitAddItemByIdSwapped( 'I00L', this.hero ) 
        call UnitAddItemByIdSwapped( 'I00L', this.hero ) 
        call this.botLog("Applied Nightmare difficulty modifiers: +25 move speed and +400 HP")
    endmethod

    // =====================================================
    // Debug Text Tag Methods
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

    method botLog takes string msg returns nothing
        call BotLogWithPlayer(GetOwningPlayer(this.hero), msg)
    endmethod
        
    method botLogError takes string msg returns nothing
        call BotLogErrorWithPlayer(GetOwningPlayer(this.hero), msg)
    endmethod

    // =====================================================
endstruct