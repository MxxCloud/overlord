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
const MapScript := preload("res://scripts/map.gd")
const SceneryFxScript := preload("res://scripts/scenery_fx.gd")
const FxScript := preload("res://scripts/fx.gd")
const LightsScript := preload("res://scripts/lights.gd")

# Abitanti disponibili all'inizio della notte: nome e foglio di sprite.
const VILLAGERS := [
	["Nonna Edda", "characters/edda"],
	["Gus", "characters/gus"],
	["Padre Tobia", "characters/tobia"],
]

var player
var dog
var world: Node2D   # contiene tutte le entità: ordinate in profondità e tinte di notte


# _ready() viene chiamata una volta, quando il nodo entra in scena.
func _ready() -> void:
	GameState.reset()
	Audio.start_ambience()
	Audio.music("music_calm")

	# Cielo e città (non tinti: sono già colori notturni).
	add_child(SceneryFxScript.new())

	# Il MONDO: un nodo che contiene terreno, personaggi, robot e difese.
	# - y_sort_enabled: chi è più in basso sullo schermo viene disegnato
	#   davanti (vista dall'alto in 3/4);
	# - modulate: la tinta notturna colora tutto ciò che contiene.
	world = Node2D.new()
	world.y_sort_enabled = true
	world.modulate = GameState.NIGHT
	add_child(world)
	GameState.world = world

	# La mappa: terreno, sentieri, decorazioni. La creiamo per prima perché
	# tutti gli altri la usano (GameState.map).
	var map = MapScript.new()
	world.add_child(map)
	GameState.map = map
	map.spawn_props(world)

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
	for pos in map.SLOTS:
		var slot = SlotScript.new()
		slot.position = pos
		slot.main = self
		world.add_child(slot)

	for i in VILLAGERS.size():
		var villager = VillagerScript.new()
		villager.nome = VILLAGERS[i][0]
		villager.sheet = VILLAGERS[i][1]
		villager.home = map.HOME + Vector2(-i * 34.0, 6.0 * i)
		villager.position = villager.home
		world.add_child(villager)

	player = PlayerScript.new()
	player.position = Vector2(640, 290)
	world.add_child(player)

	dog = DogScript.new()
	dog.position = Vector2(600, 300)
	dog.player = player
	world.add_child(dog)

	var waves = WaveManagerScript.new()
	add_child(waves)
	# Quando il gestore delle onde avvisa che sono finite tutte, abbiamo vinto.
	waves.all_waves_cleared.connect(func(): GameState.end_game(true))

	var hud = HudScript.new()
	hud.player = player
	hud.dog = dog
	hud.waves = waves
	add_child(hud)


# Restituisce l'abitante libero più vicino al punto `pos` (o null se non ce ne sono).
func find_free_villager(pos: Vector2):
	var best = null
	for villager in get_tree().get_nodes_in_group("villagers"):
		if villager.is_free() and (best == null or villager.position.distance_to(pos) < best.position.distance_to(pos)):
			best = villager
	return best


# _unhandled_input riceve i tasti non già usati da altri nodi.
func _unhandled_input(event: InputEvent) -> void:
	if GameState.finished and event.is_action_pressed("riavvia"):
		get_tree().reload_current_scene()
