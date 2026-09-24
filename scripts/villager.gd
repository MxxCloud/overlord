# Abitante di Quietville.
#
# Gli abitanti sono le "braccia" del villaggio, come i sudditi di Kingdom:
# - costruiscono e riparano nei cantieri (li chiama build_slot.gd);
# - presidiano le postazioni e lanciano molotov sui robot.
# Se un robot li raggiunge mentre lavorano, restano feriti e tornano al
# villaggio: per questa notte non possono più aiutare.
extends Node2D

const MolotovScript := preload("res://scripts/molotov.gd")
const PixelArt := preload("res://scripts/pixel_art.gd")
const HAMMER_TIME := 0.35   # durata di un colpo di martello

@export var speed := 90.0
@export var max_hp := 3.0
@export var throw_interval := 2.5     # secondi tra una molotov e l'altra
@export var throw_range := 360.0

var nome := "Abitante"
var color := Color("a07850")
var hair := Color("5a3a1f")
# Stati: libero, va_cantiere, costruisce, va_postazione, postazione, ferito
var state := "libero"
var hp := 3.0
var home := Vector2(560, 196)         # dove aspetta quando è libero
var _elev := 0.0                      # altezza da terra (in cima a una postazione)
var slot = null                       # cantiere su cui lavora
var post = null                       # postazione che presidia
var _throw_cd := 0.0
var _anim := 0.0
var _walking := false
var _facing := 1
var _throw_anim := 0.0


func _ready() -> void:
	add_to_group("villagers")
	hp = max_hp
	_throw_cd = throw_interval


func is_free() -> bool:
	return state == "libero"


func is_injured() -> bool:
	return state == "ferito"


# Può essere colpito dai robot? (sulla postazione è al sicuro, in alto)
func is_exposed() -> bool:
	return state in ["va_cantiere", "costruisce", "va_postazione"]


func go_build(target_slot) -> void:
	slot = target_slot
	state = "va_cantiere"


func go_to_post(target_post) -> void:
	post = target_post
	post.villager = self
	post.queue_redraw()  # aggiorna la scritta "(vuota)"
	state = "va_postazione"
	GameState.spawn_text(center() + Vector2(0, -30), "%s: \"Vado io!\"" % nome, Color("ffe0a0"))


func release() -> void:
	slot = null
	state = "libero"


func center() -> Vector2:
	return position + Vector2(0, -20 - _elev)


func take_damage(amount: float) -> void:
	if not is_exposed():
		return
	hp -= amount
	if hp <= 0:
		_get_injured()


func _get_injured() -> void:
	state = "ferito"
	slot = null
	if post != null and is_instance_valid(post):
		post.villager = null
		post.queue_redraw()
	post = null
	_elev = 0.0
	GameState.spawn_text(center() + Vector2(0, -30), "%s è ferito!" % nome, Color("ff8888"))


func _physics_process(delta: float) -> void:
	if GameState.finished:
		return
	_anim += delta
	_walking = false
	_throw_anim -= delta
	match state:
		"libero":
			_move_to(home, delta, speed * 0.5)
		"va_cantiere":
			if _move_to(slot.position + Vector2(-24, 2), delta, speed):
				state = "costruisce"
		"costruisce":
			# Il cantiere avanza da solo finché l'abitante è qui.
			# A ogni colpo di martello: polvere e schegge.
			_facing = 1
			if fmod(_anim, HAMMER_TIME) < delta:
				GameState.fx.dust(position + Vector2(24, 0), 2)
				GameState.fx.splinters(position + Vector2(24, -12), 1)
		"va_postazione":
			if not is_instance_valid(post) or not post.is_alive():
				post = null
				state = "libero"
			elif _move_to(post.position + Vector2(0, 1), delta, speed):
				# Sale sulla piattaforma: lo disegniamo più in alto.
				state = "postazione"
				_elev = post.height
		"postazione":
			if not post.is_alive():
				# La postazione è crollata: l'abitante cade e resta ferito.
				_get_injured()
			else:
				_throw(delta)
		"ferito":
			_move_to(home, delta, speed * 0.4)
	queue_redraw()


func _throw(delta: float) -> void:
	_throw_cd -= delta
	if _throw_cd > 0:
		return
	# Cerca il robot di terra più vicino alla postazione.
	var target = null
	var best := throw_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.flying or enemy.is_dying():
			continue
		var dist: float = enemy.position.distance_to(position)
		if dist < best:
			best = dist
			target = enemy
	if target == null:
		return
	_throw_cd = throw_interval
	_throw_anim = 0.25
	_facing = 1 if target.position.x >= position.x else -1
	var molotov = MolotovScript.new()
	molotov.position = center()
	# Mira un po' più avanti lungo la direzione di marcia del robot.
	molotov.target = target.position + target._dir * target.speed * 0.4
	get_parent().add_child(molotov)


func _move_to(target: Vector2, delta: float, spd: float) -> bool:
	var diff := target - position
	if diff.length() < 4:
		return true
	position += diff.limit_length(spd * delta)
	_walking = true
	if absf(diff.x) > 1:
		_facing = 1 if diff.x > 0 else -1
	return false


func _draw() -> void:
	# Sprite in pixel art con i colori di questo abitante.
	var frame := "villager_1"
	if _walking and int(_anim / 0.15) % 2 == 1:
		frame = "villager_2"
	var colors := {"c": color, "C": color.darkened(0.35), "h": hair}
	var tint := Color(0.55, 0.55, 0.6) if is_injured() else Color.WHITE
	PixelArt.draw(self, PixelArt.texture(frame, colors), _facing < 0, Vector2(0, -_elev), tint)
	# Il resto (martello, braccio, nome) va disegnato alla stessa altezza.
	draw_set_transform(Vector2(0, -_elev), 0.0, Vector2.ONE)
	var k := Color("1b1418")
	if state == "costruisce":
		# Martello che batte.
		var up := fmod(_anim, HAMMER_TIME) < HAMMER_TIME * 0.5
		var tip := Vector2(18, -39) if up else Vector2(24, -15)
		draw_line(Vector2(6, -21), tip, k, 4)
		draw_line(Vector2(6, -21), tip, Color("8a6a40"), 2)
		draw_rect(Rect2(tip - Vector2(4, 4), Vector2(8, 8)), Color("6a6a70"))
	elif _throw_anim > 0:
		# Braccio alzato mentre lancia.
		draw_line(Vector2(3, -24), Vector2(12, -45), k, 4)
	# Il nome si vede solo quando sta facendo qualcosa (a casa si accavallerebbero).
	if state != "libero" or position.distance_to(home) > 10:
		draw_string(ThemeDB.fallback_font, Vector2(-44, -42), nome, HORIZONTAL_ALIGNMENT_CENTER, 88, 11, Color("f0e0c0"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
