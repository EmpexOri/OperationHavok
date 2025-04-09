extends Resource
class_name WeaponEffect

# Base class for the weapon effects with are applied by the weapon, extend this to create a new weapon effect
# Don't make changes here

# The effects name
@export var effect_name: String

# This method will be used to hold a dict of the changes we want to make to the weapons behvaiour
func modify_parameters(parameters: Dictionary) -> Dictionary:
	'''
	Example for a shotgun effect
	parameters.projectile_count = 3
	parameters.spread_angle = 10
	'''
	return parameters
	
# This method can be used to completely override the firing logic of a weapon, useful for complex firing logic
func override_fire_logic(weapon: Weapon, spawn_position: Vector2, direction: Vector2, projectile_effects: Array[ProjectileEffect]):
	# Return true in the derived weapon effect if you are overriding the default firing behaviour
	return false
