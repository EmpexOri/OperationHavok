extends Node
class_name Weapon

# The base weapon script for the weapon super class, this should not be instantiated

@export var projectile_scene: PackedScene = null # The projectile the weapon will spawn
@export var fire_rate: float = 0.5 # Shots per second, 2/ps by default
@export var fire_offset: float = 5 # Spawn our projectile away from our player (think varying weapon lengths)

@export var projectile_effects: Array[ProjectileEffect] = [] # Array for projectile effects to pass to porjectile

var can_fire:bool = true # Boolean for checking if we can fire

var owning_entity: String

@onready var cooldown_timer: Timer = Timer.new() # Fire timer

func _ready() -> void:
	# Setup our weapon fire cooldown timer
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = fire_rate
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
	var projectile_instance = projectile_scene.instantiate() # Instantiate a projectile
	
	var main_scene = get_tree().current_scene # Get the main scene
	if main_scene:
		main_scene.add_child(projectile_instance) # Add our rpojectile instance to our scene
	
	var position = spawn_position + direction * fire_offset  # Get the spawn position and offset
	projectile_instance.start(position, direction, owning_entity, projectile_effects) # Call the start method on the projectile script
	
	
	
