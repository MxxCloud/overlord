# Libreria di sprite in pixel art, disegnati "a mano" con caratteri di testo.
#
# Ogni sprite è una lista di righe: ogni carattere è un pixel, e la tabella
# PALETTE dice di che colore è ("." = trasparente). All'avvio le righe vengono
# trasformate in texture (immagini) che gli script disegnano ingranditi di
# SCALE volte, con i pixel ben netti.
#
# Per modificare un personaggio basta cambiare i caratteri qui sotto.
# Sono sprite provvisori: più avanti verranno sostituiti da immagini PNG.
#
# Uso: const PixelArt := preload("res://scripts/pixel_art.gd")
#      var tex := PixelArt.texture("servitore_1")
extends RefCounted

const SCALE := 3  # ogni pixel dello sprite diventa un quadrato 3x3 sullo schermo

const PALETTE := {
	"k": Color("1b1418"),  # contorno scuro
	"h": Color("5a3a1f"),  # capelli castani
	"s": Color("e0b48a"),  # pelle
	"S": Color("b8875f"),  # pelle in ombra
	"r": Color("9a2c26"),  # camicia a quadri
	"R": Color("5e1814"),  # quadri scuri
	"b": Color("34507f"),  # jeans
	"B": Color("22365a"),  # jeans in ombra
	"o": Color("4a2e18"),  # stivali
	"K": Color("17171c"),  # pelo nero del cane
	"w": Color("eeeae0"),  # bianco (pelo, grembiule)
	"n": Color("c96a7a"),  # lingua
	"m": Color("707a88"),  # metallo chiaro
	"M": Color("454c58"),  # metallo scuro
	"E": Color("ff2a2a"),  # occhio rosso dei robot
	"y": Color("ffd040"),  # luce gialla
	"c": Color("a07850"),  # vestiti degli abitanti (sostituito per ognuno)
	"C": Color("6a4a30"),  # vestiti in ombra (sostituito per ognuno)
	"p": Color("3a3028"),  # pantaloni degli abitanti
	"g": Color("9aa0a8"),  # capelli grigi
	"e": Color("d8b070"),  # occhio del cane
}

# --- Protagonista (guarda a destra) -----------------------------------------
const _PLAYER_TOP := [
	"....kkkkk....",
	"...khhhhhk...",
	"..khhhhhhhk..",
	"..khhsssshk..",
	"..kssssksk...",
	"..ksssssssk..",
	"...kSsssSk...",
	"..kkkrrrkkk..",
	".krrRrrRrrRk.",
	".krRrrRrrRrk.",
	".krrRrrRrrRk.",
	".ksrRrrRrrsk.",
	".kkkkbbbbkkk.",
]
const _PLAYER_LEGS_IDLE := [
	"...kbbkbbk...",
	"...kbBkbBk...",
	"...kbbkbbk...",
	"...kbBkbBk...",
	"...kook.kok..",
	"..koook.kook.",
	"..kkkkk.kkkk.",
]
const _PLAYER_LEGS_WALK := [
	"...kbbkbbk...",
	"..kbBk.kbBk..",
	"..kbbk..kbbk.",
	".kbBk....kbBk",
	".kook....kook",
	"koook....kooo",
	"kkkkk....kkkk",
]

# --- Cane: border collie (guarda a destra) ----------------------------------
const _DOG_TOP := [
	"..........kk.kk....",
	".........kKKkKKk...",
	".........kKKKKKk...",
	"k........kKeKwKKk..",
	"Kk.......kKKKwKKKkk",
	".Kk.....kKKKKwwwwwk",
	".kKkkkkkKKKKKwwwkk.",
	"..kKKKKKKKKKwwwk...",
	"..kKKKKKKKKKKwk....",
	"..kkKKkkkkkKKkk....",
]
const _DOG_LEGS_1 := [
	"...kKk.....kKk.....",
	"...kKk.....kKk.....",
	"...kwk.....kwk.....",
	"...kkk.....kkk.....",
]
const _DOG_LEGS_2 := [
	"...kKk.....kKk.....",
	"..kKk.......kKk....",
	".kwk.........kwk...",
	".kkk.........kkk...",
]

# --- Servitore Domestico (guarda a sinistra) --------------------------------
const _SERV_TOP := [
	"...kkkkkk...",
	"..kmmmmmmk..",
	"..kEEmmmmk..",
	"..kmmmmmMk..",
	"...kkkkkk...",
	".....kk.....",
	"..kkmmmmkk..",
	".kmkwwwwkmk.",
	".kmkwwwwkmk.",
	".kMkwwwwkMk.",
	".kkkwwwwkkk.",
	"...kwwwwk...",
	"...kkkkkk...",
]
const _SERV_LEGS_1 := [
	"....kmkmk...",
	"....kmkmk...",
	"...kkk.kkk..",
]
const _SERV_LEGS_2 := [
	"...kmk.kmk..",
	"..kmk...kmk.",
	"..kkk...kkk.",
]

# --- Drone Sondaggio --------------------------------------------------------
const _DRONE_1 := [
	"kkkkk.....kkkkk",
	"...k.......k...",
	"..kkkkkkkkkkk..",
	".kmmmmmmmmmmMk.",
	".kEEmmmmmmmmMk.",
	"..kkkkkkkkkkk..",
]
const _DRONE_2 := [
	".kkk.......kkk.",
	"...k.......k...",
	"..kkkkkkkkkkk..",
	".kmmmmmmmmmmMk.",
	".kEEmmmmmmmmMk.",
	"..kkkkkkkkkkk..",
]

