# Rottame lasciato a terra da un robot distrutto.
# Lo raccolgono il protagonista (passandoci sopra) o il cane.
# I rottami servono a riparare le difese (tasto Q).
extends Node2D

@export var value := 1


func _ready() -> void:
	add_to_group("scrap")


func collect() -> void:
	# Il controllo evita di raccoglierlo due volte nello stesso frame.
	if is_queued_for_deletion():
		return
	GameState.add_scrap(value)
	GameState.spawn_text(position + Vector2(0, -20), "+%d rottame" % value, Color("dddddd"))
	queue_free()


func _draw() -> void:
	# Un piccolo ingranaggio.
	draw_circle(Vector2(0, -5), 5, Color("9a9aa5"))
	draw_circle(Vector2(0, -5), 2, Color("444450"))
