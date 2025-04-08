extends Node
class_name Weapon

# The base weapon script for the weapon super class, this should not be instantiated

@export var projectile_scene: PackedScene = null # The projectile the weapon will spawn
@export var base_fire_rate: float = 0.5 # Shots per second, 2/ps by default
@export var fire_offset: float = 5 # Spawn our projectile away from our player (think varying weapon lengths)

var current_fire_rate: float # The current fire rate, including any modifications

# TEMPORARY TESTING EFFECTS
var proj_penetrate = preload("res://Assets/Scripts/Effects/Projectile Effects/projectile_penetrate.gd")
var pen_effect = proj_penetrate.new()

@export var projectile_effects: Array[ProjectileEffect] = [pen_effect] # Array for projectile effects to pass to porjectile
@export var weapon_effects: Array[WeaponEffect] = [] # Array for weapon effects, weapon effects are applied in the weapon

var can_fire:bool = true # Boolean for checking if we can fire

var owning_entity: String # The owning entity of the weapon, used so projectiles can choose their collision channels

@onready var cooldown_timer: Timer = Timer.new() # Fire timer

func _ready() -> void:
	# Initialise fire rate
	current_fire_rate = base_fire_rate
	
	# Setup our weapon fire cooldown timer
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = current_fire_rate
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	add_child(cooldown_timer) 

# When timer triggers, we can fire again
func _on_cooldown_timer_timeout():
	can_fire = true
	
# Attempt to fire the weapon, if we can, fire and start cooldown timer
func attempt_to_fire(spawn_position: Vector2, direction: Vector2):
	if can_fire and projectile_scene != null:
		fire(spawn_position, direction)
		can_fire = false
		cooldown_timer.start()

# Fire our weapon, should not be called directly, use attemp to fire
func fire(spawn_position: Vector2, direction: Vector2):
	_spawn_projectile(spawn_position, direction)

# This is an interal method, called from fire
func _spawn_projectile(spawn_position: Vector2, direction: Vector2):
	var projectile_instance = projectile_scene.instantiate() # Instantiate a projectile
	
	var main_scene = get_tree().current_scene # Get the main scene
	if main_scene:
		main_scene.add_child(projectile_instance) # Add our rpojectile instance to our scene
	
	var position = spawn_position + direction * fire_offset  # Get the spawn position and offset
	
	projectile_instance.start(position, direction, owning_entity, projectile_effects) # Call the start method on the projectile script

# Adds effects - this is for both weapon and projectile effects (WIP)
func add_effect(new_effect: Resource):
	var found = false # Used to determine whether to add the effect or not
	
	# Check if we already have the projectile effect applied
	for i in range(projectile_effects.size()):
		var exisiting_effect = projectile_effects[i]
		if typeof(exisiting_effect) == typeof(new_effect) and exisiting_effect.effect_name == new_effect.effect_name:
			found  = true # The effect is already active, don't do anything
			# This can be modified later to apply additional effects if one of the same type already exists
			
	# Check if we already have the weapon effect applied
	for i in range(weapon_effects.size()):
		var existing_effect = weapon_effects[i]
		if typeof(existing_effect) == typeof(new_effect) and existing_effect.effect_name == new_effect.effect_name:
			found = true # The effect is already active, don't do anything
			# This can be modified later to apply additional effects if one of the same type already exists
	
	# Effect not applied, apply it
	if not found:
		if new_effect is ProjectileEffect:
			projectile_effects.append(new_effect) # Add projectile effect to array
			print("Added new projectile effect: ", new_effect.effect_name) # Print for testing
		elif new_effect is WeaponEffect:
			weapon_effects.append(new_effect) # Add weapon effect to array
			print("Added new weapon effect: ", new_effect.effect_name) # Print for testing
		else:
			print("Tried to add effect, but effect type was unknown")
			
# Remove an effect - this is for both weapon and projectile effects (WIP)
func remove_effect(effect_to_remove: Resource):
	if effect_to_remove:
		if projectile_effects.has(effect_to_remove):
			print("Removed the projectile effect: ", effect_to_remove.effect_name)
			projectile_effects.erase(effect_to_remove) # Projectile effects array has the effect, remove it
		elif weapon_effects.has(effect_to_remove):
			print("Removed the weapon effect: ", effect_to_remove.effect_name)
			weapon_effects.erase(effect_to_remove) # Weapon effects array has the effect, remove it
		else:
			print("Attempted to remove efffect, but it does not exist on the weapon")
		
