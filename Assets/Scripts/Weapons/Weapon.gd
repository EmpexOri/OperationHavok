extends Node
class_name Weapon

# The base weapon script for the weapon super class, this should not be instantiated

@export var projectile_scene: PackedScene = null # The projectile the weapon will spawn
@export var base_fire_rate: float = 0.5 # Shots per second, 2/ps by default
@export var fire_offset: float = 5 # Spawn our projectile away from our player (think varying weapon lengths)

var current_fire_rate: float # The current fire rate, including any modifications

@export var projectile_effects: Array[ProjectileEffect] = [] # Array for projectile effects to pass to porjectile
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
	# Completely ignore firing logic to create complex effects that the below can't handle
	for effect in weapon_effects:
		if effect.override_fire_logic(self, spawn_position, direction, projectile_effects.duplicate(true)):
			return # Effect in the weapon effect handled firing, return
	
	# Default parameters for weapon firing, i.e. a single bullet with no spread
	var fire_parameters = {
		"projectile_count": 1, # The count of projectiles to shoot
		"spread_angle": 0, # The angle of spread in degrees
		"direction": direction # The direction to shoot, where the player is aiming by default
	}
	
	# Aplly any modifiers from the weapon effect, this effects the dict above
	for effect in weapon_effects:
		fire_parameters = effect.modify_parameters(fire_parameters)
	
	# Create variables for each of our modified (or unmodified) parameters from our dict
	var projectile_count = fire_parameters["projectile_count"] # The count of projectiles to shoot
	var spread_radian = deg_to_rad(fire_parameters["spread_angle"]) # Convert degrees into radians
	var base_angle = fire_parameters["direction"].angle() # Get the central aiming direction in degrees
	
	# S on above parameters
	var angle_step = 0.0
	if projectile_count > 1: # If we have more than one projectile 
		angle_step = spread_radian / (projectile_count - 1) # Calculate the step between each projectile
	
	var start_angle = base_angle - spread_radian / 2.0 # Calculate angle for the first projectile
	
	for i in range(projectile_count): # For each projectile
		var shot_angle = start_angle + angle_step * i # Calculate specific angle for that projectile
		if projectile_count == 1: # Only one projectile
			shot_angle = base_angle # We have one projectile so just use base_angle 
		
		var fire_direction = Vector2.RIGHT.rotated(shot_angle) # The normalised direction pointing to shot_angle
		_spawn_projectile(spawn_position, fire_direction) # Spawn our projectile

# This is an interal method, called from fire
func _spawn_projectile(spawn_position: Vector2, direction: Vector2):
	var projectile_instance = projectile_scene.instantiate() # Instantiate a projectile
	
	var main_scene = get_tree().current_scene # Get the main scene
	if main_scene:
		main_scene.add_child(projectile_instance) # Add our rpojectile instance to our scene
	
	var position = spawn_position + direction * fire_offset  # Get the spawn position and offset
	
	projectile_instance.start(position, direction, owning_entity, projectile_effects.duplicate(true)) # Call the start method on the projectile script

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
		
