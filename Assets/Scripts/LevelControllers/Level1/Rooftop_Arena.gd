extends Node2D
signal arena_complete

@export var beta_level_controller_path: NodePath = "/root/World/BetaLevelController"
@export var rooftop_elevator: NodePath  # assign the Rooftop_Elevator trigger in editor

# Enemy Scenes dictionary
var ENEMY_SCENES := {
	"Hordling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Hordling.tscn"),
	"Spewling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Spewling.tscn"),
	"Biomancer": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Biomancer.tscn"),
	"Needling": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Needling.tscn")
}

# Arena state
var arena_active := false
var current_wave := 0
var enemies: Array = []
var spawn_points: Array[Marker2D] = []
var wave_in_progress := false
var wave_ending := false

# Track which sub-arenas have been started
var sub_arena_started: Array = []

# Sub-arenas setup
var sub_arenas: Array = []

# Current sub-arena index
var current_sub_arena := 0

func _ready():
	# Auto-detect Marker2Ds if not manually assigned
	if spawn_points.size() == 0:
		for child in get_children():
			if child is Marker2D:
				spawn_points.append(child)

	# Define sub-arenas (example data)
	sub_arenas = [
		{
			"spawn_points": [$Spawn0, $Spawn1],
			"wave_data": [{ "Hordling": 12, "Spewling": 2 }]
		},
		{
			"spawn_points": [$Spawn2, $Spawn3],
			"wave_data": [{ "Hordling": 14, "Needling": 2 }]
		},
		{
			"spawn_points": [$Spawn4, $Spawn5],
			"wave_data": [{ "Hordling": 18, "Spewling": 8, "Needling": 2 }]
		}
	]

	# Initialize tracking to prevent double triggers
	sub_arena_started.clear()
	for i in range(sub_arenas.size()):
		sub_arena_started.append(false)

	# Connect triggers 2 & 3 locally
	$RooftopTrigger_2.body_entered.connect(_on_RooftopTrigger_2_body_entered)
	$RooftopTrigger_3.body_entered.connect(_on_RooftopTrigger_3_body_entered)
	$RooftopTrigger_2.monitoring = false
	$RooftopTrigger_3.monitoring = false

# -------------------
# Arena control
# -------------------
func activate_arena():
	if arena_active:
		return
	arena_active = true
	current_sub_arena = 0
	start_sub_arena(0)  # Sub-Arena 1 starts automatically

func start_sub_arena(index: int):
	if index >= sub_arenas.size() or sub_arena_started[index]:
		return

	sub_arena_started[index] = true
	current_sub_arena = index
	var sub = sub_arenas[index]

	# safely assign spawn points
	spawn_points.clear()
	for sp in sub.get("spawn_points", []):
		if sp is Marker2D:
			spawn_points.append(sp)

	current_wave = 0
	print("Starting Rooftop Sub-Arena %d" % (index + 1))
	start_next_wave()

func start_next_wave():
	if not arena_active or wave_in_progress:
		return

	var sub = sub_arenas[current_sub_arena]
	var waves = sub.get("wave_data", [])

	if current_wave >= waves.size():
		wave_in_progress = false
		print("Sub-Arena %d complete" % (current_sub_arena + 1))
		
		# Enable the next trigger only after this sub-arena is complete
		if current_sub_arena == 0:
			$RooftopTrigger_2.monitoring = true
		elif current_sub_arena == 1:
			$RooftopTrigger_3.monitoring = true
		else:
			arena_completed()
			
		return

	wave_in_progress = true
	var data = waves[current_wave]
	current_wave += 1
	print("Spawning wave %d in Sub-Arena %d" % [current_wave, current_sub_arena])
	await spawn_wave_enemies(data)

func spawn_wave_enemies(data: Dictionary) -> void:
	for key in data.keys():
		var count = data[key]
		var scene = ENEMY_SCENES.get(key, null)
		if not scene:
			continue
		for i in range(count):
			spawn_enemy(scene)
			await get_tree().create_timer(randf_range(0.05, 0.25)).timeout

func spawn_enemy(scene: PackedScene) -> void:
	if spawn_points.size() == 0:
		push_error("No spawn points assigned!")
		return

	var enemy = scene.instantiate()
	var spawn = spawn_points[randi() % spawn_points.size()]
	enemy.position = spawn.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	enemy.name = "Enemy_%d" % randi()
	enemies.append(enemy)
	add_child(enemy)
	enemy.connect("died", Callable(self, "_on_enemy_died"))

func _on_enemy_died(enemy):
	enemies.erase(enemy)
	if enemies.size() == 0 and not wave_ending:
		wave_ending = true
		await get_tree().create_timer(0.5).timeout
		wave_in_progress = false
		wave_ending = false
		start_next_wave()

func arena_completed():
	arena_active = false
	GlobalEffects.activate_xp_buff(5000, 5.0)
	print("Rooftop Arena complete!")
	emit_signal("arena_complete")

	# Enable Rooftop Elevator
	var controller = get_node_or_null(beta_level_controller_path)
	if controller:
		if rooftop_elevator:
			var elevator = get_node_or_null(rooftop_elevator)
			if elevator:
				elevator.monitoring = true
				print("Rooftop Elevator enabled!")

		# Map arena name to actual respawn key
		var checkpoint_flag := "parkinglot"  # the marker you actually registered in Player
		controller._set_checkpoint(checkpoint_flag)
	else:
		push_error("BetaLevelController not found at path: %s" % beta_level_controller_path)

# -------------------
# Triggers 2 & 3 (manual sub-arena activation)
# -------------------
func _on_RooftopTrigger_2_body_entered(body):
	if body.is_in_group("Player"):
		start_sub_arena(1)  # Sub-Arena 2
		$RooftopTrigger_2.monitoring = false

func _on_RooftopTrigger_3_body_entered(body):
	if body.is_in_group("Player"):
		start_sub_arena(2)  # Sub-Arena 3
		$RooftopTrigger_3.monitoring = false

func reset_arena():
	wave_in_progress = false
	wave_ending = false
	current_wave = 0
	arena_active = false

	for e in enemies:
		if e.is_inside_tree():
			e.queue_free()
	enemies.clear()

	# Refresh spawn points if necessary
	spawn_points.clear()
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
