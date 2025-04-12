extends Node2D
class_name SniperBeam

signal perk_finished

@export var cooldown_time := 5.0 # seconds
var player = null
var index = -1

func activate(p, i):
	# Store references, because this is a VERY angry script ;-;
	player = p
	index = i

	# Simulate "firing" the Sniper Beam
	print("[SniperBeam] Activated by player: ", player.name)
	print("[SniperBeam] Charging super beam...")
	print("[SniperBeam] BOOM! Sniper beam fired across the map.")
	
	# Simulate delay if needed before cooldown starts, for now this is just the best
	# (Here you can wait a second or so for flavor, but we just start cooldown l8r)
	start_cooldown()

func start_cooldown():
	print("[SniperBeam] Cooldown started for ", cooldown_time, " seconds.")
	
	var cooldown_timer := Timer.new()
	cooldown_timer.wait_time = cooldown_time
	cooldown_timer.one_shot = true
	cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_finished"))
	add_child(cooldown_timer)
	cooldown_timer.start()

func _on_cooldown_finished():
	print("[SniperBeam] Cooldown finished. Perk ready to use again.")
	emit_signal("perk_finished", index)
	queue_free()
