extends Area2D
class_name NovaExplosion

@export var debug_nova: bool = true
@onready var cs: CollisionShape2D = $CollisionShape2D

var instant_damage: float
var dot_damage: float
var dot_duration: float
var radius: float

func setup(instant_dmg: float, dot_dmg: float, dot_dur: float, p_radius: float, inherit_mask: int = 0):
	instant_damage = instant_dmg
	dot_damage = dot_dmg
	dot_duration = dot_dur
	radius = p_radius

	if debug_nova:
		print("[NovaExplosion.setup] pos=", global_position, 
			" r=", radius, 
			" instant=", instant_damage, 
			" dot=", dot_damage, " dur=", dot_duration)

	# Shape + state
	if cs and cs.shape is CircleShape2D:
		(cs.shape as CircleShape2D).radius = radius
		cs.disabled = false
	else:
		push_warning("[NovaExplosion] Missing/invalid CollisionShape2D (needs CircleShape2D)")

	monitoring = true
	monitorable = true

	if inherit_mask != 0:
		collision_mask = inherit_mask  # match the working grenade's mask

	if debug_nova:
		print("[NovaExplosion] layer=", collision_layer, 
			" mask=", collision_mask, 
			" cs.radius=", (cs.shape as CircleShape2D).radius if cs and cs.shape else "<none>", 
			" cs.disabled=", cs.disabled if cs else "<no cs>")

	# Let physics register overlaps
	await get_tree().physics_frame

	if debug_nova:
		var overlaps = get_overlapping_bodies()
		print("[NovaExplosion] after physics frame, overlaps=", overlaps.size())
		for b in overlaps:
			print("  - overlap:", b.name, " groups=", b.get_groups())

	var applied := apply_to_enemies()
	if applied == 0 and debug_nova:
		print("[NovaExplosion] Area2D found 0 targets. Running intersect_shape fallback.")
		_fallback_shape_query()

	# auto cleanup
	var t := get_tree().create_timer(0.25)
	await t.timeout
	if is_inside_tree():
		queue_free()

func apply_to_enemies() -> int:
	var count := 0
	for body in get_overlapping_bodies():
		if body.is_in_group("Enemy"):
			if body.has_method("deal_damage"):
				body.deal_damage(int(round(instant_damage)), global_position)
				if debug_nova: print("[NovaExplosion] dealt ", instant_damage, " to ", body.name)
			if body.has_method("apply_dot"):
				body.apply_dot(dot_damage, dot_duration)
				if debug_nova: print("[NovaExplosion] applied DoT ", dot_damage, "x", dot_duration, " to ", body.name)
			count += 1
	return count

func _fallback_shape_query():
	var space := get_world_2d().direct_space_state
	if space == null:
		if debug_nova: print("[NovaExplosion] no direct_space_state")
		return

	var shape := CircleShape2D.new()
	shape.radius = radius

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0, global_position)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	# If our mask is 0 (unset), scan broadly
	params.collision_mask = collision_mask if collision_mask != 0 else 0x7FFFFFFF

	var results := space.intersect_shape(params, 64)
	if debug_nova:
		print("[NovaExplosion] intersect_shape hits=", results.size())

	for res in results:
		var collider: Node = res.get("collider")
		if collider and collider.is_in_group("Enemy"):
			if collider.has_method("deal_damage"):
				collider.deal_damage(int(round(instant_damage)), global_position)
				if debug_nova: print("[NovaExplosion][fallback] dealt ", instant_damage, " to ", collider.name)
			if collider.has_method("apply_dot"):
				collider.apply_dot(dot_damage, dot_duration)
				if debug_nova: print("[NovaExplosion][fallback] applied DoT to ", collider.name)
