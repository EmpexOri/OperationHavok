extends Node2D
signal arena_complete

@export var beta_level_controller_path: NodePath = "/root/World/BetaLevelController"
@export var area_blocker_name: String = "Stripmall_Blocker"

# Enemy prefabs
var ENEMY_SCENES := {
	"Hordling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Hordling.tscn"),
	"Spewling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Spewling.tscn"),
	"Biomancer": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Biomancer.tscn"),
	"Needling": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Needling.tscn"),
	"Gatling": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Gatling.tscn"),
	"Tumor": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Tumor.tscn"),
	"Network": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Network.tscn"),
	"Goolum": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Goolum.tscn"),
	"Warmachine": preload("res://Prefabs/GamePrefabs/Enemy/Minibosses/Warmachine.tscn"),
}

var arena_active := false
var current_wave := 0
var enemies: Array = []
var spawn_points: Array[Marker2D] = []
var wave_in_progress := false

var waves: Array = []

func _ready() -> void:
	if spawn_points.is_empty():
		for child in get_children():
			if child is Marker2D:
				spawn_points.append(child)

	# Wave 1 and 2 normal waves, Wave 3 is boss wave handled separately
	waves = [
		{ "Hordling": [2,6,3], "Spewling": [2,6,1], "Needling": [2,6,1], "Biomancer": [1,6,1], "Gatling": [2,6,2], "Tumor": [1,6,2], "Network": [1,3,1] },
		{ "Hordling": [3,6,3], "Spewling": [2,6,3], "Needling": [2,6,2], "Biomancer": [2,6,1], "Gatling": [2,6,4], "Tumor": [2,6,2], "Network": [1,3,1] },
		{ "Warmachine": 1 } # Wave 3 boss wave
	]

func activate_arena() -> void:
	if arena_active: return
	arena_active = true
	current_wave = 0
	print("Stripmall Arena activated!")
	GlobalAudioController.SetLevel1Music("res://Assets/Sound/Music/ConcreteHills.mp3", true)
	start_next_wave()

func start_next_wave() -> void:
	if not arena_active or wave_in_progress:
		return

	if current_wave >= waves.size():
		arena_completed()
		return

	wave_in_progress = true
	var wave_data = waves[current_wave]
	current_wave += 1
	print("Spawning Stripmall wave %d..." % current_wave)
	await spawn_wave_enemies(wave_data)

	# Boss wave special logic
	if wave_data.has("Warmachine"):
		var boss = enemies[-1] # assume last spawned is boss
		call_deferred("_spawn_minions_during_boss", boss)
		return

	# Wait until all enemies die before starting next wave
	while enemies.size() > 0:
		await get_tree().create_timer(0.1).timeout

	wave_in_progress = false
	start_next_wave()

func spawn_wave_enemies(data: Dictionary) -> void:
	var camera = get_viewport().get_camera_2d()
	for enemy_type in data.keys():
		var roll_data = data[enemy_type]
		var count: int
		if typeof(roll_data) == TYPE_ARRAY and roll_data.size() == 3:
			count = roll(roll_data[0], roll_data[1]) + roll_data[2]
		else:
			count = int(roll_data)
		var scene = ENEMY_SCENES.get(enemy_type, null)
		if scene == null: continue
		for i in range(count):
			var spawn = get_random_spawn_outside_camera(camera)
			if spawn:
				spawn_enemy(scene, spawn)
			await get_tree().create_timer(randf_range(0.05, 0.25)).timeout

func _spawn_minions_during_boss(boss: Node2D) -> void:
	while is_instance_valid(boss) and boss.is_inside_tree():
		var minion_type = ["Hordling", "Spewling", "Needling", "Goolum"][randi() % 4]
		var scene = ENEMY_SCENES[minion_type]
		var spawn = spawn_points[randi() % spawn_points.size()]
		spawn_enemy(scene, spawn)
		await get_tree().create_timer(randf_range(1.0, 2.0)).timeout

	arena_completed()

func spawn_enemy(scene: PackedScene, spawn: Marker2D) -> void:
	var enemy = scene.instantiate()
	enemy.position = spawn.global_position + Vector2(randf_range(-8,8), randf_range(-8,8))
	enemy.name = "Enemy_%d" % randi()
	enemies.append(enemy)
	add_child(enemy)
	if enemy.has_signal("died"):
		enemy.connect("died", Callable(self, "_on_enemy_died"))

func _on_enemy_died(enemy):
	enemies.erase(enemy)

func get_random_spawn_outside_camera(camera: Camera2D) -> Marker2D:
	var candidates := []
	for sp in spawn_points:
		if is_position_behind_camera(camera, sp.global_position):
			candidates.append(sp)
	return candidates[randi() % candidates.size()] if not candidates.is_empty() else null

func roll(dice:int, sides:int) -> int:
	var total = 0
	for i in range(dice):
		total += randi_range(1, sides)
	return total

func is_position_behind_camera(camera: Camera2D, position: Vector2) -> bool:
	if not camera: return true
	var rect = get_viewport().get_visible_rect()
	var half = rect.size * 0.5 * camera.zoom
	var center = camera.global_position
	var tl = center - half
	var br = center + half
	return not (position.x >= tl.x and position.x <= br.x and position.y >= tl.y and position.y <= br.y)

func arena_completed() -> void:
	arena_active = false
	GlobalEffects.activate_xp_buff(6000, 6.0)
	print("Stripmall Arena complete!")

	var controller = get_node_or_null(beta_level_controller_path)
	if controller:
		controller._set_checkpoint("stripmall")
	else:
		push_error("BetaLevelController not found at path: %s" % beta_level_controller_path)

	emit_signal("arena_complete")

func reset_arena() -> void:
	wave_in_progress = false
	current_wave = 0
	arena_active = false
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			e.queue_free()
	enemies.clear()
	spawn_points.clear()
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
