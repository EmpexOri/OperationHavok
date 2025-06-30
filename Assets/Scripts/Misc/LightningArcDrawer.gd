extends Node2D
class_name LightningArcDrawer

@export var segement_length: float = 10.0
@export var jitter_amount: float = 5.0
@export var arc_width: float = 2.0
@export var arc_colour: Color = Color(1, 1, 1)
@export var arc_lifetime: float = 0.25

var _points_to_connect: Array[Vector2] = []

func setup_arcs(points_array: Array[Vector2]):
	_points_to_connect = points_array
	
	if _points_to_connect.size() < 2:
		queue_free()
		return
		
	queue_redraw()
	
	var timer = get_tree().create_timer(arc_lifetime)
	timer.timeout.connect(queue_free)

func _draw():
	if _points_to_connect.size() < 2:
		return
	
	for i in range(_points_to_connect.size() - 1):
		var start_pos_global = _points_to_connect[i]
		var end_pos_global = _points_to_connect[i+1]
		_draw_jagged_arc(start_pos_global, end_pos_global)

func _draw_jagged_arc(point_a: Vector2, point_b: Vector2):
	var current_point = point_a
	var distance_to_target = point_a.distance_to(point_b)
	
	if distance_to_target < 0.01:
		return
	
	var direction_to_target = (point_b - point_a).normalized()
	var distance_covered = 0.0
	
	var points_for_line: PackedVector2Array = [point_a]
	
	while distance_covered < distance_to_target:
		
		var current_segment_len = min(segement_length * randf_range(0.7, 1.3), distance_to_target - distance_covered)
		
		if current_segment_len <= 0.01: break
		
		var next_point_on_line = current_point + direction_to_target * current_segment_len
		
		var jittered_next_point = next_point_on_line
		if (distance_to_target - distance_covered) > current_segment_len:
			var perp_dir = direction_to_target.orthogonal()
			var jitter = perp_dir * randf_range(-jitter_amount, jitter_amount)
			jittered_next_point += jitter
		
		points_for_line.append(jittered_next_point)
		
		current_point = next_point_on_line
		distance_covered += current_segment_len
	
	points_for_line.append(point_b)
	
	if points_for_line.size() > 1:
		draw_polyline(points_for_line, arc_colour, arc_width, true)
