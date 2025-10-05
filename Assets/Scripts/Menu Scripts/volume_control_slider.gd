extends HSlider

@export
var BusName: String
var BusIndex: int

func _ready() -> void:
	BusIndex = AudioServer.get_bus_index(BusName)
	
	# Check if the BusName is valid
	if BusIndex == -1:
		push_error("Invalid BusName: '%s'" % BusName)
		return
	
	value_changed.connect(_on_value_changed)

	value = db_to_linear(AudioServer.get_bus_volume_db(BusIndex))


func _process(delta):
	# Only move the slider if it's currently selected
	if not has_focus():
		return

	# Making the slider steps faster for controller
	var move_speed = 1.5
	var input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	# Only update it if there's actual input
	if abs(input) > 0.1:
		value = clamp(value + input * move_speed * delta, min_value, max_value)


func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(BusIndex, linear_to_db(value))
