extends Node2D

func LevelOneMusic():
	$Music/Level1Soundtrack.play()

func PauseMenuMusic():
	$Music/PauseMenuSoundtrack.play()
	
func DeathSound():
	$SFX/DeathSound.play()
	
func ClickSound():
	$SFX/ClickSound.play()
