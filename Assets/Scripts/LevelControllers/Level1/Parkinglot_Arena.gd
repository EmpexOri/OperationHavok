extends Node2D
signal arena_complete

@export var beta_level_controller_path: NodePath = "/root/World/BetaLevelController"
@export var rooftop_elevator: NodePath  # optional for next level access

# Enemy Scenes dictionary
var ENEMY_SCENES := {
	"Hordling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Hordling.tscn"),
	"Spewling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Spewling.tscn"),
	"Biomancer": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Biomancer.tscn"),
	"Needling": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Needling.tscn"),
	"Tumor": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Tumor.tscn"),
}

# Arena state
var arena_active := false
var current_wave := 0
var enemies: Array = []
var spawn_points: Array[Marker2D] = []
var wave_in_progress := false
var wave_ending := false

# Waves data
var waves: Array = []

func _ready():
	# Auto-detect Marker2Ds as spawns
	if spawn_points.size() == 0:
		for child in get_children():
			if child is Marker2D:
				spawn_points.append(child)

	waves = [
		{ "Hordling": 12, "Spewling": 5, "Tumor": 1 },
		{ "Hordling": 12, "Spewling": 5, "Needling": 2 },
		{ "Hordling": 15, "Spewling": 3, "Needling": 2, "Tumor": 2 }
	]

func activate_arena():
	if arena_active:
		return
	arena_active = true
	current_wave = 0
	print("Parkinglot Arena activated!")
	start_next_wave()

# Spawns the next wave sequentially
func start_next_wave() -> void:
	if current_wave >= waves.size():
		print("Parkinglot Arena complete!")
		arena_active = false
		emit_signal("arena_complete")
		var controller = get_node_or_null(beta_level_controller_path)
		if controller:
			controller._set_checkpoint("Parkinglot_Area")
		return

	wave_in_progress = true
	var wave_data = waves[current_wave]
	current_wave += 1
	print("Spawning wave %d..." % current_wave)

	# Spawn all enemies in this wave
	await spawn_wave_enemies(wave_data)

	# Now wait until all enemies die
	while enemies.size() > 0:
		await get_tree().create_timer(0.1).timeout

	print("Wave %d cleared!" % current_wave)
	wave_in_progress = false

	# Short delay before starting next wave
	await get_tree().create_timer(0.5).timeout
	start_next_wave()

# Spawn enemies in a wave
func spawn_wave_enemies(data: Dictionary) -> void:
	var camera = get_viewport().get_camera_2d()
	for enemy_type in data.keys():
		var count = data[enemy_type]
		var scene = ENEMY_SCENES.get(enemy_type, null)
		if scene == null:
			continue

		for i in range(count):
			var spawn = get_random_spawn_outside_camera(camera)
			if spawn:
				spawn_enemy(scene, spawn)
			# Slight stagger between spawns for readability
			await get_tree().create_timer(randf_range(0.05, 0.25)).timeout

# Get a random spawn that is outside the camera view
func get_random_spawn_outside_camera(camera: Camera2D) -> Marker2D:
	var candidates := []
	for sp in spawn_points:
		if is_position_behind_camera(camera, sp.global_position):
			candidates.append(sp)
	return candidates[randi() % candidates.size()] if candidates.size() > 0 else null

# Instantiate enemy
func spawn_enemy(scene: PackedScene, spawn: Marker2D) -> void:
	var enemy = scene.instantiate()
	enemy.position = spawn.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	enemy.name = "Enemy_%d" % randi()
	enemies.append(enemy)
	add_child(enemy)
	enemy.connect("died", Callable(self, "_on_enemy_died"))

func _on_enemy_died(enemy):
	enemies.erase(enemy)

# Check if position is outside camera view
func is_position_behind_camera(camera: Camera2D, position: Vector2) -> bool:
	if not camera:
		return true

	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	var half_screen = screen_size * 0.5 * camera.zoom
	var cam_center = camera.global_position
	var rect_top_left = cam_center - half_screen
	var rect_bottom_right = cam_center + half_screen

	return not (position.x >= rect_top_left.x and position.x <= rect_bottom_right.x
				and position.y >= rect_top_left.y and position.y <= rect_bottom_right.y)

func reset_arena():
	wave_in_progress = false
	wave_ending = false
	current_wave = 0
	arena_active = false

	for e in enemies:
		if e.is_inside_tree():
			e.queue_free()
	enemies.clear()

	# Refresh spawn points if necessary
	spawn_points.clear()
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
