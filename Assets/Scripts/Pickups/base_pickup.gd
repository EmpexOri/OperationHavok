extends CharacterBody2D

# Base pickup class, override values/apply effect in derived class
class_name BasePickup

@export var sprite_frames_path: String = ""

var pickup_range: int
var pickup_type: String
var pickup_value: int
var sprite_path: String

var default_pickup_range: int
var player_in_range: bool = false

var speed = 300.0

var separation_distance = 10.0
var separation_force = 1
var cohesion_distance = 50.0
var cohesion_force = 1
var smoothing = 10

var target_velocity = Vector2.ZERO

func _ready() -> void:
	add_to_group("Pickups")
	add_to_group(pickup_type)

	# Store the original pickup range
	default_pickup_range = pickup_range
	
	var anim_sprite = $AnimatedSprite2D as AnimatedSprite2D
	if anim_sprite and sprite_frames_path != "":
		var frames = load(sprite_frames_path) as SpriteFrames
		anim_sprite.frames = frames
		anim_sprite.animation = "default"
		anim_sprite.play()
	else:
		print("AnimatedSprite2D or SpriteFrames missing for pickup: ", pickup_type)

	# Listen for XP pickup buff
	if pickup_type == "Xp":
		GlobalEffects.xp_buff_started.connect(_on_xp_buff_started)
		GlobalEffects.xp_buff_ended.connect(_on_xp_buff_ended)

func _physics_process(delta: float) -> void:
	var player = get_tree().get_nodes_in_group("Player")
	var player_position = Vector2.ZERO
	var separation_vector = Vector2.ZERO
	var cohesion_vector = Vector2.ZERO
	var nearby_pickups = 0
	
	if player:
		player_position = player[0].global_position
		var distance_to_player = global_position.distance_to(player_position)
		if distance_to_player < pickup_range:
			player_in_range = true
		if distance_to_player < 10:
			apply_effect()
			queue_free()
	
	if player_in_range:
		for element in get_tree().get_nodes_in_group("xp"):
			if element != self:
				var distance_to_element = global_position.distance_to(element.global_position)
				if distance_to_element < separation_distance:
					separation_vector += (global_position - element.global_position).normalized() / distance_to_element
				elif distance_to_element < cohesion_distance:
					cohesion_vector += element.global_position - global_position
					nearby_pickups += 1
					
		separation_vector = separation_vector.normalized() * separation_force
		
		if nearby_pickups > 0:
			cohesion_vector = (cohesion_vector / nearby_pickups).normalized() * cohesion_force
		
		if player_position:
			var direction_to_player = (player_position - global_position).normalized()
			var final_direction = direction_to_player + separation_vector + cohesion_vector
			target_velocity = target_velocity.lerp(final_direction * speed, smoothing * delta)
		else:
			target_velocity = Vector2.ZERO
		
		velocity = target_velocity
		move_and_slide()

# Override and handle in derived class
func apply_effect():
	pass

# Buff event handlers
func _on_xp_buff_started(bonus: int) -> void:
	pickup_range = default_pickup_range + bonus

func _on_xp_buff_ended() -> void:
	pickup_range = default_pickup_range
