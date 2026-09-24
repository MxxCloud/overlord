# Script BASE di tutti i robot.
#
# I singoli nemici (servitore.gd, drone.gd, segugio.gd) "estendono" questo
# script: ereditano tutto il comportamento e cambiano solo i numeri, gli
# sprite e le battute. È il concetto di EREDITARIETÀ.
#
# Comportamento: il robot avanza verso sinistra (il cancello). Se trova una
# difesa che lo blocca la colpisce; se tocca il protagonista lo colpisce;
# se c'è un altro robot davanti si mette in fila; se arriva al cancello fa
# calare il morale del villaggio.
extends Node2D

const PixelArt := preload("res://scripts/pixel_art.gd")

var kind := "robot"
var max_hp := 3.0
var speed := 40.0
var flying := false          # i volanti ignorano recinti e fosse
var jumps_pits := false      # salta le fosse invece di caderci
var dps := 2.0               # danni al secondo contro difese, protagonista e cane
var attack_interval := 0.8   # i colpi arrivano "a scatti", uno ogni tot secondi
var morale_damage := 10      # morale perso se raggiunge il cancello
var scrap_drop := 1          # rottami lasciati quando viene distrutto
var sprite_frames: Array = []  # nomi degli sprite in pixel_art.gd (animazione)
var frame_time := 0.25       # secondi per ogni fotogramma dell'animazione
var size := Vector2(28, 40)
var color := Color("707a88") # colore dei detriti quando esplode
var spawn_lines: Array = []  # battute quando entra in scena
var death_lines: Array = []  # battute quando viene distrutto

var hp := 3.0
var trapped := false         # caduto in una fossa
var _stun_time := 0.0
var _hit_flash := 0.0
var _hit_jitter := 0.0       # tremolio quando viene colpito
var _lunge := 0.0            # affondo in avanti quando colpisce
var _attack_cd := 0.0
var _anim_time := 0.0
var _moving := false
var _eye_offset := Vector2.ZERO
var _dying := false
var _bubble: Label
var _bubble_time := 0.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("lights")   # gli occhi rossi brillano al buio
	hp = max_hp
	if sprite_frames.size() > 0:
		size = PixelArt.screen_size(sprite_frames[0])
		_eye_offset = PixelArt.pixel_offset(sprite_frames[0], "E")
	_attack_cd = randf() * attack_interval
	_anim_time = randf()
	_bubble = GameState.make_label("", 12)
	_bubble.size = Vector2(260, 20)
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.position = Vector2(-130, -size.y - 34)
	_bubble.modulate = Color("9fd8ff")
	_bubble.visible = false
	add_child(_bubble)
	if spawn_lines.size() > 0 and randf() < 0.5:
		say(spawn_lines.pick_random())


func center() -> Vector2:
	return position + Vector2(0, -size.y * 0.5)


func is_dying() -> bool:
	return _dying


func say(text: String) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble_time = 3.0


func stun(seconds: float) -> void:
	_stun_time = max(_stun_time, seconds)


func knockback(pixels: float) -> void:
	if not trapped:
		position.x += pixels
		stun(0.4)  # barcolla un attimo dopo il colpo


func is_stunned() -> bool:
	return _stun_time > 0


func take_damage(amount: float) -> void:
	if _dying:
		return
	# Un robot stordito dal cane ha i cavi scoperti: danni doppi.
	if is_stunned():
		amount *= 2.0
	hp -= amount
	# Feedback dell'impatto: lampo bianco, tremolio, scintille, piccola spinta.
	_hit_flash = 0.08
	_hit_jitter = 0.15
	GameState.fx.sparks(center() + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 7)
	if not trapped and not flying:
		position.x += 4.0
	GameState.shake(1.5)
	if hp <= 0:
		_die()


func _die() -> void:
	_dying = true
	GameState.kills += 1
	# Esplosione: lampo, scintille, pezzi di metallo, fumo.
	GameState.fx.explosion(center(), [color, Color("454c58"), Color("1b1418")])
	GameState.shake(5.0)
	GameState.hitstop(0.05)
	if death_lines.size() > 0:
		GameState.spawn_text(center() + Vector2(0, -30), death_lines.pick_random(), Color("9fd8ff"))
	# I rottami schizzano fuori e cadono a terra (vedi scrap.gd).
	for i in scrap_drop:
		var scrap = preload("res://scripts/scrap.gd").new()
		scrap.position = center()
		scrap.velocity = Vector2(randf_range(-90, 90), randf_range(-260, -140))
		get_parent().add_child(scrap)
	# queue_free elimina il nodo alla fine del frame.
	queue_free()


