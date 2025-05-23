extends CharacterBody2D

class_name Enemy

@onready var nav: NavigationAgent2D = $NavigationAgent2D

var dot_timers: Array = []

var Speed = 100
var Health = 10
var Group = "Enemy"
var SummonGroup = "EnemySummon"
var Target = "Player"

var WeaponScene: PackedScene
var CurrentWeapon: Weapon

signal died(enemy)

func _ready():
	add_to_group(Group)
	add_to_group(SummonGroup)
	setup_weapon()
	await get_tree().process_frame  # Give time for Player to exist in their pretty little eyes <3
	start()

func setup_weapon():
	if WeaponScene:
		CurrentWeapon = WeaponScene.instantiate()
		CurrentWeapon.owning_entity = Group
		add_child(CurrentWeapon)

func _physics_process(_delta):
	update_navigation()

func update_navigation():
	if not nav:
		return
	var player_node = resolve_target()
	if player_node:
		nav.target_position = player_node.global_position
		var dir = nav.get_next_path_position() - global_position
		velocity = dir.normalized() * Speed
		move_and_slide()

func resolve_target() -> Node2D:
	var players = get_tree().get_nodes_in_group("Player")
	return players[0] if players.size() > 0 else null

func deal_damage(damage: int, _from_position = null):
	var new_health = max(0, Health - damage)
	print("Dealt ", damage, " damage to ", self.name, " (", Health, " → ", new_health, ")")
	Health = new_health
	flash_white()
	if Health == 0:
		on_death()

func on_death():
	emit_signal("died", self)  # Notify the level before removing the enemy
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
	
func get_flash_sprite() -> CanvasItem:
	push_error("get_flash_sprite() not implemented in subclass")
	return null

func flash_white(flash_color := Color("cb002e"), times := 1, interval := 0.15):
	var sprite = get_flash_sprite()
	if not sprite or not sprite.material:
		return

	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash_color", flash_color)

	for i in range(times):
		mat.set_shader_parameter("flash_strength", 0.5)
		await get_tree().create_timer(interval).timeout
		mat.set_shader_parameter("flash_strength", 0.0)
		await get_tree().create_timer(interval).timeout
