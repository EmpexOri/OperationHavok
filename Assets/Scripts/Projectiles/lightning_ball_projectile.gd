extends Projectile
class_name LightningBallProjectile

@onready var ball_anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	ball_anim.play()
