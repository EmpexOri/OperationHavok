# SmearManager.gd
extends Node

const MAX_SMEARS := 2500
const FADE_TIME := 5.0

var smear_scene := preload("res://Prefabs/Particles/BloodSmear.tscn")
var smear_pool: Array = []
var active_smeares: Array = []

func _process(delta: float) -> void:
	for smear_data in active_smeares:
		smear_data.time_left -= delta
		if smear_data.time_left <= 0:
			smear_data.sprite.modulate.a -= delta / FADE_TIME
			if smear_data.sprite.modulate.a <= 0.0:
				_deactivate_smear(smear_data)

func spawn_smear(position: Vector2) -> void:
	var smear_data = null
	
	# Reuse or instantiate
	if smear_pool.size() > 0:
		smear_data = smear_pool.pop_back()
	else:
		var sprite = smear_scene.instantiate()
		sprite.z_index = -2
		get_tree().current_scene.add_child(sprite)
		smear_data = {
			"sprite": sprite,
			"time_left": 0.0
		}

	smear_data.sprite.global_position = position
	smear_data.sprite.visible = true
	smear_data.sprite.modulate = Color(1, 1, 1, 1)
	smear_data.time_left = 30.0
	active_smeares.append(smear_data)

	if active_smeares.size() > MAX_SMEARS:
		var oldest = active_smeares.pop_front()
		_deactivate_smear(oldest)

func _deactivate_smear(smear_data) -> void:
	var sprite = smear_data.sprite
	sprite.visible = false
	smear_pool.append(smear_data)
