extends Area2D
class_name NovaExplosion

@export var debug_nova: bool = true
@onready var cs: CollisionShape2D = $CollisionShape2D

var instant_damage: float
var dot_damage: float
var dot_duration: float

func setup(instant_dmg: float, dot_dmg: float, dot_dur: float, radius: float, inherit_mask: int = 1 << 3):
	instant_damage = instant_dmg
	dot_damage = dot_dmg
	dot_duration = dot_dur

	# Setup collision shape radius
	if cs and cs.shape is CircleShape2D:
		(cs.shape as CircleShape2D).radius = radius
		cs.disabled = false
	else:
		push_warning("NovaExplosion needs a CircleShape2D")

	collision_mask = inherit_mask
	monitoring = true
	monitorable = true

	await get_tree().physics_frame  # let physics register overlaps
	_apply_damage()

	# Auto cleanup
	await get_tree().create_timer(0.25).timeout
	queue_free()

func _apply_damage():
	for body in get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		if body.is_in_group("Enemy"):
			# Optional: raycast to see if wall is blocking
			var space_state = get_world_2d().direct_space_state
			var ray = PhysicsRayQueryParameters2D.create(global_position, body.global_position)
			ray.exclude = [self]
			ray.collision_mask = 1 << 2 # wall layer
			if space_state.intersect_ray(ray):
				if debug_nova:
					print("[NovaExplosion] blocked:", body.name)
				continue

			if body.has_method("deal_damage"):
				body.deal_damage(int(round(instant_damage)), global_position)
			if body.has_method("apply_dot"):
				body.apply_dot(dot_damage, dot_duration)
			if debug_nova:
				print("[NovaExplosion] hit:", body.name)
