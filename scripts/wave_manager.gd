# Gestore delle onde: decide quali robot arrivano e quando.
#
# Per cambiare la difficoltà basta modificare l'array `waves` qui sotto:
# ogni onda è una lista di gruppi, e ogni gruppo dice
#   "tipo": che robot, "quanti": quanti, "intervallo": secondi tra uno e l'altro,
#   "ritardo": (facoltativo) dopo quanti secondi dall'inizio dell'onda parte il gruppo.
extends Node

signal wave_started(number)
signal all_waves_cleared

const ENEMY_SCRIPTS := {
	"servitore": preload("res://scripts/enemies/servitore.gd"),
	"drone": preload("res://scripts/enemies/drone.gd"),
	"segugio": preload("res://scripts/enemies/segugio.gd"),
}

@export var first_wave_delay := 35.0     # tempo per costruire le prime difese
@export var pause_between_waves := 25.0  # tempo per riparare e prepararsi

const NAMES := {"servitore": ["servitore", "servitori"], "drone": ["drone", "droni"],
	"segugio": ["segugio", "segugi"]}

var waves := [
	# Onda 1: "Gentile cliente". Solo servitori, per imparare a costruire.
	[
		{"tipo": "servitore", "quanti": 5, "intervallo": 4.0},
	],
	# Onda 2: arrivano i droni (le molotov non li raggiungono: serve la doppietta).
	[
		{"tipo": "servitore", "quanti": 7, "intervallo": 3.5},
		{"tipo": "drone", "quanti": 3, "intervallo": 5.0, "ritardo": 6.0},
	],
	# Onda 3: i segugi saltano le fosse. Qui il cane serve davvero.
	[
		{"tipo": "servitore", "quanti": 8, "intervallo": 3.0},
		{"tipo": "segugio", "quanti": 3, "intervallo": 6.0, "ritardo": 5.0},
		{"tipo": "drone", "quanti": 3, "intervallo": 6.0, "ritardo": 10.0},
	],
]

var current := -1                # indice dell'onda attuale (-1 = non ancora iniziata)
var pause_left := 0.0            # secondi prima della prossima onda
var spawning := false            # true mentre un'onda è in corso
var _queue: Array = []           # robot ancora da far entrare: {tipo, t}
var _time := 0.0


func _ready() -> void:
	pause_left = first_wave_delay


func total_waves() -> int:
	return waves.size()


# Descrive la prossima onda, es. "7 servitori, 3 droni". È il Fiuto del cane:
# si sa in anticipo cosa sta arrivando e ci si può preparare.
func describe_next_wave() -> String:
	if current + 1 >= waves.size():
		return ""
	var parts := []
	for group in waves[current + 1]:
		var n: int = group["quanti"]
		parts.append("%d %s" % [n, NAMES[group["tipo"]][0 if n == 1 else 1]])
	return ", ".join(parts)


func _physics_process(delta: float) -> void:
	if GameState.finished:
		return
	if not spawning:
		pause_left -= delta
		if pause_left <= 0:
			_start_next_wave()
		return

	_time += delta
	# Fa entrare tutti i robot il cui momento è arrivato.
	while _queue.size() > 0 and _queue[0]["t"] <= _time:
		_spawn(_queue.pop_front()["tipo"])

	# Onda finita quando non restano robot da far entrare né in campo.
	if _queue.is_empty() and get_tree().get_nodes_in_group("enemies").is_empty():
		spawning = false
		if current >= waves.size() - 1:
			all_waves_cleared.emit()
		else:
			pause_left = pause_between_waves


func _start_next_wave() -> void:
	current += 1
	_queue.clear()
	for group in waves[current]:
		for i in group["quanti"]:
			_queue.append({"tipo": group["tipo"], "t": group.get("ritardo", 0.0) + i * group["intervallo"]})
	# Ordina per tempo di arrivo.
	_queue.sort_custom(func(a, b): return a["t"] < b["t"])
	_time = 0.0
	spawning = true
	wave_started.emit(current + 1)


func _spawn(tipo: String) -> void:
	var enemy = ENEMY_SCRIPTS[tipo].new()
	# Entrano da destra, appena fuori dallo schermo.
	enemy.position = Vector2(GameState.SCREEN_W + 60 + randf() * 80, GameState.GROUND_Y)
	get_parent().add_child(enemy)
