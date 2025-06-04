extends CharacterBody2D

const HORDLING = preload("res://Prefabs/GamePrefabs/Enemy/Hordling.tscn")

@onready var particles := $Explosion/Particles
@onready var spawn_point := $SpawnPoint

func handle_arena_completion():
	print("RoadBlock activated!")
	await spawn_hordlings()
	queue_free()  

func spawn_hordlings():
	for i in range(60):
		await get_tree().create_timer(randf_range(0.05, 0.1)).timeout
		
		var enemy = HORDLING.instantiate()
		enemy.position = spawn_point.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		enemy.name = "RB_Hordling_%d" % i
		get_tree().current_scene.add_child(enemy)
		
		if i == 3:
			GlobalAudioController.PlayMetalCreak()
		if i == 4:  # Start particles after the 5th Hordling, just makes the particles look better
			particles.emitting = true
