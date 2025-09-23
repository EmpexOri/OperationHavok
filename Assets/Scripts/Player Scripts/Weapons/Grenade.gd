extends SuperGrenade
class_name Grenade

# Assign audio streams in inspector or preload them here
@export var throw_sound: AudioStream = preload("res://Assets/Sound/SFX/WeaponSFX/Grenade/GrenadeToss.mp3")
@export var land_sound: AudioStream = preload("res://Assets/Sound/SFX/WeaponSFX/Grenade/GrenadeLanding.mp3")
@export var explosion_sound: AudioStream = preload("res://Assets/Sound/SFX/WeaponSFX/Grenade/GrenadeExplosion.mp3")

var has_landed: bool = false
var land_sound_played: bool = false

func _ready():
	super._ready()
	if throw_sound:
		GlobalAudioController.PlayFromPlayerSFX(throw_sound)

# Override movement to detect collisions
func _handle_movement(delta: float):
	var new_position = position + velocity * delta
	var query = PhysicsRayQueryParameters2D.create(position, new_position)
	query.exclude = [self]
	query.collision_mask = 1 << 2

	var space_state = get_world_2d().direct_space_state
	if space_state == null:
		return

	var result = space_state.intersect_ray(query)
	if result:
		if not has_landed:
			has_landed = true
			if land_sound and not land_sound_played:
				GlobalAudioController.PlayFromPlayerSFX(land_sound)
				land_sound_played = true

		velocity = Vector2.ZERO
		position = result.position
		if explode_on_walls:
			_explode()
	else:
		position = new_position

	velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)

func _explode():
	if exploding:
		return
	exploding = true
	velocity = Vector2.ZERO

	if land_sound and not land_sound_played:
		GlobalAudioController.PlayFromPlayerSFX(land_sound)
		land_sound_played = true

	# Explosion visuals and damage
	_do_explosion_effects()

	# Play unique explosion sound
	if explosion_sound:
		ScreenShake.shake(4, 0.5)
		GlobalAudioController.PlayFromPlayerSFX(explosion_sound)

func _do_explosion_effects():
	for body in $Area2D.get_overlapping_bodies():
		if body.is_in_group("Player"):
			continue  # Skip damaging the player
		if body.has_method("deal_damage"):
			body.deal_damage(damage, global_position)

	# Disable monitoring so grenade doesn’t trigger again
	$Area2D.monitoring = false
	$Area2D.set_deferred("monitorable", false)

	# Explosion visuals
	$Sprite2D.visible = false
	explosion_anim.visible = true
	explosion_anim.frame = 0
	explosion_anim.play("explode")

	# Play unique explosion sound for this grenade
	if explosion_sound:
		GlobalAudioController.PlayFromPlayerSFX(explosion_sound)
