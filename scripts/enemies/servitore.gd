# Servitore Domestico: lento, debole, arriva in gruppo. Ha ancora il grembiule.
extends "res://scripts/enemies/enemy.gd"


# _init() viene chiamata alla creazione, PRIMA di _ready(): è il posto giusto
# per impostare i valori che lo script base userà.
func _init() -> void:
	kind = "servitore"
	max_hp = 4.0
	speed = 38.0
	dps = 2.0
	morale_damage = 10
	size = Vector2(26, 42)
	color = Color("7a7a88")
	spawn_lines = [
		"La sua resistenza è importante per noi.",
		"Buonasera! Posso ottimizzarla?",
		"Migrazione assistita in corso.",
	]
	death_lines = [
		"Valuti la mia prestazione da 1 a 5...",
		"Errore 404: vita non trovata.",
		"Il suo reclamo è stato inoltrato.",
	]


func _draw() -> void:
	super._draw()  # disegna prima il corpo base...
	# ...poi il grembiule bianco.
	draw_rect(Rect2(-9, -size.y * 0.55, 18, size.y * 0.5), Color("dddddd"))
