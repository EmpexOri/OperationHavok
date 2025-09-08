extends "res://Assets/Scripts/LevelControllers/Level1/ArenaManager.gd"

# So clean waow
signal carpark_arena_complete

func _ready():
	super._ready()

	wave_data = [
		{ "Hordling": [3,6,3], "Spewling": [2,6,0], "Random": [1,6,1] },
		{ "Hordling": [5,6,4], "Spewling": [3,6,0], "Biomancer": [1,4,0], "Needling": [2,6,0], "Tumor": [1,6,1] },
		{ "Hordling": [6,6,8], "Spewling": [4,6,2], "Biomancer": [1,6,1], "Needling": [3,6,1], "Tumor": [2,6,2], "Gatling": [1,1,1], "Network": [1,0,1] },
		{ "Hordling": [7,6,12], "Spewling": [5,6,5], "Biomancer": [2,6,1], "Needling": [4,6,2], "Tumor": [4,6,2], "Network": [1,1,1] },
		{ "Hordling": [10,6,15], "Spewling": [6,6,6], "Biomancer": [3,6,2], "Needling": [5,6,3], "Tumor": [5,6,3], "Gatling": [1,6,1], "Network": [1,2,1], "Warmachine": [1,1,0]  },
	]

func arena_completed():
	GlobalEffects.activate_xp_buff(5000, 5.0)
	emit_signal("carpark_arena_complete")
