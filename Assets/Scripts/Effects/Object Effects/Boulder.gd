extends CharacterBody2D

@export var max_health: int = 40
var Health: int = max_health
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("Damageable")

func deal_damage(amount: int, from_pos: Vector2 = Vector2.ZERO) -> void:
	Health -= amount
	flash_hit()
	if Health <= 0:
		break_apart()

func flash_hit() -> void:
	if not sprite:
		return
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)

func break_apart() -> void:
	# Add crumble/debris logic or animation here if desired
	queue_free()
