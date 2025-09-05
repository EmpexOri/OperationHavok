extends SuperGrenade
class_name NovaGrenade

@export var nova_explosion_scene: PackedScene
@export var nova_dot_damage: float = 5.0
@export var nova_dot_duration: float = 10.0
@export var nova_instant_damage: float = 10.0
@export var debug_nova: bool = true

# Unique sounds
@export var throw_sound: AudioStream = preload("res://Assets/Sound/SFX/WeaponSFX/Grenade/GrenadeToss.mp3")
@export var land_sound: AudioStream = preload("res://Assets/Sound/SFX/WeaponSFX/Grenade/GrenadeLanding.mp3")
@export var explosion_sound: AudioStream = preload("res://Assets/Sound/SFX/WeaponSFX/Grenade/TyphoonBoom.wav")

var has_landed: bool = false
var land_sound_played: bool = false

func _ready():
	# Call parent setup
	super._ready()

	# Play toss sound on spawn
	if throw_sound:
		GlobalAudioController.PlayFromPlayerSFX(throw_sound)

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
		# Play land sound once
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

	# Slow grenade movement
	velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)

func _explode():
	if exploding:
		return
	exploding = true
	velocity = Vector2.ZERO

	# Play land sound if not already played
	if land_sound and not land_sound_played:
		GlobalAudioController.PlayFromPlayerSFX(land_sound)
		land_sound_played = true

	# Do Nova’s unique explosion effects
	_do_explosion_effects()

	# Play unique explosion sound
	if explosion_sound:
		GlobalAudioController.PlayFromPlayerSFX(explosion_sound)

func _do_explosion_effects():
	if debug_nova:
		print("[NovaGrenade] explode @", global_position, 
			" radius=", explosion_radius, 
			" instant=", nova_instant_damage, 
			" dot=", nova_dot_damage, "x", nova_dot_duration)

	if nova_explosion_scene:
		var nova = nova_explosion_scene.instantiate()
		get_parent().add_child(nova)
		nova.global_position = global_position

		var mask := 0
		var layer := 0
		if has_node("Area2D"):
			mask = $Area2D.collision_mask
			layer = $Area2D.collision_layer
		if debug_nova:
			print("[NovaGrenade] using Area2D mask=", mask, " layer=", layer)

		if "setup" in nova:
			nova.setup(nova_instant_damage, nova_dot_damage, nova_dot_duration, explosion_radius, mask)
	else:
		push_warning("[NovaGrenade] nova_explosion_scene NOT assigned")

	# visuals
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	explosion_anim.visible = true
	explosion_anim.frame = 0
	explosion_anim.play("explode")
