extends GroundEffect
class_name SlowGroundEffect

@export var slow_multiplier: float = 0.8	# 80% of normal speed

var slowed_players: Dictionary = {}			# {player: original_speed}

func _on_body_entered(body: Node2D) -> void:
	# keep parent logic (tracking + damage)
	super._on_body_entered(body)

	if not body.is_in_group("Player"):
		return
	if slowed_players.has(body):
		return

	# assume Player has MoveSpeed (per your Player.gd)
	var original_speed: float = float(body.MoveSpeed)
	slowed_players[body] = original_speed
	body.MoveSpeed = original_speed * slow_multiplier

func _on_body_exited(body: Node2D) -> void:
	# keep parent logic (tracking)
	super._on_body_exited(body)

	if body.is_in_group("Player") and slowed_players.has(body):
		if is_instance_valid(body):
			body.MoveSpeed = float(slowed_players[body])
		slowed_players.erase(body)

func _exit_tree() -> void:
	# restore anyone still slowed if the effect despawns
	for player in slowed_players.keys():
		if is_instance_valid(player):
			player.MoveSpeed = float(slowed_players[player])
	slowed_players.clear()
