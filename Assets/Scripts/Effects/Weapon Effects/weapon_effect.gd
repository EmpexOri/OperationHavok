extends Resource
class_name WeaponEffect

# Base class for the weapon effects with are applied by the weapon, extend this to create a new weapon effect
# Don't make changes here

# The effects name
@export var effect_name: String

# This method will be used to hold a dict of the changes we want to make to the weapons behvaiour
func modify_parameters(parameters: Dictionary) -> Dictionary:
	return parameters
