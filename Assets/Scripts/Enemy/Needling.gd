extends Enemy  # Inherit from Enemy.gd

@onready var sprite = $Sprite2D

var BulletSpeed = 900
var ShotsFired = 0
var ShotsBeforeMoving = randi_range(1, 3)
var IsMovingRandomly = false
var Weapon: PackedScene = preload("res://Prefabs/Weapons/EnemyWeapons/enemy_sniper.tscn")

func _ready():
	WeaponScene = Weapon
	# Call setup_weapon from the base Enemy class
	super._ready()

	# Custom setup specific to Needling
	var firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 4) # Fire every 2-4 seconds
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire"))
	firetimer.autostart = true
	add_child(firetimer)

func _process(delta):
	if Health <= 0:
		for i in range(1):
			drop_xp()  # Custom drop_xp in Needling.gd
		
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
		
		Global.spawn_meat_chunk(global_position)
		Global.spawn_blood_splatter(global_position)
		Global.spawn_death_particles(global_position) 
		queue_free()

func _physics_process(_delta):
	var target_pos: Vector2

	if IsMovingRandomly:
		var player = get_parent().get_node(Target)
		target_pos = nav.target_position
		if global_position.distance_to(player.global_position) <= 100:
			# Cancel random movement and start charging at the player
			IsMovingRandomly = false
		elif nav.is_navigation_finished() or position.distance_to(nav.get_next_path_position()) < 10:
			IsMovingRandomly = false
			velocity = Vector2(0, 0)
	else:
		var Player = resolve_target()  # Use the resolve_target from Enemy.gd
		target_pos = Player.position
		nav.target_position = target_pos

	var Direction = nav.get_next_path_position() - global_position
	Direction = Direction.normalized()

	if not IsMovingRandomly and (position.distance_to(target_pos) >= 100):
		velocity = Vector2(0, 0)
		sprite.modulate.a = 0.2 # 20% visible
	elif IsMovingRandomly:
		Speed = 60 # Half Speed
		sprite.modulate.a = 0.65 # 65% visible
		velocity = Direction * Speed
	else:
		Speed = 120 # Full Speed
		sprite.modulate.a = 1 # 100% visible
		velocity = Direction * Speed

	move_and_slide()

	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

func fire():
	var Player = get_parent().get_node(Target)
	if IsMovingRandomly or velocity.length() > 1:
		return # Don't fire while moving

	if CurrentWeapon:
		var direction_to_player = (Player.global_position - global_position).normalized()
		CurrentWeapon.attempt_to_fire(global_position, direction_to_player)

		ShotsFired += 1
		if ShotsFired >= ShotsBeforeMoving:
			random_move()

func random_move():
	IsMovingRandomly = true
	ShotsFired = 0
	ShotsBeforeMoving = randi_range(1, 3)

	var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	var target_pos = global_position + offset

	var screen_size = get_viewport_rect().size
	target_pos.x = clamp(target_pos.x, 0, screen_size.x)
	target_pos.y = clamp(target_pos.y, 0, screen_size.y)

	nav.target_position = target_pos
