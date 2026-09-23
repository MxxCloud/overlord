# Script BASE di tutti i robot.
#
# I singoli nemici (servitore.gd, drone.gd, segugio.gd) "estendono" questo
# script: ereditano tutto il comportamento e cambiano solo i numeri e le battute.
# È il concetto di EREDITARIETÀ.
#
# Comportamento: il robot avanza verso sinistra (il cancello). Se trova una
# difesa che lo blocca la attacca; se tocca il protagonista lo attacca;
# se arriva al cancello fa calare il morale del villaggio.
extends Node2D

var kind := "robot"
var max_hp := 3.0
var speed := 40.0
var flying := false          # i volanti ignorano recinti e fosse
var jumps_pits := false      # salta le fosse invece di caderci
var dps := 2.0               # danni al secondo contro difese, protagonista e cane
var morale_damage := 10      # morale perso se raggiunge il cancello
var scrap_drop := 1          # rottami lasciati quando viene distrutto
var size := Vector2(28, 40)
var color := Color("6a6a78")
var eye_color := Color("ff2a2a")
var spawn_lines: Array = []  # battute quando entra in scena
var death_lines: Array = []  # battute quando viene distrutto

var hp := 3.0
var trapped := false         # caduto in una fossa
var _stun_time := 0.0
var _hit_flash := 0.0
var _dying := false
var _bubble: Label
var _bubble_time := 0.0


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	_bubble = GameState.make_label("", 12)
	_bubble.size = Vector2(260, 20)
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.position = Vector2(-130, -size.y - 30)
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


func take_damage(amount: float) -> void:
	if _dying:
		return
	hp -= amount
	_hit_flash = 0.08
	if hp <= 0:
		_die()


func _die() -> void:
	_dying = true
	GameState.kills += 1
	if death_lines.size() > 0:
		GameState.spawn_text(center() + Vector2(0, -30), death_lines.pick_random(), Color("9fd8ff"))
	# Lascia a terra dei rottami (vedi scrap.gd).
	for i in scrap_drop:
		var scrap = preload("res://scripts/scrap.gd").new()
		scrap.position = Vector2(position.x + randf_range(-12, 12), GameState.GROUND_Y)
		get_parent().add_child(scrap)
	# queue_free elimina il nodo alla fine del frame.
	queue_free()


func _physics_process(delta: float) -> void:
	if GameState.finished or _dying:
		return
	_hit_flash -= delta
	_bubble_time -= delta
	if _bubble_time <= 0:
		_bubble.visible = false
	_update_extra(delta)
	queue_redraw()

	if _stun_time > 0:
		_stun_time -= delta
		return
	if trapped:
		return

	# 1) Una difesa mi blocca? La attacco.
	var blocker = _find_blocker()
	if blocker != null:
		blocker.take_damage(dps * delta)
		return

	# 2) Tocco il cane? Lo mordo di passaggio (senza fermarmi).
	var dog = get_tree().get_first_node_in_group("dog")
	if not flying and dog != null and not dog.is_injured() and abs(dog.position.x - position.x) < size.x * 0.5 + 12:
		dog.take_damage(dps * 0.5 * delta)

	# 3) Tocco il protagonista (e non sta saltando sopra di me)? Mi fermo e attacco.
	var player = get_tree().get_first_node_in_group("player")
	if not flying and player != null and abs(player.position.x - position.x) < size.x * 0.5 + 12 \
			and player.position.y > GameState.GROUND_Y - size.y:
		player.take_damage(dps * delta)
		return

	# 4) Altrimenti avanzo verso il cancello.
	position.x -= speed * delta

	# Sono finito in una fossa?
	for defense in get_tree().get_nodes_in_group("defenses"):
		if defense.try_trap(self):
			trapped = true
			break

	if position.x <= GameState.GATE_X:
		GameState.damage_morale(morale_damage)
		GameState.spawn_text(Vector2(GameState.GATE_X + 60, GameState.GROUND_Y - 120), "-%d morale" % morale_damage, Color("ff6666"))
		_dying = true
		queue_free()


func _find_blocker():
	for defense in get_tree().get_nodes_in_group("defenses"):
		if not defense.blocks(self):
			continue
		var dx: float = position.x - defense.position.x
		if dx > 0 and dx < defense.width * 0.5 + size.x * 0.5 + 2:
			return defense
	return null


# Da sovrascrivere nei figli per comportamenti speciali (es. il drone ondeggia).
func _update_extra(_delta: float) -> void:
	pass


func _draw() -> void:
	# Corpo rettangolare con occhio rosso. L'origine è ai "piedi".
	var body := Color.WHITE if _hit_flash > 0 else color
	draw_rect(Rect2(-size.x * 0.5, -size.y, size.x, size.y), body)
	draw_rect(Rect2(-size.x * 0.5 - 2, -size.y * 0.85, 6, 6), eye_color)
	# Barra della vita.
	var ratio: float = clamp(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-14, -size.y - 8, 28, 3), Color("330000"))
	draw_rect(Rect2(-14, -size.y - 8, 28 * ratio, 3), Color("ff4444"))
	if _stun_time > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-10, -size.y - 12), "zzz", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffee66"))
