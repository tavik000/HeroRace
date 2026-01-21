library KeyUtils

    // --- TYPE CONVERSION FUNCTIONS ---
    function B2S takes boolean b returns string
        if b then
            return "true"
        else
            return "false"
        endif
    endfunction

    // --- MATH FUNCTIONS ---
    function Abs takes real value returns real
        if value < 0.0 then
            return - value
        else
            return value
        endif
    endfunction

    function ModI takes integer a, integer b returns integer
        return ModuloInteger(a, b)
    endfunction

    function NormalizeAngle takes real a returns real
        loop
            exitwhen a >= 0.0 and a < 360.0
            if a < 0.0 then
                set a = a + 360.0
            else
                set a = a - 360.0
            endif
        endloop
        return a
    endfunction

    function MaxR takes real a, real b returns real
        if a >= b then
            return a
        else
            return b
        endif
    endfunction

    function MaxI takes integer a, integer b returns integer
        if a >= b then
            return a
        else
            return b
        endif
    endfunction

    function AngleBetweenXY takes real x1, real y1, real x2, real y2 returns real
        local real dx = x2 - x1
        local real dy = y2 - y1
        local real angle = Atan2(dy, dx) * 180.0 / bj_PI
        if angle < 0.0 then
            set angle = angle + 360.0
        endif
        return angle
    endfunction

    function GetMiddleAngle takes real sourceAngle, real targetAngle returns real
        local real angleDelta
        local real middleAngle

        // Calculate angle difference
        set angleDelta = targetAngle - sourceAngle

        // Clamp delta to the shortest arc (-180 to 180)
        if angleDelta > 180.0 then
            set angleDelta = angleDelta - 360.0
        elseif angleDelta < - 180.0 then
            set angleDelta = angleDelta + 360.0
        endif

        // Move halfway from sourceAngle toward targetAngle
        set middleAngle = sourceAngle + angleDelta * 0.5

        // Normalize result to 0 - 360 range
        if middleAngle < 0.0 then
            set middleAngle = middleAngle + 360.0
        elseif middleAngle >= 360.0 then
            set middleAngle = middleAngle - 360.0
        endif

        return middleAngle
    endfunction

    function DistanceBetweenXY takes real x1, real y1, real x2, real y2 returns real
        local real dx = x2 - x1
        local real dy = y2 - y1
        return SquareRoot(dx * dx + dy * dy)
    endfunction

    function DistanceBetweenUnits takes unit u1, unit u2 returns real
        return DistanceBetweenXY(GetUnitX(u1), GetUnitY(u1), GetUnitX(u2), GetUnitY(u2))
    endfunction

    function DistanceBetweenDestructableAndUnit takes destructable d, unit u returns real
        return DistanceBetweenXY(GetDestructableX(d), GetDestructableY(d), GetUnitX(u), GetUnitY(u))
    endfunction

    function AngleDiff takes real a, real b returns real
        local real d = a - b

        loop
            exitwhen d <= 180.0
            set d = d - 360.0
        endloop

        loop
            exitwhen d >= - 180.0
            set d = d + 360.0
        endloop

        // -90 < d <= 90
        return d
    endfunction

    function IsWithinForwardArc takes real angle, real referenceAngle returns boolean
        // True if angle is within +/-90 degrees of referenceAngle
        return RAbsBJ(AngleDiff(angle, referenceAngle)) <= 90.0
    endfunction

    function IsNearlyZero takes real value returns boolean
        return Abs(value) <= 0.01
    endfunction

    // --- UTILITY FUNCTIONS ---
    function AntiLeak takes nothing returns boolean
        return true
    endfunction

    function GetUnitMaxAttackDamage takes unit u returns real
        return GetUnitStateSwap(ConvertUnitState(0x15), u)
    endfunction

    // Stun or Paralysis (Cannot move)
    function IsUnitStun takes unit u returns boolean
        // Stun buffs
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
        // Magic Leash
        if UnitHasBuffBJ(u, 'Bmlt') then 
            return true
        endif       
        // Impale
        if UnitHasBuffBJ(u, 'BUim') then 
            return true
        endif
        // Frozen
        if UnitHasBuffBJ(u, 'B016') then 
            return true
        endif
        // Rooted (Entangling Roots)
        if UnitHasBuffBJ(u, 'B018') then 
            return true
        endif
        if UnitHasBuffBJ(u, 'BEer') then 
            return true
        endif
        // Spider Web
        if UnitHasBuffBJ(u, 'B01B') then 
            return true
        endif
        // Ensnare
        if UnitHasBuffBJ(u, 'Beng') then 
            return true
        endif
        return false
    endfunction

    function IsUnitSilenced takes unit u returns boolean
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
        // Silence
        if IsUnitSilenced(u) then 
            return true
        endif
        // Hex
        if UnitHasBuffBJ(u, 'BOhx') then 
            return true
        endif
        // Rat Transform
        if UnitHasBuffBJ(u, 'B02V') then 
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
        // Sleep
        if UnitHasBuffBJ(u, 'BUsl') then
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
        // Slow: current speed less than base speed
        if GetUnitMoveSpeed(u) < GetUnitDefaultMoveSpeed(u) then
            return true
        endif
        return false
    endfunction

    function IsUnitLocus takes unit u returns boolean
        return GetUnitAbilityLevel(u, 'Aloc') > 0
    endfunction

    // Alive, not Flying, not Building.
    function IsUnitValid takes unit filterUnit returns boolean
        if filterUnit == null then
            return false
        endif
        if not IsUnitAliveBJ(filterUnit) then
            return false
        endif
        if IsUnitType(filterUnit, UNIT_TYPE_FLYING) then
            return false
        endif
        // if IsUnitType(filterUnit, UNIT_TYPE_STRUCTURE) then
        //     return false
        // endif
        if IsUnitHiddenBJ(filterUnit) then
            return false
        endif

        if IsUnitLocus(filterUnit) then
            return false
        endif
        return true
    endfunction

    function IsUnitWard takes unit u returns boolean
        return GetUnitPointValue(u) == 233
    endfunction

    // Check if u1 is in front of u2
    function IsUnitInFrontOfUnit takes unit u1, unit u2 returns boolean
        local real dx = GetUnitX(u1) - GetUnitX(u2)
        local real dy = GetUnitY(u1) - GetUnitY(u2)

        local real rad = GetUnitFacing(u2) * bj_PI / 180.0
        return dx * Cos(rad) + dy * Sin(rad) > 0.0
    endfunction

    // Check if target is behind source unit
    function IsUnitBehindUnit takes unit u1, unit u2 returns boolean
        return not IsUnitInFrontOfUnit(u1, u2)
    endfunction

    function IsUnitInventoryFull takes unit u returns boolean
        return UnitInventoryCount(u) >= UnitInventorySizeBJ(u)
    endfunction

    function IsUnitFacingEast takes unit u returns boolean
        local real facing = GetUnitFacing(u)
        return facing >= 315.0 or facing < 45.0
    endfunction

    function IsUnitFacingEastNarrow takes unit u returns boolean
        local real facing = GetUnitFacing(u)
        return facing >= 330.0 or facing < 30.0
    endfunction

    function IsUnitFacingNorth takes unit u returns boolean
        local real facing = GetUnitFacing(u)
        return facing >= 45.0 and facing < 135.0
    endfunction

    function IsUnitFacingWest takes unit u returns boolean
        local real facing = GetUnitFacing(u)
        return facing >= 135.0 and facing < 225.0
    endfunction

    function IsUnitFacingWestNarrow takes unit u returns boolean
        local real facing = GetUnitFacing(u)
        return facing >= 150.0 and facing < 210.0
    endfunction

    function IsUnitFacingSouth takes unit u returns boolean
        local real facing = GetUnitFacing(u)
        return facing >= 225.0 and facing < 315.0
    endfunction

    function IsUnitUndead takes unit u returns boolean
        return IsUnitType(u, UNIT_TYPE_UNDEAD)
    endfunction

    // Destructable
    function EnumDestructablesInCircle takes real radius, location loc, code actionFunc returns nothing
        local rect r

        if (radius >= 0) then
            set bj_enumDestructableCenter = loc
            set bj_enumDestructableRadius = radius
            set r = GetRectFromCircleBJ(loc, radius)
            call EnumDestructablesInRect(r, filterEnumDestructablesInCircleBJ, actionFunc)
            call RemoveRect(r)
        endif
    endfunction

    function IsDayTime takes nothing returns boolean
        return GetTimeOfDay() >= 6.0 and GetTimeOfDay() < 18.0
    endfunction

    function IsNightTime takes nothing returns boolean
        return not IsDayTime()
    endfunction

endlibrary