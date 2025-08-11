extends Node

var carpark_triggered := false

@onready var carpark_trigger := $CarparkTrigger
@onready var carpark_area := get_node("../CarparkArea")
@onready var test2_area := get_node("../Test2Area")
@onready var test2_trigger = $Test2Trigger
@onready var roadblock2 = get_node("../Test2Area/RoadBlock2")
@onready var roadblock2_col = get_node("../Test2Area/RoadBlock2/CollisionShape2D")

func _ready():
	await get_tree().physics_frame
	carpark_trigger.body_entered.connect(_on_carpark_trigger_entered)
	carpark_area.carpark_arena_complete.connect(_on_carpark_arena_complete)
	test2_trigger.body_entered.connect(_on_test2_trigger_entered)
	test2_area.test2_arena_complete.connect(_on_test2_arena_complete)

	roadblock2.visible = false
	roadblock2_col.disabled = true

func _on_carpark_trigger_entered(body):
	if body.name != "Player" or carpark_triggered:
		return
	carpark_triggered = true
	GlobalAudioController.LevelOneMusic()
	print("Carpark area triggered.")
	carpark_area.activate_arena()

func _on_carpark_arena_complete():
	print("Carpark arena complete!")
	var roadblock = get_node_or_null("../YSortedObjects/RoadBlock")
	if roadblock:
		roadblock.handle_arena_completion()
	else:
		push_error("RoadBlock node not found!")

func _on_test2_arena_complete():
	print("Test2 arena complete!")
	#var another_roadblock = get_node_or_null("../SomeOtherNode/OtherRoadBlock")
	#if another_roadblock:
	#	another_roadblock.do_something_specific()
	#else:
	#	push_error("OtherRoadBlock node not found!")

func _on_test2_trigger_entered(body):
	if body.name == "Player":
		print("Test2 Trigger Entered!")
		roadblock2.visible = true  
		roadblock2_col.disabled = false
		test2_area.activate_arena()
