# Cantiere: un punto della collina dove si può costruire una difesa.
#
# Funziona come in Kingdom: il protagonista ci passa davanti, sceglie cosa
# costruire e paga in rottami. Poi un abitante libero arriva dal villaggio
# e costruisce, e questo richiede TEMPO. Per questo conta prepararsi tra
# un'onda e l'altra.
#
# I cantieri SUL SENTIERO accettano tutte le difese; quelli a lato (in mezzo
# alla collina) solo le postazioni, perché lì i robot non passano.
extends Node2D

# Catalogo delle difese costruibili: nome, costo in rottami, secondi di lavoro.
const TYPES := {
	"recinto": {"nome": "Recinto", "costo": 8, "tempo": 5.0,
		"script": preload("res://scripts/defenses/recinto.gd")},
	"fossa": {"nome": "Fossa", "costo": 6, "tempo": 4.0,
		"script": preload("res://scripts/defenses/fossa.gd")},
	"spaventapasseri": {"nome": "Spaventapasseri", "costo": 5, "tempo": 3.0,
		"script": preload("res://scripts/defenses/spaventapasseri.gd")},
	"postazione": {"nome": "Postazione", "costo": 10, "tempo": 6.0,
		"script": preload("res://scripts/defenses/postazione.gd")},
}
const ORDER := ["recinto", "fossa", "spaventapasseri", "postazione"]

@export var repair_cost := 3
@export var repair_time := 3.0
@export var interact_distance := 55.0

var main                    # la scena principale (per trovare giocatore e abitanti)
var defense = null          # la difesa costruita qui (null = cantiere vuoto)
var job := ""               # lavoro in corso: "", "costruisci" o "ripara"
var builder = null          # abitante che sta lavorando
var _pending_type := ""
var _work_left := 0.0
var _work_total := 0.0
var _prompt: Label
var on_path := false        # true se il cantiere sta su un sentiero


func _ready() -> void:
	add_to_group("slots")
	on_path = not GameState.map.paths_near(position).is_empty()
	_prompt = GameState.make_label("", 13)
	_prompt.size = Vector2(340, 40)
	_prompt.position = Vector2(-170, -150)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.modulate = GameState.untint(Color.WHITE)   # leggibile anche di notte
	add_child(_prompt)


func is_player_near() -> bool:
	return main.player.position.distance_to(position) < interact_distance


# Le difese che si possono costruire qui.
func allows(type: String) -> bool:
	return on_path or type == "postazione"


func _process(delta: float) -> void:
	if GameState.finished:
		_prompt.visible = false
		return
	if is_player_near():
		_handle_input()
	if job != "":
		_update_job(delta)
	_update_prompt()
	queue_redraw()


func _handle_input() -> void:
	if job != "":
		return
	if defense == null:
		for i in ORDER.size():
			if Input.is_action_just_pressed("costruisci_%d" % (i + 1)):
				start_build(ORDER[i])
		return
	if Input.is_action_just_pressed("interagisci"):
		if defense.needs_repair():
			if GameState.spend_scrap(repair_cost):
				_start_job("ripara", repair_time)
			else:
				_say("Servono %d rottami" % repair_cost)
		elif defense.has_method("needs_villager") and defense.needs_villager():
			var villager = main.find_free_villager(position)
			if villager != null:
				villager.go_to_post(defense)
			else:
				_say("Nessun abitante libero")


# Avvia la costruzione (la usa anche il test automatico).
func start_build(type: String) -> bool:
	if defense != null or job != "" or not allows(type):
		return false
	var info: Dictionary = TYPES[type]
	if not GameState.spend_scrap(info["costo"]):
		_say("Servono %d rottami" % info["costo"])
		return false
	_pending_type = type
	_start_job("costruisci", info["tempo"])
	return true


func _start_job(kind: String, seconds: float) -> void:
	job = kind
	_work_total = seconds
	_work_left = seconds
	builder = null


func _update_job(delta: float) -> void:
	# Serve un abitante: se non c'è (o è stato ferito) ne cerchiamo uno libero.
	if builder == null or not is_instance_valid(builder) or builder.is_injured():
		builder = main.find_free_villager(position)
		if builder != null:
			builder.go_build(self)
		return
	if builder.state != "costruisce":
		return  # sta ancora arrivando
	_work_left -= delta
	if _work_left <= 0:
		_finish_job()


func _finish_job() -> void:
	if job == "costruisci":
		defense = TYPES[_pending_type]["script"].new()
		defense.position = position
		# La difesa va nella scena principale (non dentro il cantiere), così
		# la sua `position` è nelle stesse coordinate dei robot.
		main.world.add_child(defense)
	else:
		defense.repair()
	builder.release()
	builder = null
	job = ""


func _say(text: String) -> void:
	GameState.spawn_text(position + Vector2(0, -110), text, Color("ffaaaa"))


func _update_prompt() -> void:
	var near := is_player_near()
	var text := ""
	if job != "":
		var progress := int(100.0 * (1.0 - _work_left / _work_total))
		var what := "Costruzione" if job == "costruisci" else "Riparazione"
		if builder == null:
			text = "%s: nessun abitante libero..." % what
		elif builder.state != "costruisce":
			text = "%s: %s sta arrivando" % [what, builder.nome]
		else:
			text = "%s: %d%%" % [what, progress]
	elif near and defense == null:
		var parts := []
		for i in ORDER.size():
			var info: Dictionary = TYPES[ORDER[i]]
			if allows(ORDER[i]):
				parts.append("[%d] %s (%d)" % [i + 1, info["nome"], info["costo"]])
		if parts.size() > 2:
			text = "  ".join(parts.slice(0, 2)) + "\n" + "  ".join(parts.slice(2))
		else:
			text = "  ".join(parts) + "\n(fuori dal sentiero)"
	elif near and defense.needs_repair():
		text = "[E] Ripara (%d rottami)" % repair_cost
	elif near and defense.has_method("needs_villager") and defense.needs_villager():
		text = "[E] Assegna un abitante"
	_prompt.text = text
	_prompt.visible = text != ""


func _draw() -> void:
	if defense == null and job == "":
		# Cerchio segnato a terra e paletto con bandierina: qui si può costruire.
		draw_arc(Vector2.ZERO, 22, 0, TAU, 20, Color(0.9, 0.8, 0.4, 0.35), 2)
		draw_rect(Rect2(-2, -30, 4, 30), Color("8a6a40"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(2, -30), Vector2(16, -25), Vector2(2, -20)]), Color("e0c060"))
	elif job == "costruisci":
		# Impalcatura e barra di avanzamento.
		draw_rect(Rect2(-18, -50, 36, 50), Color("c0a070"), false, 2)
		draw_line(Vector2(-18, -50), Vector2(18, 0), Color("c0a070"), 1)
		var ratio := 1.0 - _work_left / _work_total
		draw_rect(Rect2(-20, -60, 40, 4), Color("333333"))
		draw_rect(Rect2(-20, -60, 40 * ratio, 4), Color("88dd66"))
