extends Node2D

@export var enemy_scene: PackedScene
@export var enemies_to_spawn: int = 3
@export var trigger_box_name: String = "SpawnTrigger"
@export var spawn_interval: float = 0.1  

var _spawned := false

func _ready():
	var trigger = get_node_or_null(trigger_box_name)
	if trigger:
		trigger.body_entered.connect(_on_trigger_entered)
	else:
		push_warning("No trigger box found")


func _on_trigger_entered(body: Node) -> void:
	if _spawned:
		return
	if body.name == "Player" or body.is_in_group("Player"):
		_spawned = true
		spawn_enemies()


func spawn_enemies() -> void:
	if not enemy_scene:
		push_error("No enemy scene")
		return

	var ysorted_parent: Node = get_tree().get_root().find_child("YSortedNode", true, false)
	if not ysorted_parent:
		push_warning("Could not find YSortedNode")
		ysorted_parent = get_parent()

	var spawn_points: Array = []
	for child in get_children():
		if child.name.begins_with("EnemySpawn"):
			spawn_points.append(child)
	
	if spawn_points.is_empty():
		push_warning("No EnemySpawn markers")
		return

	# Start the staggered spawning coroutine
	spawn_enemies_staggered(ysorted_parent, spawn_points)


func spawn_enemies_staggered(ysorted_parent: Node, spawn_points: Array) -> void:
	# Run in a coroutine-like style
	spawn_next_enemy(ysorted_parent, spawn_points, 0)


func spawn_next_enemy(ysorted_parent: Node, spawn_points: Array, index: int) -> void:
	if index >= enemies_to_spawn:
		#print("Spawned %d enemies from %s" % [enemies_to_spawn, name])
		return
	
	var spawn_point = spawn_points[index % spawn_points.size()]
	var enemy = enemy_scene.instantiate()
	ysorted_parent.add_child(enemy)
	enemy.global_position = spawn_point.global_position

	# Wait for spawn_interval, then call again
	var timer = get_tree().create_timer(spawn_interval)
	timer.timeout.connect(func():
		spawn_next_enemy(ysorted_parent, spawn_points, index + 1)
	)
