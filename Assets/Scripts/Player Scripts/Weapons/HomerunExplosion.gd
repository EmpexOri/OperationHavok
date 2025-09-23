extends Node2D
class_name HomeRunExplosion

@export var damage: float = 20.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var explosion_sound: AudioStream = preload("res://Assets/Sound/SFX/WeaponSFX/Grenade/GrenadeExplosion.mp3")

func _ready() -> void:
	await get_tree().process_frame  # wait one frame to ensure children are ready
	var area := $Area2D
	if area == null:
		push_error("Area2D child not found!")
		return
	_apply_damage(area)
	anim.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	if explosion_sound:
		ScreenShake.shake(4, 0.5)
		GlobalAudioController.PlayFromPlayerSFX(explosion_sound)
		
	anim.play()

func _apply_damage(area: Area2D) -> void:
	await get_tree().physics_frame
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Enemy") and body.has_method("deal_damage"):
			body.deal_damage(damage, global_position)

func _on_animation_finished() -> void:
	queue_free()
