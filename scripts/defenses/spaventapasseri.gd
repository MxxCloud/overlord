# Spaventapasseri di latta: i sensori dei robot lo scambiano per un umano.
# Tutti i robot, anche i droni, si fermano ad attaccarlo finché non cade.
# Poca vita: serve a guadagnare tempo e a raggruppare i nemici per la doppietta.
extends "res://scripts/defenses/defense.gd"


func _init() -> void:
	label_text = "Spaventapasseri"
	max_hp = 20.0
	width = 24.0


func blocks(_enemy) -> bool:
	return is_alive()


func _draw() -> void:
	if is_alive():
		draw_rect(Rect2(-2, -70, 4, 70), Color("7a5530"))          # palo
		draw_rect(Rect2(-22, -55, 44, 4), Color("7a5530"))         # braccia
		draw_rect(Rect2(-10, -58, 20, 26), Color("8a8f98"))        # corpo di latta
		draw_circle(Vector2(0, -68), 8, Color("c9a86a"))           # testa di paglia
		draw_rect(Rect2(-11, -80, 22, 5), Color("5a4020"))         # cappello
	else:
		draw_rect(Rect2(-12, -6, 24, 6), Color("5a5f68"))          # rottami a terra
	super._draw()
