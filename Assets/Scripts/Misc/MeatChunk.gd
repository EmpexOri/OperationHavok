extends RigidBody2D

@export var min_speed: float = 300
@export var max_speed: float = 600
@export var control_time: float = 0.2
@export var min_torque: float = -50
@export var max_torque: float = 50

@export var blood_smear_scene: PackedScene
@export var smear_interval: float = 0.05
@export var chunk_textures: Array[Texture2D]

# Max allowed chunks at once
const MAX_MEAT_CHUNKS = 50

# Static array to track all meat chunks globally
static var active_chunks := []

var move_direction: Vector2
var move_speed: float
var time_left: float
var smear_timer: float

func _ready():
	_register_chunk()

	randomize()

	randomize_sprite()
	setup_movement()
	setup_timer()

func _physics_process(delta):
	if time_left > 0.0:
		time_left -= delta
		linear_velocity = move_direction * move_speed

	smear_timer -= delta
	if smear_timer <= 0.0:
		smear_timer += smear_interval  # += for better timing accuracy
		spawn_blood_smear()
	
	# Clamp position inside viewport bounds
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

func _register_chunk():
	active_chunks.append(self)
	if active_chunks.size() > MAX_MEAT_CHUNKS:
		var oldest = active_chunks.pop_front()
		if oldest.is_inside_tree():
			oldest.queue_free()

func _exit_tree():
	# Remove self from active list when freed
	active_chunks.erase(self)

func setup_movement():
	var angle = randf_range(0.0, TAU)
	move_direction = Vector2(cos(angle), sin(angle))
	move_speed = randf_range(min_speed, max_speed)
	time_left = control_time

	var torque = randf_range(min_torque, max_torque)
	apply_torque_impulse(torque)

func setup_timer():
	var timer = $Timer
	timer.timeout.connect(queue_free)
	timer.start()

func spawn_blood_smear():
	if blood_smear_scene:
		var smear = blood_smear_scene.instantiate()
		smear.global_position = global_position
		smear.z_index = -2
		get_tree().current_scene.add_child(smear)

func randomize_sprite():
	if chunk_textures.size() > 0:
		var sprite = $Sprite2D
		sprite.texture = chunk_textures.pick_random()
