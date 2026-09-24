# La mappa della collina, vista dall'alto in 3/4.
#
# In alto c'è il villaggio (cascina, cancello "Quietville", mulino) con la
# città all'orizzonte. In basso c'è il bosco: da lì sbucano i robot, che
# salgono lungo due SENTIERI fino al cancello.
#
# Questo script:
# - definisce i sentieri (curve) e i punti importanti (cancello, cantieri, case);
# - disegna il terreno UNA volta sola (Godot memorizza il disegno);
# - offre funzioni di aiuto ai robot per muoversi lungo i sentieri.
extends Node2D

const PX := 3

# Punti dei due sentieri, dal bosco (fuori schermo in basso) al cancello.
const PATH_POINTS := [
	[Vector2(170, 790), Vector2(230, 660), Vector2(400, 610), Vector2(500, 530),
		Vector2(380, 450), Vector2(320, 370), Vector2(430, 300), Vector2(570, 250), Vector2(640, 200)],
	[Vector2(1110, 790), Vector2(1040, 660), Vector2(870, 615), Vector2(770, 530),
		Vector2(900, 450), Vector2(960, 370), Vector2(850, 300), Vector2(710, 250), Vector2(640, 200)],
]
const GATE := Vector2(640, 200)       # il cancello: se i robot ci arrivano, cala il morale
const HOME := Vector2(560, 196)       # dove aspettano gli abitanti liberi
const FARMHOUSE := Vector2(470, 186)  # cascina (piedi dell'edificio)
const WINDMILL := Vector2(830, 186)
const PLAY_AREA := Rect2(20, 205, 1240, 500)   # dove può camminare il protagonista

# Cantieri: posizione. Quelli sul sentiero possono bloccare i robot;
# quelli a lato (in mezzo alla collina) accettano solo postazioni.
const SLOTS := [
	Vector2(430, 598), Vector2(868, 604),          # bassi, sui sentieri
	Vector2(338, 390), Vector2(944, 390),          # alti, sui sentieri
	Vector2(640, 520), Vector2(640, 350),          # al centro, tra i due sentieri
]

var curves: Array = []          # un oggetto Curve2D per sentiero
# Usati da scenery_fx.gd per le animazioni.
var antenna_tops: Array = []
var spire_tops: Array = []
var stars: Array = []


func _ready() -> void:
	z_index = -20
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
# Serve alle difese per sapere su quale tratto di sentiero si trovano.
func paths_near(pos: Vector2, max_distance: float = 30.0) -> Dictionary:
	var result := {}
	for i in curves.size():
		var offset: float = curves[i].get_closest_offset(pos)
		if curves[i].sample_baked(offset).distance_to(pos) <= max_distance:
			result[i] = offset
	return result


# --- Disegno -------------------------------------------------------------------

func _px(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(floorf(x / PX) * PX, floorf(y / PX) * PX, maxf(PX, roundf(w / PX) * PX), maxf(PX, roundf(h / PX) * PX)), color)


func _draw() -> void:
	_draw_sky_and_city()
	_draw_grass()
	for curve in curves:
		_draw_path(curve)
	_draw_rocks()
	_draw_forest()
	_draw_village()
	_draw_signpost(Vector2(1180, 700))


