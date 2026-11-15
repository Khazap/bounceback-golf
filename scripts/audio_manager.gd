extends Node
## AudioManager: plays the music and all sound effects.
## It's an autoload (like GameManager), so it never gets deleted when the scene
## changes. That's why the music keeps playing from the title into the game.
##
## Any script can play a sound with:   AudioManager.play("bounce")
## Press M at any time to turn the music on/off.
##
## Note for the web build: browsers block sound until the player clicks once,
## so the music starts properly after the first click (e.g. on Play).

const SOUNDS := {
	"launch": preload("res://audio/sfx_launch.wav"),
	"bounce": preload("res://audio/sfx_bounce.wav"),
	"ready": preload("res://audio/sfx_ready.wav"),
	"click": preload("res://audio/sfx_click.wav"),
	"win": preload("res://audio/sfx_win.wav"),
}
const MUSIC := preload("res://audio/music_loop.wav")
const MUSIC_VOLUME_DB := -8.0  # negative = quieter than the sound effects

var music_player: AudioStreamPlayer
var music_on := true  # the main menu's Music button changes these
var sound_on := true


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.stream = MUSIC
	music_player.volume_db = MUSIC_VOLUME_DB
	add_child(music_player)
	music_player.finished.connect(music_player.play)  # loop forever
	music_player.play()
	# Play a jingle when the player wins.
	GameManager.game_won.connect(play.bind("win"))


## Plays a sound effect once. volume: 1.0 = full, 0.5 = half. pitch: 1.0 = normal.
func play(sound_name: String, volume: float = 1.0, pitch: float = 1.0) -> void:
	if not sound_on:
		return
	var player := AudioStreamPlayer.new()
	player.stream = SOUNDS[sound_name]
	player.volume_db = linear_to_db(volume)
	player.pitch_scale = pitch
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)  # delete it when it's done


func set_music_on(on: bool) -> void:
	music_on = on
	music_player.stream_paused = not on


func set_sound_on(on: bool) -> void:
	sound_on = on


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		set_music_on(not music_on)
