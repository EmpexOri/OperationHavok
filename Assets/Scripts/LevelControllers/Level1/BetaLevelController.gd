extends Node
"""
Central hub for:
 • registering & starting arenas
 • running one-off scripted events
 • pause-menu handling
 • checkpoint management
"""

const PAUSE_MENU_SCENE := preload("res://Scenes/Options/PauseMenu.tscn")

@onready var pause_menu := PAUSE_MENU_SCENE.instantiate()

# Stores arenas you register at runtime:  { name:String : { trigger:Area2D, arena:Node } }
var arenas := {}

# Name of last completed checkpoint
var current_checkpoint : String = ""

func _ready() -> void:
	# Instantiate and add menu immediately
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
	pause_menu.visible = false

	# Now it's safe to use pause_menu
	await get_tree().physics_frame

	var player := get_node_or_null("Player")
	if not player:
		push_error("Player node not found at path 'Player'")
		return

	var checkpoints := get_node_or_null("LevelManager/Checkpoints")
	if not checkpoints:
		push_error("Checkpoints node not found at LevelManager/Checkpoints")
	else:
		for marker in checkpoints.get_children():
			# accept Marker2D / Node2D, or members of the RespawnMarkers group,
			# and support names that start with "Respawn_"
			if marker is Node2D or marker.is_in_group("RespawnMarkers") or marker.name.begins_with("Respawn_"):
				var key = marker.name.replace("Respawn_", "").to_lower()
				player.register_spawn(key, marker.global_position)

	add_child(pause_menu)
	pause_menu.visible = false

func register_arena(name:String, trigger:Area2D, arena:Node) -> void:
	"""
	Call this from the scene tree once each arena & its trigger exist.
	The trigger must be an Area2D that fires body_entered.
	The arena must emit `arena_complete`.
	"""
	arenas[name] = { "trigger": trigger, "arena": arena }
	trigger.body_entered.connect(func(body):
		if body.is_in_group("Player"):
			_start_arena(name)
	)
	if arena.has_signal("arena_complete"):
		arena.connect("arena_complete", Callable(self, "_on_arena_complete").bind(name))

func _input(event:InputEvent) -> void:
	if Input.is_action_just_pressed("InGameOptions"):
		GlobalAudioController.PauseMenuMusic()
		_toggle_pause()

func _toggle_pause() -> void:
	if pause_menu.visible:
		# Closing pause menu
		pause_menu.visible = false
		get_tree().paused = false
	else:
		# Opening pause menu
		pause_menu.visible = true
		get_tree().paused = true
		if pause_menu.has_method("show_pause_menu"):
			pause_menu.show_pause_menu()

func _start_arena(name:String) -> void:
	var a = arenas.get(name, null)
	if a and a["arena"].has_method("activate_arena"):
		a["arena"].activate_arena()
		print("Arena started:", name)

func _on_arena_complete(name:String) -> void:
	print("Arena complete:", name)
	_set_checkpoint(name)    # set checkpoint to arena name (or any key you like)

func _set_checkpoint(flag:String) -> void:
	current_checkpoint = flag
	print("Checkpoint set:", flag)

func get_checkpoint() -> String:
	return current_checkpoint

func _on_RooftopTrigger_1_body_entered(body):
	if body.is_in_group("Player"):
		var arena = $Rooftop_Arena
		if arena:
			arena.activate_arena()
			var trigger = arena.get_node_or_null("RooftopTrigger_1")
			if trigger:
				trigger.monitoring = false
			else:
				push_error("RooftopTrigger_1 not found in Rooftop_Arena")
		else:
			push_error("Rooftop_Arena node not found")
