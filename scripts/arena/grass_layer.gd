class_name GrassLayer
extends TileMapLayer

## Buissons : on s'y cache des adversaires et on y récupère plus vite.
##
## L'herbe est dessinée *par-dessus* les personnages (voir [constant Z_INDEX]),
## c'est ce qui les couvre visuellement. Elle n'a pas de couche physique : elle
## ne bloque ni les déplacements ni les projectiles, on la traverse librement.
##
## Le TileSet est généré en code (placeholder), comme les murs de l'arène ;
## il sera remplacé par un vrai tileset quand les graphismes deviendront un sujet.

## L'herbe passe au-dessus des murs et des bots ; le joueur local se place
## juste au-dessus pour se voir dans sa propre cachette.
const Z_INDEX := 5
const SOURCE_ID := 0
const TILE := Vector2i.ZERO

@export var tile_size: int = 64


func _ready() -> void:
	z_index = Z_INDEX
	tile_set = _build_tile_set()


## Vrai si cette position du monde est couverte d'herbe.
func covers(world_position: Vector2) -> bool:
	return get_cell_source_id(local_to_map(to_local(world_position))) != -1


## Plante un rectangle de cases (en cases, pas en pixels).
func fill(area: Rect2i) -> void:
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			set_cell(Vector2i(x, y), SOURCE_ID, TILE)


func _build_tile_set() -> TileSet:
	var built := TileSet.new()
	built.tile_size = Vector2i(tile_size, tile_size)

	var image := Image.create_empty(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.13, 0.34, 0.17))
	# Touffes plus claires pour que l'herbe ne soit pas un aplat. Graine fixe :
	# le motif doit être le même à chaque lancement, sinon l'arène clignote.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260920
	for _i in range(24):
		var patch_size := rng.randi_range(6, 15)
		image.fill_rect(Rect2i(
			rng.randi_range(0, tile_size - patch_size),
			rng.randi_range(0, tile_size - patch_size),
			patch_size, patch_size), Color(0.18, 0.46, 0.22))

	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(tile_size, tile_size)
	built.add_source(source, SOURCE_ID)
	source.create_tile(TILE)
	return built
