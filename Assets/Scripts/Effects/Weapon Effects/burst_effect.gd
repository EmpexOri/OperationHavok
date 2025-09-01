extends WeaponEffect
class_name BurstEffect

@export var burst_count: int = 3         # Shots per burst
@export var burst_cooldown: float = 1.0  # Cooldown after a burst (seconds)

var _shots_fired: int = 0
var _cooling_down: bool = false
var _cooldown_remaining: float = 0.0

# Called every frame by Weapon.gd
func process_effect(delta: float) -> void:
	if _cooling_down:
		_cooldown_remaining -= delta
		if _cooldown_remaining <= 0.0:
			_cooldown_remaining = 0.0
			_cooling_down = false
			print("[BurstEffect] Cooldown finished. Weapon ready to fire again.")

func modify_parameters(params: Dictionary) -> Dictionary:
	# Block firing if cooling down
	if _cooling_down:
		print("[BurstEffect] Fire blocked, cooling down:", _cooldown_remaining)
		params["projectile_count"] = 0
		return params
	
	# Count this shot
	_shots_fired += 1
	print("[BurstEffect] Shot fired. Shots this burst:", _shots_fired)
	
	if _shots_fired >= burst_count:
		_shots_fired = 0
		_cooling_down = true
		_cooldown_remaining = burst_cooldown
		print("[BurstEffect] Burst finished. Starting cooldown:", burst_cooldown)
	
	return params
