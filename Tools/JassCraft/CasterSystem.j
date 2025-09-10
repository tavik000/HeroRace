//***************************************************************************
//*                                                                         *
//* Caster System 13.1                                                      *
//* ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯                                                      *
//* http://www.wc3campaigns.net/vexorian                                    *
//*                                                                         *
//***************************************************************************
globals
     integer            udg_currentabi
     unit               udg_currentcaster
     unit               udg_currenthurter
     group              udg_casters
     real               udg_delayhack
     real array         udg_castervars
     location           udg_sourcehack
     gamecache          udg_cscache
endglobals


//Caster System 13.1 ( http://wc3campaigns.net/vexorian )
//====================================================================================================================================================================
function Caster_UnitId takes nothing returns integer
    return 'e000' //// Caster Unit type rawcode  (changes betwen maps, always use it inside '')
endfunction

constant function Caster_DefaultAttackType takes nothing returns attacktype
    return ATTACK_TYPE_CHAOS // Default attack type used by the old functions and when you use 0 as DamageOptions
endfunction

constant function Caster_DefaultDamageType takes nothing returns damagetype
    return DAMAGE_TYPE_UNIVERSAL // Default damage type used by the old functions and when you use 0 as DamageOptions
endfunction

constant function DamageTreeDetectorId takes nothing returns integer
    return 'Aeat' /// The eat tree ability, don't need to change this rawcode unless you modiffied that ability in your map, in that case copy it, reset the copied one and use its rawcode here.
endfunction

constant function ChangeableFlyingHeightAllowerId takes nothing returns integer
    return 'Amrf' /// Medivh's Crow form ability, don't need to change this rawcode unless you modiffied that ability in your map, in that case copy it, reset the copied one and use its rawcode here.
endfunction

constant function CS_MaxCollisionSize takes nothing returns real
    return 55. //Maximum collision size in your map
endfunction

constant function CS_Cycle takes nothing returns real
return 0.01
    return 0.04 // Cycle value for the projectile movement in seconds (Each 0.04 the projectiles get moved)
// 0.01 looks smooth but is lag friendly
// 0.1 looks horrible but is not laggy
// 0.04 is decent for the human eye and quite efficient.
// 0.05 would be an improvement in efficiency but probably doesn't look too well
endfunction


//=================================================================================================
function CS_Rawcode2Real takes integer i returns real
 return i
 return 0.
endfunction

function CS_LoadRawcodeFromReal takes integer n returns integer
 return udg_castervars[n]
 return 0
endfunction

function CS_CopyGroup takes group g returns group
    set bj_groupAddGroupDest=CreateGroup()
    call ForGroup(g, function GroupAddGroupEnum)
 return bj_groupAddGroupDest
endfunction

function CS_IsUnitVisible takes unit u, player p returns boolean
     return IsUnitVisible(u,Player(bj_PLAYER_NEUTRAL_VICTIM)) or IsUnitVisible(u,p)
endfunction

constant function CS_RectLimitOffSet takes nothing returns real
    return 50.0
endfunction

function CS_MoveUnit takes unit u, real x, real y returns boolean
 local rect r=bj_mapInitialPlayableArea
 local real t=GetRectMinX(r)+CS_RectLimitOffSet()
 local boolean b=true
    if (x<t) then
        set x=t
        set b=false
    else
        set t=GetRectMaxX(r)-CS_RectLimitOffSet()
        if (x>t) then
            set b=false
            set x=t
        endif
    endif
    set t=GetRectMinY(r)+CS_RectLimitOffSet()
    if (y<t) then
        set y=t
        set b=false
    else
        set t=GetRectMaxY(r)-CS_RectLimitOffSet()
        if (y>t) then
            set y=t
            set b=false
        endif
    endif
    if (b) then
    call SetUnitX(u, x)
    call SetUnitY(u, y)
    endif
 set r=null
 return b
endfunction
function CS_MoveUnitLoc takes unit u, location loc returns boolean
    return CS_MoveUnit(u,GetLocationX(loc),GetLocationY(loc))
endfunction

//==================================================================================================
function CS_EnumUnitsInAOE_Filter takes nothing returns boolean
    return IsUnitInRangeLoc(GetFilterUnit(), bj_enumDestructableCenter ,bj_enumDestructableRadius)
endfunction

//==================================================================================================
// Use this version when you only have coordinates of the point.
//
function CS_EnumUnitsInAOE takes group g, real x, real y, real area, boolexpr bx returns nothing
 local boolexpr cond
 local boolexpr aux=Condition(function CS_EnumUnitsInAOE_Filter)

    if (bx==null) then
        set cond=aux
    else
        set cond=And(aux,bx)
    endif
    set bj_enumDestructableCenter=Location(x,y)
    set bj_enumDestructableRadius=area
    call GroupEnumUnitsInRange(g,x,y,CS_MaxCollisionSize()+area,cond)
    call DestroyBoolExpr(cond)
    if (bx!=null) then
        call DestroyBoolExpr(aux)
    endif
    call RemoveLocation(bj_enumDestructableCenter)
 set aux=null
 set cond=null
endfunction

//==================================================================================================
// Use this version whenever you already have a location for that point, to save some steps
//
function CS_EnumUnitsInAOELoc takes group g, location loc, real area, boolexpr bx returns nothing
 local boolexpr cond
 local boolexpr aux=Condition(function CS_EnumUnitsInAOE_Filter)

    if (bx==null) then
        set cond=aux
    else
        set cond=And(aux,bx)
    endif
    set bj_enumDestructableCenter=loc
    set bj_enumDestructableRadius=area
    call GroupEnumUnitsInRangeOfLoc(g,loc,CS_MaxCollisionSize()+area,cond)
    call DestroyBoolExpr(cond)
    if (bx!=null) then
        call DestroyBoolExpr(aux)
    endif
 set aux=null
 set cond=null
endfunction



//##Begin of CS Gamecache engine##
//=================================================================================================
// GameCache - Return bug module : Without gamecache or return bug, JASS would be a
// retarded-limited scripting language.
//
//=================================================================================================
// a.k.a H2I, changed name to CS_H2I to prevent conflicts with other systems (I intended this
// system to be easy to copy
//
function CS_H2I takes handle h returns integer
    return h
    return 0
endfunction

//=================================================================================================
// Main Gamecache handler
//
function CSCache takes nothing returns gamecache
    if udg_cscache==null then
        call FlushGameCache(InitGameCache("CasterSystem.vx"))
        set udg_cscache=InitGameCache("CasterSystem.vx")
        call StoreInteger(udg_cscache,"misc","TableMaxReleasedIndex",100)
    endif
 return udg_cscache
endfunction

//==================================================================================================
// Attachable vars : Attacheable variables are what most other people call Handle Variables, they
// allow to relate data with any handle, using a label, and its value, the stuff auto flushes if
// the value is 0, false, "", or null .
//
// Differences between Attacheable variables and "Local Handle Variables" :
// - The names of the functions
// - The name of the function group does not cause confusion, it is difficult to say: 
//   "you should set local handle variables to null at the end of a function" since
//   it sounds as if you were talking about the "Local Handle Variables"
// - Also Have Attacheable Sets.
// - And can work together with Tables.
// 
// Notes: don't "attach" variables on texttags nor those handle types used mostly for parameters
// (for example damagetype) , Although there is no reason to do so anyways
//
// Gamecache stuff are NOT Case Sensitive, don't ever use "" for label (Crashes game!)
//

//============================================================================================================
// For integers
//
function AttachInt takes handle h, string label, integer x returns nothing
 local string k=I2S(CS_H2I(h))
    if x==0 then
        call FlushStoredInteger(CSCache(),k,label)
    else
        call StoreInteger(CSCache(),k,label,x)
    endif
endfunction
function GetAttachedInt_FromSet takes handle h, gamecache g returns integer
    return GetStoredInteger(g,I2S(CS_H2I(h))+";"+GetStoredString(g,"argpass","set"),GetStoredString(g,"argpass","seti"))
endfunction
function GetAttachedInt takes handle h, string label returns integer
    if (label=="") then
        return GetAttachedInt_FromSet(h,CSCache())
    endif
 return GetStoredInteger(CSCache(), I2S(CS_H2I(h)), label)
endfunction

//=============================================================================================================
function AttachReal takes handle h, string label, real x returns nothing
 local string k=I2S(CS_H2I(h))
    if x==0 then
        call FlushStoredReal(CSCache(),k,label)
    else
        call StoreReal(CSCache(),k,label,x)
    endif
endfunction
function GetAttachedReal takes handle h, string label returns real
    return GetStoredReal(CSCache(),I2S(CS_H2I(h)),label)
endfunction

//=============================================================================================================
function AttachBoolean takes handle h, string label, boolean x returns nothing
 local string k=I2S(CS_H2I(h))
    if not x then
        call FlushStoredBoolean(CSCache(),k,label)
    else
        call StoreBoolean(CSCache(),k,label,x)
    endif
endfunction
function GetAttachedBoolean takes handle h, string label returns boolean
    return GetStoredBoolean(CSCache(),I2S(CS_H2I(h)),label)
endfunction

//=============================================================================================================
function AttachString takes handle h, string label, string x returns nothing
 local string k=I2S(CS_H2I(h))
    if x=="" then
        call FlushStoredString(CSCache(),k,label)
    else
        call StoreString(CSCache(),k,label,x)
    endif
endfunction
function GetAttachedString takes handle h, string label returns string
    return GetStoredString(CSCache(),I2S(CS_H2I(h)),label)
endfunction

//=============================================================================================================
function AttachObject takes handle h, string label, handle x returns nothing
 local string k=I2S(CS_H2I(h))
    if (x==null) then
        call FlushStoredInteger(CSCache(),k,label)
    else
        call StoreInteger(CSCache(),k,label,CS_H2I(x))
    endif
endfunction
function GetAttachedObject takes handle h, string label returns handle
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedWidget takes handle h, string label returns widget
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedRect takes handle h, string label returns rect
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedRegion takes handle h, string label returns region
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedTimerDialog takes handle h, string label returns timerdialog
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedUnit takes handle h, string label returns unit
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedItem takes handle h, string label returns item
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedEffect takes handle h, string label returns effect
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedDestructable takes handle h, string label returns destructable
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedTrigger takes handle h, string label returns trigger
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedTimer takes handle h, string label returns timer
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedGroup takes handle h, string label returns group
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedTriggerAction takes handle h, string label returns triggeraction
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedLightning takes handle h, string label returns lightning
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedImage takes handle h, string label returns image
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedUbersplat takes handle h, string label returns ubersplat
    return GetAttachedInt(h,label)
    return null
endfunction
function GetAttachedSound takes handle h, string label returns sound
    return GetAttachedInt(h,label)
    return null
endfunction


//============================================================================================================
// Attached Sets: Attachable Sets are handy in some situations and are a part of attachable variables,
// you can add integers or objects to a set, order doesn't matter and adding the same object twice is
// meaningless. CleanAttachedVars is always ready to clean every set owned by the handle.
//
//============================================================================================================
function AttachedSetAddInt takes handle h, string setn, integer int returns nothing
 local gamecache g=CSCache()
 local string k=I2S(CS_H2I(h))
 local integer n
 local integer x=GetStoredInteger(g,k,"#setnumberof;"+setn)
 local integer y
    if x==0 then
        set y=GetStoredInteger(g,k,"#totalsets")+1
        call StoreInteger(g,k,"#totalsets",y)
        call StoreInteger(g,k,"#setnumberof;"+setn,y)
        call StoreString(g,k,"#setName;"+I2S(y),setn)
    endif
    set k=k+";"+setn
    if not HaveStoredInteger(g,k,"Pos"+I2S(int)) then
        set n=GetStoredInteger(g,k,"n")+1
        call StoreInteger(g,k,"n",n)
        call StoreInteger(g,k,I2S(n),int)
        call StoreInteger(g,k,"Pos"+I2S(int),n)
    endif
 set g=null
endfunction
function AttachedSetAddObject takes handle h, string setn, handle val returns nothing
    call AttachedSetAddInt(h,setn,CS_H2I(val))
endfunction

//============================================================================================================
function AttachedSetHasInt takes handle h, string setn, integer int returns boolean
    return HaveStoredInteger(CSCache(),I2S(CS_H2I(h))+";"+setn,"Pos"+I2S(int))
endfunction
function AttachedSetHasObject takes handle h, string setn, handle val returns boolean
    return AttachedSetHasInt(h,setn,CS_H2I(val))
endfunction

//============================================================================================================
function GetAttachedSetSize takes handle h, string setn returns integer
    return GetStoredInteger(CSCache(),I2S(CS_H2I(h))+";"+setn,"n")
endfunction

//============================================================================================================
function AttachedSetRemInt takes handle h, string setn, integer int returns nothing
 local gamecache g=CSCache()
 local string k=I2S(CS_H2I(h))+";"+setn
 local integer n
 local integer x
 local integer y
    if HaveStoredInteger(g,k,"Pos"+I2S(int)) then
        set x=GetStoredInteger(g,k,"Pos"+I2S(int))
        set n=GetStoredInteger(g,k,"n")
        if x!=n then
            set y=GetStoredInteger(g,k,I2S(n))
            call StoreInteger(g,k,I2S(x),y)
            call StoreInteger(g,k,"Pos"+I2S(y),x)
        endif        
        call FlushStoredInteger(g,k,"Pos"+I2S(int))
        call FlushStoredInteger(g,k,I2S(n))
        call StoreInteger(g,k,"n",n-1)
    endif
 set g=null
endfunction
function AttachedSetRemObject takes handle h, string setn, handle val returns nothing
    call AttachedSetRemInt(h,setn,CS_H2I(val))
endfunction

//============================================================================================================
function FromSetElement takes string setn, integer index returns string
 local gamecache g=CSCache()
    call StoreString(g,"argpass","set",setn)
    call StoreString(g,"argpass","seti",I2S(index))
 set g=null
 return ""
endfunction

//============================================================================================================
function ClearAttachedSet takes handle h, string setn returns nothing
    call FlushStoredMission(CSCache(),I2S(CS_H2I(h))+";"+setn)
endfunction

function CleanAttachedVars takes handle h returns nothing
 local gamecache g=CSCache()
 local string k=I2S(CS_H2I(h))
 local integer n=GetStoredInteger(g,k,"#totalsets")
 local integer i=1
    loop
        exitwhen i>n
        call FlushStoredMission(g,k+";"+GetStoredString(g,k,"#setName;"+I2S(i)))
        set i=i+1
    endloop
    call FlushStoredMission(g, k )
 set g=null
endfunction

function CleanAttachedVars_NoSets takes handle h returns nothing
    call FlushStoredMission(CSCache(), I2S(CS_H2I(h)) )
endfunction



//=============================================================================================
// Tables
//
// Tables are lame, the real name would be hash tables, they are just abbreviated usage
// of gamecache natives with the addition that you can also Copy the values of a table to
// another one, but don't expect it to be automatic, it must use a FieldData object to know
// which fields and of wich types to copy, Copying a table to another, with a lot of Fields,
// should surelly be lag friendly.
//
// The other thing about tables is that I can say that the Attached variables of a handle work
// inside a table and GetAttachmentTable which is just return bug and I2S , works to allow you
// to manipulate a handle's attached variables through a table.
//
// NewTable and DestroyTable were created to allow to create tables in the fly, but you can
// simply use strings for tables, but place the table names should be between "("")" for example
// "(mytable)" to avoid conflicts with other caster system stuff.
//
function NewTableIndex takes nothing returns integer
 local gamecache g=CSCache()
 local integer n=GetStoredInteger(g,"misc","FreeTableTotal")
 local integer i
     if (n>0) then
         set i=GetStoredInteger(g,"misc","FreeTable1")
         if (n>1) then
             call StoreInteger(g,"misc","FreeTable1", GetStoredInteger(g,"misc","FreeTable"+I2S(n)) )
             call FlushStoredInteger(g,"misc","FreeTable"+I2S(n))
         endif
         call StoreInteger(g,"misc","FreeTableTotal", n-1)
     else
         set i=GetStoredInteger(g,"misc","TableMaxReleasedIndex")+1
         call StoreInteger(g,"misc","TableMaxReleasedIndex",i)
     endif
     call StoreBoolean(g,"misc","Created"+I2S(i),true)

 set g=null
 return i
endfunction
function NewTable takes nothing returns string
    return I2S(NewTableIndex())
endfunction
function GetAttachmentTable takes handle h returns string
    return I2S(CS_H2I(h))
endfunction

//============================================================================================================
function DestroyTable takes string table returns nothing
 local gamecache g=CSCache()
 local integer i=S2I(table)
 local integer n
     if (i!=0) and (GetStoredBoolean(g,"misc","Created"+table)) then
         call FlushStoredBoolean(g,"misc","Created"+table)
         set n=GetStoredInteger(g,"misc","FreeTableTotal")+1
         call StoreInteger(g,"misc","FreeTableTotal",n)
         call StoreInteger(g,"misc","FreeTable"+I2S(n),i)
     endif
     call FlushStoredMission(g,table)
 set g=null
endfunction

