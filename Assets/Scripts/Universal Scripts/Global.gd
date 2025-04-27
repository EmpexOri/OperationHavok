extends Node

var DeathParticles = preload("res://Prefabs/Particles/DeathGore.tscn")

func spawn_death_particles(position: Vector2):
	var particle_instance = DeathParticles.instantiate()
	particle_instance.global_position = position
	get_tree().current_scene.add_child(particle_instance)

	# Access the CPUParticles2D node inside the scene
	var particles = particle_instance.get_node("Particles")
	particles.emitting = true

	# Free after its lifetime
	await get_tree().create_timer(particles.lifetime + 0.5).timeout
	if is_instance_valid(particle_instance):
		particle_instance.queue_free()

func spawn_blood_splatter(position: Vector2):
	var blood_sprite = Sprite2D.new()
	blood_sprite.texture = preload("res://Assets/Art/PlaceHolders/Splat.png") 
	blood_sprite.position = position
	blood_sprite.z_index = -2  # Ensure the blood sprite is drawn on top of the TileMap
	get_tree().current_scene.add_child(blood_sprite)

func spawn_meat_chunk(position: Vector2):
	var meat_scene = preload("res://Prefabs/Particles/MeatChunks.tscn")
	var num_chunks = randi_range(3, 12)

	for i in range(num_chunks):
		var meat_chunk = meat_scene.instantiate()
		meat_chunk.global_position = position
		meat_chunk.z_index = -1  # Still draw it below
		# You don't need to manually apply forces anymore!
		get_tree().current_scene.add_child(meat_chunk)

const MAX_BLOOD_SMEARS = 1000
var active_smeares := []

func register_smear(smear):
	active_smeares.append(smear)
	if active_smeares.size() > MAX_BLOOD_SMEARS:
		var oldest = active_smeares.pop_front()
		if oldest.is_inside_tree():
			oldest.queue_free()

func unregister_smear(smear):
	active_smeares.erase(smear)
