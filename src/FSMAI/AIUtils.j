library AIUtils requires KeyUtils
    function BotLog takes string msg returns nothing
        if udg_bEnableLogBot then
            call BJDebugMsg("[AI Bot] " + msg)
        endif
    endfunction

    function BotLogWithPlayer takes player p, string msg returns nothing
        local integer playerIndex = GetPlayerId(p) + 1
        local string playerName = ""
        if udg_bEnableLogBot then   
            if playerIndex >= 0 and playerIndex <= 12 then
                set playerName = udg_PlayerNameWithHero[playerIndex]
                if playerName != null and playerName != "" then
                    call BJDebugMsg("[AI Bot] " + playerName + " " + msg)
                else
                    call BJDebugMsg("[AI Bot] Player " + I2S(playerIndex) + " " + msg)
                endif
            else
                call BJDebugMsg("[AI Bot] " + msg)
            endif
        endif
    endfunction

    function BotLogError takes string msg returns nothing
        call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + msg)
    endfunction

    function BotLogErrorWithPlayer takes player p, string msg returns nothing
        local integer playerIndex = GetPlayerId(p) + 1
        local string playerName = ""
        if playerIndex >= 0 and playerIndex <= 12 then
            set playerName = udg_PlayerNameWithHero[playerIndex]
            if playerName != null and playerName != "" then
                call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + playerName + " " + msg)
            else
                call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r Player " + I2S(playerIndex) + " " + msg)
            endif
        else
            call BJDebugMsg("[AI Bot] |cffff0000[ERROR]|r " + msg)
        endif
    endfunction

    // Helper function to get cooldown multiplier based on difficulty
    function GetCooldownMultiplier takes integer difficulty returns real
        if difficulty == DIFF_EASY then
            return EASY_CD_MULTIPLIER
        elseif difficulty == DIFF_NORMAL then
            return NORMAL_CD_MULTIPLIER
        elseif difficulty == DIFF_HARD then
            return HARD_CD_MULTIPLIER
        elseif difficulty == DIFF_CRAZY then
            return CRAZY_CD_MULTIPLIER
        elseif difficulty == DIFF_NIGHTMARE then
            return NIGHTMARE_CD_MULTIPLIER
        else
            return 1.0
        endif
    endfunction

    function IsApplyingCombo takes integer difficulty returns boolean
        if difficulty == DIFF_HARD or difficulty == DIFF_CRAZY or difficulty == DIFF_NIGHTMARE then
            return true
        else
            return false
        endif
    endfunction

    function IsUnitInAnyHazardZone takes unit u returns boolean
        local real ux = GetUnitX(u)
        local real uy = GetUnitY(u)
        if RectContainsCoords(gg_rct_HazardSlowSpikeArea, ux, uy) then
            return true
        endif
        if RectContainsCoords(gg_rct_HazardFastSpikeArea, ux, uy) then
            return true
        endif
        if RectContainsCoords(gg_rct_HazardNetArea, ux, uy) then
            return true
        endif
        if RectContainsCoords(gg_rct_HazardSpiderNetArea, ux, uy) then
            return true
        endif
        return false
    endfunction

    function FilterSuitablePickUpItem takes nothing returns nothing
        local item itm = GetEnumItem()
        local real dist = DistanceBetweenXY(tempFoundItemX, tempFoundItemY, GetItemX(itm), GetItemY(itm))
        local real itemAngle = AngleBetweenXY(tempFoundItemX, tempFoundItemY, GetItemX(itm), GetItemY(itm))
        local boolean bIsInFrontArc = IsWithinForwardArc(itemAngle, tempFoundItemUnitFacingAngle)
        if not bIsInFrontArc then
            set tempFoundItemRange = tempFoundItemRange * 0.65
        endif
        if dist < tempFoundItemMinDist and dist <= tempFoundItemRange then
            set tempFoundItemMinDist = dist
            set tempFoundItem = itm
        endif
    endfunction

    function GetSuitablePickupItemInRange takes unit u, real range returns item
        local item foundItem = null
        local real ux = GetUnitX(u)
        local real uy = GetUnitY(u)
        local rect rec = Rect(ux - range, uy - range, ux + range, uy + range)

        set tempFoundItem = null
        set tempFoundItemX = ux
        set tempFoundItemY = uy
        set tempFoundItemRange = range
        set tempFoundItemMinDist = 999999.0
        set tempFoundItemUnitFacingAngle = GetUnitFacing(u)

        call EnumItemsInRectBJ(rec, function FilterSuitablePickUpItem)
        call RemoveRect(rec)
        set foundItem = tempFoundItem

        return foundItem
    endfunction

    function GetHeroCastPoint takes integer heroTypeId returns real
        if HaveSavedReal(heroCastPointMap, heroTypeId, 0) then
            return LoadReal(heroCastPointMap, heroTypeId, 0)
        else
            call BotLogError("Unknown hero type for GetHeroCastPoint: " + I2S(heroTypeId))
            return 0.5  // Default cast point for unknown hero types
        endif
    endfunction

    // Helper function for basic unit validation
    function IsValidHeroTarget takes unit filterUnit returns boolean
        if not IsUnitAliveBJ(filterUnit) then
            return false
        endif
        if not IsUnitType(filterUnit, UNIT_TYPE_HERO) then
            return false
        endif
        if not IsUnitVisible(filterUnit, tempHeroOwner) then
            return false
        endif
        return true
    endfunction

    // Generic filter function for heroes (enemies or allies)
    function FilterTeamHeroes takes nothing returns boolean
        local unit filterUnit = GetFilterUnit()
        
        if not IsValidHeroTarget(filterUnit) then
            set filterUnit = null
            return false
        endif

        // Check if we want allies or enemies
        if tempFindTeamType == FIND_TEAM_TYPE_ALLIES then
            // Filter for allies (same team, but not the same unit)
            if IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
        elseif tempFindTeamType == FIND_TEAM_TYPE_ENEMIES then
            // Filter for enemies
            if not IsUnitEnemy(filterUnit, tempHeroOwner) then
                set filterUnit = null
                return false
            endif
        elseif tempFindTeamType == FIND_TEAM_TYPE_NONE then
            // No team filtering
        elseif tempFindTeamType == FIND_TEAM_TYPE_ALL then
            // FIND_TEAM_TYPE_ALL - no filtering needed
        endif
        
        set filterUnit = null
        return true
    endfunction

    function GetAIHeroFromUnit takes unit u returns AIHero
        if u == null then
            return 0
        endif
        return LoadInteger(udg_UnitAIHeroMap, GetHandleId(u), 0)
    endfunction

    function DestroyAIHero takes unit u returns nothing
        local AIHero aiHero = GetAIHeroFromUnit(u)
        if aiHero != null then
            call aiHero.destroy()
        endif
    endfunction

    function IsHeroGoaled takes unit u returns boolean
        return IsUnitInGroup(u, udg_GoaledHeroes) 
    endfunction

    function IsUnitCarryMoreThanTwoItem takes unit u returns boolean
        local integer itemCount = 0
        local integer i = 0

        loop
            if i == bj_MAX_INVENTORY then
                exitwhen true
            endif
            if UnitItemInSlot(u, i) != null then
                set itemCount = itemCount + 1
            endif
            set i = i + 1
        endloop

        if itemCount >= 2 then
            return true
        endif

        return false
    endfunction


    function IsInSlowSpikeHazardZone takes AIHero aiHero returns boolean
        local integer wpi = aiHero.currentWaypointIndex
        if wpi == 8 then
            return true
        endif
        return false
    endfunction

    function IsInFastSpikeHazardZone takes AIHero aiHero returns boolean
        local integer wpi = aiHero.currentWaypointIndex
        if IsTriggerEnabled(gg_trg_FastSpike) then
            if wpi == 10 then
                return true
            endif
        endif
        return false
    endfunction

    function IsInNetHazardZone takes AIHero aiHero returns boolean
        local integer wpi = aiHero.currentWaypointIndex
        if IsTriggerEnabled(gg_trg_Net01) then
            if wpi == 12 then
                return true
            endif
        endif
        return false
    endfunction

    function IsInSpiderNetHazardZone takes AIHero aiHero returns boolean
        local real heroX = GetUnitX(aiHero.hero)
        local real heroY = GetUnitY(aiHero.hero)
        local integer wpi = aiHero.currentWaypointIndex
        if RectContainsCoords(gg_rct_HazardSpiderNetArea, heroX, heroY) then
            if wpi == 14 then
                return true
            endif
        endif
        return false
    endfunction

    function IsFinalWaypoint takes AIHero aiHero returns boolean
        if aiHero.currentWaypointIndex >= WaypointCount then
            return true
        endif
        return false
    endfunction

    function FindSpeedUpAllyTargetInRange takes unit ownerHero, real range, AIHeroAbility heroAbil returns unit
        local group heroes = CreateGroup()
        local unit currentUnit = null
        local real minHpPercent = 50 
        local unit bestTarget = null
        local real minSpeed = 200.0
        local real maxSpeed = 350.0
        local player heroOwner = GetOwningPlayer(ownerHero)

        // Not Allowed Target: MagicImmune, customFilter, CCed, In Hazard Zone, Speed <200 or >350, Goaled Hero
        // Priority Order:
        // 1. HP >= 50%
        // 2. Behind
        // 3. Far from Hero
        // 3. Self

        // Set temp variables for filter function
        set tempHeroOwner = heroOwner
        set tempFindTeamType = FIND_TEAM_TYPE_ALLIES
        set tempHeroUnit = ownerHero
        set tempAIHeroAbility = heroAbil
        call GroupEnumUnitsInRange(heroes, GetUnitX(ownerHero), GetUnitY(ownerHero), range, Filter(function FilterTeamHeroes))

        call BotLogWithPlayer(heroOwner, "group unit count for speed-up ally target: " + I2S(CountUnitsInGroup(heroes)))
            
        loop
            set currentUnit = FirstOfGroup(heroes)
            exitwhen currentUnit == null
            call GroupRemoveUnit(heroes, currentUnit)
            call BotLogWithPlayer(heroOwner, "Evaluating ally unit: " + GetUnitName(currentUnit))
            call BotLogWithPlayer(heroOwner, " GetUnitLifePercent(currentUnit): " + R2S(GetUnitLifePercent(currentUnit)))

            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
                call BotLogWithPlayer(heroOwner, " Ally unit is invulnerable/magic immune, skipping: " + GetUnitName(currentUnit))
            elseif tempAIHeroAbility != 0 and not tempAIHeroAbility.customFilter(currentUnit) then
                call BotLogWithPlayer(heroOwner, " Ally unit failed custom filter, skipping: " + GetUnitName(currentUnit))
            elseif IsUnitStunOrSlow(currentUnit) then
                call BotLogWithPlayer(heroOwner, " Ally unit is CCed, skipping: " + GetUnitName(currentUnit))
            elseif IsUnitInAnyHazardZone(currentUnit) then
                call BotLogWithPlayer(heroOwner, " Ally unit is in hazard zone, skipping: " + GetUnitName(currentUnit))
            elseif GetUnitMoveSpeed(currentUnit) < minSpeed or GetUnitMoveSpeed(currentUnit) > maxSpeed then
                call BotLogWithPlayer(heroOwner, " Ally unit speed out of range, skipping: " + GetUnitName(currentUnit))
            elseif IsHeroGoaled(currentUnit) then
                call BotLogWithPlayer(heroOwner, " Ally unit is goaled, skipping: " + GetUnitName(currentUnit))
            else
                // Valid Target
                if bestTarget == null then
                    set bestTarget = currentUnit
                    call BotLogWithPlayer(heroOwner, "New best speed-up ally target: " + GetUnitName(currentUnit))
                elseif GetUnitLifePercent(currentUnit) >= minHpPercent and GetUnitLifePercent(bestTarget) < minHpPercent then
                    // Current has >=50% HP, best has <50% HP 
                    set bestTarget = currentUnit
                    call BotLogWithPlayer(heroOwner, "New best speed-up ally target based on HP%: " + GetUnitName(currentUnit))
                elseif bestTarget == ownerHero then
                    if IsUnitBehindUnit(currentUnit, ownerHero) then
                        // Current is behind, previous best is self
                        set bestTarget = currentUnit
                        call BotLogWithPlayer(heroOwner, "New best speed-up ally target based on Position: " + GetUnitName(currentUnit))
                    endif
                elseif IsUnitInFrontOfUnit(bestTarget, ownerHero) then
                    if IsUnitBehindUnit(currentUnit, ownerHero) then
                        if currentUnit != ownerHero then
                            // Current is behind, previous best is in front
                            set bestTarget = currentUnit
                            call BotLogWithPlayer(heroOwner, "New best speed-up ally target based on Position: " + GetUnitName(currentUnit))
                        endif
                    endif
                elseif DistanceBetweenUnits(ownerHero, currentUnit) > DistanceBetweenUnits(ownerHero, bestTarget) then
                    // Both are in same relative position, choose farther one
                    set bestTarget = currentUnit
                    call BotLogWithPlayer(heroOwner, "New best speed-up ally target based on Distance: " + GetUnitName(currentUnit))
                endif
            endif
        endloop

        if IsUnitInFrontOfUnit(bestTarget, ownerHero) then
            set bestTarget = ownerHero
            call BotLogWithPlayer(heroOwner, "Ally unit in front, defaulting to self.")
        endif

        // Clean up
        call DestroyGroup(heroes)
        set heroes = null
        set currentUnit = null
        set tempAIHeroAbility = 0
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
        set heroOwner = null

        return bestTarget
    endfunction

    function GetHeroGroupAroundUnit takes unit centerUnit, real radius, integer findTeamType returns group
        local group heroGroup = CreateGroup()
        local player centerPlayer = GetOwningPlayer(centerUnit)

        // Set temp variables for filter function
        set tempHeroOwner = centerPlayer
        set tempFindTeamType = findTeamType
        set tempHeroUnit = centerUnit

        call GroupEnumUnitsInRange(heroGroup, GetUnitX(centerUnit), GetUnitY(centerUnit), radius, Filter(function FilterTeamHeroes))

        // Clean up temp variables
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
        set centerPlayer = null

        return heroGroup
    endfunction

    function GetHeroCountAroundUnit takes unit centerUnit, real radius, integer findTeamType returns integer
        local group heroGroup = GetHeroGroupAroundUnit(centerUnit, radius, findTeamType)
        local integer count = CountUnitsInGroup(heroGroup)
        call DestroyGroup(heroGroup)
        set heroGroup = null
        return count
    endfunction

    function FindTargetUnitForItem takes AIHero owner, AIItem itm returns unit
        local unit targetUnit = null
        if itm.findTargetType == FIND_TARGET_TYPE_ALLY_SPEED_UP then
            set targetUnit = FindSpeedUpAllyTargetInRange(owner.hero, itm.castRange, 0)
            call owner.setDebugTextTagContent("Item: " + GetItemName(itm.itemHandle) + " - Ally Hero Target " + GetUnitName(targetUnit))
            call owner.setDebugTextTagColorPreset("RED")
        else
            call BotLogErrorWithPlayer(GetOwningPlayer(owner.hero), "Unsupported item find target type: " + I2S(itm.findTargetType))
        endif
        return targetUnit
    endfunction

    function FindForceToUseTargetUnitForItem takes AIHero owner, AIItem itm returns unit
        local unit targetUnit = null
        if itm.findTargetType == FIND_TARGET_TYPE_ALLY_SPEED_UP then
            set targetUnit = FindSpeedUpAllyTargetInRange(owner.hero, itm.castRange, 0)
            if targetUnit == null then
                set targetUnit = owner.hero
            endif
            call owner.setDebugTextTagContent("Item: " + GetItemName(itm.itemHandle) + " - Force Use Ally Hero Target " + GetUnitName(targetUnit))
            call owner.setDebugTextTagColorPreset("YELLOW")
        else
            call BotLogErrorWithPlayer(GetOwningPlayer(owner.hero), "Unsupported item find target type for force use: " + I2S(itm.findTargetType))
        endif
        return targetUnit
    endfunction

    function EvaluateComboTarget takes AIHero owner, unit currentUnit, unit bestTarget, real comboExpectedDamage, real comboMinHpThreshold returns unit
        local real currentHp = GetUnitState(currentUnit, UNIT_STATE_LIFE)
        local real bestTargetHp = GetUnitState(bestTarget, UNIT_STATE_LIFE)
        
        local boolean currentIsStunOrSlow = IsUnitStunOrSlow(currentUnit)
        local boolean bestIsStunOrSlow = IsUnitStunOrSlow(bestTarget)
        
        local boolean currentIsKillable = (currentHp <= comboExpectedDamage)
        local boolean bestIsKillable = (bestTargetHp <= comboExpectedDamage)
    
        // Initial check: if there is no best target yet, current is automatically the best.
        if bestTarget == null then
            return currentUnit
        endif
    
        // 1. Ungoaled Hero (Higher priority than anything else)
        if not IsHeroGoaled(currentUnit) and IsHeroGoaled(bestTarget) then
            call owner.botLog("Priority 1: Current unit is Ungoaled, Best is not.")
            return currentUnit
        elseif IsHeroGoaled(currentUnit) and not IsHeroGoaled(bestTarget) then
            return bestTarget
        endif
    
        // 2. Hero carry more than 2 items
        if IsUnitCarryMoreThanTwoItem(currentUnit) and not IsUnitCarryMoreThanTwoItem(bestTarget) then
            call owner.botLog("Priority 2: Current has more items.")
            return currentUnit
        elseif not IsUnitCarryMoreThanTwoItem(currentUnit) and IsUnitCarryMoreThanTwoItem(bestTarget) then
            return bestTarget
        endif
    
        // 3. Avoid Overkill (Target is above the min threshold)
        if currentHp >= comboMinHpThreshold and bestTargetHp < comboMinHpThreshold then
            call owner.botLog("Priority 3: Avoiding overkill on current unit.")
            return currentUnit
        elseif currentHp < comboMinHpThreshold and bestTargetHp >= comboMinHpThreshold then
            return bestTarget
        endif
    
        // 4. Prioritize Stunned/Slowed
        if currentIsStunOrSlow and not bestIsStunOrSlow then
            call owner.botLog("Priority 4: Current is CC'd.")
            return currentUnit
        elseif not currentIsStunOrSlow and bestIsStunOrSlow then
            return bestTarget
        endif
    
        // 5. Secure Kills (Is the target killable with the combo?)
        if currentIsKillable and not bestIsKillable then
            call owner.botLog("Priority 5: Current is killable, Best is not.")
            return currentUnit
        elseif not currentIsKillable and bestIsKillable then
            return bestTarget
        endif
    
        // 6. Minimize Overkill Among Kills (If both are killable, pick the one with higher HP)
        if currentIsKillable and bestIsKillable then
            if currentHp > bestTargetHp then
                call owner.botLog("Priority 6: Both killable, picking current (less overkill).")
                return currentUnit
            else
                return bestTarget
            endif
        endif
    
        // 7. Damage Efficiency (If neither are killable, pick the one with lower HP)
        if not currentIsKillable and not bestIsKillable then
            if currentHp < bestTargetHp then
                call owner.botLog("Priority 7: Neither killable, picking current (lower HP).")
                return currentUnit
            else
                return bestTarget
            endif
        endif
    
        // 8. Fallback
        return bestTarget
    endfunction

    function FindBestComboTarget takes AIHero owner, real range, AIHeroAbility heroAbil returns unit
        local group heroes = CreateGroup()
        local unit currentUnit = null
        local unit bestTarget = null
        local real comboExpectedDamage = owner.combatData.comboExpectedDamage
        local real comboMinHpThreshold = comboExpectedDamage * owner.combatData.comboOverkillThresholdPercent
            
        // Set temp variables for filter function
        set tempHeroOwner = GetOwningPlayer(owner.hero)
        set tempFindTeamType = FIND_TEAM_TYPE_ENEMIES
        set tempHeroUnit = owner.hero
        set tempAIHeroAbility = heroAbil
        call GroupEnumUnitsInRange(heroes, GetUnitX(owner.hero), GetUnitY(owner.hero), range, Filter(function FilterTeamHeroes))
        call owner.botLog("Found " + I2S(CountUnitsInGroup(heroes)) + " potential combo targets in range.")
            
        // Iterate through filtered enemies to find best target
        loop
            set currentUnit = FirstOfGroup(heroes)
            exitwhen currentUnit == null
            call GroupRemoveUnit(heroes, currentUnit)
                

            // Not allow: Invulnerable/Magic Immune
                
            //  Current Priority Order:                                                                                     
            // 1. Ungoaled Hero
            // 2. Hero carry more than 2 items
            // 3. Avoid Overkill 
            // 4. Prioritize Stunned/Slowed
            // 5. Secure Kills
            // 6. Minimize Overkill Among Kills
            // 7. Damage Efficiency
            // 8. Fallback to Overkill

            // Skip if unit is invulnerable
            if IsUnitInvulnerableOrMagicImmune(currentUnit) then
                // Skip this unit
            elseif tempAIHeroAbility != 0 and not tempAIHeroAbility.customFilter(currentUnit) then
                // Skip - doesn't pass custom filter
            else
                // Valid target - evaluate
                set bestTarget = EvaluateComboTarget(owner, currentUnit, bestTarget, comboExpectedDamage, comboMinHpThreshold)
            endif

        endloop
            
        // Clean up
        call DestroyGroup(heroes)
        set heroes = null
        set currentUnit = null
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
        set tempAIHeroAbility = 0
            
        if bestTarget == null then
            call owner.botLogError("No suitable combo targets found")
            // set bestTarget = FindFallbackComboTarget(owner, range, heroAbil)
        endif

            
        set tempAIHeroAbility = 0            
        return bestTarget
    endfunction


    function FindRandomHeroInRange takes AIHero owner, real range, integer findTeamType, AIHeroAbility heroAbil returns unit
        local group heroes = CreateGroup()
        local unit randomHero
        local unit currentUnit

        // Not allow: Invulnerable/Magic Immune

        // Set temp variables for filter function
        set tempHeroOwner = GetOwningPlayer(owner.hero)
        set tempFindTeamType = findTeamType
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
        set tempHeroUnit = null
        set tempHeroOwner = null
        set tempFindTeamType = FIND_TEAM_TYPE_NONE
            
        return randomHero
    endfunction

    function FindRandomEnemyHeroInRange takes AIHero owner, real range, AIHeroAbility heroAbil returns unit
        return FindRandomHeroInRange(owner, range, FIND_TEAM_TYPE_ENEMIES, heroAbil)
    endfunction
        
    function FindRandomAllyHeroInRange takes AIHero owner, real range, AIHeroAbility heroAbil returns unit
        return FindRandomHeroInRange(owner, range, FIND_TEAM_TYPE_ALLIES, heroAbil)
    endfunction


    function FindTargetForAbility takes AIHero owner, AIHeroAbility heroAbil returns unit
        local unit targetUnit = null
            
        // Find new target based on ability type
        if heroAbil.findTargetType == FIND_TARGET_TYPE_ENEMY_COMBO then
            // Use smart combo targeting for combo abilities, random for others
            if IsApplyingCombo(owner.difficulty) and heroAbil.comboIndex > 0 then
                if owner.comboTargetUnit != null then
                    // Check if we should use existing combo target
                    set targetUnit = owner.comboTargetUnit
                    call owner.botLog("Using existing combo target for combo ability: " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Using Combo Target " + GetUnitName(targetUnit))
                    call owner.setDebugTextTagColorPreset("RED")
                    return targetUnit
                endif
                set targetUnit = FindBestComboTarget(owner, heroAbil.castRange, heroAbil)
                call owner.botLog("Finding best combo target, result: " + GetUnitName(targetUnit))
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Combo Target " + GetUnitName(targetUnit))
                call owner.setDebugTextTagColorPreset("RED")
                return targetUnit
            else
                // Fallback to random enemy hero
                set targetUnit = FindRandomEnemyHeroInRange(owner, heroAbil.castRange, heroAbil)
                call owner.botLog("Finding random enemy hero, result: " + GetUnitName(targetUnit))
                call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Enemy Hero Target " + GetUnitName(targetUnit))
                call owner.setDebugTextTagColorPreset("RED")
                return targetUnit
            endif
        endif

        if heroAbil.findTargetType == FIND_TARGET_TYPE_ALLY_SPEED_UP then
            set targetUnit = FindSpeedUpAllyTargetInRange(owner.hero, heroAbil.castRange, heroAbil)
            call owner.botLog("Finding ally hero target, result: " + GetUnitName(targetUnit))
            call owner.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - Ally Hero Target " + GetUnitName(targetUnit))
            call owner.setDebugTextTagColorPreset("RED")
            return targetUnit
        endif

            
        return targetUnit
    endfunction


endlibrary