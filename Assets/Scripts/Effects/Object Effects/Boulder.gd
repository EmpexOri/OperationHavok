extends CharacterBody2D
class_name Boulder

@export var health: int = 100
@onready var sprite: Sprite2D = $Sprite2D 

func deal_damage(amount: int, from_position: Vector2, source: Node = null) -> void:
	health -= amount
	print("Boulder hit for ", amount, " from ", source)
	flash_hit()
	if health <= 0:
		queue_free()

func flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
