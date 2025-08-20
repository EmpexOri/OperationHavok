extends ProjectileEffect
class_name ChainOnIntervalEffect

@export var zap_interval: float = 0.5
@export var max_chains: int = 2
@export var chain_radius: float = 180.0
@export var damage_per_hit: float = 8.0
@export var target_collision_mask: int = 2
@export var lightning_arc_drawer_scene: PackedScene = null
@export var effects_to_apply: Array[ProjectileEffect] = []

var _projectile_ref: Projectile = null
var _zap_timer: Timer = null
var _space_state: PhysicsDirectSpaceState2D = null

func _init():
	effect_name = "Chain On Interval"

func setup(projectile: Projectile):
	_projectile_ref = projectile
	
	_zap_timer = Timer.new()
	_zap_timer.wait_time = zap_interval
	_zap_timer.one_shot = false # Make it repeat
	_zap_timer.timeout.connect(_on_zap_timer_timeout)
	
	_projectile_ref.add_child(_zap_timer)
	_zap_timer.start()
	
	_on_zap_timer_timeout()

func _on_zap_timer_timeout():
	if not is_instance_valid(_projectile_ref):
		if is_instance_valid(_zap_timer):
			_zap_timer.queue_free()
		return
	
	var exclusions = [_projectile_ref]
	if is_instance_valid(_projectile_ref.get_parent()):
		exclusions.append(_projectile_ref.get_parent())
	
	ChainLightningUtility.execute_chain_lightning(
		_projectile_ref,
		_projectile_ref.global_position,
		Vector2.RIGHT.rotated(randf_range(0, TAU)),
		null,
		_space_state,
		max_chains,
		chain_radius,
		damage_per_hit,
		target_collision_mask,
		effects_to_apply,
		exclusions,
		lightning_arc_drawer_scene
	)

func process_effect(projectile: Projectile, delta: float, space_state: PhysicsDirectSpaceState2D):
	_space_state = space_state

func on_hit(projectile: Projectile, body: Node2D, collision: KinematicCollision2D = null):
	false
