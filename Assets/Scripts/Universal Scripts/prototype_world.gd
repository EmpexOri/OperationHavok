extends Node2D

var Enemy = preload("res://enemy.tscn")
var Enemy2 = preload("res://enemy_2.tscn")
var Enemy3 = preload("res://enemy_3.tscn")
var Enemy4 = preload("res://enemy_4.tscn")

func _ready():
	start_spawn_timer1()
	start_spawn_timer2()
	start_spawn_timer3()
	start_spawn_timer4()

func start_spawn_timer1():
	var timer = Timer.new()
	timer.wait_time = randf_range(1, 4)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn_enemy1")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func spawn_enemy1():
	var EnemyInstance = Enemy.instantiate()
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
	timer.wait_time = randf_range(5, 7)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn_enemy2")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func spawn_enemy2():
	var EnemyInstance = Enemy2.instantiate()
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
	timer.wait_time = randf_range(8, 13)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn_enemy3")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func spawn_enemy3():
	var EnemyInstance = Enemy3.instantiate()
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
	timer.wait_time = randf_range(10, 15)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn_enemy4")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func spawn_enemy4():
	var EnemyInstance = Enemy4.instantiate()
	EnemyInstance.name = "Enemy_" + str(randi()) # Assigns a unique named
	var viewport = get_viewport_rect().size
	var random_x = randf_range(0, viewport.x)  # Random X position
	var random_y = randf_range(0, viewport.y)  # Random Y position
	EnemyInstance.position = Vector2(randf_range(100, random_x), randf_range(100, random_y))
	add_child(EnemyInstance)
	
	start_spawn_timer4()
