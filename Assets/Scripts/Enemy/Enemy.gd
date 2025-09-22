extends CharacterBody2D

class_name Enemy

@onready var nav: NavigationAgent2D = $NavigationAgent2D

var dot_timers: Array = []

### Animations
var smooth_dir := Vector2.ZERO
var last_anim_dir := Vector2.ZERO
const FLIP_THRESHOLD := 0.2  

var Speed = 100
var MaxHealth: int = 10
var Health: int = 10
var Group = "Enemy"
var SummonGroup = "EnemySummon"
var Target = "Player"

var path_update_interval := 0.25  # seconds between path recalculations
var path_update_timer := 0.0
var dead := false

var flash_timer: Timer
var flash_active := false

var cached_player: Node2D = null

var WeaponScene: PackedScene
var CurrentWeapon: Weapon

signal died(enemy)

func _ready():
	flash_timer = Timer.new()
	flash_timer.wait_time = 0.15
	flash_timer.one_shot = false
	flash_timer.connect("timeout", Callable(self, "_on_flash_tick"))
	add_child(flash_timer)
	add_to_group(Group)
	add_to_group(SummonGroup)
	setup_weapon()
	
	# Cache player reference
	cached_player = get_tree().get_nodes_in_group("Player")[0] if get_tree().get_nodes_in_group("Player").size() > 0 else null
	
	await get_tree().process_frame  # Give time for Player to exist in their pretty little eyes <3
	start()

func setup_weapon():
	if WeaponScene:
		CurrentWeapon = WeaponScene.instantiate()
		CurrentWeapon.owning_entity = Group
		add_child(CurrentWeapon)

func _physics_process(delta):
	if not cached_player or not is_instance_valid(cached_player):
		var players = get_tree().get_nodes_in_group("Player")
		cached_player = players[0] if players.size() > 0 else null
	
	update_navigation(delta)

func update_navigation(delta):
	if not nav:
		return

	# Update path periodically
	path_update_timer -= delta
	if path_update_timer <= 0.0:
		var player_node = resolve_target()
		if player_node:
			nav.target_position = player_node.global_position
		path_update_timer = path_update_interval  # reset timer

	if nav.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var dir = (nav.get_next_path_position() - global_position).normalized()

		# --- Manual avoidance: if too close to another enemy, adjust direction slightly ---
		var avoidance_offset := Vector2.ZERO
		var nearby_enemies := get_tree().get_nodes_in_group("Enemy")
		for enemy in nearby_enemies:
			if enemy == self:
				continue
			if global_position.distance_to(enemy.global_position) < 24: # distance threshold
				# Push away from nearby enemy
				avoidance_offset += (global_position - enemy.global_position).normalized()

		if avoidance_offset != Vector2.ZERO:
			# Blend original direction with avoidance vector
			dir = (dir + avoidance_offset.normalized()).normalized()

		velocity = dir * Speed
		move_and_slide()

func resolve_target() -> Node2D:
	return cached_player

#func deal_damage(damage: int, _from_position = null):
	#var new_health = max(0, Health - damage)
	#print("Dealt ", damage, " damage to ", self.name, " (", Health, " → ", new_health, ")")
	#Health = new_health
	#flash_white()
	#if Health == 0:
		#on_death()

#func deal_damage(damage: int, _from_position = null):
	#var new_health = max(0, Health - damage)
	#print("Dealt ", damage, " damage to ", self.name, " (", Health, " → ", new_health, ")")
	#Health = new_health
	#flash_white()
	#if Health == 0:
		#on_death()

func deal_damage(damage: int, from_position = null):
	if dead:          # already dying
		return
	var original_health = Health

	if Armor > 0:
		var absorbed = min(damage, Armor)
		Armor -= absorbed
		damage -= absorbed
		update_scale()
		if Armor <= 0:
			remove_from_group("Armored")
			print(name, " lost all armor!")

	if damage > 0:
		Health = max(0, Health - damage)
		flash_white()
		#print("Dealt ", damage, " damage to ", name, " (", original_health, " → ", Health, ")")
		if Health <= 0:
			on_death()

func on_death():
	if dead:
		return
	dead = true
	emit_signal("died", self)
	drop_xp()
	Global.spawn_meat_chunk(global_position)
	Global.spawn_blood_splatter(global_position)
	Global.spawn_death_particles(global_position)
	GlobalAudioController.HordlingDeath()
	queue_free()

func drop_xp():
	var xp_amount = randi_range(1, 3)
	for i in xp_amount:
		var pos = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		var xp = PickupFactory.build_pickup("Xp", pos)
		get_parent().add_child(xp)

func start():
	pass  # To be overridden

func _on_area_2d_body_entered(body: Node2D):
	# Define generic collisions, Biomancer can override
	pass

