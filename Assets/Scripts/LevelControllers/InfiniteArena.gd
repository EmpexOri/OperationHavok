extends Node2D

# ============================================================
# CONFIGURATION
# ============================================================

@onready var spawn_points = $SpawnPoints.get_children()
@onready var warmachine_spawn_points = $WarmmachineSpawns.get_children()
@onready var ysorted_root: Node2D = get_node("/root/MegaTrials/YSortedObjects")

const PAUSE_MENU_SCENE := preload("res://Scenes/Options/PauseMenu.tscn")
@onready var pause_menu: PauseNode = PAUSE_MENU_SCENE.instantiate() as PauseNode

# Enemy scenes
var enemy_scenes := {
	"Hordling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Hordling.tscn"),
	"Spewling": preload("res://Prefabs/GamePrefabs/Enemy/hoard_enemy_prefabs/Spewling.tscn"),

	"Biomancer": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Biomancer.tscn"),
	"Needling": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Needling.tscn"),
	"Gatling": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Gatling.tscn"),
	"Tumor": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Tumor.tscn"),

	"Network": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Network.tscn"),
	"Goolum": preload("res://Prefabs/GamePrefabs/Enemy/elite_enemy_prefabs/Goolum.tscn"),

	"Warmachine": preload("res://Prefabs/GamePrefabs/Enemy/Minibosses/Warmachine.tscn"),
	"WarmachineRocket": preload("res://Prefabs/GamePrefabs/Enemy/Minibosses/Warmachine_Rocket.tscn")
}

# Runtime state
var infinite_wave: int = 0
var wave_in_progress := false
var alive_enemies: Array = []

func _ready() -> void:
	# Wait for one frame so the tree is ready
	await get_tree().process_frame
	
	# Add Pause Menu
	add_child(pause_menu)
	pause_menu.visible = false
	
	# Start infinite mode after a small delay
	await get_tree().create_timer(1.0).timeout
	start_infinite_mode()
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("InGameOptions"):
		_toggle_pause()
		
func _toggle_pause() -> void:
	if pause_menu.visible:
		pause_menu.visible = false
		get_tree().paused = false
	else:
		pause_menu.visible = true
		get_tree().paused = true
		if pause_menu.has_method("show_pause_menu"):
			pause_menu.show_pause_menu()

# ============================================================
# START INFINITE MODE
# ============================================================

func start_infinite_mode() -> void:
	print("Infinite Mode Starting")
	infinite_wave = 0
	await _start_next_wave()

# ============================================================
# WAVE LOOP HANDLER
# ============================================================

func _start_next_wave() -> void:
	if wave_in_progress:
		return

	infinite_wave += 1
	wave_in_progress = true

	print("\n=== Wave %d ===" % infinite_wave)

	var wave_data: Dictionary = generate_wave(infinite_wave)
	await _spawn_wave(wave_data)

	await _wait_for_all_dead()

	wave_in_progress = false
	await _start_next_wave()

# ============================================================
# WAVE GENERATION
# ============================================================

func generate_wave(round: int) -> Dictionary:
	var wave := {}

	var fodder_scale: float = 1.0 + round * 0.15
	var elite_scale: float = clamp(round * 0.1, 0.0, 3.0)
	var support_scale: float = clamp((round - 5) * 0.1, 0.0, 2.0)
	var miniboss_scale: float = clamp((round - 10) * 0.05, 0.0, 1.5)

	wave["Hordling"] = int(6 * fodder_scale)
	wave["Spewling"] = int(2 * fodder_scale)

	if round >= 3:
		wave["Needling"] = int(1 * elite_scale)
		wave["Biomancer"] = int(1 * elite_scale)
		wave["Gatling"] = int(1 * elite_scale)
		wave["Tumor"] = int(1 * elite_scale)

	if round >= 5:
		wave["Network"] = int(1 * support_scale)
		wave["Goolum"] = int(1 * support_scale)

	if round >= 10:
		var count: int = max(1, int(miniboss_scale))
		if randi() % 2 == 0:
			wave["Warmachine"] = count
		else:
			wave["WarmachineRocket"] = count

	if round >= 20:
		wave["Warmachine"] = 1 + round / 5
		wave["WarmachineRocket"] = 1 + round / 5

	return wave

# ============================================================
# SPAWNING (SAFE + PACED)
# ============================================================

func _spawn_wave(wave_data: Dictionary) -> void:
	for enemy_type in wave_data.keys():
		var amount: int = wave_data[enemy_type]
		if amount <= 0:
			continue

		# Spawn in batches of 5 to reduce physics load
		var remaining := amount
		while remaining > 0:
			var batch := int(min(5, remaining))
			for i in range(batch):
				await _spawn_enemy(enemy_type)
			remaining -= batch
			await get_tree().create_timer(randf_range(0.05, 0.2)).timeout


func _spawn_enemy(enemy_type: String) -> void:
	if not enemy_scenes.has(enemy_type):
		push_warning("Unknown enemy type: %s" % enemy_type)
		return

	var scene: PackedScene = enemy_scenes[enemy_type]
	var enemy = scene.instantiate()

	var is_warmachine := (
		enemy_type == "Warmachine"
		or enemy_type == "WarmachineRocket"
	)

	var spawn_point: Marker2D = null

	if is_warmachine and warmachine_spawn_points.size() > 0:
		spawn_point = warmachine_spawn_points.pick_random()
	else:
		spawn_point = spawn_points.pick_random()

	if spawn_point:
		enemy.global_position = spawn_point.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	else:
		enemy.global_position = global_position

	ysorted_root.add_child(enemy)
	alive_enemies.append(enemy)

	if enemy.has_signal("died"):
		enemy.connect("died", Callable(self, "_on_enemy_died"))

	if enemy.has_method("scale_stats"):
		enemy.scale_stats(1.0 + infinite_wave * 0.10)

	# Warmachines spawn slower
	await get_tree().create_timer(0.15 if is_warmachine else 0.05).timeout

# ============================================================
# DEATH CHECK
# ============================================================

func _on_enemy_died(enemy) -> void:
	alive_enemies.erase(enemy)


func _wait_for_all_dead() -> void:
	while alive_enemies.size() > 0:
		await get_tree().create_timer(0.2).timeout
