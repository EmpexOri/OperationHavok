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
	"WarmachineRocket": preload("res://Prefabs/GamePrefabs/Enemy/Minibosses/Warmachine_Rocket.tscn"),
}

var arena_active := false
var current_wave := 0
var enemies: Array = []
var spawn_points: Array[Marker2D] = []
var boss_spawn: Marker2D
var wave_in_progress := false

var waves: Array = []

const BOSS_MINION_CAP := 80

var extra_spawn_points_enabled := false
@onready var arena_blockers: Node2D = $Arena_Blockers
@export var explosion_scene: PackedScene = preload("res://Prefabs/CodePrefabs/Particles/RocketExplosion.tscn")

func _ready() -> void:
	if spawn_points.is_empty():
		var index := 0
		for child in get_children():
			if child is Marker2D:
				if child.name == "SpawnBoss":
					boss_spawn = child
				else:
					index += 1
					child.set_meta("index", index)
					spawn_points.append(child)

	# Wave 1 and 2 normal waves, Wave 3 is boss wave handled separately
	waves = [
		#{ "Hordling": [2,6,3], "Spewling": [2,6,1], "Needling": [2,6,1], "Biomancer": [1,6,1], "Gatling": [2,6,2], "Tumor": [1,6,2], "Network": [1,3,1] },
		#{ "Hordling": [3,6,3], "Spewling": [2,6,3], "Needling": [2,6,2], "Biomancer": [2,6,1], "Gatling": [2,6,4], "Tumor": [2,6,2], "Network": [1,3,1] },
		{ "Warmachine": 1, "WarmachineRocket": 1 } 
	]

func activate_arena() -> void:
	if arena_active:
		return
	arena_active = true
	current_wave = 0
	enemies.clear()
	print("Stripmall Arena activated!")
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
	spawn_wave_enemies(wave_data)

	# Boss wave special logic
	if wave_data.has("Warmachine") and wave_data.has("WarmachineRocket"):
		var warmachine_gun = get_tree().get_first_node_in_group("WarmachineGun")
		var warmachine_rocket = get_tree().get_first_node_in_group("WarmachineRocket")

		if warmachine_gun and warmachine_rocket:
			GlobalAudioController.SetLevel1Music(
				"res://Assets/Sound/Music/Lux_Target_Loops.mp3", true
			)
			
			_remove_arena_blockers()
			extra_spawn_points_enabled = true
			
			if warmachine_gun.has_signal("died"):
				warmachine_gun.connect("died", Callable(self, "_on_boss_died"))
			if warmachine_rocket.has_signal("died"):
				warmachine_rocket.connect("died", Callable(self, "_on_boss_died"))
				
			call_deferred("_spawn_minions_during_boss_duo", [warmachine_gun, warmachine_rocket])
		else:
			push_error("Warmachine duo not found correctly after spawn.")
		return

	while enemies.size() > 0:
		await get_tree().create_timer(0.1).timeout

	wave_in_progress = false
	start_next_wave()
	
func _remove_arena_blockers() -> void:
	if arena_blockers and is_instance_valid(arena_blockers):
		for blocker in arena_blockers.get_children():
			if is_instance_valid(blocker):
				# Spawn explosion at the blocker position
				if explosion_scene:
					var explosion = explosion_scene.instantiate()
					explosion.position = blocker.global_position
					get_parent().add_child(explosion)
					
				blocker.queue_free()
				
		arena_blockers.queue_free()
		arena_blockers = null
		print("Arena blockers fully cleared with explosions!")
	else:
		pass

func spawn_wave_enemies(data: Dictionary) -> void:
	var camera = get_viewport().get_camera_2d()
	for enemy_type in data.keys():
		var roll_data = data[enemy_type]
		var count: int

		if typeof(roll_data) == TYPE_ARRAY:
			var min_val = roll_data[0]
			var max_val = roll_data[1]
			var mult = roll_data[2]
			count = randi_range(min_val, max_val) * mult
		else:
			count = int(roll_data)

		var scene = ENEMY_SCENES.get(enemy_type, null)
		if scene == null:
			continue

		for i in range(count):
			var spawn: Marker2D
			if (enemy_type == "Warmachine" or enemy_type == "WarmachineRocket") and boss_spawn:
				spawn = boss_spawn
			else:
				spawn = get_random_spawn_outside_camera(camera)

			if spawn:
				spawn_enemy(scene, spawn)

			if enemy_type not in ["Warmachine", "WarmachineRocket"]:
				await get_tree().create_timer(randf_range(0.05, 0.25)).timeout

