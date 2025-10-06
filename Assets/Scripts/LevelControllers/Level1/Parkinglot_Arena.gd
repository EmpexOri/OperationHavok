extends Node2D
signal arena_complete

@export var beta_level_controller_path: NodePath = "/root/World/BetaLevelController"
@export var area_blocker_name: String = "Area_Blocker" # child name of the blocker under this arena

# Enemy Scenes dictionary
var ENEMY_SCENES := {
	"Hordling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Hordling.tscn"),
	"Spewling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Spewling.tscn"),
	"Biomancer": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Biomancer.tscn"),
	"Needling": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Needling.tscn"),
	"Gatling": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Gatling.tscn"),
	"Tumor": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Tumor.tscn"),
}

# Arena state
var arena_active := false
var current_wave := 0
var enemies: Array = []
var spawn_points: Array[Marker2D] = []
var wave_in_progress := false
var wave_ending := false

# Waves data (tweak numbers if desired)
var waves: Array = []

func _ready():
	# Auto-detect Marker2Ds as spawns, but skip the special cinematic marker
	if spawn_points.is_empty():
		for child in get_children():
			if child is Marker2D and child.name != "Spawn5":
				spawn_points.append(child)

	waves = [
		{ "Hordling": 36, "Spewling": 8, "Tumor": 2 },
		{ "Hordling": 48, "Spewling": 12, "Needling": 4, "Biomancer": 2 },
		{ "Hordling": 56, "Spewling": 15, "Needling": 5, "Tumor": 8, "Biomancer": 3 }
	]

func activate_arena():
	if arena_active:
		return
	arena_active = true
	current_wave = 0
	print("Parkinglot Arena activated!")
	
	# Play arena music
	GlobalAudioController.SetLevel1Music("res://Assets/Sound/Music/ConcreteHills.mp3", true)
	
	start_next_wave()

# Spawns the next wave sequentially
func start_next_wave() -> void:
	if not arena_active:
		return

	if current_wave >= waves.size():
		# Arena finished — run completion flow
		arena_completed()
		return

	# Prevent re-entry while in-progress
	if wave_in_progress:
		return

	wave_in_progress = true
	var wave_data = waves[current_wave]
	current_wave += 1
	print("Spawning wave %d..." % current_wave)

	# Spawn all enemies in this wave (await ensures the whole wave finishes spawning before we wait for kills)
	await spawn_wave_enemies(wave_data)

	# Now wait until all enemies are dead
	while enemies.size() > 0:
		# small sleep to avoid busy loop
		await get_tree().create_timer(0.1).timeout

	print("Wave %d cleared!" % current_wave)
	wave_in_progress = false

	# Short delay before starting next wave (gives breathing room)
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
	# return null if none found
	return candidates[randi() % candidates.size()] if not candidates.is_empty() else null

# Instantiate enemy
func spawn_enemy(scene: PackedScene, spawn: Marker2D) -> void:
	var enemy = scene.instantiate()
	enemy.position = spawn.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	enemy.name = "Enemy_%d" % randi()
	enemies.append(enemy)
	add_child(enemy)
	if enemy.has_signal("died"):
		enemy.connect("died", Callable(self, "_on_enemy_died"))
	else:
		# Fallback: if enemy uses queue_free without signaling, keep it simple
		pass

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

# -------------------------
# Completion script + checkpoint update
# -------------------------
func arena_completed() -> void:
	arena_active = false
	GlobalEffects.activate_xp_buff(5000, 5.0)
	print("Parkinglot Arena complete!")

	# Fade out the arena music
	var level1_player = GlobalAudioController.get_node("Music/Level1Soundtrack") as AudioStreamPlayer
	GlobalAudioController.MusicFadeOut(level1_player, 2.5)

	# Wait a moment, then run the breakdown event
	await get_tree().create_timer(0.25).timeout
	await _run_breakdown_event()
	
	var spawn_marker: Marker2D = get_node_or_null("Spawn5") as Marker2D
	if spawn_marker:
		var gatling_scene: PackedScene = ENEMY_SCENES.get("Gatling", null)
		if gatling_scene:
			for i in range(2):
				spawn_enemy(gatling_scene, spawn_marker)
		else:
			push_error("Gatling scene not found in ENEMY_SCENES")
	else:
		push_error("Spawn5 marker not found under %s" % name)
	
	# Set checkpoint after the event
	var controller = get_node_or_null(beta_level_controller_path)
	if controller:
		controller._set_checkpoint("park")
	else:
		push_error("BetaLevelController not found at path: %s" % beta_level_controller_path)
		
	emit_signal("arena_complete")

func _run_breakdown_event() -> void:
	# Find the Spawn5 marker where the cinematic horde should appear
	var spawn_marker: Marker2D = get_node_or_null("Spawn5") as Marker2D
	if spawn_marker == null:
		push_error("Spawn5 marker not found under %s" % name)
		return
	var spawn_center: Vector2 = spawn_marker.global_position

	# Optional: find the blocker so we can remove it after the horde spawns
	var blocker: Node2D = get_node_or_null(area_blocker_name) as Node2D

	# Load the Hordling scene
	var hordling_scene: PackedScene = ENEMY_SCENES.get("Hordling", null) as PackedScene
	if hordling_scene == null:
		push_error("Hordling scene not found in ENEMY_SCENES")
		return

	# Spawn a cinematic swarm of hordlings at Spawn5
	var count: int = 30
	for i in range(count):
		var inst: CharacterBody2D = hordling_scene.instantiate() as CharacterBody2D
		add_child(inst)
		var jitter: Vector2 = Vector2(randf_range(-48, 48), randf_range(-48, 48))
		inst.global_position = spawn_center + jitter
		inst.name = "EventHordling_%d" % i

		# Track and connect signals so arena logic can clean them up if needed
		enemies.append(inst)
		if inst.has_signal("died"):
			inst.connect("died", Callable(self, "_on_enemy_died"))

		# Stagger spawn slightly to reduce lag and make them appear more natural
		await get_tree().create_timer(randf_range(0.05, 0.15)).timeout

		# Small stagger for visual effect
		await get_tree().create_timer(0.05).timeout

	# After all Hordlings are spawned, remove the blocker with a short delay
	await get_tree().create_timer(3.5).timeout
	# After all Hordlings are spawned, remove the blocker with a short delay
	await get_tree().create_timer(0.25).timeout
	if blocker:
		# Spawn the explosion effect at the blocker's position
		var explosion_scene: PackedScene = preload("res://Prefabs/CodePrefabs/Particles/RocketExplosion.tscn")
		var explosion_instance: Node2D = explosion_scene.instantiate() as Node2D
		explosion_instance.global_position = blocker.global_position
		get_parent().add_child(explosion_instance)  # or add to self if you prefer
		
		# Remove the blocker safely
		blocker.call_deferred("queue_free")

# -------------------------
# Resetting the arena
# -------------------------
func reset_arena() -> void:
	print("Resetting Parkinglot arena: %s" % self.name)

	# Stop any active logic
	wave_in_progress = false
	wave_ending = false
	current_wave = 0
	arena_active = false

	# Delete all alive enemies spawned by this arena
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			e.queue_free()
	enemies.clear()

	# Refresh spawn points if necessary
	spawn_points.clear()
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
