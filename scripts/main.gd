# Main: la scena principale. Costruisce il livello (collina, difese, protagonista,
# cane, onde, HUD) e disegna lo sfondo.
#
# In questo prototipo creiamo quasi tutto da codice con `.new()` invece di
# preparare tante scene nell'editor: così resta tutto leggibile in pochi file.
# Più avanti, con la grafica vera, conviene passare a scene (.tscn) separate.
extends Node2D

# `preload` carica uno script (o una risorsa) quando il gioco parte.
const PlayerScript := preload("res://scripts/player.gd")
const DogScript := preload("res://scripts/dog.gd")
const WaveManagerScript := preload("res://scripts/wave_manager.gd")
const HudScript := preload("res://scripts/hud.gd")
const RecintoScript := preload("res://scripts/defenses/recinto.gd")
const FossaScript := preload("res://scripts/defenses/fossa.gd")
const SpaventapasseriScript := preload("res://scripts/defenses/spaventapasseri.gd")

var player
var dog


# _ready() viene chiamata una volta, quando il nodo entra in scena.
func _ready() -> void:
	GameState.reset()

	# Difese pre-piazzate: da destra (dove arrivano i robot) verso il cancello.
	_add_defense(SpaventapasseriScript, 1060)
	_add_defense(FossaScript, 850)
	_add_defense(RecintoScript, 620)

	player = PlayerScript.new()
	player.position = Vector2(320, GameState.GROUND_Y)
	add_child(player)

	dog = DogScript.new()
	dog.position = Vector2(260, GameState.GROUND_Y)
	dog.player = player
	add_child(dog)

	var waves = WaveManagerScript.new()
	add_child(waves)
	# Quando il gestore delle onde avvisa che sono finite tutte, abbiamo vinto.
	waves.all_waves_cleared.connect(func(): GameState.end_game(true))

	var hud = HudScript.new()
	hud.player = player
	hud.dog = dog
	hud.waves = waves
	add_child(hud)


func _add_defense(script: Script, x: float) -> void:
	var defense = script.new()
	defense.position = Vector2(x, GameState.GROUND_Y)
	add_child(defense)


# _unhandled_input riceve i tasti non già usati da altri nodi.
func _unhandled_input(event: InputEvent) -> void:
	if GameState.finished and event.is_action_pressed("riavvia"):
		get_tree().reload_current_scene()


# _draw() disegna forme semplici. È chiamata da Godot quando serve.
# Tutto questo sfondo verrà sostituito dalla pixel art.
func _draw() -> void:
	var w := GameState.SCREEN_W
	var g := GameState.GROUND_Y

	# Cielo: fasce di colore dal viola scuro all'arancio del tramonto.
	var sky := [Color("241a33"), Color("3a2447"), Color("5c2f4a"), Color("8a4046"), Color("c0613f")]
	for i in sky.size():
		draw_rect(Rect2(0, i * 70, w, 70), sky[i])
	draw_rect(Rect2(0, 350, w, g - 350), Color("c0613f"))

	# Megalopoli all'orizzonte (a destra): palazzi scuri con luci blu.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7  # seme fisso: la città è sempre uguale
	var x := 560.0
	while x < w:
		var bw := rng.randf_range(22, 50)
		var bh := rng.randf_range(80, 300) * (x / w)
		draw_rect(Rect2(x, 460 - bh, bw, bh + 40), Color("1d1830"))
		draw_rect(Rect2(x + bw * 0.45, 460 - bh, 3, bh * 0.6), Color("3aa0ff"))
		x += bw + rng.randf_range(2, 12)

	# Colline lontane e collina in primo piano.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 470), Vector2(300, 430), Vector2(700, 480), Vector2(w, 460),
		Vector2(w, g), Vector2(0, g)]), Color("2e3a2a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, g - 30), Vector2(400, g - 15), Vector2(w, g),
		Vector2(w, 720), Vector2(0, 720)]), Color("3f5b2e"))
	draw_rect(Rect2(0, g, w, 720 - g), Color("4a6b34"))
	draw_line(Vector2(0, g), Vector2(w, g), Color("6b8f47"), 3)

	# Cascina (a sinistra) con finestre illuminate.
	draw_rect(Rect2(8, g - 90, 90, 90), Color("8c7b6a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, g - 90), Vector2(53, g - 135), Vector2(106, g - 90)]), Color("7a3325"))
	draw_rect(Rect2(22, g - 70, 18, 18), Color("ffcc55"))
	draw_rect(Rect2(64, g - 70, 18, 18), Color("ffcc55"))
	draw_rect(Rect2(44, g - 40, 18, 40), Color("4a3320"))

	# Cancello del villaggio: se un robot lo raggiunge, il morale cala.
	var gx := GameState.GATE_X
	draw_rect(Rect2(gx - 4, g - 70, 8, 70), Color("5a3d22"))
	draw_rect(Rect2(gx + 26, g - 70, 8, 70), Color("5a3d22"))
	draw_rect(Rect2(gx - 4, g - 60, 38, 6), Color("7a5530"))
	draw_rect(Rect2(gx - 4, g - 30, 38, 6), Color("7a5530"))
