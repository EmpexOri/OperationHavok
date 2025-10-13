extends WeaponEffect

@export var sweep_angle_deg: float = 30.0
@export var sweep_duration: float = 1.0
@export var bullets_in_sweep: int = 15

var sweep_active: bool = false
var sweep_elapsed: float = 0.0
var sweep_base_direction: Vector2 = Vector2.RIGHT
var sweep_weapon: Weapon = null
var sweep_spawn_position: Vector2 = Vector2.ZERO
var sweep_fire_interval: float = 0.0
var next_fire_time: float = 0.0
var bullets_fired: int = 0

func override_fire_logic(
	weapon: Weapon,
	spawn_position: Vector2,
	base_direction: Vector2,
	projectile_effects: Array,
	space_state: PhysicsDirectSpaceState2D,
	damage_multiplier: float
) -> bool:
	sweep_active = true
	sweep_elapsed = 0.0
	bullets_fired = 0
	next_fire_time = 0.0
	sweep_base_direction = base_direction.normalized()
	sweep_weapon = weapon
	sweep_spawn_position = spawn_position
	sweep_fire_interval = sweep_duration / float(bullets_in_sweep)
	return true

func process_effect(delta: float) -> void:
	if not sweep_active:
		return

	sweep_elapsed += delta

	# Fire bullets one at a time at proper intervals
	if bullets_fired < bullets_in_sweep and sweep_elapsed >= next_fire_time:
		var t: float = float(bullets_fired) / float(bullets_in_sweep - 1)
		var angle_deg: float = lerp(-sweep_angle_deg, sweep_angle_deg, t)
		var fire_dir: Vector2 = sweep_base_direction.rotated(deg_to_rad(angle_deg))
		
		sweep_weapon._spawn_projectile(sweep_spawn_position, fire_dir)
		if sweep_weapon.fire_sound_method != "":
			sweep_weapon._play_fire_sound()
		
		bullets_fired += 1
		next_fire_time += sweep_fire_interval

	if bullets_fired >= bullets_in_sweep:
		sweep_active = false
