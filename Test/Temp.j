function Trig_MeatHook_00_Conditions takes nothing returns boolean
    // Check if the spell being cast is Meat Hook ('A0AI')
    return GetSpellAbilityId() == 'A0AI'
endfunction

function Trig_MeatHook_00_Actions takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer pid = GetConvertedPlayerId(GetOwningPlayer(caster))
    local location targetLoc

    if udg_B[pid] then
        set udg_B[pid] = false
    else
        set targetLoc = GetSpellTargetLoc()
        call MeatHook_Start(caster, targetLoc, 'u001', 'u000', 2300.00, 35.00, 100.00, 0.03)
        call YDUserDataSet(unit, caster, "使用钩子", integer, 1)

        call RemoveLocation(targetLoc)
        set targetLoc = null
    endif

    set caster = null
endfunction

//===========================================================================
function InitTrig_MeatHook_06 takes nothing returns nothing
    set gg_trg_MeatHook_06 = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(gg_trg_MeatHook_06, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call TriggerAddCondition(gg_trg_MeatHook_06, Condition(function Trig_MeatHook_00_Conditions))
    call TriggerAddAction(gg_trg_MeatHook_06, function Trig_MeatHook_00_Actions)
endfunction
