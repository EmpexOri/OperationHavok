extends OptionButton

func _ready() -> void:
	# Applying the saved settings
	select(Global.graphics_quality_index)
	_on_item_selected(Global.graphics_quality_index)


func _on_item_selected(index: int) -> void:
	Global.graphics_quality_index = index
	
	# Changing the variables according to the selected value
	# 0 = High, 1 = Medium, 2 = Low
	match index:
		0:
			SmearManager.MAX_SMEARS = 4000
			Global.MAX_BLOOD_SMEARS = 4000
			Global.POOL_SIZE = 128
		1:
			SmearManager.MAX_SMEARS = 2000
			Global.MAX_BLOOD_SMEARS = 2000
			Global.POOL_SIZE = 64
		2:
			SmearManager.MAX_SMEARS = 1000
			Global.MAX_BLOOD_SMEARS = 1000
			Global.POOL_SIZE = 32
