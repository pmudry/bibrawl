class_name Projectile
extends Area2D

## Projectile rectiligne : avance, touche la première chose sur son chemin
## (mur ou personnage adverse), disparaît. Le tireur et son équipe sont ignorés.

@export var speed: float = 700.0
@export var damage: int = 10
@export var lifetime: float = 1.2

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D
## Couleur du corps, reprise de celle du tireur pour distinguer qui tire.
var tint: Color = Color(1, 0.9, 0.4)

var _time_left: float


func _ready() -> void:
	_time_left = lifetime
	rotation = direction.angle()
	$Body.color = tint
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if body is BaseCharacter and is_instance_valid(shooter) and shooter is BaseCharacter \
			and body.team == shooter.team:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, shooter)
	queue_free()
