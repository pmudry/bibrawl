extends Node2D

## Arène de test : sol quadrillé, murs sur le pourtour et quelques piliers.
## Le TileSet est généré en code (placeholder) ; il sera remplacé par un vrai
## tileset dessiné quand les graphismes deviendront un sujet.

const TILE_SIZE := 64
const WALL_SOURCE_ID := 0
const WALL_TILE := Vector2i.ZERO

@export var width_tiles: int = 30
@export var height_tiles: int = 18
@export var pillars: Array[Vector2i] = [
	Vector2i(7, 5), Vector2i(7, 12), Vector2i(22, 5), Vector2i(22, 12),
	Vector2i(14, 8), Vector2i(15, 8), Vector2i(14, 9), Vector2i(15, 9),
]
## Position de départ du joueur, en cases.
@export var player_spawn: Vector2i = Vector2i(5, 9)
## Bots de test : scène + case d'apparition. Chacun réapparaît après destruction.
const BOTS := [
	{ "scene": preload("res://scenes/characters/bot.tscn"), "spawn": Vector2i(25, 9) },
	{ "scene": preload("res://scenes/characters/wander_bot.tscn"), "spawn": Vector2i(15, 3) },
]
@export var bot_respawn_delay: float = 3.0
## Niveau d'un bot à l'apparition : celui du joueur, décalé au hasard dans cette fourchette.
@export var bot_level_below: int = 2
@export var bot_level_above: int = 5

@onready var _walls: TileMapLayer = $Walls
@onready var _player: BaseCharacter = $Player
@onready var _hud: Hud = $HUD


func _ready() -> void:
	_walls.tile_set = _build_tile_set()
	_build_walls()
	var bounds := Rect2i(0, 0, width_tiles * TILE_SIZE, height_tiles * TILE_SIZE)
	_player.set_camera_limits(bounds)
	_player.spawn_position = _tile_center(player_spawn)
	_player.position = _player.spawn_position
	_player.level_changed.connect(_hud.set_level)
	_player.xp_changed.connect(_hud.set_xp)
	_hud.set_level(_player.level)
	_hud.set_xp(_player.xp, LevelStats.XP_PER_LEVEL)
	for entry in BOTS:
		_spawn_bot(entry)


func _tile_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


func _spawn_bot(entry: Dictionary) -> void:
	var bot: BaseCharacter = entry.scene.instantiate()
	bot.position = _tile_center(entry.spawn)
	bot.level = randi_range(maxi(0, _player.level - bot_level_below), _player.level + bot_level_above)
	bot.died.connect(_on_bot_died.bind(entry))
	add_child(bot)


func _on_bot_died(entry: Dictionary) -> void:
	get_tree().create_timer(bot_respawn_delay).timeout.connect(_spawn_bot.bind(entry))


func _draw() -> void:
	var size := Vector2(width_tiles, height_tiles) * TILE_SIZE
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.16, 0.18, 0.2))
	var grid := Color(1, 1, 1, 0.05)
	for x in range(width_tiles + 1):
		draw_line(Vector2(x * TILE_SIZE, 0), Vector2(x * TILE_SIZE, size.y), grid)
	for y in range(height_tiles + 1):
		draw_line(Vector2(0, y * TILE_SIZE), Vector2(size.x, y * TILE_SIZE), grid)


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()

	var image := Image.create_empty(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.35, 0.37, 0.42))
	image.fill_rect(Rect2i(4, 4, TILE_SIZE - 8, TILE_SIZE - 8), Color(0.45, 0.47, 0.53))

	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	# La source doit appartenir au TileSet avant de configurer les collisions,
	# sinon la TileData ignore l'existence de la couche physique.
	tile_set.add_source(source, WALL_SOURCE_ID)
	source.create_tile(WALL_TILE)

	var half := TILE_SIZE / 2.0
	var tile_data := source.get_tile_data(WALL_TILE, 0)
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half),
	]))
	return tile_set


func _build_walls() -> void:
	for x in range(width_tiles):
		for y in range(height_tiles):
			var on_border := x == 0 or y == 0 or x == width_tiles - 1 or y == height_tiles - 1
			if on_border:
				_walls.set_cell(Vector2i(x, y), WALL_SOURCE_ID, WALL_TILE)
	for cell in pillars:
		_walls.set_cell(cell, WALL_SOURCE_ID, WALL_TILE)
