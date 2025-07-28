extends CheckButton

@onready var censor_toggle := get_node_or_null("ScrollContainer/VBoxContainer/CensorBlood")

func _ready():
	# Check if the toggle exists
	if censor_toggle:
		# Initialize toggle state from Smearcanvas
		censor_toggle.button_pressed = SmearCanvas.blood_censorship_enabled

		# Connect signal
		censor_toggle.toggled.connect(_on_censor_toggle_toggled)
	else:
		push_error("CensorBlood toggle not found! Check your node path.")

func _on_censor_toggle_toggled(pressed: bool) -> void:
	SmearCanvas.toggle_blood_censorship(pressed)
	print("Blood censorship toggled:", pressed)
