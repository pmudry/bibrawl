class_name Bot
extends BaseCharacter

## Bot de base : immobile, tire sur le joueur dès qu'il est à portée.
## Dégâts, portée et cadence viennent du niveau (LevelStats), comme pour le joueur :
## un bot de haut niveau tire plus loin, plus fort et plus souvent.
## Les bots mobiles héritent de cette classe et surchargent _compute_move().

## Imprécision de visée, en degrés de chaque côté. Diminue avec le niveau.
@export var aim_spread_degrees: float = 12.0
## Délai avant le premier tir quand la cible entre à portée.
@export var reaction_time: float = 0.4

var _target: BaseCharacter
var _reaction_left: float = 0.0


func _physics_process(delta: float) -> void:
	super(delta)
	_think(delta)
	_nose.rotation = _facing.angle()


func _think(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as BaseCharacter
		if _target == null:
			return
	var to_target := _target.global_position - global_position
	# On tire un peu en dedans de la portée max pour que le projectile arrive.
	if to_target.length() > fire_range * 0.9:
		_reaction_left = reaction_time
		return
	_facing = to_target.normalized()
	_reaction_left -= delta
	if _reaction_left > 0.0:
		return
	var spread := deg_to_rad(aim_spread_degrees) / (1.0 + 0.2 * LevelStats.factor(level))
	_try_fire(_facing.rotated(randf_range(-spread, spread)))
