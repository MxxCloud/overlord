# Abitante di Quietville.
#
# Gli abitanti sono le "braccia" del villaggio, come i sudditi di Kingdom:
# - costruiscono e riparano nei cantieri (li chiama build_slot.gd);
# - presidiano le postazioni e lanciano molotov sui robot.
# Se un robot li raggiunge mentre lavorano, restano feriti e tornano al
# villaggio: per questa notte non possono più aiutare.
extends Node2D

const MolotovScript := preload("res://scripts/molotov.gd")

@export var speed := 90.0
@export var max_hp := 3.0
@export var throw_interval := 2.5     # secondi tra una molotov e l'altra
@export var throw_range := 360.0

var nome := "Abitante"
var color := Color("a07850")
# Stati: libero, va_cantiere, costruisce, va_postazione, postazione, ferito
var state := "libero"
var hp := 3.0
var home_x := 60.0
var slot = null                       # cantiere su cui lavora
var post = null                       # postazione che presidia
var _throw_cd := 0.0
var _anim := 0.0


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
	return position + Vector2(0, -20)


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
	position.y = GameState.GROUND_Y
	GameState.spawn_text(center() + Vector2(0, -30), "%s è ferito!" % nome, Color("ff8888"))


func _physics_process(delta: float) -> void:
	if GameState.finished:
		return
	_anim += delta
	match state:
		"libero":
			_move_to(home_x, delta, speed * 0.5)
		"va_cantiere":
			if _move_to(slot.position.x - 24, delta, speed):
				state = "costruisce"
		"costruisce":
			pass  # il cantiere avanza da solo finché l'abitante è qui
		"va_postazione":
			if not is_instance_valid(post) or not post.is_alive():
				post = null
				state = "libero"
			elif _move_to(post.position.x, delta, speed):
				state = "postazione"
				position.y = GameState.GROUND_Y - post.height
		"postazione":
			if not post.is_alive():
				# La postazione è crollata: l'abitante cade e resta ferito.
				_get_injured()
			else:
				_throw(delta)
		"ferito":
			_move_to(home_x, delta, speed * 0.4)
	queue_redraw()


func _throw(delta: float) -> void:
	_throw_cd -= delta
	if _throw_cd > 0:
		return
	# Cerca il robot di terra più vicino davanti alla postazione.
	var target = null
	var best := throw_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.flying or enemy.is_dying():
			continue
		var dx: float = enemy.position.x - position.x
		if dx > -20 and dx < best:
			best = dx
			target = enemy
	if target == null:
		return
	_throw_cd = throw_interval
	var molotov = MolotovScript.new()
	molotov.position = center()
	molotov.target = Vector2(target.position.x - target.speed * 0.4, GameState.GROUND_Y)
	get_parent().add_child(molotov)


func _move_to(x: float, delta: float, spd: float) -> bool:
	var dx := x - position.x
	if abs(dx) < 4:
		return true
	position.x += sign(dx) * min(abs(dx), spd * delta)
	return false


func _draw() -> void:
	var body := Color("777777") if is_injured() else color
	draw_rect(Rect2(-7, -18, 14, 18), body)                       # corpo
	draw_rect(Rect2(-5, -30, 10, 11), Color("e0b48a"))            # testa
	if state == "costruisce":
		# Martello che batte.
		var up := sin(_anim * 12.0) > 0
		draw_line(Vector2(6, -14), Vector2(16, -24 if up else -10), Color("8a6a40"), 3)
	draw_string(ThemeDB.fallback_font, Vector2(-40, -36), nome, HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color("f0e0c0"))