//============================================================================================================
function ClearTable takes string table returns nothing
     call FlushStoredMission(CSCache(),table)
endfunction


//============================================================================================================
function SetTableInt takes string table, string field, integer val returns nothing
 local gamecache g=CSCache()
    if (val==0) then
        call FlushStoredInteger(g,table,field)
    else
        call StoreInteger(g,table,field,val)
    endif
 set g=null
endfunction
function GetTableInt takes string table, string field returns integer
    return GetStoredInteger(CSCache(),table,field)
endfunction

//============================================================================================================
function SetTableReal takes string table, string field, real val returns nothing
 local gamecache g=CSCache()
    if (val==0) then
        call FlushStoredReal(g,table,field)
    else
        call StoreReal(g,table,field,val)
    endif
 set g=null
endfunction
function GetTableReal takes string table, string field returns real
    return GetStoredReal(CSCache(),table,field)
endfunction

//============================================================================================================
function SetTableBoolean takes string table, string field, boolean val returns nothing
 local gamecache g=CSCache()
    if (not(val)) then
        call FlushStoredBoolean(g,table,field)
    else
        call StoreBoolean(g,table,field,val)
    endif
 set g=null
endfunction
function GetTableBoolean takes string table, string field returns boolean
    return GetStoredBoolean(CSCache(),table,field)
endfunction

//============================================================================================================
function SetTableString takes string table, string field, string val returns nothing
 local gamecache g=CSCache()
    if (val=="") or (val==null) then
        call FlushStoredString(g,table,field)
    else
        call StoreString(g,table,field,val)
    endif
 set g=null
endfunction
function GetTableString takes string table, string field returns string
    return GetStoredString(CSCache(),table,field)
endfunction

//============================================================================================================
// You may ask why am I using thousands of functions instead of multi-use return bug exploiters? Well,
// these make the thing much easier to read (in my opinion) and it is also better in performance since we
// have less function calls (H2U(GetTableObject("table","unit"))) would be worse than GetTableUnit that is
// quite direct.
//
function SetTableObject takes string table, string field, handle val returns nothing
  local gamecache g=CSCache()
    if (val==null) then
        call FlushStoredInteger(g,table,field)
    else
        call StoreInteger(g,table,field,CS_H2I(val))
    endif
 set g=null
endfunction
function GetTableObject takes string table, string field returns handle
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableWidget takes string table, string field returns widget
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableRect takes string table, string field returns rect
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableRegion takes string table, string field returns region
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableTimerDialog takes string table, string field returns timerdialog
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableUnit takes string table, string field returns unit
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableItem takes string table, string field returns item
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableEffect takes string table, string field returns effect
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableDestructable takes string table, string field returns destructable
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableTrigger takes string table, string field returns trigger
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableTimer takes string table, string field returns timer
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableGroup takes string table, string field returns group
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableTriggerAction takes string table, string field returns triggeraction
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableLightning takes string table, string field returns lightning
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableImage takes string table, string field returns image
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableUbersplat takes string table, string field returns ubersplat
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction
function GetTableSound takes string table, string field returns sound
    return GetStoredInteger(CSCache(),table,field)
    return null
endfunction

//============================================================================================================
// Returns true if the fiel contains a value different from 0, false,  null, or "" (depending on the type)
// it is worthless to use this with boolean, since it would be the same as reading the boolean value
//
function HaveSetField takes string table, string field, integer fieldType returns boolean
    if (fieldType == bj_GAMECACHE_BOOLEAN) then
        return HaveStoredBoolean(CSCache(),table,field)
    elseif (fieldType == bj_GAMECACHE_INTEGER) then
        return HaveStoredInteger(CSCache(),table,field)
    elseif (fieldType == bj_GAMECACHE_REAL) then
        return HaveStoredReal(CSCache(),table,field)
    elseif (fieldType == bj_GAMECACHE_STRING) then
        return HaveStoredString(CSCache(),table,field)
    endif
 return false
endfunction

//============================================================================================================
// Allows to copy a table to another one, but it needs a FieldData object to know which fields of which type
// it is supposed to copy.
//
function CopyTable takes integer FieldData, string sourceTable, string destTable returns nothing
 local gamecache g=CSCache()
 local integer i=1
 local string k=I2S(FieldData)
 local string k2
 local string k3
 local integer n=GetStoredInteger(g,k,"N")
 local integer t
    loop
        exitwhen (i>n)
        set k2=I2S(i)
        set t=GetStoredInteger(g,k,k2)
        set k3=GetStoredString(g,k,k2)
        if (t==bj_GAMECACHE_BOOLEAN) then
            if (HaveStoredBoolean(g,sourceTable,k3)) then
                call StoreBoolean(g,destTable,k3,GetStoredBoolean(g,sourceTable,k3))
            else
                call FlushStoredBoolean(g,destTable,k3)
            endif
        elseif (t==bj_GAMECACHE_INTEGER) then
            if (HaveStoredInteger(g,sourceTable,k3)) then
                call StoreInteger(g,destTable,k3,GetStoredInteger(g,sourceTable,k3))
            else
                call FlushStoredInteger(g,destTable,k3)
            endif
        elseif (t==bj_GAMECACHE_REAL) then
            if (HaveStoredReal(g,sourceTable,k3)) then
                call StoreReal(g,destTable,k3,GetStoredReal(g,sourceTable,k3))
            else
                call FlushStoredReal(g,destTable,k3)
            endif
        elseif (t==bj_GAMECACHE_STRING) then
            if (HaveStoredString(g,sourceTable,k3)) then
                call StoreString(g,destTable,k3,GetStoredString(g,sourceTable,k3))
            else
                call FlushStoredString(g,destTable,k3)
            endif
        endif
        set i=i+1
    endloop


 set g=null
endfunction

//=============================================================================================
// FieldData inherits from Table, was just designed to be used by CopyTable.
//
function FieldData_Create takes nothing returns integer
    return NewTableIndex()
endfunction

//============================================================================================================
// valueType uses the same integer variables from blizzard.j :
// bj_GAMECACHE_BOOLEAN, bj_GAMECACHE_INTEGER, bj_GAMECACHE_REAL and bj_GAMECACHE_STRING
//
function FieldData_AddField takes integer fielddata, string field, integer valueType returns nothing
 local gamecache g=CSCache()
 local string k=I2S(fielddata)
 local integer n=GetStoredInteger(g,k,"N")+1
 local string k2=I2S(n)

    call StoreString(g,k,k2,field)
    call StoreInteger(g,k,k2,valueType)
    call StoreInteger(g,k,"N",n)
 set g=null
endfunction

//=============================================================================================
// Destroys Field Data
function FieldData_Destroy takes integer fielddata returns nothing
    call DestroyTable(I2S(fielddata))
endfunction

//##End of CS Gamecache engine##

//==================================================================================================
// Angle Calculations
//
// I decided to add them to the caster system, because I found myself using them everytime, I am
// trying to convert the caster system into a Spell Development Framework (hehe)
//
//=================================================================================================
// Returns the angle distance between angles a1 and a2 (For example: a1=30 , a2=60 , return= 30 )
//
function Angles_GetAngleDifference takes real a1, real a2 returns real
 local real x
    set a1=ModuloReal(a1,360)
    set a2=ModuloReal(a2,360)
    if a1>a2 then
        set x=a1
        set a1=a2
        set a2=x
    endif
    set x=a2-360
    if a2-a1 > a1-x then
        set a2=x
    endif
 return RAbsBJ(a1-a2)
endfunction

//=================================================================================================
// Returns the mid angle between a1 and a2 (For example: a1=30 , a2=60 , return= 45 )
//
function Angles_GetMidAngle takes real a1, real a2 returns real
 local real x
    set a1=ModuloReal(a1,360)
    set a2=ModuloReal(a2,360)
    if a1>a2 then
        set x=a1
        set a1=a2
        set a2=x
    endif
    set x=a2-360
    if a2-a1 > a1-x then
        set a2=x
    endif
 return (a1+a2)/2
endfunction

//=================================================================================================
// Makes angle a1 advance i units towards angle a2 (For Example: a1=30, a2=60, i=10, return=40 )
//
function Angles_MoveAngleTowardsAngle takes real a1, real a2, real i returns real
 local real x
    set a1=ModuloReal(a1,360)
    set a2=ModuloReal(a2,360)
    if a1>a2 then
        set x=a1-360
        if a1-a2 > a2-x then
            set a1=x
        endif
    else
        set x=a2-360
        if a2-a1 > a1-x then
            set a2=x
        endif
    endif
    if a1>a2 then
        set x=a1-i
        if x<=a2 then
            return a2
        endif
       return x
    endif
    set x=a1+i
    if x>=a2 then
        return a2
    endif
 return x
endfunction

//=================================================================================================
// Returns true if the angle 'angle' is between 'angle1' and 'angle2'
//
function Angles_IsAngleBetweenAngles takes real angle, real angle1, real angle2 returns boolean
 local real x
    set angle=ModuloReal(angle,360)
    set angle1=ModuloReal(angle1,360)
    set angle2=ModuloReal(angle2,360)
    if (angle1>angle2) then
        set x=angle1
        set angle1=angle2
        set angle2=x
    endif
    if (angle2-angle1)>(angle1 - (angle2-360)) then
        set angle2=angle2-360
        if angle > 180 then
            set angle=angle-360
        endif
        return angle>=angle2 and angle<=angle1
    endif
 return (angle>=angle1) and (angle<=angle2)
endfunction

//====================================================================================================================================================================
function AddCasterFacing takes real fac returns unit
 local unit m=CreateUnit( Player(15), Caster_UnitId(), 0 ,0 ,fac)
    call UnitAddAbility(m, 'Aloc')
    call UnitAddAbility(m, ChangeableFlyingHeightAllowerId())
    call UnitRemoveAbility(m, ChangeableFlyingHeightAllowerId())
 set udg_currentcaster=m
 set m=null
 return udg_currentcaster
endfunction

function AddCaster takes nothing returns unit
    return AddCasterFacing(0)
endfunction

//====================================================================================================================================================================
function CS_KillTrigger takes trigger t returns nothing
    if (t!=null) then
        call TriggerRemoveAction(t,GetAttachedTriggerAction(t,"ac"))
        call CleanAttachedVars(t)
        call DestroyTrigger(t)
    endif
endfunction

function CS_KillTimer takes timer t returns nothing
    if (t!=null) then
        call PauseTimer(t)
        call CleanAttachedVars(t)
        call DestroyTimer(t)
    endif
endfunction

//====================================================================================================================================================================
function CreateCasters takes integer n returns nothing
 local integer a=0
 local unit c
    set udg_castervars[100]=-1
    set udg_castervars[101]=-1
    set udg_castervars[102]=-1
    set udg_castervars[103]=-1
    set udg_castervars[104]=-1
    loop
        exitwhen a>=n
        set c=AddCaster()
        call GroupAddUnit( udg_casters, c)
        set a=a+1
    endloop
 set c=null
 call RemoveLocation(udg_sourcehack)
 set udg_sourcehack=null
endfunction

//====================================================================================================================================================================
function GetACaster takes nothing returns unit
    set udg_currentcaster=FirstOfGroup( udg_casters)
    if udg_currentcaster == null then
        set udg_currentcaster=AddCaster()
    endif
    call GroupRemoveUnit( udg_casters,udg_currentcaster)
    call SetUnitState( udg_currentcaster, UNIT_STATE_MANA, 1000)
 return udg_currentcaster
endfunction

//====================================================================================================================================================================
function Caster_SetZAngle takes unit caster, real ang returns nothing
 local real a=(ModuloReal(GetUnitFacing(caster),360)*bj_DEGTORAD)
 local real x
    set ang=ModuloReal(ang,360)
    if ( ang == 90 ) then
        set ang = 89
    endif
    if ( ang == 270 ) then
        set ang = 271
    endif
    if (ang>90) and (ang<270) then
        set x=-1
    else
        set x=1
    endif
    set ang=ang*bj_DEGTORAD
    call SetUnitLookAt(caster,"Bone_Chest",caster, 10000.0*Cos(a)*Cos(ang), 10000.0*Sin(a)*Cos(ang), x*(10000.0*Tan(ang)+90.0) )
endfunction


//====================================================================================================================================================================
function RecicleCaster takes unit caster returns nothing
    if not IsUnitDeadBJ(caster) then
        call ResetUnitLookAt(caster)
        call SetUnitOwner( caster, Player(15), true)
        call SetUnitVertexColor( caster, 255,255,255,255)
        call SetUnitScale( caster, 1,1,1)
        call SetUnitTimeScale( caster, 1)
        call SetUnitMoveSpeed( caster, 522)
        call SetUnitFlyHeight( caster, 0,0)
        call UnitAddAbility(caster, 'Aloc')
        call SetUnitTurnSpeed( caster, 0.6)
        call GroupAddUnit( udg_casters, caster)
    endif
endfunction

function CasterRecycleTimed_X takes nothing returns nothing
 local timer t=GetExpiredTimer()
 local string k=GetAttachmentTable(t)
 local unit c=GetTableUnit(k,"c")
 local integer a=GetTableInt(k,"a")
    if (a!=0) then
        call UnitRemoveAbility(c,a)
    endif
    call RecicleCaster(c)
    call ClearTable(k)
    call DestroyTimer(t)
 set c=null
 set t=null
endfunction

function CasterRecycleTimed takes unit caster, integer abi, real delay returns nothing
 local timer t=CreateTimer()
 local string k=GetAttachmentTable(t)
    call SetTableObject(k,"c",caster)
    if (abi!=0) then
        call SetTableInt(k,"a",abi)
    endif
    call TimerStart(t,delay,false,function CasterRecycleTimed_X)
 set t=null
endfunction

function CasterWaitForEndCast takes nothing returns nothing
 local unit caster=udg_currentcaster
 local integer abilid=udg_currentabi
 local real delay=udg_castervars[0]
 local boolean activeability=(udg_castervars[1]>0)
    loop
        exitwhen GetUnitCurrentOrder(caster) == 0
        call TriggerSleepAction(0)
    endloop
    if (delay>0) then
        if activeability then
            call CasterRecycleTimed(caster,abilid,delay)
        else
            call UnitRemoveAbility( caster, abilid)
            call CasterRecycleTimed(caster,0,delay)
        endif
    else
        call UnitRemoveAbility( caster, abilid)
        call RecicleCaster(caster)
    endif
 set caster=null
endfunction

function RecicleCasterAfterCastEx takes unit caster, real delaytime, integer abilid, boolean activeability returns nothing
    set udg_castervars[0]=delaytime
    set udg_castervars[1]=IntegerTertiaryOp(activeability,1,0)
    set udg_currentabi=abilid
    set udg_currentcaster=caster
    call ExecuteFunc("CasterWaitForEndCast" )
endfunction

function RecicleCasterAfterCast takes unit caster, integer abilid returns nothing
    call RecicleCasterAfterCastEx(caster,udg_delayhack,abilid,false)
endfunction

//====================================================================================================================================================================
function PreloadAbility takes integer abilid returns integer
 local unit u=FirstOfGroup(udg_casters)
    if u==null then
        set u=GetACaster()
        call UnitAddAbility(u, abilid)
        call UnitRemoveAbility(u, abilid)
        call RecicleCaster( u)
    else
        call UnitAddAbility(u, abilid)
        call UnitRemoveAbility(u, abilid)
    endif
 set u=null
 return abilid
endfunction

//====================================================================================================================================================================
function CasterCastAbilityEx takes player owner, real x, real y, real z, integer abilid, integer level, string order, widget target, real delay returns unit
 local unit caster=GetACaster()
 local boolean done=false
    call SetUnitOwner( caster, owner, false)
    call UnitAddAbility( caster, abilid)
    call SetUnitAbilityLevel(caster,abilid,level)
    call CS_MoveUnit( caster, x,y)
    call SetUnitFlyHeight(caster,z,0)
    if S2I(order) != 0 then
        set done=IssueTargetOrderById( caster, S2I(order), target )
    else
        set done=IssueTargetOrder( caster, order, target )
    endif
    if (delay<=0) or not(done) then
        call UnitRemoveAbility( caster, abilid)
        call RecicleCaster( caster)
    else
        call RecicleCasterAfterCastEx(caster, delay, abilid, true)
    endif
 set udg_currentcaster=caster
 set caster=null
 return udg_currentcaster
endfunction

//====================================================================================================================================================================
function CasterCastAbilityExLoc takes player owner, location loc, real z, integer abilid, integer level, string order, widget target, real delay returns unit
    return CasterCastAbilityEx(owner,GetLocationX(loc),GetLocationY(loc),z,abilid,level,order,target,delay)
endfunction

//====================================================================================================================================================================
function CasterCastAbilityLevel takes player owner, integer abilid, integer level, string order, widget target, boolean instant returns unit
 local real x
 local real y
 local real d
    if udg_sourcehack!=null then
        set x=GetLocationX(udg_sourcehack)
        set y=GetLocationY(udg_sourcehack)
    else
        set x=GetWidgetX(target)
        set y=GetWidgetY(target)
    endif
    if not(instant)  then
        set d=udg_delayhack+0.01
    else
        set d=0
    endif
 return CasterCastAbilityEx(owner,x,y,0,abilid,level,order,target,d)
