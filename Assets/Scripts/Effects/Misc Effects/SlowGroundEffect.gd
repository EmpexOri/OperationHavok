extends GroundEffect
class_name SlowGroundEffect

@export var slow_multiplier: float = 0.5
@export var fade_time: float = 1.0       

var slow_counts: Dictionary = {}  # { player: count }
var fade_timer := 0.0
var fading := false

@onready var sprite: CanvasItem = get_node_or_null("Sprite2D")

func _ready():
	damage_area.body_entered.connect(_on_body_entered)
	damage_area.body_exited.connect(_on_body_exited)

	tick_timer.wait_time = tick_rate
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()

	if duration > 0:
		var lifetime_timer = get_tree().create_timer(duration, false)
		lifetime_timer.timeout.connect(Callable(self, "_start_fade_out"))

func _process(delta: float) -> void:
	# Handle fading
	if fading and sprite:
		fade_timer += delta
		var alpha: float = clamp(1.0 - (fade_timer / fade_time), 0.0, 1.0)
		sprite.modulate.a = alpha
		if alpha <= 0.0:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	super._on_body_entered(body)
	if not body.is_in_group("Player"):
		return
		
	if not "BaseSpeed" in body:
		body.BaseSpeed = body.MoveSpeed
		
	if not slow_counts.has(body):
		slow_counts[body] = 0
	slow_counts[body] += 1
	_update_player_speed(body)

func _on_body_exited(body: Node2D) -> void:
	super._on_body_exited(body)
	if body.is_in_group("Player") and slow_counts.has(body):
		slow_counts[body] -= 1
		if slow_counts[body] <= 0:
			slow_counts.erase(body)
		_update_player_speed(body)

func _exit_tree() -> void:
	# Restore speeds of players
	for player in slow_counts.keys():
		if is_instance_valid(player) and "BaseSpeed" in player:
			player.MoveSpeed = player.BaseSpeed
	slow_counts.clear()

func _update_player_speed(player):
	if not is_instance_valid(player) or not "BaseSpeed" in player:
		return
		
	var count = slow_counts.get(player, 0)
	player.MoveSpeed = player.BaseSpeed * pow(slow_multiplier, count)

func _start_fade_out() -> void:
	fading = true
	fade_timer = 0.0
