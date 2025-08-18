extends Node

var xp_pickup_buff_active: bool = false
var xp_pickup_range_bonus: int = 0

signal xp_buff_started(bonus: int)
signal xp_buff_ended()

func activate_xp_buff(bonus: int, duration: float = 5.0) -> void:
	if xp_pickup_buff_active:
		return # already active
	
	xp_pickup_buff_active = true
	xp_pickup_range_bonus = bonus
	emit_signal("xp_buff_started", bonus)

	# Reset after duration
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = duration
	add_child(t)
	t.start()
	t.timeout.connect(_on_buff_timeout)

func _on_buff_timeout() -> void:
	xp_pickup_buff_active = false
	xp_pickup_range_bonus = 0
	emit_signal("xp_buff_ended")
