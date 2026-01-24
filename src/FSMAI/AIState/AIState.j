struct AIState 
    integer stateID
    AIHero owner
        
    method botLog takes string msg returns nothing
        if not IsUnitValid(owner.hero) then
            call BotLog(msg)
            return
        endif
        call BotLogWithPlayer(GetOwningPlayer(owner.hero), msg)
    endmethod
        
    method botLogError takes string msg returns nothing
        if not IsUnitValid(owner.hero) then
            call BotLogError(msg)
            return
        endif
        call BotLogErrorWithPlayer(GetOwningPlayer(owner.hero), msg)
    endmethod
        
    stub method onEnter takes nothing returns nothing
    // Placeholder for state entry logic
    endmethod

    stub method onUpdate takes nothing returns nothing
    // Placeholder for timer callback
    endmethod

    stub method onExit takes nothing returns nothing
    // Placeholder for state exit logic
    endmethod

    stub method destroy takes nothing returns nothing
    call this.deallocate()
    endmethod
endstruct