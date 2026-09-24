# Script BASE delle difese. Le difese concrete (recinto, fossa,
# spaventapasseri, postazione) lo estendono e cambiano i valori, i metodi
# `blocks` / `try_trap` e il disegno (`_draw_defense`).
extends Node2D

const K := Color("1b1418")   # colore del contorno, come negli sprite
const Sprites := preload("res://scripts/sprites.gd")

var label_text := "Difesa"
var max_hp := 20.0
var width := 40.0            # ingombro orizzontale in pixel
var hp := 20.0
var _jitter := 0.0           # tremolio quando viene colpita
var path_progress := {}      # {sentiero: progresso} se sta su un sentiero (vedi map.paths_near)


func _ready() -> void:
	add_to_group("defenses")
	hp = max_hp
	path_progress = GameState.map.paths_near(position)
	# Appena costruita: sbuffo di polvere.
	GameState.fx.dust(position, 8)
	GameState.fx.puff(position + Vector2(0, -20))
	GameState.shake(2.0)


func is_alive() -> bool:
	return hp > 0


func needs_repair() -> bool:
	return hp < max_hp


func repair() -> void:
	hp = max_hp
	GameState.fx.dust(position, 6)
	queue_redraw()


func take_damage(amount: float) -> void:
	if not is_alive():
		return
	hp = max(0.0, hp - amount)
	_jitter = 0.15
	_hit_fx(position + Vector2(randf_range(-width * 0.5, width * 0.5), -randf_range(15, 45)))
	if hp <= 0:
		_on_destroyed()
	queue_redraw()


# Effetto quando viene colpita (schegge di legno; lo spaventapasseri perde paglia).
func _hit_fx(pos: Vector2) -> void:
	GameState.fx.splinters(pos, 3)


# Effetto quando crolla: esplosione di detriti e polvere.
func _on_destroyed() -> void:
	for i in 4:
		_hit_fx(position + Vector2(randf_range(-width * 0.5, width * 0.5), -randf_range(10, 50)))
	GameState.fx.dust(position, 10)
	GameState.fx.puff(position + Vector2(0, -24))
	GameState.shake(6.0)
	GameState.spawn_text(position + Vector2(0, -80), "%s distrutto!" % label_text, Color("ff9966"))


# Restituisce true se questa difesa ferma il robot `enemy`.
func blocks(_enemy) -> bool:
	return false


# Restituisce true se questa difesa intrappola il robot (solo la fossa).
func try_trap(_enemy) -> bool:
	return false


func _process(delta: float) -> void:
	if _jitter > 0:
		_jitter -= delta
		queue_redraw()


# Rettangolo con contorno scuro di 3 pixel, nello stile degli sprite.
func block(rect: Rect2, fill: Color) -> void:
	draw_rect(rect.grow(3), K)
	draw_rect(rect, fill)


# Da sovrascrivere: disegna la difesa (con i piedi nell'origine).
func _draw_defense() -> void:
	pass


func _draw() -> void:
	var shake := Vector2(randf_range(-3, 3), 0) if _jitter > 0 else Vector2.ZERO
	draw_set_transform(shake, 0.0, Vector2.ONE)
	_draw_defense()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Nome e barra dello stato sotto la difesa.
	var ratio := hp / max_hp
	draw_rect(Rect2(-21, 9, 42, 6), K)
	draw_rect(Rect2(-18, 10.5, 36 * ratio, 3), Color("ffaa33"))
	draw_string(ThemeDB.fallback_font, Vector2(-60, 32), label_text, HORIZONTAL_ALIGNMENT_CENTER, 120, 11, GameState.untint(Color("f0e0c0")))
