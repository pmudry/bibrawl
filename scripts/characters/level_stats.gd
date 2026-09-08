class_name LevelStats
extends RefCounted

## Stats dérivées du niveau (0..MAX_LEVEL).
## Courbe logarithmique : les premiers niveaux changent beaucoup le jeu,
## les suivants de moins en moins, et les chiffres restent raisonnables à 9999.
##
##   niveau   0    1    3    7   15   63  1023  9999
##   facteur  0    1    2    3    4    6    10  ~13.3
##
## Tous les chiffres ci-dessous sont des réglages à ajuster en jouant.

const MAX_LEVEL := 9999


static func factor(level: int) -> float:
	return log(1.0 + clampi(level, 0, MAX_LEVEL)) / log(2.0)


static func max_health(level: int) -> int:
	return roundi(40.0 + 15.0 * factor(level))


## PV rendus par seconde.
static func regen_per_second(level: int) -> float:
	return 0.5 + 0.6 * factor(level)


static func damage(level: int) -> int:
	return roundi(6.0 + 2.5 * factor(level))


## Distance parcourue par un projectile, en pixels.
static func fire_range(level: int) -> float:
	return 250.0 + 60.0 * factor(level)


static func speed(level: int) -> float:
	return 200.0 + 12.0 * factor(level)


static func fire_cooldown(level: int) -> float:
	return 0.5 / (1.0 + 0.08 * factor(level))
