extends GroundEffect
class_name SlowGroundEffect

@export var slow_multiplier: float = 0.8   # 80% speed
@export var affects_only_player: bool = true

var slowed_players: Dictionary = {}  # {player: original_speed}

func _on_body_entered(body: Node2D) -> void:
	# Call parent so damage still works
	super._on_body_entered(body)

	if body.is_in_group("Player"):
		if not slowed_players.has(body):
			if body.has_variable("MoveSpeed"):
				slowed_players[body] = body.MoveSpeed
				body.MoveSpeed *= slow_multiplier
				print("Player slowed to: ", body.MoveSpeed)

func _on_body_exited(body: Node2D) -> void:
	# Call parent so damage tracking still works
	super._on_body_exited(body)

	if body.is_in_group("Player"):
		if slowed_players.has(body):
			if body.has_variable("MoveSpeed"):
				body.MoveSpeed = slowed_players[body]
				print("Player speed restored to: ", body.MoveSpeed)
			slowed_players.erase(body)
