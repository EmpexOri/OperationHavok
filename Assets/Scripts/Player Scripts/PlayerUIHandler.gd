extends Node

@onready var HealthBar: TextureProgressBar = $UIContainer/HealthBar
@onready var FocusBar: TextureProgressBar = $UIContainer/FocusBar

func _ready():
	# Initialize the health bar based on Global HP values
	HealthBar.max_value = Global.PlayerHPMax
	HealthBar.value = Global.PlayerHP
	
	# Initialize the FP bar based on Global FP values
	FocusBar.max_value = Global.PlayerFPMax
	FocusBar.value = Global.PlayerFP

func _process(_delta):
	UpdateHealthBar()
	UpdateFocusBar()

func UpdateHealthBar():
	HealthBar.value = Global.PlayerHP

func UpdateFocusBar():
	FocusBar.value = Global.PlayerFP
