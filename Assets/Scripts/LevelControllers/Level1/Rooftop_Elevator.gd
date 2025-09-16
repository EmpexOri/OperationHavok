extends Area2D

@export var teleport_target: NodePath  # assign the Marker2D target in editor
@export var beta_level_controller_path: NodePath = "/root/World/BetaLevelController"

func _ready():
	# Ensure trigger is initially disabled
	monitoring = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body.is_in_group("Player"):
		return

	# Teleport the player
	var target = get_node_or_null(teleport_target)
	if target:
		body.global_position = target.global_position
		print("Player teleported via Rooftop Elevator!")
	else:
		push_error("Teleport target not assigned or not found!")

	# Notify BetaLevelController to mark progression
	var controller = get_node_or_null(beta_level_controller_path)
	if controller:
		controller._set_checkpoint("Rooftop_Area")
		print("BetaLevelController checkpoint updated: Rooftop_Area")
		# Optionally trigger progression to Carpark
		if controller.has_method("unlock_area"):
			controller.unlock_area("Carpark_Area")
	else:
		push_error("BetaLevelController not found at path: %s" % beta_level_controller_path)

	# Disable the elevator to prevent repeated use
	monitoring = false
