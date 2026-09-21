class_name BaseCharacter
extends CharacterBody2D

## Personnage de base : déplacement top-down, visée, tir, PV, niveau, caméra.
## Les classes (assassin, archer, sorcier, tank) hériteront de cette scène.
## Un bot est simplement cette scène avec `is_local_player = false`.
##
## Toutes les stats de combat découlent de [member level] via [LevelStats],
## modulées par les facteurs exportés (les bots sont plus faibles et plus lents).

signal health_changed(current: int, maximum: int)
signal level_changed(level: int)
signal xp_changed(current: int, needed: int)
signal died

const DEATH_BURST := preload("res://scenes/fx/death_burst.tscn")
## Opacité d'un personnage qui se tient dans l'herbe.
const GRASS_ALPHA := 0.6

@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")
## Distance entre le centre du perso et le point d'apparition du projectile.
@export var muzzle_offset: float = 28.0
## Seul le joueur local lit les inputs, active sa caméra, gagne des niveaux et réapparaît.
@export var is_local_player: bool = true
## Les projectiles ignorent les personnages de la même équipe.
@export var team: int = 0
## Multiplicateurs appliqués par-dessus les stats du niveau.
@export var health_factor: float = 1.0
@export var speed_factor: float = 1.0
@export var damage_factor: float = 1.0

@export_group("Herbe")
## Multiplicateur de régénération tant qu'on se tient dans l'herbe.
@export var grass_regen_multiplier: float = 3.0
## En dessous de cette distance, un adversaire repère quand même un personnage caché.
@export var grass_reveal_distance: float = 90.0
## Durée pendant laquelle attaquer ou encaisser un coup trahit la cachette.
@export var grass_reveal_duration: float = 1.2

## Niveau courant. Le joueur gagne +1 par ennemi tué ; les bots reçoivent le leur à l'apparition.
var level: int = 0:
	set = set_level
## Expérience accumulée vers le prochain niveau (0 .. XP_PER_LEVEL - 1).
var xp: int = 0

var max_health: int = 0
var health: int = 0
var regen_per_second: float
var damage: int
var fire_range: float
var speed: float
var fire_cooldown: float
## Où réapparaître. Par défaut, la position au moment d'entrer dans la scène.
var spawn_position: Vector2
## Vrai quand le personnage se tient dans l'herbe (voir [GrassLayer]).
var in_grass: bool = false

@onready var _camera: Camera2D = $Camera2D
@onready var _body: Polygon2D = $Body
@onready var _nose: Node2D = $Nose

var _move_joystick: TouchJoystick
var _aim_joystick: TouchJoystick
var _facing: Vector2 = Vector2.RIGHT
var _cooldown_left: float = 0.0
var _regen_accumulator: float = 0.0
## Temps restant pendant lequel la cachette est trahie.
var _reveal_left: float = 0.0
## Intensité du flash d'impact, 1 au moment du coup puis ramenée à 0.
var _flash: float = 0.0
var _grass: GrassLayer
var _local_player: BaseCharacter


func _ready() -> void:
	spawn_position = position
	_apply_level_stats()
	health = max_health
	_camera.enabled = is_local_player
	_grass = get_tree().get_first_node_in_group("grass") as GrassLayer
	if not is_local_player:
		return
	# L'herbe couvre tout le monde, sauf soi : on doit se voir dans sa cachette.
	z_index = GrassLayer.Z_INDEX + 1
	add_to_group("player")
	_move_joystick = get_tree().get_first_node_in_group("move_joystick") as TouchJoystick
	_aim_joystick = get_tree().get_first_node_in_group("aim_joystick") as TouchJoystick
	if _aim_joystick != null:
		_aim_joystick.released.connect(_on_aim_released)


func set_level(value: int) -> void:
	var previous_max := max_health
	level = clampi(value, 0, LevelStats.MAX_LEVEL)
	_apply_level_stats()
	# Monter de niveau augmente les PV max : on rend la différence, pas plus.
	if previous_max > 0:
		health = mini(health + max_health - previous_max, max_health)
		health_changed.emit(health, max_health)
	level_changed.emit(level)
	queue_redraw()