endfunction

//====================================================================================================================================================================
function CasterCastAbility takes player owner, integer abilid, string order, widget target, boolean instant returns unit
    return CasterCastAbilityLevel( owner, abilid, 1, order, target, instant )
endfunction

//====================================================================================================================================================================
function CasterCastAbilityPointEx takes player owner, real x1, real y1, real z1, integer abilid, integer level, string order, real x2, real y2, real delay returns unit
 local unit caster=GetACaster()
    call SetUnitOwner( caster, owner, false)
    call UnitAddAbility( caster, abilid)
    call SetUnitAbilityLevel(caster,abilid,level)
    call CS_MoveUnit( caster, x1, y1)
    call SetUnitFlyHeight(caster,z1,0)
    if S2I(order) != 0 then
        if not IssuePointOrderById( caster, S2I(order), x2,y2 ) then
            call IssueImmediateOrderById( caster, S2I(order) )
        endif
    else
        if not IssuePointOrder( caster, order, x2,y2 ) then
            call IssueImmediateOrder( caster, order )
        endif
    endif
    if (delay<=0) then
        call UnitRemoveAbility( caster, abilid)
        call RecicleCaster( caster)
    else
        call RecicleCasterAfterCastEx(caster, delay, abilid, true)
    endif
 set udg_currentcaster=caster
 set caster=null
 return udg_currentcaster
endfunction

//====================================================================================================================================================================
function CasterCastAbilityPointExLoc takes player owner, location loc1, real z1, integer abilid, integer level, string order, location loc2, real delay returns unit
    return CasterCastAbilityPointEx(owner,GetLocationX(loc1),GetLocationY(loc1),z1,abilid,level,order,GetLocationX(loc2),GetLocationY(loc2),delay)
endfunction

//====================================================================================================================================================================
function CasterCastAbilityLevelPoint takes player owner, integer abilid, integer level, string order, real x, real y, boolean instant returns unit
 local real sx
 local real sy
 local real d
    if udg_sourcehack!=null then
        set sx=GetLocationX(udg_sourcehack)
        set sy=GetLocationY(udg_sourcehack)
    else
        set sx=x
        set sy=y
    endif
    if instant then
        set d=0
    else
        set d=udg_delayhack+0.01
    endif
 return CasterCastAbilityPointEx(owner,sx,sy,0,abilid,level,order,x,y,d)
endfunction

function CasterCastAbilityPoint takes player owner, integer abilid, string order, real x, real y, boolean instant returns unit
    return CasterCastAbilityLevelPoint(owner,abilid,1,order,x,y,instant)
endfunction

function CasterCastAbilityPointLoc takes player owner, integer abilid, string order, location loc, boolean instant returns unit
    return CasterCastAbilityLevelPoint( owner, abilid, 1,order, GetLocationX(loc), GetLocationY(loc), instant )
endfunction

function CasterCastAbilityLevelPointLoc takes player owner, integer abilid, integer level, string order, location loc, boolean instant returns unit
    return CasterCastAbilityLevelPoint( owner, abilid, level,order, GetLocationX(loc), GetLocationY(loc), instant )
endfunction

//====================================================================================================================================================================
function CasterUseAbilityLevelStatic_Rec takes nothing returns nothing
 local timer t=GetExpiredTimer() 
 local string k=GetAttachmentTable(t)
    call RecicleCaster(GetTableUnit(k,"c"))
    call ClearTable(k)
    call DestroyTimer(t)
 set t=null
endfunction

function CasterUseAbilityLevelStatic_X takes nothing returns nothing
 local timer t=GetExpiredTimer() 
 local string k=GetAttachmentTable(t)

    call DestroyEffect(GetTableEffect(k,"fx") )
    call UnitRemoveAbility(GetTableUnit(k,"c"),GetTableInt(k,"a"))
    call TimerStart(t,2,false, function CasterUseAbilityLevelStatic_Rec)
 set t=null
endfunction

function CasterUseAbilityLevelStatic takes player owner, string modelpath, integer abilityid, integer level, real duration, real x, real y returns unit
 local timer t=CreateTimer()
 local string k=GetAttachmentTable(t)
 local unit c=GetACaster()
    call SetUnitPosition( c, x, y)
    call SetTableObject(k,"fx", AddSpecialEffectTarget( modelpath, c,"origin" ))
    call SetTableObject(k,"c",c)
    call SetTableInt(k,"a",abilityid)

    call TimerStart(t,duration,false,function CasterUseAbilityLevelStatic_X)
    call SetUnitOwner(c, owner, true)
    call UnitAddAbility(c, abilityid)
    call SetUnitAbilityLevel(c, abilityid, level)



    set udg_currentcaster=c
 set t=null
 set c=null
 return udg_currentcaster
endfunction

function CasterUseAbilityStatic takes player owner, string modelpath, integer abilityid, real duration, real x, real y returns unit
    return CasterUseAbilityLevelStatic(owner,modelpath,abilityid,1,duration,x,y)
endfunction

function CasterUseAbilityStaticLoc takes player owner, string modelpath, integer abilityid, real duration, location loc returns unit
    return CasterUseAbilityLevelStatic(owner,modelpath,abilityid,1,duration, GetLocationX(loc), GetLocationY(loc))
endfunction

function CasterUseAbilityLevelStaticLoc takes player owner, string modelpath, integer abilityid, integer level,real duration, location loc returns unit
    return CasterUseAbilityLevelStatic(owner,modelpath,abilityid,level,duration, GetLocationX(loc), GetLocationY(loc))
endfunction

//====================================================================================================================================================================
function CasterCastAbilityLevelGroup takes player owner, integer abilid, integer level,string order, group targetgroup, boolean instant returns nothing
 local group affected
 local unit tempunit
 local unit caster=null
    if bj_wantDestroyGroup then
        set bj_wantDestroyGroup=false
        set affected=targetgroup
    else
        set affected=CreateGroup()
        call GroupAddGroup( targetgroup, affected)
    endif
    loop
       set tempunit=FirstOfGroup(affected)
       exitwhen tempunit == null
       if instant then
           if caster==null then
               set caster=GetACaster()
               call SetUnitOwner( caster, owner, false)
               call UnitAddAbility( caster, abilid)
               call SetUnitAbilityLevel( caster, abilid,level)
           endif
           if udg_sourcehack != null then
               call CS_MoveUnit(caster,GetLocationX(udg_sourcehack),GetLocationY(udg_sourcehack))
           else
               call CS_MoveUnit( caster, GetUnitX(tempunit), GetUnitY(tempunit))
           endif

           if S2I(order) != 0 then
               call IssueTargetOrderById( caster, S2I(order), tempunit )
           else
               call IssueTargetOrder( caster, order, tempunit )
           endif
       else
           call CasterCastAbilityLevel( owner, abilid,level, order, tempunit, false)
       endif
       call GroupRemoveUnit(affected, tempunit)    
    endloop
    if caster != null then
        call UnitRemoveAbility( caster, abilid)
        call RecicleCaster(caster)
    endif
 call DestroyGroup(affected)
 set affected=null
 set tempunit=null
 set caster=null
endfunction

function CasterCastAbilityGroup takes player owner, integer abilid, string order, group targetgroup, boolean instant returns nothing
    call CasterCastAbilityLevelGroup(owner,abilid,1,order,targetgroup,instant)
endfunction

//====================================================================================================================================================================
function CasterAOE_IsFilterEnemy takes nothing returns boolean
    return IsUnitEnemy( GetFilterUnit(), bj_groupEnumOwningPlayer ) and not(IsUnitDeadBJ(GetFilterUnit()))
endfunction

function CasterAOE_IsFilterAlly takes nothing returns boolean
    return IsUnitAlly( GetFilterUnit(), bj_groupEnumOwningPlayer ) and not(IsUnitDeadBJ(GetFilterUnit()))
endfunction

//====================================================================================================================================================================
function CasterCastAbilityLevelAOE takes player owner, integer abilid, integer level, string order, real x, real y, real radius, boolean goodeffect, boolean instant returns nothing
 local boolexpr b
 local group aoe=CreateGroup()
    set bj_groupEnumOwningPlayer=owner
    if goodeffect then
        set b=Condition(function CasterAOE_IsFilterAlly)
    else
        set b=Condition(function CasterAOE_IsFilterEnemy)
    endif
    call CS_EnumUnitsInAOE(aoe, x,y, radius, b)
    set bj_wantDestroyGroup=true
    call CasterCastAbilityLevelGroup( owner, abilid, level, order, aoe, instant)
 call DestroyBoolExpr(b)
 set b=null
 set aoe=null
endfunction

function CasterCastAbilityAOE takes player owner, integer abilid, string order, real x, real y, real radius, boolean goodeffect, boolean instant returns nothing
    call CasterCastAbilityLevelAOE(owner,abilid,1,order,x,y,radius,goodeffect,instant)
endfunction

function CasterCastAbilityAOELoc takes player owner, integer abilid, string order, location center, real radius, boolean goodeffect, boolean instant returns nothing
    call CasterCastAbilityLevelAOE(owner, abilid,1, order, GetLocationX(center),  GetLocationY(center), radius, goodeffect, instant)
endfunction

function CasterCastAbilityLevelAOELoc takes player owner, integer abilid, integer level, string order, location center, real radius, boolean goodeffect, boolean instant returns nothing
    call CasterCastAbilityLevelAOE(owner, abilid,level, order, GetLocationX(center),  GetLocationY(center), radius, goodeffect, instant)
endfunction

//====================================================================================================================================================================
function ResetSourceHack takes nothing returns nothing
    call RemoveLocation(udg_sourcehack)
    set udg_sourcehack=null
    call DestroyTimer(GetExpiredTimer() )
endfunction

function CasterSetCastSource takes real x, real y returns nothing
    set udg_sourcehack=Location(x,y)
    call TimerStart(CreateTimer(),0,false,function ResetSourceHack)
endfunction

function CasterSetCastSourceLoc takes location loc returns nothing
    call CasterSetCastSource( GetLocationX(loc), GetLocationY(loc) )
endfunction

function ResetDelayHack takes nothing returns nothing
    set udg_delayhack=0
    call DestroyTimer(GetExpiredTimer() )
endfunction

//====================================================================================================================================================================
function CasterSetRecycleDelay takes real Delay returns nothing
    set udg_delayhack=Delay
    call TimerStart(CreateTimer(),0,false,function ResetDelayHack)
endfunction

//====================================================================================================================================================================
function DamageTypes takes attacktype attT, damagetype dmgT returns integer
    set udg_castervars[100] = CS_H2I(attT)
    set udg_castervars[101] = CS_H2I(dmgT)
 return 1
endfunction

function DamageException takes unittype Exception, real ExceptionFactor returns integer
    set udg_castervars[102] = CS_H2I(Exception)
    set udg_castervars[103] = ExceptionFactor
 return 2
endfunction

function DamageOnlyTo takes unittype ThisUnitType returns integer
    set udg_castervars[104] = CS_H2I(ThisUnitType)
 return 4
endfunction

constant function DontDamageSelf takes nothing returns integer
 return 8
endfunction

constant function DamageTrees takes nothing returns integer
 return 16
endfunction

constant function DamageOnlyVisibles takes nothing returns integer
 return 32
endfunction

function DamageOnlyEnemies takes nothing returns integer
    set udg_castervars[105]=0
 return 64
endfunction

function ForceDamageAllies takes nothing returns integer
    set udg_castervars[105]=1
 return 64
endfunction

function DamageOnlyAllies takes nothing returns integer
    set udg_castervars[105]=2
 return 64
endfunction

function DamageFactorAbility1 takes integer spellid, real factor returns integer
    set udg_castervars[106]=CS_Rawcode2Real(spellid)
    set udg_castervars[107]=factor
 return 128
endfunction

function DamageFactorAbility2 takes integer spellid, real factor returns integer
    set udg_castervars[108]=CS_Rawcode2Real(spellid)
    set udg_castervars[109]=factor
 return 256
endfunction

function DamageFactorAbility3 takes integer spellid, real factor returns integer
    set udg_castervars[110]=CS_Rawcode2Real(spellid)
    set udg_castervars[111]=factor
 return 512
endfunction

function DamageIgnore takes unittype ThisUnitType returns integer
    set udg_castervars[112] = CS_H2I(ThisUnitType)
 return 1024
endfunction

function DamageAlliedFactor takes real fct returns integer
    set udg_castervars[113] = fct
 return 2048
endfunction

constant function ConsiderOnlyDeadUnits takes nothing returns integer
 return 4096
endfunction

constant function IgnoreDeadState takes nothing returns integer
 return 8192
endfunction


//===============================================================================================
function IsDamageOptionIncluded takes integer DamageOptions, integer whichDamageOption returns boolean
 local integer i=8192
    if (DamageOptions==0) then
        return false
    endif
    loop
        exitwhen (i<=whichDamageOption)
        if (DamageOptions>=i) then
            set DamageOptions=DamageOptions-i
        endif
        set i=i/2
    endloop
 return (DamageOptions>=whichDamageOption)
endfunction


//=================================================================================================
function GetDamageFactor takes unit u,attacktype a, damagetype d returns real
 local real hp=GetWidgetLife(u)
 local real r
 local unit caster=GetACaster()

    call UnitRemoveAbility(caster,'Aloc') //Otherwise the units would flee like crazy
    call CS_MoveUnit(caster,GetUnitX(u),GetUnitY(u))
    call SetUnitOwner(caster,GetOwningPlayer(u),false)
    set r=hp
    if (hp<1) then
        call SetWidgetLife(u,1)
        set r=1
    endif
    call UnitDamageTarget(caster,u,0.01,true,false,a,d,null)
    call RecicleCaster(caster)
    set r= (r-GetWidgetLife(u))*100
    call SetWidgetLife(u,hp)
 set caster=null
 return r
endfunction

//======================================================================================================
// Fix for the unit type bugs from blizzard, amphibious units aren't considered ground for some reason
// so this considers any non flying unit as ground.
//
// Also heroes are resistant too, so in case UNIT_TYPE_RESISTANT is used it will return true in case the
// unit is a hero too.
//
function CS_IsUnitType takes unit u, unittype ut returns boolean
    if (ut==UNIT_TYPE_GROUND) then
        return not(IsUnitType(u,UNIT_TYPE_FLYING))
    elseif (ut==UNIT_TYPE_RESISTANT) then
        return IsUnitType(u,ut) or IsUnitType(u,UNIT_TYPE_HERO)
    endif
 return IsUnitType(u,ut)
endfunction

function GetDamageFactorByOptions takes unit hurter, unit target, integer d returns real
 local real r=1
 
    if (d>=8192) then
	    set d=d-8192
	elseif (d>=4096) then
	    if (GetWidgetLife(target)>0.405) then
		    return 0.0
		endif
		set d=d-4096
	elseif (GetWidgetLife(target)<=0.405) then
        return 0.0
    endif

    if d>=2048 then
        if IsUnitAlly(target,GetOwningPlayer(hurter)) then
            set r=r*udg_castervars[113]
        endif
        set d=d-2048
    endif
    if d>=1024 then
        if CS_IsUnitType(target, ConvertUnitType(R2I(udg_castervars[112])) ) then
            return 0.0
        endif
        set d=d-1024
    endif
    if d>=512 then
        if GetUnitAbilityLevel(target,CS_LoadRawcodeFromReal(110))>0 then
            set r=r*udg_castervars[111]
        endif
        set d=d-512
    endif
    if d>=256 then
        if GetUnitAbilityLevel(target,CS_LoadRawcodeFromReal(108))>0 then
            set r=r*udg_castervars[109]
        endif
        set d=d-256
    endif
    if d>=128 then
        if GetUnitAbilityLevel(target,CS_LoadRawcodeFromReal(106))>0 then
            set r=r*udg_castervars[107]
        endif
        set d=d-128
    endif
    if d>=64 then
        if (udg_castervars[105]==0) and IsUnitAlly(target,GetOwningPlayer(hurter)) then
            return 0.0
        elseif (udg_castervars[105]==2) and IsUnitEnemy(target,GetOwningPlayer(hurter)) then
            return 0.0
        endif
        set d=d-64
    endif
    if d>=32 then
        set d=d-32
        if not CS_IsUnitVisible(target,GetOwningPlayer(hurter)) then
            return 0.0
        endif
    endif
    if d>=16 then
        set d=d-16
    endif
    if d>=8 then
        set d=d-8
        if hurter==target then
            return 0.0
        endif
    endif
    if d>=4 then
        set d=d-4
        if not CS_IsUnitType( target, ConvertUnitType(R2I(udg_castervars[104])) ) then
            return 0.0
        endif
    endif
    if d>=2 then
        set d=d-2
        if CS_IsUnitType( target, ConvertUnitType(R2I(udg_castervars[102])) ) then
            set r=r*udg_castervars[103]
        endif
    endif
    if d>=1 then
        set d=d-1
        set r=r*GetDamageFactor(target,ConvertAttackType(R2I(udg_castervars[100])),ConvertDamageType(R2I(udg_castervars[101])))
    endif
 return r
