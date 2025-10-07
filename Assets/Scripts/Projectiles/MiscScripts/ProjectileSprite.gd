extends AnimatedSprite2D

@export var collision_shape_path: NodePath = "../CollisionShape2D"
@export var frame_sizes: Array[float] = [3.0, 6.0, 9.0, 12.0]

var shape_ref: CollisionShape2D

func _ready():
	shape_ref = get_node_or_null(collision_shape_path)
	if not shape_ref:
		push_warning("CollisionShape2D not found at path: " + str(collision_shape_path))
		return

	# Connect the frame_changed signal so we can react when the sprite updates
	frame_changed.connect(_on_frame_changed)
	
	# Update shape immediately to match starting frame
	_on_frame_changed()

func _on_frame_changed():
	if not shape_ref:
		return
	
	# Get current frame index and corresponding size
	var frame_index := frame % frame_sizes.size()
	var new_size := frame_sizes[frame_index]
	
	var shape = shape_ref.shape
	if shape is CircleShape2D:
		shape.radius = new_size
	elif shape is RectangleShape2D:
		shape.size = Vector2(new_size, new_size)
