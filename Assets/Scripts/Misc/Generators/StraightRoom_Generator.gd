extends Node2D

@export var enemy_scene: PackedScene
@export var enemies_to_spawn: int = 3
@export var trigger_box_name: String = "SpawnTrigger"
@export var spawn_interval: float = 0.1

# Updated path for your doors
@export var door_folder_path: String = "res://Scenes/Prefig_Rooms/Rooms/Doors/"

var _active := false
var _spawned := false
var _enemies: Array = []
var _spawned_doors: Array = []

func _ready():
	var trigger = get_node_or_null(trigger_box_name)
	if trigger:
		trigger.body_entered.connect(_on_trigger_entered)
	else:
		push_warning("No trigger box found in %s" % name)

	move_prefab_ysorted_objects()

# --- TRIGGER HANDLING -------------------------------------------------

func _on_trigger_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("Player"):
		activate_room()

		# Disable the trigger safely
		var trigger = get_node_or_null(trigger_box_name)
		if trigger and trigger is Area2D:
			trigger.set_deferred("monitoring", false)

# --- ROOM LIFECYCLE ---------------------------------------------------

func activate_room() -> void:
	if _spawned:
		return 
	_active = true
	_spawned = true
	spawn_doors()
	spawn_enemies()

func deactivate_room() -> void:
	# Despawn doors
	for door in _spawned_doors:
		if is_instance_valid(door):
			door.queue_free()
	_spawned_doors.clear()

	_active = false
	_spawned = false

# --- DOOR HELPERS ----------------------------------------------------

# Returns the "opposite" internal marker name we expect inside the door prefab
# e.g. room marker "Door_South" expects a door prefab marker "Door_North" to align with it.
func _expected_internal_marker_name(room_marker_name: String) -> String:
	match room_marker_name:
		"Door_North": return "Door_South"
		"Door_South": return "Door_North"
		"Door_East":  return "Door_West"
		"Door_West":  return "Door_East"
		_: return ""

func _spawn_door(door_scene: PackedScene, ysorted_parent: Node, attach_marker: Marker2D) -> Node:
	var door_instance = door_scene.instantiate()
	
	# Add the door to the ysorted parent (so draw order works)
	ysorted_parent.add_child(door_instance)
	# Choose the internal marker to use for alignment.
	var expected_name = _expected_internal_marker_name(attach_marker.name)
	var door_marker: Marker2D = null
	
	if expected_name != "":
		door_marker = door_instance.get_node_or_null(expected_name)
	if not door_marker:
		# find the first Marker2D named Door_* inside the door prefab
		door_marker = _find_first_internal_door_marker(door_instance)
		
	# Note: door_marker.position is the local position inside the door instance.
	if door_marker:
		# For typical non-rotated doors this is simply:
		door_instance.global_position = attach_marker.global_position - door_marker.position
	else:
		door_instance.global_position = attach_marker.global_position
		
	# Give the spawned door a unique name so its internal Door_* markers don't conflict with room markers
	door_instance.name = "%s_door" % attach_marker.name
	
	# Sanitize internal Door_* markers (rename so room scanning ignores them later)
	_sanitize_internal_door_markers(door_instance)
	
	return door_instance
	
func _find_first_internal_door_marker(node: Node) -> Marker2D:
	for n in node.get_children():
		if n is Marker2D and n.name.begins_with("Door_"):
			return n
		# recursive search
		var found = _find_first_internal_door_marker(n)
		if found:
			return found
	return null
	
func _sanitize_internal_door_markers(root_node: Node) -> void:
	# copy the children list to avoid mutation while iterating
	for node in root_node.get_children().duplicate():
		_sanitize_internal_door_markers(node)
		if node is Marker2D and node.name.begins_with("Door_"):
			node.name = "InternalMarker_%s" % node.name
		# Also, add the node to an internal group so other systems can still find them if needed
		if node is Marker2D and node.name.begins_with("InternalMarker_"):
			node.add_to_group("Door_Internal")

# --- DOOR SPAWNING ---------------------------------------------------
func spawn_doors() -> void:
	var ysorted_parent = get_tree().get_root().find_child("YSortedNode", true, false)
	if not ysorted_parent:
		push_warning("Could not find YSortedNode; using current parent instead.")
		ysorted_parent = get_parent()
		
	# Only consider direct children that are Marker2D and whose name begins with "Door_"
	for child in get_children():
		if child is Marker2D and child.name.begins_with("Door_"):
			var door_name = child.name + ".tscn"
			var door_path = door_folder_path + door_name
			
			if ResourceLoader.exists(door_path):
				var door_scene = load(door_path)
				var door_instance = _spawn_door(door_scene, ysorted_parent, child)
				_spawned_doors.append(door_instance)
			else:
				push_warning("Missing door scene for marker: %s" % door_path)

# --- ENEMY HANDLING ---------------------------------------------------

func spawn_enemies() -> void:
	if not enemy_scene:
		push_error("No enemy scene set for room %s" % name)
		return
		
	var ysorted_parent: Node = get_tree().get_root().find_child("YSortedNode", true, false)
	if not ysorted_parent:
		push_warning("Could not find YSortedNode; using current parent instead.")
		ysorted_parent = get_parent()
		
	var spawn_points: Array = []
	for child in get_children():
		if child.name.begins_with("EnemySpawn") and child is Marker2D:
			spawn_points.append(child)
			
	if spawn_points.is_empty():
		push_warning("No EnemySpawn markers in %s" % name)
		return
		
	spawn_enemies_staggered(ysorted_parent, spawn_points)

func spawn_enemies_staggered(ysorted_parent: Node, spawn_points: Array) -> void:
	spawn_next_enemy(ysorted_parent, spawn_points, 0)

func spawn_next_enemy(ysorted_parent: Node, spawn_points: Array, index: int) -> void:
	if index >= enemies_to_spawn:
		return
		
	var spawn_point = spawn_points[index % spawn_points.size()]
	var enemy = enemy_scene.instantiate()
	ysorted_parent.add_child(enemy)
	enemy.global_position = spawn_point.global_position
	_enemies.append(enemy)
	
	enemy.tree_exited.connect(_on_enemy_died.bind(enemy))
	
	var timer = get_tree().create_timer(spawn_interval)
	timer.timeout.connect(func():
		spawn_next_enemy(ysorted_parent, spawn_points, index + 1)
	)

func _on_enemy_died(enemy: Node) -> void:
	_enemies.erase(enemy)
	if _enemies.is_empty():
		deactivate_room()

# --- MOVE YSORTED OBJECTS --------------------------------------------
func move_prefab_ysorted_objects() -> void:
	var ysorted_parent = get_tree().get_root().find_child("YSortedNode", true, false)
	if not ysorted_parent:
		push_warning("Could not find YSortedNode in scene tree")
		return
		
	var local_ysorted_objects = get_node_or_null("YSortedObjects")
	if not local_ysorted_objects:
		return
		
	for obj in local_ysorted_objects.get_children():
		var global_xform = obj.global_transform
		obj.get_parent().remove_child(obj)
		ysorted_parent.add_child(obj)
		obj.global_transform = global_xform
