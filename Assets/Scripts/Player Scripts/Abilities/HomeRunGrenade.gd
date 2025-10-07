extends Node2D
class_name HomeRungrenade

signal perk_finished(index: int)

@export var cooldown_time: float = 4.0

var perk_index: int

func activate(player, index = -1):
	perk_index = index
	self.owner = player

	var weapon_scene = preload("res://Prefabs/CodePrefabs/Weapons/HomeRunLauncher.tscn")
	var home_run_grenade = weapon_scene.instantiate()
	home_run_grenade.owning_entity = "Player"

	# Fix the bounce effect runtime value
	for effect in home_run_grenade.projectile_effects:
		if effect is PhysProjectileBounces:
			effect.max_bounces = 15  # Set the value you want here

	get_tree().current_scene.add_child(home_run_grenade)

	var direction = Vector2()
	if player.ControllerEnabled:
		direction.x = Input.get_action_strength("fire_right") - Input.get_action_strength("fire_left")
		direction.y = Input.get_action_strength("fire_down") - Input.get_action_strength("fire_up")
		if direction.length() > 0.1:
			direction = direction.normalized()
		else:
			return
	else:
		direction = (get_global_mouse_position() - global_position).normalized()
			
	home_run_grenade.attempt_to_fire(player.global_position, direction)
	
	_start_cooldown()

func _start_cooldown():
	if owner and owner.has_method("start_cooldown_on_slot"):
		owner.start_cooldown_on_slot(2, cooldown_time)  # slot 2 is grenade
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = cooldown_time
	timer.timeout.connect(_cooldown_complete)
	add_child(timer)
	timer.start()

func _cooldown_complete():
	emit_signal("perk_finished", perk_index)
	queue_free()
