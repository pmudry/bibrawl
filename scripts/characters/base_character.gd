class_name BaseCharacter
extends CharacterBody2D

## Personnage de base : déplacement top-down, visée, tir, caméra qui suit.
## Les classes (assassin, archer, sorcier, tank) hériteront de cette scène.

signal health_changed(current: int, maximum: int)
signal died

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
@onready var _nose: Node2D = $Nose

var _move_joystick: VirtualJoystick
var _aim_joystick: VirtualJoystick
var _facing: Vector2 = Vector2.RIGHT
var _cooldown_left: float = 0.0


func _ready() -> void:
	health = max_health
	_camera.enabled = is_local_player
	_move_joystick = get_tree().get_first_node_in_group("move_joystick") as VirtualJoystick
	_aim_joystick = get_tree().get_first_node_in_group("aim_joystick") as VirtualJoystick
	if is_local_player and _aim_joystick != null:
		_aim_joystick.released.connect(_on_aim_released)


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if not is_local_player:
		return
	var direction := _read_move()
	velocity = direction * speed
	move_and_slide()

	# Le regard suit la visée en priorité, sinon le déplacement.
	var aim := _aim_joystick.output if _aim_joystick != null else Vector2.ZERO
	if aim.length_squared() > 0.0:
		_facing = aim.normalized()
	elif direction.length_squared() > 0.0:
		_facing = direction.normalized()
	_nose.rotation = _facing.angle()


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


func take_damage(amount: int, _from: Node2D) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()
		# Phase 1 : mort et respawn. Pour l'instant on se contente de remettre les PV.
		health = max_health
		health_changed.emit(health, max_health)


## Empêche la caméra de sortir de l'arène.
func set_camera_limits(bounds: Rect2i) -> void:
	_camera.limit_left = bounds.position.x
	_camera.limit_top = bounds.position.y
	_camera.limit_right = bounds.end.x
	_camera.limit_bottom = bounds.end.y
