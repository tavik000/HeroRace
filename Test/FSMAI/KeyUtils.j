library KeyUtils

    // --- MATH FUNCTIONS ---
    function Abs takes real value returns real
        if value < 0.0 then
            return -value
        else
            return value
        endif
    endfunction

    // --- UTILITY FUNCTIONS ---
    function IsUnitStun takes unit u returns boolean
        if UnitHasBuffBJ(u, 'BSTN') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'B01N') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'BPSE') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'BHtb') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'B01O') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'BNcs') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'BNvc') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'B03F') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'B01H') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'B00B') then 
            return true
        endif 
        return false
    endfunction

    function IsUnitStunOrSilence takes unit u returns boolean
        if not IsUnitAliveBJ(u) then
            return true  
        endif
        if IsUnitPausedBJ(u) then
            return true
        endif
        if IsUnitHiddenBJ(u) then
            return true
        endif
        // Stun
        if IsUnitStun(u) then 
            return true
        endif
        // Magic Leash
        if UnitHasBuffBJ(u, 'Bmlt') then 
            return true
        endif       
        // Impale
        if UnitHasBuffBJ(u, 'BUim') then 
            return true
        endif
        // Silence
        if UnitHasBuffBJ(u, 'B02H') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'B035') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'B01J') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'BNsi') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'B02G') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'BNdo') then 
            return true 
        endif
        // Hex
        if UnitHasBuffBJ(u, 'BOhx') then 
            return true
        endif
        // Thunder Axe
        if UnitHasBuffBJ(u, 'B01F') then 
            return true
        endif
        // Cyclone
        if UnitHasBuffBJ(u, 'Bcyc') then 
            return true
        endif
        return false
    endfunction


    function IsUnitInvulnerableOrMagicImmune takes unit u returns boolean
        // Invulnerability
        if UnitHasBuffBJ(u, 'Bvul') then
            return true
        endif
        if UnitHasBuffBJ(u, 'Bpsh') then
            return true
        endif
        if GetUnitAbilityLevel(u, 'Avul') > 0 then
            return true
        endif
        if UnitHasBuffBJ(u, 'B021') then
            return true
        endif
        if UnitHasBuffBJ(u, 'BHds') then
            return true
        endif
        if UnitHasBuffBJ(u, 'BOvd') then
            return true
        endif
        // Cyclone
        if UnitHasBuffBJ(u, 'Bcyc') then
            return true
        endif
        if UnitHasBuffBJ(u, 'Bcy2') then
            return true
        endif
        // Animated Dead
        if UnitHasBuffBJ(u, 'BUan') then
            return true
        endif
        // Magic Immunity
        if IsUnitType(u, UNIT_TYPE_MAGIC_IMMUNE) then
            return true
        endif
        return false
    endfunction

    function IsUnitStunOrSlow takes unit u returns boolean
        if IsUnitPausedBJ(u) then
            return false
        endif
        if IsUnitHiddenBJ(u) then
            return false
        endif
        // Stun
        if IsUnitStun(u) then 
            return true
        endif
        // Magic Leash
        if UnitHasBuffBJ(u, 'Bmlt') then 
            return true
        endif       
        // Impale
        if UnitHasBuffBJ(u, 'BUim') then 
            return true
        endif
        // Slow: current speed less than base speed
        if GetUnitMoveSpeed(u) < GetUnitDefaultMoveSpeed(u) then
            return true
        endif
        return false
    endfunction

    function IsUnitInFrontOfUnit takes unit source, unit target returns boolean
        local real sourceX = GetUnitX(source)
        local real sourceY = GetUnitY(source)
        local real targetX = GetUnitX(target)
        local real targetY = GetUnitY(target)
        local real angleThreshold = 180.0
        
        local real dx = targetX - sourceX
        local real dy = targetY - sourceY
        local real angleToTarget = Atan2(dy, dx) * 180.0 / bj_PI
        
        local real sourceFacing = GetUnitFacing(source)
        
        local real angleDiff = Abs(angleToTarget - sourceFacing)

        call BJDebugMsg("Source Facing: " + R2S(sourceFacing) + ", Angle to Target: " + R2S(angleToTarget) + ", Angle Diff: " + R2S(angleDiff))
        
        return angleDiff <= angleThreshold
    endfunction



endlibrary