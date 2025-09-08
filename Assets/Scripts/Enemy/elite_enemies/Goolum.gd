extends Enemy

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var latch_area: Area2D = $Area2D

const WALL_COLLISION_MASK = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)

@onready var attach_timer: Timer = Timer.new()
var nearby_targets: Array[Node2D] = []

func _ready():
	super()
	
	# Duplicate material to avoid shared material issues
	if sprite.material:
		sprite.material = sprite.material.duplicate()

	latch_area.body_entered.connect(_on_area_2d_body_entered)
	latch_area.body_exited.connect(_on_area_2d_body_exited)

	Speed = 50
	Health = 120
	MaxHealth = Health
	Group = "Enemy"
	add_to_group("Support")
	Target = null

	attach_timer.wait_time = 1.0
	attach_timer.one_shot = false
	attach_timer.autostart = true
	add_child(attach_timer)
	attach_timer.timeout.connect(_on_attach_timer_timeout)

func _process(delta):
	super._process(delta)
	if Health <= 0:
		on_death()

func _physics_process(delta):
	if not is_instance_valid(Target) or Target.is_in_group("Armored"):
		find_strongest_target()

	if Target:
		nav.target_position = Target.global_position
		var direction = (nav.get_next_path_position() - global_position).normalized()
		velocity = direction * Speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	if velocity.length() > 0.1:
		var moving_up = velocity.y < 0
		sprite.animation = "move_up_left" if moving_up else "move_down_left"
		sprite.flip_h = velocity.x > 0
		sprite.play()
	else:
		sprite.stop()
		
func on_death():
	# Spawn goo chunks at this enemy's position
	if is_instance_valid(self):
		Global.spawn_goo_chunks(global_position)
	super()

	# Original death logic (disable enemy, play animation, etc.)
	queue_free()

func find_strongest_target():
	var candidates := get_tree().get_nodes_in_group("Enemy")

	var valid_candidates := []
	for enemy in candidates:
		if enemy == self:
			continue
		if enemy.is_in_group("Armored") or enemy.is_in_group("Support"):
			continue
		if enemy.Health <= 0:
			continue
		valid_candidates.append(enemy)

	if valid_candidates.is_empty():
		Target = null
		return

	var strongest = valid_candidates[0]
	for enemy in valid_candidates:
		if enemy.Health > strongest.Health:
			strongest = enemy

	Target = strongest

@warning_ignore("unused_parameter")
func attempt_transfer_health_async(target: Node2D) -> void:
	await get_tree().physics_frame

	if not is_instance_valid(target) or target.is_in_group("Armored"):
		return

	var space_state = get_world_2d().direct_space_state
	if space_state == null:
		return

	var ray_params = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	ray_params.exclude = [self]
	ray_params.collision_mask = WALL_COLLISION_MASK

	var result = space_state.intersect_ray(ray_params)
	if result and result.collider != target:
		return # Blocked

	if target.has_method("apply_armor_buff"):
		print("Goolum grants armor to:", target.name)
		target.apply_armor_buff(Health)

		if target.has_method("flash_white"):
			target.flash_white(Color(0, 0, 1))  # Blue flash using shader
		else:
			var spr = target.get_node_or_null("AnimatedSprite2D")
			if spr:
				spr.modulate = Color(0, 0, 1)
				var timer = Timer.new()
				timer.one_shot = true
				timer.wait_time = 1.0
				add_child(timer)
				timer.timeout.connect(Callable(self, "_reset_modulate_color").bind(spr))
				timer.start()

	on_death()

func get_flash_sprite() -> CanvasItem:
	return sprite

func _reset_modulate_color(sprite: CanvasItem):
	if is_instance_valid(sprite):
		sprite.modulate = Color(1, 1, 1)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") and not body.is_in_group("Armored") and body.has_method("apply_armor_buff") and not body.is_in_group("Support"):
		if not nearby_targets.has(body):
			nearby_targets.append(body)

func _on_area_2d_body_exited(body: Node2D) -> void:
	nearby_targets.erase(body)

func _on_attach_timer_timeout():
	if nearby_targets.is_empty():
		return

	for body in nearby_targets:
		if is_instance_valid(body) and body.Health > 0:
			if randf() <= 0.4:
				attempt_transfer_health_async(body)
				return
