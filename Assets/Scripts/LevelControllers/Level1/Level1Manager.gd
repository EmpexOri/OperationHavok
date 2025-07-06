extends Node

var carpark_triggered := false

@onready var carpark_trigger := $CarparkTrigger
@onready var CarparkArea := get_node("../CarparkArea")
@onready var Test2Area := get_node("../Test2Area")
@onready var test2_trigger = $Test2Trigger
@onready var roadblock2 = get_node("../Test2Area/RoadBlock2")
@onready var roadblock2Col = get_node("../Test2Area/RoadBlock2/CollisionShape2D")

func _ready():
	carpark_trigger.body_entered.connect(_on_carpark_trigger_entered)
	CarparkArea.carpark_arena_complete.connect(_on_carpark_arena_complete)
	test2_trigger.body_entered.connect(_on_test2_trigger_entered)
	roadblock2.visible = false
	roadblock2Col.disabled = true

func _on_carpark_trigger_entered(body):
	if body.name != "Player":
		return
	if carpark_triggered:
		return
	
	carpark_triggered = true
	GlobalAudioController.LevelOneMusic()
	print("Carpark area triggered.")
	CarparkArea.activate_carpark_area()

func _on_carpark_arena_complete():
	print("Carpark arena complete!")
	var roadblock = get_node("../YSortedObjects/RoadBlock")
	roadblock.handle_arena_completion()

func _on_test2_trigger_entered(body):
	if body.name == "Player":  
		print("Test2 Trigger Entered!")
		roadblock2.visible = true  
		roadblock2Col.disabled = false
		Test2Area.activate_test_arena()