endfunction

//======================================================================================================================
// This used to be needed because in 1.17 UnitDamageTarget didn't consider the damagetype argument, this bug
// was fixed in 1.18, and we no longer need this function, left for compatibility.
//
function DamageUnitByTypes takes unit hurter, unit target, real dmg, attacktype attT, damagetype dmgT returns boolean
    return UnitDamageTarget(hurter,target,dmg,true,false,attT,dmgT,null)
endfunction

//=============================================================================================================================
function DamageUnitByOptions takes unit hurter, unit target, real dmg, integer DamageOptions returns boolean
 local real f=GetDamageFactorByOptions(hurter,target,DamageOptions)
    if (f==0) then
        return false
    endif
 return UnitDamageTarget(hurter,target,dmg*f,true,false,null,null,null)
endfunction

//=============================================================================================================================
function DamageUnit takes player hurter, real damage, unit victim returns boolean
 local unit caster=GetACaster()
    call UnitRemoveAbility(caster,'Aloc') //Otherwise the units would flee like crazy
    call CS_MoveUnit(caster,GetUnitX(victim),GetUnitY(victim))
    call SetUnitOwner(caster,hurter,false)
    call DamageUnitByTypes(caster,victim,damage,Caster_DefaultAttackType(),Caster_DefaultDamageType())
    call RecicleCaster(caster)
 return GetWidgetLife(victim)<=0 // I thought UnitDamageTarget returned true when it killed the unit, but nope, it returns true when it was able to do the damage.
endfunction

//====================================================================================================================================================================
function UnitDamageUnitTimed_Child takes nothing returns nothing
 local real damage = udg_castervars[0]
 local real damageperiod= udg_castervars[2]
 local effect fx=bj_lastCreatedEffect
 local timer t=CreateTimer()
 local unit hurter=udg_currenthurter
 local real next=0
 local integer i=0
 local real c
 local unit target=udg_currentcaster
 local damagetype dmgT=ConvertDamageType(R2I(udg_castervars[4]))
 local attacktype attT=ConvertAttackType(R2I(udg_castervars[3]))

    call TimerStart(t, udg_castervars[1]-0.01, false,null)
    loop
        if TimerGetElapsed(t) >= next then
            exitwhen not UnitDamageTarget(hurter, target, damage,true,false, attT, dmgT,null)
            exitwhen IsUnitDeadBJ(target)
            set i=i+1
            set next=i*damageperiod
        endif
        exitwhen (TimerGetRemaining(t) <= 0) or IsUnitDeadBJ(target)
        call TriggerSleepAction(0)
    endloop
 call DestroyEffect(fx)
 call DestroyTimer(t)
 set t=null
 set fx=null
 set dmgT=null
 set attT=null
endfunction

function UnitDamageUnitTimed takes unit hurter, real damageps, real damageperiod, real duration, unit target, string modelpath, string attachPointName, attacktype attT, damagetype dmgT returns nothing
 local unit c=udg_currentcaster
    set bj_lastCreatedEffect=AddSpecialEffectTarget( modelpath, target,attachPointName )
    set udg_currentcaster=target
    set udg_castervars[0]=damageps
    set udg_castervars[1]=duration
    set udg_castervars[2]=damageperiod
    set udg_castervars[3]=CS_H2I(attT)
    set udg_castervars[4]=CS_H2I(dmgT)
    set udg_currenthurter=hurter
    call ExecuteFunc("UnitDamageUnitTimed_Child")
    set udg_currentcaster=c
 set c=null
endfunction

//=============================================================================================================
// Left for compatibility
//
function DamageUnitTimedEx_Child takes nothing returns nothing
 local real damage = udg_castervars[0]
 local real damageperiod= udg_castervars[2]
 local effect fx=bj_lastCreatedEffect
 local timer t=CreateTimer()
 local integer id=udg_currentabi
 local real next=0
 local integer i=0
 local real c
 local unit target=udg_currentcaster
    call TimerStart(t, udg_castervars[1]-0.01, false,null)
    loop
        if TimerGetElapsed(t) >= next then
            exitwhen DamageUnit( Player(id), damage, target)
            set i=i+1
            set next=i*damageperiod
        endif
        exitwhen (TimerGetRemaining(t) <= 0) or IsUnitDeadBJ(target)
        call TriggerSleepAction(0)
    endloop
 call DestroyEffect(fx)
 call DestroyTimer(t)
 set t=null
 set fx=null
endfunction

function DamageUnitTimedEx takes player owner, real damageps, real damageperiod, real duration, unit target, string modelpath, string attachPointName returns nothing
 local unit c=udg_currentcaster
    set bj_lastCreatedEffect=AddSpecialEffectTarget( modelpath, target,attachPointName )
    set udg_currentcaster=target
    set udg_castervars[0]=damageps
    set udg_castervars[1]=duration
    set udg_castervars[2]=damageperiod
    set udg_currentabi=GetPlayerId( owner )
    call ExecuteFunc("DamageUnitTimedEx_Child")
    set udg_currentcaster=c
 set c=null
endfunction

function DamageUnitTimed takes player owner, real damageps, real duration, unit target, string modelpath, string attachPointName returns nothing
    call DamageUnitTimedEx(owner , damageps, 1, duration, target, modelpath, attachPointName )
endfunction

function SetDamageOptions_i takes gamecache g, integer n, integer DamageOptions returns nothing
 local string key="DOPT"+I2S(n)
 local integer d=DamageOptions
    call StoreInteger(g,key,"value",d)
	if (d>=8192) then
        set d=d-8192
	endif
	if (d>=4096) then
        set d=d-4096
	endif
	
    if d>=2048 then
        call StoreReal(g,key,"allf",udg_castervars[113])
        set d=d-2048
    endif
    if d>=1024 then
        call StoreInteger(g,key,"ign",R2I(udg_castervars[112]))
        set d=d-1024
    endif
    if d>=512 then
        call StoreInteger(g,key,"ab3",CS_LoadRawcodeFromReal(110))
        call StoreReal(g,key,"fc3",udg_castervars[111])
        set d=d-512
    endif
    if d>=256 then
        call StoreInteger(g,key,"ab2",CS_LoadRawcodeFromReal(108))
        call StoreReal(g,key,"fc2",udg_castervars[109])
        set d=d-256
    endif
    if d>=128 then
        call StoreInteger(g,key,"ab1",CS_LoadRawcodeFromReal(106))
        call StoreReal(g,key,"fc1",udg_castervars[107])
        set d=d-128
    endif
    if d >= 64 then
        set d=d-64
        call StoreInteger(g,key,"allied",R2I(udg_castervars[105]))
    endif
    if d >= 32 then
        set d=d-32
    endif
    if d >= 16 then
        set d=d-16
    endif
    if d >= 8 then
        set d=d-8
    endif
    if d >= 4 then
        call StoreInteger(g,key,"only",R2I(udg_castervars[104]))
        set d=d-4
    endif
    if d >= 2 then
        call StoreInteger(g,key,"excp",R2I(udg_castervars[102]))
        call StoreReal(g,key,"excf",udg_castervars[103])
        set d=d-2
    endif
    if d >= 1 then
        call StoreInteger(g,key,"attT",R2I(udg_castervars[100]))
        call StoreInteger(g,key,"dmgT",R2I(udg_castervars[101]))
    endif
endfunction

function SetDamageOptions takes integer id, integer DamageOptions returns nothing
    call SetDamageOptions_i(CSCache(),id,DamageOptions)
endfunction

function CreateDamageOptions takes integer DamageOptions returns integer
 local gamecache g=CSCache()
 local integer n=GetStoredInteger(g,"misc","DOPTn")+1
    call StoreInteger(g,"misc","DOPTn",n)
    call SetDamageOptions_i(g,n,DamageOptions)
 set g=null
 return n
endfunction

function DestroyDamageOptions takes integer id returns nothing
    call FlushStoredMission(CSCache(),"DOPT"+I2S(id))
endfunction

function LoadDamageOptions takes integer id returns integer
 local gamecache g=CSCache()
 local string key="DOPT"+I2S(id)
 local integer opt=GetStoredInteger(g,key,"value")
 local integer v=opt

    if v>=8192 then
	    set v=v-8192
	endif
    if v>=4096 then
	    set v=v-4096
	endif
    if v>=2048 then
        set udg_castervars[113]=GetStoredReal(g,key,"allf")
        set v=v-2028
    endif
    if v>=1024 then
        set udg_castervars[112]= GetStoredInteger(g,key,"ign")
        set v=v-1024
    endif
    if v>=512 then
        set udg_castervars[110]=CS_Rawcode2Real(GetStoredInteger(g,key,"ab3"))
        set udg_castervars[111]=GetStoredReal(g,key,"fc3")
        set v=v-512
    endif
    if v>=256 then
        set udg_castervars[108]=CS_Rawcode2Real(GetStoredInteger(g,key,"ab2"))
        set udg_castervars[109]=GetStoredReal(g,key,"fc2")
        set v=v-256
    endif
    if v>=128 then
        set udg_castervars[106]=CS_Rawcode2Real(GetStoredInteger(g,key,"ab1"))
        set udg_castervars[107]=GetStoredReal(g,key,"fc1")
        set v=v-128
    endif
    if v >= 64 then
        set v=v-64
        set udg_castervars[105]= GetStoredInteger(g,key,"allied")
    endif
    if v >= 32 then
        set v=v-32
    endif
    if v >= 16 then
        set v=v-16
    endif
    if v >= 8 then
        set v=v-8
    endif
    if v >= 4 then
        set udg_castervars[104]=GetStoredInteger(g,key,"only")
        set v=v-4
    endif
    if v >= 2 then
        set udg_castervars[102]=GetStoredInteger(g,key,"excp")
        set udg_castervars[103]=GetStoredReal(g,key,"excf")
        set v=v-2
    endif
    if v >= 1 then
        set udg_castervars[100]=GetStoredInteger(g,key,"attT")
        set udg_castervars[101]=GetStoredInteger(g,key,"dmgT")
    endif
 set g=null
 return opt
endfunction

//==================================================================================================
function IsDestructableTree_withcs takes destructable d returns boolean
 local unit c=GetACaster()
 local boolean b
 local boolean i=IsDestructableInvulnerable(d)
 local integer s=DamageTreeDetectorId()
    if i then
        call SetDestructableInvulnerable(d,false)
    endif
    call UnitAddAbility(c,s)
    call CS_MoveUnit(c,GetWidgetX(d),GetWidgetY(d))
    set b=(IssueTargetOrder(c,"eattree",d))
    call UnitRemoveAbility(c,s)
    call RecicleCaster(c)
    set c=null
    if i then
        call SetDestructableInvulnerable(d,true)
    endif
 return b 
endfunction

function IsDestructableTree takes destructable d returns boolean
 local gamecache g=CSCache()
 local string k=I2S(GetDestructableTypeId(d))
 local boolean b

    if HaveStoredBoolean(g,"trees",k) then
        set b=GetStoredBoolean(g,"trees",k)
        set g=null
        return b
    else
        set b=IsDestructableTree_withcs(d)
        call StoreBoolean(g,"trees",k,b)
    endif
 set g=null
 return b
endfunction

//===============================================================================================
function DamageDestructablesInCircleEnum takes nothing returns nothing
 local destructable d=GetEnumDestructable()
 local unit u=udg_currentcaster
    if (GetWidgetLife(d)>0) and not(IsDestructableInvulnerable(d)) and ((Pow(GetDestructableX(d)-udg_castervars[200],2)+Pow(GetDestructableY(d)-udg_castervars[201],2)) <= udg_castervars[202]) then
        call SetWidgetLife(d,GetWidgetLife(d)-udg_castervars[203])
    endif
 set udg_currentcaster=u
 set u=null
 set d=null
endfunction

function DamageDestructablesInCircle takes real x, real y, real radius, real dmg returns nothing
 local rect r=Rect(x - radius,y - radius,x + radius,y + radius)
    set udg_castervars[200]=x
    set udg_castervars[201]=y
    set udg_castervars[202]=radius*radius
    set udg_castervars[203]=dmg
    call EnumDestructablesInRect(r,null,function DamageDestructablesInCircleEnum)
 call RemoveRect(r)
 set r=null
endfunction

function DamageDestructablesInCircleLoc takes location loc, real radius, real dmg returns nothing
    call DamageDestructablesInCircle(GetLocationX(loc),GetLocationY(loc),radius,dmg)
endfunction

function DamageTreesInCircleEnum takes nothing returns nothing
 local destructable d=GetEnumDestructable()
    if (GetWidgetLife(d)>0) and not(IsDestructableInvulnerable(d)) and ((Pow(GetDestructableX(d)-udg_castervars[200],2)+Pow(GetDestructableY(d)-udg_castervars[201],2)) <= udg_castervars[202]) and (IsDestructableTree(d)) then
        call KillDestructable(d)
    endif
 set d=null
endfunction

function DamageTreesInCircle takes real x, real y, real radius returns nothing
 local rect r=Rect(x - radius,y - radius,x + radius,y + radius)
    set udg_castervars[200]=x
    set udg_castervars[201]=y
    set udg_castervars[202]=radius*radius
    call EnumDestructablesInRect(r,null,function DamageTreesInCircleEnum)
 call RemoveRect(r)
 set r=null
endfunction

function DamageTreesInCircleLoc takes location loc, real radius returns nothing
    call DamageTreesInCircle(GetLocationX(loc),GetLocationY(loc),radius)
endfunction

function DamageUnitGroupEx takes unit hurter, real damage, group targetgroup, integer DamageOptions returns nothing
 local group affected
 local unit p
    if bj_wantDestroyGroup then
        set bj_wantDestroyGroup=false
        set affected=targetgroup
    else
        set affected=CreateGroup()
        call GroupAddGroup( targetgroup, affected)
    endif
    loop
        set p=FirstOfGroup(affected)
        exitwhen p==null
        call DamageUnitByOptions(hurter,p,damage,DamageOptions)
        call GroupRemoveUnit(affected,p)
    endloop
 call DestroyGroup(affected)
 set affected=null
 set p=null
endfunction

function DamageUnitsInAOEEx takes unit hurter, real damage, real x, real y, real radius, boolean affectallied, integer DamageOptions returns nothing
 local boolexpr b=null
 local group aoe=CreateGroup()
 local integer d=DamageOptions
    set bj_groupEnumOwningPlayer=GetOwningPlayer(hurter)
    if d>=8192 then
        set d=d-8192
    endif
    if d>=4096 then
        set d=d-4096
    endif

    if d>=2048 then
        set d=d-2048
    endif
    if d>=1024 then
        set d=d-1024
    endif
    if d>=512 then
        set d=d-512
    endif
    if d>=256 then
        set d=d-256
    endif
    if d>=128 then
        set d=d-128
    endif
    if d>=64 then
        if     (udg_castervars[105]==2) then
            set b=Condition(function CasterAOE_IsFilterAlly)
        elseif (udg_castervars[105]==1) then
        else
            set b=Condition(function CasterAOE_IsFilterEnemy)
        endif
        set d=d-64
    elseif not(affectallied) then
        set b=Condition(function CasterAOE_IsFilterEnemy)
    endif
    if d>=32 then
        set d=d-32
    endif
    if d>=16 then
        call DamageTreesInCircle(x,y,radius)
    endif
    call CS_EnumUnitsInAOE(aoe, x,y, radius, b)
    set bj_wantDestroyGroup=true
    call DamageUnitGroupEx( hurter, damage, aoe,DamageOptions)
 call DestroyBoolExpr(b)
 set b=null
 set aoe=null
endfunction

function DamageUnitsInAOEExLoc takes unit hurter, real damage, location loc, real radius, boolean affectallied, integer DamageOptions returns nothing
    call DamageUnitsInAOEEx(hurter,damage, GetLocationX(loc), GetLocationY(loc), radius, affectallied,DamageOptions)
endfunction

function DamageUnitGroup takes player hurter, real damage, group targetgroup returns nothing
 local unit caster=GetACaster()
    call UnitRemoveAbility(caster,'Aloc') //Otherwise the units would flee like crazy
    call SetUnitOwner(caster,hurter,false)
    call DamageUnitGroupEx(caster,damage,targetgroup,0)
 call RecicleCaster(caster)
 set caster=null
endfunction

//====================================================================================================================================================================
function DamageUnitsInAOE takes player hurter, real damage, real x, real y, real radius, boolean affectallied returns nothing
 local unit caster=GetACaster()
    call UnitRemoveAbility(caster,'Aloc') //Otherwise the units would flee like crazy
    call SetUnitOwner(caster,hurter,false)
    call DamageUnitsInAOEEx(caster,damage,x,y,radius,affectallied,0)
 call RecicleCaster(caster)
 set caster=null
endfunction

function DamageUnitsInAOELoc takes player hurter, real damage, location loc, real radius, boolean affectallied returns nothing
    call DamageUnitsInAOE( hurter, damage, GetLocationX(loc), GetLocationY(loc), radius, affectallied)
endfunction

