# Il protagonista: il "comandante della collina".
#
# Non è una macchina da guerra: il suo lavoro è camminare lungo la collina,
# costruire difese, assegnare gli abitanti e raccogliere rottami (lo fanno
# i cantieri, vedi build_slot.gd). La doppietta ha poche cartucce per notte
# ed è l'ultima risorsa per le emergenze.
#
# L'origine del nodo (position) corrisponde ai PIEDI del personaggio.
extends Node2D

const PixelArt := preload("res://scripts/pixel_art.gd")

# @export rende la variabile modificabile dall'editor (pannello Ispettore).
@export var speed := 170.0
@export var max_hp := 6.0
@export var max_shells := 6             # cartucce per TUTTA la notte
@export var shotgun_range := 320.0      # portata in pixel
@export var shotgun_spread_deg := 12.0  # apertura del cono di pallini
@export var shotgun_damage := 4.0       # a bruciapelo; da lontano cala molto
@export var shot_cooldown := 1.2        # la doppietta è lenta da riarmare
@export var pickup_radius := 30.0

var hp := 6.0
var shells := 6
var facing := 1           # 1 = guarda a destra, -1 = a sinistra
var _shot_cd := 0.0
var _flash_time := 0.0
var _hurt_time := 0.0
var _aim := Vector2.RIGHT
var _walk_time := 0.0
var _step_cd := 0.0
var _pellets: Array = []  # punti d'arrivo dei pallini, per disegnarli un istante


func _ready() -> void:
	# I GRUPPI sono etichette: altri script trovano il giocatore con
	# get_tree().get_first_node_in_group("player").
	add_to_group("player")
	add_to_group("lights")   # la fiammata dello sparo illumina la scena
	hp = max_hp
	shells = max_shells


func is_dead() -> bool:
	return hp <= 0


# Punto "centrale" del corpo, usato per mirare.
func center() -> Vector2:
	return position + Vector2(0, -30)


func take_damage(amount: float) -> void:
	if is_dead():
		return
	hp -= amount
	_hurt_time = 0.15
	# Urto: spinta all'indietro, scossone e schermo che lampeggia di rosso (HUD).
	position.x = max(20.0, position.x - 10.0)
	GameState.shake(4.0)
	GameState.player_hurt.emit()
	if hp <= 0:
		GameState.end_game(false)


# _physics_process viene chiamata 60 volte al secondo. `delta` è il tempo
# passato dall'ultima chiamata: moltiplicare per delta rende il movimento
# indipendente dagli FPS.
func _physics_process(delta: float) -> void:
	if GameState.finished:
		return

	var dir := Input.get_axis("sinistra", "destra")
	position.x = clamp(position.x + dir * speed * delta, 20.0, GameState.SCREEN_W - 20)
	if dir != 0:
		facing = 1 if dir > 0 else -1
		_walk_time += delta
		# Sbuffi di polvere ai passi.
		_step_cd -= delta
		if _step_cd <= 0:
			_step_cd = 0.3
			GameState.fx.dust(position + Vector2(-facing * 6, 0), 2)
	else:
		_walk_time = 0.0

	var mouse := get_global_mouse_position()
	_aim = (mouse - center()).normalized()

	_shot_cd -= delta
	if Input.is_action_just_pressed("spara"):
		_shoot()

	_pick_up_scrap()

	_flash_time -= delta
	_hurt_time -= delta
	queue_redraw()  # chiede a Godot di richiamare _draw()


func _shoot() -> void:
	if shells <= 0:
		GameState.spawn_text(center() + Vector2(0, -40), "Niente cartucce!", Color("ffaaaa"))
		return
	if _shot_cd > 0:
		return
	shells -= 1
	_shot_cd = shot_cooldown
	_flash_time = 0.1
	facing = 1 if _aim.x >= 0 else -1
	var origin := center()
	var muzzle := origin + _aim * 34.0
	# Feedback dello sparo: rinculo, scossone, fiammata, fumo, bossolo, pallini.
	position.x = clamp(position.x - _aim.x * 10.0, 20.0, GameState.SCREEN_W - 20)
	GameState.shake(6.0)
	GameState.fx.flash(muzzle, 40.0, Color(1.0, 0.85, 0.4, 1.0), 0.08)
	GameState.fx.smoke(muzzle, 4)
	GameState.fx.debris(origin, [Color("c9a050")], 1)
	_pellets.clear()
	for i in 6:
		var spread := deg_to_rad(randf_range(-shotgun_spread_deg, shotgun_spread_deg))
		_pellets.append(_aim.rotated(spread) * randf_range(0.6, 1.0) * shotgun_range)
	# I pallini si fermano sul PRIMO robot che incontrano: cerchiamo il più
	# vicino dentro il "cono" davanti alla canna.
	var best = null
	var best_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var to_enemy: Vector2 = enemy.center() - origin
		var dist := to_enemy.length()
		if dist > shotgun_range:
			continue
		# Tolleranza extra per i bersagli grandi o molto vicini.
		var extra := rad_to_deg(atan2(enemy.size.y * 0.5, max(dist, 1.0)))
		if abs(rad_to_deg(_aim.angle_to(to_enemy))) > shotgun_spread_deg + extra:
			continue
		if dist < best_dist:
			best = enemy
			best_dist = dist
	if best != null:
		var falloff := 1.0 - (best_dist / shotgun_range) * 0.7
		best.take_damage(shotgun_damage * falloff)
		best.knockback(12.0 * falloff)
		# I pallini si fermano sul robot colpito.
		for i in _pellets.size():
			_pellets[i] = _pellets[i].limit_length(best_dist)


func _pick_up_scrap() -> void:
	for scrap in get_tree().get_nodes_in_group("scrap"):
		if scrap.position.distance_to(position) < pickup_radius:
			scrap.collect()


func get_lights() -> Array:
	if _flash_time > 0:
		return [[center() + _aim * 34.0, 140.0, Color(1.0, 0.8, 0.4, 0.45)]]
	return []


func _draw() -> void:
	# Sprite in pixel art: camminata a due fotogrammi, specchiato se va a sinistra.
	var frame := "player_idle"
	if _walk_time > 0 and int(_walk_time / 0.15) % 2 == 0:
		frame = "player_walk"
	var tex := PixelArt.flash_texture(frame) if _hurt_time > 0 else PixelArt.texture(frame)
	PixelArt.draw(self, tex, facing < 0)

	# Doppietta: puntata verso il mouse quando spara, altrimenti a tracolla.
	var gun_start := Vector2(0, -30)
	if _flash_time > 0:
		draw_line(gun_start, gun_start + _aim * 34, Color("1b1418"), 6)
		draw_line(gun_start, gun_start + _aim * 34, Color("6b4a2a"), 3)
		# Pallini: linee sottili che partono dalla canna.
		var muzzle := gun_start + _aim * 34
		for p in _pellets:
			draw_line(muzzle, gun_start + p, Color(1.0, 0.9, 0.5, _flash_time * 8.0), 1)
		draw_circle(muzzle, 6, Color("fff0a0"))
	else:
		draw_line(Vector2(-facing * 9, -48), Vector2(facing * 9, -21), Color("1b1418"), 5)
		draw_line(Vector2(-facing * 9, -48), Vector2(facing * 9, -21), Color("6b4a2a"), 3)
