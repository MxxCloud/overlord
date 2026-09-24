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


func _hit_fx(pos: Vector2) -> void:
	GameState.fx.straw(pos, 4)
	GameState.fx.sparks(pos, 3)   # la latta sfrigola


func _draw_defense() -> void:
	if not is_alive():
		# A terra: la croce spezzata e la paglia sparsa.
		Sprites.draw_image(self, "decor/cross", Vector2.ZERO, Color(0.6, 0.55, 0.5), Rect2(0, 9, 11, 5))
		block(Rect2(9, -6, 12, 3), Color("c9a86a"))
		return
	# Croce di legno (sprite) con giacca di latta, testa di paglia e cappello.
	Sprites.draw_image(self, "decor/cross", Vector2(0, 0))
	block(Rect2(-9, -30, 18, 15), Color("8a8f98"))            # giacca di latta
	draw_rect(Rect2(-9, -24, 18, 3), Color("6a6f78"))
	block(Rect2(-6, -45, 12, 12), Color("c9a86a"))            # testa di paglia
	draw_rect(Rect2(-3, -40, 3, 3), K)                        # occhi cuciti
	draw_rect(Rect2(3, -40, 3, 3), K)
	block(Rect2(-12, -48, 24, 3), Color("5a4020"))            # tesa del cappello
	block(Rect2(-6, -54, 12, 6), Color("5a4020"))
