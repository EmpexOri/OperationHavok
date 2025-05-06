extends Enemy

var FleshSpawn = preload("res://Prefabs/Enemy/FleshSpawn.tscn")
var firetimer: Timer

func start():
	Speed = 110
	Health = 20
	WeaponScene = preload("res://Prefabs/Weapons/EnemyWeapons/EnemyShotgun.tscn")
	setup_weapon()
	start_timer()
	
	firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 3)
	firetimer.one_shot = false
	firetimer.autostart = true
	firetimer.connect("timeout", Callable(self, "fire"))
	add_child(firetimer)

func update_navigation():
	var target_node = resolve_target()
	if not target_node:
		return
	
	var distance = global_position.distance_to(target_node.global_position)
	var dir = (nav.get_next_path_position() - global_position).normalized()
	
	# Custom Biomancer logic to retreat
	if distance < 150:
		velocity = -dir * Speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func start_timer():
	var timer = Timer.new()
	timer.wait_time = randf_range(4, 8)
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "spawn"))
	add_child(timer)
	timer.start()

func spawn():
	if get_tree().get_nodes_in_group(SummonGroup).size() < 51:
		var instance = FleshSpawn.instantiate()
		instance.name = "Enemy_" + str(randi())
		instance.Group = Group
		instance.SummonGroup = SummonGroup
		instance.position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		get_parent().add_child(instance)
	start_timer()

func fire():
	var target = resolve_target()
	if target and global_position.distance_to(target.global_position) <= 150:
		if CurrentWeapon:
			var direction = (target.global_position - global_position).normalized()
			CurrentWeapon.attempt_to_fire(global_position, direction)
