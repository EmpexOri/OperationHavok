extends ProjectileEffect
class_name PenetrationEffect

# Penetration effect for a projectile

@export var max_hits: int = 5 # The maximum number of hits allowed
var current_hits: int = 0 # How many hits we have actually had

var hit_bodies: Array[Node2D] = [] # Bodies we have hit will be added here

func _init() -> void:
	effect_name = "Penetrate" # Giggity
	
func setup(projectile: Projectile):
	# For some reason we have to do this as all penetrating projectiles share the same variables
	current_hits = 0
	hit_bodies.clear() 

func process_effect(projectile: Projectile, delta: float):
	pass 

func on_hit(projectile: Projectile, body: Node2D):
	if body.has_method("take_damage"): # Quick dirty fix for penetrating environment
		if body in hit_bodies:
			return false # We have already hit this entity
			
		current_hits += 1 # Up our current hits
		hit_bodies.append(body) # Add the hit body for checking for repeat hits
		
		if current_hits > max_hits:
			return true # Destroy the projectile on hit count matching max_hits
		else:
			return false # We can still hit more entities, don't destroy the projectile
	else:
		return true # We hit the environment, destory projectile
