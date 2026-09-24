# Aiuti per disegnare gli sprite in pixel art presi dai pacchetti CC0
# (vedi assets/CREDITS.md e tools/import_assets.py).
#
# I "fogli" dei personaggi sono griglie di fotogrammi 16x16:
#   - colonne = direzione (0 giù, 1 su, 2 sinistra, 3 destra)
#   - righe   = fotogrammi dell'animazione di camminata
# Tutto viene disegnato ingrandito SCALE volte, con i pixel ben netti.
#
# Uso: const Sprites := preload("res://scripts/sprites.gd")
#      Sprites.draw_frame(self, "characters/player", Sprites.dir_index(direzione), fotogramma)
extends RefCounted

const SCALE := 3.0
const CELL := 16

# Le texture già caricate (una "cache": ogni file si carica una volta sola).
static var _cache := {}

# I personaggi sono un po' più "illuminati" del terreno (trucco classico per
# farli risaltare di notte): dopo la tinta notturna risultano di questo colore.
const CHARACTER_LIGHT := Color(0.8, 0.8, 0.9)


# Modulazione da usare per i personaggi, che compensa in parte la tinta notturna.
static func character_modulate() -> Color:
	var night: Color = GameState.NIGHT
	return Color(CHARACTER_LIGHT.r / night.r, CHARACTER_LIGHT.g / night.g, CHARACTER_LIGHT.b / night.b)


static func tex(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = load("res://assets/%s.png" % path)
	return _cache[path]


# Colonna del foglio corrispondente a una direzione di movimento.
static func dir_index(dir: Vector2) -> int:
	if absf(dir.x) > absf(dir.y):
		return 3 if dir.x > 0 else 2
	return 0 if dir.y >= 0 else 1


# Quanti fotogrammi (righe) ha un foglio.
static func frame_count(path: String) -> int:
	return int(tex(path).get_height() / CELL)


# Disegna un fotogramma del foglio con i piedi nell'origine del nodo.
# flash = true usa la versione tutta bianca (lampo quando è colpito).
static func draw_frame(canvas: CanvasItem, path: String, col: int, row: int, flash: bool = false,
		offset: Vector2 = Vector2.ZERO, modulate: Color = Color.WHITE, flip: bool = false) -> void:
	var texture := tex(path + "_flash" if flash else path)
	modulate *= character_modulate()
	var region := Rect2(col * CELL, row * CELL, CELL, CELL)
	var size := Vector2(CELL, CELL) * SCALE
	if flip:
		canvas.draw_set_transform(offset, 0.0, Vector2(-1, 1))
		canvas.draw_texture_rect_region(texture, Rect2(Vector2(-size.x * 0.5, -size.y), size), region, modulate)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		canvas.draw_texture_rect_region(texture, Rect2(offset + Vector2(-size.x * 0.5, -size.y), size), region, modulate)


# Disegna un'immagine intera (es. una decorazione) con la base nell'origine.
static func draw_image(canvas: CanvasItem, path: String, offset: Vector2 = Vector2.ZERO,
		modulate: Color = Color.WHITE, region: Rect2 = Rect2()) -> void:
	var texture := tex(path)
	if region.size == Vector2.ZERO:
		region = Rect2(Vector2.ZERO, texture.get_size())
	var size := region.size * SCALE
	canvas.draw_texture_rect_region(texture, Rect2(offset + Vector2(-size.x * 0.5, -size.y), size), region, modulate)


# Crea un nodo Sprite2D già pronto (base nell'origine, ingrandito, pixel netti).
# Si usa per le decorazioni che devono stare "in profondità" con i personaggi
# (alberi, case...): Godot le ordina automaticamente in base alla y.
static func make_prop(path: String, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex(path)
	sprite.centered = false
	sprite.offset = Vector2(-sprite.texture.get_width() * 0.5, -sprite.texture.get_height())
	sprite.scale = Vector2(SCALE, SCALE)
	sprite.position = pos
	return sprite
