extends Node2D

@export var room_scenes: Array[PackedScene]
@export var cap_scenes_north: Array[PackedScene]
@export var cap_scenes_south: Array[PackedScene]
@export var cap_scenes_east: Array[PackedScene]
@export var cap_scenes_west: Array[PackedScene]

@export var spacer_room_scene: PackedScene  

@export var start_room_scene: PackedScene
@export var player_scene: PackedScene

@export var room_count: int = 8
@export var max_attempts_per_room: int = 12

var dungeon_root: Node2D
var placed_rooms: Array = []
var available_doors: Array = []  # { room, marker, direction }

func _ready():
	randomize()
	generate_dungeon()

func generate_dungeon():
	if room_scenes.is_empty():
		push_error("No room scenes assigned!")
		return
		
	dungeon_root = Node2D.new()
	add_child(dungeon_root)
	
	# --- Start Room ---
	var start_room: Node2D
	if start_room_scene:
		start_room = start_room_scene.instantiate()
	else:
		start_room = _instantiate_room()
	dungeon_root.add_child(start_room)
	placed_rooms.append(start_room)
	_register_doors(start_room)
	
	# Spawn player
	if player_scene:
		var player_spawn = start_room.get_node_or_null("Player_Spawn")
		if player_spawn:
			var player = player_scene.instantiate()
			var ysorted_parent = get_parent().get_node_or_null("YSortedNode")
			if ysorted_parent:
				ysorted_parent.add_child(player)
			else:
				push_warning("YSortedNode not found! Adding player to dungeon_root instead.")
				dungeon_root.add_child(player)
			player.global_position = player_spawn.global_position
		else:
			push_error("No PlayerSpawn marker found in Start Room!")

	# --- Spacer Room ---
	if spacer_room_scene:
		var spacer_room = spacer_room_scene.instantiate()
		var spacer_door: Marker2D = null  # Declare here

		# Pick a door in start room to connect
		var start_door: Marker2D = start_room.get_node_or_null("Door_North")
		if not start_door:
			push_error("Start room has no Door_North!")
		else:
			# Find the opposite door in the spacer room
			var opposite_dir = _get_opposite_dir("North")
			spacer_door = spacer_room.get_node_or_null("Door_" + opposite_dir)
			if not spacer_door:
				push_error("Spacer room has no Door_" + opposite_dir + "!")
			else:
				# Align spacer room
				spacer_room.global_position += start_door.global_position - spacer_door.global_position

				# Remove the connecting doors from available_doors so they won't be capped
				available_doors = available_doors.filter(func(d):
					return d["marker"] != start_door
				)

		dungeon_root.add_child(spacer_room)
		placed_rooms.append(spacer_room)

		# Register all other doors of the spacer room (except the one connecting to start)
		for door in spacer_room.get_children():
			if door is Marker2D and door != spacer_door and door.name.begins_with("Door_"):
				available_doors.append({
					"room": spacer_room,
					"marker": door,
					"direction": door.name.replace("Door_", "")
				})

	# --- Controlled room placement ---
	var placed_normal_rooms := 0
	var attempts := 0
	while placed_normal_rooms < room_count and attempts < room_count * max_attempts_per_room:
		if _try_place_room():
			placed_normal_rooms += 1
		attempts += 1

	print("Generated ", placed_normal_rooms, " normal rooms after ", attempts, " attempts.")

	# --- Cap remaining doors ---
	_cap_remaining_doors()
	
func _instantiate_room() -> Node2D:
	if room_scenes.is_empty():
		push_error("No room scenes assigned!")
		return null
	return room_scenes.pick_random().instantiate()
	
func _instantiate_cap_for_direction(dir: String) -> Node2D:
	var cap_array: Array
	match dir:
		"North": cap_array = cap_scenes_north
		"South": cap_array = cap_scenes_south
		"East": cap_array = cap_scenes_east
		"West": cap_array = cap_scenes_west
		_: return null
	
	if cap_array.is_empty():
		return null
	return cap_array.pick_random().instantiate()
	
func _register_doors(room: Node2D) -> void:
	for door in room.get_children():
		if door is Marker2D and door.name.begins_with("Door_"):
			available_doors.append({
				"room": room,
				"marker": door,
				"direction": door.name.replace("Door_", "")
			})
			
