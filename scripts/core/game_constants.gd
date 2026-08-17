class_name GameConstants
extends RefCounted

# GDD §4 — Combat & Deck Engine
const DECK_MIN_SIZE: int = 20
const DECK_MAX_SIZE: int = 50
const HAND_START_SIZE: int = 5
const HAND_MAX_SIZE: int = 10
const OVERDRIVE_MAX_PLAYS: int = 12

const MANA_REGEN_PER_TURN: int = 5
const MANA_DEFAULT_CAP: int = 20

# Physical weapon hit (GDD: can proc a deck card at 0 mana).
const PHYSICAL_ATTACK_DAMAGE: int = 4
const PHYSICAL_PROC_CHANCE: float = 0.25

# Guard — shield absorbed before HP, lasts until the next player turn.
const GUARD_SHIELD: int = 6

# Mid-combat burn revive (GDD: burn pile revivable).
const BURN_REVIVE_MANA_COST: int = 2

# UI — minimum touch target for mobile (dp)
const MIN_TOUCH_TARGET: int = 48

# Top-down 2D overworld
const TILE_SIZE: int = 16
const OVERWORLD_WALK_SPEED: float = 120.0
const ENCOUNTER_DISTANCE_PX: float = 420.0
const CAMERA_ZOOM: float = 2.5

# Guildhall dispatch stub
const DISPATCH_DURATION_SEC: float = 8.0
const DISPATCH_WOOD_REWARD: int = 3
