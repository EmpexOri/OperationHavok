extends Sprite2D

var cooldown_duration := 0.0
var cooldown_remaining := 0.0
var is_on_cooldown := false

@onready var countdown_label := $Label 

# All HUD ability icons
@onready var NovacasterIcon = $"../Icon2/Novacaster"
@onready var BaseballIcon = $"../Icon2/BaseballGrenade"
@onready var HomerunIcon = $"../Icon2/HomerunGrenade"
@onready var MinigunIcon = $"../Icon3/Minigun"
@onready var RocketMinigunIcon = $"../Icon3/RocketMingun"
@onready var LightningIcon = $"../Icon3/LightningGun"
@onready var TyphoonIcon = $"../Icon3/TyphoonCannon"

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
	
	var Abilities = GlobalPlayer.ClassData["Commando"]["Abilities"]
	
	# Grenade ability icons
	match Abilities[1]:
		"NovacasterGrenade":
			NovacasterIcon.visible = true
			BaseballIcon.visible = false
			HomerunIcon.visible = false
		"BaseballGrenade":
			BaseballIcon.visible = true
			NovacasterIcon.visible = false
			HomerunIcon.visible = false
		"HomerunGrenade":
			HomerunIcon.visible = true
			NovacasterIcon.visible = false
			BaseballIcon.visible = false
	
	# Minigun ability icons
	match Abilities[2]:
		"Minigun":
			MinigunIcon.visible = true
			RocketMinigunIcon.visible = false
			TyphoonIcon.visible = false
			LightningIcon.visible = false
		"RocketMinigun":
			RocketMinigunIcon.visible = true
			MinigunIcon.visible = false
			TyphoonIcon.visible = false
			LightningIcon.visible = false
		"LightningLauncher":
			LightningIcon.visible = true
			MinigunIcon.visible = false
			RocketMinigunIcon.visible = false
			TyphoonIcon.visible = false
		"TyphoonCannon":
			TyphoonIcon.visible = true
			MinigunIcon.visible = false
			RocketMinigunIcon.visible = false
			LightningIcon.visible = false

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
