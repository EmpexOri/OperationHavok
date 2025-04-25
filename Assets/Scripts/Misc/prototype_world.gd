extends Node2D

var Hordling = preload("res://Prefabs/Enemy/Hordling.tscn")
var Spewling = preload("res://Prefabs/Enemy/Spewling.tscn")
var Biomancer = preload("res://Prefabs/Enemy/Biomancer.tscn")
var Needling = preload("res://Prefabs/Enemy/Needling.tscn")

@onready var PausedLabel: Label = $PausedLayer/Title
@onready var ResumeButton: Button = $PausedLayer/ResumeButton
@onready var ControlsButton: Button = $PausedLayer/ControlsButton
@onready var OptionsButton: Button = $PausedLayer/OptionsButton
@onready var QuitButton: Button = $PausedLayer/QuitButton

func _ready():
	start_spawn_timer1()
	start_spawn_timer2()
	start_spawn_timer3()
	start_spawn_timer4()
	
	# Pause screen assets
	PausedLabel.visible = false
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	QuitButton.visible = false

func _process(_delta):
	# Make sure that the pause menu isn't being displayed when not paused
	if PausedLabel.visible:
		PausedLabel.visible = false
		ResumeButton.visible = false
		ControlsButton.visible = false
		OptionsButton.visible = false
		QuitButton.visible = false
		
func _input(event):
	if Input.is_action_just_pressed("InGameOptions"):
		GlobalAudioController.PauseMenuMusic()
		$PausedLayer/ResumeButton.grab_focus()
		pause_game()

# Function to display the pause menu when game is paused
func pause_game():
	PausedLabel.visible = true
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	QuitButton.visible = true
	get_tree().paused = true

func start_spawn_timer1():
	var timer = Timer.new()
	timer.wait_time = randf_range(1, 2)
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