func apply_dot(dps: float, duration: float) -> void:
	var ticks = int(duration)
	for i in range(ticks):
		var t = Timer.new()
		t.wait_time = 1.0
		t.one_shot = true
		t.connect("timeout", Callable(self, "_on_dot_tick").bind(dps))
		add_child(t)
		t.start(i) # stagger each tick based on when it should occur
		
func _on_dot_tick(dps: float) -> void:
	deal_damage(dps)
	
func _process(delta: float) -> void:
	for dot in dot_timers:
		var damage = dot.damage_per_second * delta
		deal_damage(damage)
		dot.time_remaining -= delta

	# Remove expired effects
	dot_timers = dot_timers.filter(func(d):
		return d.time_remaining > 0
	)
	
	# MY NEW BIT YIPPEEEEE
	if is_buffed:
		buff_timer -= delta
		if buff_timer <= 0:
			remove_buff()
	
func get_flash_sprite() -> CanvasItem:
	push_error("get_flash_sprite() not implemented in subclass")
	return null

func flash_white(flash_color := Color("cb002e"), times := 1, interval := 0.15):
	var sprite = get_flash_sprite()
	if not sprite or not (sprite.material is ShaderMaterial):
		return
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash_color", flash_color)

	var tween := create_tween()
	for i in range(times):
		tween.tween_property(mat, "shader_parameter/flash_strength", 0.5, interval)
		tween.tween_property(mat, "shader_parameter/flash_strength", 0.0, interval)

# STIILL MY NEW BIT YIPPEEE
func has_weapon() -> bool:
	if CurrentWeapon == null: # Does the enemy have a weapon? 
		return false
	if not is_instance_valid(CurrentWeapon): # Is the enemies weapon existing?
		return false
	return true

var is_buffed := false
var buff_timer := 0.0
const BUFF_DURATION := 5.0  # seconds

func apply_buff(flash_color := Color("98fb98")):
	var sprite = get_flash_sprite()
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash_color", flash_color)
	
	if is_buffed:
		return
	
	is_buffed = true
	add_to_group("Buffed")
	Speed *= 1.35

	if has_weapon():
		CurrentWeapon.current_fire_rate *= 0.8
		CurrentWeapon.cooldown_timer.wait_time = CurrentWeapon.current_fire_rate

	mat.set_shader_parameter("flash_strength", 0.5)
	buff_timer = BUFF_DURATION

	# Start healing timer ticks
	for i in range(int(BUFF_DURATION)):
		var t = Timer.new()
		t.wait_time = 1.0
		t.one_shot = true
		t.connect("timeout", Callable(self, "_on_buff_heal_tick"))
		add_child(t)
		t.start(i)
		
	print("Buff applied to:", name)
	 
func _on_buff_heal_tick():
	if Health <= 0:
		return  # Don't heal dead enemies LMAO
		
	Health = min(Health + 5, MaxHealth)
	print(name, " healed 5hp during buff → now has ", Health)
	
	# Spawn healing particles
	var particles = preload("res://Assets/Art/Particles/Misc/HealingEffect.tscn").instantiate()
	add_child(particles)
	particles.position = Vector2.ZERO
	
	var pfx = particles.get_node("GPUParticles2D")
	pfx.emitting = true
	pfx.one_shot = true
	pfx.restart()  # Just to be safe
	
	# Auto-queue_free the wrapper node after emission ends
	await get_tree().create_timer(pfx.lifetime).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func remove_buff(flash_color := Color("98fb98")):
	var sprite = get_flash_sprite()
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash_color", flash_color)
	
	is_buffed = false
	remove_from_group("Buffed")
	Speed /= 1.25
	if has_weapon():
		CurrentWeapon.current_fire_rate = CurrentWeapon.base_fire_rate
		CurrentWeapon.cooldown_timer.wait_time = CurrentWeapon.base_fire_rate
	mat.set_shader_parameter("flash_strength", 0.0)
	print("Buff expired for:", name)


############################################################################################################
############################################################################################################
############################################################################################################

var Armor: int = 0
var MaxArmor: int = 0
var BaseScale: Vector2 = Vector2.ONE

func update_scale():
	if MaxArmor <= 0:
		self.scale = BaseScale
		return

	var ratio := float(Armor) / MaxArmor
	var scale_increase := ratio * 0.8  # Max growth +80%
	self.scale = BaseScale + Vector2.ONE * scale_increase

func apply_armor_buff(amount: int) -> void:
	Armor += amount
	MaxArmor = Armor  # Set max for shrink reference
	print("Armor buff applied:", amount)
	add_to_group("Armored")
	
	# Scale up based on armor (e.g., each 100 HP = +1x scale)
	update_scale()
