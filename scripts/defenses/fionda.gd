# Fionda: una torretta come la postazione, ma in cima c'è una grande fionda.
# L'abitante che la presidia tira sassi SOLO ai robot volanti (i droni),
# che le molotov non riescono a raggiungere.
extends "res://scripts/defenses/postazione.gd"


func _init() -> void:
	label_text = "Fionda"
	max_hp = 20.0
	width = 34.0
	height = 54.0
	anti_air = true


func _draw_equipment() -> void:
	var wood := Color("8a6538")
	var top := -height - 3
	# Forcella a Y con l'elastico.
	block(Rect2(6, top - 18, 4, 18), wood)
	draw_line(Vector2(8, top - 16), Vector2(0, top - 30), K, 6)
	draw_line(Vector2(8, top - 16), Vector2(16, top - 30), K, 6)
	draw_line(Vector2(8, top - 16), Vector2(0, top - 30), wood, 3)
	draw_line(Vector2(8, top - 16), Vector2(16, top - 30), wood, 3)
	draw_line(Vector2(0, top - 29), Vector2(16, top - 29), Color("c8b090"), 1)
	# Mucchietto di sassi.
	for p in [Vector2(-18, top - 6), Vector2(-12, top - 6), Vector2(-15, top - 10)]:
		block(Rect2(p, Vector2(4, 4)), Color("8a8f98"))
