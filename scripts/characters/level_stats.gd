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
## Expérience nécessaire pour passer un niveau. Constante : la courbe des
## stats est déjà logarithmique, inutile d'en rajouter une ici.
const XP_PER_LEVEL := 100


static func factor(level: int) -> float:
	return log(1.0 + clampi(level, 0, MAX_LEVEL)) / log(2.0)


## Expérience gagnée en tuant un ennemi. Un ennemi de même niveau vaut exactement
## un niveau ; chaque niveau d'écart au-dessus ajoute un demi-niveau (max 5),
## chaque niveau en dessous en retire un demi (min un quart).
##
##   écart   -3   -2   -1    0   +1   +2   +4   +8
##   XP      25   25   50  100  150  200  300  500
static func kill_xp(killer_level: int, victim_level: int) -> int:
	var difference := victim_level - killer_level
	var multiplier := clampf(1.0 + 0.5 * difference, 0.25, 5.0)
	return roundi(XP_PER_LEVEL * multiplier)


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
