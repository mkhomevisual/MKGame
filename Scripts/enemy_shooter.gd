extends "res://Scripts/enemy_base.gd"

# EnemyShooter.gd
#
# A ranged enemy that periodically shoots at the player when within a
# certain distance.  It inherits basic movement and damage logic from
# EnemyBase and adds a shooting cooldown and custom bullet scene.

@export var shoot_interval: float = 10
@export var shoot_range: float = 100.0
@export var projectile_scene: PackedScene = preload("res://Scenes/enemy_projectile.tscn")
@export var projectile_speed: float = 50.0
@export var projectile_damage: int = 1

var _shoot_timer: float = 0.0

func _ready() -> void:
	# Call base initialisation.
	super._ready()
	_shoot_timer = randf() * shoot_interval  # randomise initial offset

func _update_enemy(delta: float) -> void:
	# Reduce shoot timer.
	if _shoot_timer > 0.0:
		_shoot_timer -= delta

	# Only shoot if projectile scene is set and timer expired.
	if _shoot_timer <= 0.0 and projectile_scene != null and target != null:
		# Check distance to target.
		var dir: Vector2 = target.global_position - global_position
		var distance: float = dir.length()
		if distance <= shoot_range:
			_shoot_timer = shoot_interval
			_spawn_projectile(dir)

func _spawn_projectile(dir: Vector2) -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	var proj := projectile_scene.instantiate()
	world.add_child(proj)
	proj.global_position = global_position
	# Set direction and damage if methods exist on projectile.
	if proj.has_method("set_direction"):
		proj.set_direction(dir)
	if proj.has_method("set_damage"):
		proj.set_damage(projectile_damage)
	if proj.has_method("set_speed"):
		proj.set_speed(projectile_speed)