func _apply_level_stats() -> void:
	max_health = maxi(1, roundi(LevelStats.max_health(level) * health_factor))
	regen_per_second = LevelStats.regen_per_second(level)
	damage = maxi(1, roundi(LevelStats.damage(level) * damage_factor))
	fire_range = LevelStats.fire_range(level)
	speed = LevelStats.speed(level) * speed_factor
	fire_cooldown = LevelStats.fire_cooldown(level)


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_reveal_left = maxf(_reveal_left - delta, 0.0)
	in_grass = _grass != null and _grass.covers(global_position)
	_regenerate(delta)
	var direction := _compute_move(delta)
	velocity = direction * speed
	move_and_slide()

	# Le regard suit la visée en priorité, sinon le déplacement.
	var aim := _aim_joystick.output if _aim_joystick != null else Vector2.ZERO
	if aim.length_squared() > 0.0:
		_facing = aim.normalized()
	elif direction.length_squared() > 0.0:
		_facing = direction.normalized()
	_nose.rotation = _facing.angle()
	_update_appearance()


## Régénération lente et continue ; on accumule les fractions pour rendre des PV entiers.
func _regenerate(delta: float) -> void:
	if health >= max_health:
		_regen_accumulator = 0.0
		return
	var rate := regen_per_second
	if in_grass:
		rate *= grass_regen_multiplier
	_regen_accumulator += rate * delta
	var whole := floori(_regen_accumulator)
	if whole > 0:
		_regen_accumulator -= whole
		health = mini(health + whole, max_health)
		health_changed.emit(health, max_health)
		queue_redraw()


## Caché pour qui ? La question se pose toujours par rapport à un observateur :
## on est invisible pour l'adversaire d'en face, jamais « invisible » dans l'absolu.
## C'est aussi la forme qu'il faudra en réseau, où le serveur répond à cette
## question une fois par client — le client ne décide jamais seul de ce qu'il voit.
##
## Un personnage dans l'herbe disparaît, sauf s'il vient d'attaquer ou d'encaisser
## un coup, ou si l'observateur est assez près pour le repérer. Les coéquipiers
## se voient toujours.
func is_concealed_from(observer: BaseCharacter) -> bool:
	if not in_grass or _reveal_left > 0.0:
		return false
	if not is_instance_valid(observer) or observer == self or observer.team == team:
		return false
	return global_position.distance_to(observer.global_position) > grass_reveal_distance


## Trahit la cachette pour un court instant (attaque reçue ou donnée).
func reveal() -> void:
	_reveal_left = grass_reveal_duration


## Une seule écriture de `modulate` par frame : le flash d'impact et la
## transparence de l'herbe se disputeraient la propriété sinon.
func _update_appearance() -> void:
	if not is_local_player:
		visible = not is_concealed_from(_get_local_player())
	# Un personnage visible dans l'herbe reste assombri : on voit qu'il y est.
	var alpha := GRASS_ALPHA if in_grass else 1.0
	var flash := 1.0 + 1.5 * _flash
	modulate = Color(flash, flash, flash, alpha)


func _get_local_player() -> BaseCharacter:
	if not is_instance_valid(_local_player):
		_local_player = get_tree().get_first_node_in_group("player") as BaseCharacter
	return _local_player

## Direction de déplacement voulue (longueur 0..1). Le joueur local lit ses
## inputs ; les bots surchargent cette méthode ; les autres restent immobiles.
func _compute_move(_delta: float) -> Vector2:
	if is_local_player:
		return _read_move()
	return Vector2.ZERO


## Au-dessus de la tête : barre de vie quand blessé, et niveau pour les bots
## (le joueur voit le sien dans le HUD).
func _draw() -> void:
	var width := 44.0
	var height := 6.0
	var top := -32.0
	if health < max_health:
		draw_rect(Rect2(-width / 2.0, top, width, height), Color(0, 0, 0, 0.6))
		var ratio := float(health) / max_health
		draw_rect(Rect2(-width / 2.0, top, width * ratio, height), Color(0.3, 0.9, 0.4))
	if not is_local_player:
		draw_string(ThemeDB.fallback_font, Vector2(-width / 2.0, top - 6.0), "Nv %d" % level,
			HORIZONTAL_ALIGNMENT_CENTER, width, 12, Color(1, 1, 1, 0.85))


