extends OptionButton

func _ready() -> void:
	select(Global.graphics_quality_index)
	_on_item_selected(Global.graphics_quality_index)

func _on_item_selected(index: int) -> void:
	Global.graphics_quality_index = index
	
	match index:
		0:
			SmearManager.set_max_smeares(4000)
			Global.MAX_BLOOD_SMEARS = 4000
			Global.POOL_SIZE = 128
		1:
			SmearManager.set_max_smeares(2000)
			Global.MAX_BLOOD_SMEARS = 2000
			Global.POOL_SIZE = 64
		2:
			SmearManager.set_max_smeares(1000)  # <- don't use 0 unless you truly want none
			Global.MAX_BLOOD_SMEARS = 1000
			Global.POOL_SIZE = 32
	
	#print("Max smears:", SmearManager.MAX_SMEARS)
	#print("Blood smears:", Global.MAX_BLOOD_SMEARS)
	#print("Pool size:", Global.POOL_SIZE)

	Global.apply_graphics_settings()
	SmearManager.apply_graphics_settings()
