class_name VirtualJoystick
extends Control

## Joystick tactile : une base fixe et un bouton qui suit le doigt.
## [member output] vaut un vecteur de longueur 0..1, lu par le personnage.

@export var radius: float = 90.0
@export var knob_radius: float = 36.0
@export var dead_zone: float = 0.15
## Force l'affichage même sans écran tactile (test à la souris sur desktop,
## grâce à `input_devices/pointing/emulate_touch_from_mouse`).
@export var always_visible: bool = false

var output: Vector2 = Vector2.ZERO

var _touch_index: int = -1
var _knob_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * radius * 2.0
	visible = always_visible or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Coordonnées locales au Control, quel que soit le stretch de la fenêtre.
	var local_event := make_input_local(event)
	if local_event is InputEventScreenTouch:
		_handle_touch(local_event)
	elif local_event is InputEventScreenDrag:
		_handle_drag(local_event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _touch_index == -1 and Rect2(Vector2.ZERO, size).has_point(event.position):
		_touch_index = event.index
		_update_knob(event.position)
		get_viewport().set_input_as_handled()
	elif not event.pressed and event.index == _touch_index:
		_release()
		get_viewport().set_input_as_handled()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	_update_knob(event.position)
	get_viewport().set_input_as_handled()


func _update_knob(local_position: Vector2) -> void:
	var offset := (local_position - size / 2.0).limit_length(radius)
	_knob_offset = offset
	var strength := offset.length() / radius
	output = offset / radius if strength > dead_zone else Vector2.ZERO
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	_knob_offset = Vector2.ZERO
	output = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, radius, Color(1, 1, 1, 0.15))
	draw_arc(center, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.4), 2.0)
	draw_circle(center + _knob_offset, knob_radius, Color(1, 1, 1, 0.6))
