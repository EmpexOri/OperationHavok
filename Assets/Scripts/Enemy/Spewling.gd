extends Enemy

@onready var orbittimer: Timer
@onready var firetimer: Timer

var OrbitSpeed = 50
var OrbitDirection = 1
var BulletSpeed = 800

func start():
	OrbitDirection = [-1, 1].pick_random()

	# Orbit timer
	orbittimer = Timer.new()
	orbittimer.wait_time = randf_range(3, 6)
	orbittimer.one_shot = false
	orbittimer.connect("timeout", Callable(self, "orbit_direction_change"))
	orbittimer.autostart = true
	add_child(orbittimer)

	# Fire timer
	firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 3)
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire"))
	firetimer.autostart = true
	add_child(firetimer)

func orbit_direction_change():
	OrbitDirection *= -1
	print("ORBIT DIRECTION CHANGE")

func _physics_process(delta):
	var player = resolve_target()
	if player:
		nav.target_position = player.global_position
		if position.distance_to(player.global_position) >= 150:
			var dir = (nav.get_next_path_position() - global_position).normalized()
			velocity = dir * Speed
		else:
			handle_orbiting(player, delta)
	move_and_slide()
	clamp_position_to_screen()

func fire():
	var player = resolve_target()
	if player and CurrentWeapon:
		var dir = (player.global_position - global_position).normalized()
		CurrentWeapon.attempt_to_fire(global_position, dir)

func handle_orbiting(player: Node, delta: float):
	var angle = (position - player.position).angle() + OrbitSpeed * OrbitDirection * delta
	var orbit_radius = 300
	var orbit_pos = player.position + Vector2(orbit_radius, 0).rotated(angle)
	velocity = (orbit_pos - position).normalized() * Speed

func clamp_position_to_screen():
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(10)
		handle_bounce(body)
	elif is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		body.queue_free()
		deal_damage(10)
	elif body.is_in_group("Spell"):
		handle_spell_collision()
	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await handle_minion_collision(body)

func handle_bounce(body: Node2D):
	var dir = (position - body.position).normalized()
	var target = global_position + dir * Speed * 0.3
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", target, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

func handle_spell_collision():
	remove_from_group("Enemy")
	add_to_group("Minion")
	get_node("Sprite2D").modulate = Color(0.8, 0.9, 1)
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.size() > 0:
		Target = enemies[0].get_path()

func handle_minion_collision(body: Node2D):
	await get_tree().process_frame
	if not is_instance_valid(body) or not body.get_parent():
		call_deferred("queue_free")
