extends PhysicsProjectile
class_name HomeRunProjectile

@onready var projectile_sprite: Sprite2D = $Sprite2D
@onready var explosion_ref: HomeRunExplosion2 = $Explosion

func _ready() -> void:
	super._ready()
	explosion_ref.start(global_position, Vector2.ZERO)
	explosion_ref.explosion_delay = base_lifetime - 1

func explode() -> void:
	if is_instance_valid(explosion_ref) and explosion_ref.has_method("_explode"):
		self.velocity = Vector2.ZERO
		projectile_sprite.visible = false
		explosion_ref._explode()