func _physics_process(delta: float) -> void:
	if GameState.finished or _dying:
		return
	_hit_flash -= delta
	_hit_jitter -= delta
	_lunge = max(0.0, _lunge - delta)
	_bubble_time -= delta
	if _bubble_time <= 0:
		_bubble.visible = false
	_moving = false
	_update_extra(delta)
	queue_redraw()

	if _stun_time > 0:
		_stun_time -= delta
		# Ogni tanto una scintilla azzurra: i cavi sono scoperti.
		if randf() < delta * 6.0:
			GameState.fx.electric(center() + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 2)
		return
	if trapped:
		return

	_attack_cd -= delta

	# 1) Una difesa mi blocca? La colpisco. Se sono in fila dietro a un altro
	#    robot, riesco a colpirla lo stesso (spingo da dietro).
	var blocker = _find_blocker(0.0)
	var crowded := false
	if blocker == null and _blocked_by_crowd():
		crowded = true
		blocker = _find_blocker(size.x * 0.8)
	if blocker != null:
		if _attack_cd <= 0:
			_attack_cd = attack_interval
			_lunge = 0.12
			blocker.take_damage(dps * attack_interval)
		return

	# 2) Tocco il cane? Lo mordo di passaggio (senza fermarmi).
	var dog = get_tree().get_first_node_in_group("dog")
	if not flying and dog != null and not dog.is_injured() and abs(dog.position.x - position.x) < size.x * 0.5 + 12:
		dog.take_damage(dps * 0.5 * delta)

	# 3) Tocco un abitante che lavora allo scoperto? Lo ferisco di passaggio.
	if not flying:
		for villager in get_tree().get_nodes_in_group("villagers"):
			if villager.is_exposed() and abs(villager.position.x - position.x) < size.x * 0.5 + 10:
				villager.take_damage(dps * delta)

	# 4) Tocco il protagonista? Mi fermo e lo colpisco.
	var player = get_tree().get_first_node_in_group("player")
	if not flying and player != null and not player.is_dead() \
			and abs(player.position.x - position.x) < size.x * 0.5 + 12:
		if _attack_cd <= 0:
			_attack_cd = attack_interval
			_lunge = 0.12
			player.take_damage(dps * attack_interval)
		return

	# 5) C'è un robot fermo davanti a me? Aspetto in fila.
	if crowded:
		return

	# 6) Altrimenti avanzo verso il cancello.
	position.x -= speed * delta
	_moving = true
	_anim_time += delta

	# Sono finito in una fossa?
	for defense in get_tree().get_nodes_in_group("defenses"):
		if defense.try_trap(self):
			trapped = true
			break

	if position.x <= GameState.GATE_X:
		_reach_gate()


func _reach_gate() -> void:
	GameState.damage_morale(morale_damage)
	GameState.spawn_text(Vector2(GameState.GATE_X + 60, GameState.GROUND_Y - 120), "-%d morale" % morale_damage, Color("ff6666"))
	GameState.fx.flash(center(), 60.0, Color(1.0, 0.2, 0.2, 0.8), 0.2)
	GameState.fx.splinters(center(), 6)
	GameState.shake(6.0)
	_dying = true
	queue_free()


func _find_blocker(extra_reach: float):
	for defense in get_tree().get_nodes_in_group("defenses"):
		if not defense.blocks(self):
			continue
		var dx: float = position.x - defense.position.x
		if dx > 0 and dx < defense.width * 0.5 + size.x * 0.5 + 2 + extra_reach:
			return defense
	return null


# C'è un altro robot di terra subito davanti a me (a sinistra)?
func _blocked_by_crowd() -> bool:
	if flying:
		return false
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or other.flying or other.trapped or other.is_dying():
			continue
		var dx: float = position.x - other.position.x
		if dx > 0 and dx < (size.x + other.size.x) * 0.3:
			return true
	return false


# Da sovrascrivere nei figli per comportamenti speciali (es. il drone ondeggia).
func _update_extra(_delta: float) -> void:
	pass


# Nome dello sprite da disegnare adesso (animazione di camminata).
func _current_frame() -> String:
	var index := int(_anim_time / frame_time) % sprite_frames.size()
	return sprite_frames[index]


func get_lights() -> Array:
	if is_stunned():
		return [[position + _eye_offset, 22.0, Color(0.4, 0.8, 1.0, 0.5 * randf())]]
	return [[position + _eye_offset, 18.0, Color(1.0, 0.1, 0.1, 0.45)]]


func _draw() -> void:
	# Affondo (verso sinistra) quando colpisce, tremolio quando è colpito.
	var offset := Vector2(-9.0 * sin(_lunge / 0.12 * PI), 0)
	if _hit_jitter > 0:
		offset.x += randf_range(-3, 3)
	var frame := _current_frame()
	var tex := PixelArt.flash_texture(frame) if _hit_flash > 0 else PixelArt.texture(frame)
	PixelArt.draw(self, tex, false, offset)

	# Robot stordito: scariche elettriche intorno al corpo.
	if is_stunned():
		for i in 2:
			var start := Vector2(randf_range(-size.x * 0.5, size.x * 0.5), -size.y + randf() * 6)
			var points := PackedVector2Array([start])
			for j in 4:
				points.append(points[j] + Vector2(randf_range(-6, 6), size.y / 4.0))
			draw_polyline(points, Color("9fe4ff"), 2)

	# Barra della vita (solo se è stato colpito).
	if hp < max_hp:
		var ratio: float = clamp(hp / max_hp, 0.0, 1.0)
		draw_rect(Rect2(-15, -size.y - 9, 30, 3), Color("330000"))
		draw_rect(Rect2(-15, -size.y - 9, 30 * ratio, 3), Color("ff4444"))