//====================================================================================================================================================================
function AddAreaDamagerForUnit_Child takes nothing returns nothing
 local real D
 local real damageps = udg_castervars[0]
 local real area = udg_castervars[2]
 local real damageperiod = udg_castervars[3]
 local real excd=udg_castervars[8]
 local boolean affectallies = (udg_castervars[4]>=1)
 local boolean onlyallies = (udg_castervars[4]==2)
 local boolean self = (udg_castervars[5]==1)
 local unit hurter=udg_currenthurter
 local unit fire = udg_currentcaster
 local player owner = GetOwningPlayer(fire)
 local timer t = CreateTimer()
 local real next = 0
 local integer a = 0
 local group inrange = CreateGroup()
 local string c
 local string art=bj_lastPlayedMusic
 local string attach=""
 local unit picked
 local boolean recicled=false
 local unittype only=null
 local unittype ign=null
 local unittype exce=null
 local attacktype attT
 local damagetype dmgT
 local boolean trees=(udg_castervars[11]==1)
 local boolean inv=(udg_castervars[12]==1)
 local integer a1=0
 local integer a2=0
 local integer a3=0
 local real f1=udg_castervars[107]
 local real f2=udg_castervars[109]
 local real f3=udg_castervars[111]
 local real allf=udg_castervars[113]
 local effect array fx
 local integer deadcond=R2I(udg_castervars[114])
 local boolean deadeval=false
 local integer fxn=0
    set fx[0]=bj_lastCreatedEffect

    if f1!=1 then
        set a1=CS_LoadRawcodeFromReal(106)
    endif
    if f2!=1 then
        set a2=CS_LoadRawcodeFromReal(108)
    endif
    if f3!=1 then
        set a3=CS_LoadRawcodeFromReal(110)
    endif
    if udg_castervars[112]!=-1 then
        set ign=ConvertUnitType(R2I(udg_castervars[112]))
    endif
    if udg_castervars[6]!=-1 then
        set only=ConvertUnitType(R2I(udg_castervars[6]))
    endif
    if udg_castervars[7]!=-1 then
        set exce=ConvertUnitType(R2I(udg_castervars[7]))    
    endif
    if udg_castervars[9]!=-1 then
        set attT=ConvertAttackType(R2I(udg_castervars[9]))
    else
        set attT=Caster_DefaultAttackType()
    endif
    if udg_castervars[10]!=-1 then
        set dmgT=ConvertDamageType(R2I(udg_castervars[10]))
    else
        set dmgT=Caster_DefaultDamageType()
    endif
    loop
        set c=SubString(art,a,a+1)
        exitwhen c=="!" or c==""
        set attach=attach+c
        set a=a+1
    endloop
    set art=SubString(art,a+1,10000)
    call TimerStart(t, udg_castervars[1]-0.01, false,null)
    set a=0
    loop
        loop
            exitwhen fxn<=0
            call DestroyEffect(fx[fxn])
            set fx[fxn]=null
            set fxn=fxn-1
        endloop
        if IsUnitInGroup( fire, udg_casters) then
            set recicled=true
            call GroupRemoveUnit( udg_casters,fire)
        endif
        exitwhen recicled
        if TimerGetElapsed(t) >= next then
            set a=a+1
            set next=a*damageperiod
            call CS_EnumUnitsInAOE(inrange, GetUnitX(fire), GetUnitY(fire), area, null )
            if trees then
                call DamageTreesInCircle(GetUnitX(fire), GetUnitY(fire), area)
            endif
            loop
                set picked=FirstOfGroup(inrange)
                exitwhen picked==null
				if (deadcond==0) then
				    set deadeval=(GetWidgetLife(picked)>0.405)
				elseif(deadcond==1)then
				    set deadeval=(GetWidgetLife(picked)<=0.405)
				else
				    set deadeval=true
				endif
                if (self or picked!=hurter) and not(IsUnitDeadBJ(picked)) and ( ((affectallies or onlyallies) and IsUnitAlly(picked, owner)) or (not(onlyallies) and IsUnitEnemy(picked, owner)) ) and (only==null or CS_IsUnitType(picked,only)) and (ign==null or not(CS_IsUnitType(picked,ign))) then
                    set D=damageps
                    if (allf!=1) and IsUnitAlly(picked, owner) then
                        set D=D*allf
                    endif
                    if (exce!=null) and CS_IsUnitType(picked,exce) then
                        set D=D*excd
                    endif
                    if inv and not(CS_IsUnitVisible(picked,owner)) then
                        set D=0
                    endif
                    if (a1!=0) and (GetUnitAbilityLevel(picked,a1)>0) then
                        set D=D*f1
                    endif
                    if (a2!=0) and (GetUnitAbilityLevel(picked,a2)>0) then
                        set D=D*f2
                    endif
                    if (a3!=0) and (GetUnitAbilityLevel(picked,a3)>0) then
                        set D=D*f3
                    endif
                    if D!=0 then
                        call DamageUnitByTypes(hurter,picked,D,attT,dmgT )
                        if (art!="") and (art!=null) then
                            set fxn=fxn+1
                            set fx[fxn]=AddSpecialEffectTarget(art,picked,attach)
                        endif
                    endif
                endif
                call GroupRemoveUnit(inrange,picked)
            endloop
        endif
        exitwhen TimerGetRemaining(t)<=0
        call TriggerSleepAction(0)
    endloop
 call DestroyGroup(inrange)
 call DestroyEffect(fx[0])
 call TriggerSleepAction(2)
 call RecicleCaster(fire)
 call DestroyTimer(t)
 set inrange=null
 set fire=null
 set t=null
 set owner=null
 set fx[0]=null
 set picked=null
 set hurter=null
 set only=null
 set ign=null
 set exce=null
 set attT=null
 set dmgT=null
endfunction

function AddAreaDamagerForUnit takes unit hurter, string modelpath, string targetart, string targetattach, real x, real y, real damage , real damageperiod, real duration, real area, boolean affectallies, integer DamageOptions returns unit
 local string s=bj_lastPlayedMusic
 local integer v=DamageOptions
    set bj_lastPlayedMusic=targetattach+"!"+targetart
    set udg_currentcaster=GetACaster()
    call SetUnitPosition( udg_currentcaster, x, y)
    set bj_lastCreatedEffect = AddSpecialEffectTarget( modelpath, udg_currentcaster,"origin" )
    set udg_castervars[0]=damage
    set udg_castervars[1]=duration
    set udg_castervars[2]=area
    set udg_castervars[3]=damageperiod
	
	if(v>=8192)then
	    set udg_castervars[114]=2
		set v=v-8192
	elseif (v>=4096)then
	    set udg_castervars[114]=1
		set v=v-4096
	else
	    set udg_castervars[114]=0
	endif

    if v>=2048 then
        set v=v-2048
    else
        set udg_castervars[113]=1
    endif
    if v >= 1024 then
        set v=v-1024
    else
        set udg_castervars[112]=-1
    endif
    if v >= 512 then
        set v=v-512
    else
        set udg_castervars[111]=0
    endif
    if v >= 256 then
        set v=v-256
    else
        set udg_castervars[109]=0
    endif
    if v >= 128 then
        set v=v-128
    else
        set udg_castervars[107]=0
    endif
    if v >= 64 then
        set v=v-64
        set udg_castervars[4]=udg_castervars[105]
    else
        set udg_castervars[4]=IntegerTertiaryOp(affectallies,1,0)
    endif
    if v >= 32 then
        set udg_castervars[12]=1
        set v=v-32
    else
        set udg_castervars[12]=0
    endif
    if v >= 16 then
        set udg_castervars[11]=1
        set v=v-16
    else
        set udg_castervars[11]=0
    endif
    if v >= 8 then
        set udg_castervars[5]=0
        set v=v-8
    else
        set udg_castervars[5]=1
    endif
    if v >= 4 then
        set udg_castervars[6]=udg_castervars[104]
        set v=v-4
    else
        set udg_castervars[6]=-1
    endif
    if v >= 2 then
        set udg_castervars[7]=udg_castervars[102]
        set udg_castervars[8]=damage*udg_castervars[103]
        set v=v-2
    else
        set udg_castervars[7]=-1
        set udg_castervars[8]=-1
    endif
    if v >= 1 then
        set udg_castervars[9]=udg_castervars[100]
        set udg_castervars[10]=udg_castervars[101]
    else
        set udg_castervars[9]=-1
        set udg_castervars[10]=-1
    endif
    set udg_currenthurter=hurter
    call SetUnitOwner( udg_currentcaster, GetOwningPlayer(hurter), true)
    call ExecuteFunc("AddAreaDamagerForUnit_Child")
    set bj_lastPlayedMusic=s
 return udg_currentcaster
endfunction

function AddAreaDamagerForUnitLoc takes unit hurter, string modelpath, string targetart, string targetattach, location loc, real damage , real damageperiod, real duration, real area, boolean affectallies, integer DamageOptions returns unit
 return AddAreaDamagerForUnit(hurter,modelpath,targetart,targetattach,GetLocationX(loc),GetLocationY(loc), damage , damageperiod, duration, area,affectallies, DamageOptions)
endfunction

function AddDamagingEffectEx takes player owner, string modelpath, string targetart, string targetattach, real x, real y, real damage , real damageperiod, real duration, real area, boolean affectallies returns unit
 local string s=bj_lastPlayedMusic
    set bj_lastPlayedMusic=targetattach+"!"+targetart
    set udg_currentcaster=GetACaster()
    call SetUnitPosition( udg_currentcaster, x, y)
    set bj_lastCreatedEffect = AddSpecialEffectTarget( modelpath, udg_currentcaster,"origin" )
    set udg_castervars[0]=damage
    set udg_castervars[1]=duration
    set udg_castervars[2]=area
    set udg_castervars[3]=damageperiod
    set udg_castervars[4]=IntegerTertiaryOp(affectallies,1,0)
    set udg_castervars[5]=1
    set udg_castervars[6]=-1
    set udg_castervars[7]=-1
    set udg_castervars[8]=-1
    set udg_castervars[9]=-1
    set udg_castervars[10]=-1
    set udg_castervars[107]=0
    set udg_castervars[109]=0
    set udg_castervars[111]=0
    set udg_castervars[112]=-1
    set udg_castervars[113]=1
    set udg_currenthurter=udg_currentcaster
    call SetUnitOwner( udg_currentcaster, owner, true)
    call ExecuteFunc("AddAreaDamagerForUnit_Child")
    set bj_lastPlayedMusic=s
 return udg_currentcaster
endfunction

function AddDamagingEffectExLoc takes player owner, string modelpath, string targetart, string targetattach, location loc, real damage , real damageperiod, real duration, real area, boolean affectallies returns unit
    return AddDamagingEffectEx( owner, modelpath, targetart, targetattach, GetLocationX(loc), GetLocationY(loc), damage , damageperiod, duration, area, affectallies )
endfunction

function AddDamagingEffect takes player owner, string modelpath, real x, real y, real damageps , real duration, real area, boolean affectallies returns unit
    return AddDamagingEffectEx( owner, modelpath, "", "", x, y, damageps , 1, duration, area, affectallies )
endfunction

function AddDamagingEffectLoc takes player owner, string modelpath, location loc, real damageps , real duration, real area, boolean affectallies returns unit
    return AddDamagingEffectEx( owner, modelpath, "", "", GetLocationX(loc), GetLocationY(loc), damageps ,1, duration, area, affectallies)
endfunction

//============================================================================================================
function UnitMoveToAsProjectileAnySpeed_Target takes gamecache H, string a, string b returns unit
    return GetStoredInteger(H,a,b)
    return null
endfunction

function UnitMoveToAsProjectileAnySpeed_Move takes gamecache H, unit m, string k returns boolean
 local boolean tounit = GetStoredBoolean(H,k,"unit")
 local unit tg
 local real x2
 local real y2
 local real z2
 local real x1=GetUnitX(m)
 local real y1=GetUnitY(m)
 local real z1=GetUnitFlyHeight(m)
 local real g
 local real d
 local real od
 local real v
 local real time
 local integer n
 local boolean done=false
    if tounit then
        set tg=UnitMoveToAsProjectileAnySpeed_Target(H,k,"tg")
        if (GetWidgetLife(tg)<=0.405) then
            set tounit=false
            call StoreBoolean(H,k,"unit",false)
        else
            set x2=GetUnitX(tg)
            set y2=GetUnitY(tg)
            set z2=GetUnitFlyHeight(tg)+GetStoredReal(H,k,"z2o")
            set n=GetStoredInteger(H,k,"N")
            set n=n+1
            if (n==0) then
                //I have the tilt writing on gamecache is slower than reading, in that case I prevent writting
                // these 3 reals, but use a counter so each second they are backuped.
                // They are needed because if the unit dies or is removed, they would otherwise go to the
                // center of the map, and that is not something nice.
                call StoreReal(H,k,"z2",z2)
                call StoreReal(H,k,"x2",x2) // Backup stuff just in case
                call StoreReal(H,k,"y2",y2)
            elseif (n==25) then
                set n=0
            endif
            call StoreInteger(H,k,"N",n)
        endif
        set tg=null
    endif
    if not(tounit) then
        set z2=GetStoredReal(H,k,"z2")
        set x2=GetStoredReal(H,k,"x2")
        set y2=GetStoredReal(H,k,"y2")
    endif

    set g=Atan2(y2-y1,x2-x1)
    call SetUnitFacing(m,g*bj_RADTODEG)
    set v=GetStoredReal(H,k,"speed")
    set d= v * CS_Cycle()
    
    set od=SquareRoot(Pow(x1-x2,2) +  Pow(y1-y2,2))
    if( od  <=d )then
        call CS_MoveUnit(m , x2, y2 )
        set done=true
    else
        call CS_MoveUnit(m , x1+d*Cos(g), y1+d*Sin(g) )
    endif
    set g=GetStoredReal(H,k,"acel")
    set time= od / v
    set v=(z2-z1+0.5*g*time*time)/time //z speed
    call SetUnitFlyHeight(m,z1+v*CS_Cycle(),0)
    set d=( Pow(GetUnitX(m)-x2,2) + Pow(GetUnitY(m)-y2,2) )
    if (done or (d<=400)) then //So the actual distance is less than or equal to 20
        set done=true
        call StoreBoolean(H,k,"done",true)
    endif
 return done
endfunction



function CollisionMissile_Destroyer takes gamecache H, unit m, string k, trigger T returns nothing
    call TriggerExecute(T)
    call DestroyEffect(GetTableEffect(k,"fx"))
    call FlushStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m))
    call FlushStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(T))
    if GetTableBoolean(k,"new") then
        call ExplodeUnitBJ(m)
    else
        call RecicleCasterAfterCastEx(m,4,0,true)
    endif
    call DestroyTable(k)
    call TriggerRemoveAction(T,GetTableTriggerAction(k,"ac"))
    call CleanAttachedVars(T)
    call DestroyTrigger(T)
endfunction

function GetTriggerCollisionMissile takes nothing returns unit
    return GetStoredInteger( CSCache(), GetAttachmentTable(GetTriggeringTrigger()), "m" )
    return null
endfunction

function CollisionMissile_Move takes gamecache g, unit m,  string k returns boolean

 local boolean done=GetStoredBoolean(g,k,"dest")
 local real d
 local real F
 local real asp
 local real x
 local real nx
 local real y
 local real ny
 local integer tt
 local widget wd

    if not(done) then
        if not(GetStoredBoolean(g,k,"doneReg")) then
            call TriggerRegisterUnitInRange(GetTableTrigger(k,"T"),m,GetStoredReal(g,k,"collision"),null)
            call StoreBoolean(g,k,"doneReg",true)
        endif
        set d=GetStoredReal(g,k,"speed") * CS_Cycle()
        set F=GetStoredReal(g,k,"F")
        set asp=GetStoredReal(g,k,"aspeed")
        set x=GetUnitX(m)
        set y=GetUnitY(m)
        if (asp!=0) then
            set tt=GetStoredInteger(g,k,"TType")
            if (tt==1) or (tt==2) then
                if (tt==1) then
                    set nx=GetStoredReal(g,k,"Tx")
                    set ny=GetStoredReal(g,k,"Ty")
                else 
                    set wd=GetTableWidget(k,"Tw")
                    if (GetWidgetLife(wd)<=0.405) then
                        call StoreInteger(g,k,"TType",0)
                        set nx=x+0.001
                        set ny=y+0.001
                    else
                        set nx=GetWidgetX(wd)
                        set ny=GetWidgetY(wd)
                    endif
                   set wd=null
                endif
                set F=Angles_MoveAngleTowardsAngle(F,Atan2BJ(ny-y,nx-x), asp * CS_Cycle())
            else
                set F=F+ asp * CS_Cycle()
            endif
            call StoreReal(g,k,"F",F)
            call SetUnitFacing(m,F)
        endif
        set F=F*bj_DEGTORAD
        set nx=x+d*Cos(F)
        set ny=y+d*Sin(F)
        set d=GetStoredReal(g,k,"maxd")-d
        call StoreReal(g,k,"maxd",d)
        set done=(d<=0)
        if not(CS_MoveUnit(m,nx,ny)) then
            call SetUnitX(m,x)
            call SetUnitY(m,y)
            set done=true
        elseif (GetStoredBoolean(g,k,"pfx")) then
            set F=GetStoredReal(g,k,"pfx_current")+CS_Cycle()
            if (F>=GetStoredReal(g,k,"pfx_dur")) then
                call DestroyEffect(AddSpecialEffectTarget(GetStoredString(g,k,"pfx_path"), m, "origin"  ))
                call StoreReal(g,k,"pfx_current",0)
            else
                call StoreReal(g,k,"pfx_current",F)
            endif
        endif
    endif
    if done then

        call CollisionMissile_Destroyer(g,m,k,GetTableTrigger(k,"T"))
    endif
 set g=null
 return done
