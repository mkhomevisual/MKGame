extends EnemyBase

# EnemyTank.gd
#
# A heavily armoured melee enemy.  This variant has high health and
# slower movement but otherwise behaves like a basic ghost.  It can be
# further customised in the inspector.

@export var speed: float = 50.0
@export var max_hp: int = 8
@export var knockback_force: float = 80.0
@export var knockback_friction: float = 0.3
@export var contact_damage: int = 2
@export var attack_cooldown: float = 0.8
@export var frost_slow_factor: float = 0.0

func _update_enemy(_delta: float) -> void:
    # Tank has no ranged attacks; default behaviour is enough.
    pass