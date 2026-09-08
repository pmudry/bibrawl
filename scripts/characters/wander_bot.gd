class_name WanderBot
extends Bot

## Bot qui erre : change de direction au hasard à intervalles irréguliers,
## fait parfois une pause, rebondit sur ce qu'il percute. Tire comme un Bot.

@export var change_interval_min: float = 0.5
@export var change_interval_max: float = 1.5
## Probabilité de rester immobile au prochain changement de direction.
@export var idle_chance: float = 0.25

var _direction: Vector2 = Vector2.ZERO
var _time_until_change: float = 0.0


func _compute_move(delta: float) -> Vector2:
	_time_until_change -= delta
	if _time_until_change <= 0.0:
		_pick_direction()
	# move_and_slide() du frame précédent : si on a percuté quelque chose, on rebondit.
	var collision := get_last_slide_collision()
	if collision != null and _direction.length_squared() > 0.0:
		_direction = _direction.bounce(collision.get_normal()).normalized()
	return _direction


func _pick_direction() -> void:
	_time_until_change = randf_range(change_interval_min, change_interval_max)
	if randf() < idle_chance:
		_direction = Vector2.ZERO
	else:
		_direction = Vector2.from_angle(randf() * TAU)
