extends Node2D

var UndergroundArenaActivated := false
signal underground_arena_complete

const HORDLING = preload("res://Prefabs/GamePrefabs/Enemy/Hordling.tscn")
const SPEWLING = preload("res://Prefabs/GamePrefabs/Enemy/Spewling.tscn")
const BIOMANCER = preload("res://Prefabs/GamePrefabs/Enemy/Biomancer.tscn")
const NEEDLING = preload("res://Prefabs/GamePrefabs/Enemy/Needling.tscn")
const TUMOR = preload("res://Prefabs/GamePrefabs/Enemy/Tumor.tscn")
const GATLING = preload("res://Prefabs/GamePrefabs/Enemy/Gatling.tscn")

var current_wave := 0
var enemies: Array = []
var spawn_points: Array[Node2D] = []
var wave_in_progress := false
var wave_ending := false

var wave_data = [
	{ "Spewling": [2, 4, 1], "Needling": [1, 3, 0] },
	{ "Spewling": [3, 5, 1], "Needling": [2, 4, 1], "Tumor": [1, 2, 0] },
	{ "Needling": [2, 4, 2], "Tumor": [2, 3, 1], "Biomancer": [1, 2, 0] },
	{ "Needling": [3, 4, 2], "Tumor": [3, 4, 2], "Biomancer": [1, 3, 1], "Gatling": [1, 1, 0] },
]

func _ready():
	for i in range(5):
		var node_name = "Spawn%d" % i
		var spawn_node = get_node_or_null(node_name)
		if spawn_node:
			spawn_points.append(spawn_node)
		else:
			push_error("Missing spawn point: %s" % node_name)

func start_next_wave():
	if not UndergroundArenaActivated or wave_in_progress or current_wave >= wave_data.size():
		if current_wave >= wave_data.size():
			print("Underground arena complete!")
			emit_signal("underground_arena_complete")
		return

	wave_in_progress = true
	print("Starting underground wave %d" % (current_wave + 1))
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
	return null

func spawn_wave_enemies(data: Dictionary) -> void:
	for key in data.keys():
		var count = roll(data[key][0], data[key][1]) + data[key][2]
		var scene_data = get_scene_for_key(key)

		var enemies_remaining = count
		while enemies_remaining > 0:
			var batch_size = min(4, enemies_remaining)
			for i in range(batch_size):
				spawn_enemy(scene_data)
			enemies_remaining -= batch_size
			await get_tree().create_timer(randf_range(0.05, 0.2)).timeout

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

func activate_test_arena():
	if not UndergroundArenaActivated:
		UndergroundArenaActivated = true
		print("Next arena activated! Waiting 3 seconds...")
		await get_tree().create_timer(3.0).timeout
		start_next_wave()
