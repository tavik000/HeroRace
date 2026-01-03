# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Warcraft III mod that implements an AI system for hero racing. The project uses JASS (Warcraft III's scripting language) to create intelligent AI heroes that navigate through waypoints, engage in combat, and handle various game states.

## File Structure

- `AIStateMachine.j` - Main AI logic implementing state machine pattern for hero behavior
- `api/1.0.0/` - Warcraft III API definitions
  - `blizzard.j` - Blizzard's standard function library
  - `common.j` - Core JASS type definitions and native functions

## Programming Language: JASS

This project uses JASS, Warcraft III's custom scripting language. Key characteristics:
- C-like syntax with Pascal-style variable declarations
- Struct-based object-oriented programming
- Manual memory management with `allocate()` and `deallocate()`
- No traditional build system - code is embedded directly into map files
- Uses hashtables for dynamic data storage
- Timer-based execution model

## Architecture

### State Machine Pattern
The AI system uses a state machine with these states:
- `STATE_PRE_GAME` (0) - Initial state
- `STATE_RUN` (1) - Normal movement/navigation
- `STATE_COMBAT` (2) - Ability casting and combat
- `STATE_HAZARD` (3) - Hazard avoidance
- `STATE_HEALING` (4) - Health recovery
- `STATE_DEAD` (5) - Death handling

### Key Components

**AIHero struct** (`AIStateMachine.j:400-473`):
- Main AI controller with hero unit reference
- Manages current state and waypoint progression
- Contains difficulty setting and combat data
- Updates every 0.3 seconds via timer system

**Waypoint System** (`AIStateMachine.j:38-57`):
- 14 predefined rectangular areas for navigation
- Heroes move through waypoints sequentially
- Configurable via World Editor regions (gg_rct_* variables)

**Combat System** (`AIStateMachine.j:276-396`):
- Difficulty-based ability casting (Easy: 2x cooldowns, Normal/Hard: standard)
- Hero-specific ability configurations
- Support for instant, point-target, and unit-target abilities

**HeroCombatData struct** (`AIStateMachine.j:88-119`):
- Manages hero abilities and cooldowns
- Supports up to 7 abilities per hero
- Tracks last cast times for cooldown calculations

## Development Guidelines

### JASS Syntax Conventions
- Use `local` keyword for all function-scoped variables
- **CRITICAL: All `local` variable declarations MUST be at the very top of functions/methods, before any executable code**
- Always set handle variables to `null` to prevent leaks
- Use `thistype` for struct self-references
- Implement proper `destroy` methods for all structs

### Adding New Heroes
1. Add hero type ID to `InitializeHeroCombatData` function (`AIStateMachine.j:133-152`)
2. Configure abilities using `data.addAbility(abilityId, cooldown, castType)`
3. Cast types: `CAST_INSTANT`, `CAST_POINT`, `CAST_UNIT`

### Modifying Waypoints
Update the `InitializeWaypoints` function (`AIStateMachine.j:39-57`) and adjust `GoalWaypointIndex` accordingly.

### Debug Output
Use `BJDebugMsg()` for logging - output appears in Warcraft III's debug console.

## Configuration Constants

Key settings in `AIStateMachine.j:4-36`:
- `HEAL_THRESHOLD` (0.40) - HP percentage for healing state
- `UPDATE_PERIOD` (0.30) - AI update frequency in seconds
- `CAST_RANGE` (700.00) - Ability casting range
- Difficulty-based cooldown multipliers

## No Build System

This project doesn't use traditional build tools. JASS code is integrated directly into Warcraft III map files. Testing requires:
1. Opening the map in Warcraft III World Editor
2. Saving and testing in-game
3. Using debug messages for troubleshooting