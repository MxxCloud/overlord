# Recinto rinforzato: blocca i robot di terra finché non lo distruggono.
# I droni ci volano sopra.
extends "res://scripts/defenses/defense.gd"


func _init() -> void:
	label_text = "Recinto"
	max_hp = 30.0
	width = 30.0


func blocks(enemy) -> bool:
	return is_alive() and not enemy.flying


func _draw() -> void:
	var wood := Color("7a5530") if is_alive() else Color("3a2a18")
	var h := 60.0 if is_alive() else 15.0  # distrutto: resta solo un moncone
	for px in [-14, 0, 14]:
		draw_rect(Rect2(px - 3, -h, 6, h), wood)
	if is_alive():
		draw_rect(Rect2(-17, -45, 34, 5), wood)
		draw_rect(Rect2(-17, -22, 34, 5), wood)
	super._draw()
