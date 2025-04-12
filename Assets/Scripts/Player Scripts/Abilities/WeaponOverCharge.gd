extends Node2D
class_name WeaponOverCharge

signal perk_finished(index: int)

@export var duration: float = 5.0
@export var cooldown_time: float = 10.0
@export var fire_rate_multiplier: float = 2.0

var weapon: Weapon
var original_fire_rate: float
var perk_index: int

func activate(player, index = -1):
	perk_index = index  # Store index to notify when cooldown is over

	if not player.CurrentWeapon:
		queue_free()
		return

	weapon = player.CurrentWeapon
	original_fire_rate = weapon.current_fire_rate

	weapon.current_fire_rate = original_fire_rate / fire_rate_multiplier
	weapon.cooldown_timer.wait_time = weapon.current_fire_rate
	print("Weapon Overcharged!")

	# Start effect timer
	var effect_timer := Timer.new()
	effect_timer.one_shot = true
	effect_timer.wait_time = duration
	effect_timer.timeout.connect(_end_effect)
	add_child(effect_timer)
	effect_timer.start()

func _end_effect():
	if weapon:
		weapon.current_fire_rate = original_fire_rate
		weapon.cooldown_timer.wait_time = original_fire_rate
		print("Weapon Overcharge ended.")
	_start_cooldown()

func _start_cooldown():
	var cooldown_timer := Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = cooldown_time
	cooldown_timer.timeout.connect(_cooldown_complete)
	add_child(cooldown_timer)
	cooldown_timer.start()

func _cooldown_complete():
	print("Perk cooldown complete.")
	emit_signal("perk_finished", perk_index)
	queue_free()
