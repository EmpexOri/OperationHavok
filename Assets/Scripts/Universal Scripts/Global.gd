extends Node

# Preload materials (used only for prewarm trick)
var materials = [
	preload("res://Prefabs/CodePrefabs/Particles/Preloaded/TumourExplosionGore.tres"),
	preload("res://Prefabs/CodePrefabs/Particles/Preloaded/DeathExplosionGore.tres")
]

# Preload particle scenes for instancing
var TumourParticlesScene = preload("res://Prefabs/CodePrefabs/Particles/TumourExplosionGore.tscn")
var DeathParticlesScene = preload("res://Prefabs/CodePrefabs/Particles/DeathGore.tscn")

# Pools for reusing particle nodes
var tumour_particle_pool: Array = []
var death_particle_pool: Array = []

var POOL_SIZE := 128  # Customize based on how many can be active at once

# A global variable for the particle options index
var graphics_quality_index: int = 1 

func _ready() -> void:
	# Prewarm GPU shaders by creating dummy instances briefly
	for material in materials:
		var dummy = GPUParticles2D.new()
		dummy.process_material = material
		dummy.modulate = Color(1, 1, 1, 0)
		dummy.emitting = true
		add_child(dummy)

	# Wait 3 frames before removing dummy nodes
	await get_tree().create_timer(0.05).timeout
	for child in get_children():
		if child is GPUParticles2D:
			child.queue_free()

	# Fill the pools
	_fill_pool(TumourParticlesScene, tumour_particle_pool, POOL_SIZE)
	_fill_pool(DeathParticlesScene, death_particle_pool, POOL_SIZE)

func _fill_pool(scene: PackedScene, pool: Array, count: int) -> void:
	for i in count:
		var instance = scene.instantiate()
		instance.visible = false
		add_child(instance)
		pool.append(instance)

# -- Spawning Logic --

func spawn_death_particles(position: Vector2) -> void:
	_spawn_particles(position, death_particle_pool)

func spawn_tumour_particles(position: Vector2) -> void:
	_spawn_particles(position, tumour_particle_pool)

func _spawn_particles(position: Vector2, pool: Array) -> void:
	var instance: Node2D = null

	for p in pool:
		var particles := p.get_node("Particles") as GPUParticles2D
		if not p.visible and (particles == null or not particles.emitting):
			instance = p
			break  # break only when found

	if instance == null:
		print("No free particles available! Consider increasing POOL_SIZE.")
		return

	instance.global_position = position
	instance.visible = true

	var particles := instance.get_node("Particles") as GPUParticles2D
	particles.emitting = false
	particles.restart()
	particles.emitting = true

	var total_time: float = particles.lifetime + 0.1
	_reset_particle_after_delay(instance, particles, total_time)

# Reset particle after its lifetime expires
func _reset_particle_after_delay(instance: Node2D, particles: GPUParticles2D, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	
	if is_instance_valid(instance):
		# Only hide after next frame to give time for `emitting` flag to stop properly
		await get_tree().process_frame
		particles.emitting = false
		instance.visible = false

func spawn_blood_splatter(position: Vector2):
	SmearCanvas.spawn_smear(position)

func spawn_meat_chunk(position: Vector2):
	var meat_scene = preload("res://Prefabs/CodePrefabs/Particles/MeatChunks.tscn")
	var num_chunks = randi_range(8, 48)

	for i in range(num_chunks):
		var meat_chunk = meat_scene.instantiate()
		meat_chunk.global_position = position
		meat_chunk.z_index = -1
		get_tree().current_scene.call_deferred("add_child", meat_chunk)

# -- Blood Smear Tracking --

var MAX_BLOOD_SMEARS = 4000
var active_smeares := []

func register_smear(smear):
	active_smeares.append(smear)
	if active_smeares.size() > MAX_BLOOD_SMEARS:
		var oldest = active_smeares.pop_front()
		if oldest.is_inside_tree():
			oldest.queue_free()

func unregister_smear(smear):
	active_smeares.erase(smear)

#-- Settings Logic --
func apply_graphics_settings() -> void:
	# Resize particle pools
	_clear_and_refill_pool(tumour_particle_pool, TumourParticlesScene, POOL_SIZE)
	_clear_and_refill_pool(death_particle_pool, DeathParticlesScene, POOL_SIZE)
	print("Reinitialized particle pools to new POOL_SIZE:", POOL_SIZE)

func _clear_and_refill_pool(pool: Array, scene: PackedScene, size: int) -> void:
	# Remove old particles
	for p in pool:
		if is_instance_valid(p):
			p.queue_free()
	pool.clear()
	
	# Refill with new size
	_fill_pool(scene, pool, size)


## Settings Options

const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

var resolution_index := 1
var fullscreen_enabled := false

func apply_display_settings():
	var resolution = RESOLUTIONS[resolution_index]

	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
