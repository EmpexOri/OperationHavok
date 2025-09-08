extends Node2D
class_name GroundEffect

@export var damage_per_tick: float = 5.0
@export var tick_rate: float = 1.0       # seconds between damage ticks
@export var affects_enemies: bool = true
@export var affects_players: bool = false
@export var duration: float = 5.0        # how long effect lasts, 0 = infinite

@onready var damage_area: Area2D = $DamageArea
@onready var tick_timer: Timer = $TickTimer

var bodies_in_area: Array = []

func _ready() -> void:
	# Freeze this node when paused
	process_mode = Node.PROCESS_MODE_PAUSABLE  

	tick_timer.wait_time = tick_rate
	tick_timer.process_mode = Node.PROCESS_MODE_PAUSABLE  # Timer respects pause
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()

	damage_area.body_entered.connect(_on_body_entered)
	damage_area.body_exited.connect(_on_body_exited)

	for body in damage_area.get_overlapping_bodies():
		_on_body_entered(body)

	# Auto-despawn after duration (respects pause)
	if duration > 0:
		var lifetime_timer = get_tree().create_timer(duration, false)
		await lifetime_timer.timeout
		queue_free()

func _on_tick() -> void:
	for body in bodies_in_area:
		if is_instance_valid(body):
			if body.is_in_group("Enemy") and affects_enemies:
				if body.has_method("deal_damage"):
					body.deal_damage(damage_per_tick, global_position)
			if body.is_in_group("Player") and affects_players:
				if body.has_method("deal_damage"):
					body.deal_damage(damage_per_tick, global_position)

func _on_body_entered(body: Node2D) -> void:
	if (affects_enemies and body.is_in_group("Enemy")) \
	or (affects_players and body.is_in_group("Player")):
		if not bodies_in_area.has(body):
			bodies_in_area.append(body)

func _on_body_exited(body: Node2D) -> void:
	bodies_in_area.erase(body)
