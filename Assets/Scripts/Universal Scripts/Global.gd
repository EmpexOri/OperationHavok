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
	var num_chunks = randi_range(1, 4)

	for i in range(num_chunks):
		var meat_chunk = meat_scene.instantiate()
		meat_chunk.global_position = position
		meat_chunk.z_index = -1  # Draw below other game elements
		meat_chunk.gravity_scale = 0  # For top-down games

		# Ensure it's a RigidBody2D (for physics-based movement)
		if meat_chunk is RigidBody2D:
			# Apply physics force/torque deferred
			var direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			var force = randf_range(300, 600)
			meat_chunk.apply_impulse(Vector2.ZERO, direction * force)

			# Apply torque impulse
			var torque = randf_range(-50, 50)
			meat_chunk.apply_torque_impulse(torque)

		# Add the meat chunk to the scene
		get_tree().current_scene.add_child(meat_chunk)

		# Auto-despawn via internal timer
		var timer = meat_chunk.get_node("Timer")
		timer.timeout.connect(meat_chunk.queue_free)
		timer.start()
