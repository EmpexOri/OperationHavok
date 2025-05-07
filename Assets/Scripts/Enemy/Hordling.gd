extends Enemy

func start():
	Speed = 140
	Health = 10
	Group = "Enemy"
	SummonGroup = "EnemySummon"
	Target = "Player"

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(2)

		var direction = (global_position - body.global_position).normalized()
		var bounce_target = global_position + direction * Speed * 0.3
		var screen_size = get_viewport_rect().size
		bounce_target.x = clamp(bounce_target.x, 0, screen_size.x)
		bounce_target.y = clamp(bounce_target.y, 0, screen_size.y)

		var bounce_tween = get_tree().create_tween()
		bounce_tween.tween_property(self, "global_position", bounce_target, 0.2)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await bounce_tween.finished
		return

	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		body.queue_free()
		deal_damage(10)

	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Minion")

		var sprite = get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = Color(1, 0.7, 0.7)

		var enemies = get_tree().get_nodes_in_group("Enemy")
		if enemies.size() > 0:
			Target = enemies[0].get_path()

	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await get_tree().process_frame
		if not is_instance_valid(body) or not body.get_parent():
			call_deferred("queue_free")

func drop_xp():
	var xp_drop_chance := 0.4  # Hordling-specific: 40% chance
	var xp_drop_range := Vector2i(1, 2)  # Drops 1 to 2 XP pickups

	if randf() > xp_drop_chance:
		return  # No drop

	var screen_size = get_viewport_rect().size
	var xp_amount = randi_range(xp_drop_range.x, xp_drop_range.y)

	for i in xp_amount:
		var pos = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		pos.x = clamp(pos.x, 0, screen_size.x)
		pos.y = clamp(pos.y, 0, screen_size.y)

		var xp_pickup = PickupFactory.build_pickup("Xp", pos)
		get_parent().add_child(xp_pickup)
