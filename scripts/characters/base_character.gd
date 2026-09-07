class_name BaseCharacter
extends CharacterBody2D

## Personnage de base : déplacement top-down, caméra qui suit.
## Les classes (assassin, archer, sorcier, tank) hériteront de cette scène.

@export var speed: float = 260.0
## Seul le joueur local lit les inputs et active sa caméra.
@export var is_local_player: bool = true

@onready var _camera: Camera2D = $Camera2D
@onready var _nose: Node2D = $Nose

var _joystick: VirtualJoystick


func _ready() -> void:
	_camera.enabled = is_local_player
	_joystick = get_tree().get_first_node_in_group("virtual_joystick") as VirtualJoystick


func _physics_process(_delta: float) -> void:
	if not is_local_player:
		return
	var direction := _read_input()
	velocity = direction * speed
	move_and_slide()
	if direction.length_squared() > 0.0:
		_nose.rotation = direction.angle()


## Clavier (WASD / flèches) ou joystick virtuel : le joystick gagne s'il est utilisé.
func _read_input() -> Vector2:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _joystick != null and _joystick.output.length_squared() > 0.0:
		direction = _joystick.output
	return direction.limit_length(1.0)


## Empêche la caméra de sortir de l'arène.
func set_camera_limits(bounds: Rect2i) -> void:
	_camera.limit_left = bounds.position.x
	_camera.limit_top = bounds.position.y
	_camera.limit_right = bounds.end.x
	_camera.limit_bottom = bounds.end.y
