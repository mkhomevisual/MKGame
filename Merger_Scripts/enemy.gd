extends EnemyBase  # EnemyGhost

# This script defines the default "ghost" enemy.  It inherits from
# EnemyBase, which provides all of the basic movement, target tracking,
# knockback, frost effects and death handling.  The ghost has no
# special behaviour beyond moving directly towards the player and
# damaging on contact, so it simply exposes the exported properties
# (which override the base defaults) and leaves _update_enemy() empty.

# Override base defaults with ghost-specific values
@export var speed: float = 100.0
@export var max_hp: int = 2
@export var knockback_force: float = 50.0
@export var knockback_friction: float = 0.5
@export var contact_damage: int = 1
@export var attack_cooldown: float = 0.5
@export var frost_slow_factor: float = 0.0

# The ghost uses the same XP crystal scene as defined in EnemyBase.

func _update_enemy(_delta: float) -> void:
    # The ghost has no special behaviour; movement and attack are handled in EnemyBase.
    pass
