extends CharacterBody2D

# EnemyBase.gd
#
# Common base class for all enemy types.  This script centralises shared
# functionality such as movement towards the player, taking damage,
# knockback handling, frost/vortex effects and death/XP drops.  Concrete
# enemies should extend this class and override _update_enemy() to add
# specialised behaviour like ranged attacks or unique movement.

class_name EnemyBase

# --- Core stats ---
@export var speed: float = 20.0
@export var max_hp: int = 2
@export var knockback_force: float = 50.0
@export var knockback_friction: float = 0.5
@export var contact_damage: int = 1
@export var attack_cooldown: float = 0.5
@export var xp_crystal_scene: PackedScene = preload("res://Scenes/xpcrystal.tscn")
@export var frost_slow_factor: float = 0.0  # speed multiplier when frozen

# --- State ---
var hp: int = 0
var target: Node2D = null
var knockback_velocity: Vector2 = Vector2.ZERO
var _attack_cooldown_timer: float = 0.0
var is_dying: bool = false

var frost_time_left: float = 0.0
var _base_modulate: Color = Color(1, 1, 1, 1)

const FROST_COLOR: Color = Color(0.6, 0.8, 1.0, 1.0)

@onready var _damage_area: Area2D = $DamageArea
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _body_collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    # Initialise health and register this instance in the enemy group.
    hp = max_hp
    add_to_group("enemy")

    # Capture original sprite colour.
    if _sprite != null:
        _base_modulate = _sprite.modulate

    # Locate the player in the current scene if target isn't set.
    var world := get_tree().current_scene
    if world != null and target == null:
        if world.has_node("Player"):
            target = world.get_node("Player") as Node2D

    # Connect damage area signal if not already connected.
    if _damage_area != null and not _damage_area.body_entered.is_connected(_on_damage_area_body_entered):
        _damage_area.body_entered.connect(_on_damage_area_body_entered)

func _physics_process(delta: float) -> void:
    if is_dying:
        return

    # Handle frost slow effect.
    var speed_mult: float = 1.0
    if frost_time_left > 0.0:
        frost_time_left -= delta
        if frost_time_left <= 0.0:
            frost_time_left = 0.0
            _set_frost_visual(false)
        else:
            speed_mult = frost_slow_factor

    # Basic movement towards the player.
    var move_dir: Vector2 = Vector2.ZERO
    if target != null:
        var dir: Vector2 = target.global_position - global_position
        if dir.length() > 5.0:
            move_dir = dir.normalized()

    var base_velocity: Vector2 = move_dir * speed * speed_mult
    velocity = base_velocity + knockback_velocity
    move_and_slide()

    knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
    if _attack_cooldown_timer > 0.0:
        _attack_cooldown_timer -= delta

    # Allow subclasses to implement additional behaviour.
    _update_enemy(delta)

func _update_enemy(_delta: float) -> void:
    # Override this in subclasses to implement custom AI/attacks.
    pass

func take_damage(amount: int) -> void:
    if is_dying:
        return
    hp -= amount
    _play_hit_flash()
    if hp <= 0:
        _die()

func apply_knockback(dir: Vector2) -> void:
    knockback_velocity += dir.normalized() * knockback_force

func _on_damage_area_body_entered(body: Node) -> void:
    # Deal contact damage when colliding with the player if cooldown allows.
    if not body.is_in_group("player"):
        return
    if _attack_cooldown_timer > 0.0:
        return
    if body.has_method("take_damage"):
        body.take_damage(contact_damage)
    _attack_cooldown_timer = attack_cooldown

# ---- Frost / Vortex effects ----

func apply_frost(duration: float) -> void:
    frost_time_left = duration
    _set_frost_visual(true)

func _set_frost_visual(enabled: bool) -> void:
    if _sprite == null:
        return
    if enabled:
        _sprite.modulate = FROST_COLOR
    else:
        _sprite.modulate = _base_modulate

func apply_vortex_pull(center: Vector2, strength: float, delta: float) -> void:
    # Pull this enemy towards a center point with limited speed.
    var dir: Vector2 = center - global_position
    if dir == Vector2.ZERO:
        return
    var desired := dir.normalized() * strength
    knockback_velocity = knockback_velocity.move_toward(desired, strength * delta)
    var max_vortex_speed := strength
    if knockback_velocity.length() > max_vortex_speed:
        knockback_velocity = knockback_velocity.normalized() * max_vortex_speed

# ---- Hit flash ----

func _play_hit_flash() -> void:
    if _sprite == null:
        return
    var t := create_tween()
    t.tween_property(_sprite, "modulate", Color(1, 0.4, 0.4, 1.0), 0.05)
    var back_color: Color = FROST_COLOR if frost_time_left > 0.0 else _base_modulate
    t.tween_property(_sprite, "modulate", back_color, 0.10)

# ---- Death ----

func is_dead() -> bool:
    return is_dying or hp <= 0

func _die() -> void:
    if is_dying:
        return
    is_dying = true
    if _body_collision != null:
        _body_collision.set_deferred("disabled", true)
    if _damage_area != null:
        _damage_area.set_deferred("monitoring", false)
        _damage_area.set_deferred("monitorable", false)
    var world := get_tree().current_scene
    if world != null and world.has_method("add_score"):
        world.add_score(1)
    if xp_crystal_scene != null and world != null:
        var crystal := xp_crystal_scene.instantiate()
        crystal.global_position = global_position
        world.call_deferred("add_child", crystal)
    if _sprite != null:
        var t := create_tween()
        t.tween_property(_sprite, "scale", _sprite.scale * 1.2, 0.08)
        t.tween_property(_sprite, "modulate:a", 0.0, 0.18)
        t.finished.connect(func(): queue_free())
    else:
        queue_free()