# --- Segugio (quadrupede, guarda a sinistra) --------------------------------
const _HOUND_1 := [
	".kkkk.............",
	"kmmmmk.........kk.",
	"kEEmmkkkkkkkkkkMk.",
	".kkmmmmmmmmmmmmMk.",
	"...kMmmmmmmmmmMk..",
	"...kkkkkkkkkkkkk..",
	"...kmk.kmk.kmk.kmk",
	"..kmk..kmk..kmkkmk",
	"..kk...kk....kk.kk",
]
const _HOUND_2 := [
	".kkkk.............",
	"kmmmmk.........kk.",
	"kEEmmkkkkkkkkkkMk.",
	".kkmmmmmmmmmmmmMk.",
	"...kMmmmmmmmmmMk..",
	"...kkkkkkkkkkkkk..",
	"....kmkkmk..kmkkmk",
	"....kmk.kmk.kmk.km",
	"....kk...kk.kk...k",
]

# --- Abitante (colori "c"/"C" e capelli "h" sostituiti per ognuno) ----------
const _VILLAGER_1 := [
	"..kkkk..",
	".khhhhk.",
	".khsssk.",
	".kskssk.",
	"..kSsk..",
	".kccCck.",
	"kcccCcck",
	"kscccCsk",
	".kccCck.",
	".kppppk.",
	".kpkkpk.",
	".kkk.kkk",
]
const _VILLAGER_2 := [
	"..kkkk..",
	".khhhhk.",
	".khsssk.",
	".kskssk.",
	"..kSsk..",
	".kccCck.",
	"kcccCcck",
	"kscccCsk",
	".kccCck.",
	".kppppk.",
	"kpk..kpk",
	"kkk..kkk",
]

const SPRITES := {
	"player_idle": [_PLAYER_TOP, _PLAYER_LEGS_IDLE],
	"player_walk": [_PLAYER_TOP, _PLAYER_LEGS_WALK],
	"dog_1": [_DOG_TOP, _DOG_LEGS_1],
	"dog_2": [_DOG_TOP, _DOG_LEGS_2],
	"servitore_1": [_SERV_TOP, _SERV_LEGS_1],
	"servitore_2": [_SERV_TOP, _SERV_LEGS_2],
	"drone_1": [_DRONE_1],
	"drone_2": [_DRONE_2],
	"segugio_1": [_HOUND_1],
	"segugio_2": [_HOUND_2],
	"villager_1": [_VILLAGER_1],
	"villager_2": [_VILLAGER_2],
}

# Le texture già create vengono conservate qui (una "cache"), così ogni
# sprite si costruisce una volta sola.
static var _cache := {}


# Restituisce la texture dello sprite `name`. `overrides` permette di
# cambiare alcuni colori della palette (es. i vestiti di un abitante).
static func texture(name: String, overrides: Dictionary = {}) -> Texture2D:
	var key := name + str(overrides)
	if not _cache.has(key):
		_cache[key] = _build(SPRITES[name], overrides)
	return _cache[key]


# Versione "tutta bianca" dello sprite: si usa per il lampo quando viene colpito.
static func flash_texture(name: String) -> Texture2D:
	var white := {}
	for ch in PALETTE:
		white[ch] = Color.WHITE
	return texture(name, white)


# Disegna lo sprite su `canvas` con i piedi nell'origine.
# flip = true lo specchia orizzontalmente.
static func draw(canvas: CanvasItem, tex: Texture2D, flip: bool = false, offset: Vector2 = Vector2.ZERO, modulate: Color = Color.WHITE) -> void:
	var size := Vector2(tex.get_width(), tex.get_height()) * SCALE
	var pos := Vector2(-size.x * 0.5, -size.y) + offset
	if flip:
		# Specchia: disegniamo con una scala orizzontale negativa.
		canvas.draw_set_transform(offset, 0.0, Vector2(-1, 1))
		canvas.draw_texture_rect(tex, Rect2(Vector2(-size.x * 0.5, -size.y), size), false, modulate)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		canvas.draw_texture_rect(tex, Rect2(pos, size), false, modulate)


# Posizione media (sullo schermo, rispetto ai piedi) dei pixel di un certo
# carattere. Serve per sapere dove sono, per esempio, gli occhi rossi ("E").
static func pixel_offset(name: String, ch: String) -> Vector2:
	var rows: Array = []
	for part in SPRITES[name]:
		rows.append_array(part)
	var width := 0
	for row in rows:
		width = max(width, row.length())
	var total := Vector2.ZERO
	var count := 0
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == ch:
				total += Vector2(x + 0.5, y + 0.5)
				count += 1
	if count == 0:
		return Vector2.ZERO
	var avg := total / count
	return Vector2(avg.x - width * 0.5, avg.y - rows.size()) * SCALE


# Dimensione in pixel sullo schermo di uno sprite.
static func screen_size(name: String) -> Vector2:
	var tex := texture(name)
	return Vector2(tex.get_width(), tex.get_height()) * SCALE


static func _build(parts: Array, overrides: Dictionary) -> Texture2D:
	return ImageTexture.create_from_image(build_image(parts, overrides))


# Trasforma le righe di testo in un'immagine (pixel per pixel).
static func build_image(parts: Array, overrides: Dictionary = {}) -> Image:
	var rows: Array = []
	for part in parts:
		rows.append_array(part)
	var width := 0
	for row in rows:
		width = max(width, row.length())
	var image := Image.create(width, rows.size(), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			var color: Color = overrides.get(ch, PALETTE.get(ch, Color.MAGENTA))
			image.set_pixel(x, y, color)
	return image
