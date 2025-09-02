extends SuperGrenade
class_name NovaGrenade

@export var nova_explosion_scene: PackedScene
@export var nova_dot_damage: float = 5.0
@export var nova_dot_duration: float = 10.0
@export var nova_instant_damage: float = 10.0
@export var debug_nova: bool = true

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

	# visuals/audio (same as base)
	if has_node("Sprite2D"): $Sprite2D.visible = false
	explosion_anim.visible = true
	explosion_anim.frame = 0
	explosion_anim.play("explode")
	GlobalAudioController.PlayGrenadeExplosion()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if debug_nova:
			print("[NovaGrenade] impact with Enemy:", body.name, " -> explode now")
		velocity = Vector2.ZERO
		_explode()
