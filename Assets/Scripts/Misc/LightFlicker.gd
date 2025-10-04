extends Node2D

@onready var light := $PointLight2D

@export var base_energy: float = 0.6
@export var flicker_intensity: float = 0.25 
@export var flicker_speed: float = 0.25   

var _time_accum := 0.0
var _target_energy := base_energy

func _ready():
	light.energy = base_energy
	randomize()

func _process(delta):
	_time_accum -= delta
	if _time_accum <= 0:
		_target_energy = base_energy + randf_range(-flicker_intensity, flicker_intensity)
		_time_accum = randf_range(flicker_speed * 0.5, flicker_speed * 1.5)

	light.energy = lerp(light.energy, _target_energy, delta * 10.0)
