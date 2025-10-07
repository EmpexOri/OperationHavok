extends CharacterBody2D
class_name TrashCan

@export var max_health: int = 20
var Health: int = max_health
@onready var sprite: Sprite2D = $Sprite2D
@export var destroyed_texture: Texture2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@export var destruction_particles_scene: PackedScene  

func _ready() -> void:
	add_to_group("Damageable")

func deal_damage(amount: int, from_pos: Vector2 = Vector2.ZERO) -> void:
	Health -= amount
	flash_hit()
	if Health <= 0:
		break_apart()

func flash_hit() -> void:
	if not sprite:
		return
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)

func break_apart() -> void:
	# Disable collision safely
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Swap sprite to destroyed version
	if destroyed_texture:
		sprite.texture = destroyed_texture
	
	# Spawn destruction particles
	if destruction_particles_scene:
		call_deferred("_spawn_destruction_particles")

func _spawn_destruction_particles():
	GlobalAudioController.play_general_sfx("res://Assets/Sound/SFX/Misc/TrashExplosion.wav")
	var particles = destruction_particles_scene.instantiate()
	add_child(particles)
	particles.global_position = global_position

	for pfx in particles.get_children():
		if pfx is GPUParticles2D:
			pfx.one_shot = true
			pfx.emitting = true