func _spawn_minions_during_boss_duo(bosses: Array) -> void:
	var start_time := Time.get_ticks_msec() / 1000.0
	var base_delay := 2.0
	var min_delay := 0.5
	var base_batch := 1
	var max_batch := 5
 
	var weighted_pool: Array[String] = []
	for i in range(70): weighted_pool.append("Hordling")
	for i in range(15): weighted_pool.append("Spewling")
	var others := []
	for k in ENEMY_SCENES.keys():
		if k not in ["Warmachine","WarmachineRocket","Hordling","Spewling"]:
			others.append(k)
	for i in range(15):
		weighted_pool.append(others[randi() % others.size()])

	var camera := get_viewport().get_camera_2d()

	while true:
		bosses = bosses.filter(func(b): return is_instance_valid(b) and b.is_inside_tree())
		if bosses.is_empty():
			break

		var elapsed := (Time.get_ticks_msec() / 1000.0) - start_time
		var current_batch: int = clamp(base_batch + int(elapsed / 20.0), base_batch, max_batch)
		var current_delay: float = max(base_delay - elapsed * 0.02, min_delay)

		if enemies.size() < BOSS_MINION_CAP:
			for i in range(current_batch):
				if enemies.size() >= BOSS_MINION_CAP:
					break
				var pick := weighted_pool[randi() % weighted_pool.size()]
				var count := 1
				if pick in ["Hordling","Spewling"]:
					count = randi_range(3,5)
				var scene: PackedScene = ENEMY_SCENES[pick]
				for j in range(count):
					if enemies.size() >= BOSS_MINION_CAP:
						break
					var spawn := get_random_spawn_outside_camera(camera)
					if spawn:
						spawn_enemy(scene, spawn)
						await get_tree().create_timer(randf_range(0.05, 0.15)).timeout

		await get_tree().create_timer(current_delay).timeout

	# cleanup after duo death
	while enemies.size() > 0:
		for e in enemies:
			if is_instance_valid(e) and e.is_inside_tree():
				e.queue_free()
		enemies.clear()
		await get_tree().create_timer(0.1).timeout

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
		var index: int = int(sp.get_meta("index", 1))
		if not extra_spawn_points_enabled and index > 2:
			continue
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
	_on_cutscene_start()

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

func _on_boss_died(boss: Node) -> void:
	# Remove boss if tracked
	enemies.erase(boss)

	# Check both groups
	var gun_alive = get_tree().get_first_node_in_group("WarmachineGun")
	var rocket_alive = get_tree().get_first_node_in_group("WarmachineRocket")

	if not gun_alive and not rocket_alive:
		# Both bosses are dead → cleanup + complete
		print("Warmachine duo defeated!")
		_cleanup_after_boss_duo()
		arena_completed()
		
func _cleanup_after_boss_duo() -> void:
	# Trigger proper death logic for all remaining enemies
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			if e.has_method("on_death"):
				e.on_death()  # Let the enemy handle its death logic
			else:
				e.queue_free()  # Fallback if no death handler exists, or I cant find it

	enemies.clear()

# CUTSCENE STUFF
func _on_cutscene_start() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		push_error("Player not found for cutscene sequence!")
		return
		
	# Lock all player controls
	player.LockAllControls = true
	player.LockMovement = true
	player.LockShooting = true
	player.LockAbilities = true
	player.LockDodging = true
	
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if not camera:
		push_error("Camera not found on Player!")
		return
		
	# Get the blackout sprite on the camera
	var blackout_sprite: Sprite2D = camera.get_node_or_null("BlackoutSprite")
	if not blackout_sprite:
		push_error("BlackoutSprite not found on Camera2D!")
		return
		
	blackout_sprite.visible = true
	blackout_sprite.modulate.a = 0.0
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(blackout_sprite, "modulate:a", 1.0, 0.25)
	await fade_in.finished
	
	var target_pos = Vector2(1656, 1417)
	var cam_tween = get_tree().create_tween()
	cam_tween.tween_property(camera, "global_position", target_pos, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await cam_tween.finished
	
	await get_tree().create_timer(0.25).timeout
	
	# pawn the cutscene scene while still blacked out
	_spawn_cutscene_scene()
	
	# Fade out blackout after cutscene spawns
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(blackout_sprite, "modulate:a", 0.0, 0.25)
	await fade_out.finished

func _spawn_cutscene_scene() -> void:
	var level1_player = GlobalAudioController.get_node("Music/Level1Soundtrack") as AudioStreamPlayer
	GlobalAudioController.MusicFadeOut(level1_player, 2.5)
	var cutscene_scene: PackedScene = preload("res://Prefabs/Cutscenes/BossDeath_LevelBeta.tscn")
	if not cutscene_scene:
		push_error("Cutscene scene not found!")
		_transition_to_level_finish()
		return
		
	var cutscene_instance = cutscene_scene.instantiate()
	get_tree().current_scene.add_child(cutscene_instance)
	
	# Position cutscene at camera target
	var target_pos = Vector2(1656, 1417)
	cutscene_instance.global_position = target_pos
	print("Cutscene started at position:", target_pos)
	
	# Await the cutscene_finished signal
	if cutscene_instance.has_signal("cutscene_finished"):
		await cutscene_instance.cutscene_finished
		print("Cutscene finished signal received.")
	else:
		print("Couldnt Get Signal")
		#await get_tree().create_timer(6.0).timeout
		
	_transition_to_level_finish()

func _transition_to_level_finish() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.LockAllControls = true
		
	print("Transitioning to LevelFinish scene...")
	
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if not camera:
		push_error("Camera not found for level finish fade!")
		get_tree().change_scene_to_file("res://Scenes/Beta/LevelFinished.tscn")
		return
		
	var blackout_sprite: Sprite2D = camera.get_node_or_null("BlackoutSprite")
	if not blackout_sprite:
		push_error("BlackoutSprite not found on Camera2D!")
		get_tree().change_scene_to_file("res://Scenes/Beta/LevelFinished.tscn")
		return
	blackout_sprite.visible = true
	blackout_sprite.modulate.a = 0.0
	
	# Fade in the blackout
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(blackout_sprite, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_tween.finished
	
	var level_music: AudioStreamPlayer = GlobalAudioController.get_node("Music/Level1Soundtrack") as AudioStreamPlayer
	if level_music:
		GlobalAudioController.MusicFadeOut(level_music, 2.5)
		
	get_tree().change_scene_to_file("res://Scenes/Beta/LevelFinished.tscn")