# --- Attempt to place a room at a random available door ---
func _try_place_room() -> bool:
	if available_doors.is_empty():
		return false
		
	# Shuffle doors to try a different order each call
	available_doors.shuffle()
	
	for base_door_data in available_doors.duplicate():
		var base_dir = base_door_data["direction"]
		
		var room_attempts := 0
		while room_attempts < max_attempts_per_room:
			var new_room = _instantiate_room()
			if not new_room:
				room_attempts += 1
				continue
				
			# Collect all doors in the new room
			var new_room_doors: Array = []
			for child in new_room.get_children():
				if child is Marker2D and child.name.begins_with("Door_"):
					new_room_doors.append(child)
					
			var opposite = _get_opposite_dir(base_dir)
			var matching_doors = new_room_doors.filter(func(d): return d.name == "Door_" + opposite)
			if matching_doors.is_empty():
				new_room.queue_free()
				room_attempts += 1
				continue
				
			var new_door = matching_doors.pick_random()
			var offset = base_door_data["marker"].global_position - new_door.global_position
			new_room.global_position += offset
			
			# Check overlap with **all existing rooms**
			var overlaps := false
			for existing in placed_rooms:
				if _rooms_overlap(existing, new_room):
					overlaps = true
					break
					
			if overlaps:
				new_room.queue_free()
				room_attempts += 1
				continue
				
			available_doors.erase(base_door_data)
			dungeon_root.add_child(new_room)
			placed_rooms.append(new_room)
			
			for door in new_room_doors:
				if door != new_door:
					available_doors.append({
						"room": new_room,
						"marker": door,
						"direction": door.name.replace("Door_", "")
					})
			return true
			
		_cap_single_door(base_door_data)
		available_doors.erase(base_door_data)

	return false

# --- Check room overlap with padding ---
func _rooms_overlap(room_a: Node2D, room_b: Node2D) -> bool:
	var padding := 8  # pixels of extra buffer
	var rect_a = _get_room_bounds(room_a).grow(padding)
	var rect_b = _get_room_bounds(room_b).grow(padding)
	return rect_a.intersects(rect_b)

# --- Force cap a single door if room cannot fit ---
func _cap_single_door(door_data):
	var cap = _instantiate_cap_for_direction(door_data["direction"])
	if not cap:
		return
	var cap_door = cap.get_node_or_null("Door_" + _get_opposite_dir(door_data["direction"]))
	if not cap_door:
		cap.queue_free()
		return
	var offset = door_data["marker"].global_position - cap_door.global_position
	cap.global_position += offset
	dungeon_root.add_child(cap)

func _get_opposite_dir(dir: String) -> String:
	match dir:
		"North": return "South"
		"South": return "North"
		"East": return "West"
		"West": return "East"
		_: return ""

# --- Cap placement system ---
func _cap_remaining_doors() -> void:
	if cap_scenes_north.is_empty() and cap_scenes_south.is_empty() and cap_scenes_east.is_empty() and cap_scenes_west.is_empty():
		print("⚠️ No cap scenes set — skipping capping.")
		return
		
	print("Capping remaining doors: ", available_doors.size())
	
	for door_data in available_doors:
		var cap = _instantiate_cap_for_direction(door_data["direction"])
		if not cap:
			continue
			
		# Look for the opposite door marker on the cap
		var cap_door = cap.get_node_or_null("Door_" + _get_opposite_dir(door_data["direction"]))
		if not cap_door:
			cap.queue_free()
			continue
			
		# Align cap to existing door
		var offset = door_data["marker"].global_position - cap_door.global_position
		cap.global_position += offset
		
		dungeon_root.add_child(cap)

# --- Collision helpers ---

func _get_room_bounds(room: Node2D) -> Rect2:
	var padding: float = -8.0  # Small buffer to prevent tight fits

	# Try to find the Walls tilemap (child of Floor)
	var walls_tilemap: TileMapLayer = room.get_node_or_null("Floor/Walls")
	if walls_tilemap:
		var used_rect: Rect2i = walls_tilemap.get_used_rect()
		var cell_size: Vector2 = walls_tilemap.tile_set.tile_size
		var rect_pos: Vector2 = Vector2(used_rect.position.x, used_rect.position.y) * cell_size
		var rect_size: Vector2 = Vector2(used_rect.size.x, used_rect.size.y) * cell_size
		var rect: Rect2 = Rect2(rect_pos, rect_size)
		rect.position += room.global_position
		return rect.grow(padding)

	# Fallback: any TileMap in the room
	for child in room.get_children():
		if child is TileMap:
			var tilemap: TileMap = child
			var used_rect: Rect2i = tilemap.get_used_rect()
			var cell_size: Vector2 = tilemap.tile_set.tile_size
			var rect_pos: Vector2 = Vector2(used_rect.position.x, used_rect.position.y) * cell_size
			var rect_size: Vector2 = Vector2(used_rect.size.x, used_rect.size.y) * cell_size
			var rect: Rect2 = Rect2(rect_pos, rect_size)
			rect.position += room.global_position
			return rect.grow(padding)
		elif child is Sprite2D:
			var sprite: Sprite2D = child
			var size: Vector2 = sprite.texture.get_size()
			var rect: Rect2 = Rect2(sprite.position - size / 2, size)
			rect.position += room.global_position
			return rect.grow(padding)

	# Safety fallback
	return Rect2(room.global_position - Vector2(64, 64), Vector2(128, 128))
