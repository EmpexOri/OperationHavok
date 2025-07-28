extends Node2D

var CarparkAreaActivated := false
signal carpark_arena_complete

const HORDLING = preload("res://Prefabs/GamePrefabs/Enemy/Hordling.tscn")
const SPEWLING = preload("res://Prefabs/GamePrefabs/Enemy/Spewling.tscn")
const BIOMANCER = preload("res://Prefabs/GamePrefabs/Enemy/Biomancer.tscn")
const NEEDLING = preload("res://Prefabs/GamePrefabs/Enemy/Needling.tscn")
const GATLING = preload("res://Prefabs/GamePrefabs/Enemy/Gatling.tscn")
const TUMOR = preload("res://Prefabs/GamePrefabs/Enemy/Tumor.tscn")
const NETWORK = preload("res://Prefabs/GamePrefabs/Enemy/Network.tscn")
const GOOLUM = preload("res://Prefabs/GamePrefabs/Enemy/Goolum.tscn")
const WARMACHINE = preload("res://Prefabs/GamePrefabs/Enemy/Minibosses/Warmachine.tscn")

const PAUSE_MENU_SCENE = preload("res://Scenes/Options/PauseMenu.tscn")

var current_wave := 0
var enemies: Array = []
var spawn_points: Array[Node2D] = []
var PauseMenu  
var wave_in_progress := false
var wave_ending := false

var wave_data = [
	{ "Hordling": [3,6,3], "Spewling": [2,6,0], "Random": [1,6,1] },
	{ "Hordling": [5,6,4], "Spewling": [3,6,0], "Biomancer": [1,4,0], "Needling": [2,6,0], "Tumor": [1,6,1] },
	{ "Hordling": [6,6,8], "Spewling": [4,6,2], "Biomancer": [1,6,1], "Needling": [3,6,1], "Tumor": [2,6,2], "Gatling": [1,1,1], "Network": [1,0,1] },
	{ "Hordling": [7,6,12], "Spewling": [5,6,5], "Biomancer": [2,6,1], "Needling": [4,6,2], "Tumor": [4,6,2], "Network": [1,1,1] },
	{ "Hordling": [10,6,15], "Spewling": [6,6,6], "Biomancer": [3,6,2], "Needling": [5,6,3], "Tumor": [5,6,3], "Gatling": [1,6,1], "Network": [1,2,1], "Warmachine": [1,1,0]  },
]

func _ready():
	for i in range(5):
		var node_name = "Spawn%d" % i
		var spawn_node = get_node_or_null(node_name)
		if spawn_node:
			spawn_points.append(spawn_node)
		else:
			push_error("Missing spawn point: %s" % node_name)
	
	PauseMenu = PAUSE_MENU_SCENE.instantiate()
	PauseMenu.visible = false
	add_child(PauseMenu)
	
	# start_next_wave()

func _input(event):
	if Input.is_action_just_pressed("InGameOptions"):
		GlobalAudioController.PauseMenuMusic()
		if PauseMenu.has_method("show_pause_menu"):
			PauseMenu.show_pause_menu()
		pause_game()

func pause_game():
	if get_tree().paused:
		get_tree().paused = false
		PauseMenu.visible = false
	else:
		get_tree().paused = true
		PauseMenu.visible = true

func start_next_wave():
	if not CarparkAreaActivated or wave_in_progress or current_wave >= wave_data.size():
		if current_wave >= wave_data.size():
			print("All waves complete!")
			emit_signal("carpark_arena_complete")
		return

	wave_in_progress = true
	print("Starting wave %d" % (current_wave + 1))
	var data = wave_data[current_wave]
	current_wave += 1

	await spawn_wave_enemies(data)

func roll(dice: int, sides: int) -> int:
	var total = 0
	for i in range(dice):
		total += randi_range(1, sides)
	return total

func get_scene_for_key(key: String):
	match key:
		"Hordling":
			return HORDLING
		"Spewling":
			return SPEWLING
		"Biomancer":
			return BIOMANCER
		"Needling":
			return NEEDLING
		"Gatling":
			return GATLING
		"Tumor":
			return TUMOR
		"Network":
			return NETWORK
		"Warmachine":
			return WARMACHINE
		"Random":
			return [GOOLUM] #[NETWORK, GOOLUM, BIOMANCER, NEEDLING, TUMOR]
	return null

func spawn_wave_enemies(data: Dictionary) -> void:
	for key in data.keys():
		var count = roll(data[key][0], data[key][1]) + data[key][2]
		var scene_data = get_scene_for_key(key)
		
		var enemies_remaining = count
		while enemies_remaining > 0:
			var batch_size = min(5, enemies_remaining)
			for i in range(batch_size):
				var scene
				if key == "Random":
					scene = scene_data.pick_random()  # Pick a new one each time
				else:
					scene = scene_data
				spawn_enemy(scene)
			enemies_remaining -= batch_size
			await get_tree().create_timer(randf_range(0.05, 0.25)).timeout

func spawn_enemy(scene: PackedScene) -> void:
	var enemy = scene.instantiate()
	var spawn = spawn_points[randi() % spawn_points.size()]
	enemy.visible = true
	enemy.position = spawn.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	enemy.name = "Enemy_" + str(randi())
	enemies.append(enemy)
	call_deferred("add_child", enemy)
	enemy.connect("died", Callable(self, "_on_enemy_died"))

func spawn_enemy_delayed(scene: PackedScene) -> void:
	await get_tree().create_timer(randf_range(0.1, 0.4)).timeout
	var enemy = scene.instantiate()
	var spawn = spawn_points[randi() % spawn_points.size()]
	enemy.visible = true
	enemy.position = spawn.global_position + Vector2(randf_range(-4, 4), randf_range(-4, 4))
	enemy.name = "Enemy_" + str(randi())
	enemies.append(enemy)
	call_deferred("add_child", enemy)  # <-- defer adding the enemy
	enemy.connect("died", Callable(self, "_on_enemy_died"))

func _on_enemy_died(enemy):
	enemies.erase(enemy)

	if enemies.is_empty() and not wave_ending:
		wave_ending = true  
		await get_tree().create_timer(1.0).timeout
		wave_in_progress = false
		wave_ending = false 
		start_next_wave()

func check_for_wave_completion():
	while not enemies.is_empty():
		await get_tree().process_frame
	print("Wave %d complete!" % current_wave)

func activate_carpark_area():
	if not CarparkAreaActivated:
		CarparkAreaActivated = true
		start_next_wave()