endfunction


function CasterSystemMovementTimer takes nothing returns nothing
 local timer t=GetExpiredTimer()
 local group g=GetTableGroup("CasterSystem","MOVEMENT_GROUP")
 local group x=CreateGroup()
 local unit p

 local string k
 local gamecache H=CSCache()

    call GroupAddUnit(g,null) //Sometimes removed / exploded units may be in a group, and FirstOfGroup wouldn't
                              //return null but a invalid pointer
    loop
        set p=FirstOfGroup(g)
        exitwhen (p==null)
        call GroupRemoveUnit(g,p)
        set k=I2S(GetStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(p)) )
        if (k!=null) and (k!="") then
            if GetStoredBoolean(H,k,"IsCollisionMissile") then

                if not(CollisionMissile_Move(H,p,k)) then

                    call GroupAddUnit(x,p)
                endif           
            elseif GetStoredBoolean(H,k,"IsProjectile") then
                if not(UnitMoveToAsProjectileAnySpeed_Move(H,p,k )) then
                    call GroupAddUnit(x,p)
                endif
            else

            endif
        else
            call BJDebugMsg("Caster System: Unexpected Error (2)")
        endif
    endloop

    if (FirstOfGroup(x)==null) then
        call SetTableObject("CasterSystem","MOVEMENT_TIMER",null)
        call SetTableObject("CasterSystem","MOVEMENT_GROUP",null)
        call CleanAttachedVars(t)
        call DestroyTimer(t)
        call DestroyGroup(x)
    else
        call SetTableObject("CasterSystem","MOVEMENT_GROUP",x)
    endif
    call DestroyGroup(g)

 set p=null
 set x=null
 set g=null
 set t=null
 set H=null
endfunction

function UnitMoveToAsProjectileAnySpeed takes unit m, real speed, real arc, real x2, real y2, unit target, real z2 returns nothing
//
//   The internal projectile system used by all the projectile functions
//
 local timer t //=GetTableTimer("CasterSystem","MOVEMENT_TIMER")
 local gamecache H=CSCache()
 local string k
 local string km
 local integer ki
 local group g



    if (HaveStoredInteger(H,"CasterSystem","MOVEMENT_TIMER")) then
        set g=GetTableGroup("CasterSystem","MOVEMENT_GROUP")
    else
        set t=CreateTimer()
        set g=CreateGroup()
        call SetTableObject("CasterSystem","MOVEMENT_GROUP",g)
        call SetTableObject("CasterSystem","MOVEMENT_TIMER",t)
        call TimerStart(t,CS_Cycle(),true,function CasterSystemMovementTimer)
       set t=null
    endif
    set km=GetAttachmentTable(m)
    set k=I2S(GetTableInt("MOVEMENT_TABLES",km))
    if (k!=null) and (k!="") then
        call SetTableBoolean(k,"done",true)
    endif
    set ki=NewTableIndex()
    set k=I2S(ki)
    call SetTableInt("MOVEMENT_TABLES",km,ki)
    call GroupAddUnit(g,m)
    call StoreBoolean(H,k,"IsProjectile",true)
    if (target!=null) then
        call StoreBoolean(H,k,"unit",true)
        call StoreInteger(H,k,"tg",CS_H2I(target) )
        call StoreReal(H,k,"x2",GetUnitX(target))
        call StoreReal(H,k,"y2",GetUnitY(target))
        call StoreReal(H,k,"z2o",z2)
    else
        call StoreReal(H,k,"x2",x2)
        call StoreReal(H,k,"y2",y2)
    endif
    call StoreReal(H,k,"z2",z2)
    call StoreReal(H,k,"speed",speed)
    call StoreReal(H,k,"acel",arc*8000)
    loop
        exitwhen GetStoredBoolean(H,k,"done")
        call TriggerSleepAction(0)
    endloop
    call SetTableInt("MOVEMENT_TABLES",km,0)
 set H=null

 set g=null
endfunction



//========================================================================================================================
function UnitMoveToAsProjectileGen takes unit m, real arc, real x2, real y2, unit target, real z2 returns nothing
//
//   The internal projectile system used by all the projectile functions
//
 local real x1=GetUnitX(m)
 local real y1=GetUnitY(m)
 local real acel=arc*1600
 local real speed=GetUnitMoveSpeed(m) 
 local real z1=GetUnitFlyHeight(m)
 local real d
 local real d1
 local real d2
 local real t
 local real vel
 local real dif=0
 local boolean tounit= (target!=null)
 local boolean b=false
 local boolean mode=false
    if tounit then
        set x2=GetUnitX(target)
        set y2=GetUnitY(target)
        set z2=GetUnitFlyHeight(target)+z2
    endif
    set mode=(z2>z1)
    set d=SquareRoot(Pow(x2-x1,2)+Pow(y2-y1,2))
    set d1=1000000
    set d2=0
    set t=d/speed
    if t==0 then
        set t=0.001
    endif
    set vel=(z2-z1+0.5*acel*t*t)/t
    call SetUnitFacing( m, Atan2BJ(y2 - y1, x2 - x2) )
    call IssuePointOrder( m, "move", x2,y2)
    set t=0
    loop
        set d2=d1
        if tounit then
            if IsUnitDeadBJ(target) then
                set tounit=false
            else
                set x2=GetUnitX(target)
                set y2=GetUnitY(target)
            endif
        endif
        set d1=SquareRoot(Pow(x2-GetUnitX(m),2)+Pow(y2-GetUnitY(m),2))
        exitwhen b or d1==0
        set b=(d1<=speed*(t-dif))
        exitwhen (mode and b) or (GetUnitCurrentOrder(m) != OrderId("move"))
        if tounit then
            call IssuePointOrder( m, "move", x2,y2)
        endif
        set dif=t
        if dif==0.001 then
           set t=0.1
        else
            set t= (d-d1)/speed
        endif
        set t= 2*t-dif
        call SetUnitFlyHeight( m, z1+(vel*t-0.5*acel*t*t), RAbsBJ( vel-acel*(t+dif)/2) )
        set t=(t+dif)/2
        call TriggerSleepAction(0)
    endloop
    if tounit then
        set x2=GetUnitX(target)
        set y2=GetUnitY(target)
    endif
    call SetUnitFlyHeight( m,z2,0)
    call CS_MoveUnit(m,x2,y2)
endfunction

function UnitMoveToAsProjectile takes unit m, real arc, real x2, real y2, real z2 returns nothing
    call UnitMoveToAsProjectileGen(m, arc,x2,y2,null,z2)
endfunction

//============================================================================================================
function ProjectileLaunchEx takes player owner, string modelpath, real scale, integer red, integer green, integer blue, integer alpha, real speed, real arc,real x1, real y1, real z1, real x2, real y2, real z2 returns nothing
 local unit m=AddCasterFacing( Atan2BJ(y2 - y1, x2 - x1) )
 local effect fx=null
    call SetUnitPosition( m, x1,y1)
    call SetUnitScale( m, scale, scale, scale)
    call SetUnitVertexColor(m, red, green, blue, alpha)

    call SetUnitFlyHeight( m, z1, 0)
    set fx= AddSpecialEffectTarget( modelpath, m,"origin" )
    call SetUnitOwner( m, owner, true)

    if (speed<=522) then
        call SetUnitMoveSpeed(m, speed)
        call UnitMoveToAsProjectile(m, arc, x2, y2, z2)
    else
        call UnitMoveToAsProjectileAnySpeed(m,speed,arc,x2,y2,null,z2)
    endif
    call DestroyEffect(fx)
    call ExplodeUnitBJ(m)
 set owner=null
 set fx=null
 set m=null
endfunction

function ProjectileLaunchExLoc takes player owner, string modelpath, real scale, integer red, integer green, integer blue, integer alpha, real speed, real arc, location loc1, real z1, location loc2, real z2 returns nothing
    call ProjectileLaunchEx( owner, modelpath, scale, red, green, blue, alpha, speed, arc,GetLocationX(loc1), GetLocationY(loc1), z1, GetLocationX(loc2), GetLocationY(loc2), z2)
endfunction

//============================================================================================================
function ProjectileLaunch takes string modelpath, real speed, real arc,real x1, real y1, real z1, real x2, real y2, real z2 returns nothing
    call ProjectileLaunchEx( Player(15), modelpath, 1, 255, 255, 255, 255, speed, arc,x1,y1,z1,x2,y2,z2)
endfunction

function ProjectileLaunchLoc takes string modelpath, real speed, real arc, location loc1, real z1, location loc2, real z2 returns nothing
    call ProjectileLaunchExLoc( Player(15), modelpath, 1,255,255,255,255,speed,arc,loc1,z1,loc2,z2)
endfunction

//============================================================================================================
function DamagingProjectileLaunchAOE_Child takes nothing returns nothing
 local unit m=udg_currentcaster
 local effect fx=bj_lastCreatedEffect
 local real x2=udg_castervars[0]
 local real y2=udg_castervars[1]
 local real aoeradius=udg_castervars[3]
 local real damage=udg_castervars[4]
 local boolean affectallied=bj_isUnitGroupInRectResult
 local integer V=CreateDamageOptions(R2I(udg_castervars[5]))
 local unit hurter=udg_currenthurter
 local real speed=udg_castervars[6]
    if (speed<=522) then
        call SetUnitMoveSpeed(m, speed)
        call UnitMoveToAsProjectile(m, bj_meleeNearestMineDist, udg_castervars[0], udg_castervars[1], udg_castervars[2])
    else
        call UnitMoveToAsProjectileAnySpeed(m,speed,bj_meleeNearestMineDist, udg_castervars[0], udg_castervars[1],null, udg_castervars[2])
    endif
    call DestroyEffect(fx)
    call DamageUnitsInAOEEx(hurter,damage,x2,y2,aoeradius,affectallied,LoadDamageOptions(V))
    call DestroyDamageOptions(V)
    call ExplodeUnitBJ(m)
 set m=null
 set fx=null
endfunction

function DamagingProjectileLaunchAOE takes unit hurter, string modelpath, real speed, real arc, real x1, real y1, real z1, real x2, real y2, real z2, real aoeradius, real damage, boolean affectallied, integer DamageOptions returns unit
 local unit m=AddCasterFacing( Atan2BJ(y2 - y1, x2 - x1) )
    call SetUnitPosition(m, x1,y1)
    call SetUnitFlyHeight( m, z1, 0)
    set udg_currentcaster=m
    set bj_lastCreatedEffect=AddSpecialEffectTarget( modelpath, m,"origin" )
    call SetUnitOwner( m, GetOwningPlayer(hurter), true)
    set bj_meleeNearestMineDist = arc
    set udg_castervars[0] = x2
    set udg_castervars[1] = y2
    set udg_castervars[2] = z2
    set udg_castervars[3] =aoeradius
    set udg_castervars[4] =damage
    set udg_castervars[5] =DamageOptions
    set udg_castervars[6] =speed
    set udg_currenthurter=hurter
    call ExecuteFunc("DamagingProjectileLaunchAOE_Child")
 set m=null
 return udg_currentcaster
endfunction

function DamagingProjectileLaunchAOELoc takes unit hurter, string modelpath, real speed, real arc, location loc1, real z1, location loc2, real z2, real aoeradius, real damage, boolean affectallied, integer DamageOptions returns unit
    return DamagingProjectileLaunchAOE(hurter,modelpath,speed,arc,GetLocationX(loc1),GetLocationY(loc1),z1,GetLocationX(loc2),GetLocationY(loc2),z2, aoeradius, damage, affectallied, DamageOptions )
endfunction

function ProjectileLaunchDamage takes player owner, string modelpath, real speed, real arc, real x1, real y1, real z1, real x2, real y2, real z2, real aoeradius, real damage, boolean affectallied returns unit
 local unit m=AddCasterFacing( Atan2BJ(y2 - y1, x2 - x1) )
    call SetUnitPosition(m, x1,y1)
    call SetUnitFlyHeight( m, z1, 0)
    set udg_currentcaster=m
    set bj_lastCreatedEffect=AddSpecialEffectTarget( modelpath, m,"origin" )
    call SetUnitOwner( m, owner, true)
    set bj_meleeNearestMineDist = arc
    set udg_castervars[0] = x2
    set udg_castervars[1] = y2
    set udg_castervars[2] = z2
    set udg_castervars[3] =aoeradius
    set udg_castervars[4] =damage
    set udg_castervars[5] =0
    set udg_castervars[6]= speed

    set bj_isUnitGroupInRectResult=affectallied
    set udg_currenthurter=m
    call ExecuteFunc("DamagingProjectileLaunchAOE_Child")
 set m=null
 return udg_currentcaster
endfunction

function ProjectileLaunchDamageLoc takes player owner, string modelpath, real speed, real arc, location loc1, real z1, location loc2, real z2, real aoeradius, real damage, boolean affectallied returns unit
    return ProjectileLaunchDamage( owner, modelpath, speed, arc, GetLocationX(loc1), GetLocationY(loc1), z1, GetLocationX(loc2), GetLocationY(loc2), z2, aoeradius, damage, affectallied) 
endfunction

//============================================================================================================
function ProjectileLaunchKill_Child takes nothing returns nothing
 local unit m=udg_currentcaster
 local effect fx=bj_lastCreatedEffect
 local real x2=udg_castervars[0]
 local real y2=udg_castervars[1]
 local real speed=udg_castervars[3]

    if (speed<=522) then
        call SetUnitMoveSpeed( m, speed)
        call UnitMoveToAsProjectile(m, bj_meleeNearestMineDist, udg_castervars[0], udg_castervars[1], udg_castervars[2])
    else
        call UnitMoveToAsProjectileAnySpeed(m,speed, bj_meleeNearestMineDist, udg_castervars[0], udg_castervars[1], null, udg_castervars[2])
    endif

    call ExplodeUnitBJ(m)
    call DestroyEffect( fx)
 set m=null
 set fx=null
endfunction

function ProjectileLaunchKill takes player owner, string modelpath, real speed, real arc, real x1, real y1, real z1, real x2, real y2, real z2 returns unit
 local unit m=AddCasterFacing( Atan2BJ(y2 - y1, x2 - x1) )
    call SetUnitPosition(m, x1,y1)

    call SetUnitFlyHeight( m, z1, 0)
    set udg_currentcaster=m
    set bj_lastCreatedEffect=AddSpecialEffectTarget( modelpath, m,"origin" )
    call SetUnitOwner( m, owner, true)
    set bj_meleeNearestMineDist = arc
    set udg_castervars[0] = x2
    set udg_castervars[1] = y2
    set udg_castervars[2] = z2
    set udg_castervars[3] = speed
    call ExecuteFunc("ProjectileLaunchKill_Child")
 set m=null
 return udg_currentcaster
endfunction

function ProjectileLaunchKillLoc takes player owner, string modelpath, real speed, real arc, location loc1, real z1, location loc2, real z2 returns unit
    return ProjectileLaunchKill( owner, modelpath, speed, arc, GetLocationX(loc1), GetLocationY(loc1), z1, GetLocationX(loc2), GetLocationY(loc2), z2)
endfunction

//====================================================================================================================================================================
function UnitMoveToUnitAsProjectile takes unit m, real arc, unit target, real zoffset returns nothing
    call UnitMoveToAsProjectileGen(m, arc,0,0,target,zoffset)
endfunction

//====================================================================================================================================================================
function ProjectileLaunchToUnitEx takes player owner, string modelpath, real scale, integer red, integer green, integer blue, integer alpha, real speed, real arc, real x1, real y1, real z1, unit target, real zoffset returns nothing
 local unit m=AddCasterFacing( Atan2BJ(GetUnitY(target) - y1, GetUnitX(target) - x1) )
 local effect fx=null
    call SetUnitPosition( m, x1,y1)
    call SetUnitFlyHeight( m, z1, 0)
    call SetUnitScale( m, scale, scale, scale)
    call SetUnitVertexColor(m, red, green, blue, alpha)
    set fx=AddSpecialEffectTarget( modelpath, m,"origin" )
    call SetUnitOwner( m , owner, true)

    if (speed<=522) then
        call SetUnitMoveSpeed( m, speed)
        call UnitMoveToUnitAsProjectile(m,arc,target, zoffset)
    else
        call UnitMoveToAsProjectileAnySpeed(m,speed, arc,0,0,target,zoffset)
    endif
    call DestroyEffect(fx)
    call ExplodeUnitBJ(m)
 set m=null
 set fx=null
endfunction

