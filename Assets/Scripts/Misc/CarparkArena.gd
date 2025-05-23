extends Node2D

var CarparkAreaActivated := false

const HORDLING = preload("res://Prefabs/GamePrefabs/Enemy/Hordling.tscn")
const SPEWLING = preload("res://Prefabs/GamePrefabs/Enemy/Spewling.tscn")
const BIOMANCER = preload("res://Prefabs/GamePrefabs/Enemy/Biomancer.tscn")
const NEEDLING = preload("res://Prefabs/GamePrefabs/Enemy/Needling.tscn")
const TUMOR = preload("res://Prefabs/GamePrefabs/Enemy/Tumor.tscn")
const PAUSE_MENU_SCENE = preload("res://Scenes/Options/PauseMenu.tscn")

var current_wave := 0
var enemies: Array = []
var spawn_points: Array[Node2D] = []
var PauseMenu  # Will be instance of pause menu
var wave_in_progress := false
var wave_ending := false

var wave_data = [
	{ "Hordling": [3,6,3] },
	{ "Hordling": [3,6,3], "Spewling": [2,6,0], "Random": [1,6,1] },
	{ "Hordling": [5,6,3], "Spewling": [2,6,0], "Biomancer": [1,3,0], "Needling": [1,6,0], "Tumor": [1,6,0] },
	{ "Hordling": [5,6,4], "Spewling": [3,6,0], "Biomancer": [1,4,0], "Needling": [2,6,0], "Tumor": [1,6,1] },
	{ "Hordling": [6,6,6], "Spewling": [4,6,0], "Biomancer": [1,6,0], "Needling": [3,6,0], "Tumor": [2,6,1] },
	{ "Hordling": [6,6,8], "Spewling": [4,6,2], "Biomancer": [1,6,1], "Needling": [3,6,1], "Tumor": [2,6,2] },
	{ "Hordling": [7,6,10], "Spewling": [5,6,3], "Biomancer": [2,4,1], "Needling": [4,6,1], "Tumor": [3,6,2] },
	{ "Hordling": [7,6,12], "Spewling": [5,6,5], "Biomancer": [2,6,1], "Needling": [4,6,2], "Tumor": [4,6,2] },
	{ "Hordling": [8,6,14], "Spewling": [6,6,5], "Biomancer": [2,6,2], "Needling": [4,6,3], "Tumor": [4,6,3] },
	{ "Hordling": [10,6,15], "Spewling": [6,6,6], "Biomancer": [3,6,2], "Needling": [5,6,3], "Tumor": [5,6,3] },
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
	if not CarparkAreaActivated:
		return
	if wave_in_progress:
		return
	if current_wave >= wave_data.size():
		print("All waves complete!")
		return

	wave_in_progress = true
	print("Starting wave %d" % (current_wave + 1))
	var data = wave_data[current_wave]
	current_wave += 1

	for key in data.keys():
		var count = roll(data[key][0], data[key][1]) + data[key][2]
		var enemy_scene = null
	
		match key:
			"Hordling":
				enemy_scene = HORDLING
			"Spewling":
				enemy_scene = SPEWLING
			"Biomancer":
				enemy_scene = BIOMANCER
			"Needling":
				enemy_scene = NEEDLING
			"Tumor":
				enemy_scene = TUMOR
			"Random":
				enemy_scene = [BIOMANCER, NEEDLING, TUMOR].pick_random()
	
		if enemy_scene:
			for i in range(count):
				spawn_enemy_delayed(enemy_scene)

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

func roll(dice: int, sides: int) -> int:
	var total = 0
	for i in range(dice):
		total += randi_range(1, sides)
	return total

func activate_carpark_area():
	if not CarparkAreaActivated:
		CarparkAreaActivated = true
		start_next_wave()
