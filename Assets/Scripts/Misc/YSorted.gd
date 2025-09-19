extends Node2D
## Works on Sprite2D **and** Node2D roots.

@export var alpha_behind: float = 0.25
@export var alpha_normal: float = 1.0
@export var search_delay: float = 0.1
@export var max_distance: float = 100.0
@export var fade_speed: float = 20.0

var player: CharacterBody2D
var canvas_item: CanvasItem    # Sprite2D, Node2D, etc.

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

func _process(delta: float) -> void:
	if player == null or canvas_item == null:
		return

	var distance := player.global_position.distance_to(global_position)
	var target_alpha := alpha_normal

	if distance <= max_distance and player.global_position.y < global_position.y:
		target_alpha = lerp(alpha_normal, alpha_behind, 1.0 - distance / max_distance)

	# Smooth fade toward target alpha
	var current := canvas_item.modulate
	current.a = lerp(current.a, target_alpha, fade_speed * delta)
	canvas_item.modulate = current
