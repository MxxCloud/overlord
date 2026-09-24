# Audio: effetti sonori, ambiente notturno e musica.
#
# È un AUTOLOAD (come GameState): da qualsiasi script si scrive per esempio
#   Audio.play("shoot")
# I file sono in assets/audio (suoni CC0, vedi assets/CREDITS.md).
#
# Musica: di giorno (pausa tra le onde) un tema acustico western; durante
# l'assedio un tema synth, come previsto dal GDD (il synth "invade" il folk).
extends Node

@export var sfx_volume_db := -4.0
@export var music_volume_db := -12.0
@export var ambience_volume_db := -14.0

# Suoni con più varianti: ne viene scelta una a caso ogni volta.
const VARIANTS := {
	"hit": ["hit_1", "hit_2"],
	"explosion": ["explosion_1", "explosion_2", "explosion_3"],
	"glass": ["glass_1", "glass_2"],
	"scrap": ["scrap_1", "scrap_2"],
	"robot_voice": ["robot_voice_1", "robot_voice_2"],
	"raven": ["raven_1", "raven_2"],
}

var _streams := {}
var _pool: Array = []          # lettori per gli effetti (più suoni insieme)
var _last_played := {}         # per non ripetere lo stesso suono troppe volte al secondo
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _current_music := ""
var _raven_cd := 8.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 12:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	_music = AudioStreamPlayer.new()
	_music.volume_db = music_volume_db
	add_child(_music)
	# Quando la musica finisce, ricomincia (loop).
	_music.finished.connect(func(): _music.play())
	_ambience = AudioStreamPlayer.new()
	_ambience.volume_db = ambience_volume_db
	add_child(_ambience)
	_ambience.finished.connect(func(): _ambience.play())


func _stream(name: String) -> AudioStream:
	if not _streams.has(name):
		for ext in ["ogg", "wav"]:
			var path := "res://assets/audio/%s.%s" % [name, ext]
			if ResourceLoader.exists(path):
				_streams[name] = load(path)
				break
	return _streams.get(name)


# Suona un effetto. `pitch_range` cambia un po' il tono ogni volta, così i suoni
# ripetuti non diventano monotoni. `volume` in decibel (0 = normale, -6 = metà).
func play(name: String, volume: float = 0.0, pitch_range: float = 0.1, pitch: float = 1.0) -> void:
	# Evita che decine di colpi nello stesso istante diventino un muro di rumore.
	var now := Time.get_ticks_msec()
	if now - _last_played.get(name, -1000) < 40:
		return
	_last_played[name] = now
	var actual: String = VARIANTS[name].pick_random() if VARIANTS.has(name) else name
	var stream := _stream(actual)
	if stream == null:
		return
	for player in _pool:
		if not player.playing:
			player.stream = stream
			player.volume_db = sfx_volume_db + volume
			player.pitch_scale = pitch * randf_range(1.0 - pitch_range, 1.0 + pitch_range)
			player.play()
			return


# Cambia musica ("music_calm" o "music_siege") con una breve dissolvenza.
func music(name: String) -> void:
	if name == _current_music:
		return
	_current_music = name
	var tween := create_tween()
	if _music.playing:
		tween.tween_property(_music, "volume_db", -40.0, 0.8)
	tween.tween_callback(func():
		_music.stream = _stream(name)
		_music.play())
	tween.tween_property(_music, "volume_db", music_volume_db, 0.8)


func stop_music() -> void:
	_current_music = ""
	create_tween().tween_property(_music, "volume_db", -40.0, 1.0)


func start_ambience() -> void:
	if not _ambience.playing:
		_ambience.stream = _stream("ambience")
		_ambience.play()


func _process(delta: float) -> void:
	# Ogni tanto un corvo gracchia nel bosco.
	_raven_cd -= delta
	if _raven_cd <= 0:
		_raven_cd = randf_range(12.0, 25.0)
		if _ambience.playing:
			play("raven", -10.0)
