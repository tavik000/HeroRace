struct AIAbility
    // Ability configuration
    integer abilityId
    real baseCooldown
    integer castType
    real lastCastTime
    integer comboIndex  // For chaining abilities in sequence
    string orderString  
    integer orderId // if string is empty, use orderId to issue order
    integer manaCost    
    real castRange
    integer findTargetType
    real effectiveRadius
    real expectedDamage  // For combo targeting logic
    boolean isPassive
    real requiredCastTime
    boolean isIgnoreMagicImmune
    integer mustHaveBuffCodeWhenFollowing
    boolean shouldCheckOtherUnitBlockingTargetUnit
    real minTargetDistance
    real followTargetDuration
    real basePredictOffset
    real basePredictDelay
    real projectileSpeed

    // Runtime variables    
    boolean bIsReadyToCast
    real readyTargetPointX
    real readyTargetPointY
    unit readyTargetUnit
    location readyTargetPoint
    AIHero owner
    unit ownerHero

    static method create takes integer aid, AIHero inOwner, real cd, integer inCastType, string order, integer inOrderId, integer mana, real inCastRange, integer inFindTargetType, real inEffectiveRadius, integer inComboIndex, real inExpectedDamage, boolean inIsPassive, real inRequiredCastTime, boolean inIsIgnoreMagicImmune, integer inMustHaveBuffCodeWhenFollowing, boolean inShouldCheckOtherUnitBlockingTargetUnit, real inMinTargetDistance, real inFollowTargetDuration, real inBasePredictOffset, real inBasePredictDelay, real inProjectileSpeed returns thistype
        local thistype this = thistype.allocate()
        set this.abilityId = aid
        set this.baseCooldown = cd
        set this.castType = inCastType
        set this.lastCastTime = 0.0
        set this.comboIndex = inComboIndex
        set this.orderString = order
        set this.orderId = inOrderId
        set this.manaCost = mana
        set this.castRange = inCastRange
        set this.findTargetType = inFindTargetType
        set this.effectiveRadius = inEffectiveRadius
        set this.expectedDamage = inExpectedDamage
        set this.bIsReadyToCast = false
        set this.readyTargetPointX = 0.0
        set this.readyTargetPointY = 0.0
        set this.readyTargetUnit = null
        set this.readyTargetPoint = null
        set this.owner = inOwner
        set this.ownerHero = inOwner.hero
        set this.isPassive = inIsPassive
        set this.requiredCastTime = inRequiredCastTime
        set this.isIgnoreMagicImmune = inIsIgnoreMagicImmune
        set this.mustHaveBuffCodeWhenFollowing = inMustHaveBuffCodeWhenFollowing
        set this.shouldCheckOtherUnitBlockingTargetUnit = inShouldCheckOtherUnitBlockingTargetUnit
        set this.minTargetDistance = inMinTargetDistance
        set this.followTargetDuration = inFollowTargetDuration
        set this.basePredictOffset = inBasePredictOffset
        set this.basePredictDelay = inBasePredictDelay
        set this.projectileSpeed = inProjectileSpeed
        return this
    endmethod

    method isCooldownReady takes integer difficulty returns boolean
        local real currentTime = TimerGetElapsed(gameTimer)
        local real requiredCooldown 
        local real cooldownMultiplier = GetCooldownMultiplier(difficulty)
        if this.lastCastTime == 0.0 then
            return true
        endif
        set requiredCooldown = this.baseCooldown * cooldownMultiplier
        if currentTime >= this.lastCastTime + requiredCooldown then
            return true
        endif
        return false
    endmethod


    method isManaReady takes unit caster returns boolean
        local real currentMana = GetUnitState(caster, UNIT_STATE_MANA)
        if currentMana >= I2R(this.manaCost) then
            return true
        endif
        return false
    endmethod

    method customFilter takes unit u returns boolean
        // Custom filtering logic for specific abilities
        if this.abilityId == 'A00W' then  // Banish ability
            if UnitHasBuffBJ(u, 'BHbn') then
                call this.botLog("Skipping banish target, already banished, unit: " + GetUnitName(u))
                return false
            endif
        endif
        return true
    endmethod

    method getUnitOffsetDistance takes unit targetUnit returns real
        local real targetMoveSpeed = GetUnitMoveSpeed(targetUnit)
        local real projectileSpeed = this.projectileSpeed
        local real targetDistance = DistanceBetweenUnits(this.ownerHero, targetUnit)
        local real baseOffset = this.basePredictOffset
        local real baseDelay = this.basePredictDelay
        local integer ownerUnitTypeId = GetUnitTypeId(this.ownerHero)
        local real ownerCastPoint = owner.getCastPoint()
        local integer currentOrder
        local real timeToReachTarget = 0.0
        local real offsetDistance = 0.0
        local boolean isFront = true
        local real projectileTravelTime = 0.0

        if this.castType != CAST_POINT_ENEMY_FRONT and this.castType != CAST_POINT_ALL_FRONT and this.castType != CAST_POINT_ALLY_FRONT and this.castType != CAST_POINT_ENEMY_BEHIND and this.castType != CAST_POINT_SELF_BEHIND_ENEMY_CROWDED then
            call this.botLogError("getUnitOffsetDistance called for non-front-cast ability: " + GetObjectName(this.abilityId))
            return 0.0
        endif

        if this.castType == CAST_POINT_ENEMY_BEHIND then
            set isFront = false
        endif

        set currentOrder = GetUnitCurrentOrder(targetUnit)
        if currentOrder == 0 then
            set targetMoveSpeed = 0.0
        endif

        if IsUnitStun(targetUnit) then
            // Cannot move
            set targetMoveSpeed = 0.0
        endif

        if projectileSpeed > 0.0 then
            set projectileTravelTime = targetDistance / projectileSpeed
        else
            set projectileTravelTime = 0.0
        endif

        if this.abilityId == 'A00S' then  // Flame Strike
            set timeToReachTarget = 0.0
            set baseOffset = 0.0
            if targetMoveSpeed > 0.0 then
                set offsetDistance = this.effectiveRadius
            else
                set offsetDistance = 0.0
            endif
        else
            if isFront then
                set offsetDistance = targetMoveSpeed * (baseDelay + ownerCastPoint + projectileTravelTime) + baseOffset
            else
                set offsetDistance = - targetMoveSpeed * (baseDelay + ownerCastPoint + projectileTravelTime) + baseOffset
            endif
        endif
        return offsetDistance
    endmethod

    method canCastAbility takes nothing returns boolean
        // Check if hero is stunned or silenced
        if IsUnitStunOrSilence(owner.hero) then
            call this.botLog("Cannot cast ability, hero is stunned or silenced.")
            call owner.setDebugTextTagContent("Combat: " + this.orderString + " - Stunned/Silenced")
            call owner.setDebugTextTagColorPreset("YELLOW")
            return false
        endif

        // Check if ability is available
        if GetUnitAbilityLevel(owner.hero, this.abilityId) <= 0 then
            call BotLogError("Ability not available: " + this.orderString)
            return false
        endif
            
        // Check if hero has enough mana
        if not this.isManaReady(owner.hero) then
            // call this.botLog("Not enough mana for ability: " + this.orderString)
            call owner.setDebugTextTagContent("Combat: " + this.orderString + " - Not Enough Mana")
            call owner.setDebugTextTagColorPreset("RED")
            return false
        endif
            
        return true
    endmethod

    method shouldUpdateComboTarget takes unit targetUnit returns boolean
        if targetUnit == null then
            return false
        endif

        if not IsDifficultyApplyingCombo(owner.difficulty) then
            return false
        endif
            
        if this.comboIndex <= 0 then
            return false
        endif
            
        if owner.comboTargetUnit == targetUnit then
            return false
        endif
            
        return true
    endmethod

    method markAsReadyToCast takes nothing returns nothing
        set this.bIsReadyToCast = true
        set this.readyTargetUnit = this.ownerHero
    endmethod

    method resetNotReadyToCast takes nothing returns nothing
        set this.bIsReadyToCast = false
        set this.readyTargetUnit = null
        set this.readyTargetPoint = null
        set this.readyTargetPointX = 0.0
        set this.readyTargetPointY = 0.0
        call this.botLog("Resetting not ready to cast for ability: " + GetObjectName(this.abilityId))
    endmethod

    method tryPrepareTarget takes nothing returns nothing
        local integer targetUnitCount

        if this.castType == CAST_NONE then
            return
        elseif this.castType == CAST_INSTANT then
            set this.bIsReadyToCast = true
            call this.botLog("Instant ability ready to cast: " + GetObjectName(this.abilityId))
        elseif this.castType == CAST_INSTANT_BACK_ENEMY then
            set this.readyTargetUnit = FindTargetUnitForAbility(this.owner, this)
            set this.bIsReadyToCast = this.readyTargetUnit != null
        elseif this.castType == CAST_INSTANT_ENEMY_CROWDED then
            set targetUnitCount = GetHeroCountAroundUnit(this.ownerHero, this.effectiveRadius, FIND_TEAM_TYPE_ENEMIES)
            if targetUnitCount > 1 then
                call this.botLog("Found " + I2S(targetUnitCount) + " enemy heroes around for ability: " + GetObjectName(this.abilityId))
            endif
            set this.bIsReadyToCast = targetUnitCount >= 2
        elseif this.castType == CAST_INSTANT_BACK_ALLY then
            set this.readyTargetUnit = FindTargetUnitForAbility(this.owner, this)
            set this.bIsReadyToCast = this.readyTargetUnit != null
        elseif this.castType == CAST_INSTANT_ALLY_CROWDED then
            set targetUnitCount = GetHeroCountAroundUnit(this.ownerHero, this.effectiveRadius, FIND_TEAM_TYPE_ALLIES)
            if targetUnitCount > 1 then
                call this.botLog("Found " + I2S(targetUnitCount) + " allied heroes around for ability: " + GetObjectName(this.abilityId))
            endif
            set this.bIsReadyToCast = targetUnitCount >= 2
        elseif this.castType == CAST_INSTANT_ALLY_DEFENSE_AND_CLEANSE then
            // if any CCed ally around 
            set this.readyTargetUnit = FindCCedTargetInRange(owner.hero, this.effectiveRadius, FIND_TEAM_TYPE_ALLIES, true, this, 0)
            if this.readyTargetUnit != null then
                call owner.botLog("Found CC'ed ally target for ability: " + GetObjectName(this.abilityId))
            endif
            set this.bIsReadyToCast = this.readyTargetUnit != null
        elseif this.castType == CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE then
            // will be set when being targeted by other ability, or taken damage
        elseif this.castType == CAST_INSTANT_ALL_CROWDED then
            set targetUnitCount = GetHeroCountAroundUnit(this.ownerHero, this.effectiveRadius, FIND_TEAM_TYPE_ALL)
            if targetUnitCount > 0 then
                call this.botLog("Found " + I2S(targetUnitCount) + " heroes around for ability: " + GetObjectName(this.abilityId))
            endif
            set this.bIsReadyToCast = targetUnitCount >= 2
        elseif this.castType == CAST_INSTANT_HEAL then
            set this.bIsReadyToCast = GetUnitLifePercent(this.ownerHero) <= HEAL_HP_PERCENTAGE_THRESHOLD
        elseif this.castType == CAST_INSTANT_COMBO_TARGET_NOT_CC then
            if not IsUnitValid(owner.comboTargetUnit) then
                set this.bIsReadyToCast = false
                return
            endif
            set this.bIsReadyToCast = not IsUnitStun(owner.comboTargetUnit)
            if this.bIsReadyToCast then
                call this.botLog("Ready Done! Combo target is not CC'ed for ability: " + GetObjectName(this.abilityId))
            endif
        elseif this.castType == CAST_POINT_ENEMY_FRONT then
            if this.findTargetType == FIND_TARGET_TYPE_NONE then
                call this.botLogError("Ability find target type is FIND_TARGET_TYPE_NONE, cannot prepare ability: " + GetObjectName(this.abilityId))
                return
            endif
            // set point when casting, set target unit now
            set this.readyTargetUnit = FindTargetUnitForAbility(this.owner, this)
            set this.bIsReadyToCast = this.readyTargetUnit != null
        elseif this.castType == CAST_POINT_ENEMY_BEHIND then
            if this.findTargetType == FIND_TARGET_TYPE_NONE then
                call this.botLogError("Ability find target type is FIND_TARGET_TYPE_NONE, cannot prepare ability: " + GetObjectName(this.abilityId))
                return
            endif
            // set point when casting, set target unit now
            set this.readyTargetUnit = FindTargetUnitForAbility(this.owner, this)
            set this.bIsReadyToCast = this.readyTargetUnit != null
        elseif this.castType == CAST_POINT_ENEMY_CROWDED then
            // the final target point will be find again when casting
            set this.readyTargetPoint = FindPointAroundCrowdedHeroes(this.owner, this.effectiveRadius, FIND_TEAM_TYPE_ENEMIES)
            set this.readyTargetPointX = GetLocationX(this.readyTargetPoint)
            set this.readyTargetPointY = GetLocationY(this.readyTargetPoint)
            call RemoveLocation(this.readyTargetPoint)
            set this.bIsReadyToCast = (not IsNearlyZero(this.readyTargetPointX) and not IsNearlyZero(this.readyTargetPointY))
        elseif this.castType == CAST_POINT_SELF_BEHIND_ENEMY_CROWDED then
            set targetUnitCount = GetHeroCountAroundUnit(this.ownerHero, this.effectiveRadius, FIND_TEAM_TYPE_ENEMIES)
            if targetUnitCount >= 2 then
                call this.botLog("Found " + I2S(targetUnitCount) + " enemy heroes around for ability: " + GetObjectName(this.abilityId))
                set this.readyTargetUnit = this.ownerHero
                set this.bIsReadyToCast = this.readyTargetUnit != null
            endif
        elseif this.castType == CAST_POINT_SELF_FRONT_HEAL then
            if GetUnitLifePercent(this.ownerHero) <= HEAL_HP_PERCENTAGE_THRESHOLD then
                set this.readyTargetUnit = this.ownerHero
            else
                set this.readyTargetUnit = null
            endif
            set this.bIsReadyToCast = this.readyTargetUnit != null
        elseif this.castType == CAST_UNIT then
            if this.findTargetType == FIND_TARGET_TYPE_NONE then
                call this.botLogError("Ability find target type is FIND_TARGET_TYPE_NONE, cannot prepare ability: " + GetObjectName(this.abilityId))
                return
            endif
            set this.readyTargetUnit = FindTargetUnitForAbility(this.owner, this)
            set this.bIsReadyToCast = this.readyTargetUnit != null
            if this.readyTargetUnit != null then
                call owner.botLog("Found target unit: " + GetUnitName(this.readyTargetUnit) + " for unit ability: " + GetObjectName(this.abilityId))
            endif
        else
            call this.botLogError("Ability cast type not implemented for prepare target: " + I2S(this.castType) + " for ability: " + GetObjectName(this.abilityId))
            set this.readyTargetUnit = null
            set this.bIsReadyToCast = false
            return
        endif

        if this.readyTargetUnit != null then
            if this.shouldUpdateComboTarget(this.readyTargetUnit) then
                set owner.comboTargetUnit = this.readyTargetUnit
                call owner.botLog("Updated combo target to unit: " + GetUnitName(this.readyTargetUnit) + " for ability: " + GetObjectName(this.abilityId))
            endif
        endif

    endmethod

    method castInstant takes nothing returns nothing
        if this.orderString == "none" then
            call IssueImmediateOrderById(owner.hero, this.orderId)
            call this.botLog("Casting instant ability by orderId: " + I2S(this.orderId))
        else
            call IssueImmediateOrder(owner.hero, this.orderString)
            call this.botLog("Casting instant ability by orderString: " + this.orderString)
        endif
        if this.requiredCastTime <= 0.0 then
            call this.owner.moveToNextWaypoint()
        endif
        call this.botLog("Casting instant ability: " + this.orderString)
        call this.resetNotReadyToCast()
    endmethod

    method castPoint takes real targetX, real targetY returns nothing
        call IssuePointOrder(owner.hero, this.orderString, targetX, targetY)
        call this.botLog("Casting point ability at: (" + R2S(targetX) + ", " + R2S(targetY) + ") for ability: " + this.orderString)
        call this.resetNotReadyToCast()
    endmethod

    method castUnit takes unit targetUnit returns nothing
        if targetUnit == null then
            call this.botLogError("Cannot cast unit ability, target unit is null for ability: " + this.orderString)
            return
        endif
        call IssueTargetOrder(owner.hero, this.orderString, targetUnit)
        call this.botLog("Casting unit ability on target: " + GetUnitName(targetUnit) + " for ability: " + this.orderString)
        call this.resetNotReadyToCast()
    endmethod

    method tryCast takes nothing returns boolean
        local unit targetUnit = null
        local integer targetUnitCount = 0
        local real targetFacingAngle
        local real offset
        local unit hazardUnitAround = null
            
        call this.botLog("Attempting to cast ability: " + this.orderString)
        call this.owner.setCurrentCastingAbility(this)

        if not this.canCastAbility() then
            return false
        endif

        if not this.bIsReadyToCast then
            return false
        endif

        if this.castType == CAST_NONE then
            call this.botLogError("Cannot cast ability with CAST_NONE type: " + this.orderString)
            return false
        elseif this.castType == CAST_INSTANT then
            call this.castInstant()
            return true
        elseif this.castType == CAST_INSTANT_BACK_ENEMY then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for ability, should be blocked by prepare target: " + GetObjectName(this.abilityId))
                set this.readyTargetUnit = null
                set this.bIsReadyToCast = false
                return false
            endif

            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToCast = false
                return false
            endif

            if DistanceBetweenUnits(this.ownerHero, targetUnit) > this.effectiveRadius * 2.0 then
                set this.readyTargetUnit = null
                set this.bIsReadyToCast = false
                return false
            endif
            // Follow target unit
            if DistanceBetweenUnits(this.ownerHero, targetUnit) <= this.effectiveRadius then
                call this.castInstant()
                return true
            else
                call IssueTargetOrder(this.ownerHero, "move", targetUnit)
                return true
            endif
        elseif this.castType == CAST_INSTANT_ENEMY_CROWDED then
            call this.castInstant()
            return true
        elseif this.castType == CAST_INSTANT_BACK_ALLY then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for ability, should be blocked by prepare target: " + GetObjectName(this.abilityId))
                set this.readyTargetUnit = null
                set this.bIsReadyToCast = false
                return false
            endif

            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToCast = false
                return false
            endif

            if DistanceBetweenUnits(this.ownerHero, targetUnit) > this.effectiveRadius * 2.0 then
                set this.readyTargetUnit = null
                set this.bIsReadyToCast = false
                return false
            endif
            // Follow target unit
            if DistanceBetweenUnits(this.ownerHero, targetUnit) <= this.effectiveRadius then
                call this.castInstant()
                return true
            else
                call IssueTargetOrder(this.ownerHero, "move", targetUnit)
                return true
            endif
        elseif this.castType == CAST_INSTANT_ALLY_CROWDED then
            call this.castInstant()
            return true
        elseif this.castType == CAST_INSTANT_ALLY_DEFENSE_AND_CLEANSE then
            call this.castInstant()
            return true
        elseif this.castType == CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE then
            call this.castInstant()
            return true
        elseif this.castType == CAST_INSTANT_ALL_CROWDED then
            call this.castInstant()
            return true
        elseif this.castType == CAST_INSTANT_COMBO_TARGET_NOT_CC then
            if not IsUnitValid(owner.comboTargetUnit) then
                set this.bIsReadyToCast = false
                return false
            endif
            call this.botLog("combo target: " + GetUnitName(owner.comboTargetUnit) + " is not CC'ed, casting ability: " + GetObjectName(this.abilityId))
            call this.castInstant()
            return true
        elseif this.castType == CAST_POINT_ENEMY_FRONT then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLog("No target found for point ability: " + GetObjectName(this.abilityId))
                return false
            else
                // Calculate point in front of target unit
                set targetFacingAngle = GetUnitFacing(this.readyTargetUnit)
                set offset = this.getUnitOffsetDistance(targetUnit)
                set this.readyTargetPointX = GetUnitX(this.readyTargetUnit) + offset * Cos(targetFacingAngle * bj_DEGTORAD)
                set this.readyTargetPointY = GetUnitY(this.readyTargetUnit) + offset * Sin(targetFacingAngle * bj_DEGTORAD)
                call this.castPoint(this.readyTargetPointX, this.readyTargetPointY)
                return true 
            endif
        elseif this.castType == CAST_POINT_ENEMY_BEHIND then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLog("No target found for point ability: " + GetObjectName(this.abilityId))
                return false
            endif
            if not IsUnitValid(targetUnit) then
                call this.botLog("Target unit is not valid for ability: " + this.orderString)
                set this.bIsReadyToCast = false
                set this.readyTargetUnit = null
                return false
            endif
            // if there is hazard around, cast to hazard center + offset 150
            set hazardUnitAround = GetHazardAroundUnit(targetUnit, this.effectiveRadius)
            if hazardUnitAround != null then
                set this.readyTargetPointX = GetUnitX(hazardUnitAround) + 150.0 * Cos((GetUnitFacing(hazardUnitAround)) * bj_DEGTORAD)
                set this.readyTargetPointY = GetUnitY(hazardUnitAround) + 150.0 * Sin((GetUnitFacing(hazardUnitAround)) * bj_DEGTORAD)
                call this.botLog("Casting behind enemy to hazard center for ability: " + GetObjectName(this.abilityId))
                call this.castPoint(this.readyTargetPointX, this.readyTargetPointY)
                return true
            endif

            // fallback: Calculate point behind target unit
            set targetFacingAngle = GetUnitFacing(this.readyTargetUnit)
            set offset = this.getUnitOffsetDistance(targetUnit)
            set this.readyTargetPointX = GetUnitX(this.readyTargetUnit) - offset * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(this.readyTargetUnit) - offset * Sin(targetFacingAngle * bj_DEGTORAD)
            call this.castPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true 
        elseif this.castType == CAST_POINT_ENEMY_CROWDED then
            set this.readyTargetPoint = FindPointAroundCrowdedHeroes(this.owner, this.effectiveRadius, FIND_TEAM_TYPE_ENEMIES)
            set this.readyTargetPointX = GetLocationX(this.readyTargetPoint)
            set this.readyTargetPointY = GetLocationY(this.readyTargetPoint)
            call RemoveLocation(this.readyTargetPoint)
            if (IsNearlyZero(this.readyTargetPointX) and IsNearlyZero(this.readyTargetPointY)) then
                set this.bIsReadyToCast = false
                return false
            endif
            call this.castPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true
        elseif this.castType == CAST_POINT_SELF_BEHIND_ENEMY_CROWDED then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLog("No target found for point ability: " + GetObjectName(this.abilityId))
                return false
            endif
            if not IsUnitValid(targetUnit) then
                call this.botLog("Target unit is not valid for ability: " + this.orderString)
                set this.bIsReadyToCast = false
                set this.readyTargetUnit = null
                return false
            endif

            // fallback: Calculate point behind target unit
            set targetFacingAngle = GetUnitFacing(this.readyTargetUnit)
            set offset = this.getUnitOffsetDistance(targetUnit)
            set this.readyTargetPointX = GetUnitX(this.readyTargetUnit) - offset * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(this.readyTargetUnit) - offset * Sin(targetFacingAngle * bj_DEGTORAD)
            call this.castPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true 
        elseif this.castType == CAST_POINT_SELF_FRONT_HEAL then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No valid target found for ability, should be blocked by prepare target: " + GetObjectName(this.abilityId))
                set this.readyTargetUnit = null
                set this.bIsReadyToCast = false
                return false
            endif
            
            if not IsUnitValid(targetUnit) then
                set this.readyTargetUnit = null
                set this.bIsReadyToCast = false
                return false
            endif

            // Calculate point in front of self
            set targetFacingAngle = GetUnitFacing(this.ownerHero)
            set offset = this.castRange
            set this.readyTargetPointX = GetUnitX(this.ownerHero) + offset * Cos(targetFacingAngle * bj_DEGTORAD)
            set this.readyTargetPointY = GetUnitY(this.ownerHero) + offset * Sin(targetFacingAngle * bj_DEGTORAD)
            call this.castPoint(this.readyTargetPointX, this.readyTargetPointY)
            return true
        elseif this.castType == CAST_UNIT then
            set targetUnit = this.readyTargetUnit
            if targetUnit == null then
                call this.botLogError("No target found for unit ability: " + this.orderString)
                return false
            endif
            if not IsUnitValid(targetUnit) then
                call this.botLog("Target unit is not valid for ability: " + this.orderString)
                set this.bIsReadyToCast = false
                set this.readyTargetUnit = null
                return false
            endif
            if not IsUnitVisible(targetUnit, GetOwningPlayer(owner.hero)) then
                set this.bIsReadyToCast = false
                set this.readyTargetUnit = null
                call this.botLog("Target unit is not visible for ability: " + this.orderString)
                return false
            endif

            // Mass Teleport specific checks
            if this.findTargetType == FIND_TARGET_TYPE_ALLY_TELEPORT_FULL_MAP then
                if IsHeroGoaled(owner.hero) then
                    call this.botLog("Skipping teleport cast, hero already goaled.")
                    set this.bIsReadyToCast = false
                    set this.readyTargetUnit = null
                    return false
                endif
                if GetUnitLifePercent(owner.hero) < 35.0 then
                    call this.botLog("Skipping teleport cast due to low health.")
                    set this.bIsReadyToCast = false
                    set this.readyTargetUnit = null
                    return false
                endif
                if DistanceBetweenUnits(owner.hero, targetUnit) < 3000.0 then
                    call this.botLog("Skipping teleport cast, target too close.")
                    set this.bIsReadyToCast = false
                    set this.readyTargetUnit = null
                    return false
                endif
            endif

            if this.findTargetType == FIND_TARGET_TYPE_ENEMY_BACK_OR_CLOSE or this.findTargetType == FIND_TARGET_TYPE_ENEMY_BACK then
                if DistanceBetweenUnits(this.ownerHero, targetUnit) > this.castRange * 2.0 then
                    set this.bIsReadyToCast = false
                    set this.readyTargetUnit = null
                    return false
                endif
                // Follow target unit
                if DistanceBetweenUnits(this.ownerHero, targetUnit) <= this.castRange then
                    call this.castUnit(targetUnit)
                    return true
                else
                    call IssueTargetOrder(this.ownerHero, "move", targetUnit)
                    return true
                endif
            endif

            call this.castUnit(targetUnit)
            return true
        else
            call this.botLogError("Ability cast type not implemented: " + I2S(this.castType) + " for ability: " + this.orderString)
            return false
        endif
            
    endmethod

    method destroy takes nothing returns nothing
        call this.deallocate()
    endmethod

    method getName takes nothing returns string
        return GetObjectName(this.abilityId)
    endmethod

    method botLog takes string msg returns nothing
        call BotLogWithPlayer(GetOwningPlayer(this.ownerHero), msg)
    endmethod

    method botLogError takes string msg returns nothing
        call BotLogErrorWithPlayer(GetOwningPlayer(this.ownerHero), msg)
    endmethod
endstruct