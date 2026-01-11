struct AIAbility
    // Ability configuration
    integer abilityId
    real baseCooldown
    integer castType
    real lastCastTime
    integer comboIndex  // For chaining abilities in sequence
    string orderString  
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

    static method create takes integer aid, AIHero inOwner, real cd, integer inCastType, string order, integer mana, real inCastRange, integer inFindTargetType, real inEffectiveRadius, integer inComboIndex, real inExpectedDamage, boolean inIsPassive, real inRequiredCastTime, boolean inIsIgnoreMagicImmune, integer inMustHaveBuffCodeWhenFollowing, boolean inShouldCheckOtherUnitBlockingTargetUnit, real inMinTargetDistance, real inFollowTargetDuration, real inBasePredictOffset, real inBasePredictDelay, real inProjectileSpeed returns thistype
        local thistype this = thistype.allocate()
        set this.abilityId = aid
        set this.baseCooldown = cd
        set this.castType = inCastType
        set this.lastCastTime = 0.0
        set this.comboIndex = inComboIndex
        set this.orderString = order
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

    method getUnitFrontOffsetDistance takes unit targetUnit returns real
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

        if this.castType != CAST_POINT_ENEMY_FRONT and this.castType != CAST_POINT_ALL_FRONT and this.castType != CAST_POINT_ALLY_FRONT then
            call this.botLogError("getFrontOffsetDistance called for non-front-cast ability: " + GetObjectName(this.abilityId))
            return 0.0
        endif

        set currentOrder = GetUnitCurrentOrder(targetUnit)
        if currentOrder == 0 then
            set targetMoveSpeed = 0.0
        endif

        if IsUnitStun(targetUnit) then
            // Cannot move
            set targetMoveSpeed = 0.0
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
            set offsetDistance = targetMoveSpeed * (baseDelay + ownerCastPoint) + baseOffset
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

        if not IsApplyingCombo(owner.difficulty) then
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

    method tryPrepareTarget takes nothing returns nothing
        local integer targetUnitCount

        if this.castType == CAST_NONE then
            return
        elseif this.castType == CAST_INSTANT_BACK_ENEMY then
            set this.readyTargetUnit = FindTargetUnitForAbility(this.owner, this)
            set this.bIsReadyToCast = this.readyTargetUnit != null
        elseif this.castType == CAST_INSTANT_HEAL then
            set this.bIsReadyToCast = GetUnitLifePercent(this.ownerHero) <= SELF_HEAL_HP_PERCENTAGE_THRESHOLD
        elseif this.castType == CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE then
            // will be set when being targeted by other ability, or taken damage
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
        elseif this.castType == CAST_UNIT then
            if this.findTargetType == FIND_TARGET_TYPE_NONE then
                call this.botLogError("Ability find target type is FIND_TARGET_TYPE_NONE, cannot prepare ability: " + GetObjectName(this.abilityId))
                return
            endif
            set this.readyTargetUnit = FindTargetUnitForAbility(this.owner, this)
            set this.bIsReadyToCast = this.readyTargetUnit != null
        else
            call this.botLogError("Ability cast type not implemented for prepare target: " + I2S(this.castType) + " for ability: " + GetObjectName(this.abilityId))
            set this.readyTargetUnit = null
            set this.bIsReadyToCast = false
            return
        endif

        if this.readyTargetUnit != null then
            if this.shouldUpdateComboTarget(this.readyTargetUnit) then
                set owner.comboTargetUnit = this.readyTargetUnit
            endif
        endif

    endmethod

    method castInstant takes nothing returns nothing
        call IssueImmediateOrder(owner.hero, this.orderString)
        call this.botLog("Casting instant ability: " + this.orderString)
        set this.bIsReadyToCast = false
    endmethod

    method castPoint takes real targetX, real targetY returns nothing
        call IssuePointOrder(owner.hero, this.orderString, targetX, targetY)
        call this.botLog("Casting point ability at: (" + R2S(targetX) + ", " + R2S(targetY) + ") for ability: " + this.orderString)
        set this.bIsReadyToCast = false
        set this.readyTargetPointX = 0.0
        set this.readyTargetPointY = 0.0
        set this.readyTargetPoint = null
    endmethod

    method castUnit takes unit targetUnit returns nothing
        if targetUnit == null then
            call this.botLogError("Cannot cast unit ability, target unit is null for ability: " + this.orderString)
            return
        endif
        call IssueTargetOrder(owner.hero, this.orderString, targetUnit)
        call this.botLog("Casting unit ability on target: " + GetUnitName(targetUnit) + " for ability: " + this.orderString)
        set this.bIsReadyToCast = false
        set this.readyTargetUnit = null
    endmethod

    method tryCast takes nothing returns boolean
        local unit targetUnit = null
        local integer targetUnitCount = 0
        local real targetFacingAngle
        local real offset
        local unit hazardUnitAround = null
            
        call this.botLog("Attempting to cast ability: " + this.orderString)

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
        elseif this.castType == CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE then
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
                set offset = this.getUnitFrontOffsetDistance(targetUnit)
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
            else
                // if there is hazard around, cast to hazard center
                set hazardUnitAround = FindHazardUnitAroundTargetUnit(this.owner, targetUnit, this.effectiveRadius)
                if hazardUnitAround != null then
                    set this.readyTargetPointX = GetUnitX(hazardUnitAround)
                    set this.readyTargetPointY = GetUnitY(hazardUnitAround)
                    call this.botLog("Casting behind enemy to hazard center for ability: " + GetObjectName(this.abilityId))
                    call this.castPoint(this.readyTargetPointX, this.readyTargetPointY)
                    return true
                endif

                // fallback: Calculate point behind target unit
                set targetFacingAngle = GetUnitFacing(this.readyTargetUnit)
                set offset = this.getUnitFrontOffsetDistance(targetUnit)
                set this.readyTargetPointX = GetUnitX(this.readyTargetUnit) - offset * Cos(targetFacingAngle * bj_DEGTORAD)
                set this.readyTargetPointY = GetUnitY(this.readyTargetUnit) - offset * Sin(targetFacingAngle * bj_DEGTORAD)
                call this.castPoint(this.readyTargetPointX, this.readyTargetPointY)
                return true 
            endif
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

    method botLog takes string msg returns nothing
        call BotLogWithPlayer(GetOwningPlayer(this.ownerHero), msg)
    endmethod

    method botLogError takes string msg returns nothing
        call BotLogErrorWithPlayer(GetOwningPlayer(this.ownerHero), msg)
    endmethod
endstruct