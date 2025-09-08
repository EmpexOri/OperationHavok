extends GroundEffect
class_name SlowGroundEffect

@export var slow_multiplier: float = 0.8  # 80% of normal speed

# Tracks how many zones each player is in
var slow_counts: Dictionary = {}  # { player: count }

func _on_body_entered(body: Node2D) -> void:
	super._on_body_entered(body)
	if not body.is_in_group("Player"):
		return

	# ensure BaseSpeed exists
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
	# restore all affected players
	for player in slow_counts.keys():
		if is_instance_valid(player) and "BaseSpeed" in player:
			player.MoveSpeed = player.BaseSpeed
	slow_counts.clear()

func _update_player_speed(player):
	if not is_instance_valid(player) or not "BaseSpeed" in player:
		return

	var count = slow_counts.get(player, 0)
	if count > 0:
		# Each slow multiplies
		player.MoveSpeed = player.BaseSpeed * pow(slow_multiplier, count)
	else:
		player.MoveSpeed = player.BaseSpeed
