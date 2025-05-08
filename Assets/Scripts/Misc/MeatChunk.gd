extends RigidBody2D

@export var min_speed: float = 300
@export var max_speed: float = 600
@export var control_time: float = 0.2
@export var min_torque: float = -50
@export var max_torque: float = 50

@export var blood_smear_scene: PackedScene
@export var smear_interval: float = 0.05
@export var chunk_textures: Array[Texture2D]

@export var fade_duration: float = 1.0
var fade_time_left: float = 0.0
var is_fading: bool = false

# Max allowed chunks at once
const MAX_MEAT_CHUNKS = 1000

# Static array to track all meat chunks globally
static var active_chunks := []

var move_direction: Vector2
var move_speed: float
var time_left: float
var smear_timer: float

func _ready():
	$FadeTimer.timeout.connect(_on_fade_timer_timeout)
	$FadeTimer.start()

	_register_chunk()

	randomize()

	randomize_sprite()
	setup_movement()
	setup_timer()

func _physics_process(delta):
	if time_left > 0.0:
		time_left -= delta
		linear_velocity = move_direction * move_speed

	if is_fading:
		fade_time_left -= delta
		var alpha = clamp(fade_time_left / fade_duration, 0, 1)
		$Sprite2D.modulate.a = alpha  # Set alpha of the sprite
		if fade_time_left <= 0:
			queue_free()

	smear_timer -= delta
	if smear_timer <= 0.0:
		smear_timer += smear_interval
		spawn_blood_smear()

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
	timer.wait_time = randf_range(1.5, 3.5)  # Random lifetime between 1.5 and 3.5 seconds
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	timer.start()

func spawn_blood_smear():
	if blood_smear_scene:
		SmearManager.spawn_smear(global_position)

func randomize_sprite():
	if chunk_textures.size() > 0:
		var sprite = $Sprite2D
		sprite.texture = chunk_textures.pick_random()

func _on_fade_timer_timeout():
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true  # Disable further physics movement
	fade_time_left = fade_duration
	is_fading = true
