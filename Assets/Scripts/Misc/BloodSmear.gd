extends Sprite2D

@export var lifetime: float = 30.0  # Time before it starts fading
@export var fade_time: float = 5.0  # Time it takes to fade out

var timer: Timer
var fading := false

func _ready():
	Global.register_smear(self)
	timer = $Timer
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(start_fading)
	timer.start()

func start_fading():
	fading = true
	timer.stop()  # Stop any current countdown
	timer.disconnect("timeout", start_fading)  # Clean up old signal
	timer.wait_time = fade_time
	timer.timeout.connect(_on_fade_finished)
	timer.start()

func _on_fade_finished():
	queue_free()

func _process(delta):
	if fading:
		var alpha_decrease = delta / fade_time
		modulate.a = max(0.0, modulate.a - alpha_decrease)

func _exit_tree():
	Global.unregister_smear(self)

func _on_screen_exited():
	self.visible = false
	self.set_process(false)  # Optional if you want to stop any logic
