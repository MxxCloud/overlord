# Drone Sondaggio: vola, è fragile e veloce. Ignora recinti e fosse,
# ma lo spaventapasseri lo confonde. Chiede feedback mentre ti invade.
extends "res://scripts/enemies/enemy.gd"

const BulletScript := preload("res://scripts/enemies/bullet.gd")

var fire_interval := 4.5
var fire_range := 450.0
var _time := 0.0
var _fire_cd := 0.0


func _init() -> void:
	kind = "drone"
	max_hp = 2.0
	speed = 40.0
	flying = true
	fly_height = 80.0
	dps = 3.0
	morale_damage = 6
	sheet = "characters/drone"
	frame_time = 0.12
	eye_height = 24.0
	color = Color("454c58")
	spawn_lines = [
		"Sondaggio: quanto è soddisfatto della sua fattoria?",
		"Arrendersi è facile!",
		"Il 97% degli umani processati non ha fatto reclami.",
	]
	death_lines = ["Feedback registrato.", "Grazie per la sua opinione."]


func _ready() -> void:
	super._ready()
	_time = randf() * TAU
	_fire_cd = randf_range(1.0, fire_interval)


# Il drone vola in alto e ondeggia.
func _update_extra(delta: float) -> void:
	_time += delta * 3.0
	_anim_time += delta  # le eliche girano anche quando è fermo
	fly_height = 80.0 + sin(_time) * 6.0
	# Spara al protagonista quando è a portata (anche mentre è fermo a
	# confondersi con lo spaventapasseri). Costringe a muoversi.
	_fire_cd -= delta
	if _fire_cd <= 0 and not is_stunned():
		var player = get_tree().get_first_node_in_group("player")
		if player != null and player.position.distance_to(position) < fire_range:
			_fire_cd = fire_interval
			var bullet = BulletScript.new()
			bullet.position = center()
			bullet.velocity = (player.center() - center()).normalized() * 260.0
			get_tree().current_scene.add_child(bullet)
			GameState.fx.flash(center(), 18.0, Color(1.0, 0.2, 0.3, 0.8), 0.08)
