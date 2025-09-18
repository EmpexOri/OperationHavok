extends Sprite2D

@export var alpha_behind: float = 0.25
@export var alpha_normal: float = 1.0  
@export var search_delay: float = 0.1  
@export var max_distance: float = 100.0
@export var fade_speed: float = 20.0  

var player: CharacterBody2D

func _ready():
	await get_tree().create_timer(search_delay).timeout
	
	var parent_node = get_parent()
	if parent_node == null:
		push_warning("No parent found for %s" % name)
		return

	# Scan children of parent for CharacterBody2D named "Player"
	for child in parent_node.get_children():
		if child is CharacterBody2D and child.name == "Player":
			player = child
			break
	
	if player == null:
		push_warning("Player not found under %s" % parent_node.name)

func _process(delta):
	if player == null:
		return

	var distance = player.global_position.distance_to(global_position)
	
	# Determine target alpha based on distance and Y position
	var target_alpha = alpha_normal
	if distance <= max_distance and player.global_position.y < global_position.y:
		# Closer = more transparent
		target_alpha = lerp(alpha_normal, alpha_behind, 1.0 - distance / max_distance)
	
	# Smoothly interpolate current alpha towards target
	modulate.a = lerp(modulate.a, target_alpha, fade_speed * delta)
