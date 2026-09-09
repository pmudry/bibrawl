class_name Bot
extends BaseCharacter

## Bot de base : immobile, tire sur le joueur dès qu'il est à portée.
## PV, dégâts, portée et cadence de base viennent du niveau (LevelStats), comme
## pour le joueur. Par-dessus, une « maîtrise » propre aux bots va de 0 (niveau 0)
## à 1 (niveau max) sur la même courbe logarithmique que les stats : un bot de bas
## niveau tire rarement, faiblement et à côté ; un bot de niveau 9999 a les réglages
## « max » ci-dessous, sans handicap.
##
##   niveau      0     3     15    63   1023  9999
##   maîtrise   0.00  0.15  0.30  0.45  0.75  1.00
##
## Les bots mobiles héritent de cette classe et surchargent _compute_move().

@export_group("Niveau 0")
## Fraction des dégâts normaux infligés par un bot de niveau 0.
@export_range(0.0, 1.0) var weak_damage_ratio: float = 0.45
## Un bot de niveau 0 attend autant de fois plus longtemps entre deux tirs.
@export_range(1.0, 10.0) var weak_cooldown_multiplier: float = 3.0
## Imprécision de visée d'un bot de niveau 0, en degrés de chaque côté.
@export var weak_aim_spread_degrees: float = 24.0
## Délai avant le premier tir quand la cible entre à portée, au niveau 0.
@export var weak_reaction_time: float = 1.0

@export_group("Niveau max")
## Imprécision de visée d'un bot de niveau max, en degrés de chaque côté.
@export var aim_spread_degrees: float = 3.0
## Délai avant le premier tir quand la cible entre à portée, au niveau max.
@export var reaction_time: float = 0.4

var _target: BaseCharacter
var _reaction_left: float = 0.0
var _skill: float = 0.0
var _aim_spread: float = 0.0
var _reaction_time: float = 0.0


## Maîtrise du bot, 0 au niveau 0 et 1 au niveau max.
static func skill(level: int) -> float:
	return LevelStats.factor(level) / LevelStats.factor(LevelStats.MAX_LEVEL)


func _apply_level_stats() -> void:
	super()
	_skill = skill(level)
	damage = maxi(1, roundi(damage * lerpf(weak_damage_ratio, 1.0, _skill)))
	fire_cooldown *= lerpf(weak_cooldown_multiplier, 1.0, _skill)
	_aim_spread = deg_to_rad(lerpf(weak_aim_spread_degrees, aim_spread_degrees, _skill))
	_reaction_time = lerpf(weak_reaction_time, reaction_time, _skill)


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
		_reaction_left = _reaction_time
		return
	_facing = to_target.normalized()
	_reaction_left -= delta
	if _reaction_left > 0.0:
		return
	_try_fire(_facing.rotated(randf_range(-_aim_spread, _aim_spread)))
