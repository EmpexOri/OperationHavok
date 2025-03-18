extends CharacterBody2D


var speed = 300.0
var separation_distance = 35.0
var separation_force = 3
var cohesion_distance = 50.0
var cohesion_force = 3
var smoothing = 0.1
var target_velocity = Vector2.ZERO

var pickup_range = 300
var player_in_range = false

func _ready() -> void:
	add_to_group("xp")

func _physics_process(delta: float) -> void:
	var player = get_tree().get_nodes_in_group("player")
	var player_position = Vector2.ZERO
	var separation_vector = Vector2.ZERO
	var cohesion_vector = Vector2.ZERO
	var nearby_xp = 0
	
	if player:
		player_position = player[0].global_position
		var distance_to_player = global_position.distance_to(player_position)
		if distance_to_player < pickup_range:
			player_in_range = true
		if distance_to_player < 5:
			queue_free()
	
	if player_in_range:
		for element in get_tree().get_nodes_in_group("xp"):
			if element != self:
				var distance_to_element = global_position.distance_to(element.global_position)
				if distance_to_element < separation_distance:
					separation_vector += (global_position - element.global_position).normalized() / distance_to_element
				elif distance_to_element < cohesion_distance:
					cohesion_vector += element.global_position - global_position
					nearby_xp += 1
					
		separation_vector = separation_vector.normalized() * separation_force
		
		if nearby_xp > 0:
			cohesion_vector = (cohesion_vector / nearby_xp).normalized() * cohesion_force
		
		if player_position:
			var direction_to_player = (player_position - global_position).normalized()
			var final_direction = direction_to_player + separation_vector + cohesion_vector
			target_velocity = target_velocity.lerp(final_direction * speed, smoothing)
		else:
			target_velocity = Vector2.ZERO
		
		velocity = target_velocity
		move_and_slide()
