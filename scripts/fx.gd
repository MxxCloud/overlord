# Effetti visivi: scintille, detriti, fumo, polvere, fuoco, lampi, bruciature.
#
# Un solo nodo gestisce TUTTE le particelle: ognuna è un piccolo Dictionary
# con posizione, velocità, colore e durata. Ogni frame le muoviamo e le
# ridisegniamo come quadratini, della stessa "grana" degli sprite in pixel art.
#
# Da qualsiasi script: GameState.fx.sparks(posizione), GameState.fx.explosion(...), ecc.
extends Node2D

const PX := 3.0            # lato di un "pixel" degli effetti
const MAX_PARTICLES := 700 # limite di sicurezza

var _particles: Array = []
var _flashes: Array = []   # lampi circolari (esplosioni, spari)
var _scorches: Array = []  # bruciature a terra che svaniscono lentamente
var _anims: Array = []     # animazioni a fotogrammi (esplosioni, nuvole di fumo)

# Animazioni disponibili: file, larghezza di un fotogramma, n. fotogrammi.
const ANIMS := {
	"explosion": ["res://assets/fx/explosion.png", 35, 7],
	"puff": ["res://assets/fx/smoke.png", 32, 6],
}


func _ready() -> void:
	z_index = 5              # sopra i personaggi
	add_to_group("lights")   # i lampi illuminano la scena (vedi lights.gd)


# --- Effetti pronti all'uso ---------------------------------------------------

# Scintille gialle: un colpo che va a segno sul metallo.
func sparks(pos: Vector2, count: int = 8, color: Color = Color("ffd060")) -> void:
	for i in count:
		var angle := randf_range(0.0, TAU)
		var speed := randf_range(120.0, 320.0)
		_spawn(pos, Vector2(cos(angle), sin(angle)) * speed, randf_range(0.12, 0.3), color, 1, 500.0, false)


# Scintille azzurre: cavi morsi dal cane, robot in corto circuito.
func electric(pos: Vector2, count: int = 6) -> void:
	sparks(pos, count, Color("7fd4ff"))


# Pezzi che volano via, cadono e rimbalzano a terra.
func debris(pos: Vector2, colors: Array, count: int = 10) -> void:
	for i in count:
		var vel := Vector2(randf_range(-200.0, 200.0), randf_range(-380.0, -120.0))
		_spawn(pos, vel, randf_range(1.0, 2.2), colors.pick_random(), randi_range(1, 2), 950.0, true)


# Schegge di legno (difese colpite).
func splinters(pos: Vector2, count: int = 5) -> void:
	debris(pos, [Color("8a6538"), Color("6b4a2a"), Color("b08a50")], count)


# Fumo grigio che sale e si allarga.
func smoke(pos: Vector2, count: int = 6) -> void:
	for i in count:
		var vel := Vector2(randf_range(-30.0, 30.0), randf_range(-70.0, -25.0))
		var color := Color(0.35, 0.33, 0.38, 0.55)
		_spawn(pos + Vector2(randf_range(-10, 10), 0), vel, randf_range(0.7, 1.4), color, randi_range(2, 3), -15.0, false, 1.5)


# Polvere a terra (passi, cadute, costruzioni).
func dust(pos: Vector2, count: int = 4) -> void:
	for i in count:
		var vel := Vector2(randf_range(-70.0, 70.0), randf_range(-50.0, -10.0))
		_spawn(pos, vel, randf_range(0.3, 0.6), Color(0.55, 0.47, 0.35, 0.7), randi_range(1, 2), 60.0, false, 3.0)


# Braci e fiammelle che salgono.
func fire(pos: Vector2, count: int = 3) -> void:
	var colors := [Color("ffd24a"), Color("ff8a2a"), Color("ff5020")]
	for i in count:
		var vel := Vector2(randf_range(-40.0, 40.0), randf_range(-160.0, -60.0))
		_spawn(pos + Vector2(randf_range(-30, 30), 0), vel, randf_range(0.3, 0.8), colors.pick_random(), 1, -80.0, false, 1.0)


# Paglia (lo spaventapasseri colpito).
func straw(pos: Vector2, count: int = 5) -> void:
	debris(pos, [Color("d8b860"), Color("c9a86a"), Color("a88840")], count)


# Lampo circolare che si espande e svanisce.
func flash(pos: Vector2, radius: float, color: Color, duration: float = 0.12) -> void:
	_flashes.append({"pos": pos, "radius": radius, "color": color, "life": duration, "max": duration})


# Bruciatura a terra.
func scorch(pos: Vector2) -> void:
	_scorches.append({"pos": pos, "life": 10.0})


