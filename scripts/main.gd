# Main: la scena principale. Costruisce il livello: sfondo, cantieri,
# abitanti, protagonista, cane, onde, effetti, luci, camera e HUD.
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
const SlotScript := preload("res://scripts/build_slot.gd")
const VillagerScript := preload("res://scripts/villager.gd")
const BackgroundScript := preload("res://scripts/background.gd")
const SceneryFxScript := preload("res://scripts/scenery_fx.gd")
const FxScript := preload("res://scripts/fx.gd")
const LightsScript := preload("res://scripts/lights.gd")

# Posizioni dei cantieri lungo la collina (da destra verso il villaggio).
const SLOT_POSITIONS := [1060.0, 880.0, 700.0, 520.0]
# Abitanti disponibili all'inizio della notte: nome, vestiti, capelli.
const VILLAGERS := [
	["Nonna Edda", Color("9a5a8a"), Color("b8b8c0")],
	["Gus", Color("5a6a7a"), Color("5a3a1f")],
	["Padre Tobia", Color("2a2a30"), Color("3a3a3a")],
]

var player
var dog


# _ready() viene chiamata una volta, quando il nodo entra in scena.
func _ready() -> void:
	GameState.reset()

	# Sfondo statico e sfondo animato (z_index negativo: stanno dietro a tutto).
	var background = BackgroundScript.new()
	add_child(background)
	var scenery = SceneryFxScript.new()
	scenery.background = background
	add_child(scenery)

	# Camera fissa al centro dello schermo: serve per farla tremare.
	var camera := Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)
	GameState.camera = camera

	# Effetti (particelle) e luci: hanno z_index alto, stanno davanti.
	var fx = FxScript.new()
	add_child(fx)
	GameState.fx = fx
	add_child(LightsScript.new())

	# Cantieri vuoti: sarà il giocatore a decidere cosa costruire.
	for x in SLOT_POSITIONS:
		var slot = SlotScript.new()
		slot.position = Vector2(x, GameState.GROUND_Y)
		slot.main = self
		add_child(slot)

	for i in VILLAGERS.size():
		var villager = VillagerScript.new()
		villager.nome = VILLAGERS[i][0]
		villager.color = VILLAGERS[i][1]
		villager.hair = VILLAGERS[i][2]
		villager.home_x = 40.0 + i * 25.0
		villager.position = Vector2(villager.home_x, GameState.GROUND_Y)
		add_child(villager)

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


# Restituisce l'abitante libero più vicino al punto x (o null se non ce ne sono).
func find_free_villager(x: float):
	var best = null
	for villager in get_tree().get_nodes_in_group("villagers"):
		if villager.is_free() and (best == null or abs(villager.position.x - x) < abs(best.position.x - x)):
			best = villager
	return best


# _unhandled_input riceve i tasti non già usati da altri nodi.
func _unhandled_input(event: InputEvent) -> void:
	if GameState.finished and event.is_action_pressed("riavvia"):
		get_tree().reload_current_scene()
