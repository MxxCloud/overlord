# Strumento: salva un'anteprima ingrandita di tutti gli sprite in un PNG.
# Uso: godot --headless -s res://tools/sprite_preview.gd -- percorso/anteprima.png
extends SceneTree

const PixelArt := preload("res://scripts/pixel_art.gd")
const ZOOM := 8


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://sprite_preview.png"
	var names: Array = PixelArt.SPRITES.keys()
	var cell := 24 * ZOOM
	var cols := 4
	var rows := int(ceil(names.size() / float(cols)))
	var sheet := Image.create(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3a4a3a"))
	for i in names.size():
		var img: Image = PixelArt.build_image(PixelArt.SPRITES[names[i]])
		img.resize(img.get_width() * ZOOM, img.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
		var pos := Vector2i((i % cols) * cell + 8, (i / cols) * cell + 8)
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), pos)
	sheet.save_png(out)
	print("Anteprima salvata in ", out)
	quit()
