extends Node2D
signal arena_complete

@export var beta_level_controller_path: NodePath = "/root/World/BetaLevelController"
@export var area_blocker_name: String = "Area_Blocker"

# Enemy Scenes dictionary
var ENEMY_SCENES := {
	"Hordling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Hordling.tscn"),
	"Spewling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Spewling.tscn"),
	"Biomancer": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Biomancer.tscn"),
	"Needling": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Needling.tscn"),
	"Gatling": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Gatling.tscn"),
	"Tumor": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Tumor.tscn"),
}

var arena_active := false
var current_wave := 0
var enemies: Array = []
var spawn_points: Array[Marker2D] = []
var wave_in_progress := false
var wave_ending := false

var waves: Array = []

func _ready():
	if spawn_points.is_empty():
		for child in get_children():
			if child is Marker2D:
				spawn_points.append(child)

	waves = [
		{ "Hordling": 10, "Spewling": 4 },
		{ "Hordling": 12, "Spewling": 6, "Needling": 2 },
		{ "Hordling": 14, "Spewling": 6, "Biomancer": 1, "Gatling": 1 }
	]

func activate_arena():
	if arena_active: return
	arena_active = true
	current_wave = 0
	print("Park Arena activated!")
	GlobalAudioController.SetLevel1Music("res://Assets/Sound/Music/DoomWaterPark.mp3", true)
	start_next_wave()

func start_next_wave() -> void:
	if not arena_active or wave_in_progress: return
	if current_wave >= waves.size():
		arena_completed()
		return

	wave_in_progress = true
	var wave_data = waves[current_wave]
	current_wave += 1
	print("Spawning Park wave %d..." % current_wave)
	await spawn_wave_enemies(wave_data)

	while enemies.size() > 0:
		await get_tree().create_timer(0.1).timeout

	print("Wave %d cleared!" % current_wave)
	wave_in_progress = false
	await get_tree().create_timer(0.5).timeout
	start_next_wave()

func spawn_wave_enemies(data: Dictionary) -> void:
	var camera = get_viewport().get_camera_2d()
	for enemy_type in data.keys():
		var count = data[enemy_type]
		var scene = ENEMY_SCENES.get(enemy_type, null)
		if scene == null: continue
		for i in range(count):
			var spawn = get_random_spawn_outside_camera(camera)
			if spawn:
				spawn_enemy(scene, spawn)
			await get_tree().create_timer(randf_range(0.05, 0.25)).timeout

func get_random_spawn_outside_camera(camera: Camera2D) -> Marker2D:
	var candidates := []
	for sp in spawn_points:
		if is_position_behind_camera(camera, sp.global_position):
			candidates.append(sp)
	return candidates[randi() % candidates.size()] if not candidates.is_empty() else null

func spawn_enemy(scene: PackedScene, spawn: Marker2D) -> void:
	var enemy = scene.instantiate()
	enemy.position = spawn.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	enemy.name = "Enemy_%d" % randi()
	enemies.append(enemy)
	add_child(enemy)
	if enemy.has_signal("died"):
		enemy.connect("died", Callable(self, "_on_enemy_died"))

func _on_enemy_died(enemy):
	enemies.erase(enemy)

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
	print("Park Arena complete!")

	var level1_player = GlobalAudioController.get_node("Music/Level1Soundtrack") as AudioStreamPlayer
	GlobalAudioController.MusicFadeOut(level1_player, 2.5)

	await get_tree().create_timer(0.25).timeout
	await _run_breakdown_event()

	# *** Set checkpoint to Respawn_Park ***
	var controller = get_node_or_null(beta_level_controller_path)
	if controller:
		controller._set_checkpoint("park")
	else:
		push_error("BetaLevelController not found at path: %s" % beta_level_controller_path)

	emit_signal("arena_complete")

func _run_breakdown_event() -> void:
	var blocker: Node2D = get_node_or_null(area_blocker_name) as Node2D
	if blocker:
		var explosion_scene: PackedScene = preload("res://Prefabs/CodePrefabs/Particles/RocketExplosion.tscn")
		var explosion_instance: Node2D = explosion_scene.instantiate() as Node2D
		explosion_instance.global_position = blocker.global_position
		get_parent().add_child(explosion_instance)
		blocker.call_deferred("queue_free")

func reset_arena() -> void:
	print("Resetting Park arena: %s" % name)
	wave_in_progress = false
	wave_ending = false
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
