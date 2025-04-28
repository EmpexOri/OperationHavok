extends WeaponEffect
class_name InaccuracyEffect

@export var inaccuracy_angle: float = 5.0

func modify_parameters(parameters: Dictionary) -> Dictionary:
	parameters["inaccuracy_angle"] = inaccuracy_angle
	return parameters
