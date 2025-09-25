extends Area2D

@export var teleport_target: NodePath
@export var beta_level_controller_path: NodePath = "/root/World/BetaLevelController"
@export var elevator_sfx_path: String = "res://Assets/Sound/SFX/Misc/ElevatorDing.mp3"
@export var blackout_duration: float = 2.5
@export var player_path: NodePath 

var player: Node = null
var camera: Camera2D = null
var blackout_sprite: Sprite2D = null

func _ready():
	monitoring = false
	body_entered.connect(_on_body_entered)
	call_deferred("_setup_camera_and_blackout")

func _setup_camera_and_blackout():
	var player_node = get_node_or_null(player_path)
	if not player_node:
		push_error("Player not found at path!")
		return

	player = player_node
	camera = player.get_node_or_null("Camera2D")
	if not camera:
		push_error("Camera2D not found under Player!")
		return

	blackout_sprite = camera.get_node_or_null("BlackoutSprite")
	if not blackout_sprite:
		push_error("BlackoutSprite not found under Camera2D!")
		return

	# Ensure initial alpha is 0
	blackout_sprite.modulate.a = 0.0
	blackout_sprite.visible = true

func _on_body_entered(body):
	if not body.is_in_group("Player"):
		return

	player = body
	start_elevator_sequence()

func start_elevator_sequence():
	if not player or not blackout_sprite:
		return

	# Lock player controls
	if player.has_method("set_master_lock"):
		player.set_master_lock(true)

	# Fade in blackout
	var tween = create_tween()
	tween.tween_property(blackout_sprite, "modulate:a", 1.0, 0.3)
	tween.connect("finished", Callable(self, "_on_blackout_faded_in"))

	# Play elevator sound
	var audio_controller = get_node("/root/GlobalAudioController")
	if audio_controller:
		audio_controller.play_general_sfx(elevator_sfx_path)

func _on_blackout_faded_in():
	# Teleport player
	var target = get_node_or_null(teleport_target)
	if target:
		player.global_position = target.global_position
		print("Player teleported via Rooftop Elevator!")

	# Update BetaLevelController
	var controller = get_node_or_null(beta_level_controller_path)
	if controller:
		controller._set_checkpoint("Rooftop_Area")
		if controller.has_method("unlock_area"):
			controller.unlock_area("Carpark_Area")

	# Wait for the blackout duration before fading out
	var timer = get_tree().create_timer(blackout_duration)
	timer.timeout.connect(_fade_out_blackout)

func _fade_out_blackout():
	# Fade out blackout
	if blackout_sprite:
		var tween = create_tween()
		tween.tween_property(blackout_sprite, "modulate:a", 0.0, 0.3)

	# Unlock player controls
	if player.has_method("set_master_lock"):
		player.set_master_lock(false)

	# Disable elevator trigger
	monitoring = false
