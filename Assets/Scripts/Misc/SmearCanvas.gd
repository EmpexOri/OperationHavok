extends Node2D
class_name Smearcanvas

var MAX_SMEARS := 5000
const FADE_TIME := 30.0
var CULL_THRESHOLD := MAX_SMEARS / 2
const CULL_FADE_MULTIPLIER := 2.0

var blood_censorship_enabled := false
var bloodcolor := '63070fd4'
var censoredbloodcolor := '4a0642cc'
var nullcolor := Color("ffffffd4")

var smear_texture: Texture2D
var smears: Array = []

func _ready():
	smear_texture = preload("res://Assets/Art/PlaceHolders/SmallSplatWhite.png")
	z_index = 1
	visible = true

func _process(delta: float):
	var fade_multiplier := CULL_FADE_MULTIPLIER if smears.size() > CULL_THRESHOLD else 1.0

	for i in range(smears.size() - 1, -1, -1):
		var smear = smears[i]
		smear["time_left"] -= delta * fade_multiplier
		if smear["time_left"] <= 0:
			smears.remove_at(i)

	queue_redraw()

func _draw():
	for smear in smears:
		var ratio = clamp(smear["time_left"] / FADE_TIME, 0.0, 1.0)
		var mod_color = smear.get("color", Color(1, 1, 1, 1)) * Color(1, 1, 1, ratio)
		draw_texture(smear_texture, smear["position"], mod_color)

func spawn_smear(global_position: Vector2, color := nullcolor) -> void:
	if smears.size() >= MAX_SMEARS:
		smears.pop_front()

	if color == nullcolor:
		color = get_active_blood_color()

	# Convert global to local coordinates
	var local_pos = to_local(global_position)
	var varied_color = randomize_color(color, 0.06)

	smears.append({
		"position": local_pos,
		"time_left": FADE_TIME,
		"color": varied_color,
	})

# -- Settings logic --

func apply_graphics_settings():
	CULL_THRESHOLD = MAX_SMEARS / 2
	print("Updated SmearCanvas graphics settings. MAX_SMEARS =", MAX_SMEARS)

func enforce_smear_limit():
	while smears.size() > MAX_SMEARS:
		smears.pop_front()

func set_max_smeares(value: int) -> void:
	MAX_SMEARS = value
	CULL_THRESHOLD = MAX_SMEARS / 2
	enforce_smear_limit()

func reset():
	smears.clear()
	queue_redraw()

func randomize_color(base_color: Color, variation := 0.1) -> Color:
	var r = clamp(base_color.r + randf_range(-variation, variation), 0.0, 1.0)
	var g = clamp(base_color.g + randf_range(-variation, variation), 0.0, 1.0)
	var b = clamp(base_color.b + randf_range(-variation, variation), 0.0, 1.0)
	return Color(r, g, b, base_color.a)

func get_active_blood_color() -> Color:
	return Color(censoredbloodcolor) if blood_censorship_enabled else Color(bloodcolor)
	
func toggle_blood_censorship(state: bool) -> void:
	blood_censorship_enabled = state
	print("Blood censorship is now: ", state)
