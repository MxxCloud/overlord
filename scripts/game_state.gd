# GameState: lo "stato globale" della partita.
#
# È un AUTOLOAD (vedi project.godot, sezione [autoload]): Godot lo crea da solo
# all'avvio e lo rende raggiungibile da qualsiasi script scrivendo `GameState`.
# Qui teniamo le cose che servono a tutti: morale del villaggio, rottami,
# costanti del livello e fine partita.
extends Node

# I SEGNALI sono "avvisi" che uno script lancia e che altri script ascoltano.
# L'HUD, per esempio, ascolta `game_over` per mostrare il report finale.
signal morale_changed(value)
signal scrap_changed(value)
signal game_over(won)
signal player_hurt

# Costanti del livello (in pixel). Lo schermo è 1280x720.
const GROUND_Y := 600.0   # altezza del terreno: tutti "camminano" su questa linea
const GATE_X := 110.0     # posizione del cancello del villaggio (a sinistra)
const SCREEN_W := 1280.0  # larghezza dello schermo

@export var max_morale := 100
@export var start_scrap := 30       # rottami a inizio notte, per le prime difese

var morale := 100
var scrap := 0            # rottami raccolti: servono a riparare le difese
var finished := false     # true quando la partita è finita (vinta o persa)
var kills := 0            # robot distrutti, per il report finale

# Riferimenti impostati da main.gd a ogni partita.
var fx                    # il nodo degli effetti (fx.gd)
var camera: Camera2D      # la camera, che facciamo tremare

var _shake := 0.0
var _hitstop_active := false


func _ready() -> void:
	_setup_input()


# Rimette tutto a zero. La chiama main.gd all'inizio di ogni partita.
func reset() -> void:
	morale = max_morale
	scrap = start_scrap
	finished = false
	kills = 0


# --- "Game feel": scossone e fermo immagine -----------------------------------

# Fa tremare lo schermo. `amount` è l'ampiezza in pixel (2 = leggero, 8 = forte).
func shake(amount: float) -> void:
	_shake = max(_shake, amount)


# Congela il gioco per un istante (es. 0.05 s) quando un colpo va a segno:
# è un trucco classico per dare "peso" agli impatti.
func hitstop(duration: float) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	var previous := Engine.time_scale
	Engine.time_scale = previous * 0.05
	# Timer che ignora il rallentamento (ultimo parametro = true).
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = previous
	_hitstop_active = false


func _process(delta: float) -> void:
	if camera != null and is_instance_valid(camera):
		# Spostamento casuale arrotondato ai pixel, che si smorza velocemente.
		camera.offset = (Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake).round()
	_shake = move_toward(_shake, 0.0, 40.0 * delta)


func damage_morale(amount: int) -> void:
	if finished:
		return
	morale = max(0, morale - amount)
	morale_changed.emit(morale)
	if morale <= 0:
		end_game(false)


func add_scrap(amount: int) -> void:
	scrap += amount
	scrap_changed.emit(scrap)


# Prova a spendere rottami. Restituisce true se ce n'erano abbastanza.
func spend_scrap(amount: int) -> bool:
	if scrap < amount:
		return false
	scrap -= amount
	scrap_changed.emit(scrap)
	return true


func end_game(won: bool) -> void:
	if finished:
		return
	finished = true
	game_over.emit(won)


# Crea un'etichetta di testo già leggibile (bianca con bordo nero).
# La usano i fumetti dei robot, il cane e l'HUD.
func make_label(text: String, font_size: int = 14) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


# Mostra un testo che sale e svanisce (es. "+1 rottame", battute dei robot).
func spawn_text(pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var label := make_label(text, 13)
	label.modulate = color
	label.size = Vector2(300, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos - Vector2(150, 0)
	get_tree().current_scene.add_child(label)
	# Un TWEEN anima una proprietà nel tempo: qui sposta in alto e sfuma.
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 2.0)
	tween.tween_property(label, "modulate:a", 0.0, 2.0)
	tween.chain().tween_callback(label.queue_free)


# Definisce i comandi (le "azioni" di input) da codice.
# Si potrebbero impostare anche dall'editor: Progetto > Impostazioni > Mappa input.
func _setup_input() -> void:
	_add_keys("sinistra", [KEY_A, KEY_LEFT])
	_add_keys("destra", [KEY_D, KEY_RIGHT])
	_add_keys("interagisci", [KEY_E])
	_add_keys("costruisci_1", [KEY_1])
	_add_keys("costruisci_2", [KEY_2])
	_add_keys("costruisci_3", [KEY_3])
	_add_keys("costruisci_4", [KEY_4])
	_add_keys("riavvia", [KEY_ENTER])
	_add_mouse("spara", MOUSE_BUTTON_LEFT)
	_add_mouse("cane", MOUSE_BUTTON_RIGHT)


func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


func _add_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
