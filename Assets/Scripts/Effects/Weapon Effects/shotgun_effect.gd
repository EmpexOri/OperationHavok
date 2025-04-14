extends WeaponEffect
class_name ShotgunSpreadEffect

@export var projectile_count: int = 3
@export var spread_angle: float = 10.0

func modify_parameters(parameters: Dictionary) -> Dictionary:
	parameters["projectile_count"] = projectile_count
	parameters["spread_angle"] = spread_angle
	return parameters # Return the modified dictionary
