extends Node2D

signal arena_complete

# Enemy Scenes dictionary (child arenas can add/override entries)
var ENEMY_SCENES := {
	"Hordling": preload("res://Prefabs/GamePrefabs/Enemy/Hordling.tscn"),
	"Spewling": preload("res://Prefabs/GamePrefabs/Enemy/Spewling.tscn"),
	"Biomancer": preload("res://Prefabs/GamePrefabs/Enemy/Biomancer.tscn"),
	"Needling": preload("res://Prefabs/GamePrefabs/Enemy/Needling.tscn"),
	"Gatling": preload("res://Prefabs/GamePrefabs/Enemy/Gatling.tscn"),
	"Tumor": preload("res://Prefabs/GamePrefabs/Enemy/Tumor.tscn"),
	"MalignantTumor": preload("res://Prefabs/GamePrefabs/Enemy/MalignantTumor.tscn"),
	"Network": preload("res://Prefabs/GamePrefabs/Enemy/Network.tscn"),
	"Goolum": preload("res://Prefabs/GamePrefabs/Enemy/Goolum.tscn"),
	"Warmachine": preload("res://Prefabs/GamePrefabs/Enemy/Minibosses/Warmachine.tscn"),
	"Bruiser": preload("res://Prefabs/GamePrefabs/Enemy/Minibosses/Bruiser.tscn")
}

# Arena state
var arena_active := false
var current_wave := 0
var enemies: Array = []
var spawn_points: Array[Node2D] = []
var wave_in_progress := false
var wave_ending := false

# Child scripts override this
var wave_data: Array = []

func _ready():
	# Detect spawn points
	for i in range(4):
		var node_name = "Spawn%d" % i
		var spawn_node = get_node_or_null(node_name)
		if spawn_node:
			spawn_points.append(spawn_node)
		else:
			push_error("Missing spawn point: %s" % node_name)

func start_next_wave():
	if not arena_active or wave_in_progress or current_wave >= wave_data.size():
		if current_wave >= wave_data.size():
			arena_completed()
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
	if ENEMY_SCENES.has(key):
		return ENEMY_SCENES[key]
	elif key == "Random":
		# Default random picks from most enemies
		return [
			ENEMY_SCENES["Network"],
			ENEMY_SCENES["Goolum"],
			ENEMY_SCENES["Biomancer"],
			ENEMY_SCENES["Needling"],
			ENEMY_SCENES["Tumor"]
		]
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
					scene = scene_data.pick_random()
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

func _on_enemy_died(enemy):
	enemies.erase(enemy)
	if enemies.is_empty() and not wave_ending:
		wave_ending = true
		await get_tree().create_timer(1.0).timeout
		wave_in_progress = false
		wave_ending = false
		start_next_wave()

# Child scripts override this
func arena_completed():
	pass

func activate_arena():
	if not arena_active:
		arena_active = true
		start_next_wave()