# Esplosione completa di un robot.
func explosion(pos: Vector2, colors: Array) -> void:
	anim("explosion", pos, 0.45)
	flash(pos, 90.0, Color(1.0, 0.6, 0.2, 0.9), 0.15)
	sparks(pos, 12)
	debris(pos, colors, 10)
	smoke(pos, 4)


# Nuvoletta di polvere (costruzioni, cadute, crolli).
func puff(pos: Vector2) -> void:
	anim("puff", pos, 0.4)


# Avvia un'animazione a fotogrammi centrata in `pos`.
func anim(name: String, pos: Vector2, duration: float) -> void:
	var info: Array = ANIMS[name]
	_anims.append({"tex": load(info[0]), "w": info[1], "n": info[2], "pos": pos, "t": 0.0, "dur": duration})


# --- Motore delle particelle --------------------------------------------------

func _spawn(pos: Vector2, vel: Vector2, life: float, color: Color, size: int,
		gravity: float, bounce: bool, drag: float = 0.0) -> void:
	if _particles.size() >= MAX_PARTICLES:
		return
	# Il "pavimento" su cui rimbalzano i detriti: un po' sotto il punto di partenza
	# (nella vista dall'alto ogni cosa ha il suo terreno alla propria altezza).
	_particles.append({"pos": pos, "vel": vel, "life": life, "max": life, "color": color,
		"size": size, "gravity": gravity, "bounce": bounce, "drag": drag, "floor": pos.y + 24.0})


func _process(delta: float) -> void:
	for p in _particles:
		p["vel"].y += p["gravity"] * delta
		p["vel"] *= max(0.0, 1.0 - p["drag"] * delta)
		p["pos"] += p["vel"] * delta
		# Rimbalzo sul terreno.
		if p["bounce"] and p["pos"].y > p["floor"]:
			p["pos"].y = p["floor"]
			p["vel"].y *= -0.35
			p["vel"].x *= 0.6
		p["life"] -= delta
	_particles = _particles.filter(func(p): return p["life"] > 0)

	for f in _flashes:
		f["life"] -= delta
	_flashes = _flashes.filter(func(f): return f["life"] > 0)

	for s in _scorches:
		s["life"] -= delta
	_scorches = _scorches.filter(func(s): return s["life"] > 0)

	for a in _anims:
		a["t"] += delta
	_anims = _anims.filter(func(a): return a["t"] < a["dur"])
	queue_redraw()


# Luci per lights.gd: ogni lampo illumina i dintorni.
func get_lights() -> Array:
	var lights := []
	for f in _flashes:
		var t: float = f["life"] / f["max"]
		var c: Color = f["color"]
		lights.append([f["pos"], f["radius"] * 1.8, Color(c.r, c.g, c.b, c.a * t * 0.55)])
	return lights


func _draw() -> void:
	for s in _scorches:
		var alpha: float = clamp(s["life"] / 4.0, 0.0, 0.6)
		var pos: Vector2 = s["pos"]
		draw_rect(Rect2(pos.x - 36, pos.y - 3, 72, 6), Color(0.05, 0.04, 0.03, alpha))
		draw_rect(Rect2(pos.x - 24, pos.y - 6, 48, 3), Color(0.05, 0.04, 0.03, alpha * 0.7))

	for p in _particles:
		var color: Color = p["color"]
		# Negli ultimi istanti di vita la particella sfuma.
		var fade: float = clamp(p["life"] / (p["max"] * 0.3), 0.0, 1.0)
		color.a *= fade
		var size: float = p["size"] * PX
		# Allineiamo alla griglia di 3 pixel per restare "pixel art".
		var pos: Vector2 = (p["pos"] / PX).floor() * PX
		draw_rect(Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), color)

	# Animazioni a fotogrammi, ingrandite x3 come il resto della pixel art.
	for a in _anims:
		var tex: Texture2D = a["tex"]
		var w: int = a["w"]
		var frame := mini(int(a["t"] / a["dur"] * a["n"]), a["n"] - 1)
		var h := tex.get_height()
		var size := Vector2(w, h) * 3.0
		draw_texture_rect_region(tex, Rect2(a["pos"] - size * 0.5, size), Rect2(frame * w, 0, w, h))

	# Nucleo del lampo: piccolo e bianco-giallo, il bagliore lo fa lights.gd.
	for f in _flashes:
		var t: float = f["life"] / f["max"]
		var r: float = f["radius"] * 0.18 * (0.6 + t)
		draw_circle(f["pos"], r, Color(1.0, 0.95, 0.75, t))
