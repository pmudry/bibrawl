class_name BaseCharacter
extends CharacterBody2D

## Personnage de base : déplacement top-down, visée, tir, PV, caméra qui suit.
## Les classes (assassin, archer, sorcier, tank) hériteront de cette scène.
## Un bot est simplement cette scène avec `is_local_player = false`.

signal health_changed(current: int, maximum: int)
signal died

const DEATH_BURST := preload("res://scenes/fx/death_burst.tscn")

@export var speed: float = 260.0
@export var max_health: int = 100
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")
@export var fire_cooldown: float = 0.35
## Distance entre le centre du perso et le point d'apparition du projectile.
@export var muzzle_offset: float = 28.0
## Seul le joueur local lit les inputs et active sa caméra.
@export var is_local_player: bool = true

var health: int

@onready var _camera: Camera2D = $Camera2D
@onready var _body: Polygon2D = $Body
@onready var _nose: Node2D = $Nose

var _move_joystick: VirtualJoystick
var _aim_joystick: VirtualJoystick
var _facing: Vector2 = Vector2.RIGHT
var _cooldown_left: float = 0.0


func _ready() -> void:
	health = max_health
	_camera.enabled = is_local_player
	if not is_local_player:
		return
	_move_joystick = get_tree().get_first_node_in_group("move_joystick") as VirtualJoystick
	_aim_joystick = get_tree().get_first_node_in_group("aim_joystick") as VirtualJoystick
	if _aim_joystick != null:
		_aim_joystick.released.connect(_on_aim_released)


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
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


## Direction de déplacement voulue (longueur 0..1). Le joueur local lit ses
## inputs ; les bots surchargent cette méthode ; les autres restent immobiles.
func _compute_move(_delta: float) -> Vector2:
	if is_local_player:
		return _read_move()
	return Vector2.ZERO


## Barre de vie au-dessus de la tête, seulement quand le perso est blessé.
func _draw() -> void:
	if health >= max_health:
		return
	var width := 44.0
	var height := 6.0
	var top := -32.0
	draw_rect(Rect2(-width / 2.0, top, width, height), Color(0, 0, 0, 0.6))
	var ratio := float(health) / max_health
	draw_rect(Rect2(-width / 2.0, top, width * ratio, height), Color(0.3, 0.9, 0.4))


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
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.direction = direction
	projectile.shooter = self
	projectile.global_position = global_position + direction * muzzle_offset
	# Le projectile vit dans la scène, pas dans le perso, pour ne pas suivre ses déplacements.
	get_tree().current_scene.add_child(projectile)
	Sfx.play("shoot", -6.0)


func take_damage(amount: int, _from: Node2D) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	queue_redraw()
	Sfx.play("hit", -8.0)
	# Flash blanc bref pour marquer l'impact.
	modulate = Color(2.5, 2.5, 2.5)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.1)
	if health == 0:
		die()


## Éclat de particules aux couleurs du perso, son, puis suppression.
## Le respawn (Phase 1) sera géré par le mode de jeu, pas ici.
func die() -> void:
	died.emit()
	Sfx.play("destroy")
	var burst: CPUParticles2D = DEATH_BURST.instantiate()
	burst.global_position = global_position
	burst.color = _body.color
	get_tree().current_scene.add_child(burst)
	queue_free()


## Empêche la caméra de sortir de l'arène.
func set_camera_limits(bounds: Rect2i) -> void:
	_camera.limit_left = bounds.position.x
	_camera.limit_top = bounds.position.y
	_camera.limit_right = bounds.end.x
	_camera.limit_bottom = bounds.end.y
