# La mappa della collina, vista dall'alto in 3/4.
#
# In alto c'è il villaggio (cascina, cancello "Quietville", palizzata) con la
# città all'orizzonte. In basso c'è il bosco: da lì sbucano i robot, che
# salgono lungo due SENTIERI fino al cancello.
#
# Questo script:
# - definisce i sentieri (curve) e i punti importanti (cancello, cantieri, case);
# - disegna il terreno (erba e sentieri) UNA volta sola;
# - piazza le decorazioni (alberi, rocce, case) come sprite ordinati in profondità;
# - offre funzioni di aiuto ai robot per muoversi lungo i sentieri.
# Cielo e città sono in scenery_fx.gd.
extends Node2D

const Sprites := preload("res://scripts/sprites.gd")
const S := 3.0   # ingrandimento della pixel art

# Punti dei due sentieri, dal bosco (fuori schermo in basso) al cancello.
const PATH_POINTS := [
	[Vector2(170, 790), Vector2(230, 660), Vector2(400, 610), Vector2(500, 530),
		Vector2(380, 450), Vector2(320, 370), Vector2(430, 300), Vector2(570, 255), Vector2(640, 222)],
	[Vector2(1110, 790), Vector2(1040, 660), Vector2(870, 615), Vector2(770, 530),
		Vector2(900, 450), Vector2(960, 370), Vector2(850, 300), Vector2(710, 255), Vector2(640, 222)],
]
const GATE := Vector2(640, 222)       # il cancello: se i robot ci arrivano, cala il morale
const HOME := Vector2(585, 240)       # dove aspettano gli abitanti liberi
const FARMHOUSE := Vector2(420, 206)  # cascina (base dell'edificio)
const COTTAGE := Vector2(880, 206)
const PLAY_AREA := Rect2(20, 225, 1240, 480)   # dove può camminare il protagonista

# Cantieri: quelli sul sentiero possono bloccare i robot; quelli a lato
# (in mezzo alla collina) accettano solo postazioni.
const SLOTS := [
	Vector2(430, 598), Vector2(868, 604),          # bassi, sui sentieri
	Vector2(338, 390), Vector2(944, 390),          # alti, sui sentieri
	Vector2(640, 520), Vector2(640, 355),          # al centro, tra i due sentieri
]

# Colori del sentiero (presi dal tileset medievale).
const DIRT := Color("b36c61")
const DIRT_EDGE := Color("6e3c48")
const DIRT_LIGHT := Color("c4806c")

var curves: Array = []          # un oggetto Curve2D per sentiero
var _rng := RandomNumberGenerator.new()
# Timbri per disegnare i sentieri. Vanno CONSERVATI qui: se fossero variabili
# locali di _draw() verrebbero cancellati subito e Godot li mostrerebbe bianchi.
var _edge: ImageTexture
var _dirt: ImageTexture
var _spot: ImageTexture


func _ready() -> void:
	z_index = -20
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED   # per ripetere l'erba
	add_to_group("lights")
	for points in PATH_POINTS:
		var curve := Curve2D.new()
		curve.bake_interval = 4.0
		for i in points.size():
			# Tangenti morbide: il sentiero curva invece di fare spigoli.
			var prev: Vector2 = points[max(i - 1, 0)]
			var next: Vector2 = points[min(i + 1, points.size() - 1)]
			var tangent: Vector2 = (next - prev) * 0.25
			curve.add_point(points[i], -tangent, tangent)
		curves.append(curve)
	_edge = _blob(8, DIRT_EDGE)
	_dirt = _blob(7, DIRT)
	_spot = _blob(2, DIRT_LIGHT)


# --- Aiuti per i sentieri -------------------------------------------------------

func path_length(path_id: int) -> float:
	return curves[path_id].get_baked_length()


func path_point(path_id: int, progress: float) -> Vector2:
	return curves[path_id].sample_baked(clampf(progress, 0.0, path_length(path_id)))


# Direzione del sentiero in quel punto (vettore lungo 1).
func path_direction(path_id: int, progress: float) -> Vector2:
	var a := path_point(path_id, progress)
	var b := path_point(path_id, progress + 6.0)
	return (b - a).normalized() if a != b else Vector2.UP


# Per ogni sentiero che passa vicino a `pos`, restituisce {id: progresso}.
func paths_near(pos: Vector2, max_distance: float = 30.0) -> Dictionary:
	var result := {}
	for i in curves.size():
		var offset: float = curves[i].get_closest_offset(pos)
		if curves[i].sample_baked(offset).distance_to(pos) <= max_distance:
			result[i] = offset
	return result


func distance_to_paths(pos: Vector2) -> float:
	var best := INF
	for curve in curves:
		best = minf(best, curve.sample_baked(curve.get_closest_offset(pos)).distance_to(pos))
	return best


# --- Decorazioni (sprite ordinati in profondità) ------------------------------

