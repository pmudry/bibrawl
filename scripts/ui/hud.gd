class_name Hud
extends CanvasLayer

## Affichage en jeu : titre, niveau et expérience du joueur, joysticks tactiles.

@onready var _level_label: Label = $LevelLabel
@onready var _xp_bar: ProgressBar = $XpBar


func _ready() -> void:
	_level_label.pivot_offset = _level_label.size / 2.0


func set_level(level: int) -> void:
	_level_label.text = "Niveau %d" % level
	# Petit rebond pour marquer la montée.
	_level_label.scale = Vector2(1.35, 1.35)
	create_tween().tween_property(_level_label, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_xp(current: int, needed: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = current