## Desktop : clic gauche tire vers la souris, espace tire devant soi.
## Sur écran tactile, un tap hors des joysticks arrive ici comme un clic
## (émulation souris) et tire donc vers le point touché.
func _unhandled_input(event: InputEvent) -> void:
	if not is_local_player:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length_squared() > 0.0:
			_facing = to_mouse.normalized()
		_try_fire(_facing)
	elif event.is_action_pressed("fire"):
		_try_fire(_facing)


## Clavier (WASD / flèches) ou joystick virtuel : le joystick gagne s'il est utilisé.
func _read_move() -> Vector2:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _move_joystick != null and _move_joystick.output.length_squared() > 0.0:
		direction = _move_joystick.output
	return direction.limit_length(1.0)


## Relâcher le joystick de visée tire ; un simple tap tire dans la direction du regard.
func _on_aim_released(direction: Vector2) -> void:
	if direction.length_squared() > 0.0:
		_facing = direction.normalized()
	_try_fire(_facing)


func _try_fire(direction: Vector2) -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = fire_cooldown
	reveal()
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.direction = direction
	projectile.shooter = self
	projectile.damage = damage
	projectile.lifetime = fire_range / projectile.speed
	projectile.global_position = global_position + direction * muzzle_offset
	projectile.tint = _body.color
	# Le projectile vit dans la scène, pas dans le perso, pour ne pas suivre ses déplacements.
	get_tree().current_scene.add_child(projectile)
	Sfx.play("shoot", -12.0)


func take_damage(amount: int, from: Node2D) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	queue_redraw()
	Sfx.play("hit", -8.0)
	# Flash blanc bref pour marquer l'impact, rendu par _update_appearance().
	_flash = 1.0
	create_tween().tween_property(self, "_flash", 0.0, 0.1)
	# Encaisser un coup trahit la cachette : on ne se fait pas tirer dessus sans réagir.
	reveal()
	if health == 0:
		die(from)


## Éclat de particules aux couleurs du perso, son, crédit du kill au tueur,
## puis suppression (bot) ou réapparition (joueur local, qui garde son niveau).
func die(killer: Node2D = null) -> void:
	died.emit()
	Sfx.play("destroy")
	var burst: CPUParticles2D = DEATH_BURST.instantiate()
	burst.global_position = global_position
	burst.color = _body.color
	get_tree().current_scene.add_child(burst)
	if is_instance_valid(killer) and killer is BaseCharacter and killer != self:
		killer.on_kill(self)
	if is_local_player:
		_respawn()
	else:
		queue_free()


## Tuer rapporte de l'expérience selon l'écart de niveau (voir LevelStats.kill_xp) ;
## un ennemi nettement plus fort peut faire gagner plusieurs niveaux d'un coup.
## Seul le joueur progresse pour l'instant.
func on_kill(victim: BaseCharacter) -> void:
	if not is_local_player:
		return
	gain_xp(LevelStats.kill_xp(level, victim.level))


func gain_xp(amount: int) -> void:
	if level >= LevelStats.MAX_LEVEL:
		return
	xp += amount
	var levels_gained := 0
	while xp >= LevelStats.XP_PER_LEVEL and level < LevelStats.MAX_LEVEL:
		xp -= LevelStats.XP_PER_LEVEL
		level += 1
		levels_gained += 1
	if level >= LevelStats.MAX_LEVEL:
		xp = 0
	if levels_gained > 0:
		Sfx.play("levelup", -4.0)
	xp_changed.emit(xp, LevelStats.XP_PER_LEVEL)


func _respawn() -> void:
	position = spawn_position
	velocity = Vector2.ZERO
	health = max_health
	_regen_accumulator = 0.0
	_reveal_left = 0.0
	_flash = 0.0
	health_changed.emit(health, max_health)
	_camera.reset_smoothing()
	queue_redraw()


## Empêche la caméra de sortir de l'arène.
func set_camera_limits(bounds: Rect2i) -> void:
	_camera.limit_left = bounds.position.x
	_camera.limit_top = bounds.position.y
	_camera.limit_right = bounds.end.x
	_camera.limit_bottom = bounds.end.y