function ProjectileLaunchToUnitExLoc takes player owner, string modelpath, real scale, integer red, integer green, integer blue, integer alpha, real speed, real arc, location loc1, real z1, unit target, real zoffset returns nothing
    call ProjectileLaunchToUnitEx( owner, modelpath, scale, red, green, blue, alpha, speed, arc, GetLocationX(loc1),GetLocationY(loc1), z1, target, zoffset)
endfunction

function ProjectileLaunchToUnit takes string modelpath, real speed, real arc,real x1, real y1, real z1, unit target, real zoffset returns nothing
    call ProjectileLaunchToUnitEx( Player(15), modelpath, 1, 255,255,255,255,speed,arc,x1,y1,z1,target,zoffset)
endfunction

function ProjectileLaunchToUnitLoc takes string modelpath, real speed, real arc, location loc1, real z1, unit target, real zoffset returns nothing
    call ProjectileLaunchToUnitExLoc( Player(15), modelpath, 1, 255,255,255,255, speed, arc, loc1, z1, target,zoffset)
endfunction

//====================================================================================================================================================================
function DamagingProjectileLaunchTarget_Child takes nothing returns nothing
 local unit m=udg_currentcaster
 local unit target=bj_meleeNearestMine
 local effect fx=bj_lastCreatedEffect
 local real damage=udg_castervars[4]
 local damagetype dmgT=ConvertDamageType(R2I(udg_castervars[6]))
 local attacktype attT=ConvertAttackType(R2I(udg_castervars[5]))
 local unit hurter=udg_currenthurter
 local real speed=udg_castervars[7]
    if (speed<=522) then
        call SetUnitMoveSpeed( m, speed)
        call UnitMoveToUnitAsProjectile(m, bj_meleeNearestMineDist, target, udg_castervars[2])
    else
        call UnitMoveToAsProjectileAnySpeed(m,speed, bj_meleeNearestMineDist,0,0,target,udg_castervars[2])
    endif
    call DestroyEffect( fx)
    call DamageUnitByTypes(hurter,target,damage,attT,dmgT)
    call ExplodeUnitBJ(m)
 set m=null
 set hurter=null
 set target=null
 set fx=null
 set dmgT=null
 set attT=null
endfunction

function DamagingProjectileLaunchTarget takes unit hurter, string modelpath, real speed, real arc, real x1, real y1, real z1, unit target, real zoffset, real damage, attacktype attT, damagetype dmgT returns unit
 local unit m=AddCasterFacing( Atan2BJ(GetUnitY(target) - y1, GetUnitX(target) - x1) )
    call SetUnitPosition(m, x1,y1)
    set udg_castervars[7]=speed
    call SetUnitFlyHeight( m, z1, 0)
    set udg_currentcaster=m
    set bj_lastCreatedEffect=AddSpecialEffectTarget( modelpath, m,"origin" )
    call SetUnitOwner( m, GetOwningPlayer(hurter), true)
    set bj_meleeNearestMineDist = arc
    set udg_castervars[2]= zoffset
    set bj_meleeNearestMine=target
    set udg_castervars[4]=damage
    set udg_castervars[5]=CS_H2I(attT)
    set udg_castervars[6]=CS_H2I(dmgT)
    set udg_currenthurter=hurter
    call ExecuteFunc("DamagingProjectileLaunchTarget_Child")
 set m=null
 return udg_currentcaster
endfunction

function DamagingProjectileLaunchTargetLoc takes unit hurter, string modelpath, real speed, real arc, location loc, real z1, unit target, real zoffset, real damage, attacktype attT, damagetype dmgT returns unit
    return DamagingProjectileLaunchTarget(hurter,modelpath,speed,arc,GetLocationX(loc),GetLocationY(loc), z1, target, zoffset, damage, attT, dmgT)
endfunction

function ProjectileLaunchToUnitDamage takes player owner, string modelpath, real speed, real arc, real x1, real y1, real z1, unit target, real zoffset, real damage returns unit
 local unit m=AddCasterFacing( Atan2BJ(GetUnitY(target) - y1, GetUnitX(target) - x1) )
    call SetUnitPosition(m, x1,y1)
    set udg_castervars[7]=speed
    call SetUnitFlyHeight( m, z1, 0)
    set udg_currentcaster=m
    set bj_lastCreatedEffect=AddSpecialEffectTarget( modelpath, m,"origin" )
    call SetUnitOwner( m, owner, true)
    set bj_meleeNearestMineDist = arc
    set udg_castervars[2]= zoffset
    set bj_meleeNearestMine=target
    set udg_castervars[4]=damage
    set udg_castervars[5]=CS_H2I(Caster_DefaultAttackType())
    set udg_castervars[6]=CS_H2I(Caster_DefaultDamageType())
    set udg_currenthurter=m
    call ExecuteFunc("DamagingProjectileLaunchTarget_Child")
 set m=null
 return udg_currentcaster
endfunction

function ProjectileLaunchToUnitDamageLoc takes player owner, string modelpath, real speed, real arc, location loc1, real z1, unit target, real zoffset, real damage returns unit
    return ProjectileLaunchToUnitDamage( owner, modelpath, speed, arc,GetLocationX(loc1),GetLocationY(loc1),z1,target,zoffset,damage)
endfunction

//==============================================================================================================================================================================
// Caster System Class: CollisionMissile
//
function CollisionMissile_Destroy takes unit m returns nothing
 local gamecache H=CSCache()
 local string k=I2S(GetStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m)))
 local trigger T=GetTableTrigger(k,"T")
    if (T==GetTriggeringTrigger()) or (GetTriggerUnit()!=null) then
        call SetTableBoolean(k,"dest",true)
    else
        call GroupRemoveUnit( GetTableGroup("CasterSystem","MOVEMENT_GROUP"),m )
        call CollisionMissile_Destroyer(H,m,k,T)
    endif
 set T=null
 set H=null
endfunction

function CollisionMissile_Create takes string MissileModelPath, real x, real y, real dirangle, real speed, real AngleSpeed, real MaxDist,  real height, boolean UseNewCaster, real Collision, code OnImpact returns unit
 local timer t
 local gamecache H=CSCache()
 local string k
 local integer ki
 local trigger R
 local group g
 local unit m

    if (HaveStoredInteger(H,"CasterSystem","MOVEMENT_TIMER")) then
        set g=GetTableGroup("CasterSystem","MOVEMENT_GROUP")
    else
        set t=CreateTimer()
        set g=CreateGroup()
        call SetTableObject("CasterSystem","MOVEMENT_TIMER",t)
        call SetTableObject("CasterSystem","MOVEMENT_GROUP",g)
        call TimerStart(t,CS_Cycle(),true,function CasterSystemMovementTimer)
    endif
    set ki=NewTableIndex()
    set k=I2S(ki)



    if UseNewCaster then
        set m=AddCasterFacing(dirangle)
        call StoreBoolean(H,k,"new",true)
    else
        set m=GetACaster()
        call SetUnitFacing(m,dirangle)
    endif
    call StoreInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m),ki)
    call StoreBoolean(H,k,"IsCollisionMissile",true)

    call SetUnitPosition(m,x,y)
    call StoreReal(H,k,"speed",speed)
    call StoreReal(H,k,"aspeed",AngleSpeed)
    call StoreReal(H,k,"F",dirangle)
    call StoreReal(H,k,"maxd",MaxDist)
    call SetUnitFlyHeight(m,height,0)



    call GroupAddUnit(g,m)

    set R=CreateTrigger()
    call AttachObject(R,"m",m)
    call StoreReal(H,k,"collision",Collision)
    call SetTableObject(k,"T",R)
    call StoreInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(R),ki)
    call SetTableObject(k,"fx", AddSpecialEffectTarget(MissileModelPath,m,"origin") )
    call SetTableObject(k,"m",m)
    call SetTableObject(k,"ac",TriggerAddAction(R,OnImpact))

 set t=null
 set g=null
 set R=null
 set udg_currentcaster=m
 set m=null
 set H=null
 return udg_currentcaster
endfunction

function CollisionMissile_CreateLoc takes string MissileModelPath, location loc, real dirangle, real speed, real AngleSpeed, real MaxDist,  real height, boolean UseNewCaster, real Collision, code OnImpact returns unit
    return CollisionMissile_Create(MissileModelPath,GetLocationX(loc),GetLocationY(loc),dirangle,speed,AngleSpeed,MaxDist,height,UseNewCaster,Collision,OnImpact)
endfunction

//=========================================================================================================================================================
function CollisionMissile_SetAngleSpeed takes unit m, real newAspeed returns nothing
 local gamecache H=CSCache()
 local string k=I2S( GetStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m)) )
    call StoreReal(H,k,"aspeed",newAspeed    )
 set H=null
endfunction

//=========================================================================================================================================================
function CollisionMissile_SetSpeed takes unit m, real newspeed returns nothing
 local gamecache H=CSCache()
 local string k=I2S( GetStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m)) )
    call StoreReal(H,k,"speed",newspeed    )
 set H=null
endfunction

//=========================================================================================================================================================
function CollisionMissile_SetTargetPoint takes unit m, real tx, real ty returns nothing
 local gamecache H=CSCache()
 local string k=I2S( GetStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m)) )
    call StoreReal(H,k,"Tx",tx    )
    call StoreReal(H,k,"Ty",ty    )
    call StoreInteger(H,k,"TType",1)
 set H=null
endfunction
function CollisionMissile_SetTargetPointLoc takes unit m, location tloc returns nothing
    call CollisionMissile_SetTargetPoint(m,GetLocationX(tloc),GetLocationY(tloc))
endfunction

//=========================================================================================================================================================
function CollisionMissile_SetTarget takes unit m, widget Target returns nothing
 local gamecache H=CSCache()
 local string k=I2S( GetStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m)) )
    call SetTableObject(k,"Tw",Target)
    call StoreInteger(H,k,"TType",2)
 set H=null
endfunction

//=========================================================================================================================================================
function CollisionMissile_ForgetTarget takes unit m returns nothing
 local gamecache H=CSCache()
 local string k=I2S( GetStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m)) )
    call StoreInteger(H,k,"TType",0)
 set H=null
endfunction

//=========================================================================================================================================================
function CollisionMissile_SetDirAngle takes unit m, real f returns nothing
 local gamecache H=CSCache()
 local string k=I2S( GetStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m)) )
    call StoreReal(H,k,"F",f)
    call SetUnitFacing(m,f)
 set H=null
endfunction

//=========================================================================================================================================================
function CollisionMissile_ResetMaxDist takes unit m, real maxdist returns nothing
 local gamecache H=CSCache()
 local string k=I2S( GetStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m)) )
    call StoreReal(H,k,"maxd",maxdist)
 set H=null
endfunction

//=========================================================================================================================================================
function CollisionMissile_PeriodicFX takes unit m, string fx, real dur returns nothing
 local gamecache H=CSCache()
 local string k=I2S( GetStoredInteger(H,"MOVEMENT_TABLES",GetAttachmentTable(m)) )
    call StoreBoolean(H,k,"pfx",true)
    call StoreString(H,k,"pfx_path",fx)
    call StoreReal(H,k,"pfx_dur",dur)
    call StoreReal(H,k,"pfx_current",0)
 set H=null
endfunction


//==============================================================================================================================================================================
// Caster System Class: Damager
//
function Damager_SetAbility takes unit Damager, integer abilid, integer l returns nothing
 local string k=GetAttachmentTable(Damager)
 local integer i

    if (GetTableBoolean(k,"CS_IsDamager")) then
        set i=GetTableInt(k,"CS_abil")
        if (i!=0) then
            call UnitRemoveAbility(Damager,i)
        endif
        call UnitAddAbility(Damager,abilid)
        call SetUnitAbilityLevel(Damager,abilid,l)
        call SetTableInt(k,"CS_abil",abilid)
    endif
endfunction

function Damager_Removage takes unit u, timer t, group g returns nothing
 local string k=GetAttachmentTable(u)
    call PauseTimer(t)
    call CleanAttachedVars(t)
    call DestroyTimer(t)
   call GroupRemoveUnit(g,u)
   call DestroyEffect( GetTableEffect(k,"CS_fx") )
   call RecicleCasterAfterCastEx(u,4,GetTableInt(k,"CS_abil"),false)
   call ClearTable(k)

endfunction

function Damager_Remove takes unit Damager returns nothing
 local string k=GetAttachmentTable(Damager)
 local timer dg
 local group g

    if (GetTableBoolean(k,"CS_IsDamager")) then
        set g=GetTableGroup(I2S( GetTableInt(k,"CS_DG") ),"G")
        if (IsUnitInGroup(Damager,g)) then
            call Damager_Removage(Damager,GetTableTimer(k,"CS_t"),g)
        endif
    endif
 set g=null
 set dg=null
endfunction

function Damager_Expire takes nothing returns nothing
 local timer t=GetExpiredTimer()
 local unit u=GetAttachedUnit(t,"u")
    call Damager_Removage(u,t, GetAttachedGroup( GetAttachedObject(u,"CS_DG")  ,"G")     )
 set t=null
 set u=null
endfunction

function Damager_SetLifeSpan takes unit Damager, real lifespan returns nothing
 local timer t
    if (GetAttachedBoolean(Damager,"CS_IsDamager")) then
        set t=GetAttachedTimer(Damager,"CS_t")
        if (lifespan==0) then
            call PauseTimer(t)
        else
            call TimerStart(t,lifespan,false, function Damager_Expire)
        endif
       set t=null
    endif
endfunction

//============================================================================================================
// Caster System Class: DamagerGroup
//

function DamagerGroup_Destroy takes timer DamagerGroup returns nothing
 local string k=I2S(CS_H2I(DamagerGroup))
 local gamecache H=CSCache()
 local group g=GetTableGroup(k,"G")
 local unit p
    call DestroyDamageOptions(GetStoredInteger(H,k,"dop") )
    call CS_KillTimer( GetTableTimer(k,"lifespan") )
    loop
        set p=FirstOfGroup(g)
        exitwhen (p==null)
        call Damager_Removage(p, GetAttachedTimer(p,"CS_t") ,g)       
    endloop
    call DestroyGroup(g)
    call FlushStoredMission(H,k)
    call PauseTimer(DamagerGroup)
    call DestroyTimer(DamagerGroup)
 set g=null
 set H=null
endfunction

function DamagerGroup_Enum takes nothing returns nothing
    call GroupAddUnit(bj_groupAddGroupDest, GetFilterUnit() )
endfunction

function DamagerGroup_DoDamage takes nothing returns nothing
 local timer t=GetExpiredTimer()
 local string k=I2S(CS_H2I(t))
 local gamecache H=CSCache()
 local group g=CreateGroup()
 local group a=CS_CopyGroup(GetTableGroup(k,"G"))
 local group arg=CreateGroup()
 local unit p
 local unit u=GetTableUnit(k,"hur")
 local real x=GetStoredReal(H,k,"are")
 local real dm
 local integer d
 local boolean trees=GetStoredBoolean(H,k,"trees")
 local boolexpr bex=Condition(function DamagerGroup_Enum)

    set bj_groupAddGroupDest=g
    if (FirstOfGroup(a)!=null) then
        loop
            set p=FirstOfGroup(a)
            exitwhen (p==null)
            call GroupRemoveUnit(a,p)
            call CS_EnumUnitsInAOE(arg,GetUnitX(p),GetUnitY(p),x,bex)
            if trees then
                call DamageTreesInCircle(GetUnitX(p),GetUnitY(p),x)
            endif
        endloop   
        if (FirstOfGroup(g)!=null) then
            set d=LoadDamageOptions( GetStoredInteger(H,k,"dop") )
            set dm=GetStoredReal(H,k,"dmg")
            loop
                set p=FirstOfGroup(g)
                exitwhen (p==null)
                set x=GetDamageFactorByOptions(u,p,d)
                if (x!=0) then
                    call UnitDamageTarget(u,p,dm*x,true,false,null,null,null)
                endif
                call GroupRemoveUnit(g,p)
            endloop
        endif
    elseif GetStoredBoolean(H,k,"autodestruct") then
        call DamagerGroup_Destroy(t)
    endif
 call DestroyBoolExpr(bex)
 call DestroyGroup(g)
 call DestroyGroup(arg)
 call DestroyGroup(a)
 set bex=null
 set t=null
 set g=null
 set arg=null
 set a=null
 set u=null
 set H=null
endfunction

function DamagerGroup_Create takes unit hurter, real damage, real damageperiod, real area, integer DamageOptions returns timer
 local gamecache g=CSCache()
 local timer t=CreateTimer()
 local integer i=CS_H2I(t)
 local string k=I2S(i)

    if (damageperiod<0.01) then
        set damageperiod=0.01
    endif
    call StoreInteger(g,k,"dop",CreateDamageOptions(DamageOptions))
    call StoreInteger(g,k,"hur",CS_H2I(hurter))
    call StoreReal(g,k,"dmg",damage)
    call StoreReal(g,k,"are",area)
    call StoreInteger(g,k,"G",CS_H2I(CreateGroup()))

    if IsDamageOptionIncluded(DamageOptions, DamageTrees() ) then
        call StoreBoolean(g,k,"trees", true )
    endif
    call TimerStart(t,damageperiod,true,function DamagerGroup_DoDamage)

 set i=CS_H2I(t)
 set t=null
 return i
 return null
