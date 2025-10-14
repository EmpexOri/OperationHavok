extends Node

const PAUSE_MENU_SCENE := preload("res://Scenes/Options/PauseMenu.tscn")
const BOULDER_BLOCKER_SCENE := preload("res://Prefabs/GamePrefabs/Objects/Blockers/Boulder_Blocker.tscn")

var checkpoint_to_arena := {
	"rooftop": $ChecRooftop_Arena,
	"parkinglot": $Parkinglot_Arena,
	"park": $Park_Arena,
	"stripmall": $Respawn_Stripmall
}

@onready var pause_menu: PauseNode = PAUSE_MENU_SCENE.instantiate() as PauseNode
@onready var runtime_objects: Node = Node.new() 

# Stores arenas you register at runtime:  { name:String : { trigger:Area2D, arena:Node } }
var arenas := {}

var level_time_active: bool = false

# Name of last completed checkpoint
var current_checkpoint : String = ""

func _ready() -> void:
	# Instantiate pause menu
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
	pause_menu.visible = false
	
	# Wait for player
	var player: Node = null
	while not player:
		await get_tree().process_frame
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player = players[0]
			
	print("Player found:", player)
	runtime_objects.name = "RuntimeObjects"
	add_child(runtime_objects)
	pause_menu.SkillTreeClosed.connect(_on_skill_tree_closed_in_level)
	
	# Register spawn points
	var checkpoints := get_node_or_null("LevelManager/Checkpoints")
	if checkpoints:
		for marker in checkpoints.get_children():
			if marker is Node2D or marker.is_in_group("RespawnMarkers") or marker.name.begins_with("Respawn_"):
				var key = marker.name.replace("Respawn_", "").to_lower()
				player.register_spawn(key, marker.global_position)
				
	for arena in checkpoint_to_arena.values():
		if arena and arena.has_method("reset_arena"):
			arena.reset_arena()
			print("Arena reset:", arena.name)
			
	if not GlobalPlayer.HasRestartedLevel:
		GlobalPlayer.HasRestartedLevel = true
		#if GlobalPlayer.has_method("restart_level"):
			#GlobalPlayer.restart_level()
			
func _on_skill_tree_closed_in_level():
	get_tree().paused = false
	GlobalAudioController.STOPPauseMenuMusic()
	pause_menu.visible = false  

func register_arena(name:String, trigger:Area2D, arena:Node) -> void:
	arenas[name] = { "trigger": trigger, "arena": arena }
	trigger.body_entered.connect(func(body):
		if body.is_in_group("Player"):
			_start_arena(name)
	)
	if arena.has_signal("arena_complete"):
		arena.connect("arena_complete", Callable(self, "_on_arena_complete").bind(name))

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("InGameOptions"):
		GlobalAudioController.PauseMenuMusic()
		#_show_perk_menu()
		_toggle_pause()
	if Input.is_action_just_pressed("DebugInput_4"):
		_debug_teleport_to_checkpoint()
		
func _show_perk_menu() -> void:
	get_tree().paused = true
	pause_menu._on_skill_tree_button_pressed()

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
		
		# Set checkpoint immediately when arena begins
		var checkpoint_name := ""
		match name:
			"Rooftop_Arena":
				checkpoint_name = "rooftop"
			"Parkinglot_Arena":
				checkpoint_name = "parkinglot"
			"Park_Arena":
				checkpoint_name = "park"
			"Stripmall_Arena":
				checkpoint_name = "stripmall"
			_:
				checkpoint_name = name.to_lower()
		
		_set_checkpoint(checkpoint_name)

func _on_arena_complete(name:String) -> void:
	print("Arena complete:", name)

	var respawn_checkpoint := ""
	match name:
		"Rooftop_Arena":
			respawn_checkpoint = "parkinglot"   # after Rooftop -> respawn at Parkinglot
		"Parkinglot_Arena":
			respawn_checkpoint = "park"         # after Parkinglot -> respawn at Park
		"Park_Arena":
			respawn_checkpoint = "park"         # Park completed -> keep park (or change if you want another)
		_:
			respawn_checkpoint = name.to_lower()

	_set_checkpoint(respawn_checkpoint)

func _set_checkpoint(flag:String) -> void:
	current_checkpoint = flag
	print("Checkpoint set:", flag)

	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var player = players[0]
		if player.spawn_points.has(flag):
			GlobalPlayer.current_respawn_position = player.spawn_points[flag]

	# Reset the arena if it exists
	var arena = checkpoint_to_arena.get(flag, null)
	if arena and arena.has_method("reset_arena"):
		arena.reset_arena()

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

func _on_ParkinglotTrigger_body_entered(body):
	if body.is_in_group("Player"):
		var arena = $Parkinglot_Arena
		if arena:
			arena.activate_arena()
			var trigger = arena.get_node_or_null("Parkinglot_Trigger")
			if trigger:
				trigger.queue_free()
			else:
				push_error("Parkinglot_Trigger not found in Parkinglot_Arena")
		else:
			push_error("Parkinglot_Arena node not found")

func respawn_player(player):
	# Teleport player to checkpoint
	player.global_position = GlobalPlayer.current_respawn_position
	GlobalPlayer.PlayerHP = GlobalPlayer.PlayerHPMax

	# Reset arena tied to this checkpoint
	var arena = checkpoint_to_arena.get(current_checkpoint, null)
	if arena and arena.has_method("reset_arena"):
		arena.reset_arena()
		# Optionally, re-activate the arena automatically
		if arena.has_method("activate_arena"):
			arena.activate_arena()

func _on_ParkTrigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	var arena = $Park_Arena
	if not arena or arena.arena_active:
		return

	arena.activate_arena()
	print("Park Arena activated!")

	# Spawn Boulder_Blocker using runtime container
	spawn_runtime_object(BOULDER_BLOCKER_SCENE, Vector2(310, 1674))

	# Disable or remove the trigger
	var trigger = arena.get_node_or_null("ParkTrigger")
	if trigger:
		trigger.queue_free()

func _on_StripmallTrigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	var arena = $Stripmall_Arena
	if arena:
		arena.activate_arena()
		print("Stripmall Arena activated!")

		# Spawn Boulder_Blocker using runtime container
		spawn_runtime_object(BOULDER_BLOCKER_SCENE, Vector2(1445, 1764))

		var trigger = get_node_or_null("StripmallTrigger")
		if trigger:
			trigger.queue_free()
	else:
		push_error("Stripmall_Arena node not found")

func spawn_runtime_object(scene: PackedScene, position: Vector2) -> Node:
	var obj = scene.instantiate()
	obj.global_position = position
	runtime_objects.add_child(obj)
	return obj

func clear_runtime_objects() -> void:
	for child in runtime_objects.get_children():
		child.queue_free()

func _debug_teleport_to_checkpoint() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() == 0:
		print("No player found to teleport!")
		return
	
	var player = players[0]
	print("Teleporting player to checkpoint:", current_checkpoint)
	respawn_player(player)
