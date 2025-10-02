extends Projectile
class_name RocketProjectilePlayerOnly

@export var explosion_radius_size: float = 50.0 # The AOE for explosion
@export var explosion_scene: PackedScene = null # The explosion VFX

@export var initial_speed: float = 100.0
@export var max_speed: float = 700.0
@export var acceleration_rate: float = 1000.0

@onready var explosion_area: Area2D = $ExplosionRadius
@onready var explosion_shape: CollisionShape2D = $ExplosionRadius/CollisionShape2D
@onready var explosioncloud: GPUParticles2D = $GPUParticles2D2

var has_exploded: bool = false

func _ready() -> void:
	super._ready()
	explosion_shape.shape.radius = explosion_radius_size
	explosion_area.monitoring = false
	explosion_area.monitorable = false
	explosioncloud.emitting = true

func start(start_position: Vector2, direction: Vector2, entity_owner: String, 
		p_effects: Array[ProjectileEffect], space_state: PhysicsDirectSpaceState2D, damage_multiplier: float):
	super.start(start_position, direction, entity_owner, p_effects, space_state, damage_multiplier)
	has_exploded = false
	explosion_area.collision_mask = self.collision_mask
	explosion_area.position = Vector2.ZERO
	self.speed = initial_speed
	self.velocity = direction.normalized() * self.speed

func _handle_movement(delta: float):
	if self.speed < max_speed:
		self.speed += acceleration_rate * delta
		if self.speed >= max_speed:
			self.speed = max_speed
		self.velocity = self.velocity.normalized() * self.speed
	super._handle_movement(delta)

func _on_body_entered(body: Node2D):
	if not has_exploded:
		_explode()

func _explode():
	if has_exploded:
		return
	has_exploded = true
	
	if lifetime_timer and not lifetime_timer.is_stopped():
		lifetime_timer.stop()
	
	if explosion_scene:
		var explosion_instance = explosion_scene.instantiate()
		explosion_instance.start(explosion_radius_size)
		get_parent().add_child(explosion_instance)
		explosion_instance.global_position = self.global_position
	
	explosion_area.monitoring = true
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var bodies_in_aoe = explosion_area.get_overlapping_bodies()
	
	for body in bodies_in_aoe:
		if body == self:
			continue
		# Only damage the player
		if body.is_in_group("Player") and body.has_method("deal_damage"):
			body.deal_damage(damage)
		
		# Apply projectile effects
		if current_effects:
			for effect in current_effects:
				if effect.has_method("on_hit"):
					effect.on_hit(self, body)
	
	explosion_area.monitoring = false
	explosion_shape.disabled = true
	
	queue_free()
