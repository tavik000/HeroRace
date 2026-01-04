struct HeroCombatData
    AIHeroAbility array abilities[MAX_ABILITIES_PER_HERO]
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
        
    method addAbility takes integer abilityId, real cooldown, integer castType, string orderString, integer manaCost, real castRange, integer findTargetType, real effectiveRadius, integer comboIndex, real expectedDamage returns nothing
        if this.abilityCount < MAX_ABILITIES_PER_HERO then
            set this.abilities[this.abilityCount] = AIHeroAbility.create(abilityId, this.owner, cooldown, castType, orderString, manaCost, castRange, findTargetType, effectiveRadius, comboIndex, expectedDamage)
            if comboIndex > 0 then
                set this.comboExpectedDamage = this.comboExpectedDamage + this.abilities[this.abilityCount].expectedDamage
            endif
            set this.abilityCount = this.abilityCount + 1
        else
            // Exceeded max abilities - handle error as needed
            call this.botLogError("Exceeded max abilities for hero combat data.")
        endif
    endmethod

    method addItem takes item newItemHandle, integer itemId, real baseCooldown, real castRange, real effectiveRadius, real requiredCastTime, unit ownerHero, boolean isPassive, integer castType, integer findTargetType returns nothing
        local integer i = 0
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            if this.items[i] == null then
                set this.items[i] = AIItem.create(newItemHandle, itemId, baseCooldown, castRange, effectiveRadius, requiredCastTime, ownerHero, isPassive, castType, findTargetType)
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

    method getAbilityByComboIndex takes integer comboIndex returns AIHeroAbility
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
        local AIHeroAbility heroAbil = this.getReadyAbility(hero, difficulty)
        if heroAbil != 0 then
            return true
        endif
        return false
    endmethod

    method getReadyAbility takes unit hero, integer difficulty returns AIHeroAbility
        local integer i = 0
        local AIHeroAbility heroAbil
        local real currentMana
        local boolean bCheckCombo = IsApplyingCombo(difficulty)
        local AIHero aiHero = GetAIHeroFromUnit(hero)

        if bCheckCombo then
            // Check for combo abilities starting from index 1
            set heroAbil = this.getAbilityByComboIndex(1)
            if heroAbil != 0 then
                // Exist any combo ability
                // If combo ability cooldown are ready, prioritize them
                if this.areComboAbilityCooldownReady(hero, difficulty, aiHero.currentComboIndex) then
                    // Check if we have enough mana for combo
                    if this.hasEnoughManaForCombo(hero, aiHero.currentComboIndex) then
                        // Cooldown ready and enough mana - proceed with combo
                        set heroAbil = this.getReadyComboAbility(hero, difficulty, aiHero.currentComboIndex)
                        if heroAbil != 0 then
                            if heroAbil.bIsReadyToCast then
                                return heroAbil
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
            set heroAbil = this.abilities[i]
                
            if bCheckCombo and heroAbil.comboIndex > 0 then
                // Skip combo abilities if not checking for combos
            else
                // Check cooldown (skip for first-time cast)
                if heroAbil.isCooldownReady(difficulty) then
                    // Check if ability is available
                    if GetUnitAbilityLevel(hero, heroAbil.abilityId) <= 0 then
                        call this.botLogError("Ability not available: " + heroAbil.orderString)
                    else
                        // Check if hero has enough mana
                        set currentMana = GetUnitState(hero, UNIT_STATE_MANA)
                        if not heroAbil.isManaReady(hero) then
                            call this.botLog("Not enough mana for ability. Need: " + I2S(heroAbil.manaCost) + ", Have: " + I2S(R2I(currentMana)))
                            call aiHero.setDebugTextTagContent("Combat: " + heroAbil.orderString + " - No Mana" + "(" + I2S(heroAbil.manaCost) + "/" + I2S(R2I(currentMana)) + ")")
                            call aiHero.setDebugTextTagColorPreset("RED")
                        else
                            if heroAbil.bIsReadyToCast then
                                return heroAbil
                            endif
                        endif
                    endif
                endif
            endif
            set i = i + 1
        endloop

        return 0
    endmethod

    method getReadyComboAbility takes unit hero, integer difficulty, integer startingComboIndex returns AIHeroAbility
        local integer i = startingComboIndex
        local AIHeroAbility heroAbil
        local AIHeroAbility resultComboAbility = 0
        local AIHero aiHero = GetAIHeroFromUnit(hero)
        if aiHero == 0 then
            call this.botLogError("AIHero not found for unit in getReadyComboAbility.")
            return 0
        endif


        // Check if a sequence of combo abilities are ready
        loop
            set heroAbil = this.getAbilityByComboIndex(i)
            // Reach end of combo sequence
            exitwhen heroAbil == 0
                
            // Check cooldown
            if not heroAbil.isCooldownReady(difficulty) then
                call this.botLog("Ability cooldown not ready for combo: " + heroAbil.orderString)
                call aiHero.setDebugTextTagContent("Combat: Combo CD Not Ready " + heroAbil.orderString)
                call aiHero.setDebugTextTagColorPreset("RED")
                return 0
            endif
                
            // Check if ability is available
            if GetUnitAbilityLevel(hero, heroAbil.abilityId) <= 0 then
                call this.botLogError("Ability not available for combo: " + heroAbil.orderString)
                return 0
            endif
                
            if i == aiHero.currentComboIndex then
                if not heroAbil.bIsReadyToCast then
                    call this.botLog("Ability not prepared for combo: " + heroAbil.orderString)
                    return 0
                else
                    set resultComboAbility = heroAbil
                    call this.botLog("Found ready combo ability at comboIndex " + I2S(i) + ": " + heroAbil.orderString)
                    call aiHero.setDebugTextTagContent("Combat: Found Combo Ability " + heroAbil.orderString)
                    call aiHero.setDebugTextTagColorPreset("RED")
                endif
            endif
            set i = i + 1
        endloop

        if not this.hasEnoughManaForCombo(hero, startingComboIndex) then
            call this.botLog("Not enough mana for remaining combo abilities from index " + I2S(startingComboIndex))
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
        local AIHeroAbility heroAbil
        local AIHero aiHero = GetAIHeroFromUnit(hero)
            
        // Calculate mana cost for remaining combo abilities from currentComboIndex
        loop
            set heroAbil = this.getAbilityByComboIndex(i)
            // Reach end of combo sequence
            exitwhen heroAbil == 0
                
            set requiredMana = requiredMana + heroAbil.manaCost
            set i = i + 1
        endloop
            
        if currentMana >= requiredMana then
            return true
        endif
        call this.botLog("Not enough mana for remaining combo. (" + I2S(R2I(currentMana)) + "/" + I2S(R2I(requiredMana)) + ")")
        call aiHero.setDebugTextTagContent("Combat: No Mana, (" + I2S(R2I(currentMana)) + "/" + I2S(R2I(requiredMana)) + ")")
        call aiHero.setDebugTextTagColorPreset("RED")
        return false
    endmethod

    method areComboAbilityCooldownReady takes unit hero, integer difficulty, integer currentComboIndex returns boolean
        local integer i = currentComboIndex
        local AIHeroAbility heroAbil
            
        // Check if combo abilities have their cooldowns ready (starting from currentComboIndex)
        loop
            set heroAbil = this.getAbilityByComboIndex(i)
            // Reach end of combo sequence
            exitwhen heroAbil == 0
                
            // Check cooldown
            if not heroAbil.isCooldownReady(difficulty) then
                return false
            endif
                
            // Check if ability is available
            if GetUnitAbilityLevel(hero, heroAbil.abilityId) <= 0 then
                return false
            endif
                
            set i = i + 1
        endloop
            
        // All remaining combo abilities have cooldown ready
        return true
    endmethod

    method tryPrepareTargetForAbilities takes nothing returns nothing
        local integer i = 0
        local AIHeroAbility heroAbil

        // Prepare target for each ability
        loop
            exitwhen i >= this.abilityCount
            set heroAbil = this.abilities[i]
            if heroAbil != 0 then
                if not heroAbil.bIsReadyToCast then
                    if heroAbil.comboIndex > 0 then
                        // Only prepare combo abilities if in combo mode
                        if IsApplyingCombo(owner.difficulty) then
                            if areComboAbilityCooldownReady(owner.hero, owner.difficulty, 1) then
                                if this.hasEnoughManaForCombo(owner.hero, 1) then
                                    call heroAbil.tryPrepareTarget()
                                endif
                            endif
                        endif
                    else
                        // Non-combo abilities always prepare
                        if heroAbil.isCooldownReady(owner.difficulty) then
                            if heroAbil.isManaReady(owner.hero) then
                                call heroAbil.tryPrepareTarget()
                            endif
                        endif
                    endif
                endif
            endif
            set i = i + 1
        endloop
    endmethod

    method tryPrepareTargetForItems takes nothing returns nothing
        local integer i = 0
        local AIItem heroItem

        // Prepare target for each item
        loop
            exitwhen i >= MAX_ITEM_PER_HERO
            set heroItem = this.items[i]
            if heroItem != 0 then
                call heroItem.tryPrepareTarget()
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
                if not UnitHasItem(ownerHero, heroItem.itemHandle) then
                    call this.removeItem(heroItem.itemHandle)
                else
                    if heroItem.isCooldownAndReadyToUse() then
                        return heroItem
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

        call this.botLog("No item found with find target type: " + I2S(findTargetType))
        return false
    endmethod

    method botLog takes string msg returns nothing
        call BotLogWithPlayer(GetOwningPlayer(owner.hero), msg)
    endmethod

    method botLogError takes string msg returns nothing
        call BotLogErrorWithPlayer(GetOwningPlayer(owner.hero), msg)
    endmethod

endstruct