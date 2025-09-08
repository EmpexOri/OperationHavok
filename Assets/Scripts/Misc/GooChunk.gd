extends RigidBody2D
class_name GooChunk

@export var min_speed: float = 300
@export var max_speed: float = 600
@export var control_time: float = 0.2
@export var min_torque: float = -50
@export var max_torque: float = 50

@export var goo_effect_scene: PackedScene    
@export var chunk_textures: Array[Texture2D]

@export var puddle_interval: float = 0.3      # seconds between puddles
@export var fade_duration: float = 1.0

const MAX_GOO_CHUNKS = 300
static var active_chunks := []

const MIN_PUDDLE_DISTANCE := 16.0  # minimum distance between puddles
static var active_puddles: Array = []

var move_direction: Vector2
var move_speed: float
var time_left: float
var puddle_timer: float

var fade_time_left: float = 0.0
var is_fading: bool = false
var disable_collision_time: float = 0.2

func _ready():
	$FadeTimer.timeout.connect(_on_fade_timer_timeout)
	$FadeTimer.start()

	_register_chunk()
	randomize()
	randomize_sprite()
	setup_movement()
	setup_timer()

	# temporary collision disable
	set_collision_disabled(true)
	var collision_timer = Timer.new()
	collision_timer.one_shot = true
	collision_timer.wait_time = disable_collision_time
	collision_timer.timeout.connect(_enable_collision)
	add_child(collision_timer)
	collision_timer.start()

func _enable_collision():
	set_collision_disabled(false)

func _physics_process(delta):
	if time_left > 0.0 and not is_fading:
		time_left -= delta
		linear_velocity = move_direction * move_speed

	if is_fading:
		fade_time_left -= delta
		$Sprite2D.modulate.a = clamp(fade_time_left / fade_duration, 0, 1)
		if fade_time_left <= 0:
			queue_free()

	# Ensure puddle spawns keep up
	puddle_timer -= delta
	while puddle_timer <= 0.0:
		puddle_timer += puddle_interval
		spawn_goo_puddle()

func _register_chunk():
	active_chunks.append(self)
	if active_chunks.size() > MAX_GOO_CHUNKS:
		var oldest = active_chunks[0]
		active_chunks.remove_at(0)
		if oldest.is_inside_tree():
			oldest.queue_free()

func _exit_tree():
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
	timer.wait_time = randf_range(1.5, 2.5)
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	timer.start()

func spawn_goo_puddle():
	if not goo_effect_scene:
		return

	# Check existing puddles to avoid overlap
	for puddle in active_puddles:
		if not is_instance_valid(puddle):
			active_puddles.erase(puddle)
			continue
		if puddle.global_position.distance_to(global_position) < MIN_PUDDLE_DISTANCE:
			return  # Too close, skip spawning

	# Spawn the puddle
	var puddle_instance = goo_effect_scene.instantiate()
	puddle_instance.global_position = global_position
	get_tree().current_scene.add_child(puddle_instance)
	active_puddles.append(puddle_instance)

	# Clean up puddle from tracking after it exits tree
	puddle_instance.connect("tree_exited", Callable(self, "_on_puddle_exited").bind(puddle_instance))

func randomize_sprite():
	if chunk_textures.size() > 0:
		$Sprite2D.texture = chunk_textures.pick_random()

func _on_fade_timer_timeout():
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true
	fade_time_left = fade_duration
	is_fading = true

func set_collision_disabled(disabled: bool):
	$CollisionShape2D.disabled = disabled

func _on_puddle_exited(puddle):
	active_puddles.erase(puddle)
