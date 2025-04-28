extends Node
class_name Weapon

# Base weapon script for the Weapon superclass — should not be instantiated directly.

@export var projectile_scene: PackedScene = null # The projectile this weapon will spawn
@export var base_fire_rate: float = 0.5 # Shots per second
@export var fire_offset: float = 5.0 # Offset from player to spawn projectile (weapon length)

@export var projectile_effects: Array[ProjectileEffect] = [] # Effects applied to projectiles
@export var weapon_effects: Array[WeaponEffect] = [] # Effects applied at the weapon level

var current_fire_rate: float
var can_fire: bool = true
var owning_entity: String

@onready var cooldown_timer: Timer = Timer.new()

func _ready() -> void:
	# Initialize fire rate
	current_fire_rate = base_fire_rate

	# Setup cooldown timer
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = current_fire_rate
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	add_child(cooldown_timer)

func _on_cooldown_timer_timeout() -> void:
	can_fire = true

func attempt_to_fire(spawn_position: Vector2, direction: Vector2) -> void:
	if can_fire and projectile_scene != null:
		fire(spawn_position, direction)
		can_fire = false
		cooldown_timer.start()

# Fire the weapon — this should NOT be called directly, always use attempt_to_fire().
func fire(spawn_position: Vector2, direction: Vector2) -> void:
	# Check if any weapon effect overrides the firing logic
	for effect in weapon_effects:
		if effect.override_fire_logic(self, spawn_position, direction, projectile_effects.duplicate(true)):
			return
	
	# Default firing parameters
	var fire_parameters = {
		"projectile_count": 1,
		"spread_angle": 0,
		"direction": direction
	}

	# Allow weapon effects to modify firing parameters
	for effect in weapon_effects:
		fire_parameters = effect.modify_parameters(fire_parameters)

	# Extract parameters
	var projectile_count: int = fire_parameters["projectile_count"]
	var spread_angle_deg: float = fire_parameters["spread_angle"]
	var base_direction: Vector2 = fire_parameters["direction"]

	var spread_radian: float = deg_to_rad(spread_angle_deg)
	var base_angle: float = base_direction.angle()

	var angle_step: float = 0.0
	if projectile_count > 1:
		angle_step = spread_radian / (projectile_count - 1)

	var start_angle: float = base_angle - spread_radian / 2.0

	for i in range(projectile_count):
		var shot_angle: float = start_angle + angle_step * i
		if projectile_count == 1:
			shot_angle = base_angle
		
		var fire_direction: Vector2 = Vector2.RIGHT.rotated(shot_angle)

		# Handle inaccuracy if set
		var inaccuracy_angle: float = fire_parameters.get("inaccuracy_angle", 0)
		if inaccuracy_angle != 0:
			var random_angle: float = deg_to_rad(randf_range(-inaccuracy_angle, inaccuracy_angle))
			fire_direction = fire_direction.rotated(random_angle)
		
		_spawn_projectile(spawn_position, fire_direction)

# Internal method for spawning a projectile
func _spawn_projectile(spawn_position: Vector2, direction: Vector2) -> void:
	var projectile_instance = projectile_scene.instantiate()

	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(projectile_instance)

	var position = spawn_position + direction * fire_offset
	projectile_instance.start(position, direction, owning_entity, projectile_effects.duplicate(true))

# Adds an effect to the weapon or projectiles
func add_effect(new_effect: Resource) -> void:
	var found: bool = false

	# Check projectile effects
	for existing_effect in projectile_effects:
		if typeof(existing_effect) == typeof(new_effect) and existing_effect.effect_name == new_effect.effect_name:
			found = true
			break

	# Check weapon effects
	for existing_effect in weapon_effects:
		if typeof(existing_effect) == typeof(new_effect) and existing_effect.effect_name == new_effect.effect_name:
			found = true
			break

	# Apply if not found
	if not found:
		if new_effect is ProjectileEffect:
			projectile_effects.append(new_effect)
			print("Added new projectile effect: ", new_effect.effect_name)
		elif new_effect is WeaponEffect:
			weapon_effects.append(new_effect)
			print("Added new weapon effect: ", new_effect.effect_name)
		else:
			print("Attempted to add unknown effect type.")

# Removes an effect from the weapon or projectiles
func remove_effect(effect_to_remove: Resource) -> void:
	if not effect_to_remove:
		return

	if projectile_effects.has(effect_to_remove):
		projectile_effects.erase(effect_to_remove)
		print("Removed projectile effect: ", effect_to_remove.effect_name)
	elif weapon_effects.has(effect_to_remove):
		weapon_effects.erase(effect_to_remove)
		print("Removed weapon effect: ", effect_to_remove.effect_name)
	else:
		print("Attempted to remove an effect that does not exist.")
