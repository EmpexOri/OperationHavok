extends ProjectileEffect

# Penetration effect for a projectile

@export var max_hits: int = 5 # The maximum number of hits allowed
var current_hits: int = 0 # How many hits we have actually had

var hit_bodies: Array[Node2D] = [] # Bodies we

func _init() -> void:
	effect_name = "Penetrate" #Giggity
	
func setup(projectile: Projectile):
	pass 

func process_effect(projectile: Projectile, delta: float):
	pass 

func on_hit(projectile: Projectile, body: Node2D):
	if body in hit_bodies:
		return false # We have already hit this entity
		
	current_hits += 1 # Up our current hits
	hit_bodies.append(body) # Add the hit body for checking for repeat hits
	
	if current_hits > max_hits:
		return true # Destroy the projectile on hit count matching max_hits
	else:
		return false # We can still hit more entities, don't destroy the projectile
