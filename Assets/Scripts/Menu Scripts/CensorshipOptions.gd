extends CheckButton

func _ready():
	# Initialize toggle state from Smearcanvas
	button_pressed = SmearCanvas.blood_censorship_enabled

	# Connect signal
	toggled.connect(_on_censor_toggle_toggled)

func _on_censor_toggle_toggled(pressed: bool) -> void:
	SmearCanvas.toggle_blood_censorship(pressed)
	print("Blood censorship toggled:", pressed)
