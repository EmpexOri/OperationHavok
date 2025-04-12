extends Node2D

# Set up functions to play each track when called
func LevelOneMusic():
	$Music/Level1Soundtrack.volume_db = -10
	$Music/Level1Soundtrack.play()

func PauseMenuMusic():
	$Music/PauseMenuSoundtrack.volume_db = -10
	$Music/PauseMenuSoundtrack.play()
	
func DeathSound():
	$SFX/DeathSound.play()
	
func ClickSound():
	$SFX/ClickSound.play()
