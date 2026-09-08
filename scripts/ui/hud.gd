class_name Hud
extends CanvasLayer

## Affichage en jeu : titre, niveau du joueur, joysticks tactiles.

@onready var _level_label: Label = $LevelLabel


func _ready() -> void:
	_level_label.pivot_offset = _level_label.size / 2.0


func set_level(level: int) -> void:
	_level_label.text = "Niveau %d" % level
	# Petit rebond pour marquer la montée.
	_level_label.scale = Vector2(1.35, 1.35)
	create_tween().tween_property(_level_label, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
