extends VideoStreamPlayer

# --- Video paths ---
const INTRO_VIDEO := "res://Assets/Videos/AttractMode_fixed.ogv"
const LOOP_VIDEO := "res://Assets/Videos/Gameplay_Highlights_80mb.ogv"

# --- Variables ---
var next_video_is_loop := false
@onready var title_sprite: Sprite2D = get_node_or_null("OperationHavocTitle")

func _ready() -> void:
	if title_sprite:
		title_sprite.modulate.a = 1.0
		
	# Start with intro video
	_play_intro()
	
	connect("finished", Callable(self, "_on_video_finished"))
	
func _play_intro() -> void:
	stream = load(INTRO_VIDEO)
	loop = false
	next_video_is_loop = true
	
	# Fade out title for intro
	if title_sprite:
		_fade_title(false)
	
	if randi() % 100 == 0:
		speed_scale = 5.0
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = 1.0
		timer.timeout.connect(func():
			speed_scale = 1.0
		)
		add_child(timer)
		timer.start()
	else:
		speed_scale = 1.0
	
	play()
	
func _play_loop() -> void:
	stream = load(LOOP_VIDEO)
	loop = false  # we want to switch back to intro when done
	next_video_is_loop = false
	
	# Fade in title for loop
	if title_sprite:
		_fade_title(true)
	
	play()
	
func _on_video_finished() -> void:
	if next_video_is_loop:
		_play_loop()
	else:
		_play_intro()
		
func _fade_title(fade_in: bool, duration: float = 0.5) -> void:
	if not title_sprite:
		return
	
	var target_alpha = 1.0 if fade_in else 0.0
	var tween = create_tween()
	tween.tween_property(title_sprite, "modulate:a", target_alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
