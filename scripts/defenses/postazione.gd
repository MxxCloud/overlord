# Postazione: una piattaforma di legno rialzata. Da sola non fa nulla:
# serve un abitante che la presidi, e allora lancia molotov sui robot di terra.
# I robot di terra si fermano ad abbatterla. Se crolla, l'abitante resta ferito.
extends "res://scripts/defenses/defense.gd"

var height := 64.0
var villager = null      # abitante che la presidia (null = vuota)


func _init() -> void:
	label_text = "Postazione"
	max_hp = 25.0
	width = 34.0


func blocks(enemy) -> bool:
	return is_alive() and not enemy.flying


func needs_villager() -> bool:
	return is_alive() and villager == null


func _draw() -> void:
	var wood := Color("7a5530") if is_alive() else Color("3a2a18")
	if is_alive():
		draw_rect(Rect2(-16, -height, 4, height), wood)
		draw_rect(Rect2(12, -height, 4, height), wood)
		draw_line(Vector2(-14, -height), Vector2(14, 0), wood, 2)
		draw_line(Vector2(14, -height), Vector2(-14, 0), wood, 2)
		draw_rect(Rect2(-20, -height - 4, 40, 6), Color("8a6538"))
		if villager == null:
			draw_string(ThemeDB.fallback_font, Vector2(-40, -height - 12), "(vuota)", HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color("ffaaaa"))
	else:
		draw_rect(Rect2(-18, -8, 36, 8), wood)
	super._draw()
