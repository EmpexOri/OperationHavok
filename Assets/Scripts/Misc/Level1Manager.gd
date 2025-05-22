extends Node

var carpark_triggered := false

@onready var carpark_trigger := $CarparkTrigger
@onready var CarparkArea := get_node("../CarparkArea")

func _ready():
	carpark_trigger.body_entered.connect(_on_carpark_trigger_entered)

func _on_carpark_trigger_entered(body):
	if body.name != "Player":
		return
	if carpark_triggered:
		return
	
	carpark_triggered = true
	print("Carpark area triggered.")
	CarparkArea.activate_carpark_area()
