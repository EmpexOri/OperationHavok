extends Node2D
## Works on Sprite2D **and** Node2D roots.

@export var alpha_behind: float = 0.25
@export var alpha_normal: float = 1.0
@export var search_delay: float = 0.1
@export var max_distance: float = 100.0
@export var fade_speed: float = 20.0
@export var sprite_width: float = 100.0
@export var sprite_height: float = 200.0  

var player: CharacterBody2D
var canvas_item: CanvasItem    

func _ready() -> void:
	# Store a reference to whatever CanvasItem we are (Sprite2D, Node2D…)
	canvas_item = self as CanvasItem
	if canvas_item == null:
		push_error("%s is not a CanvasItem; cannot fade alpha." % name)
		return

	await get_tree().create_timer(search_delay).timeout

	var parent_node := get_parent()
	if parent_node == null:
		push_warning("No parent found for %s" % name)
		return

	for child in parent_node.get_children():
		if child is CharacterBody2D and child.name == "Player":
			player = child
			break

	if player == null:
		push_warning("Player not found under %s" % parent_node.name)

	# --- NEW: Auto-register NavObstacle if present (optional) ---
	# If this scene has a NavigationObstacle2D child, assign it the correct navigation_map.
	var obstacle_node := get_node_or_null("NavigationObstacle2D")
	if obstacle_node and obstacle_node is NavigationObstacle2D:
		# find a NavigationRegion2D anywhere in the tree (recursively)
		var nav_region := _find_navigation_region(get_tree().get_root()) as NavigationRegion2D
		if nav_region:
			obstacle_node.navigation_map = nav_region.get_navigation_map()
			# optional debug
			# print("Assigned navigation_map for obstacle on ", name, " -> ", nav_region.name)
		else:
			push_warning("No NavigationRegion2D found to assign obstacle for %s" % name)


func _find_navigation_region(root: Node) -> Node:
	# Recursively search for the first NavigationRegion2D in the scene tree.
	# Return as Node so caller can cast it cleanly (avoids type-inference errors).
	for child in root.get_children():
		if child is NavigationRegion2D:
			return child
		var found := _find_navigation_region(child)
		if found:
			return found
	return null


func _process(delta: float) -> void:
	if player == null or canvas_item == null:
		return

	var target_alpha := alpha_normal
	var distance := 0.0

	if canvas_item is Sprite2D:
		var sprite: Sprite2D = canvas_item
		var scale = sprite.scale
		var pivot_offset = sprite.offset
		var sprite_size = Vector2(sprite_width, sprite_height)

		var global_top_left = sprite.global_position - pivot_offset * scale
		var global_bottom_right = global_top_left + sprite_size * scale

		var closest_x = clamp(player.global_position.x, global_top_left.x, global_bottom_right.x)
		var closest_y = clamp(player.global_position.y, global_top_left.y, global_bottom_right.y)
		var closest_point = Vector2(closest_x, closest_y)

		distance = player.global_position.distance_to(closest_point)
	else:
		distance = player.global_position.distance_to(canvas_item.global_position)

	if distance <= max_distance and player.global_position.y < canvas_item.global_position.y:
		target_alpha = lerp(alpha_normal, alpha_behind, 1.0 - distance / max_distance)

	var current := canvas_item.modulate
	current.a = lerp(current.a, target_alpha, fade_speed * delta)
	canvas_item.modulate = current
