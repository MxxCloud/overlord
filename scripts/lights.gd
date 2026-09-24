# Luci della notte: aloni luminosi disegnati "in aggiunta" (blend ADD) sopra
# la scena, così le zone illuminate si schiariscono.
#
# Qualsiasi nodo può fare luce: basta che sia nel gruppo "lights" e che abbia
# una funzione get_lights() che restituisce una lista di luci, ognuna così:
#   [posizione, raggio, colore]      (l'alfa del colore = intensità)
# Esempi: occhi dei robot, finestre della cascina, molotov, spari.
extends Node2D

var _glow: Texture2D


func _ready() -> void:
	z_index = 50  # sopra a tutto il mondo di gioco (l'HUD è su un livello a parte)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # alone morbido
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

	# Texture circolare: bianca al centro, trasparente ai bordi.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.35, Color(1, 1, 1, 0.45))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	_glow = tex


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for source in get_tree().get_nodes_in_group("lights"):
		for light in source.get_lights():
			var pos: Vector2 = light[0]
			var radius: float = light[1]
			draw_texture_rect(_glow, Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, light[2])
