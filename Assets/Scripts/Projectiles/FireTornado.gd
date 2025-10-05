extends PhysicsProjectile
class_name FireTornado

@export var direction_change_interval: float = 0.75

@export var max_direction_change_angle: float = 45.0

var _direction_change_timer: float = 0.0

func _ready():
	super._ready()
	_direction_change_timer = direction_change_interval

# We need to override the start method to control rotation
func start(start_position: Vector2, direction: Vector2, entity_owner: String, 
		p_effects: Array[ProjectileEffect], space_state: PhysicsDirectSpaceState2D, 
		damage_multiplier: float):
	
	super.start(start_position, direction, entity_owner, p_effects, space_state, damage_multiplier)
	
	self.rotation = 0

# Override the movement logic, wander
func _handle_movement(delta: float):
	_direction_change_timer -= delta
	if _direction_change_timer <= 0:
		_direction_change_timer = direction_change_interval * randf_range(0.8, 1.2)
		
		var angle_change = deg_to_rad(randf_range(-max_direction_change_angle, max_direction_change_angle))
		
		self.velocity = self.velocity.rotated(angle_change)
		
		self.velocity = self.velocity.normalized() * speed
	
	var collision_info = move_and_collide(velocity * delta)
	
	if collision_info:
		var reflect_velocity = velocity.bounce(collision_info.get_normal())
		self.velocity = reflect_velocity
		
		var angle_change_on_bounce = deg_to_rad(randf_range(-15, 15))
		self.velocity = self.velocity.rotated(angle_change_on_bounce)

# Override the collision handler to deal damage but not be destroyed
func _on_collision(collision: KinematicCollision2D):
	var body: Node2D = collision.get_collider()
	if not is_instance_valid(body):
		return
	
	# TODO - Currently, this will deal damage on every contact frame
	if body.has_method("deal_damage"):
		body.deal_damage(damage, global_position)
