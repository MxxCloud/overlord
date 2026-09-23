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
	dps = 3.0
	morale_damage = 6
	size = Vector2(30, 14)
	color = Color("2a2a36")
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
	position.y = GameState.GROUND_Y - 170 + sin(_time) * 8
	# Spara al protagonista quando è a portata (anche mentre è fermo a
	# confondersi con lo spaventapasseri). Costringe a muoversi.
	_fire_cd -= delta
	if _fire_cd <= 0 and not is_stunned():
		var player = get_tree().get_first_node_in_group("player")
		if player != null and abs(player.position.x - position.x) < fire_range:
			_fire_cd = fire_interval
			var bullet = BulletScript.new()
			bullet.position = center()
			bullet.velocity = (player.center() - center()).normalized() * 260.0
			get_parent().add_child(bullet)


func _draw() -> void:
	super._draw()
	# Eliche.
	draw_line(Vector2(-22, -size.y - 2), Vector2(-4, -size.y - 2), Color("aaaaaa"), 2)
	draw_line(Vector2(4, -size.y - 2), Vector2(22, -size.y - 2), Color("aaaaaa"), 2)
