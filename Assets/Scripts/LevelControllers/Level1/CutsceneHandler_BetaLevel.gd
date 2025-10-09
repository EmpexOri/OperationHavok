extends Node2D

@export var explosion_scene: PackedScene = preload("res://Prefabs/CodePrefabs/Particles/RocketExplosion.tscn")
@export var explosion_interval: float = 0.25  
@export var cutscene_duration: float = 4.0
@export var explosion_radius: float = 32.0
@export var final_gore_count: int = 30  

signal cutscene_finished

@onready var sprite: Sprite2D = $Sprite2D  # the boss sprite

func _ready() -> void:
	randomize()
	_start_cutscene()

func _start_cutscene() -> void:
	# Start SFX after 1 second, but don't block explosions
	_play_sfx_delayed()
	# Play explosions (this coroutine will run until cutscene_duration ends)
	await _play_explosions()
	# Once explosions are done, play the final death FX
	await _play_final_death_fx()
	
func _play_sfx_delayed() -> void:
	# Use a one-shot timer to delay SFX by 1 second
	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	
	timer.timeout.connect(Callable(self, "_play_boss_death_sfx"))

func _play_boss_death_sfx() -> void:
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.stream = preload("res://Assets/Sound/SFX/DeathSFX/Boss_Death_SFX.wav")
	sfx_player.bus = "SFX"
	sfx_player.volume_db = 5
	add_child(sfx_player)
	sfx_player.play()
	
	var secondary_sfx := AudioStreamPlayer.new()
	secondary_sfx.stream = preload("res://Assets/Sound/SFX/Misc/BigDeath.wav")
	secondary_sfx.bus = "SFX"
	secondary_sfx.volume_db = -5
	add_child(secondary_sfx)
	secondary_sfx.play()
	
	var duration := sfx_player.stream.get_length()
	var cleanup_timer := Timer.new()
	cleanup_timer.wait_time = duration
	cleanup_timer.one_shot = true
	cleanup_timer.autostart = true
	add_child(cleanup_timer)
	cleanup_timer.timeout.connect(func():
		if sfx_player: sfx_player.queue_free()
		if secondary_sfx: secondary_sfx.queue_free()
		cleanup_timer.queue_free()
	)

func _play_explosions() -> void:
	var elapsed := 0.0
	while elapsed < cutscene_duration:
		_spawn_explosion()

		# Spawn a small amount of gore for each explosion
		Global.spawn_death_particles(global_position)

		await get_tree().create_timer(explosion_interval).timeout
		elapsed += explosion_interval

func _spawn_explosion() -> void:
	if not explosion_scene:
		return
	var explosion = explosion_scene.instantiate()
	add_child(explosion)
	explosion.global_position = global_position + Vector2(
		randf_range(-explosion_radius, explosion_radius),
		randf_range(-explosion_radius, explosion_radius)
	)

func _play_final_death_fx() -> void:
	# Massive final gore burst loop
	for i in range(final_gore_count):
		Global.spawn_death_particles(global_position)
		Global.spawn_blood_splatter(global_position)
		Global.spawn_meat_chunk(global_position)
		await get_tree().create_timer(0.05).timeout 

	# Fade out the sprite
	if sprite and sprite.is_inside_tree():
		# Spawn the massive explosion right as fade begins
		var massive_explosion_scene: PackedScene = preload("res://Prefabs/CodePrefabs/Weapons/PlasmaExplosion.tscn")
		if massive_explosion_scene:
			var explosion_instance = massive_explosion_scene.instantiate()
			add_child(explosion_instance)
			explosion_instance.global_position = global_position

		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
		sprite.visible = false

	# Wait 1 second before signaling cutscene finished
	await get_tree().create_timer(0.75).timeout
	emit_signal("cutscene_finished")
