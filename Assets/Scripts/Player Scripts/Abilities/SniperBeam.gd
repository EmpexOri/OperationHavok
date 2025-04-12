extends Node2D

@export var duration := 2.0
@export var total_projectiles := 100

@export var spawn_position: Vector2
@export var direction: Vector2
@export var projectile_scene: PackedScene  # The scene that defines the projectile

var current_projectile: int = 0

func activate(player):
	spawn_beam()

func spawn_beam():
	print_stack()