# Chiamata da main.gd: aggiunge alberi, rocce e case al nodo del mondo.
func spawn_props(world: Node2D) -> void:
	_rng.seed = 21
	# Il villaggio: cascina, casetta, palizzata con il cancello, barili, pozzo.
	world.add_child(Sprites.make_prop("decor/farmhouse", FARMHOUSE))
	world.add_child(Sprites.make_prop("decor/cottage", COTTAGE))
	world.add_child(Sprites.make_prop("decor/gate", GATE + Vector2(0, -6)))
	for x in range(48, 1280, 96):
		if absf(x - GATE.x) > 80:
			world.add_child(Sprites.make_prop("decor/palisade", Vector2(x, 218)))
	for p in [Vector2(520, 212), Vector2(545, 216), Vector2(755, 214)]:
		world.add_child(Sprites.make_prop("decor/barrel", p))
	world.add_child(Sprites.make_prop("decor/well", Vector2(1010, 214)))
	world.add_child(Sprites.make_prop("decor/chapel", Vector2(210, 210)))
	world.add_child(Sprites.make_prop("decor/house_b", Vector2(1150, 210)))

	# Il bosco in basso e ai lati (lontano dai sentieri, che restano liberi).
	var trees := ["decor/pine", "decor/pine", "decor/tree_round", "decor/tree_big"]
	var placed := 0
	var attempts := 0
	while placed < 60 and attempts < 2000:
		attempts += 1
		var p := Vector2(_rng.randf_range(-20, 1300), _rng.randf_range(660, 780))
		if _rng.randf() < 0.4:
			var left := _rng.randf() < 0.5
			p = Vector2(_rng.randf_range(-10, 70) if left else _rng.randf_range(1210, 1290), _rng.randf_range(300, 700))
		if distance_to_paths(p) < 60 or _near_slot(p, 70):
			continue
		world.add_child(Sprites.make_prop(trees[_rng.randi() % trees.size()], p))
		placed += 1

	# Rocce, ceppi e cespugli sparsi sulla collina.
	var small := ["decor/rock", "decor/rock_small", "decor/stump", "decor/bush", "decor/fern", "decor/dead_tree", "decor/pine_small"]
	placed = 0
	attempts = 0
	while placed < 22 and attempts < 2000:
		attempts += 1
		var p := Vector2(_rng.randf_range(60, 1220), _rng.randf_range(270, 650))
		if distance_to_paths(p) < 50 or _near_slot(p, 80) or p.distance_to(Vector2(640, 440)) < 90:
			continue
		world.add_child(Sprites.make_prop(small[_rng.randi() % small.size()], p))
		placed += 1


func _near_slot(p: Vector2, radius: float) -> bool:
	for slot in SLOTS:
		if p.distance_to(slot) < radius:
			return true
	return false


# --- Disegno del terreno -------------------------------------------------------

# Un "timbro" circolare in pixel art (usato per disegnare i sentieri).
func _blob(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2 + 1
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			if Vector2(x - radius, y - radius).length() <= radius + 0.3:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


# Disegna un timbro allineato alla griglia dei pixel ingranditi.
func _stamp(texture: Texture2D, pos: Vector2) -> void:
	var half := (texture.get_width() - 1) * 0.5
	var p := (pos / S).floor() - Vector2(half, half)
	draw_texture_rect(texture, Rect2(p * S, texture.get_size() * S), false)


func _draw() -> void:
	_rng.seed = 5
	# Prato: tessere d'erba ripetute, con qualche tessera più scura qua e là.
	var grass_a := Sprites.tex("tiles/grass_a")
	var grass_b := Sprites.tex("tiles/grass_b")
	# Disegniamo in "pixel dell'arte" (x3) con una trasformazione di scala.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(S, S))
	draw_texture_rect(grass_a, Rect2(0, 40, 1280 / S, 600 / S), true)
	for ty in range(0, 13):
		for tx in range(0, 27):
			if _rng.randf() < 0.3:
				draw_texture_rect(grass_b, Rect2(tx * 16, 40 + ty * 16, 16, 16), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Sentieri: prima il bordo scuro, poi la terra, poi qualche chiazza chiara.
	for curve in curves:
		for p in curve.get_baked_points():
			_stamp(_edge, p)
	for curve in curves:
		var points: PackedVector2Array = curve.get_baked_points()
		for i in points.size():
			_stamp(_dirt, points[i])
			if i % 9 == 0:
				_stamp(_spot, points[i] + Vector2(_rng.randf_range(-9, 9), _rng.randf_range(-6, 6)))

	# Fiori e ciuffi d'erba (piatti, sotto a tutto il resto).
	var decals := ["decor/tuft", "decor/tuft", "decor/weed", "decor/flower", "decor/flowers"]
	for i in 90:
		var p := Vector2(_rng.randf_range(0, 1280), _rng.randf_range(235, 700))
		if distance_to_paths(p) < 34:
			continue
		Sprites.draw_image(self, decals[_rng.randi() % decals.size()], p)

	# Il bosco in basso è più buio: velo scuro sfumato.
	for i in 12:
		draw_rect(Rect2(0, 600 + i * 10, 1280, 10), Color(0.02, 0.03, 0.05, 0.03 * i))


# Luce calda dalle finestre della cascina e della casetta.
func get_lights() -> Array:
	return [
		[FARMHOUSE + Vector2(-60, -40), 50.0, Color(1.0, 0.7, 0.3, 0.4)],
		[FARMHOUSE + Vector2(60, -40), 50.0, Color(1.0, 0.7, 0.3, 0.4)],
		[COTTAGE + Vector2(0, -40), 55.0, Color(1.0, 0.7, 0.3, 0.35)],
	]
