extends Projectile
class_name LightningBallProjectile

@onready var ball_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion_ref: Grenade = $Explosion

var exploded: bool = false

func _ready() -> void:
	super._ready()
	ball_anim.play()
	explosion_ref.start(global_position, Vector2.ZERO)
	explosion_ref.explosion_delay = base_lifetime - 1
	
func _physics_process(delta: float) -> void:
	if explosion_ref:
		explosion_ref.global_position = global_position
		
func _handle_movement(delta: float):
	if not exploded:
		position += velocity * delta

func _on_explosion_timer_timeout() -> void:
	ball_anim.visible = false
	exploded = true
