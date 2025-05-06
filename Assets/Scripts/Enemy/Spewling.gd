extends CharacterBody2D

@onready var nav: NavigationAgent2D = $NavigationAgent2D

var Speed = 60
var Health = 20
var OrbitSpeed = 50
var OrbitDirection
var BulletSpeed = 800
var Target = "Player"
var WeaponScene = preload("res://Prefabs/Weapons/EnemyWeapons/SpewlingWeapon.tscn")
var CurrentWeapon: Weapon = null

func _ready():
	add_to_group("Enemy")
	OrbitDirection = [-1, 1].pick_random()
	
	# Orbit timer
	var orbittimer = Timer.new()
	orbittimer.wait_time = randf_range(3, 6)
	orbittimer.one_shot = false
	orbittimer.connect("timeout", Callable(self, "orbit_direction_change"))
	orbittimer.autostart = true
	add_child(orbittimer)
	
	# Create weapon
	CurrentWeapon = WeaponScene.instantiate()
	CurrentWeapon.owning_entity = "Enemy"
	add_child(CurrentWeapon)
	
	# Fire timer
	var firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 3)
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire"))
	firetimer.autostart = true
	add_child(firetimer)

func _process(delta):
	if Health <= 0:
		handle_death()
	pass

func orbit_direction_change():
	OrbitDirection *= -1
	print("ORBIT DIRECTION CHANGE")

func _physics_process(_delta):
	var Player = get_target_player()
	nav.target_position = Player.position
	var Direction = (nav.get_next_path_position() - global_position).normalized()

	if position.distance_to(Player.position) >= 150:
		velocity = Direction * Speed
	else:
		handle_orbiting(Player, _delta)

	move_and_slide()

	clamp_position_to_screen()

func fire():
	var Player = get_target_player()
	if CurrentWeapon:
		var direction_to_player = (Player.global_position - global_position).normalized()
		CurrentWeapon.attempt_to_fire(global_position, direction_to_player)

func drop_xp():
	var xp_drop_chance := 0.25
	if randf() > xp_drop_chance:
		return

	var xp_amount = randi_range(1, 1)  # 1 XP drop for simplicity
	var screen_size = get_viewport_rect().size
	for i in range(xp_amount):
		var position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		position.x = clamp(position.x, 0, screen_size.x)
		position.y = clamp(position.y, 0, screen_size.y)
		var xp_pickup = PickupFactory.build_pickup("Xp", position)
		get_parent().add_child(xp_pickup)

func deal_damage(damage, from_position = null):
	Health -= damage

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

# Helper functions
func handle_death():
	for i in range(1):
		drop_xp()
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	GlobalAudioController.HordlingDeath()
	Global.spawn_meat_chunk(global_position)
	Global.spawn_blood_splatter(global_position)
	Global.spawn_death_particles(global_position)
	queue_free()

func get_target_player() -> Node:
	if is_in_group("Enemy"):
		return get_parent().get_node(Target)
	elif is_in_group("Minion") and is_instance_valid(Target):
		return get_parent().get_node(Target)
	elif is_in_group("Minion"):
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			return get_parent().get_node(Target)
	return get_parent().get_node("Player")

func handle_orbiting(Player: Node, _delta: float):
	var Angle = (position - Player.position).angle() + OrbitSpeed * OrbitDirection * _delta
	var OrbitRadius = 300
	var OrbitPosition = Player.position + Vector2(OrbitRadius, 0).rotated(Angle)
	velocity = (OrbitPosition - position).normalized() * Speed

func clamp_position_to_screen():
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

func handle_bounce(body: Node2D):
	var Direction = (position - body.position).normalized()
	var bounce_target = global_position + (Direction * Speed * 0.3)
	var Inbe_tween = get_tree().create_tween()
	Inbe_tween.tween_property(self, "global_position", bounce_target, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await Inbe_tween.finished

func handle_spell_collision():
	remove_from_group("Enemy")
	add_to_group("Minion")
	var sprite = get_node("Sprite2D")
	sprite.modulate = Color(0.8, 0.9, 1)
	if get_tree().get_nodes_in_group("Enemy").size() > 0:
		Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()

func handle_minion_collision(body: Node2D):
	await get_tree().process_frame
	if not is_instance_valid(body) or not body.get_parent():
		call_deferred("queue_free")
