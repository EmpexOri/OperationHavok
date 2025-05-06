extends CharacterBody2D

class_name Enemy

@onready var nav: NavigationAgent2D = $NavigationAgent2D

var Speed = 100
var Health = 10
var Group = "Enemy"
var SummonGroup = "EnemySummon"
var Target = "Player"

var WeaponScene: PackedScene
var CurrentWeapon: Weapon

func _ready():
	add_to_group(Group)
	add_to_group(SummonGroup)
	
	setup_weapon()
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

func resolve_target():
	if is_in_group("Enemy") or (is_in_group("Minion") and not is_instance_valid(Target)):
		var players = get_tree().get_nodes_in_group("Player")
		return players[0] if players.size() > 0 else null
	if is_instance_valid(Target):
		return get_node_or_null(Target)
	return null

func deal_damage(damage: int, _from_position = null):
	Health -= damage
	if Health <= 0:
		on_death()

func on_death():
	drop_xp()
	Global.spawn_meat_chunk(global_position)
	Global.spawn_blood_splatter(global_position)
	Global.spawn_death_particles(global_position)
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
