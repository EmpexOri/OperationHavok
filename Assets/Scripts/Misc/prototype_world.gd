extends Node2D

var Hordling = preload("res://Prefabs/Enemy/Hordling.tscn")
var Spewling = preload("res://Prefabs/Enemy/Spewling.tscn")
var Biomancer = preload("res://Prefabs/Enemy/Biomancer.tscn")
var Needling = preload("res://Prefabs/Enemy/Needling.tscn")
var Tumor = preload("res://Prefabs/Enemy/Tumor.tscn")

var PauseMenu = preload("res://Scenes/Options/PauseMenu.tscn").instantiate()

func _ready():
	# Start spawn timers
	start_spawn_timer1()
	start_spawn_timer2()
	start_spawn_timer3()
	start_spawn_timer4()
	start_spawn_timer5()
	
	# Add PauseMenu to the scene, but keep it hidden initially
	add_child(PauseMenu)
	PauseMenu.visible = false
	
# Handle input events like Escape key
func _input(event):
	if Input.is_action_just_pressed("InGameOptions"):  # Escape key or your custom key mapping
		GlobalAudioController.PauseMenuMusic()
		PauseMenu.show_pause_menu()
		pause_game()

# Function to display or hide the pause menu when game is paused
func pause_game():
	if get_tree().paused:
		# Unpause the game and hide the pause menu
		get_tree().paused = false
		PauseMenu.visible = false
	else:
		# Pause the game and show the pause menu
		get_tree().paused = true
		PauseMenu.visible = true


func start_spawn_timer1():
	var timer = Timer.new()
	timer.wait_time = randf_range(0.1, 0.5)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn_enemy1")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func spawn_enemy1():
	var EnemyInstance = Hordling.instantiate()
	EnemyInstance.name = "Enemy_" + str(randi()) # Assigns a unique named
	var viewport = get_viewport_rect().size
	var random_x = randf_range(0, viewport.x)  # Random X position
	var random_y = randf_range(0, viewport.y)  # Random Y position
	EnemyInstance.position = Vector2(randf_range(100, random_x), randf_range(100, random_y))
	add_child(EnemyInstance)
	
	start_spawn_timer1()
	
	###############################################################################################################
	
func start_spawn_timer2():
	var timer = Timer.new()
	timer.wait_time = randf_range(3, 4)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn_enemy2")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func spawn_enemy2():
	var EnemyInstance = Spewling.instantiate()
	EnemyInstance.name = "Enemy_" + str(randi()) # Assigns a unique named
	var viewport = get_viewport_rect().size
	var random_x = randf_range(0, viewport.x)  # Random X position
	var random_y = randf_range(0, viewport.y)  # Random Y position
	EnemyInstance.position = Vector2(randf_range(100, random_x), randf_range(100, random_y))
	EnemyInstance.position = Vector2(randf_range(100, 700), randf_range(100, 500))
	add_child(EnemyInstance)
	
	start_spawn_timer2()

	###############################################################################################################
	
func start_spawn_timer3():
	var timer = Timer.new()
	timer.wait_time = randf_range(6, 9) # nice
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn_enemy3")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func spawn_enemy3():
	var EnemyInstance = Biomancer.instantiate()
	EnemyInstance.name = "Enemy_" + str(randi()) # Assigns a unique named
	var viewport = get_viewport_rect().size
	var random_x = randf_range(0, viewport.x)  # Random X position
	var random_y = randf_range(0, viewport.y)  # Random Y position
	EnemyInstance.position = Vector2(randf_range(100, random_x), randf_range(100, random_y))
	add_child(EnemyInstance)
	
	start_spawn_timer3()
	
	###############################################################################################################
	
func start_spawn_timer4():
	var timer = Timer.new()
	timer.wait_time = randf_range(5, 7)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn_enemy4")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func spawn_enemy4():
	var EnemyInstance = Needling.instantiate()
	EnemyInstance.name = "Enemy_" + str(randi()) # Assigns a unique named
	var viewport = get_viewport_rect().size
	var random_x = randf_range(0, viewport.x)  # Random X position
	var random_y = randf_range(0, viewport.y)  # Random Y position
	EnemyInstance.position = Vector2(randf_range(100, random_x), randf_range(100, random_y))
	add_child(EnemyInstance)
	
	start_spawn_timer4()
	
		###############################################################################################################
	
func start_spawn_timer5():
	var timer = Timer.new()
	timer.wait_time = randf_range(5, 7)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn_enemy5")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func spawn_enemy5():
	var EnemyInstance = Tumor.instantiate()
	EnemyInstance.name = "Enemy_" + str(randi()) # Assigns a unique named
	var viewport = get_viewport_rect().size
	var random_x = randf_range(0, viewport.x)  # Random X position
	var random_y = randf_range(0, viewport.y)  # Random Y position
	EnemyInstance.position = Vector2(randf_range(100, random_x), randf_range(100, random_y))
	add_child(EnemyInstance)
	
	start_spawn_timer5()