endfunction

function DamagerGroup_Update takes timer DamagerGroup, unit hurter, real damage, real damageperiod, real area, integer DamageOptions returns nothing
 local integer i
 local string k=GetAttachmentTable(DamagerGroup)
 local unit p=GetTableUnit(k,"hur")
 local player ow
 local group g

    if (damageperiod<0.01) then
        set damageperiod=0.01
    endif
    if (p!=hurter) then
        set g=CS_CopyGroup( GetTableGroup(k,"G") )
        call SetTableObject(k,"hur",hurter)
        set ow=GetOwningPlayer(hurter)
        loop
            set p=FirstOfGroup(g)
            exitwhen (p==null)
            call GroupRemoveUnit(g,p)
            call SetUnitOwner(p,ow,true)
        endloop
        call DestroyGroup(g)
       set g=null
       set ow=null
    endif

    call SetTableBoolean(k,"trees",IsDamageOptionIncluded(DamageOptions, DamageTrees() ) )
    call SetDamageOptions(GetTableInt(k,"dop") , DamageOptions )

    call SetTableReal(k,"dmg",damage)
    call SetTableReal(k,"are",area)

    call TimerStart(DamagerGroup,damageperiod,true,function DamagerGroup_DoDamage)

 set p=null
endfunction

function DamagerGroup_AddDamager takes timer DamagerGroup, string modelpath, real x, real y, real LifeSpan returns unit
 local unit c=GetACaster()
 local string k=GetAttachmentTable(c)
 local string dk=GetAttachmentTable(DamagerGroup)

 local timer t=CreateTimer()

    call SetUnitPosition(c,x,y)
    call SetTableObject(k,"CS_fx",AddSpecialEffectTarget( modelpath,c,"origin") )
    call SetTableObject(k,"CS_t", t)
    call SetTableObject(k,"CS_DG", DamagerGroup)
    call AttachObject(t,"u", c)
    if (LifeSpan>0) then
        call TimerStart(t,LifeSpan,false, function Damager_Expire)
    endif
    call SetUnitOwner(c,GetOwningPlayer(GetTableUnit(dk,"hur")),true)
    call GroupAddUnit(GetTableGroup(dk,"G"),c)
    call SetTableBoolean(k,"CS_IsDamager",true)

 set udg_currentcaster=c
 set c=null
 set t=null

 return udg_currentcaster
endfunction

function DamagerGroup_AddDamagerLoc takes timer DamagerGroup, string modelpath, location loc, real LifeSpan returns unit
    return DamagerGroup_AddDamager(DamagerGroup,modelpath,GetLocationX(loc),GetLocationY(loc),LifeSpan)
endfunction

function DamagerGroup_OnLifeSpanExpire takes nothing returns nothing
    call DamagerGroup_Destroy( GetAttachedTimer(GetExpiredTimer() , "t")  )
endfunction

function DamagerGroup_SetLifeSpan takes timer DamagerGroup, real lifespan returns nothing
 local string k=GetAttachmentTable(DamagerGroup)
 local timer t=GetAttachedTimer(DamagerGroup,"lifespan")

    if (HaveSetField(k,"lifespan",bj_GAMECACHE_INTEGER)) then
        set t=GetTableTimer(k,"lifespan")
    else
        set t=CreateTimer()
        call SetTableObject(k,"lifespan",t)
        set k=GetAttachmentTable(t)
        call AttachObject(t,"t",DamagerGroup)
    endif
    call TimerStart(t,lifespan,false, function DamagerGroup_OnLifeSpanExpire)
 set t=null
endfunction

function DamagerGroup_AutoDestruct takes timer DamagerGroup, boolean auto returns nothing
    call AttachBoolean(DamagerGroup,"autodestruct",auto)
endfunction

//**************************************************************************************************
//*
//* Caster System Special Events:
//*
//*
//**************************************************************************************************

//==================================================================================================
// Event: OnAbilityLearn
//
function Event_OnLearn1 takes nothing returns nothing
 local gamecache g=CSCache()
 local integer s=GetLearnedSkill()
 local string k=I2S(s)
   if HaveStoredString( g, "events_onlearn",k) then
       call ExecuteFunc( GetStoredString( g, "events_onlearn",k) )
   endif
 set g=null
endfunction

function Event_OnLearn2 takes nothing returns nothing
 local gamecache g=CSCache()
 local integer s=GetLearnedSkill()
 local string k=I2S(s)
   if HaveStoredString( g, "events_onlearn",k) then
       call StoreInteger(g,"events_variables","unit",CS_H2I(GetTriggerUnit()))
       call StoreInteger(g,"events_variables","current",s)
       call ExecuteFunc( GetStoredString( g, "events_onlearn",k) )
   endif
 set g=null
endfunction

function InitLearnEvent takes gamecache g, integer i returns nothing
 local trigger t=CreateTrigger()
 local integer j=0
    loop
        call TriggerRegisterPlayerUnitEvent(t, Player(j),EVENT_PLAYER_HERO_SKILL, null)
        set j=j+1
        exitwhen j==bj_MAX_PLAYER_SLOTS
    endloop
    if (i==1) then
        call StoreInteger(g,"Events_ProbablyTemp","learntrig",CS_H2I(t))
        call StoreInteger(g,"Events_ProbablyTemp","learntriga",CS_H2I(TriggerAddAction(t, function Event_OnLearn1)))
    else
        call TriggerAddAction(t, function Event_OnLearn2)
    endif
    call StoreInteger(g,"eventhandlers","learn",i)
     
 set t=null
endfunction

function OnAbilityLearn takes integer abilid, string funcname returns nothing
 local gamecache g=CSCache()

    if (not HaveStoredInteger(g,"eventhandlers","learn")) then
        call InitLearnEvent(g,1)
    endif

    call StoreString( g,"events_onlearn", I2S(abilid), funcname)

 set g=null
endfunction

//==================================================================================================
// Event: OnAbilityGet
//
function GetAbilityAcquiringUnit takes nothing returns unit
    return GetStoredInteger(CSCache(),"events_variables","unit")
    return null
endfunction

function GetAcquiredAbilityId takes nothing returns integer
    return GetStoredInteger(CSCache(),"events_variables","current")
endfunction

function UnitAddAbility_ConsiderEvent takes unit whichUnit, integer abilid, integer level returns nothing
 local gamecache g=CSCache()
 local string k=I2S(abilid)
    call UnitAddAbility(whichUnit,abilid)
    call SetUnitAbilityLevel(whichUnit,abilid,level)
    if (HaveStoredString(g,"events_onlearn",k)) then
        call StoreInteger(g,"events_variables","units",CS_H2I(whichUnit))
        call StoreInteger(g,"events_variables","current",abilid)
        call ExecuteFunc(GetStoredString(g,"events_onlearn",k))
    endif
 set g=null
endfunction

function Event_OnPassive_Browse takes gamecache g, unit u, string k returns nothing
 local integer n=GetStoredInteger(g,"events_passives","n")
 local integer un=0
 local integer i=1
 local integer s

    loop
        exitwhen (i>n)
        set s=GetStoredInteger(g,"events_passives",I2S(i))
        if (GetUnitAbilityLevel(u,s)>0) then
            if (un==0) then
                set un=1
                call StoreInteger(g,"events_variables","unit",CS_H2I(u))
            else
                set un=un+1
            endif
            call StoreInteger(g,"events_unit_passive"+I2S(un),k,s)
            call StoreInteger(g,"events_variables","current",s)
            call ExecuteFunc(GetStoredString(g,"events_onlearn",I2S(s)))
        endif
        set i=i+1
    endloop
    if (un==0) then
        set un=-1
    endif
    call StoreInteger(g,"events_unit_passives",k,un)
endfunction

function Event_OnPassive_Do takes gamecache g, unit u, string k, integer n returns nothing
 local integer i=1
 local integer s
    call StoreInteger(g,"events_variables","unit",CS_H2I(u))
    loop
        exitwhen (i>n)
        set s=GetStoredInteger(g,"events_unit_passive"+I2S(i),k)
        if (GetUnitAbilityLevel(u,s)>0) then
            call StoreInteger(g,"events_variables","current",s)
            call ExecuteFunc(GetStoredString(g,"events_onlearn",I2S(s)))
        endif
        set i=i+1
    endloop
endfunction


function Event_OnPassive_EnterRect takes nothing returns nothing
 local gamecache g=CSCache()
 local unit u=GetTriggerUnit()
 local string k=I2S(GetUnitTypeId(u))
 local integer n=GetStoredInteger(g,"events_unit_passives",k)
    if (n>0) then
        call Event_OnPassive_Do(g,u,k,n)
    elseif (n==0) then
        call Event_OnPassive_Browse(g,u,k)
    endif      

 set g=null
 set u=null
endfunction


function Event_OnPassive_InitEnum takes nothing returns nothing
 local gamecache g=CSCache()
 local trigger t
 local integer n=GetStoredInteger(g,"events_passives","n")
 local integer i=1
 local integer array p
 local string array s
 local unit u
 local group a=CreateGroup()
 local boolean saved
    call DestroyTimer(GetExpiredTimer())
    loop
        exitwhen (i>n)
        set p[i]=GetStoredInteger(g,"events_passives",I2S(i))
        set s[i]=GetStoredString(g,"events_onlearn", I2S(p[i]))
        set i=i+1
    endloop
    call GroupEnumUnitsInRect(a,bj_mapInitialPlayableArea,null)
    loop
        set u=FirstOfGroup(a)
        exitwhen (u==null)
        set i=1
        set saved=false

        loop
            exitwhen (i>n)
            if (GetUnitAbilityLevel(u,p[i])>0) then
                if (not saved) then
                    set saved=true
                    call StoreInteger(g,"events_variables","unit",CS_H2I(u))
                endif
                call StoreInteger(g,"events_variables","current",p[i])
                call ExecuteFunc(s[i])
            endif
            set i=i+1
        endloop
        call GroupRemoveUnit(a,u)
    endloop  
    set t=CreateTrigger()
    call TriggerRegisterEnterRectSimple(t,bj_mapInitialPlayableArea)
    call TriggerAddAction(t,function Event_OnPassive_EnterRect)
    call DestroyGroup(a)

 set t=null
 set a=null
endfunction

function InitPassiveEvent takes gamecache g returns nothing
 local trigger t
    call TimerStart(CreateTimer(),0,false,function Event_OnPassive_InitEnum)
    call StoreInteger(g,"eventhandlers","passives",1)

    if (not HaveStoredInteger(g,"eventhandlers","learn")) then
        call InitLearnEvent(g,2)
    else
        set t=GetTableTrigger("Events_ProbablyTemp","learntrig")
        call TriggerRemoveAction(t,GetTableTriggerAction("Events_ProbablyTemp","learntriga") )
        call FlushStoredMission(g,"Events_ProbablyTemp")
        set t=CreateTrigger()
        call TriggerAddAction(t, function Event_OnLearn2)
        call StoreInteger(g,"eventhandlers","learn",2)
       set t=null
    endif 

endfunction

function OnAbilityGet takes integer abilid, string funcname returns nothing
 local gamecache g=CSCache()
 local integer n=GetStoredInteger(g,"events_passives","n")+1

    if (not HaveStoredInteger(g,"eventhandlers","passives")) then
        call InitPassiveEvent(g)
    endif

    call StoreString( g,"events_onlearn", I2S(abilid), funcname)
    call StoreInteger(g,"events_passives","n",n)
    call StoreInteger(g,"events_passives",I2S(n),abilid)   
 set g=null
endfunction

//==================================================================================================
// Event: OnAbilityEffect
//
function Event_OnEffect takes nothing returns nothing
 local string k=I2S(GetSpellAbilityId())
 local gamecache g=CSCache()
    if HaveStoredString(g, "events_oneffect",k) then
        call ExecuteFunc( GetStoredString(g, "events_oneffect",k))
    endif
 set g=null
endfunction

function InitEffectEvent takes gamecache g returns nothing
 local trigger t=CreateTrigger()
 local integer i = 0
    loop
        call TriggerRegisterPlayerUnitEvent(t, Player(i),EVENT_PLAYER_UNIT_SPELL_EFFECT, null)
        set i=i+1
        exitwhen i==bj_MAX_PLAYER_SLOTS
    endloop
    call TriggerAddAction(t,function Event_OnEffect)
    call StoreInteger(g,"eventhandlers","effect",1)
 set t=null
endfunction

function OnAbilityEffect takes integer abilid, string funcname returns nothing
 local gamecache g=CSCache()
    if (not HaveStoredInteger(g,"eventhandlers","effect")) then
        call InitEffectEvent(g)
    endif
    call StoreString(g,"events_oneffect",I2S(abilid),funcname)
 set g=null
endfunction

//==================================================================================================
// Event: OnAbilityCast
//
function Event_OnCast takes nothing returns nothing
 local string k=I2S(GetSpellAbilityId())
 local gamecache g=CSCache()
    if HaveStoredString(g, "events_oncast",k) then
        call ExecuteFunc( GetStoredString(g, "events_oncast",k))
    endif
 set g=null
endfunction

function InitCastEvent takes gamecache g returns nothing
 local trigger t=CreateTrigger()
 local integer i = 0
    loop
        call TriggerRegisterPlayerUnitEvent(t, Player(i),EVENT_PLAYER_UNIT_SPELL_CAST, null)
        set i=i+1
        exitwhen i==bj_MAX_PLAYER_SLOTS
    endloop
    call TriggerAddAction(t,function Event_OnCast)
    call StoreInteger(g,"eventhandlers","cast",1)
 set t=null
endfunction

function OnAbilityPreCast takes integer abilid, string funcname returns nothing
 local gamecache g=CSCache()
    if (not HaveStoredInteger(g,"eventhandlers","cast")) then
        call InitCastEvent(g)
    endif
    call StoreString(g,"events_oncast",I2S(abilid),funcname)
 set g=null
endfunction

//==================================================================================================
// Event: OnAbilityEndCast
//
function Event_OnEndCast takes nothing returns nothing
 local string k=I2S(GetSpellAbilityId())
 local gamecache g=CSCache()
    if HaveStoredString(g, "events_onendcast",k) then
        call ExecuteFunc( GetStoredString(g, "events_onendcast",k))
    endif
 set g=null
endfunction

function InitEndCastEvent takes gamecache g returns nothing
 local trigger t=CreateTrigger()
 local integer i = 0
    loop
        call TriggerRegisterPlayerUnitEvent(t, Player(i),EVENT_PLAYER_UNIT_SPELL_ENDCAST, null)
        set i=i+1
        exitwhen i==bj_MAX_PLAYER_SLOTS
    endloop
    call TriggerAddAction(t,function Event_OnEndCast)
    call StoreInteger(g,"eventhandlers","endcast",1)
 set t=null
endfunction

function OnAbilityEndCast takes integer abilid, string funcname returns nothing
 local gamecache g=CSCache()
    if (not HaveStoredInteger(g,"eventhandlers","endcast")) then
        call InitEndCastEvent(g)
    endif
    call StoreString(g,"events_onendcast",I2S(abilid),funcname)
 set g=null
endfunction


//==================================================================================================
// Spell Helpers
//
function IsPointWater takes real x, real y returns boolean
    return IsTerrainPathable(x,y,PATHING_TYPE_WALKABILITY) and not(IsTerrainPathable(x,y,PATHING_TYPE_AMPHIBIOUSPATHING))
endfunction

function IsPointWaterLoc takes location loc returns boolean
    return IsPointWater(GetLocationX(loc),GetLocationY(loc))
endfunction

//==================================================================================================
function IsUnitSpellImmune takes unit u returns boolean
    return IsUnitType(u,UNIT_TYPE_MAGIC_IMMUNE)
endfunction

function IsUnitImmuneToPhisical takes unit u returns boolean
    return (GetDamageFactor(u,ATTACK_TYPE_CHAOS,DAMAGE_TYPE_DEMOLITION)==0)
endfunction

function IsUnitInvulnerable takes unit u returns boolean
    return (GetDamageFactor(u,ATTACK_TYPE_CHAOS,DAMAGE_TYPE_UNIVERSAL)==0)
endfunction

//## Utility functions ##
//====================================================================================================
// Mimic an interface error message
//     ForPlayer : The player to show the error
//     msg       : The error
//
function CS_Error takes player ForPlayer, string msg returns nothing
 local sound error=CreateSoundFromLabel( "InterfaceError",false,false,false,10,10)
    if (GetLocalPlayer() == ForPlayer) then
        if (msg!="") and (msg!=null) then
            call ClearTextMessages()
            call DisplayTimedTextToPlayer( ForPlayer, 0.52, -1.00, 2.00, "|cffffcc00"+msg+"|r" )
        endif
        call StartSound( error )
    endif
 call KillSoundWhenDone( error)
 set error=null
endfunction



//=============================================================================================================
// Obsolette functions: (Left for compatibility)
//
constant function WaterDetectorId takes nothing returns integer
    return 'Asb2' //Left for compat
endfunction
function SpellEffectModelPath takes integer abilityid, effecttype t returns string
    return GetAbilityEffectById(abilityid,t, 0)
endfunction