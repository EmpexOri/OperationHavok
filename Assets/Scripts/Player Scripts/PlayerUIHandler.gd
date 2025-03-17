extends Node

@onready var HealthBar: TextureProgressBar = $UIContainer/HealthBar
@onready var FocusBar: TextureProgressBar = $UIContainer/FocusBar

func _ready():
	# Initialize the health bar based on Global HP values
	HealthBar.max_value = GlobalControls.PlayerHPMax
	HealthBar.value = GlobalControls.PlayerHP
	
	# Initialize the FP bar based on Global FP values
	FocusBar.max_value = GlobalControls.PlayerFPMax
	FocusBar.value = GlobalControls.PlayerFP

func _process(delta):
	UpdateHealthBar()
	UpdateFocusBar()

func UpdateHealthBar():
	HealthBar.value = GlobalControls.PlayerHP

func UpdateFocusBar():
	FocusBar.value = GlobalControls.PlayerFP
