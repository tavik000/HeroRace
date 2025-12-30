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
        local boolean isCastOvertime = currentTime > owner.lastStartCastTime + owner.castPt + TURN_TIME // Turn Time and Pre-swing 
        local boolean isCastFailed = owner.isCasting and isCastOvertime

        if isCastFailed then
            call this.botLog("Casting failed or interrupted, resetting casting state")
            call owner.setDebugTextTagContent("Combat: Cast Failed " + owner.castingAbility.orderString)
            call owner.setDebugTextTagColorPreset("RED")
            set owner.isCasting = false
            set owner.castingAbility = 0
        endif

        if owner.isCasting then
            call this.botLog("Currently casting an ability, skipping update")
            call owner.setDebugTextTagContent("Combat: Casting " + owner.castingAbility.orderString)
            call owner.setDebugTextTagColorPreset("RED")
            return
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

        if difficulty < DIFF_NORMAL then
            return false
        endif

        set heroItem = owner.combatData.getReadyItem()            
        if heroItem != 0 then
            call owner.setDebugTextTagContent("Combat: Try using item " + GetItemName(heroItem.itemHandle))
            call owner.setDebugTextTagColorPreset("RED")
            call heroItem.tryUse()
            return true
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

    method findTargetForAbility takes AIHeroAbility heroAbil returns unit
        local unit targetUnit = null
            
            
        // Find new target based on ability type
        if heroAbil.findTargetType == FIND_TARGET_TYPE_ENEMY_COMBO then
            // Use smart combo targeting for combo abilities, random for others
            if IsApplyingCombo(owner.difficulty) and heroAbil.comboIndex > 0 then
                if owner.comboTargetUnit != null then
                    // Check if we should use existing combo target
                    set targetUnit = owner.comboTargetUnit
                    call this.botLog("Using existing combo target for combo ability: " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Using Combo Target " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagColorPreset("RED")
                    return targetUnit
                endif
                set targetUnit = this.findBestComboTarget(heroAbil.castRange, heroAbil)
                call this.botLog("Finding best combo target, result: " + GetUnitName(targetUnit))
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Combo Target " + GetUnitName(targetUnit))
                call owner.setDebugTextTagColorPreset("RED")
                return targetUnit
            else
                // Fallback to random enemy hero
                set targetUnit = this.findRandomEnemyHeroInRange(heroAbil.castRange, heroAbil)
                call this.botLog("Finding random enemy hero, result: " + GetUnitName(targetUnit))
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Enemy Hero Target " + GetUnitName(targetUnit))
                call owner.setDebugTextTagColorPreset("RED")
                return targetUnit
            endif
        endif

        if heroAbil.findTargetType == FIND_TARGET_TYPE_ALLY_SPEED_UP then
            set targetUnit = this.findSpeedUpAllyTargetInRange(heroAbil.castRange, heroAbil)
            call this.botLog("Finding ally hero target, result: " + GetUnitName(targetUnit))
            call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Ally Hero Target " + GetUnitName(targetUnit))
            call owner.setDebugTextTagColorPreset("RED")
            return targetUnit
        endif

            
        return targetUnit
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
        set targetUnit = this.findTargetForAbility(heroAbil)
            
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

    method findRandomHeroInRange takes real range, boolean isForAllies, AIHeroAbility heroAbil returns unit
        local group heroes = CreateGroup()
        local unit randomHero
        local unit currentUnit

        // Not allow: Invulnerable/Magic Immune

        // Set temp variables for filter function
        set tempHeroOwner = GetOwningPlayer(owner.hero)
        set bTempFilterForAllies = isForAllies
        set tempHeroUnit = owner.hero
        set tempAIHeroAbility = heroAbil
            
        call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterTeamHeroes))

        if CountUnitsInGroup(heroes) > 0 then
            loop
                set currentUnit = FirstOfGroup(heroes)
                exitwhen currentUnit == null

                if tempAIHeroAbility != 0 then
                    if not tempAIHeroAbility.customFilter(currentUnit) then
                        call GroupRemoveUnit(heroes, currentUnit)
                    endif
                endif

                if IsUnitInvulnerableOrMagicImmune(currentUnit) then
                    call GroupRemoveUnit(heroes, currentUnit)
                endif
            endloop
        endif

        set randomHero = GroupPickRandomUnit(heroes)
            
        // Clean up
        set tempAIHeroAbility = 0
        call DestroyGroup(heroes)
        set heroes = null
            
        return randomHero
    endmethod

    method findRandomEnemyHeroInRange takes real range, AIHeroAbility heroAbil returns unit
        return this.findRandomHeroInRange(range, false, heroAbil)
    endmethod
        
    method findRandomAllyHeroInRange takes real range, AIHeroAbility heroAbil returns unit
        return this.findRandomHeroInRange(range, true, heroAbil)
    endmethod

    method findSpeedUpAllyTargetInRange takes real range, AIHeroAbility heroAbil returns unit
        local group heroes = CreateGroup()
        local unit currentUnit = null
        local real minHpPercent = 50 
        local unit bestTarget = null
        local real minSpeed = 200.0
        local real maxSpeed = 350.0

        // Not Allowed Target: MagicImmune, customFilter, CCed, In Hazard Zone, Speed <200 or >350 
        // Priority Order:
        // 1. HP >= 50%
        // 2. Behind
        // 3. Far from Hero
        // 3. Self

        // Set temp variables for filter function
        set tempHeroOwner = GetOwningPlayer(owner.hero)
        set bTempFilterForAllies = true
        set tempHeroUnit = owner.hero
        set tempAIHeroAbility = heroAbil
        call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterTeamHeroes))

        call this.botLog("group unit count for speed-up ally target: " + I2S(CountUnitsInGroup(heroes)))
            
        loop
            set currentUnit = FirstOfGroup(heroes)
            exitwhen currentUnit == null
            call GroupRemoveUnit(heroes, currentUnit)
            call this.botLog("Evaluating ally unit: " + GetUnitName(currentUnit))
            call this.botLog(" GetUnitLifePercent(currentUnit): " + R2S(GetUnitLifePercent(currentUnit)))

            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
                call this.botLog(" Ally unit is invulnerable/magic immune, skipping: " + GetUnitName(currentUnit))
            elseif tempAIHeroAbility != 0 and not tempAIHeroAbility.customFilter(currentUnit) then
                call this.botLog(" Ally unit failed custom filter, skipping: " + GetUnitName(currentUnit))
            elseif IsUnitStunOrSlow(currentUnit) then
                call this.botLog(" Ally unit is CCed, skipping: " + GetUnitName(currentUnit))
            elseif IsUnitInAnyHazardZone(currentUnit) then
                call this.botLog(" Ally unit is in hazard zone, skipping: " + GetUnitName(currentUnit))
            elseif GetUnitMoveSpeed(currentUnit) < minSpeed or GetUnitMoveSpeed(currentUnit) > maxSpeed then
                call this.botLog(" Ally unit speed out of range, skipping: " + GetUnitName(currentUnit))
            else
                // Valid Target
                if bestTarget == null then
                    set bestTarget = currentUnit
                    call this.botLog("New best speed-up ally target: " + GetUnitName(currentUnit))
                elseif GetUnitLifePercent(currentUnit) >= minHpPercent and GetUnitLifePercent(bestTarget) < minHpPercent then
                    // Current has >=50% HP, best has <50% HP 
                    set bestTarget = currentUnit
                    call this.botLog("New best speed-up ally target based on HP%: " + GetUnitName(currentUnit))
                elseif bestTarget == owner.hero then
                    if IsUnitBehindUnit(currentUnit, owner.hero) then
                        // Current is behind, previous best is self
                        set bestTarget = currentUnit
                        call this.botLog("New best speed-up ally target based on Position: " + GetUnitName(currentUnit))
                    endif
                elseif IsUnitInFrontOfUnit(bestTarget, owner.hero) then
                    if IsUnitBehindUnit(currentUnit, owner.hero) then
                        if currentUnit != owner.hero then
                            // Current is behind, previous best is in front
                            set bestTarget = currentUnit
                            call this.botLog("New best speed-up ally target based on Position: " + GetUnitName(currentUnit))
                        endif
                    endif
                elseif DistanceBetweenUnits(owner.hero, currentUnit) > DistanceBetweenUnits(owner.hero, bestTarget) then
                    // Both are in same relative position, choose farther one
                    set bestTarget = currentUnit
                    call this.botLog("New best speed-up ally target based on Distance: " + GetUnitName(currentUnit))
                endif
            endif
        endloop

        if IsUnitInFrontOfUnit(bestTarget, owner.hero) then
            set bestTarget = owner.hero
            call this.botLog("Ally unit in front, defaulting to self.")
        endif

        // Clean up
        call DestroyGroup(heroes)
        set heroes = null
        set currentUnit = null
        set tempAIHeroAbility = 0
        set tempHeroUnit = null
        set tempHeroOwner = null

        return bestTarget
    endmethod

    method evaluateComboTarget takes unit currentUnit, unit bestTarget, real bestTargetHp, boolean bestIsKillableTarget, boolean bestIsStunOrSlow, real comboExpectedDamage, real comboMinThreshold returns unit
        local real currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
        local boolean isKillableTarget
        local boolean isStunOrSlow
            
        if currentHp >= comboMinThreshold then
            set isKillableTarget = (currentHp <= comboExpectedDamage)
            set isStunOrSlow = IsUnitStunOrSlow(currentUnit)
            
            if bestTarget == null then
                return currentUnit
            elseif isStunOrSlow and not bestIsStunOrSlow then
                return currentUnit
            elseif (isStunOrSlow == bestIsStunOrSlow) then
                if isKillableTarget and not bestIsKillableTarget then
                    return currentUnit
                elseif isKillableTarget and bestIsKillableTarget and currentHp > bestTargetHp then
                    return currentUnit
                elseif not isKillableTarget and not bestIsKillableTarget and currentHp < bestTargetHp then
                    return currentUnit
                endif
            endif
        endif
        return bestTarget
    endmethod

    method findBestComboTarget takes real range, AIHeroAbility heroAbil returns unit
        local group heroes = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local real currentHp
        local real bestTargetHp = 0.0
        local boolean bestIsKillableTarget = false
        local boolean bestIsStunOrSlow = false
        local real comboExpectedDamage = owner.combatData.comboExpectedDamage
        local real comboMinThreshold = comboExpectedDamage * owner.combatData.comboOverkillThresholdPercent
            
        // Set temp variables for filter function
        set tempHeroOwner = GetOwningPlayer(owner.hero)
        set bTempFilterForAllies = false
        set tempHeroUnit = owner.hero
        set tempAIHeroAbility = heroAbil
        call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterTeamHeroes))
            
        // Iterate through filtered enemies to find best target
        loop
            set currentUnit = FirstOfGroup(heroes)
            exitwhen currentUnit == null
            call GroupRemoveUnit(heroes, currentUnit)
                
            set currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)

            // Not allow: Invulnerable/Magic Immune
                
            //  Current Priority Order:                                                                                     
            // 1. Avoid Overkill 
            // 2. Prioritize Stunned/Slowed
            // 3. Secure Kills
            // 4. Minimize Overkill Among Kills
            // 5. Damage Efficiency
            // 6. Fallback to Overkill

            // Skip if unit is invulnerable
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
                // Skip this unit
            elseif tempAIHeroAbility != 0 and not tempAIHeroAbility.customFilter(currentUnit) then
                // Skip - doesn't pass custom filter
            else
                // Valid target - evaluate
                set bestTarget = this.evaluateComboTarget(currentUnit, bestTarget, bestTargetHp, bestIsKillableTarget, bestIsStunOrSlow, comboExpectedDamage, comboMinThreshold)
                if bestTarget == currentUnit then
                    set bestTargetHp = currentHp
                    set bestIsKillableTarget = (currentHp <= comboExpectedDamage)
                    set bestIsStunOrSlow = IsUnitStunOrSlow(currentUnit)
                endif
            endif

        endloop
            
        // Clean up
        call DestroyGroup(heroes)
        set heroes = null
        set currentUnit = null
            
        if bestTarget != null then
            // Log selected target details
            if bestIsKillableTarget then
                if bestIsStunOrSlow then
                    call this.botLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:1")
                    call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:1)")
                    call owner.setDebugTextTagColorPreset("RED")
                else
                    call this.botLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:0")
                    call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:1 Stun/Slow:0)")
                    call owner.setDebugTextTagColorPreset("RED")
                endif
            else
                if bestIsStunOrSlow then
                    call this.botLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:1")
                    call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:1)")
                    call owner.setDebugTextTagColorPreset("RED")
                else
                    call this.botLog("Selected combo target: " + GetUnitName(bestTarget) + " HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:0")
                    call owner.setDebugTextTagContent("Combat: Combo Target: " + GetUnitName(bestTarget) + "(HP:" + R2S(bestTargetHp) + " Killable:0 Stun/Slow:0)")
                endif
            endif
        else
            set bestTarget = this.findFallbackComboTarget(range, heroAbil)
        endif
            
        set tempAIHeroAbility = 0            
        return bestTarget
    endmethod

    method findFallbackComboTarget takes real range, AIHeroAbility heroAbil returns unit
        local group heroes = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local real bestTargetHp = 0.0
        local real currentHp
            
        call this.botLog("No suitable combo target found, trying fallback to overkill targets")
            
        set tempHeroOwner = GetOwningPlayer(owner.hero)
        set bTempFilterForAllies = false
        set tempHeroUnit = owner.hero
        set tempAIHeroAbility = heroAbil
        call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterTeamHeroes))
            
        loop
            set currentUnit = FirstOfGroup(heroes)
            exitwhen currentUnit == null
            call GroupRemoveUnit(heroes, currentUnit)

            // Skip if no ability to check
            if tempAIHeroAbility == 0 then
                // Skip this unit
            elseif not tempAIHeroAbility.customFilter(currentUnit) then
                // Skip - doesn't pass custom filter
            elseif IsUnitInvulnerableOrMagicImmune(currentUnit) then
                // Skip - invulnerable unit
            else
                // Valid target - check HP
                set currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
                
                if bestTarget == null or currentHp > bestTargetHp then
                    set bestTarget = currentUnit
                    set bestTargetHp = currentHp
                endif
            endif
                
        endloop
            
        call DestroyGroup(heroes)
        set heroes = null
        set tempAIHeroAbility = 0
            
        if bestTarget != null then
            call this.botLog("Fallback combo target selected: " + GetUnitName(bestTarget))
            call owner.setDebugTextTagContent("Combat: Combo Target (Overkill): " + GetUnitName(bestTarget))
            call owner.setDebugTextTagColorPreset("RED")
        else
            call this.botLog("No combo targets found at all")
            call owner.setDebugTextTagContent("Combat: No Combo Target")
            call owner.setDebugTextTagColorPreset("RED")
        endif
            
        return bestTarget
    endmethod

    method onExit takes nothing returns nothing
        call this.botLog("Exiting Combat State")
        call owner.setDebugTextTagContent("Combat: Exit")
        call owner.setDebugTextTagColorPreset("RED")
    endmethod
endstruct