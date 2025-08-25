extends Enemy

var FleshSpawn = preload("res://Prefabs/GamePrefabs/Enemy/FleshSpawn.tscn")
#Special Enemies we can spawn
var Gatling = preload("res://Prefabs/GamePrefabs/Enemy/Gatling.tscn")
var Needling = preload("res://Prefabs/GamePrefabs/Enemy/Needling.tscn")
var Goolum = preload("res://Prefabs/GamePrefabs/Enemy/Goolum.tscn")

var SummonFX = preload("res://Prefabs/FX/SummonFX.tscn")

var firetimer: Timer

func start():
	Speed = 110
	Health = 50
	MaxHealth = Health
	WeaponScene = preload("res://Prefabs/CodePrefabs/Weapons/EnemyWeapons/EnemyShotgun.tscn")
	setup_weapon()
	start_timer()
	
	firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 3)
	firetimer.one_shot = false
	firetimer.autostart = true
	firetimer.connect("timeout", Callable(self, "fire"))
	add_child(firetimer)

func _ready():
	super()
	get_flash_sprite().material = get_flash_sprite().material.duplicate()

func update_navigation():
	var target_node = resolve_target()
	if not target_node:
		return
	
	var distance = global_position.distance_to(target_node.global_position)
	var dir = (nav.get_next_path_position() - global_position).normalized()
	
	if distance < 150:
		velocity = -dir * Speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func start_timer():
	var timer = Timer.new()
	timer.wait_time = randf_range(4, 8)
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_begin_summon"))
	add_child(timer)
	timer.start()

# --- Show FX before spawning ---
func _begin_summon():
	var fx = SummonFX.instantiate()
	fx.global_position = global_position
	add_child(fx)  

	if fx.has_signal("finished"):
		fx.connect("finished", Callable(self, "_on_summon_fx_finished").bind(fx))
	else:
		await get_tree().create_timer(1.0).timeout
		_on_summon_fx_finished(fx)

func _on_summon_fx_finished(fx):
	if is_instance_valid(fx):
		fx.queue_free()
	spawn() # Actually summon enemies after FX ends <3

# --- Actual New summoning logic ---
func spawn():
	if get_tree().get_nodes_in_group(SummonGroup).size() >= 51:
		start_timer()
		return

	await get_tree().physics_frame
	var space_state = get_world_2d().direct_space_state
	var spawn_count = randi_range(2, 5)
	var attempts = 0
	var spawned = 0

	while spawned < spawn_count and attempts < spawn_count * 3:
		attempts += 1
		var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		var spawn_pos = global_position + offset

		var query = PhysicsPointQueryParameters2D.new()
		query.position = spawn_pos
		query.collide_with_areas = false
		query.collision_mask = 1 << 2  # Assumes environment layer is 2
		if space_state.intersect_point(query).is_empty():
			var instance = _pick_enemy().instantiate()
			instance.name = "Enemy_" + str(randi())
			instance.Group = Group
			instance.SummonGroup = SummonGroup
			instance.position = spawn_pos
			get_parent().add_child(instance)
			spawned += 1

	start_timer()

# --- NEW FUNCTION: 10% chance to summon special enemy ---
func _pick_enemy() -> PackedScene:
	if randf() <= 0.1: # 10% chance
		var specials = [Gatling, Needling, Goolum]
		return specials.pick_random()
	return FleshSpawn

func fire():
	var target = resolve_target()
	if target and global_position.distance_to(target.global_position) <= 150:
		if CurrentWeapon:
			var direction = (target.global_position - global_position).normalized()
			CurrentWeapon.attempt_to_fire(global_position, direction)

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(2)

		var direction = (global_position - body.global_position).normalized()
		var dodge_distance = Speed * 0.6
		var start_position = global_position
		var end_position = start_position + direction * dodge_distance

		var collision_shape = $CollisionShape2D
		collision_shape.disabled = true

		await get_tree().physics_frame
		var space_state = get_world_2d().direct_space_state
		var ray_params = PhysicsRayQueryParameters2D.create(start_position, end_position)
		ray_params.exclude = [self]
		ray_params.collision_mask = 1 << 2

		var ray_result = space_state.intersect_ray(ray_params)
		if ray_result:
			end_position = ray_result.position - direction.normalized() * 4.0

		var tween = get_tree().create_tween()
		tween.tween_property(self, "global_position", end_position, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished

		collision_shape.disabled = false
		return

	if is_in_group("Enemy") and body.is_in_group("Minion"):
		body.queue_free()
		deal_damage(10)

func get_flash_sprite() -> CanvasItem:
	return $Sprite2D
