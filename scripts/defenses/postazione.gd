# Postazione: una piattaforma di legno rialzata. Da sola non fa nulla:
# serve un abitante che la presidi, e allora lancia molotov sui robot di terra.
# I robot di terra si fermano ad abbatterla. Se crolla, l'abitante resta ferito.
extends "res://scripts/defenses/defense.gd"

var height := 64.0
var villager = null      # abitante che la presidia (null = vuota)
var anti_air := false    # true = colpisce solo i volanti (la Fionda)


func _init() -> void:
	label_text = "Postazione"
	max_hp = 25.0
	width = 34.0


func blocks(enemy) -> bool:
	return is_alive() and not enemy.flying


func needs_villager() -> bool:
	return is_alive() and villager == null


func _draw_defense() -> void:
	var wood := Color("7a5530")
	if not is_alive():
		block(Rect2(-18, -9, 36, 9), Color("4a3420"))
		block(Rect2(-9, -15, 6, 6), Color("4a3420"))
		return
	# Traliccio di legno.
	block(Rect2(-18, -height, 6, height), wood)
	block(Rect2(12, -height, 6, height), wood)
	for y in [-height * 0.33, -height * 0.66]:
		draw_line(Vector2(-12, y + 15), Vector2(12, y), K, 6)
		draw_line(Vector2(-12, y + 15), Vector2(12, y), Color("8a6538"), 3)
	# Piattaforma e parapetto.
	block(Rect2(-24, -height - 3, 48, 6), Color("8a6538"))
	block(Rect2(-24, -height - 15, 3, 12), wood)
	block(Rect2(21, -height - 15, 3, 12), wood)
	_draw_equipment()
	if villager == null:
		draw_string(ThemeDB.fallback_font, Vector2(-40, -height - 24), "(vuota)", HORIZONTAL_ALIGNMENT_CENTER, 80, 11, GameState.untint(Color("ffaaaa")))


# Cosa c'è sulla piattaforma: qui la cassa di molotov (la Fionda lo cambia).
func _draw_equipment() -> void:
	block(Rect2(-18, -height - 12, 12, 9), Color("5a8a3a"))
