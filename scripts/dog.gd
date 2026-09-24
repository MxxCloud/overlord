# Il cane (nome provvisorio: Bullone).
#
# Funziona come una piccola "macchina a stati": in ogni momento è in uno stato
# (segui, vai, morde, ferito) e si comporta di conseguenza.
#
# Abilità del prototipo (GDD §4.3):
# - Fiuto: sente i robot prima che entrino nello schermo e abbaia.
# - Vai!: clic destro su un punto vuoto. Corre lì e raccoglie i rottami.
# - Morso ai cavi: clic destro su un robot a terra. Lo raggiunge e lo stordisce
#   (un robot stordito subisce danni doppi).
extends Node2D

const Sprites := preload("res://scripts/sprites.gd")

@export var speed := 320.0
@export var max_hp := 4.0
@export var bite_stun := 2.5           # secondi di stordimento del morso
@export var bite_damage := 1.0
@export var command_cooldown := 4.0    # attesa tra un ordine e l'altro
@export var collect_radius := 70.0

var player                             # riferimento al protagonista (lo imposta main.gd)
var hp := 4.0
var state := "segui"
var cooldown := 0.0
var incoming := 0                      # robot fiutati ancora nel bosco (fuori schermo)
var incoming_x := 640.0                # da che parte arrivano (per l'HUD)
var facing := 1
var _target_pos := Vector2.ZERO
var _target_enemy = null
var _bark_label: Label
var _bark_time := 0.0
var _running := false
var _run_time := 0.0
var _lunge := 0.0          # scatto in avanti quando morde
var _dust_cd := 0.0


func _ready() -> void:
	add_to_group("dog")
	hp = max_hp
	_bark_label = GameState.make_label("", 14)
	_bark_label.position = Vector2(-30, -62)
	_bark_label.modulate = GameState.untint(Color.WHITE)   # leggibile anche di notte
	_bark_label.visible = false
	add_child(_bark_label)


func is_injured() -> bool:
	return state == "ferito"


func bark(text: String) -> void:
	_bark_label.text = text
	_bark_label.visible = true
	_bark_time = 1.2


func take_damage(amount: float) -> void:
	if is_injured():
		return
	hp -= amount
	if hp <= 0:
		# Regola d'oro del GDD: il cane non muore mai. Scappa ferito e per
		# questa notte non può più aiutare.
		state = "ferito"
		bark("Kaiii!")


# Chiamata col clic destro: decide se mordere un robot o andare in un punto.
func command(pos: Vector2) -> void:
	if is_injured() or cooldown > 0:
		return
	_target_enemy = null
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.flying and enemy.center().distance_to(pos) < 50:
			_target_enemy = enemy
			break
	if _target_enemy != null:
		state = "morde"
	else:
		state = "vai"
		var area: Rect2 = GameState.map.PLAY_AREA
		_target_pos = pos.clamp(area.position, area.end)
	cooldown = command_cooldown
	bark("WOOF!")


func _physics_process(delta: float) -> void:
	if GameState.finished:
		return
	cooldown = max(0.0, cooldown - delta)
	_lunge = max(0.0, _lunge - delta)
	_running = false
	_bark_time -= delta
	if _bark_time <= 0:
		_bark_label.visible = false

	if Input.is_action_just_pressed("cane"):
		command(get_global_mouse_position())

	_sniff()

	# `match` è come una serie di if: esegue il blocco dello stato attuale.
	match state:
		"segui":
			# Resta un po' dietro al protagonista.
			_move_to(player.position + Vector2(-40 * player.facing, 12), delta, speed * 0.8)
		"vai":
			if _move_to(_target_pos, delta, speed):
				_collect_scrap()
				state = "segui"
		"morde":
			# is_instance_valid controlla che il robot non sia già stato distrutto.
			if not is_instance_valid(_target_enemy) or _target_enemy.is_dying():
				state = "segui"
			elif _move_to(_target_enemy.position, delta, speed) or \
					_target_enemy.position.distance_to(position) < 20:
				_bite(_target_enemy)
				state = "segui"
		"ferito":
			_move_to(GameState.map.HOME + Vector2(-40, 0), delta, speed * 0.4)

	# Mentre corre raccoglie i rottami su cui passa.
	if not is_injured():
		for scrap in get_tree().get_nodes_in_group("scrap"):
			if scrap.position.distance_to(position) < 20:
				scrap.collect()
	queue_redraw()


func _bite(enemy) -> void:
	# Il Segugio è l'unico robot che il cane considera "suo": morso doppio.
	var dmg := bite_damage * (2.0 if enemy.kind == "segugio" else 1.0)
	enemy.stun(bite_stun)
	enemy.take_damage(dmg)
	# Morso ai cavi: scatto, scintille elettriche, piccolo scossone.
	_lunge = 0.15
	GameState.fx.electric(enemy.center(), 12)
	GameState.fx.flash(enemy.center(), 30.0, Color(0.5, 0.85, 1.0, 0.9), 0.1)
	GameState.shake(2.5)
	Audio.play("zap", -4.0)
	bark("GRRR!")


func _collect_scrap() -> void:
	for scrap in get_tree().get_nodes_in_group("scrap"):
		if scrap.position.distance_to(position) < collect_radius:
			scrap.collect()


# Fiuto: conta i robot ancora fuori dallo schermo e abbaia se ne arrivano.
func _sniff() -> void:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.position.y > GameState.SCREEN.y:
			count += 1
			incoming_x = enemy.position.x
	if count > 0 and incoming == 0 and not is_injured():
		bark("Woof! Woof!")
	incoming = count


# Muove il cane verso il punto `target`. Restituisce true quando è arrivato.
func _move_to(target: Vector2, delta: float, spd: float) -> bool:
	var diff := target - position
	if diff.length() < 6:
		return true
	if absf(diff.x) > 2:
		facing = 1 if diff.x > 0 else -1
	position += diff.limit_length(spd * delta)
	_running = true
	_run_time += delta
	# Polvere quando corre forte.
	_dust_cd -= delta
	if spd > 200.0 and _dust_cd <= 0:
		_dust_cd = 0.12
		GameState.fx.dust(position + Vector2(-facing * 12, 0), 1)
	return false


func _draw() -> void:
	draw_rect(Rect2(-15, -4, 30, 6), Color(0, 0, 0, 0.3))   # ombra
	# Il foglio del cane ha 2 fotogrammi affiancati (colonne), visto di lato
	# verso destra: lo specchiamo quando va a sinistra.
	var frame := 0
	if _running:
		frame = int(_run_time / 0.1) % 2
	var tint := Color(0.55, 0.55, 0.6) if is_injured() else Color.WHITE
	var offset := Vector2(facing * 8.0 * sin(_lunge / 0.15 * PI), 0)
	if is_injured():
		offset.y = 3.0 * absf(sin(_run_time * 6.0))   # zoppica
	Sprites.draw_frame(self, "characters/dog", frame, 0, false, offset, tint, facing < 0)
