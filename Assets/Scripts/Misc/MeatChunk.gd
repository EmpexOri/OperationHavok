extends RigidBody2D

@export var min_speed: float = 300
@export var max_speed: float = 600
@export var control_time: float = 0.2
@export var min_torque: float = -50
@export var max_torque: float = 50

@export var blood_smear_scene: PackedScene
@export var smear_interval: float = 0.05

@export var chunk_textures: Array[Texture2D]  # Drag your chunk sprites here!

var move_direction := Vector2.ZERO
var move_speed := 0.0
var time_left := 0.0
var smear_timer := 0.0

func _ready():
	randomize()

	# Randomize visual appearance
	randomize_sprite()

	# Pick random angle
	var angle = randf_range(0, TAU)
	move_direction = Vector2(cos(angle), sin(angle)).normalized()

	# Pick random speed
	move_speed = randf_range(min_speed, max_speed)

	# Set timer for how long we "control" it
	time_left = control_time

	# Apply random torque at start
	var torque = randf_range(min_torque, max_torque)
	apply_torque_impulse(torque)

	# Start despawn timer
	var timer = $Timer
	timer.timeout.connect(queue_free)
	timer.start()

func _physics_process(delta):
	if time_left > 0:
		time_left -= delta
		linear_velocity = move_direction * move_speed
	else:
		linear_velocity = linear_velocity

	smear_timer -= delta
	if smear_timer <= 0:
		smear_timer = smear_interval
		spawn_blood_smear()

func spawn_blood_smear():
	if blood_smear_scene:
		var smear = blood_smear_scene.instantiate()
		smear.global_position = global_position
		smear.z_index = -2
		get_tree().current_scene.add_child(smear)

func randomize_sprite():
	if chunk_textures.size() > 0:
		var sprite = $Sprite2D
		sprite.texture = chunk_textures[randi() % chunk_textures.size()]
