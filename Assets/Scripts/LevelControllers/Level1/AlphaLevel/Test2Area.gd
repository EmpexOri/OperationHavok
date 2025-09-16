extends "res://Assets/Scripts/LevelControllers/Level1/ArenaManager.gd"

signal test2_arena_complete

func _ready():
	super._ready()

	wave_data = [
	{ "Spewling": [2, 4, 1], "Needling": [1, 3, 0] },
	{ "Spewling": [3, 5, 1], "Needling": [2, 4, 1], "Tumor": [1, 2, 0] },
	{ "Needling": [2, 4, 2], "Tumor": [2, 3, 1], "Biomancer": [1, 2, 0] },
	{ "Needling": [3, 4, 2], "Tumor": [3, 4, 2], "Biomancer": [1, 3, 1], "Gatling": [1, 1, 0] },
]

func arena_completed():
	emit_signal("test2_arena_complete")
