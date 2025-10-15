extends Node2D

@export var enemy_scene: PackedScene

func spawn_enemies():
	for child in get_children():
		if child.name.begins_with("EnemySpawn"):
			var enemy = enemy_scene.instantiate()
			enemy.global_position = child.global_position
			get_parent().add_child(enemy)
