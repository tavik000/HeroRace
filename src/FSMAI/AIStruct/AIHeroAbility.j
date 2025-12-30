struct AIHeroAbility
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

    static method create takes integer aid, real cd, integer inCastType, string order, integer mana, real inCastRange, integer inFindTargetType, real inEffectiveRadius, integer inComboIndex, real inExpectedDamage returns thistype
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
                call BotLog("Skipping banish target, already banished, unit: " + GetUnitName(u))
                return false
            endif
        endif
        return true
    endmethod

        
    method destroy takes nothing returns nothing
        call this.deallocate()
    endmethod
endstruct