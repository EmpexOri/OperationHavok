extends BasePickup
class_name PickupXpBuff

@export var bonus_range: float = 4000.0
@export var buff_duration: float = 5.0

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		# Activate the buff in GlobalEffects
		GlobalEffects.activate_xp_buff(bonus_range, buff_duration)
		queue_free()
