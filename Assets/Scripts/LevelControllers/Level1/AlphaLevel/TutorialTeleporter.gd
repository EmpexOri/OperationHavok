extends Area2D

@export var destination_path: NodePath   # assign your Node2D in the editor
var destination: Node2D

func _ready():
	destination = get_node_or_null(destination_path)
	if not destination:
		push_error("TeleportTrigger missing destination node!")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and destination:
		print("Teleporting player to: ", destination.global_position)
		body.global_position = destination.global_position
