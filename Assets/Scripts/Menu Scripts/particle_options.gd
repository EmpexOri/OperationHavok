extends OptionButton

func _ready() -> void:
	select(Global.graphics_quality_index)
	_on_item_selected(Global.graphics_quality_index)

func _on_item_selected(index: int) -> void:
	Global.graphics_quality_index = index
	
	match index:
		0:
			SmearCanvas.set_max_smeares(10000)
			Global.MAX_BLOOD_SMEARS = 10000
			Global.POOL_SIZE = 256
		1:
			SmearCanvas.set_max_smeares(5000)
			Global.MAX_BLOOD_SMEARS = 5000
			Global.POOL_SIZE = 128
		2:
			SmearCanvas.set_max_smeares(1000)  # <- don't use 0 unless you truly want none
			Global.MAX_BLOOD_SMEARS = 1000
			Global.POOL_SIZE = 32
	
	#print("Max smears:", SmearManager.MAX_SMEARS)
	#print("Blood smears:", Global.MAX_BLOOD_SMEARS)
	#print("Pool size:", Global.POOL_SIZE)

	Global.apply_graphics_settings()
	SmearCanvas.apply_graphics_settings()
