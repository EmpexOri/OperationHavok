extends Enemy

var Colour = Color(0, 0.5, 0)

func _ready():
	super._ready()
	Speed = 140
	Health = 15
	$Sprite2D.modulate = Colour

func deal_damage(damage, from_position = null):
	Health -= damage

func _process(delta):
	if Health <= 0:
		for i in range(1):
			drop_xp()

		$Area2D/CollisionShape2D.set_deferred("disabled", true)

		Global.spawn_meat_chunk(global_position)
		Global.spawn_blood_splatter(global_position)
		Global.spawn_death_particles(global_position)
		queue_free()

func drop_xp():
	var xp_drop_chance := 0.1
	var xp_drop_range := Vector2i(1, 1)

	if randf() > xp_drop_chance:
		return

	var xp_amount = randi_range(xp_drop_range.x, xp_drop_range.y)
	var screen_size = get_viewport_rect().size

	for i in xp_amount:
		var position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		position.x = clamp(position.x, 0, screen_size.x)
		position.y = clamp(position.y, 0, screen_size.y)

		var xp_pickup = PickupFactory.build_pickup("Xp", position)
		get_parent().add_child(xp_pickup)

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(10)
		var Direction = (position - body.position).normalized()
		var bounce_target = global_position + (Direction * Speed * 0.3)

		var Inbe_tween = get_tree().create_tween()
		Inbe_tween.tween_property(self, "global_position", bounce_target, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		await Inbe_tween.finished
		return

	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		body.queue_free()
		deal_damage(10)

	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Minion")
		Group = "Minion"
		add_to_group("PlayerSummon")
		SummonGroup = "PlayerSummon"
		Colour = Color(0.9, 1, 0.9)
		$Sprite2D.modulate = Colour
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()

	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await get_tree().process_frame
		if not is_instance_valid(body) or not body.get_parent():
			call_deferred("queue_free")
