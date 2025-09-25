extends CharacterBody2D

@export var secret_song_path: String = "res://Assets/Sound/Music/Temp/MachinesLove.mp3"

@onready var main_sprite   : AnimatedSprite2D = $Sprite2D     
@onready var secret_sprite : AnimatedSprite2D = $SecretSprite
@onready var local_player  : AudioStreamPlayer2D = $AudioStreamPlayer2D

var player_in_range := false
var activated       := false

func _ready() -> void:
	secret_sprite.visible = false
	secret_sprite.stop()
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = false

func _physics_process(_delta: float) -> void:
	if not activated and player_in_range and Input.is_action_just_pressed("Input_Activation"):
		_activate_secret()

func _activate_secret() -> void:
	activated = true
	await get_tree().physics_frame

	if main_sprite:
		main_sprite.frame = 1

	if secret_sprite:
		secret_sprite.visible = true
		secret_sprite.play()

	# 3. Play local music
	if local_player:
		var stream := load(secret_song_path)
		if stream:
			local_player.stream = stream
			local_player.volume_db = 0
			local_player.play()
		else:
			push_warning("Failed to load music: %s" % secret_song_path)
	else:
		push_warning("AudioPlayer node not found")
