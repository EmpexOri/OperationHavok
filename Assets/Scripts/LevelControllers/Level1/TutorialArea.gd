# TutorialArena.gd
extends "res://Assets/Scripts/LevelControllers/Level1/ArenaManager.gd"

signal tutorial_complete

func _ready():
	super._ready()

	# Instead of multiple waves, just one scripted wave
	wave_data = [
		{
			"Spawn0": { "Hordling": 12, "Spewling": 3 },
			"Spawn1": { "Hordling": 12, "Spewling": 3 },
			"Spawn2": { "Needling": 1 },
			"Spawn3": { "Needling": 1 },
			"Spawn4": { "Hordling": 15, "Spewling": 5, "Needling": 1 }
		}
	]

func spawn_wave_enemies(data: Dictionary) -> void:
	# Each key is a spawn node ("Spawn0"..."Spawn4")
	for spawn_key in data.keys():
		var spawn_node = get_node_or_null(spawn_key)
		if not spawn_node:
			push_error("Missing spawn point: %s" % spawn_key)
			continue

		# For each enemy type in this spawn point
		for enemy_type in data[spawn_key].keys():
			var count = data[spawn_key][enemy_type]

			if not ENEMY_SCENES.has(enemy_type):
				push_error("Unknown enemy type: %s" % enemy_type)
				continue

			var scene = ENEMY_SCENES[enemy_type]

			for i in range(count):
				var enemy = scene.instantiate()
				enemy.visible = true
				enemy.position = spawn_node.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
				enemy.name = "%s_%d" % [enemy_type, randi()]
				enemies.append(enemy)
				call_deferred("add_child", enemy)
				enemy.connect("died", Callable(self, "_on_enemy_died"))

		await get_tree().create_timer(0.05).timeout

func arena_completed():
	print("Tutorial arena complete!")
	emit_signal("tutorial_complete")
