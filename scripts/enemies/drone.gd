# Drone Sondaggio: vola, è fragile e veloce. Ignora recinti e fosse,
# ma lo spaventapasseri lo confonde. Chiede feedback mentre ti invade.
extends "res://scripts/enemies/enemy.gd"

var _time := 0.0


func _init() -> void:
	kind = "drone"
	max_hp = 1.0
	speed = 70.0
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


# Il drone vola in alto e ondeggia.
func _update_extra(delta: float) -> void:
	_time += delta * 3.0
	position.y = GameState.GROUND_Y - 170 + sin(_time) * 8


func _draw() -> void:
	super._draw()
	# Eliche.
	draw_line(Vector2(-22, -size.y - 2), Vector2(-4, -size.y - 2), Color("aaaaaa"), 2)
	draw_line(Vector2(4, -size.y - 2), Vector2(22, -size.y - 2), Color("aaaaaa"), 2)