func _draw_sky_and_city() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color("0a0a1a"))
	gradient.set_color(1, Color("7a3a3a"))
	gradient.add_point(0.5, Color("24183a"))
	for y in range(0, 130, PX):
		draw_rect(Rect2(0, y, 1280, PX), gradient.sample(y / 130.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	stars.clear()
	for i in 40:
		var pos := Vector2(rng.randi_range(0, 426) * PX, rng.randi_range(0, 22) * PX)
		var bright := rng.randf_range(0.25, 0.9)
		stars.append([pos, bright])
		draw_rect(Rect2(pos, Vector2(PX, PX)), Color(1, 1, 0.9, bright))
	# La megalopoli all'orizzonte, dietro al villaggio.
	antenna_tops.clear()
	spire_tops.clear()
	rng.seed = 11
	var x := 0.0
	while x < 1280:
		var w := float(rng.randi_range(5, 12) * PX)
		var peak := 70.0 * exp(-pow((x - 900.0) / 180.0, 2)) + 40.0 * exp(-pow((x - 300.0) / 120.0, 2))
		var h := rng.randf_range(12, 40) + peak * rng.randf_range(0.6, 1.0)
		var top := 130.0 - h
		_px(x, top, w, h + 6, Color("14111f"))
		for wy in range(int(top) + 6, 128, 9):
			if rng.randf() < 0.15:
				_px(x + 3 + rng.randi_range(0, int(w / 9)) * 6, wy, PX, PX, Color("4aa8ff") if rng.randf() < 0.7 else Color("f2c96a"))
		if h > 70:
			_px(x + floorf(w / 6.0) * PX, top + 6, PX, h * 0.5, Color("3aa0ff"))
			antenna_tops.append(Vector2(x + floorf(w / 6.0) * PX, top - 9))
			_px(x + floorf(w / 6.0) * PX, top - 9, PX, 9, Color("14111f"))
			if h > 95:
				spire_tops.append(Vector2(x + w * 0.5, top - 9))
		x += w + rng.randi_range(0, 2) * PX
	# Nebbia sul bordo della collina.
	for i in 5:
		draw_rect(Rect2(0, 118 + i * 3, 1280, 3), Color(0.5, 0.4, 0.6, 0.08 + i * 0.03))


func _draw_grass() -> void:
	# Prato: più scuro verso il bosco in basso.
	for y in range(130, 720, PX):
		var t := (y - 130.0) / 590.0
		draw_rect(Rect2(0, y, 1280, PX), Color("2c4222").lerp(Color("18261a"), t))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 900:
		var p := Vector2(rng.randi_range(0, 426) * PX, rng.randi_range(44, 239) * PX)
		var c := Color("3a5a2a") if rng.randf() < 0.5 else Color("1a2a15")
		_px(p.x, p.y, PX, PX, c)
		if rng.randf() < 0.15:
			_px(p.x, p.y - PX, PX, PX, Color("4d6b34"))   # filo d'erba


func _draw_path(curve: Curve2D) -> void:
	var points := curve.get_baked_points()
	draw_polyline(points, Color("1b1418"), 46.0)
	draw_polyline(points, Color("4a3a28"), 40.0)
	draw_polyline(points, Color("5a4630"), 26.0)
	# Sassolini lungo il sentiero.
	var rng := RandomNumberGenerator.new()
	rng.seed = points.size()
	for i in range(0, points.size(), 5):
		var p: Vector2 = points[i] + Vector2(rng.randf_range(-16, 16), rng.randf_range(-12, 12))
		_px(p.x, p.y, PX, PX, Color("6a5640") if rng.randf() < 0.6 else Color("3a2c1e"))


func _draw_rocks() -> void:
	var k := Color("1b1418")
	for p in [Vector2(120, 420), Vector2(1150, 470), Vector2(560, 640), Vector2(720, 420), Vector2(250, 250), Vector2(1060, 260)]:
		_px(p.x - 15, p.y - 12, 30, 15, k)
		_px(p.x - 12, p.y - 9, 24, 9, Color("5a5f68"))
		_px(p.x - 9, p.y - 9, 12, 3, Color("7a8088"))


# Il bosco in basso e ai lati: chiome tonde in pixel, con dei varchi per i sentieri.
func _draw_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var trees := []
	for i in 70:
		var p := Vector2(rng.randf_range(-20, 1300), rng.randf_range(650, 760))
		if rng.randf() < 0.35:
			p = Vector2(rng.randf_range(-20, 90) if rng.randf() < 0.5 else rng.randf_range(1190, 1300), rng.randf_range(260, 700))
		var near_path := false
		for curve in curves:
			if curve.sample_baked(curve.get_closest_offset(p)).distance_to(p) < 55:
				near_path = true
		if not near_path:
			trees.append(p)
	trees.sort_custom(func(a, b): return a.y < b.y)
	for p in trees:
		_draw_tree(p, rng.randf_range(0.8, 1.3))


func _draw_tree(p: Vector2, s: float) -> void:
	var k := Color("1b1418")
	_px(p.x - 4, p.y - 18 * s, 9, 18 * s, k)
	_px(p.x - 2, p.y - 16 * s, 4, 16 * s, Color("3a2a1a"))
	var r := 22.0 * s
	for yy in range(int(-r), int(r), PX):
		for xx in range(int(-r), int(r), PX):
			var d := Vector2(xx, yy * 1.2).length()
			if d > r:
				continue
			var c := Color("1c3320")
			if d > r - 4:
				c = k
			elif xx + yy < -r * 0.4:
				c = Color("2a4a2c")
			_px(p.x + xx, p.y - 30 * s + yy, PX, PX, c)


func _draw_village() -> void:
	var k := Color("1b1418")
	# Recinzione del villaggio lungo il ciglio, con il cancello in mezzo.
	for x in range(30, 1250, 24):
		if absf(x - GATE.x) < 40:
			continue
		_px(x, 170, 6, 24, k)
		_px(x + 1, 172, 3, 21, Color("6b4a2a"))
	_px(30, 176, 1220, 6, k)
	_px(30, 177, 1220, 3, Color("8a6538"))
	# Il cancello.
	for px in [GATE.x - 36, GATE.x + 30]:
		_px(px - 3, 150, 12, 48, k)
		_px(px, 153, 6, 45, Color("6b4a2a"))
	_px(GATE.x - 51, 132, 102, 24, k)
	_px(GATE.x - 48, 135, 96, 18, Color("5a3d22"))
	draw_string(ThemeDB.fallback_font, Vector2(GATE.x - 48, 149), "Quietville", HORIZONTAL_ALIGNMENT_CENTER, 96, 12, Color("f0dcb0"))
	# Cascina in pietra.
	var f := FARMHOUSE
	_px(f.x - 48, f.y - 54, 96, 54, k)
	_px(f.x - 45, f.y - 51, 90, 51, Color("6e6358"))
	for row in 8:
		for col in 5:
			_px(f.x - 45 + (row % 2) * 9 + col * 18, f.y - 48 + row * 6, 12, 3, Color("7d7266") if (row + col) % 3 else Color("5f564c"))
	for i in 10:
		_px(f.x - 54 + i * 4, f.y - 57 - i * 3, 108 - i * 8, PX, Color("7e3326") if i % 2 else Color("6b2a20"))
	_px(f.x + 18, f.y - 96, 12, 24, k)
	_px(f.x + 21, f.y - 93, 6, 21, Color("5b5249"))
	for wx in [f.x - 33, f.x + 15]:
		_px(wx - 3, f.y - 42, 21, 18, k)
		_px(wx, f.y - 39, 15, 12, Color("ffcc55"))
	_px(f.x - 9, f.y - 27, 18, 27, k)
	_px(f.x - 6, f.y - 24, 12, 24, Color("4a3320"))


func _draw_signpost(pos: Vector2) -> void:
	var k := Color("1b1418")
	_px(pos.x - 3, pos.y - 45, 9, 45, k)
	_px(pos.x, pos.y - 42, 3, 42, Color("6b4a2a"))
	_px(pos.x - 39, pos.y - 51, 84, 21, k)
	_px(pos.x - 36, pos.y - 48, 78, 15, Color("7a5530"))
	draw_string(ThemeDB.fallback_font, Vector2(pos.x - 36, pos.y - 36), "‹ Città 30 km", HORIZONTAL_ALIGNMENT_CENTER, 78, 10, Color("f0dcb0"))


# Luce calda dalle finestre della cascina.
func get_lights() -> Array:
	return [
		[FARMHOUSE + Vector2(-26, -33), 45.0, Color(1.0, 0.7, 0.3, 0.35)],
		[FARMHOUSE + Vector2(22, -33), 45.0, Color(1.0, 0.7, 0.3, 0.35)],
	]
