struct HeroCombatData
    AIAbility array abilities[MAX_ABILITIES_PER_HERO]
    integer abilityCount
    real comboExpectedDamage
    real comboOverkillThresholdPercent
    AIItem array items[MAX_ITEM_PER_HERO]
    AIHero owner

    static method create takes AIHero inOwner returns thistype
        local thistype this = thistype.allocate()
        set this.owner = inOwner
        set this.abilityCount = 0
        set this.comboExpectedDamage = 0.0
        set this.comboOverkillThresholdPercent = 0.3 // Default to 30% of combo damage
        return this
    endmethod
        
    method addAbilityById takes integer abilityId returns nothing
        local real baseCooldown = GetAbilityBaseCooldown(abilityId)
        local integer castType = GetAbilityCastType(abilityId)
        local string orderString = GetAbilityOrderString(abilityId)
        local integer orderId = GetAbilityOrderId(abilityId)
        local integer manaCost = GetAbilityManaCost(abilityId)
        local real castRange = GetAbilityCastRange(abilityId)
        local integer findTargetType = GetAbilityFindTargetType(abilityId)
        local real effectiveRadius = GetAbilityEffectiveRadius(abilityId)
        local integer comboIndex = GetAbilityComboIndex(abilityId)
        local real expectedDamage = GetAbilityExpectedDamage(abilityId)
        local boolean isPassive = GetAbilityIsPassive(abilityId)
        local real requiredCastTime = GetAbilityRequiredCastTime(abilityId)
        local boolean isIgnoreMagicImmune = GetAbilityIsIgnoreMagicImmune(abilityId)
        local integer mustHaveBuffCodeWhenFollowing = GetAbilityMustHaveBuffCodeWhenFollowing(abilityId)
        local boolean shouldCheckOtherUnitBlockingTargetUnit = GetAbilityShouldCheckOtherUnitBlockingTargetUnit(abilityId)
        local real minTargetDistance = GetAbilityMinTargetDistance(abilityId)
        local real followTargetDuration = GetAbilityFollowTargetDuration(abilityId)
        local real basePredictOffset = GetAbilityBasePredictOffset(abilityId)
        local real basePredictDelay = GetAbilityBasePredictDelay(abilityId)
        local real projectileSpeed = GetAbilityProjectileSpeed(abilityId)
        if this.abilityCount < MAX_ABILITIES_PER_HERO then
            set this.abilities[this.abilityCount] = AIAbility.create(abilityId, this.owner, baseCooldown, castType, orderString, orderId, manaCost, castRange, findTargetType, effectiveRadius, comboIndex, expectedDamage, isPassive, requiredCastTime, isIgnoreMagicImmune, mustHaveBuffCodeWhenFollowing, shouldCheckOtherUnitBlockingTargetUnit, minTargetDistance, followTargetDuration, basePredictOffset, basePredictDelay, projectileSpeed)
            if comboIndex > 0 then
                set this.comboExpectedDamage = this.comboExpectedDamage + this.abilities[this.abilityCount].expectedDamage
            endif
            set this.abilityCount = this.abilityCount + 1
        else
            // Exceeded max abilities - handle error as needed
            call this.botLogError("Exceeded max abilities for hero combat data.")
        endif
    endmethod

    method getCurrentItemCount takes nothing returns integer
        local integer count = 0
        local integer i = 0
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            if this.items[i] != null then
                set count = count + 1
            endif
            set i = i + 1
        endloop
        return count
    endmethod

    method addItem takes item newItemHandle, integer itemId, real baseCooldown, real castRange, real effectiveRadius, real requiredCastTime, integer manaCost, unit ownerHero, boolean isPassive, integer castType, integer findTargetType returns nothing
        local integer i = 0
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            if this.items[i] == null then
                set this.items[i] = AIItem.create(newItemHandle, itemId, baseCooldown, castRange, effectiveRadius, requiredCastTime, manaCost, ownerHero, isPassive, castType, findTargetType)
                call this.botLog("Added item to hero combat data: " + GetItemName(newItemHandle) + " at slot " + I2S(i) + ", total item count: " + I2S(this.getCurrentItemCount()))
                return
            endif
            set i = i + 1
        endloop
        // Exceeded max items - handle error as needed
        call this.botLogError("Exceeded max items for hero combat data.")
    endmethod
        
    method removeItem takes item itemHandle returns nothing
        local integer i = 0
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            if this.items[i] != null then
                if this.items[i].itemHandle == itemHandle then
                    call this.items[i].destroy()
                    set this.items[i] = 0
                    return
                endif
            endif
            set i = i + 1
        endloop
        // Item not found - handle error as needed
        call this.botLogError("Item not found in hero combat data for removal.")
    endmethod

    method removeAllItems takes nothing returns nothing
        local integer i = 0
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            if this.items[i] != null then
                call this.items[i].destroy()
                set this.items[i] = 0
            endif
            set i = i + 1
        endloop
    endmethod
        
    method destroy takes nothing returns nothing
        local integer i = 0
        loop
            exitwhen i >= this.abilityCount
            call this.abilities[i].destroy()
            set i = i + 1
        endloop
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            if this.items[i] != null then
                call this.items[i].destroy()
            endif
            set i = i + 1
        endloop
        call this.deallocate()
    endmethod

    method getAbilityByComboIndex takes integer comboIndex returns AIAbility
        local integer i = 0
        loop
            exitwhen i >= this.abilityCount
            if this.abilities[i].comboIndex == comboIndex then
                return this.abilities[i]
            endif
            set i = i + 1
        endloop
        return 0
    endmethod

    method hasReadyAbility takes unit hero, integer difficulty returns boolean
        local AIAbility abil = this.getReadyAbility(hero, difficulty)
        if abil != 0 then
            return true
        endif
        return false
    endmethod

    method getReadyAbility takes unit hero, integer difficulty returns AIAbility
        local integer i = 0
        local AIAbility abil
        local real currentMana
        local boolean bCheckCombo = IsDifficultyApplyingCombo(difficulty)
        local AIHero aiHero = GetAIHeroFromUnit(hero)

        if bCheckCombo then
            // Check for combo abilities starting from index 1
            set abil = this.getAbilityByComboIndex(1)
            if abil != 0 then
                // Exist any combo ability
                // If combo ability cooldown are ready, prioritize them
                if this.areComboAbilityCooldownReady(hero, difficulty, aiHero.currentComboIndex) then
                    // Check if we have enough mana for combo
                    if this.hasEnoughManaForCombo(hero, aiHero.currentComboIndex) then
                        // Cooldown ready and enough mana - proceed with combo
                        set abil = this.getReadyComboAbility(hero, difficulty, aiHero.currentComboIndex)
                        if abil != 0 then
                            if abil.bIsReadyToCast then
                                return abil
                            endif
                        endif
                    else
                        // Cooldown ready but not enough mana - don't fallback to non-combo abilities, prioritize mana waiting
                        return 0
                    endif
                endif
                // If combo cooldown are not ready, continue to check non-combo abilities
            endif
        endif

        // Check if any ability is ready for combat based on difficulty
        loop
            exitwhen i >= this.abilityCount
            set abil = this.abilities[i]
                
            if bCheckCombo and abil.comboIndex > 0 then
                // Skip combo abilities if not checking for combos
            else
                // Check cooldown (skip for first-time cast)
                if abil.isCooldownReady(difficulty) then
                    // Check if ability is available
                    if GetUnitAbilityLevel(hero, abil.abilityId) <= 0 then
                        call this.botLogError("Ability not available: " + abil.orderString)
                    else
                        // Check if hero has enough mana
                        set currentMana = GetUnitState(hero, UNIT_STATE_MANA)
                        if not abil.isManaReady(hero) then
                            // call this.botLog("Not enough mana for ability. Need: " + I2S(abil.manaCost) + ", Have: " + I2S(R2I(currentMana)))
                            call aiHero.setDebugTextTagContent("Combat: " + abil.orderString + ", No Mana" + "(" + I2S(abil.manaCost) + "/" + I2S(R2I(currentMana)) + ")")
                            call aiHero.setDebugTextTagColorPreset("RED")
                        else
                            if abil.bIsReadyToCast then
                                return abil
                            endif
                        endif
                    endif
                endif
            endif
            set i = i + 1
        endloop

        return 0
    endmethod

    method getReadyComboAbility takes unit hero, integer difficulty, integer startingComboIndex returns AIAbility
        local integer i = startingComboIndex
        local AIAbility abil
        local AIAbility resultComboAbility = 0
        local AIHero aiHero = GetAIHeroFromUnit(hero)
        if aiHero == 0 then
            call this.botLogError("AIHero not found for unit in getReadyComboAbility.")
            return 0
        endif


        // Check if a sequence of combo abilities are ready
        loop
            set abil = this.getAbilityByComboIndex(i)
            // Reach end of combo sequence
            exitwhen abil == 0
                
            // Check cooldown
            if not abil.isCooldownReady(difficulty) then
                call this.botLog("Ability cooldown not ready for combo: " + abil.orderString)
                call aiHero.setDebugTextTagContent("Combat: Combo CD Not Ready " + abil.orderString)
                call aiHero.setDebugTextTagColorPreset("RED")
                return 0
            endif
                
            // Check if ability is available
            if GetUnitAbilityLevel(hero, abil.abilityId) <= 0 then
                call this.botLogError("Ability not available for combo: " + abil.orderString)
                return 0
            endif
                
            if i == aiHero.currentComboIndex then
                if not abil.bIsReadyToCast then
                    return 0
                else
                    set resultComboAbility = abil
                    call this.botLog("Found ready combo ability at comboIndex " + I2S(i) + ": " + abil.orderString)
                    call aiHero.setDebugTextTagContent("Combat: Found Combo Ability " + abil.orderString)
                    call aiHero.setDebugTextTagColorPreset("RED")
                endif
            endif
            set i = i + 1
        endloop

        if not this.hasEnoughManaForCombo(hero, startingComboIndex) then
            // call this.botLog("Not enough mana for remaining combo abilities from index " + I2S(startingComboIndex))
            return 0
        endif

        call this.botLog("Combo abilities ready, returning ability: " + resultComboAbility.orderString)
        call aiHero.setDebugTextTagContent("Combat: Combo Ability Ready " + resultComboAbility.orderString)
        call aiHero.setDebugTextTagColorPreset("RED")

        return resultComboAbility
    endmethod

    method hasEnoughManaForCombo takes unit hero, integer currentComboIndex returns boolean
        local real currentMana = GetUnitState(hero, UNIT_STATE_MANA)
        local real requiredMana = 0.0
        local integer i = currentComboIndex
        local AIAbility abil
        local AIHero aiHero = GetAIHeroFromUnit(hero)
            
        // Calculate mana cost for remaining combo abilities from currentComboIndex
        loop
            set abil = this.getAbilityByComboIndex(i)
            // Reach end of combo sequence
            exitwhen abil == 0
                
            set requiredMana = requiredMana + abil.manaCost
            set i = i + 1
        endloop
            
        if currentMana >= requiredMana then
            return true
        endif
        // call this.botLog("Not enough mana for remaining combo. (" + I2S(R2I(currentMana)) + "/" + I2S(R2I(requiredMana)) + ")")
        call aiHero.setDebugTextTagContent("Combat: No Mana, (" + I2S(R2I(currentMana)) + "/" + I2S(R2I(requiredMana)) + ")")
        call aiHero.setDebugTextTagColorPreset("RED")
        return false
    endmethod

    method areComboAbilityCooldownReady takes unit hero, integer difficulty, integer currentComboIndex returns boolean
        local integer i = currentComboIndex
        local AIAbility abil
            
        // Check if combo abilities have their cooldowns ready (starting from currentComboIndex)
        loop
            set abil = this.getAbilityByComboIndex(i)
            // Reach end of combo sequence
            exitwhen abil == 0
                
            // Check cooldown
            if not abil.isCooldownReady(difficulty) then
                return false
            endif
                
            // Check if ability is available
            if GetUnitAbilityLevel(hero, abil.abilityId) <= 0 then
                return false
            endif
                
            set i = i + 1
        endloop
            
        // All remaining combo abilities have cooldown ready
        return true
    endmethod

    method shouldPrepareAbility takes AIAbility abil returns boolean
        // Non-combo abilities: check cooldown and mana
        if abil.comboIndex == 0 then
            return abil.isCooldownReady(owner.difficulty) and abil.isManaReady(owner.hero)
        endif
        
        // Combo abilities: check if applying combo
        if IsDifficultyApplyingCombo(owner.difficulty) then
            return areComboAbilityCooldownReady(owner.hero, owner.difficulty, abil.comboIndex) and this.hasEnoughManaForCombo(owner.hero, abil.comboIndex)
        endif
        
        // Not applying combo: treat as regular ability
        return abil.isCooldownReady(owner.difficulty) and abil.isManaReady(owner.hero)
    endmethod

    method tryPrepareTargetForAbilities takes nothing returns nothing
        local integer i = 0
        local AIAbility abil

        // Prepare target for each ability
        loop
            exitwhen i >= this.abilityCount
            set abil = this.abilities[i]
            
            if abil != 0 and not abil.bIsReadyToCast then
                if this.shouldPrepareAbility(abil) then
                    call abil.tryPrepareTarget()
                endif
            endif
            
            set i = i + 1
        endloop
    endmethod

    method tryPrepareTargetForItems takes nothing returns nothing
        local integer i = 0
        local AIItem heroItem

        if not IsAIHardOrAbove(owner.difficulty) then
            return
        endif

        // TaurenChieftain or SkeletonGrunt keep item until close to goal
        if GetUnitTypeId(owner.hero) == 'O008' or GetUnitTypeId(owner.hero) == 'O00F' then
            if not IsCurrentGoalWaypoint(owner) and not IsHeroGoaled(owner.hero) then
                if this.getCurrentItemCount() < 6 then
                    return
                endif
            endif
        endif

        // Prepare target for each item
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            set heroItem = this.items[i]
            if heroItem != 0 then
                if heroItem.isCooldownReady() then
                    if heroItem.isManaReady() then
                        if heroItem.tryPrepareTarget() then
                            call this.botLog("Prepared target for item: " + GetItemName(heroItem.itemHandle))
                            return
                        endif
                    endif
                endif
            endif
            set i = i + 1
        endloop
    endmethod

    method hasReadyItem takes nothing returns boolean
        local AIItem heroItem = this.getReadyItem()
        if heroItem != 0 then
            return true
        endif
        return false
    endmethod

    method getReadyItem takes nothing returns AIItem
        local integer i = 0
        local AIItem heroItem
        local real currentMana
        local unit ownerHero = owner.hero

        if ownerHero == null then
            call this.botLogError("Owner hero is null in getReadyItem.")
            return 0
        endif

        // Check if any item is ready for use
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            set heroItem = this.items[i]
            if heroItem != 0 then
                if not UnitHasItem(ownerHero, heroItem.itemHandle) or heroItem.itemHandle == null then
                    call this.removeItem(heroItem.itemHandle)
                else
                    if heroItem.isCooldownAndReadyToUse() then
                        if heroItem.isManaReady() then
                            return heroItem
                        endif
                    endif
                endif
            endif
            set i = i + 1
        endloop

        return 0
    endmethod

    method hasItemOfFindTargetType takes integer findTargetType returns boolean
        local integer i = 0
        local AIItem heroItem

        // Check if any item matches the find target type
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            set heroItem = this.items[i]
            if heroItem != 0 then
                if heroItem.findTargetType == findTargetType then
                    call this.botLog("Found item with find target type: " + I2S(findTargetType))
                    return true
                endif
            endif
            set i = i + 1
        endloop

        // call this.botLog("No item found with find target type: " + I2S(findTargetType))
        return false
    endmethod

    method hasItemOfCastType takes integer castType returns boolean
        local AIItem heroItem = this.getItemOfCastType(castType)
        if heroItem != 0 then
            return true
        endif
        return false
    endmethod

    method getItemOfCastType takes integer castType returns AIItem
        local integer i = 0
        local AIItem heroItem

        // Find and return the first item that matches the cast type
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            set heroItem = this.items[i]
            if heroItem != 0 then
                if heroItem.castType == castType then
                    call this.botLog("Found item with cast type: " + I2S(castType))
                    return heroItem
                endif
            endif
            set i = i + 1
        endloop

        // call this.botLog("No item found with cast type: " + I2S(castType))
        return 0
    endmethod

    method hasAbilityOfCastType takes integer castType returns boolean
        local AIAbility abil = this.getAbilityOfCastType(castType)
        if abil != 0 then
            return true
        endif
        return false
    endmethod

    method getAbilityOfCastType takes integer castType returns AIAbility
        local integer i = 0
        local AIAbility abil

        // Find and return the first ability that matches the cast type
        loop
            exitwhen i >= this.abilityCount
            set abil = this.abilities[i]
            if abil != 0 then
                if abil.castType == castType then
                    call this.botLog("Found ability with cast type: " + I2S(castType))
                    return abil
                endif
            endif
            set i = i + 1
        endloop

        // call this.botLog("No ability found with cast type: " + I2S(castType))
        return 0
    endmethod

    method getAnySelfDefenseAbility takes nothing returns AIAbility
        return this.getAbilityOfCastType(CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE)
    endmethod

    method getAnySelfDefenseItem takes nothing returns AIItem
        local AIItem resultItem
        set resultItem = this.getItemOfCastType(CAST_INSTANT_SELF_DEFENSE_AND_CLEANSE)
        if resultItem == 0 then
            set resultItem = this.getItemOfCastType(CAST_POINT_SELF_FRONT_DEFENSE_AND_CLEANSE)
        endif
        return resultItem
    endmethod

    method syncItemCooldown takes AIItem heroItem returns nothing
        local integer i = 0
        local AIItem otherItem

        // Sync cooldown for all items with the same itemId
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            set otherItem = this.items[i]
            if otherItem != 0 and otherItem != heroItem then
                if otherItem.itemId == heroItem.itemId then
                    set otherItem.lastUseTime = heroItem.lastUseTime
                    call this.botLog("Synced cooldown for item: " + GetItemName(otherItem.itemHandle))
                endif
            endif
            set i = i + 1
        endloop
    endmethod

    method botLog takes string msg returns nothing
        call BotLogWithPlayer(GetOwningPlayer(owner.hero), msg)
    endmethod

    method botLogError takes string msg returns nothing
        call BotLogErrorWithPlayer(GetOwningPlayer(owner.hero), msg)
    endmethod

endstruct