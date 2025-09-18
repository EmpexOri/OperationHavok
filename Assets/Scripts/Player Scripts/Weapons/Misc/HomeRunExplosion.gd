extends SuperGrenade
class_name HomeRunExplosion2

# Assign audio streams in inspector or preload them here
@export var explosion_sound: AudioStream = preload("res://Assets/Sound/SFX/WeaponSFX/Grenade/TyphoonBoom.wav")

var has_landed: bool = false
var land_sound_played: bool = false

func _ready():
	# Call parent _ready so all explosion logic still works
	super._ready()

func _explode():
	if exploding:
		return
	exploding = true
	velocity = Vector2.ZERO

	# Explosion visuals and damage
	_do_explosion_effects()

	# Play unique explosion sound
	if explosion_sound:
		GlobalAudioController.PlayFromPlayerSFX(explosion_sound)
