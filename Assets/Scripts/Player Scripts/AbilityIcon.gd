extends Sprite2D

var cooldown_duration := 0.0
var cooldown_remaining := 0.0
var is_on_cooldown := false

@onready var countdown_label := $Label 

func start_cooldown(duration: float):
	cooldown_duration = duration
	cooldown_remaining = duration
	is_on_cooldown = true
	modulate = Color(0.5, 0.5, 0.5, 1)  # start greyed out while cooling down
	scale = Vector2.ONE  # reset scale
	countdown_label.visible = true
	countdown_label.text = _format_time(cooldown_remaining) # Countdown label

func _process(delta):
	if is_on_cooldown:
		cooldown_remaining -= delta
		if cooldown_remaining <= 0.0:
			is_on_cooldown = false
			modulate = Color(1, 1, 1, 1)  # fully bright when ready
			countdown_label.visible = false
			_play_finish_animation()
		else:
			var t = (cooldown_duration - cooldown_remaining) / cooldown_duration
			var color_val = lerp(0.5, 1.0, t)
			modulate = Color(color_val, color_val, color_val, 1)
			countdown_label.text = _format_time(cooldown_remaining)  # Update countdown text

func _play_finish_animation():
	# Create a tween to do a quick pop scale-up and back
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# quick flash effect by tweaking modulate alpha
	tween.tween_property(self, "modulate:a", 0.7, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _format_time(time: float) -> String:
	# Round the time to 1 decimal place for easier readability
	return "%.1f" % time
